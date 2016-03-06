new File('aur-packages').eachLine { line ->
	job(line) {
		scm {
			git("https://aur.archlinux.org/${line}")
		}
		steps {
			makechrootpkg -c -r "/mnt/aur/build_test"
		}
	}
}
