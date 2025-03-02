
(require 'prisma-ts-mode)

(defun buffer-test-string (first last)
  (goto-char (point-min))
  (forward-line (1- first))
  (let ((start (point)))
    (forward-line (- last first))
    (buffer-substring (1- start) (1+ (point)))))

(ert-deftest format-model-simple-default-indent ()
  (let ((expected "
model User {
  id    Int     @id @default(autoincrement())
  email String  @unique
  name  String?
  posts Post[]
}"))
    (with-temp-buffer
     (insert-file-contents "test/schema.prisma")
     (forward-line 8)
     (prisma-ts-mode)
     (prisma-format-declaration)
     (should (equal (buffer-test-string 7 12) expected)))))


(ert-deftest format-model-simple-4-indent ()
  (let ((expected "
model User {
    id    Int     @id @default(autoincrement())
    email String  @unique
    name  String?
    posts Post[]
}")
        (prisma-ts-mode-indent-level 4))
    (with-temp-buffer
     (insert-file-contents "test/schema.prisma")
     (forward-line 8)
     (prisma-ts-mode)
     (prisma-format-declaration)
     (should (equal (buffer-test-string 7 12) expected)))))


(ert-deftest format-model-chunks ()
  (let ((expected "
model Post {
  id Int @id @default(autoincrement())

  title     String
  content   String?
  published Boolean @default(false)

  author   User? @relation(fields: [authorId], references: [id])
  authorId Int?
}"))
    (with-temp-buffer
     (insert-file-contents "test/schema.prisma")
     (forward-line 23)
     (prisma-ts-mode)
     (prisma-format-declaration)
     (should (equal (buffer-test-string 20 29) expected)))))


(ert-deftest format-model-comments ()
  (let ((expected "
model PostComment {
  id        Int     @id @default(autoincrement())
  // commented Int
  title     String
  content   String?
  published Boolean @default(false) // comment foo
  author    User?   @relation(fields: [authorId], references: [id])
  authorId  Int?
}"))
    (with-temp-buffer
     (insert-file-contents "test/schema.prisma")
     (forward-line 33)
     (prisma-ts-mode)
     (prisma-format-declaration)
     (should (equal (buffer-test-string 31 39) expected)))))


(ert-deftest format-enum ()
  (let ((expected "
enum FooEnum {
  FOO
  BAR
  BAZ
}"))
    (with-temp-buffer
     (insert-file-contents "test/schema.prisma")
     (forward-line 16)
     (prisma-ts-mode)
     (prisma-format-declaration)
     (should (equal (buffer-test-string 14 18) expected)))))


(ert-deftest format-datasource ()
  (let ((expected "
datasource db {
  provider = \"postgresql\"
  url      = env(\"DATABASE_URL\")
}"))
    (with-temp-buffer
     (insert-file-contents "test/schema.prisma")
     (forward-line 2)
     (prisma-ts-mode)
     (prisma-format-declaration)
     (should (equal (buffer-test-string 2 5) expected)))))


(ert-deftest format-model-linebreak ()
  (let ((expected "
model UserLineBreak {
  id    Int     @id
                @default(autoincrement())
  email String  @unique
                @db.VarChar(3000)
  name  String?
  posts Post[]
}"))
    (with-temp-buffer
     (insert-file-contents "test/schema.prisma")
     (forward-line 43)
     (prisma-ts-mode)
     (prisma-format-declaration)
     (should (equal (buffer-test-string 41 48) expected)))))


(ert-deftest format-view ()
  (let ((expected "
view UserView {
  id    Int     @id @default(autoincrement())
  email String  @unique
  name  String?
  posts Post[]
}"))
    (with-temp-buffer
     (insert-file-contents "test/schema.prisma")
     (forward-line 52)
     (prisma-ts-mode)
     (prisma-format-declaration)
     (should (equal (buffer-test-string 50 55) expected)))))


(ert-deftest format-generator ()
  (let ((expected "
generator client {
  provider        = \"prisma-client-js\"
  previewFeatures = [\"sample-preview-feature\"]
  binaryTargets   = [\"linux-musl\"]
}"))
    (with-temp-buffer
     (insert-file-contents "test/schema.prisma")
     (forward-line 59)
     (prisma-ts-mode)
     (prisma-format-declaration)
     (should (equal (buffer-test-string 57 61) expected)))))
