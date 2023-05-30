// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Synthetic Memories
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    X##=+XxxX+xXXXXXXx#X###;;=#X#XxX#X#X####x-##XX##X##XXxX+X###xx#######XXxX#xX##X##xX#XXXXXX#+xxxXXxxx    //
//    X##-=+;+x++XX#X#xxxXXx;-xXxXXxxx########x,X#X####Xx#X#Xx####x#############+##XxXxxX#Xxxxx#X+x+xXxxxx    //
//    X##==+=X#xx####xx++x+xx+##+xXxX+#####X###+XXXxX##+#xxx###XX###############xX#xxxXXxXxxXXXXxxxx#XXX#X    //
//    X##+=x=X#xXXx++xxXX#=-+;+XX##################XXXxx#++xXxx###xxX###XxxxX###xXX#####X#xxxxxxxx+#X#XXx#    //
//    X##+-x=##+-,=xxxxXXX=;X################################Xx++--;..X#x##Xx#XxXX###########XXXX+xXXxXx#X    //
//    X##X-Xx+;;..-xXXxxx########################################+-....Xx##X##X###X#############++XXXxxXXX    //
//    X###=x-.;-,.+-++xX###############XXxxxxxxxXxXX#################XxX#xx##x+++===.-##########+xXXXxX###    //
//    X###==;.==,.-=X###########XxxxxxxxxxxxxxxxxxxxxxxxxXX###############XX=-;=+=-=..x##X###########XxxX#    //
//    X##X,--.;+;,X##########XxxxxxxxxxxxxxxxxxxxxxxxxXxxxxxxxxxxX############xx=;,.-;,#X#####XxxxXX####XX    //
//    X##.;=,,.-x#########XxxxxxxxxxxxxxxxxxxxxxxxxxxxxXxxxXxxxxxxxxxXX##########x-..-x#######xX##########    //
//    ##..x=..;#########XxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxXxxxxxXxxxxxxx###########x++####XX#####X######    //
//    #+..-=.+########XxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxXxxxxxXxxxXxXxxxxx##########xxxxXX#####X=x#####    //
//    #...==x########xxxxxxxxxxxxxxxxxxxxxXxxxxxxxxxxxxxXxxxxxxxxxXxxxXxXxXxxxxxX########X#########xX#####    //
//    #....X########xxxxxxxxxxxxxxxxxxxxxXXxxxxxxxxxxxxxxxxxxxxxxXxxxXxxxXxXxXxxxxxX##################X###    //
//    #=..=#######Xxxxx+xxxxxxxxxxxxXxxxxxXxxxxxxxxxxxxxXxXxxxxxXxXxXxXxXxXxXxXxXxxxxxXX#######X#####X####    //
//    #-..#X#####x+xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxXxXxXxXxXxXxXxXxXxXxXxxxxxxxX###XXX######    //
//    ##.=#xX###x+xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxXxxxxxxxxxXxxxXxXxXxXXXxXXXxXxXxXxxxXXXxXx######    //
//    ##=xxxX##x+xxxxxxxxxxxxxxxxxxxxxxxxXxxxxxxxxxxxxxxxxxxxxxxxXxXxXxXxXxXXXxXxXxXxXxXxXxXxxxXxXxxx#####    //
//    X##x++###+xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxXxxxxxxxxxxxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxx#####    //
//    X##X+x##x++xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxXxXxXxXxXxxxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXX###    //
//    X###xx#X=+++x+xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxXxXxxxxxXxxxXxXxXxXxXxXxXxXxXxXxXxxxxxXxXxxxx#    //
//    X###XX#X=++x+xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxXxxxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXXXxXxXxXxXxXxXxxx#    //
//    X######x=+++x+xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxXxxxXxxxXxXxXxXxXXXxXxXxXxXxXxXxXXXxXxXxXxXxxx##    //
//    X######x=++++xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxXxxxxxxxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxxxXxXxxxXxxX#    //
//    X#######+=++++x+xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxXxXxXxXxXxXxxxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXXxx    //
//    X#######+++++++xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxXxxxxxXxXxxxXxXxXxXxXxXxXxXXXxXxXxXxXxXXXxx    //
//    X#######x.==++xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxXxxxxxxxxxxxXxXxXxxxXxXxXxXxXxxxXxXxXxxxXxXxXxXxxxXxXxXx    //
//    X##########+=+++xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxXxXxxxXxXxxxXxXxXxXxXxxxXxXxXxXxXxxxxxXxXxXxx    //
//    X###########x=++++x+xxxxxxxxxxxxxxxxxxXxxxXxxxxxxxxxxxxxxxxxXxXxXxxxXxXxXxXxXxXxXxXxXxXxxxXxXxXxxxXx    //
//    X############X==++++xx+xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxXxXxxxXxXxxxxxxxXxxxXxXxXxxxXxXxxxxxXxXxxxx    //
//    X##############x=-=+++x+xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxXxXxXxXxXxXxxxXxXxXxXxXxXxXxXxXxXxXxXxXx    //
//    X################+--==+++++x+xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxXxxxXxXxxxXxxxXxxxXxXxXxxxXxXxXxXxx    //
//    X##################=;;-=++++++x+xxxxxxxxxxxxXXXxxxxxxxxxxxxxxxxxxxxxxxxxxxXxXxXxxxxxXxxxxxXxXxxxXxXx    //
//    X####################+;,;====++++++x+xxx==+xXXxXxxxx+x+xxxxxxxxxxxxxxxxxxxxxxxxxxXxxxxxxxXxXxXxXxxxx    //
//    X######################x-..,--===++++++-..,-=;,XXxx+++++x+xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxXxXx    //
//    X#########################+;...----==--;.,--;..;=+=+==-;=++xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    X+xX#########################+;......,-===++++===;;;;;,.;-==++++xxx+xxxxxxxxxxxxxxxxxxxxxxXxxxxxXxXx    //
//    X=---==xX#######################X=.......,;--==+++++=+==---==+++xx+x+xxxxxxxxxxxxxxxxxxxxxxxxxxxxXxx    //
//    #=+====---=+X########################x-..........,==+==-========++x+++++xxxxxxx+xxxxxxxxxxxxxxxxxxxx    //
//    #=++++====-;--=x###############################X=;.,-+==---===-====+++=++++++++++xxxxx+xxxxxxxxxxxxx    //
//    #+++++=====---;;-=X################################+,,===-=-=-=---====+=+++=++++++++xxx+xxxxxxxxxxxx    //
//    #+++=+++====-----;,-+################################-.-==========-----==+++++++++++++xxxxxxxxxxxxxx    //
//    #=+++==========----;,;+###############################x.;===+=++++xxx++=======++++x+xxxxxxxxxxx+x+x+    //
//    X==+=++==+====-=----;;,;+###############################,,-=+++x+x+xxxxx+======++++++++====+++++++++    //
//    #=-=+=====+==-=------;;,;;x##############################=.-++++++xxxxx++++===+++++++===+=====++++++    //
//    #+=--=+++=-=++==-------;,;,-x#############################x.-++++xxX+=--=+=+===+++++++++++++++=++++=    //
//    #+x+=-==+++--====-=------;;;.-#############################+.=++++x=-++,.;====++++++==++++========+=    //
//    X=+x+=--=+++=--=====-=;----;;;,+############################;.=+++--=,,x##;-=++++;...-=====-......,;    //
//    #-=+x+=---=++=---===--+=-;;;;;-,-############################-..;....-#####;...........;-,..........    //
//    #=-=+xx=---==++=--====-+=-;;;;;--;+############################x+XxX########=....-x##X,.....+#######    //
//    #++==+x+=---===+=;;-=-=--++;,;-;-;;-X###################################################x+##########    //
//    #+++--+x+=---=====-----=--++-,,-;----+##############################################################    //
//    #=+++=-+++=--;===-;-----==-+x=,,;,----+#############################################################    //
//    #+++++=-+++=--;-==;,;-;-;==-=x=;,;,-=-=+X###########################################################    //
//    #++=+++--+++=--;-==-,,;;;;=+--x+-;;,=+-=xx##########################################################    //
//    X+x+++++--+++=--;-==;..;;,-===-++---;=x=+Xx#########################################################    //
//    #=+x+++++--++==--;-=-;..;;;;=+=;+x-=--=x+xX#########################################################    //
//    X++xx+++++--=++=--;=--,..=,,;++=-Xx=+=-+xxXX########################################################    //
//    #++++x+++++-=++x+==-=--...-.,-+x+-#xx++=xX#X########################################################    //
//    Xxx++xx+++++--=+++==-=-;..x=..-x#=+#xXxx+###########################################################    //
//    X+xxx+++++++=--=++====+=,.=#-..;X#=X##X##x##########################################################    //
//    Xxxxxx+++++++=-==+++++=+=..=#=..;##+##X##X##########################################################    //
//    #xxxxxx+++++x+==++xxx++++=...#+..-##X###############################################################    //
//    Xxxxxxxx+++++++===+xxx++++=;.;Xx..=#################################################################    //
//    #xxxxxxxx++=++x++=++xxx++++==;;x=..x################################################################    //
//    Xxxxxxxxxx++=+xxxx+xxx++++++===---,;xX##############################################################    //
//    XxXxXxxxxxxxxxxxxx+++++++++=+======-;;;=xX##########################################################    //
//    XxXXxXxxxxxxxx+xxxxxx+=====+==========-;,;,;;=######################################################    //
//    XxXxxxxxxxxxxxxxxxxxxxx+====+===+++++++++====-.#####################################################    //
//    XxxXxXxxxxxxxxxxxxxxxxxx+====++++++++x+++++xxX.-####################################################    //
//    XxXxXxXxxxxxxxxxxx++++++x++=+=++++xxx+++x+xxxX.x####################################################    //
//    XXXXxXxXxxxxxxxxxx+++++++xx++++++xxxxxxxxxxxXx=#####################################################    //
//    XxXXXxXxXxxxxxxxxxxxx+x++++x++++++xxxxxxXxXXX=######################################################    //
//    XXxXXXXXxXxXxxxXxXxxxxxxxx+x+x+x+++XxxxxxxxX+,######################################################    //
//    XxXxXXXXXxXXXxxxxxXxXxxxxxxxxxxxx++xXXXXXxx++,;+--##################################################    //
//    XXXXxXXXXXXXxxxxxxxXXXxXxxxxxxxxxx++xXXXxx+++x+-=,,XX###############################################    //
//    XXXXXxXxXXXXXXXxxxxxxXXxxxxxxxxxxxx+++++++++++++X#,+X+x#############################################    //
//    XXXXXXXXXXXXXXXXxxxxxxxXxXxxxxxxxx+x+++++++++++x#X,x##x++X##########################################    //
//    XXXXXXXXXXXXXXXXXXXxxxxxxxxxXxxxxxxxx+++++++++x#X,.#####X+=+########################################    //
//    XXXXXXXXXXXXXXXXxXXXxxxxxxxxxxxxxxxx+x+x+x+++xX#-,;;=X#####x=+x#####################################    //
//    XXXXXXXXXXXXXXXxXxXxXxXxxxxxxxxxxxxxxxxxxxx+xx#x+xx-..xx######x+xx##################################    //
//    XXXXXXXXXXXXXXXXxXxXxXxXxxxxxxxxxxxxxxxxxxxxxXXXxxxXx.-x+x#######XxxX###############################    //
//    XX#XXXXXXXXXXXXXXxXxXxxxXxxxxxxxxxxxxxxxxxxxX#XxxxX##;.x#Xxx########XxXX############################    //
//    XXXXXXXXXXXXXXXXXXXXxXxxxxxxxxxxxxxx+++xxxX##XxxxXX#=...,x##Xxx#####################################    //
//    XX#XXXXXXXXXXXXXXxXXXxXxxxxxxxxxxxxxxx++++xXxxxxXxX+.x#;..,+########################################    //
//    XXXXXXXXXXXXXXXXXXXXXXxXxXxxxxxxxxxxxxxx++===xxXXxx-..###+-..=######################################    //
//    XX#XXXXXXXXXXXXXXXXxXxXxXxxxxxxxxxxxxxx+xxx++==+xxXxx.-####X+,,=X###################################    //
//    XXXXXXXXXXXXXXXXXXXXxXxXxXxxxxxxxx+xxxxxxx+xxx++==+xXx.+######X+=+x#################################    //
//    XXXXXXXXXXXXXXXXXXXXXxXxXxxxxxxxxxxxx+++xxxxxxxxx++=+x=.##########XX################################    //
//    XXXXXXXXXXXXXXXXXXXXXXXXxXxXxxxxxxxxxxxx++xxxxxxxxxx+++;,###########################################    //
//    XXXXXXXXXXXXXXXXXXXXXXXxXxXxxxxxxxxxxxxxxxx+++xxxxxxxxx+.xxxX#######################################    //
//    XXXXXXXXXXXXXXXXXXXXXXXXxXxXxxxxxxxxxxxxxxxxxx+xxxxxxXXx.###X#X#####################################    //
//    XXXXXXXXXXXXXXXXXXXXXXXxXxXxxxXxXxxxxxxxxxxxxxxxxxxxxxX--###########################################    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXxXxxxxxxxxxxxxxxxxxxxxxXxx=-############################################    //
//    XxXXXXXXXXXXXXXXXXXxXXXXXXXXXxXxxxxxxxxxxxxxxxxxXxxx+-x#############################################    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXxXxXxxxxxxxxxxxxxxxxxx++=++###############################################    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXxXxXxXxxxxxxxxxxxx++=++xX##################################################    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXxXxXxxxxXxx++++++xX#######################################################    //
//    XxXXXXXXXXXXXXXXXXXXXxXXXXXXXXxxx+-=++xx############################################################    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXX+=xx+...X###############################################################    //
//    XXXXXXXXXXXXXXXXXxXXXxXXx++-.x#X......+xXX##########################################################    //
//    XXXXXXXXXXX#X#X#####X#Xxxx+-;#x..#+....,=xxX########################################################    //
//    XxXX###XXXXXXX#X###XXxxxx+==-;.=#=.......-xxX#######################################################    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SYNTH is ERC721Creator {
    constructor() ERC721Creator("Synthetic Memories", "SYNTH") {}
}