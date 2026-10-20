;; extends
; `struct` e `interface` separados do `type` (que fica em @keyword.type),
; e `package` separado do `import`, espelhando os scopes da gramática Go do VSCode.
[
  "struct"
  "interface"
] @keyword.type.struct

"package" @keyword.package
