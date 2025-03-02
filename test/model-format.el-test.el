
(require 'prisma-ts-mode)

(ert-deftest format-model-simple-default-indent ()
  (let ((expected "
model User {
  id    Int     @id @default(autoincrement())
  email String  @unique
  name  String?
  posts Post[]
}
"))
    (with-temp-buffer
     (insert-file-contents "test/simple.prisma")
     (forward-line 2)
     (prisma-ts-mode)
     (prisma-format-declaration)
     (should (equal (buffer-string) expected)))))

(ert-deftest format-model-simple-4-indent ()
  (let ((expected "
model User {
    id    Int     @id @default(autoincrement())
    email String  @unique
    name  String?
    posts Post[]
}
")
        (prisma-ts-mode-indent-level 4))
    (with-temp-buffer
     (insert-file-contents "test/simple.prisma")
     (forward-line 2)
     (prisma-ts-mode)
     (prisma-format-declaration)
     (should (equal (buffer-string) expected)))))

(ert-deftest format-model-chunks ()
  (let ((expected "
model Post {
  id Int @id @default(autoincrement())

  title     String
  content   String?
  published Boolean @default(false)

  author   User? @relation(fields: [authorId], references: [id])
  authorId Int?
}
"))
    (with-temp-buffer
     (insert-file-contents "test/chunks.prisma")
     (forward-line 2)
     (prisma-ts-mode)
     (prisma-format-declaration)
     (should (equal (buffer-string) expected)))))


(ert-deftest format-model-comments ()
  (let ((expected "
model Post {
  id        Int     @id @default(autoincrement())
  // commented Int
  title     String
  content   String?
  published Boolean @default(false) // comment foo
  author    User?   @relation(fields: [authorId], references: [id])
  authorId  Int?
}
"))
    (with-temp-buffer
     (insert-file-contents "test/comments.prisma")
     (forward-line 2)
     (prisma-ts-mode)
     (prisma-format-declaration)
     (should (equal (buffer-string) expected)))))


(ert-deftest format-enum ()
  (let ((expected "
enum FooEnum {
  FOO
  BAR
  BAZ
}
"))
    (with-temp-buffer
     (insert-file-contents "test/enum.prisma")
     (forward-line 2)
     (prisma-ts-mode)
     (prisma-format-declaration)
     (should (equal (buffer-string) expected)))))


(ert-deftest format-datasource ()
  (let ((expected "
datasource db {
  provider = \"postgresql\"
  url      = env(\"DATABASE_URL\")
}
"))
    (with-temp-buffer
     (insert-file-contents "test/datasource.prisma")
     (forward-line 2)
     (prisma-ts-mode)
     (prisma-format-declaration)
     (should (equal (buffer-string) expected)))))
