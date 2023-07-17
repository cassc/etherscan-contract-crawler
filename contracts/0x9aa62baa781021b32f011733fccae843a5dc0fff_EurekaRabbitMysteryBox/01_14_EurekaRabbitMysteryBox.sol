// SPDX-License-Identifier: MIT
/**
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣾⣦⡙⢿⣷⣦⡀⠀⠀⣠⣴⣦⡒⢶⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣿⡗⣹⡿⠁⣰⢸⣿⣿⣿⣿⢆⡿⡁⣱⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⢏⣼⡟⠁⣼⣿⡆⣿⣿⣿⢣⣾⠀⠸⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣏⡺⢿⣷⣄⠙⢿⡃⣿⣿⣿⣦⣝⠳⡄⠘⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣶⣍⢻⡷⠀⡁⢿⣿⣿⣿⣿⠃⢁⣴⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡇⠋⢠⣾⡇⠈⢿⣿⣿⠏⣠⣾⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⡿⢀⣴⣿⣿⣷⣶⣶⣶⣶⣶⣶⣭⣭⣃⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣷⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣦⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⢋⢉⣍⠻⣿⡟⡛⠳⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣔⢥⡻⣿⣷⣌⠘⣱⣿⡎⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣌⠪⡻⣿⣿⣿⢋⣾⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢋⢜⣴⣿⣿⣿⣷⡙⢿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣟⠱⡱⢿⣿⠟⡑⢌⢻⡟⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣮⣀⣡⣾⣿⣦⣤⠞⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣤⣤⣭⣭⣭⣭⣭⣭⣭⣭⣭⣭⣭⣭⣤⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠻⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠿⠿⠿⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣶⣦⡀⠀⠀⣸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣶⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡿⣠⣴⣿⡟⣸⣿⣿⣿⣿⠸⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⠟⠁⣼⣿⣿⣿⡇⢿⣿⣿⣿⣿⣷⣝⠿⣿⣿⣿⣿⣿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⡘⣿⣿⣿⣿⡿⢋⣾⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣷⣌⠻⢟⣫⣴⣿⣿⣿⣿⢏⣿⣿⣿⣿⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠿⣿⣿⣿⣶⣝⡻⠿⠿⠿⢛⣡⣾⣿⠿⠟⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢠⣤⣤⣤⣤⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣤⡄⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣬⣍⠉⣭⣤⣦⣤⣄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣤⡄⠀⠀⠀⠀⠀⠀⣤⡄⠀⠀⠀⠀⠀⠀⢠⣤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢸⣿⠉⠉⠉⠁⠀⢀⡀⠀⠀⠀⣀⠀⠀⢀⡀⠀⣀⠀⠀⠀⣀⣀⡀⠀⠀⢸⣿⡇⠀⠀⢀⡀⠀⠀⢀⣿⣿⣿⣿⣿⣿⣿⣛⣀⣿⣿⣏⣉⡙⣿⣧⠀⠀⠀⣀⣀⡀⠀⠀⢸⣿⡇⢀⣀⡀⠀⠀⠀⣿⡇⠀⣀⣀⠀⠀⠀⢀⡀⠀⢀⣸⣿⢀⡀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢸⣿⣤⣤⣤⠀⠀⣿⣿⠀⠀⢸⣿⡇⠀⢹⣿⡾⠛⠃⣰⣿⠛⠛⢿⣦⠀⢸⣿⡇⢀⣾⠟⠁⢀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣎⣿⣿⣿⡟⠀⠰⠿⠛⠙⣿⣆⠀⢸⣿⡷⠛⠛⢿⣷⡀⠀⣿⣷⠟⠛⠻⣿⡄⠀⢸⣿⠀⠛⣿⣿⠛⠃⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢸⣿⠉⠉⠉⠀⠀⣿⣿⠀⠀⢸⣿⡇⠀⢸⣿⠀⠀⠀⣿⣷⠶⠶⠾⠿⠆⢸⣿⣷⣿⣇⠀⠀⢘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⣻⣿⡿⠀⠀⣠⣴⠶⠶⢿⣿⠀⢸⣿⡇⠀⠀⠈⣿⡇⠀⣿⡇⠀⠀⠀⣿⣿⠀⢸⣿⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢸⣿⣀⣀⣀⣀⠀⢻⣿⣀⣀⣼⣿⡇⠀⢸⣿⠀⠀⠀⢻⣿⣀⢀⣠⣤⠀⢸⣿⡇⠈⢿⣧⡀⢸⣿⣄⢀⣸⣿⡇⠀⠀⠀⠀⠀⣿⣿⠀⠀⠻⣿⣄⠀⣿⣯⡀⣀⣿⣿⠀⢸⣿⣧⣀⣀⣸⣿⠃⠀⣿⣷⣀⣀⣠⣿⠏⠀⢸⣿⠀⠀⢿⣿⣀⡀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠘⠛⠛⠛⠛⠋⠀⠀⠙⠛⠋⠁⠛⠃⠀⠘⠛⠀⠀⠀⠀⠉⠛⠛⠋⠁⠀⠈⠛⠃⠀⠀⠛⠛⠀⠙⠛⠛⠉⠛⠁⠀⠀⠀⠀⠀⠛⠋⠀⠀⠀⠙⠛⠂⠈⠛⠛⠋⠙⠛⠀⠘⠛⠉⠙⠛⠋⠁⠀⠀⠛⠃⠙⠛⠛⠉⠀⠀⠘⠛⠀⠀⠈⠛⠛⠃⠀⠀⠀⠀⠀⠀
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./utils/TimeUtil.sol";

interface ERC721Interface {
    function mintTransfer(address to) external returns(uint256);
}


/**
    code    |	 meaning
    400	    |    Invalid params
    404	    |    TokenId nonexistent
    100	    |    Finalised
    101	    |    Ether value sent is not correct
    102	    |    Purchase would exceed max tokens
    103	    |    It's not the time for mint white
    104	    |    It's not the time for mint public
    105	    |    It's not the time for free mint
    106	    |    Over the whitelist maximum can be purchased
    107	    |    Over the maximum can be purchased
    108	    |    Over the free mint maximum can be purchased
    109	    |    Free mint slots have been used up
    110	    |    Reserved mint slots have been used up
    111	    |    Migration has not started
    112	    |    Doesn't own the token
 */
contract EurekaRabbitMysteryBox is ERC1155, Ownable, ERC1155Burnable {
    using ECDSA for bytes32;

    // Sale Stage configuration
    enum Status {
        Pending,
        White,
        Public
    }

    Status public status;

    // Open box of switch
    bool    public      migrationStarted = false;
    uint16  constant    public TOTAL_COUNT = 3261;      // The max tokens count
    uint16  public white_max_mint_count = 2;            // The maximum number of white mint
    uint16  public public_max_mint_count = 1;           // The maximum number of public mint
    uint16  public free_max_mint_count = 1;             // The maximum number of free mint
    uint256 public availableCountReserved = 600;        // available count of reserved
    uint256 public availableCountFreeMint = 161;        // available count of free mint

    uint256 public tokenId = 0;
    uint256 public amountMinted = 0;
    uint256 public freeMintStartTime = 0;
    uint256 public freeMintEndTime = 0;
    uint256 public mintPrice;

    mapping (address => uint) public numberMintedPublic;
    mapping (address => uint) public numberMintedWhite;
    mapping (address => uint) public numberMintedFree;
    address private whiteSigner;
    address private freeSigner;

    // the NFT contract address
    ERC721Interface rabbitContractAddress;

    event priceChanged(uint256 newPrice);
    /******************************************************* constructor *******************************************************/
    constructor(address contractAddress, address _whiteSigner, address _freeSigner)
    ERC1155("ipfs://QmQHJLjUf6K2dBaETQWM9p52VRihtFuC4QSPNn5LbJPAAx") {
        require(contractAddress != address(0) && _whiteSigner != address(0) && _freeSigner != address(0), "400");
        rabbitContractAddress = ERC721Interface(contractAddress);
        whiteSigner = _whiteSigner;
        freeSigner = _freeSigner;
    }

    /******************************************************* config funs *******************************************************/
    // Authorize specific smart contract to be used for minting an ERC-1155 token
    function toggleMigration(bool newStatus) external onlyOwner {
        migrationStarted = newStatus;
    }

    // Set authorized contract address for minting the ERC-721 token
    function setRabbitContract(address contractAddress) external onlyOwner {
        rabbitContractAddress = ERC721Interface(contractAddress);
    }

    // Used for manual activation on dutch auction, GWei
    function setPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice * 10**9;
        emit priceChanged(mintPrice);
    }

    function setMaxCount(uint16 _white, uint16 _public, uint16 _free) external onlyOwner {
        public_max_mint_count = _public;
        white_max_mint_count = _white;
        free_max_mint_count = _free;
    }

    function setWhiteSigner(address newSigner) external onlyOwner {
        require(newSigner != address(0), "400");
        whiteSigner = newSigner;
    }

    function setFreeSigner(address newSigner) external onlyOwner {
        require(newSigner != address(0), "400");
        freeSigner = newSigner;
    }

    // Sale Stage and set price, GWei
    function setStatusAndPrice(Status newMintStatus, uint newMintPrice) external onlyOwner {
        status = newMintStatus;
        mintPrice = newMintPrice * 10**9;
        emit priceChanged(mintPrice);
    }

    function setFreeMintTime(uint newStartTime, uint newEndTime) external onlyOwner {
        freeMintStartTime = newStartTime;
        freeMintEndTime = newEndTime;
    }

    /******************************************************* external funs *******************************************************/
    // get tokenId & amount
    function getBalanceInfo(address addr) external view returns(uint[] memory tokenIds, uint[] memory amounts) {
        uint totalCount = tokenId;
        tokenIds = new uint[](totalCount);
        amounts = new uint[](totalCount);
        uint count = 0;
        for (uint i = 1; i <= totalCount; i++) {
            uint b = balanceOf(addr, i);
            if (b > 0) {
                tokenIds[count] = i;
                amounts[count++] = b;
            }
        }
        if (count < amountMinted) {
            uint[] memory realTokenIds = new uint[](count);
            uint[] memory realAmounts = new uint[](count);
            for (uint index = 0; index < count; index++) {
                realTokenIds[index] = tokenIds[index];
                realAmounts[index] = amounts[index];
            }
            tokenIds = realTokenIds;
            amounts = realAmounts;
        }
    }

    /******************************************************* modifiers *******************************************************/
    modifier pubMintCheck(uint256 amount) {
        require(amount > 0, "400");
        require(msg.value == mintPrice * amount, "101");
        /**
        * amountMinted + amount <= (TOTAL_COUNT - 600 - 161) + (600 - availableCountReserved) + (161 - availableCountFreeMint)
        */
        require(amountMinted + amount <= TOTAL_COUNT - availableCountReserved - availableCountFreeMint, "102");
        _;
    }

    /******************************************************* mint funs *******************************************************/
    //The white mint. You should get whitelist rights first
    function whiteMint(uint256 amount, string calldata salt, bytes memory token) external payable pubMintCheck(amount) {
        require(status == Status.White, "103");
        require(_recover(_hash(salt, msg.sender), token) == whiteSigner, "400");
        require(numberMintedWhite[msg.sender] + amount <= white_max_mint_count, "106");
        tokenId++;
        amountMinted += amount;
        numberMintedWhite[msg.sender] += amount;
        _mint(msg.sender, tokenId, amount, "");
    }

    // Mint function
    function mint(uint256 amount) external payable pubMintCheck(amount) {
        require(status == Status.Public, "104");
        require(numberMintedPublic[msg.sender] + amount <= public_max_mint_count, "107");
        tokenId++;
        amountMinted += amount;
        numberMintedPublic[msg.sender] += amount;
        _mint(msg.sender, tokenId, amount, "");
    }

    function freeMint(uint256 amount, string calldata salt, bytes memory token) external {
        require(TimeUtil.currentTime() >= freeMintStartTime && TimeUtil.currentTime() <= freeMintEndTime, "105");
        require(_recover(_hash(salt, msg.sender), token) == freeSigner, "400");
        require(numberMintedFree[msg.sender] + amount <= free_max_mint_count, "108");
        require(amount <= availableCountFreeMint, "109");

        tokenId++;
        amountMinted += amount;
        numberMintedFree[msg.sender] += amount;
        availableCountFreeMint -= amount;
        _mint(msg.sender, tokenId, amount, "");
    }

    // Allowing direct drop for giveaway
    function airdropGiveaway(address[] calldata to, uint256[] calldata amountToMint) external onlyOwner {
        require(to.length == amountToMint.length, "400");
        uint tempTokenId = tokenId;
        uint tempAmountMinted = amountMinted;
        for(uint256 i = 0; i < to.length; i++) {
            tempTokenId++;
            tempAmountMinted += amountToMint[i];
            _mint(to[i], tempTokenId, amountToMint[i], "");
        }
        require(tempAmountMinted <= TOTAL_COUNT - availableCountReserved - availableCountFreeMint, "102");
        tokenId = tempTokenId;
        amountMinted = tempAmountMinted;
    }

    // Allowing direct drop for giveaway
    function airdropGiveawayReserve(address[] calldata to, uint256[] calldata amountToMint) external onlyOwner {
        require(to.length == amountToMint.length, "400");
        uint tempTokenId = tokenId;
        uint tempAmountMinted = amountMinted;
        uint tempAvailableCountReserved = availableCountReserved;
        for(uint256 i = 0; i < to.length; i++) {
            tempTokenId++;
            require(amountToMint[i] <= tempAvailableCountReserved, "110");
            tempAmountMinted += amountToMint[i];
            tempAvailableCountReserved -= amountToMint[i];
            _mint(to[i], tempTokenId, amountToMint[i], "");
        }
        tokenId = tempTokenId;
        amountMinted = tempAmountMinted;
        availableCountReserved = tempAvailableCountReserved;
    }
    // Allowing direct drop for giveaway
    function airdropGiveawayFree(address[] calldata to, uint256[] calldata amountToMint) external onlyOwner {
        require(to.length == amountToMint.length, "400");
        uint tempTokenId = tokenId;
        uint tempAmountMinted = amountMinted;
        uint tempAvailableCountFree = availableCountFreeMint;
        for(uint256 i = 0; i < to.length; i++) {
            tempTokenId++;
            require(amountToMint[i] <= tempAvailableCountFree, "110");
            tempAmountMinted += amountToMint[i];
            tempAvailableCountFree -= amountToMint[i];
            _mint(to[i], tempTokenId, amountToMint[i], "");
        }
        tokenId = tempTokenId;
        amountMinted = tempAmountMinted;
        availableCountFreeMint = tempAvailableCountFree;
    }

    /******************************************************* publish *******************************************************/
    // Allow to use the ERC-1155 to get the Eureka Rabbit ERC-721 final token
    function migrateToken(uint256 id) external returns(uint256) {
        require(migrationStarted, "111");
        require(balanceOf(msg.sender, id) > 0, "112"); // Check if the user own one of the ERC-1155
        burn(msg.sender, id, 1); // Burn one the ERC-1155 token
        uint256 mintedId = rabbitContractAddress.mintTransfer(msg.sender); // Mint the ERC-721 token
        return mintedId; // Return the minted ID
    }

    /******************************************************* other *******************************************************/

    // Get amount of 1155 minted
    function getAmountMinted() external view returns(uint256) {
        return amountMinted;
    }

    // Basic withdrawal of funds function in order to transfer ETH out of the smart contract
    function withdrawFunds() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    // tools
    function _hash(string calldata salt, address _address) private view returns (bytes32) {
        return keccak256(abi.encode(salt, address(this), _address));
    }
    function _recover(bytes32 hash, bytes memory token) private pure returns (address) {
        return hash.toEthSignedMessageHash().recover(token);
    }
}