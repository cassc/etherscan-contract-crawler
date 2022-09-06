// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CityCitizens
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    55yyyyyyyyyyy5yyyyyyy55y5555555oooooooooooooooooooaaaaaaaaaaaaZZZZZZZZZSSSSSSSSSSmmmmmmmmmmwwwwmwwwwwEEEwwwEEEEEEEEPPPhhhhhhhhhhkkkkkkkXXXXXXXXXXXXXXX    //
//    yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy555555555oooooooooooaaaaaaaaaaaaaaZZZZZZZSSSSSSSSSSmmmmmmmmwwwwwwwwwwwEwEEEEEEEEEEEEPPhPhhhhhhhkkkkkkkXXXXXXXXXXXXXX    //
//    yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy555555555o5oooooooooaaaaaaaaaaaaaZZZZSZSZSSSSSSSSSSmmmmmmmwmwwwwwwwEwEEEEEEEEEEEPPPhhhhhhhhhkkkkkkkkXXXXXXXXXXX    //
//    yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy5555555ooooooooooooooaaaaaaaaaaaaZZZZSZZSSSSSSSSSSmmmmmmwwwmwwwwwwEEwEEEEEEEEEEEPhhPhhhhhhkkkkkkkkXXXXXXXXXX    //
//    yjyyjjjjjyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy555555555ooooooooooooooaaaaaaaaaaZZZZZSZZSSSSSSSSSmmmmmmmwwwwwwwwwEwEEEEEEEEEEPPhhhhhhhhkkkkkkkkkXXXXXXXX    //
//    jjjjjjjjjjjjjjjjyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy555555ooooooooooooooooaaaaaaaaZZZZZSSSSSSSSSSmmmmmmmwwwwwwwwwwwwEEEEEEEEEEPPPhhhhhhhhkkkkkkkXXXXXXX    //
//    jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjyyyyyyyyyyyyyyyyyyyyyyy55555555oooooooooooaaaaoaaaaaaaaZZZZSSSSSSSSSmmmmmmmwwwwwwwwwwEEEEEEEEEEPPPPhhhhhhhhkkkkkkkXXXXXX    //
//    jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjyyyyyyyyyyyyyyyyyyyyy555555ooooooooooooaoaaaaSwEPhhkPmSSSSSSSSSSSmmmmmmwwwwwwwwwEEEEEEEEEEEEPPPhhhhhhhkkkkkkkkXXXX    //
//    jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjyyyyyyyyyyyyyyyyamEkXUU6qqKKbbddDDDDDR%gWN8W%DR#QQRXEEmSSSSSSSSmmmmmmwwwwwwwwwEEEEEEEEEEEEPPhhhhhhhhkkkkkkkXXX    //
//    jjjfjjjfffffjfffffjjjjjjjjjjjjjjjjjjjjjjjjjjyyyyy5E6Dg#BBB&#NNNN88WWWWWWWWWWWWWWWWg%DdD&QQNKUdW8gDKUhSSSSmmmmmmwwwwwwwwwEwEEEEEEEEEPPhPhhhhhhkkkkkkXXX    //
//    ffffffffffffffffffffffjjfjjjjjjjjjjjjjjjjjjjjjjjym6DW#BBB##NNN888WWWWWWggggggggggg%RDbD&QQBRbDW#BBB#N%KUESSSmmmmmwwwwwwwwwEEEEEEEEEEEPPhhhhhhhkkkkkkkk    //
//    }}}}}}}}}}}}}}ffffffffffffffffffjjjjjjjjjjjjjjjjywq%N&BB&##NNN88WWWWWggggggggg%%%RRDdbDBQQQNgg8#BB&#NgDAm}7jSmmmmmmwwwwwwwEEEEEEEEEEEPPPhhhhhhhhkkkkkk    //
//    }}}}}}}}}}}}}}}}}}}}}}}fffffffffffffffjjjjjjjjjfyhbgN&B&&#NNN88WWWWWgggggg%%%%RRDDDDdbDBQQQQB##BQB&#8gDAm{i*SSSmmmmmmwwwwwwwwEEwEEEEEEEPPhhhhhhhhkkkkk    //
//    {{{{{{{{{{{{{{{}}}}}}}}}}}}}}}ffffffffffffjjjjj}aUDW#BB&##NNN88WWWWggggg%%%%RRDDDDddbbRBQQQQQQQQQQB#NgDqwf\^ySSSmmmmmwwwwwwwwwEEEEEEEEEEEhPhhhhhhhkkkk    //
//    uuuuuuuuuuuuu{u{{{}}}}}}}}}}}}}}}}}}fffffffffj{fEq%N#BB&#NNN888WWWggggg%%%RRDDDDdddbbbRBQQQQQQQQQQQ&NgDKPj7=TSSSSSmmmmmwwwwwwwwEwEEEEEEEEPPhhhhhhhhkkk    //
//    nunnnuuuuuuuuuuuuuu{{{{{{{{{{}}}}}}}}}}ffffff}I5XdgN&B&##NNN88WWWWgggg%%%RDDDDDddbbbKb%QQQQQQQQQQQQB#WRbXyz*+ZSSSSSmmmmmmwwwwwwwEEwEEEEEEEPPPhhhhhhhkk    //
//    nnnnnnnnnnnnnnnnnnnuuuuuuuuuu{{{{}}}}}}}}ffffs}mqD8#&&&##NNN88WWWgggg%%RRDDDDDddbbbKKb%QQQQQQQQQQQQQB8%dUos|;YSSSSSSmmmmmwwwwwwwwwEEEEEEEEEEPPhhhhhhhk    //
//    IIIIIIIYYYYYYYYYYYnnnnnnnnnuuuuu{{{{{{}}}}f}uxyXd%N#B&##NNN888WWWggg%%RRDDDDDddbbbKKKd%QQQQQQQQQQQQQQ#gD6S}i^*SSSSSSSSmmmmmwwwwwwwwEEEEEEEEEEPPhhhhhhk    //
//    sssssssssIIIIIIIYYYYYYYYYYYnnnnnuuuu{{{{{{}{JjwqRWN&&&##NNN888WWggg%%RRDDDDDddddbbbbbdgQQQQQQQQQQQQQQQN%KEj7=;oZSSSSSSSmmmmmwwwwwwwEEEEEEEEEEPPhhhhhhh    //
//    sxxsxxxxxxxssssIjnssIIIIIIYYYYYnnnnnuuu{{{{tYZUdgN#&&&##NNN888WWgg%%RDDDDDDDddddddbbbDgQQQQQQQQQQQQQQQBWDXoJ?!vSSSSSSSSSmmmmmmwwwwwwwEEEEEEEEEEPhhhhhh    //
//    xxxttxxttttxxxzzh%%DKUhSy}sIIIIIYYYnnnunY}f}okqR8N#&&###NN8Wg%DDbq6UXkhPhkXU6qKbdddddDgQQQQQQQQQQQQQQQQB%qw}i=^aSSSSSSSSSmmmmmwwwwwwwwEEEEEEEEEEPPhhhh    //
//    ttttJJJJJJJJJJtJT7abW#BQQQ&WDKUPZy}YYnnIjoSwEPPEEPhPEEwmSZZZZSZSSSSSSSmmmmmmmmmmSmmEkXAdD%ggggggWW88N&B#WDU5z|!zSSSSmmmmmmmwwwwwwwwwwwwEEEEEEEEEPPhhhh    //
//    JJJJJzJJJJzzJJJJJz77jXKD%g8N#B&BBB&WRdAUqKbKUhEEEEEwwmmmSSSZaaaZSwkUqKbbKq6XwmSSmmwEEhkXU6AqKbbddDDDDDDDDDDKX57|kUwwwwwwwwwwwwEEEEEEEPEEEEEEEPEPPPPhhh    //
//    zzzzzzzzzzzzzzzzzzzzzIykqKbbdDDR%ggW8N#&BBQQQQ&8Wgggg%ggggW8NN&QQQQQQQQQQQQQQQQQ#WgDDbKqqqKbDDR%gg%%RDDDDDR%%%%RDqwShhhhhkXU6qKbDDR%Db6kPhhhhhhhhhhhhh    //
//    zzzzzzzzzzzzzzzzzzzzzzzx}oPAbDRR%%ggWggggR%g8N#BQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQB&##NWRDq6888N#BBBBBBBBBBB&&NRqkkkkkhhhhhhhh    //
//    zzzzzzzzzzzzzzzzzzzzzzzzzzzzJnfjjyyyy55ooZ6bDWQQQQ&N8NNNBQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQB##NNNNNN88888888WWWgg%%R6otXXXXkkkkhhhh    //
//    [email protected]@@@@@@QQQBNggg8&QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQBBB&&&&BBBQ#8gDdKUkXUUUXXXXXkkkhh    //
//    77777777777zzzzzzzzzzzzzzzzzzzzzzJJJtttxx{[email protected]@@@@@@@@@@@@QQQ#g%ggNQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ#NW%DDddbbKqqqA66UUUXXXXkkk    //
//    777777777777777zz7zzzzzzzzzzzzzzzzJJJtttt{[email protected]@@[email protected]@[email protected]@@@QQNggg8#QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQBNg%%%%%%%RRDDDdbKKqqq6UUUXXXXkk    //
//    777777777777777777777zzzzzzzzzzzzzzzJJtttumkXq%[email protected]?|[email protected]@@QQQNW88NBQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQb#NWWWWWWWWWWgggg%RDDDdbKKqq66UUXXXXk    //
//    777777777777777777777777zzzzzzzzzzzzzJJJz}mkX6DQQQQQQQQQQQQ!;;*7J{[email protected]@@@@@QQQQ&&BBBQQQQQQQQQQQQQQQQQQQQ&@@grDWWWWWWWWWWWWWWWgg%RDDddKKqq66UUUXXX    //
//    777777777777777777777777777zzzzzzzzzzzzJzfwXU6KBQQQBQQQQQQf;;;;~~,,,~^[email protected]@@@@@[email protected]@[email protected]@Q<DWWWWWWWWWWWWWWWWg%%RDDDbbKqqA66UUUX    //
//    777777777777777777777777777zzzzzzzzzzzzzzjEXqK6WQQBBQQQQQg!;;;;~_,:;!;;;!!^<Ltmafmqwjyw6d%[email protected]@@@@QQQQ&b8#[email protected]@@L%WWWWWWWWWWWWWWWWgg%RDDDddbKKKqq666U    //
//    v7v777777777777777777777777777zzzzzzzzzzzfjj5Ek%QQQQQQQQQL;;;;;~_,;;;;;~~;;^=?cIi!?i^^+<[email protected]##&[email protected]@@sWWWWWWWWWWWWWWWWWWgg%RRDDDddbbKKKqqq    //
//    TTvvv7vvvvvv77777777777777777777zzzzzzzz*!!^^!!IQQQQQQQQb;;;;;;~~,.  Iqhq%mjI!<\n!*|^;!!!!^r=*?WRfywh6kww\[email protected]@@a6wgWWWWWWWWWWWWWWWggg%%RDDDDDdddbbKK    //
//    TTTTvvvvvvvvv7v777777777777777777zzzzzz*;!<|||>;EQQQQQQQL;;;;;;~~,`  ybANQRRy`'~!!<?^;;;!!!^^^^[email protected]@@&N{^|!%Z~,[email protected]@k*~*WWWWWWWWWWWWWWWWWggg%%%RDDDDDDDdd    //
//    TTTTTvvvvvvvvvvvv7777777777777777zzzzzz^;!>=^!!^!WQQQQQB!!;;;;;~~_'  `<aAqS<..:;;!<?>^^^^^r=><<[email protected]%%j:;?*Ds'`[email protected]@sK%XUWWWWWWWWWWWWWWWWWWgggg%%%%%RRDDD    //
//    TccccTTTvvvvTvvvv77777777777777z7zzzzzz!;^<+;;~;;iQQQQQq!!;;;;;;~~:,...''''',~;;;!<?*<**?|LicT7jg%w+,,;<zXS|` [email protected]%%%%    //
//    ccccccTvvvvvvvvvvv777777777777777zzzzzz^;^*+;;~:;~KQQQQh!!;;;;;;;~~::;!^=<*<=!;;;!*?<**?||Li\\\wBBqx7syyo}z^``[email protected]%P%%E6WWWWWWWWWWWWWWWWWWWWWWWWWWWWWggg    //
//    cccccccTvvvTTTvvv7777777777777777zzzzzz*!!L>;;;~;;<QQQQk^!;;;;;;;;~~:,,,,:~~~;;;;!<+!^^^r+=<<**m#gyi|ic7xsi~`[email protected]    //
//    TTTcccTTvvvvTvv7v777777777777777zzzzzzzz^!+|!;;;;;!j&QDu!^!;;;;;;;~~~:,,,,_~~~;;;r=;;;;;;!!!!!!=%Kz|L\7zI7='``@Qjdgq|WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    cTTTTccTvvvvvvv77777777777777777zzzzzzzz\^!^=^^!;;;=++7T?>!;;;;;;;;~~~:,,:_~~~~;;<^;;;;;;!!!!!!!7WZ\iczxsL;.` #gv^q!wWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    TTTcTTTvvvvvvvv7777777777777777zzzzzzzzzzv=^!!!!;;;**>?<zz+!+;!;;;;;~~~::_~~~~;rLjw}*!;!!!!!!!^zENWo77zIz=_.`=Qq|,'*WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWggg    //
//    TTTTTTvvvvvvv777777777777777777zzzzzzzzzzzJc?=^!!!?y+;^iZYzxL*!!;;;;;~~~_~~?jq#QQQQQQ#Kmj}[email protected]@@@QqnxY7^_'~6Nq\~zgWWWWWWWWWWWWWWWWWWWWWWWWWWWWgggg%%    //
//    Tvvvvv77v77777777777777777777zzzzzzzzzzzzzzJtJm%D#@W5'!<azt=vfL?^;;;;;[email protected]@@@@@@@@Qdy\r;;xQgDqbWWWWWWWWWWWWWWWWWWWWWWWWWWWWgggg%%%R    //
//    [email protected],^fuyE\jyL=!!!;;;;;[email protected]@@@@@@@@@@KT*yjQQWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWgggg%%%RRD    //
//    [email protected]@X!:zzcTwIsk><?!^;;;[email protected]@@@@@@@@@@#{[email protected]%%%RRDDD    //
//    77777777777777777777777777zzzzzzzzzzzzzzzJJttxsI#@@@Q|,+hkkzvyci|<*?;;;[email protected]@@@@@@@@@QshQQQWWWWWWWWWWWWWWWWWWWWWWWWWWWWWggg%%RRRDDDD    //
//    [email protected]@@m<=ivzjI<o?\i>?!|=jXRDqkaEjj7Jmj{jEf}}7i|7xzzsY{ykU6QKQNWWWWWWWWWWWWWWWWWWWWWWWWWWWWggg%%RRDDDDdd    //
//    [email protected]@Qi!=XzS+fyjL|I?S<^^;;!;;;;~~;;;;^=^*?*i\i7z7z}akXoyszuoqgWWWWWWWWWWWWWWWWWWWWWWWWWWWg%%%RDDDDDdbb    //
//    7777777777777777zzzzzzzzzzzzzzzzzzJzzJJJJttxxsssIIYwqb\==iIxt==LZ=oi*j**;*=^;;;^!<^zr=*<inicZEkhw}{ESNNW8Q8wJic5KWWWWWWWWWWWWWWWWWWWWWWWWg%%RDDDDddbKK    //
//    zzzzzzzzz777zzzzzzzzzzzzzzzzzzzzzJJJJJttttxxxsIIIIYnnns>^?L\sIu{jf|=S=i7!w<L|;|*+!i?^L}<L?vfyyY5ohSUD&N#QBWWWW%EtaWWWWWWWWWWWWWWWWWWWWWWg%%RDDDDddbKKK    //
//    zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzJJtJttttxxxxsIIYYYYnnuux^^!?aaYSo7yyc7J7*^;|I;;**x+>|i7=7TfsfSyywXmR&QQQNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWgg%%RDDDddbKKqq    //
//    zzzzzzzzzzzzzzzzzzzzzzzzzzzJJJJJJtttxxxxxxsssIIIYnnnuuu{7!!!?zYokZXwzSa7Joi^<\^};^\;^\7Lcz*7UznXaS6QQQNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWg%%RDDDdbbKKqqq    //
//    zzzzzzzzzzzzzzzzzzzzzzzzJJJJJttttxxxxxxsssIIIIIInnuuu{{}}?;;^*i7swkdXbqUUTgLz+z^z7+zzL*oz{zjyUSyX#QQ8WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWgg%RDDDDdbKKqqAA    //
//    JJJzzzzzzzzJJzJJJJJJJJJJJtttttttxxssssIIIIYYYYYYnnu{{usnjy<^^<|L\7zsj5ahKbwUE{iy<<I|L}o}zSy6mkq#QQWWW8WWWWW8WWWWWWWWWWWWWWWWWWWWWWWWWgg%%RDDDdbKKKqq66    //
//    JJJJJJJJJJJJJJJJtJttJtttttttxxxxxssIIIYYYYnnnnnnuuu{tzvJywPi**||Li\T7zJs{faUK6WDDAD%wXdNAD%RSg%dgWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWgg%RDDDdbbKKqqA66    //
//    tttttttttttttttttttttxxxxxxxxssssIIIYYYYnnnnuuuuuu{zzJzzujyZY7L||||Lii\c77zxujoEUqdDRRDDRDKw6gdmsSD8WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWgg%%RDDDdbKKKqA666    //
//    xxxxxxxxxxxxxxxxxxxxxxsssssssssIIIIYYnnnnnuuuuu{{{}it{nIufjyoaajn7||||Lii\T7zs}j5mPUKKKdDDDRQB%X7xzDWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWgg%RDDDDdbKKqqA66U    //
//    sssssssssssssssssssssssssIIIIIIYYnnnnnnuuuuuu{{{{}}\sufjffjoaZZaoaZy}7iLLLic7Jn}jyomEhkXUqDNQgKu|YsYWWWWWWWWWW88WWWWWWWWWWWWWW8WWWWgg%RRDDDddKKKqq666U    //
//    IIIIIIIIIIIIIIIIIIIIIIIIYYYYYYYnnnnuuuuuuuuu{}}}}nxL\7j5oyjj5aSmmmSSSEkwyxvc7zsY{}jyyyyoZwUKqEjvIyTn%WWWWWWWWW8WWWWWWWWWWWWWWWWWWWgg%%RDDDDdbKKqqA66UU    //
//    YYYYYYYYYYYYYYYYYYYYYYYYYYnnnnnuuuuuu{{uYJ77\iL||||L\nyoaaojy5ZSwEPhESZmhXkZjuxxxsYu}ffjoSa5oo5Swf7iLvzYjomXqDWWWWWWWWWWWWWWWWWWWgg%%RDDDDdbKKKqqA66UU    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnuuu{uunt7cL|**<<**||LLLi\\cjoaaaooZSSSmmEhXXhmSSwPkkwoj}}jyjjj}{j5SEkXy}f<i7Ti|**<==LzyU%WWWWWWWWWWWWggg%%RDDDDdbbKKqqA666UU    //
//    uuuuuuuuuuuuuuunuuuuuuuuuuu{{7*^+++>*????|LLLLicci\vzzsZmSSSSSSSmmmmwhXXXhwSmwwwPUAKKKbKAEoowkhaojL<zY\L?****<<>=+=ijqgW8WWWWWggg%RRDDDddbKKKqqA66UUUU    //
//    {{{{{{{{{{{{uuuu{{{{{{{{{{z*!;;;^?*||??|iiiL\Tcii7zzv7JY}wEmmSSZaZmEEmmmPkXXESSEXqbDdbqUPmmwEwEXasiiyniiL||||?***<<>==|jAWWWWgg%%%RDDDDdbKKKqqqA66UUUX    //
//    }}}}}}}}{{}}{{{}}{{}}}}I|^~~;!!;^\|i||ic\Li77vivzzvTzxJ7tfymEmSao5y5ShXESaZwhXXXXU6UXhEEPEEEXdDEy{7jwJTc\\iiiLLL||??**<==?fbggg%%RRDDDDdbKKqqA666UUUUU    //
//    }}}}}}}}}}}}}}}}}}}}{i^~;~;;!^+^=zLLLc77ii7zci7zz\7Jt7vtYYzIoSPmoyyyyyoEXUhSooSwkXXXXXkkX6bgNdkSoj{6Szz77777vTc\\iiiLL|?>*>!*yDg%%RRDDDdbbKKqq666UUUXX    //
//    }}}}}}}}}}}}}}}}}fu|;~~;;;!!=<<=?JL|L77ci7zviTzzc7JtvTzxz7znuJYmEmoyjjyyomX66XPmSmEXUqd%NB#%AXkESokKfJzJzzzzzzz77777Tc\iL?iL+!^76%%RDDDDddbKKqqA66UUXX    //
//    ffffffffffffffff}L;~~;;!^^^+?||*iJL|i77iTzzi\zzc\zJ7\zt7c7xx77Yutykmoyyyyy5ZwXAKbDD%gWW%DK6UUUXXkURoIIYssxttxxxxttJJzzz7vc|}7L<+^Tk%%RDDDDdbKKKqA66UUU    //
//    fffffffffffffffi;~;;;!^=<*<*i\i|vzL|c7ci7z7i7zTiTz7i7zJ\TJJTctsz7z}jPwayyyyyyoamEkXXUUU6UUUUU66AbgEnIssYYnnnYYYYYYYYYIsstz77o}t7L<+iU%RDDDDddbKKqqA66U    //
//    jjjjjjjjjjjjjsr~;;!^+==*Li||v7i|7zL|v7LLzziizziizziizzvizzci7z7\zxt7zSEwaoyyyyyoaSwEhkXUU66AAqK%NPIxYu{unnYnu{}}}{{{{}}}{uYzjZjjuz\?>7KRRDDDDdbbKKqqA6    //
//    jjjjjjjjjjjjc^;!!^r<?L?|c7L|77i|T7L|77||77L\7zL\zTL\z7i7zziTzzi\Jz7czxzykEZoyyyy5oaSmEhXUAqKKdNN5IY{unYInu}}}uu{}}}ffffffffYzUaaayjxTL|E%%RDDDDdbbKKqq    //
//    jjjjjjjjjjj|!!^+><*|icLLT7i|7vi?\7L|7c|L7c|77cL77iL7ziLzz\izzii7zvizzz\7njSPmoyyyy5oaSEkUqbDgQ%jY{uYtsn}}{YYu}ff}ff}fjjjjjjj}mXooaaay}7iYD%%RDDDDddbKK    //
//    jjjjjjjjjf|^r+>?|i|L77iL\7i|TTi*\vL|7i?Lvi|77iL77|i7vLi77L7z7iTz7i\zz\vJJv7}5SPmao55aZwX6b%BQqfuusttu{}YII{}f}}}}}fjjjjjjyyyj}%wooaaZa5uzIDg%%%RDDDDdb    //
//    jjjjjjjjji=><*?|\7\Lv7i|ivi?\\i*\vLL7i?iv|?77|i77|\7iLT7iLzz\izzii7zcizzz\7xz7JyZmhhEPXqDNQgSYunxzIu{YsIn}}{{n{}fjjffjjjyyy5yjDbaoaZSmSS5Y}Dggg%%RDDDD    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CICI is ERC721Creator {
    constructor() ERC721Creator("CityCitizens", "CICI") {}
}