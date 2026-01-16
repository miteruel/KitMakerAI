unit KitMaker.Task;

interface

// Monadas_Pascal
// (C)  Antonio Alcázar Ruiz.
// Task Monad system.
//

uses

  System.Threading,

  System.Classes, SysUtils;

type

  TProTask = record
    class operator Add(const pro: TProTask; const data: TThreadProcedure)
      : String; overload;
    class operator GreaterThan(const pro: TProTask;
      const data: TThreadProcedure): Boolean; overload;

    class operator Multiply(const pro: TProTask;
      const data: array of TThreadProcedure): String; overload;
    class procedure Errores(Exception: Exception;
      const ErrorMsg: string = ''); static;

  private
    MainThreads: TThread;

    Procedure Init;
    procedure done;

    Procedure Cola_(AMethod: TThreadProcedure; slip: Integer = 0);

  end;

procedure FreeNil(const [ref] Obj: TObject);

var

  TaskA: TProTask;

implementation

procedure FreeNil(const [ref] Obj: TObject);
begin
  if Obj = Nil then
  begin
    exit
  end;
  FreeAndNil(Obj);
end;

{ TProTask }

class operator TProTask.Multiply(const pro: TProTask;
  const data: array of TThreadProcedure): String;
var
  p: TThreadProcedure;
begin
  result := '';
  for p in data do
  begin
    pro.Cola_(p)
  end;
end;

class operator TProTask.Add(const pro: TProTask;
  const data: TThreadProcedure): String;
begin
  result := '';
  pro.Cola_(data);
end;

Procedure TProTask.Cola_(AMethod: TThreadProcedure; slip: Integer = 0);
begin
  TTask.Run(
    procedure
    begin

      Try
        if slip <> 0 then
          Sleep(slip);
        AMethod()

      Except
        On E: Exception do
        Begin
          Errores(E)
        End;
      End;
    end);
end;

procedure TProTask.Init;
begin
  MainThreads := TThread.CurrentThread;
end;

procedure TProTask.done;
begin
  // FiFo_.done;
  MainThreads := Nil;
end;

class procedure TProTask.Errores(Exception: Exception; const ErrorMsg: string);
begin
  // TaskA -
  // procedure
  begin
    // ShowMessage(ErrorMsg+exception.Message);
  end;
end;

class operator TProTask.GreaterThan(const pro: TProTask;
const data: TThreadProcedure): Boolean;
begin
  result := False;
  if pro.MainThreads = TThread.CurrentThread then
  begin
    if assigned(data) then
    begin
      data()
    end;
  end
  else
  begin
    result := True;
    if assigned(data) then
    begin
      TThread.Queue(nil, data);
    end;
  end;
end;

initialization

TaskA.Init;

finalization

TaskA.done;

end.
(************* Find Bugs ***************
Here are the potential bugs and
critical issues in the Delphi code:

### **Critical Bugs**

1. **`FreeNil`
Compilation Error**
   ```delphi
   procedure FreeNil(const [ref] Obj:
TObject);
   begin
     FreeAndNil(Obj); // ERROR: FreeAndNil requires a var
parameter, not const
   end;
   ```
   The `[ref]` attribute doesn't make the
parameter writable. `FreeAndNil` requires a `var` parameter to modify the
reference. This code won't compile.

2. **Broken Record Semantics**
   -
`TProTask` is a **record** (value type), but it's used as if it were a class
(reference type).
   - The `Init` method sets `TaskA.MainThreads`, but class
operators receive **copies** of the record, not references. Therefore,
`pro.MainThreads` in operators is always a copy and won't reflect the original
`TaskA.MainThreads` value.
   - **Impact**: The `GreaterThan` operator's thread
comparison is completely broken—it compares against a stale copy of the thread
reference.

3. **Dangerous Thread Reference Storage**
   ```delphi

MainThreads: TThread;
   ```
   Storing `TThread.CurrentThread` doesn't
increment the reference count. If the thread terminates, this reference becomes
dangling, leading to potential access violations.

### **Major Bugs**

4.
**Race Condition on `MainThreads`**
   - Multiple threads calling `GreaterThan`
simultaneously can cause race conditions on the `MainThreads` field.
   - No
synchronization (critical section, mutex) protects this shared state.

5.
**Missing Assigned() Checks**
   ```delphi
   class operator
TProTask.Add(const pro: TProTask; const data: TThreadProcedure): String;

begin
     pro.Cola_(data); // No check if data is assigned
   end;
   ```

If `data` is `nil`, this will crash. The `GreaterThan` operator checks it, but
`Add` and `Multiply` don't.

6. **Improper Shutdown**
   - Tasks started with
`TTask.Run` continue running after `finalization` calls `done`.
   - No waiting
for pending tasks, leading to potential access violations during program
shutdown.

7. **Empty Error Handler**
   ```delphi
   class procedure
TProTask.Errores(Exception: Exception; const ErrorMsg: string);
   begin

// TaskA - procedure begin // ShowMessage(...);
   end;
   ```
   The error
handler is commented out and silently swallows exceptions, making debugging
impossible.

### **Design & Implementation Flaws**

8. **Misleading Operator
Semantics**
   - `Add` and `Multiply` return `String` but only produce empty
strings with side effects (launching tasks). This violates operator overloading
principles.
   - `GreaterThan` has a non-obvious side effect (executing code)
while returning a boolean—extremely confusing.

9. **Thread Pool Abuse**

```delphi
   if slip <> 0 then Sleep(slip);
   ```
   Blocking thread pool
threads with `Sleep` is inefficient and can lead to thread pool
starvation.

10. **Unused Result Variables**
    ```delphi
    result := '';
// Set but never used meaningfully
    ```

11. **Uninitialized Record
Fields**
    If users create local `TProTask` variables, the `MainThreads`
field contains garbage until `Init` is called.

12. **Inconsistent Naming**

- `Cola_` (Spanish for "queue") mixes languages.
    - `Errores` (Spanish)
should be `HandleError` or similar.

### **Recommended
Fixes**

```delphi
// Change to class with proper lifetime management
type

TProTask = class(TObject)
  private
    FMainThreadID: TThreadID; // Store ID
instead of reference
    FTasks: TList<ITask>; // Track active tasks

public
    constructor Create;
    destructor Destroy; override;

    //
Use methods instead of confusing operators
    procedure QueueTask(const
AMethod: TThreadProcedure; ASleepMs: Integer = 0);
    function IsMainThread:
Boolean;
    procedure SynchronizeIfNeeded(const AMethod: TThreadProcedure);


    class procedure HandleError(E: Exception; const ErrorMsg: string = '');
static;
  end;

// Implement proper cleanup
destructor
TProTask.Destroy;
begin
  // Wait for all tasks to complete

TTask.WaitForAll(FTasks.ToArray);
  FTasks.Free;

inherited;
end;
```

**Summary**: The code has fundamental architectural
flaws (record vs class misuse), compilation errors, and thread safety issues
that make it unreliable for production use.
*)

(*
  procedure FreeAndNil(const [ref] Obj: TObject);
  var
  Temp: TObject;
  begin
  Temp := Obj;
  TObject(Pointer(@Obj)^) := nil;
  Temp.Free;
  end;

  (************* Explanation ***************
  This code attempts to implement a
  version of `FreeAndNil` using a `const [ref]` parameter instead of the standard
  `var` parameter, but it's **fundamentally flawed and dangerous**.

  ### What It
  Literally Does

  ```delphi
  Temp := Obj;                    // 1. Saves the
  object reference to a local variable
  TObject(Pointer(@Obj)^) := nil; // 2. Uses
  pointer manipulation to nil the parameter
  Temp.Free;                      // 3.
  Frees the saved object reference
  ```

  The second line is the key: `@Obj` gets
  the address of the reference, casts it to a pointer, dereferences it, and
  assigns `nil`—bypassing the `const` restriction.

  ### The (Flawed)
  Intent

  The author likely wanted to allow `FreeAndNil` to accept
  **properties**, since `const [ref]` permits passing expressions that `var` does
  not:

  ```delphi
  // This works with const [ref] but NOT with
  var:
  FreeAndNil(MyObjectProperty);
  ```

  ### Why It's Broken

  When you pass
  a **property** to `const [ref]`, Delphi creates a **temporary variable** behind
  the scenes. The pointer manipulation nils out this *temporary*, **not the actual
  property**. The property retains its original value (now a dangling pointer to
  freed memory), causing silent memory corruption.

  ```delphi
  // If MyProperty
  is backed by FMyField:
  FreeAndNil(MyProperty);
  // FMyField is STILL pointing
  to the freed object! DISASTER.
  ```

  ### Correct Approach

  Use the standard
  `FreeAndNil` with a `var` parameter:

  ```delphi
  procedure FreeAndNil(var Obj:
  TObject);
  var
  Temp: TObject;
  begin
  Temp := Obj;
  Obj := nil;

  Temp.Free;
  end;
  ```

  And for properties, you must assign them
  directly:

  ```delphi
  MyObject.Free;
  MyObject := nil;
  ```

  **Conclusion**:
  This code is a misguided hack that appears to work for variables but fails
  catastrophically with properties—the main reason you'd use `const [ref]`. Never
  use it.
*)
