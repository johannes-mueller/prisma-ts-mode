
(require 'prisma-ts-mode)

(ert-deftest format-simple-default-indent ()
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
     (prisma-format-model)
     (should (equal (buffer-string) expected)))))

(ert-deftest format-simple-4-indent ()
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
     (prisma-format-model)
     (should (equal (buffer-string) expected)))))

(ert-deftest format-chunks ()
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
     (prisma-format-model)
     (should (equal (buffer-string) expected)))))


(ert-deftest format-comments ()
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
     (prisma-format-model)
     (should (equal (buffer-string) expected)))))
