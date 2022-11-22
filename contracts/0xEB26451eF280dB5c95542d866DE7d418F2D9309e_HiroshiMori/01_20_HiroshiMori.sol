// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "./XYZA.sol";
import "./interfaces/IGameData.sol";

//                                                                         #"@m
//                              ,-w            am, ,MMw      ,,ee,  ,e,    @m#"
//                          ,m#"   @     ;##m#"  j#   @  ;##`     '@   5##m,#`"#m,
//                      ,##`    ,#M`  ,##   '         @#`     "WM   `  #M j##m    `#Mw
//                  ,##`   ,a#"     ;#`  ,   ,#b  ,#    ,  ##M    se##M  ^`    s#m,    5#m,
// ;#""########MMM#^    -%85####""^^    ``                                                 ``^^""####M,
// %m,,                      ,,,,    ,,,,sssssseeeeeeeeeeeeeeeemmmmmmmmmmmmmmmmmmmmmmmmeew,     ,,, ,,#
//         @"   ,#MMmw,,      "`  ,#"                                                      "%m  @b
//         7ms#"         `""@p  sM                                                            ``
//                            ``

contract HiroshiMori is XYZA {
    constructor(IGameData _gameDataContract)
        XYZA("Hiroshi Mori", "morihiroshii")
    {
        gameDataContract = _gameDataContract;
    }

    IGameData public gameDataContract;

    function setGameDataContract(IGameData _gameDataContract)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        gameDataContract = _gameDataContract;
    }

    function gameData() public view returns (string memory) {
        return gameDataContract.gameData();
    }
}