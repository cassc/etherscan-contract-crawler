// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: iAmFuture's Edition Pieces
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                  //
//                                                                                                                                                                                                  //
//    |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||ubbbbbbbbbbbbbbbbbbbbbbbbbbbbw|||||||||||||||||||||||||||||||||||||||||||||||||||||||Xbbbbbbbbbbbbbbbbbbbbb    //
//    |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||ubbbbbbbbazpkbbbbbbbbbbbbbbbbJ||||||||||||||||||||||||||||||||||||||||||||||||||||||rbbbbbbbbbbbbbbbbbbbbbb    //
//    |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||xbbbbbbbbbkvuChbbbbbbbbbbbbbbf|||||||||||||||||||||||||||||||||||||||||||||||||||||tdbbbbbbbbbbbbbbbbbbbbbb    //
//    |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||tbbbbbbbbbbbvuuwkbbbbbbbbbbbb|||||||||||||||||||||||||||||||||||||||||||||||||||||jbbbbbbbbbbbbbbbbbbbbbbbb    //
//    ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||bbbbbbbbbbbhuuuchbbbbbbbbbbp|||||||||||||||||||||||||||||||||||||||||||||||||||||dbbbbbbbbbbbbbbbbbbbbbbbb    //
//    ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||wbbbbbbbbbbbCuuuuhbbbbbbbbbJ||||||||||||||/kv|||||||||||||||||||||||||||||||||||Obbbbbbbbbbbbbbbbbbbbbbbbb    //
//    ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||zbbbbbbbbbbbauuuuupbbbbbbbbJ||||||||||||||QuC|||||||||||||||||||||||||||||||||/qbbbbbbbbbbbbbbbbbbbbbbbbbb    //
//    |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||bbbbbbbbbbbbwuuuuuqbbbbbbbv|||||||J/||||JuuX|||||||||||||||||||||||||||||||||Cbbbbbbbbbbbbbbbbbbbbbbbbbbb    //
//    |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||kbbbbbbbbbbbhuuuuuuhbbbbbbt||||||Up||||tUuun||||||||||||||||||||||||||||||||Xbbbbbbbbbbbbbbbbbbbbbbbbbbbb    //
//    bj|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||qYobbbbbbbbbbauuuuuCbbbbbb||||||JXf|||tXuuuv|||||||||||||||||||||||||||||||cbbbbbbbbbbbbbbbbbbbbbbbbbbbbb    //
//    bbv||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||OhYuZkbbbbbbbkYuuuuukbbbbm|||||jXQ|||/kuuuuu||||||||||||||||||||||||||||||fbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb    //
//    bbbO|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||0bbduuwbbbbbbbQuuuuucbbbbu||||vuuX|||CuuuuL/|||||||||||||||||||||||||||||rbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb    //
//    bbbbdf|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||Xbbbbuuupbbbbbouuuuuudbbbu|||zXucn||Cuuuuuw|||||||||||||||||||||||||||||fbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb    //
//    bbbbbbz||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||fbbbbquuuchbbbkcuuuuuuhbbj||cXuuQ|/OuuuuuY/|||||||||||||||||||||||||||||qbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb    //
//    bbbbbbbO||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||bbbbbauuuuqbbbQuuuuuumbb/|nvuuvjtZuuuuuuw||||||||||||||||||||||||||||/qbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb    //
//    bbbbbbbbdf|||||||||||||||||||||||||||||||||||||azf/|||||||||||||||||||||||||||||||pbbbbbLuuuvJO-Luuuuvvmbb|YuuucuUzuuuuuuO|||||||||||||||||||||||||||||wbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbm|    //
//    bbbbbbbbbbz|||||||||||||||||||||||||||||||||||||xLuuwXt||||||||||||||||||||||fvYqwLCQmpppYC]---|zx-------uYuuuuOmuuuuuuuuY||||||||||||||||||||||||||||Cbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbx||    //
//    bbbbbbbbbbb0||||||||||||||||||||||||||||||||||||||rJvuuCCj|||YnzczrY/|||||tLcuuuuuuuuuuuux----0--------xCuuuuuXuuuuuuuuuO||||||||||||||||||||||||||||JbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbO||||    //
//    bbbbbbbbbbbbbf||||||||||||||||||||||||||||||||||||||/LcuuuYZf-------?ju||mcuuuuuuuuuuuuuuL]-]Y------(UvuuuuuuuuuuuuuuuuUf|||||||||||||||||||||||||||xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbn|||||    //
//    bbbbbbbbbbbbbbz|||||||||||||||||||||||||||||||||||||||/QzuuuuY0--------]puuuuuuuuuuuuuuuuuuuuuJmLvcuuuuuuuuuuuuuuuuuuuJt|||||||||||||||||||||||||||nbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbd/||||||    //
//    bbbbbbbbbbbbbbbO/|||||||||||||||||||||||||||||||/tffffftfOuuuuuuL]------juuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuucJq/-]cpzQ|||||||||||||||||||||||||||jbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbL||||||||    //
//    bbbbbbbbbbbbbbbbdt||||||||||||||||||||||vzwZcuuuuuuuuuuuuuuuuuuuuuQnffLXuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuYX----------|z|||||||||||||||||||||||||/bbbbbbbbbbbbbbbbbbbbbbbbbbbbbdf|||||||||    //
//    bbbbbbbbbbbbbbbbbbu||||||||||||||||||||||||jzCUvU0UuuuuuuuuuuuuuuuUJXuuuuuuuuuuuuuUQ]-----]fcXCuuuuuuuuuXv--------------Ut||||||||||||||||||||||tqbbbbbbbbbbbbbbbbbbbbbbbbbbbbQ|||||||||||    //
//    bbbbbbbbbbbbbbbbbbbC||||||||||||||||||||||||||||||||/nvqYuuuuu0j-------|vcuuuuuuuuuuuL----------(xmuuuuun----------------v||||||||||||||||||||||dbbbbbbbbbbbbbbbbbbbbbbbbbbbbn||||||||||||    //
//    bbbbbbbbbbbbbbbbbbbbq|||||||||||||||||||||||||||||||||||U-?}CZ------------{dqkhhdcuuuuvQ-------------[}/dd---rZ[?[n-------t/|||||||||||||||||||Obbbbbbbbbbbbbbbbbbbbbbbbbbbp/|||||||||||||    //
//    bbbbbbbbbbbbbbbbbbbbbbt|||||||||||||||||||||||||||||||||Z?}}[X][[}]--------(--------)wcv0--------------------------}b)]----b||||||||||||||||||0bbbbbbbbbbbbbbbbbbbbbbbbbbbu|||||||||||||||    //
//    bbbbbbbbbbbbbbbbbbbbbbbv|||||||||||||||||||||||||||||fXwuuuuuuuuuuuuuCZjt{zJ}------------}---------(-------------------)}---v|||/zdaooqcv/|||Ybbbbbbbbbbbbbbbbbbbbbbbbbbp|||||||||||||||||    //
//    bbbbbbbbbbbbbbbbbbbbbbbbQ||||||||||||||||||||||||||zq0O0CXvuuuuuuuuuu0}-------xx------------------}(-------t?-----](t1-]}---[C|JbddddddddddkwhkbbbbbbbbbbbbbbbbbbbbbbbbL||||||||||||||||||    //
//    bbbbbbbbbbbbbbbbbbbbbbbbbp||||||||||||||||||||||||||||||m-----]t/CLJt-------_---](--------------{X------------j|i       ;+X--}bbkdddddddddddddddkkabbbbbbbbbbbbbbbbbbbx|||||||||||||||||||    //
//    bbbbbbbbbbbbbbbbbbbbbbbbbbbr||||||||||||||||||||||||||||j)-----------------------/------------Ol     ."J-----n              v-1dddaddddddddddddddddddbabbbbbbbbbbbbbZ/||||||||||||||||||||    //
//    bbbbbbbbbbbbbbbbbbbbbbbbbbbbU||||||||||||||||||||||||||||z[--------------pt[}]?[b----------[f            0]-u                }1bdddbdddddddddddddddddddddkhkbbbbbbbv||||||||||||||||||||||    //
//    bbbbbbbbbbbbbbbbbbbbbbbbbbbbbw/|||||||||||||||||||||||||||j|-_-----------Cuuuuuzr--------1x               .nu          __     wddddbdddddddddddddddddddddddddhkbbq||||||||||||||||||||||||    //
//    bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbr|||||||||||||||||||||||||||x(-----------?Xuuuuuuuz------c"                 ,r         ,oo;    :ddddkdddddddddddddddddddddddddddddz||||||||||||||||||||||||    //
//    bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbU|||||||||||||||||||||||rf||t-----------[uuuuuuuuuc----?!         ^ob       m                 :bdddddddddddddddddddddddddddddddddddqc|||||||||||||||||||||    //
//    bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbw/|||||||ukpbddddddddkddddpn-----------{uuuuuuuuuuw---[`          ^`       aqd/              {dddhdddddddddddddddddddddddddddddddddddL|||||||||||||||||||    //
//    bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbt||/LddddddddddddddddbddddO----------(vuuuuuuuwZuZ--?<                  )----_0"          (dddbdddddddddddddddddddddddddddddddddddddbJ|||||||||||||||||    //
//    ZbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbJadddddddddddddddddddkbdddb)--------zuuuuuuuuuJ}Jz--vI                <t-------jj]_>!!i>qdddbddddddddddddddddddddddddddddddddddddddddbt|||||||||||||||    //
//    |/JbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbhkddddddddddddddddddddddbhddddC----?vYuuuuuuuuuuuU]1c--{f.            >u?------------------(kdddddddddddddddddddddddddddddddddddddddddddkf||||||||||||||    //
//    ||||Xbbbbbbbbbbbbbbbbbbbbbbbbbbbhkddddddddddddddddddddddddddkddddd]xvYvuuuuuuuuuuuuuw-------|v:    .|jt?----------------------{bdddddddddddddddddddddddddddddddddddddddddddJ||||||||||||||    //
//    ||||||nbbbbbbbbbbbbbbbbbbbbbbbhbdddddddddddddddddddddddddddddkddddk/||fQuuuuuuuuuuuuuf----------------------------------------wUkddddddddddddddddddddddddddddddddddddddddddC||||||||||||||    //
//    ||||||||fdbbbbbbbbbbbbbbbbbbaddddddddddddddddddddddddddddddddddbdddj||||tqvvYO]--JvuuO-------------------------------}/xLbqj-------?ZqpbdddddddddddddddddddddddddddddddddddU||||||||||||||    //
//    ||||||||||jwbbbbbbbbbbbbbbhbdddddddddddddddddddddddddddddddddddkdbt|||||||C-------/Juuu----------------------------------------------------mdddddddddddbbbddddddddddddddddh|||||||||||||||    //
//    |||||||||||||mbbbbbbbbbbkbddddddddddddddddddddddddddddddddddddddC|||||||/C--]Z{tz---uYQ----------------------------------------------------ckbkkbdbkbddddddddddddddddddddbn|||||||||||||||    //
//    ||||||||||||||tJbbbbbbadddddddddddddddddddddddddddddddddddddddddJ|||||||/)--([j-------(---------------------------------------------------Ukbbkddddddddddddddddddddddddddb/|||||||||||||||    //
//    |||||||||||||||||Cbbhdddddddddddddddddddddddddddddddddddddddddddr||||||||Z-----1)------------------C,,,vp/-----------------------------0bbbbkbddddddddddddddddddddddddddk/||||||||||||||||    //
//    |||||||||||||||||thddddddddddddddddddddddddddddddddddddddddddddu||||||||||Xt------_--------------[b"^,      ' .)pJ1??/mU"     'I~}jhbbbbbbbhddddddddddddddddddddddddddddC|||||||||||||||||    //
//    |||||||||||||||/bddddddddddddddddddddddddddddddddddddddddddddd||||||||||||||tOf)fOO--------------|QLLLLpvcdQ0?.   :+?^      -i  ;fkbbbbbbbhddddddddddddddddddddddddddddY||||||||||||||||||    //
//    ||||||||||||||/kddddddddddddddddddddddddddddddddddddddddddbLt||||||||||||||||||||||U-------------/QLLLLLLLLLLLLLLLLLLLmxrUxbbbbbbbbbbbbbbaddddddddddddddddddddddddddddm|||||||||||||||||||    //
//    ||||||||||||||Ydddddddddddddddddddddddddddddddddddddddbkv/|||||||||||||||||||||||||/X------------[QLLLLLLLLLLLLLLLLLLOf-Jfbbbbbbbbbbbbbkkddddddddddddddddddddddddddddq/|||||||||||||||||||    //
//    ||||||||||||||0ddddddddddddddddddddddddddddddddddddokX||||||||||||||||||||||||||||||/f---------}--kLLLLLLLLLLLLLLLLQd?-d/dbbbbbbbbbbbbhbddddddddddddddddddddddddddddL|||||||||||||||||||||    //
//    ||||||||||||||UddddddddddddddddddddddddddddddddaddddokZ||||||||||||||||||||||||||||||x--------[(--wLLLLLLLLLLLLLLLL--tz/wbbbbbbbbbbbbadddddddddddddddddddddddddddddm||||||||||||||||||||||    //
//    ||||||||||||||/hddddddddddddddddddddddddddddddddddddddddkOv/|||||||||||||||||||||||||u]-------n?-/LLLLLLLLLLLLLLLc-{Y|/dbbbbbbbbbbbkkdddddddddddddddddddddddddddddm|||||||||||||||||||||||    //
//    |||||||||||||||rdddddddddddddddddddddddddddddddddddddddddddddbJx||||||||||||||||||||||J------))-[wLLLLmc)((nZLO0JvYt||LbbbbbbbbbbbabdddddddddddddddddddddddddddddJ||||||||||||||||||||||||    //
//    ||||||||||||||||rkdddddddddddddddddddddddddddddddddddddddddddddddbmj|||||||||||||||||Lm------U--QLLLOn(((((((((((((ntLbbbbbbbbbbbhddddddddddddddddddddddddddddddc|||||||||||||||||||||||||    //
//    |||||||||||||||||thddddddddddddddddddddddddddddddddddddddddddddddddddpU||||||||||||hdddt----u--ZLLLLL(((|q((((((((((mbbbbbbbbbbhbdddddddddddddddddddddddddddddbf||||||||||||||||||||||||||    //
//    |||||||||||||||||||kddddddddddddddddddddddddddddddddddddddddddddddddddddbqffrrff|Zdddddh---f}-zQLLLLm((((((vmtt|(|vdbbbbbbbkkkoddddddddddddddddddddddddddddddb||||||||||||||||||||||||||||    //
//    ||||||||||||||||||||jddddddddddddddddddddddddddddddddddddddddddddddddddddddddddbkddddddp]--O--bJvOZUUQ||||||/btfjv--Qkbkaddddddhddddddddddddddddddddddddddddp|||||||||||||||||||||||||||||    //
//    ||||||||||||||||||||||Jbddddddddddddddddddddddddddddddddddddddddddddddddddddddkbdddddddd)--U--?t                  iu-?Zddddddddddddddddddddddddddddddddddddm||||||||||||||||||||||||||xJbb    //
//    bbOv||||||||||||||||||||Lbdddddddddddddddddddddddddddddddddddddddddddddddddddhbddddddddd/--/(------------?][}{1))(/)--XdddddddddddddddddddddddddddddddddddQ|||||||||||||||||||||||fQbbbbbb    //
//    bbbbbbpX|||||||||||||||||/vbdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd|---?tb1-------------------OpdddhddddddddddddddddddddddddddddddddX|||||||||||||||||||||Qdbbbbbbbbb    //
//    bbbbbbbbbbbXf|||||||||||||||zddddddddddddddddddddddddddddddddddddddddddddddkddddddddddddn-----------------------?wdddddddhdddddddddddddddddddddddddddddbj|||||||||||||||||fCbbbbbbbbbbbbbb    //
//    bbbbbbbbbbbbbbbUr||||||||||||||0bddddddddddddddddddddddddddddddddddddddddddhdddddbkddkddq----------------------/ddddddddddbdddddddddddddddddddddddddddd|||||||||||||||jYbbbbbbbbbbbbbbbbbb    //
//    bbbbbbbbbbbbbbbbbbbCn||||||||||||rpbddddddddddddddddddddddddddddddddddddddhddddbkdddddbka----------------------nddddddddddddbddddddddddddddddddddddddd/|||||||||||/Ydbbbbbbbbbbbbbbbbbbbbb    //
//    bbbbbbbbbbbbbbbbbbbbbbbOn|||||||||||vaddddddddddddddddddddddddddddddddddddbdddkdddddddddb----------------------wddddddddddddbbddddddddddddddddddddddh/||||||||/Cqbbbbbbbbbbbbbbbbbbbbbbbbb    //
//    bbbbbbbbbbbbbbbbbbbbbbbbbbbpx|||||||||/chdddddddddddddddddddddddddddddddddbdbbdddddddddddh---------------------bddddddbdddbddkdddddddddddddddddddddq|||||||Udbbbbbbbbbbbbbbbbbbbbbbbbbbbbb    //
//    bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbnt||||||||XbddddddddddddddddddddddddddddddbkdddddddddddddL.mf---------------[c|!dddddbdddddhddbdddddddddddddddddddU|||tvbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb    //
//    bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbdYf|||||||zqbdddddddddddddddddddddddddddddddddddddddddb'  'z/t{----?/)U>     ,bdbkdddddddhbkddddddddddddddddddufcbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb    //
//    bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbdUj||||||jQkddddddddddddddddddddddddddddddddddddddd0                      Ydddddddddddkdddddddddddddddddbkbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb    //
//    bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbd0j|||||/vmkdddddddddddddddddddddddddddddddddddm'                      Qdddddddddddadddddddddddddddkkbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb    //
//    bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbpr||||||tuodddddddddddddddddddddddddddddddb^                      <dddddddddddbbdddddddddddddbkbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb    //
//    pbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbxt||||||Jpddddddddddddddddddddddddddddr                       JdddddddddddhddddddddddddbkbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbdpqU|||||||    //
//    |||||||nL0Zdbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbdct|||||Xkddddddddddddddddddddddddd*                       !ddddddddddddbddddddddddhbbbbbbbbbbbbbbbbbbbbbbbbbbbw0Cx|||||||||||||||    //
//    |||||||||||||||||vYUQdbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbdUt|Uddddddddddddddddddddddddddh                        ddddddddddddbdddddddddhkbbbbbbbbbbbbbbbbbbqUUv||||||||||||||||||||||||    //
//    ||||||||||||||||||||||||||txucwbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbkddddddddddddddddddddddddddb                        "bddddddddddbbdddddddakbbbbbbbbbbdCunt||||||||||||||||||||||||||||||||    //
//    ||||||||||||||||||||||||||||||||||||tffnqbbbbbbbbbbbbbbbbbbbbbbkbddddddddddddddddddddddddddd`                        Zdddddddddddbddddddkbbbbmrft/||||||||||||||||||||||||||||||||||||||||    //
//    |||||||||||||||||||||||||||||||||||||||||||||||||Xmppbbbbbbbbbbodddddddddddddddddddddddddddd"                        cdddddddddddbdddddm||||||||||||||||||||||||||||||||||||||||||||||||||    //
//    ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||/UQOwbdddddddddddddddddddddddddddd"                        1ddddddddddddhdddq|||||||||||||||||||||||||||||||||||||||||||||||||||    //
//    ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||jbdddddddddddddddddddddddddddd^                        .bddddddddddddbdZ||||||||||||||||||||||||||||||||||||||||||||||||||||    //
//    ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||oddddddddddddddddddddddddddddd'                         addddddddddddhQ|||||||||||||||||||||||||||||||||||||||||||||||||||||    //
//    |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||udddddddddddddddddddddddddddddk                          zdddddddddddddL|||||||||||||||||||||||||||||||||||||||||||||||||||||    //
//                                                                                                                                                                                                  //
//                                                                                                                                                                                                  //
//                                                                                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract iAFEP is ERC1155Creator {
    constructor() ERC1155Creator("iAmFuture's Edition Pieces", "iAFEP") {}
}