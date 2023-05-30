pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

/*


     #####   ##    ##        ###                                                        #####   ##    ##              /                           
  ######  /#### #####    #    ###                                                    ######  /#### #####            #/                            
 /#   /  /  ##### ##### ###    ##                                                   /#   /  /  ##### #####          ##                            
/    /  /   # ##  # ##   #     ##                                                  /    /  /   # ##  # ##           ##                            
    /  /    #     #            ##                                                      /  /    #     #              ##                            
   ## ##    #     #    ###     ##      /###     /###     /###    ##   ####            ## ##    #     #      /###    ##  /##      /##  ###  /###   
   ## ##    #     #     ###    ##     / ###  / / ###  / /  ###  / ##    ###  /        ## ##    #     #     / ###  / ## / ###    / ###  ###/ #### /
   ## ##    #     #      ##    ##    /   ###/ /   ###/ /    ###/  ##     ###/         ## ##    #     #    /   ###/  ##/   /    /   ###  ##   ###/ 
   ## ##    #     #      ##    ##   ##    ## ##    ## ##     ##   ##      ##          ## ##    #     #   ##    ##   ##   /    ##    ### ##        
   ## ##    #     ##     ##    ##   ##    ## ##    ## ##     ##   ##      ##          ## ##    #     ##  ##    ##   ##  /     ########  ##        
   #  ##    #     ##     ##    ##   ##    ## ##    ## ##     ##   ##      ##          #  ##    #     ##  ##    ##   ## ##     #######   ##        
      /     #      ##    ##    ##   ##    ## ##    ## ##     ##   ##      ##             /     #      ## ##    ##   ######    ##        ##        
  /##/      #      ##    ##    ##   ##    ## ##    ## ##     ##   ##      ##         /##/      #      ## ##    /#   ##  ###   ####    / ##        
/  #####           ##   ### / ### / ######   ######   ########    #########        /  #####           ## ####/ ##  ##   ### / ######/  ###       
/     ##                  ##/   ##/   ####     ####      ### ###     #### ###      /     ##                ###   ##  ##   ##/   #####    ###      
#                                                             ###          ###     #                                                              
 ##                                                     ####   ###  #####   ###     ##                                                            
                                                      /######  /# /#######  /#                                                                    
                                                     /     ###/  /      ###/                                                        
                

                                  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣾⣿⣷⣶⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
                                  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠿⣿⣿⣿⣿⣿⣿⣶⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
                                  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣠⣤⣴⣶⣾⣿⣷⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠙⠻⢿⣿⣿⣿⣿⣷⣦⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀
                                  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠻⢿⣿⣿⣿⣿⣦⡀⠀⠀⠀⠀⠀⠀
                                  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣾⣿⣿⣿⣿⣿⡿⠿⠟⠛⠉⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠻⣿⣿⣿⣆⠀⠀⠀⠀⠀
                                  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⣿⡿⠟⠋⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⣿⣿⣧⠀⠀⠀⠀
                                  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣿⣿⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢻⣿⣇⠀⠀⠀
                                  ⠀⠀⠀⠀⠀⠀⠀⣠⣾⣿⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣶⣿⣿⣿⣿⣿⣿⣿⣶⣤⡀⠀⠙⠋⠀⠀⠀
                                  ⠀⠀⠀⠀⠀⣠⣾⣿⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣤⣾⠟⢋⣥⣤⠀⣶⣶⣶⣦⣤⣌⣉⠛⠀⠀⠀⠀⠀⠀
                                  ⠀⠀⠀⠀⣴⣿⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠋⢁⣴⣿⣿⡿⠀⣿⣿⣿⣿⣿⣿⣿⣷⡄⠀⠀⠀⠀⠀
                                  ⠀⠀⠀⣼⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣤⣤⣶⣶⣾⣿⣿⣿⣿⣷⣶⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣿⣿⣿⠁⠀⠀⢹⣿⣿⣿⣿⣿⣿⢻⣿⡄⠀⠀⠀⠀
                                  ⠀⠀⠀⠛⠋⠀⠀⠀⠀⠀⠀⠀⢀⣤⣾⣿⠿⠛⣛⣉⣉⣀⣀⡀⠀⠀⠀⠀⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⣿⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⢸⣿⣿⡄⠀⠀⠀
                                  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣾⡿⢋⣩⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣶⣦⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⣿⣦⣀⣀⣴⣿⣿⣿⣿⣿⡿⢸⣿⢿⣷⡀⠀⠀
                                  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣡⣄⠀⠋⠁⠀⠈⠹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⡟⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⢸⡿⠀⠛⠃⠀⠀
                                  ⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⣿⣧⡀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠛⠛⠃⢹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠁⠈⠁⠀⠀⠀⠀⠀
                                  ⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⣿⢿⣿⣿⣿⣷⣦⣤⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣶⣶⠀⠈⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⣿⠇⠀⠀⠀⠀⠀
                                  ⠀⠀⠀⠀⠀⢠⣿⣿⣿⠟⠉⠀⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⠀⠀⢹⣿⣿⣿⣿⣿⣿⣿⣿⣿⠁⢸⣿⠀⠀⠀⠀⠀⠀
                                  ⠀⠀⠀⠀⠀⣼⣿⡟⠁⣠⣦⠀⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠉⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⡆⠀⠀⢻⣿⣿⣿⣿⣿⣿⣿⠏⠀⣸⡏⠀⠀⠀⠀⠀⠀
                                  ⠀⠀⠀⠀⠀⣿⡏⠀⠀⣿⣿⡀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠀⢹⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⣇⠀⠀⠀⠙⢿⣿⣿⡿⠟⠁⠀⣸⡿⠁⠀⠀⠀⠀⠀⠀
                                  ⠀⠀⠀⠀⢸⣿⠁⠀⠀⢸⣿⣇⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠁⠀⢀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢿⣦⡀⠀⠀⠀⠈⠉⠀⠀⠀⣼⡿⠁⠀⠀⠀⠀⠀⠀⠀
                                  ⠀⠀⠀⠀⠈⠁⠀⠀⠀⠀⢿⣿⡄⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⣼⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣷⣦⣄⣀⠀⠀⢀⡈⠙⠁⠀⠀⠀⠀⠀⠀⠀⠀
                                  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢻⣿⣆⠀⠀⠀⠉⠛⠿⢿⣿⣿⠿⠛⠁⠀⠀⠀⣠⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠿⣿⣿⣷⣿⣯⣤⣶⠄⠀⠀⠀⠀⠀⠀⠀
                                  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⣿⣷⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠙⠛⠋⠁⠀⠀⠀⠀⠀⠀⠀
                                  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⢿⣷⣤⣀⠀⠀⠀⠀⠀⠀⠀⠺⣿⣿⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
                                  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⢻⣿⣶⣤⣤⣤⣶⣷⣤⠈⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
                                  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢿⣿⣿⣿⣿⡿⠿⠛⠋⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
                                  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
                                  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
                                  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
                                  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠶⢤⣄⣀⣀⣤⠶⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀


                                  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
                                                                                                                                                  */

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./auth/Ownable.sol";
import './utils/Base64.sol';
import "./utils/MerkleProofLib.sol";
import './utils/HexStrings.sol';
import './ToColor.sol';

abstract contract NFTContract {
  function renderTokenByIdBack(uint256 id) external virtual view returns (string memory);
  function renderTokenByIdFront(uint256 id) external virtual view returns (string memory);
  function renderTokenById(uint256 id) external virtual view returns (string memory);
  function transferFrom(address from, address to, uint256 id) external virtual;
  function getTraits(uint256 id) external virtual view returns(string memory);
}

contract Miloogys is ERC721Enumerable, IERC721Receiver, Ownable {

  using Strings for uint256;
  using HexStrings for uint160;
  using ToColor for bytes3;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  uint256 public constant limit = 1436; //i love you milady
  uint public constant freeLimit = 656; //loogie loves milady
  uint public freeMints;
  uint256 public price = 0.008 ether;
  NFTContract[] public nftContracts;
  mapping (uint256 => bytes3) public race;
  mapping (uint256 => bytes3) public eyeColor;
  mapping (uint256 => uint256) public bmi;
  mapping (address => bool) nftContractsAvailables;
  mapping (address => mapping(uint256 => uint256)) nftById;
  mapping (address => bool) public freeMintUsed;
  bool minting;
  bytes32 merkleRoot;

  constructor(address owner_, bytes32 merkleRoot_) ERC721("miloogymaker", "miloogy") {
    _initializeOwner(owner_);
    merkleRoot = merkleRoot_;
  }

  function setMinting(bool toggleMint) public onlyOwner {
    minting = toggleMint;
  }

  function mintItem()
      public
      payable
      returns (uint256)
  {
    require(msg.value >= price, "NOT ENOUGH");
    return(_mintMiloogy(msg.sender));
  }

  function _mintMiloogy(address sender) internal returns(uint){
    require(_tokenIds.current() < limit, "DONE MINTING");
    require(minting, "not minting");
    _tokenIds.increment();
    uint256 id = _tokenIds.current();
    _mint(sender, id);
    bytes32 predictableRandom = keccak256(abi.encodePacked( id, blockhash(block.number-1), sender, address(this) ));
    race[id] = bytes2(predictableRandom[3]) | ( bytes2(predictableRandom[4]) >> 8 ) | ( bytes3(predictableRandom[5]) >> 16 );
    eyeColor[id] = bytes2(predictableRandom[0]) | ( bytes2(predictableRandom[1]) >> 8 ) | ( bytes3(predictableRandom[2]) >> 16 );
    bmi[id] = 1+((40*uint256(uint8(predictableRandom[6])))/255);
    return id;
  }

  function mintMultiple(uint qty) public payable { 
    require(msg.value >= price * qty, "NOT ENOUGH");
    for(uint i = 0; i < qty; i++) {
      _mintMiloogy(msg.sender);
    }
  }

  function freeMint(bytes32[] calldata merkleProof) public returns(uint){
    require(MerkleProofLib.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "invalid merkle proof");
    require(!freeMintUsed[msg.sender], "freemint used");
    require(freeMints < freeLimit, "no more free mints");
    freeMints++;
    freeMintUsed[msg.sender] = true;
    return(_mintMiloogy(msg.sender));
  }

  function withdraw() public onlyOwner {
      (bool success, ) = owner().call{value: address(this).balance}("");
      require(success, "could not send");
  }

  function tokenURI(uint256 id) public view override returns (string memory) {
      require(_exists(id), "not exist");
      string memory name = string(abi.encodePacked('miloogy #',id.toString()));
      string memory description = string(abi.encodePacked('This miloogy is race #',race[id].toRace(), ' with pigment ', race[id].toPigment().toString(), ', a bmi of ',uint2str(bmi[id]), ', and an eye color of #', eyeColor[id].toColor()));
      string memory image = Base64.encode(bytes(generateSVGofTokenById(id)));
      string memory traits;
      for (uint i=0; i<nftContracts.length; i++) {
      if (nftById[address(nftContracts[i])][id] > 0) {
        traits = string(abi.encodePacked(traits, ',', nftContracts[i].getTraits(nftById[address(nftContracts[i])][id])));
      }
    }

      return
        string(
          abi.encodePacked(
            'data:application/json;base64,',
            Base64.encode(
              bytes(
                abi.encodePacked(
                  '{"name":"',
                  name,
                  '", "description":"',
                  description,
                  '", "external_url":"https://miloogymaker.net/token/',
                  id.toString(),
                  '", "attributes": [{"trait_type": "race", "value": "#',
                  race[id].toRace(),
                  '"},{"trait_type": "pigmnet", "value": ',
                  race[id].toPigment().toString(),
                  '},{"trait_type": "bmi", "value": ',
                  uint2str(bmi[id]),
                  '},{"trait_type": "eye color", "value": "#',
                  eyeColor[id].toColor(),
                  '"}',
                  traits,
                  '], "owner":"',
                  (uint160(ownerOf(id))).toHexString(20),
                  '", "image": "',
                  'data:image/svg+xml;base64,',
                  image,
                  '"}'
                )
              )
            )
          )
        );
  }

  function generateSVGofTokenById(uint256 id) internal view returns (string memory) {

    string memory svg = string(abi.encodePacked(
      '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
        renderTokenById(id),
      '</svg>'
    ));

    return svg;
  }

  // Visibility is `public` to enable it being called by other contracts for composition.
  function renderTokenById(uint256 id) public view returns (string memory) {
    
    string memory render;

    for (uint i=0; i<nftContracts.length; i++) {
      if (nftById[address(nftContracts[i])][id] > 0) {
        render = string(abi.encodePacked(render, nftContracts[i].renderTokenByIdBack(nftById[address(nftContracts[i])][id])));
      }
    }

    render = string(abi.encodePacked(render, string(abi.encodePacked(
      '<g id="headline" fill="#fff">',
        '<ellipse cx="222" cy="144"  rx="',
        (bmi[id]+74).toString(),
        '" ry="90"/>',
        '<ellipse cx="155" cy="202"  rx="75" ry="14" transform="rotate(22,155,202)"/>',
        '<ellipse cx="159" cy="165"  rx="75" ry="22" transform="rotate(-7,159,165)"/>',
      '</g>',
      '<g id="headfill" fill="#',
      race[id].toRace(),
      '" opacity=".',
      race[id].toPigment().toString(),
      '">',
        '<ellipse cx="222" cy="144"  rx="',
        (bmi[id]+74).toString(),
        '" ry="90" />',
        '<ellipse cx="155" cy="202"  rx="75" ry="14" transform="rotate(22,155,202)"/>',
        '<ellipse cx="159" cy="165"  rx="75" ry="22" transform="rotate(-7,159,165)"/>',
      '</g>',
      '<g id="eyewhites" fill="#fff">',
        '<ellipse  cx="178" cy="173" rx="12" ry="20" transform="rotate(-43,178,173)"/>',
        '<ellipse  cx="188" cy="167" rx="17" ry="22"/>',
        '<ellipse  cx="281" cy="155" rx="8" ry="21" transform="rotate(9,281,155)"/>',
        '<ellipse  cx="270" cy="150" rx="10" ry="21"/>',
      '</g>',
      '<g id="eyecolor" stroke="#',
      eyeColor[id].toColor(),
      '" >',
        '<line x1="172" y1="155" x2="192" y2="187" stroke-width="12" />',
        '<line x1="261" y1="149" x2="273" y2="170" stroke-width="11" />',
      '</g>',
      '<g id="eyes" transform="translate(65,270) scale(0.1,-0.1)" fill="#000000" >',
        '<path d="M1978 1449 c-27 -17 -48 -38 -48 -45 0 -19 15 -18 48 4 25 16 24 13 ',
        '-9 -28 -53 -66 -60 -82 -65 -173 -7 -116 9 -173 61 -209 43 -29 159 -78 188 ',
        '-78 9 0 17 7 17 15 0 8 -7 15 -16 15 -9 0 -14 3 -12 8 2 4 15 30 29 57 27 51 ',
        '43 109 55 200 4 28 9 44 11 38 3 -7 12 -13 20 -13 19 0 12 34 -25 110 -14 30 ',
        '-25 65 -24 77 4 32 -43 53 -120 53 -54 0 -70 -5 -110 -31z m88 -94 c10 -16 14 ',
        '-34 10 -50 -15 -60 -73 -30 -60 30 11 54 24 59 50 20z m-109 -192 c-3 -10 -5 ',
        '-4 -5 12 0 17 2 24 5 18 2 -7 2 -21 0 -30z m43 -106 c0 -5 -7 -4 -15 3 -8 7 ',
        '-15 20 -15 29 1 13 3 13 15 -3 8 -11 15 -24 15 -29z m150 -3 c0 -8 -4 -14 -9 ',
        '-14 -11 0 -22 26 -14 34 9 9 23 -3 23 -20z m-67 -45 c-6 -6 -17 -8 -24 -3 -9 ',
        '5 -8 9 7 14 23 9 31 3 17 -11z"/>',
        '<path d="M1214 1356 c-71 -16 -131 -45 -158 -75 -19 -21 -19 -21 0 -21 11 0 ',
        '30 7 42 16 45 31 134 54 213 54 72 0 104 10 79 25 -22 14 -118 14 -176 1z"/>',
        '<path d="M1129 1280 c-48 -25 -146 -115 -164 -150 -20 -39 -30 -106 -16 -114 ',
        '6 -4 16 8 25 27 21 52 32 52 45 1 23 -91 57 -142 123 -187 35 -23 36 -25 16 ',
        '-30 -21 -6 -21 -7 -3 -27 23 -25 50 -25 128 1 74 25 118 64 148 133 18 43 21 ',
        '63 16 131 -3 44 -12 96 -20 115 -16 37 -67 90 -104 109 -36 18 -153 13 -194 ',
        '-9z m69 -72 c-3 -26 -42 -36 -68 -18 -13 9 -12 12 4 25 11 8 31 15 44 15 19 0 ',
        '23 -5 20 -22z m-45 -241 c15 -18 39 -31 75 -39 38 -10 52 -17 52 -30 0 -33 ',
        '-58 -22 -115 21 -57 43 -94 107 -103 176 -4 38 -3 37 32 -30 20 -39 47 -83 59 ',
        '-98z m214 -17 c2 -8 -2 -22 -7 -30 -9 -13 -11 -13 -20 0 -16 25 -12 52 7 48 ',
        '10 -2 19 -10 20 -18z"/>',
      '</g>'
      /*
      '<g class="mouth" transform="translate(',uint256((810-9*(bmi[id] + 34))/11).toString(),',0)">',
        '<path d="M 130 240 Q 165 250 ',mouthLength[id].toString(),' 235" stroke="black" stroke-width="3" fill="transparent"/>',
      '</g>'
      */
    ))));

    for (uint i=0; i<nftContracts.length; i++) {
      if (nftById[address(nftContracts[i])][id] > 0) {
        render = string(abi.encodePacked(render, nftContracts[i].renderTokenByIdFront(nftById[address(nftContracts[i])][id])));
      }
    }

    return render;
  }

  function addNft(address nft) public onlyOwner {
    nftContractsAvailables[nft] = true;
    nftContracts.push(NFTContract(nft));
  }

  function nftContractsCount() public view returns (uint256) {
    return nftContracts.length;
  }

  function getContractsAddress() public view returns (address[] memory) {
    address[] memory addresses = new address[](nftContracts.length);
    for (uint i=0; i<nftContracts.length; i++) {
      addresses[i] = address(nftContracts[i]);
    }
    return addresses;
  }

  function removeNftFromMiloogy(address nft, uint256 id) external {
    require(msg.sender == ownerOf(id), "only the owner can undress a miloogy!!");
    require(this.hasNft(nft, id), "the miloogy is not wearing this NFT");

    NFTContract nftContract = NFTContract(nft);
    _removeNftFromMiloogy(nftContract, id);
  }

  function downgradeMiloogy(uint256 id) external {
    require(msg.sender == ownerOf(id), "only the owner can downgrade a miloogy!!");

    // remove nft tokens from FancyMiloogy
    for (uint i=0; i<nftContracts.length; i++) {
      if (nftById[address(nftContracts[i])][id] > 0) {
        _removeNftFromMiloogy(nftContracts[i], id);
      }
    }
  }

  function _removeNftFromMiloogy(NFTContract nftContract, uint256 id) internal {
    nftContract.transferFrom(address(this), ownerOf(id), nftById[address(nftContract)][id]);

    nftById[address(nftContract)][id] = 0;
  }

  function hasNft(address nft, uint256 id) external view returns (bool) {
    require(nftContractsAvailables[nft], "the miloogys can't wear this NFT");

    return (nftById[nft][id] != 0);
  }

  function nftId(address nft, uint256 id) external view returns (uint256) {
    require(nftContractsAvailables[nft], "the miloogys can't wear this NFT");

    return nftById[nft][id];
  }

  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
      if (_i == 0) {
          return "0";
      }
      uint j = _i;
      uint len;
      while (j != 0) {
          len++;
          j /= 10;
      }
      bytes memory bstr = new bytes(len);
      uint k = len;
      while (_i != 0) {
          k = k-1;
          uint8 temp = (48 + uint8(_i - _i / 10 * 10));
          bytes1 b1 = bytes1(temp);
          bstr[k] = b1;
          _i /= 10;
      }
      return string(bstr);
  }

   // https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol#L374
  function _toUint256(bytes memory _bytes) internal pure returns (uint256) {
        require(_bytes.length >= 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(_bytes, 0x20))
        }

        return tempUint;
  }

   // to receive ERC721 tokens
  function onERC721Received(
      address /*operator*/,
      address from,
      uint256 tokenId,
      bytes calldata fancyIdData) external override returns (bytes4) {

      uint256 fancyId = _toUint256(fancyIdData);

      require(ownerOf(fancyId) == from, "you can only add stuff to a fancy miloogy you own.");
      require(nftContractsAvailables[msg.sender], "the miloogys can't wear this NFT");
      require(nftById[msg.sender][fancyId] == 0, "the miloogy already has this NFT!");

      nftById[msg.sender][fancyId] = tokenId;

      return this.onERC721Received.selector;
    }
}