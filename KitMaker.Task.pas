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

  TProThread = record
    class operator Add(const pro: TProThread; const data: TThreadProcedure)
      : String; overload;
    class operator Subtract(const pro: TProThread;
      const data: TThreadProcedure): String; overload;

    class operator Multiply(const pro: TProThread;
      const data: array of TThreadProcedure): String; overload;

  private
    MainThreads: TThread;

    Procedure Init;
    procedure done;

    Function AlaCola_(AMethod: TThreadProcedure; slip: Integer = 0): ITask;

  end;

Procedure Freenil(var oo); overload;

var

  TaskA: TProThread;

implementation


Procedure Freenil(var oo); overload;
var
  mio: TObject;
begin

  // try
  mio := TObject(oo);
  if mio = nil then
  begin
    // mio := TObject(oo);
    exit;
  end;

  TObject(oo) := Nil;
  mio.free;

end;

{ TProThread }

class operator TProThread.Multiply(const pro: TProThread;
  const data: array of TThreadProcedure): String;
var
  p: TThreadProcedure;
begin
  result := '';
  for p in data do
  begin
    pro.AlaCola_(p)
  end;
end;

class operator TProThread.Add(const pro: TProThread;
  const data: TThreadProcedure): String;
begin
  result := '';
  pro.AlaCola_(data);
end;

Function TProThread.AlaCola_(AMethod: TThreadProcedure;
  slip: Integer = 0): ITask;
begin
  result :=
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

        End;
      End;
    end);
end;

procedure TProThread.Init;
begin
  MainThreads :=  TThread.Current;
end;

procedure TProThread.done;
begin
  // FiFo_.done;
  MainThreads := Nil;
end;

class operator TProThread.Subtract(const pro: TProThread;
const data: TThreadProcedure): String;
begin
  result := '';
  if pro.MainThreads = TThread.Current then
  begin
    // VoLog_ > '-sme'; // + inttostr(int64(loga.MainThreads));
    if assigned(data) then
    begin
      data()
    end;
  end
  else
  begin

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
H
Records are not zero-initialized.
The global `TaskA` could contain random data until `Init` is called. While
`Init` is called in the `initialization` section, it's better to use a properly
constructed instance.

```
The `MainThreads` field is initialized to `nil` and never assigned an
actual thread reference. The `Subtract` operator's logic `if loga.MainThreads =
TThread.Current then` will always be false, making the conditional execution
logic broken.

### 6. **Silent Exception Swallowing**
```delphi
Except
  On
E: Exception do
  Begin
    // EMPTY - Silently swallows all exceptions

End;
```
Empty exception handlers hide errors and make debugging impossible.
At minimum, exceptions should be logged or re-raised.

### 7. **Thread Pool
Abuse with Sleep**
```delphi
if slip <> 0 then Sleep(slip);
```
Calling
`Sleep()` on a thread pool thread blocks that thread from being reused,
defeating the purpose of the thread pool and hurting scalability.

## Major
Design Flaws

### 8. **Confusing Operator Overloading**
Using `+`, `-`, `*`
for thread operations is non-intuitive and violates Delphi conventions:
-
`Add`: Runs a task asynchronously (fire-and-forget)
- `Subtract`: Executes
immediately or queues to main thread (broken logic)
- `Multiply`: Runs multiple
tasks asynchronously
These would be better as explicit methods like `Run`,
`Queue`, `RunParallel`.

### 9. **Return Type Mismatch**
All operators return
`String` but always return an empty string with no meaningful value. This
suggests the operators should return void or a task handle.

### 10. **No Task
Lifetime Management**
- No way to wait for tasks to complete
- No way to
cancel tasks
- No way to handle task results
- Creates potential memory leaks
and AVs on shutdown

### 11. **Unsafe Type Casting in
Freenil**
```delphi
Procedure Freenil(var oo);
var
  mio: TObject;
begin

mio := TObject(oo); // Unsafe cast of untyped parameter
  if mio = nil then
exit;
  TObject(oo) := Nil; // Modifies original variable

mio.free;
end;
```
- Works but is dangerous; better to use `FreeAndNil` or
generic type safety
- The parameter name `oo` is unclear

## Minor
Issues

### 12. **Incorrect Inline Variable Syntax**
```delphi
var
t :=
loga_.AlaCola_(data); // Wrong syntax
```
Should be: `var t :=
loga_.AlaCola_(data);` on one line, or properly typed.

### 13. **Unused
Variable**
```delphi
var
t := loga_.AlaCola_(data); // 't' is assigned but
never used
```
Generates a compiler hint/warning.

### 14. **Inconsistent
Naming**
- `AlaCola_` (Spanish?), `done` (lowercase), `Init` (PascalCase)
-
Parameter names `loga`, `loga_` are unclear

### 15. **Finalization Doesn't
Wait for Tasks**
```delphi
finalization
  TaskA.done; // Just sets
MainThreads := nil, doesn't wait for running tasks
```
If tasks are still
running during shutdown, it can cause access violations.

## Summary
This
code has **critical compilation errors** and **fundamental design flaws** that
make it non-functional and unsafe. It should be rewritten with proper task
management, clear method names, and correct lifetime handling.
*)
