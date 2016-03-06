new File('aur-packages').eachLine { line ->
	job(line) {
		scm {
			git("https://aur.archlinux.org/${line}")
		}
		steps {
			println("makechrootpkg -c -r /mnt/aur/build_test")
		}
	}
}
