// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Under the Skin
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                       //
//                                                                                                                       //
//    +x#####=---==++=++x===+x+xx+++++++++++xxxX-.,=-,,,;;;;;;;;---------==-=-=-=---=-----------=+x+xxXXXxX##x#Xx+X#x    //
//    ++####------=+=+++===-==-==-------------==--;;,;.....,.,,,,,,;;;;;;-;;;---;-------;---;-;-;=++++xxxxxX##xxx+xXx    //
//    +=###=,;===+++++x+x+=-=----;;----;;;;;-;-;;;--+---;,;;;;-;------------=-------=------------=+xX+++xxxxX##XXxxxX    //
//    =++++=---=xx++=+++=-;;--;;,;;;;;,,,;,;,;,,,;,,-X--=-,;;;;;;--------=-=---=-=-=-=-=--------;-=+xXXx+xxx+x##XXxxX    //
//    =x-;=;=+xxX####Xxx+-;,,,,...........,,,,,,,,,,.-#,,+=;;;-;------------=-===-=---=-=-=-=-=--=+xX#######X+xX##XxX    //
//    =xx++++XXxXXX#X###X##X++=--;;;,,.............,..=+..x=--;-;--------------=---=-------=---+X###########Xx++x##Xx    //
//    =xXXX#X#xxXXXxXXx+++xxxxXXXxxx+++++=+====-=----=++;,===-==---=======+=================--==+xxxX##########xx###x    //
//    +#x####X+xxXxxxX##XXX#########XX####X#######X#X#Xx#Xx#XxX#XXX#X#X###########################X#################X    //
//    x+x##XX+-X#XXXX##########XXXXX#XXXXXXXXxXxXxXxxxXXXXXXXXXX########################################X##x+=++xX##X    //
//    x=X##X+#+x#XXX########XXXXxXXXxxxx+x+x+++++++++++++++xxxxxxxxXXxX#XXX##########X+#xxx++++xxxX#####X##xx+++xXX#x    //
//    #+x##X+xX+XXxx#######XXXXxXx=...............................;x+.-+XXXX#X###X###Xx#X+======++X#######XXxxxX#XXXx    //
//    #Xx###+=+XxXxx######X#XXxxxx;................................++;=xXXXXX###X####X+xx#XxXXxxxxx######Xxxx++XXXX#x    //
//    ######==Xx##xx#######XXXXxxx=...............................,++.-xXXXX#X#X#####X+++xxxXxXx++X##X##XXXxx+xXXxXXx    //
//    x######=X,=#X+####X#X#XXXXxx-................................x=.;xXXX#XXX#X#X###xX++Xx++xX+xX#####xXxx=+XXxxXx+    //
//    =;x#++#X+..+x+#####X#XXXXXXxx++++++++=+=+===+======+==+++++++xxxxXXX#X#X#XXXX#Xxxxxxx++x++x+x##X##xxx+==XXXxXxx    //
//    =.;X.=##;--+=+####X#X#X#X#XXX#XXXXxXxXxXxXxXxxxXxXxXXXXXXXX#XXX###X#X#X#XXXXXxxxxxxx++++++++xxxX##+xx=-+==xXxxx    //
//    #==X.+xX=,XX=.####XXXXXxxxXxXxXXXXXxXxXxxxxxXxxxXxXxXxXXXXXXXX#X#X#X###X#XXx+................=xx#x=+x-+#x+xXxxX    //
//    #Xx#+Xx+X,.##.x###XXx+......+xxXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX#X#########XXXX+;.;-.,,.........+xX#x-=..+x+XxxxxX    //
//    #+X##xx+x=..x#+######x.....,+xXXXXXXXXXXXXXXXXXX#X#X#####################X#X####XXXXXXXxXXX#####X=+X+=#;;XxxxxX    //
//    ++x##x+++x-..,-=xXx#################X#X###X##################################################Xx+=x=x=XXxXxxxxxx    //
//    #+x##+++=+x,.....=-;.,=+++++++++=-=x####XX###XXX###xx+xxxxXX#XXXXXXXXXXXXXXXXXXXXxXxxxxxx++==-===-==x#,-XxxxxxX    //
//    #xx##++x=+=#.....;,-+;...........-x###X#X#XXXXxXXx-......;=xxx+x+x+x+x++++++++++++====-----==++=-=+=#xxXxxxx+xx    //
//    #X+#X-+x===x#.....;.,Xx...,....=#####XXXXXXXXxxXX=,.....,;=+xxx+x+x+x+xxxxx++++++++=+=======++=-+x-X#.+X+xxx+xX    //
//    ##=#x-+X===-#x...-;,,.xX.....=####XXXXXXXXxXxXX#+;.....,;==++x+x+++x+++x++++++++++++=+++==++=+--==x#-+Xxxxxx+xx    //
//    #X-##+X#===;x#X=+#=.,..#=..,#####XxxXxXxXxXXXXX=.....;-=+++=++++xx++x++++++++++++++=+++++++==##xxX#+=xx+xxxx+xX    //
//    #X-##x##+++++######....X;.-####XxxxXxxxXXXXxxx+..;--=xxXxx+++++++x++++++++++++=+=+++===++++=+###XXx=xX+xxxx++xx    //
//    #X=##X##Xxx+-X#XXX#=..;#.+####XxXXXxxXXxx++++++=x####X##Xxx###Xxx++++++++++++=+++=+=+=+=++=-###X##=+Xx+xx+x++xX    //
//    xx+###XX#Xx+-+##xX##..#+x###XXXXXXxXxx+=====---=x##X+=x##x+xxXXx++++++++++++++++++=+=+=+++=x##X+;,+Xx++Xxx+++xX    //
//    +-Xx#xxx#XXx++##Xx##+XX####XXXXXXXXx+------;-;;;;,,,,,=xx++++++=+++++++++++===+=+=+=++++===###Xx--Xx++xxxxx=xx#    //
//    x-=,-x=+XXxXx+X##XX#-#####X#XXX#XXx=-;;;,;,,,,,,......;-,,;-=====+++=+=+=+=====+=+=+++==+#X##XxXXXXx+xxxxx++xx#    //
//    X;x.-x+-xXxxxxx####-x#######XX#XXx=-;;,,,,,,,.....,;---,,;=+++======+=+=+++===+=++++++=X#####Xxxxxx+xxXxxx++xx#    //
//    #,x++x+-=Xxxxxx###-x########X#XXX+-;,,,,,,....,-++xXXXXxx##XXxxx+====+=+++=+=+=+=++++-x##X##XxxxxXx++xxxxx++xX#    //
//    #-;+=+x+=xx+xxx+x++#######=##XXXx--;;,,,,..,-+xxXXXX#######XXxXXXxx+==+++=++++==+====-#XX##XXxXxxxx+xxxxxx++xX#    //
//    #=,;;+xx=xxxx+xx+#############XX+-;-;;;-=+X#########################XXx+++++++===+x#X#xX##X#xxxxxx+xxXxxxx++x##    //
//    #+;;-=x+=+X++x###X+#############x--,,;-+####xx++==+++++xxxxxxXXXXXXX###x+======x####XxX###X#xxxxxxxxxxxxxx++x#X    //
//    #x;--=x+==X++####,x##############+.-#xxx-;,-,.,;;;;----=-==++xxx+++x++++X###=-####Xxx######XxXxxxx+xxx+Xxx++x#X    //
//    #X=---x++=x+X###X.x==X############+#####X..=#xx+++xxxxxxxxXxXxXxXx##x==######X###Xxx#####X#XxXxxx+xxxxxxxx+xX#X    //
//    #X+---xx+-x#####..==-x##################++##+#xX#x+###XXX####XX#xxX+##+x########Xxx#####X##XxXxxxxxxxxxxxx+xX#X    //
//    #Xx-=,+x+-x###Xx=#X,,-###########x#####+=######+x++xxx###XXxXxx++######=X#######x=#######X#xxXXxxxxxxxxxx++xX#X    //
//    #X+==;=x+=+##xx####+=-XXX#########XX=-=++####X##;,+X###;;####x-=#######Xxx+x##Xx=X######X##xxXXxxxxxxxxxxx+xX#X    //
//    #xx==;-xx=x+=+x########X#######XX##x==X#####=..#=.Xx++-.,+xx##=+##########xx#x+=+##########XxXXxxxxxxxxxx++xX#X    //
//    #Xx+=-;+x=xxxXxX#######+########xX##xX##+####x.+x######.-######x#######x##Xx++++X##########XxXXxxxxxxXXxxx+xXXX    //
//    #X+++;;+x=Xx+X#XX###############XXX#####+x####x.+X#############x######x##xxx++++###########XxXXxxxxxxXXxx+++#xX    //
//    #X+++-;=+=Xx+XXxx###############xXXXX####+XxxX########################xXxx++++=+##########XXxXXxxxxxxXXxxxx+X#x    //
//    #x++=;;=+=X++XXxxX###############XXxxxxX#####-.=xXXxX####X#X##xxXX##x++++++++++##########X#XXXXxxxXxxxXxxxxxx#x    //
//    #x=+--,=+xx++XxxxXX###################Xx=;,-+#+-,=,....;...,-==X##XXX#######################XXXXxxxXxxXX+xxx+#X    //
//    #++=--;+=x+=xXx+XX##############+x#######=;,=X#################################X###########X#X#xxxXxxxxXx+xx+x#    //
//    #=+--;-++x=+xx+xXx#############x;-===++xxxX############xx###############XXXXxx+x#############XXXxxxXxXxXX++Xxx#    //
//    +++-=,=+x+=+xx+XXx#############-;---===+++x+xxxxxxXxXxxXXX#######XXXXXXxXxxxxxxx##############XXXxxXXxxx#x+xXxx    //
//    ++=+;;=x++=xx+x#+X#############,;----====++++++xxxxxXXX#####X#XXXXXXXXXXXXxxxxxxx###########X#X#XxxXXXxxX#x+Xxx    //
//    x===,-x++=+x++#xx##X##########-,;-----====++++++++xxxxxXxXXXXX#XXXXXXXXXXXXxXxxxx##X###########X#xXxXXXxxX#xxXx    //
//    +=+;,+x++=+++XXxX#Xxxx#######x.,;-;;---====+++++++++xxx#xXXXXXXXXXXXXXXXXXxxxXxxxX###############XxXxXXXxxX#xxx    //
//    ===.=x++=+++xxXXX############,,,;;;;;---====+=++++++xxx#XxXXXXXXXXXXXXXXXxXxXxxxxX################XxXXX#Xxx##xx    //
//    =+;;++x==x+xxX#XX###########,,,;;;;;;--========++++++x+#XxxXxXXXXXXXXXXXXXxxxxxxxXx################XXXx###xxXXx    //
//    +=,+xx==++xxX#XX##########x,,,;,;,;,;---========+++++++##xxxXXXxXXXXXXXXXXxxXxxxXxXX###############XXXXx###XxXX    //
//    x;-x+=-++xX###X##########-.,,;;;,;,;;----======++++++++#XxxxxxxXXXXXxXxXxXxxxxxXxXXXX###############XXXXxXX#XXx    //
//    =;x+==++x####X#########=,.,,;,;,,,,,;;---=====+=+++++++##+xxxxXxXXXxxxxxXxxxxxxxXXXXXXX##############X###xxx##x    //
//    xxx+-=+x####X########=,.,;,;,;,;,,,,;----======++++++++#X+xxxxxxxxxxxxxxxxxXxXxXXXXXXXXXX#################XxxXX    //
//    #X;x#Xx####X######x-..,,;,;,,,,,,,,,;;----====++++++x++##+xxxxxxxxxxxxxxxxxxXXXXXXXXXX#XXXXX################Xxx    //
//    x=-+###X######X+-....,,;,;;;,,,,,,,;;;;----====+++=====##+xxxxxxxxxxxxxxxxxXxXXXXXXXX###X#XXXXX###############x    //
//    =+++x##xxX#X-,....,,;;;,;;,.,,,,,,,,;;;;--=-==+=+=;----++====+xxxxxxxxxxxxxxXXXXXXXxx++xXXXXXXXxXx#############    //
//    =+xX##xx##X;,,.,,,,,,,,,,,.........,,;;;---====++-;----======+xx+x++++xxxxxXxXXXXXxXX+,-xXXXXXXXxxxxxXX#######X    //
//    +==-;,..---==--;;,,,,,,,.........,,,;;;;;---====+=----==+===+++++++++++xxxxxxxXXXXXXX##xXXXXXXXXXXXxxxxxXX#####    //
//    -,;;,;,,.,;--=--;;,,,,......,;;;;-;;;;;;;;---====+++++x=+x+++++++++++++x+xxxxXXXXXXXXXX###X#XXXXXXXXXXXXxXxXX#X    //
//    -,;;;,;;;;;;-;;;;,;,,,.....--;;;;;;;;;;;;;---=====++++x==xx+++++++==++++xxxxXxXXXXXXXXXXXX#X#X#XXXXXXXXXXXXXXXX    //
//    ;,;;;;;;;;;;;;;;;;,;,,......;;;;;;;;;;;;;;;----====++++x++++=+=======++xxxxxxXxXxXxXxXxXXXXXXXXXXXXXXXXXXXXXXXX    //
//    ;,-;-;-;-;-;;;;;;,;,;,;,,...;;;;;;;;;,;,,...,,;---=====#x==-----;;;;-=++++x+xxxxxxxxxxXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    ;,,;;;;;;;;;;;;;;;;;;;,,,,...,,;;,,,,;;;;;-xX###XXX#X#X#XxxXX#X#########XXxxxx+++++x+xxxxxxxxxxXxXxXxXXXxXxXxXx    //
//    ,.,,,,,,,,,,;;;;;;;,,,,,,;--==-...-+X###########Xx######X##########################Xx++++=+++xxxxxxxxxxxxxxxxxx    //
//    ,..........,,;;;;------x###Xxxx##########X+;..,-=+++====++++++=-.,;=+xX####################Xx+=++++++x+xxxxxxx+    //
//    ...................,-==xXxxxXX#Xx+==--;,........;------;-,........,-=-=-=======+xxxX############Xx+===++xxxxxxx    //
//    .........=X+,,,;-+x##Xx+==--,...................,-;,,,...........;---;,,.,.......,,;;--==++xX#########xx+++xxxx    //
//    .....-######XX##X+-,.............................,-;,............,,.......,.,.,,,.,,....,.,,;;==xX########Xxxxx    //
//    ..-####X-;;===;..................................,--;,,..................,.,,,,;;;;;;;;;---------==xx########X+    //
//    x###=...,-,.......................................--,.....................,,,,,,;,;;;;;-------=------==++xX####    //
//                                                                                                                       //
//                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SKIN is ERC721Creator {
    constructor() ERC721Creator("Under the Skin", "SKIN") {}
}