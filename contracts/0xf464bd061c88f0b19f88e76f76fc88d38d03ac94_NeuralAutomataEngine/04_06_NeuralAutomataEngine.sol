/* SPDX-License-Identifier: MIT
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWMMMNNWWWWWWX00KNWWWWNNWWNWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMWWMWWMMWWNX00Okkkdlloddoolc,,loooollooooxkkOKXNNNWWWWWMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMWWWNWMWXKXK00kddl:ll:;lo:cdxxood:.,c:l:'.',,..''';:coxO0XXNNWWWMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMNXXK0O00dcccccldOkxkOxokkooxxdloo'.c:;:;',;;'.'..'.',,,;cok0KXNNWWWMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMWWNKxl:;;;c;,cdkkxkkdllc;:l;''''',..........','.'..........,:lx0KXXNNWWMMMMMMMMMMM
MMMMMMMMMWNNNMMWWWXKkdc;;:;::;,,',:;,'''''.....   ...         ..................,:ok0KXNNWWMMMMMMMMM
MMMMMMMMWWX00KKXXOdllodkOdclc::,..      .....    ..............      ........  ...';lx0KXXNNWWMMMMMM
MMMMMMMMWNXXOoooccokOOOO0kddl:;'.   ....   ...'',::;:loc,;::;,....    .''.......  ..',:dOKKXNNWMMMMM
MMMMMMMMMWX0Oxc;::;:clccc:;,.......':c:. ..:oooox0KOOOo,..,:ll:,'...  .:ooc;'''..    ...:dO0KXNWMMMM
MMMMMMMWNNNK0kdl:,.............,;coOKOl'..'cxkO0XNNKd;.    .;ll:,......;dOOkdl:,''..    .,cxkOKXWMMM
MMWWMMMWNX0xkxl;,......    .'cdkKXNNN0l'.,:ldxddxxo:.       ;odl;,....';dOKKK0d:;;,,'......,lxk0XWMM
MMWNXXNWWX0kl;;,...      ..ckKXWWWWMWXx:cdkkxxxxdol:,..    'lxdc;;'''.'ckKXXXK0xlc;,,;;,'..',cxOXWMM
MMMMWXK0KX0xc;;::;.......;oOXNWWMMMMMWXkodxOKXKOxddddo;'';coxoc:;,'''';dKNNNXK0kdl:;:cclolclccxKNWMM
MMMMWWWNX0kdc;;;,,';lxkl,,lOXWWMMMMMMMMXxoloddddddxxdxxdodddxl;;:;,'.,o0NNNNXK0koc::cclkK0kkddOXNWMM
MMMWNXXXNXKKKKKkxxddxdddo:;l0NMMMMMMMMMMXkl:ccooc:::loooccc:l:,;,,..,o0NWNNNK0kdl;,;;coxxdc;:dKNNWMM
MMMMMMMMMMMMWWWNNXKOdoddxddoxKNWMMMMMMMMMW0o:;::;;:c::cc:;;;;,'...':xKXNXXKKOkxl;'.....'''':xXWWWWWM
MMMMMMMMMMMMMMMMMMN0xodddxkkddk0NWMMMMMMMMMNkl;',;;;,,;'''.......,lkKKXK0Oxoc;,.......;ldkOKNWWWWWMM
MMMMMMMMMMMMMMMMMWNXXK0OkddxkkkkkkOKNWMMMMMMMNKkolc:,''.....'';ldk00Oxdoc;'...,;:cloodOKKXXNNWWWWMMM
MMMMMMMMMMMMMMMMMWMMMWNX0kkxxdloc:cloxxkOKXXXNNNXKK0kddoolllooddoccc:,',,;;:clxkO000KXXXXNNNNNWWMMMM
MMMMMMMMMMMMMMMMMMMMMWWNXNN0oooddllllolccllcloodddoolllccccccloxl,,:c:;::ldxkO0KXXXXXXXXXNNNWWMMMMMM
MMMMMMMMMMMMMMMMMMMMMMWNWMN0OOO00kxxxocoxdoccldxlcloocodllc;;:clc,;:cllddkO0000KKKKKKXXNNWWWMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMWNNKKXNWNXKOxOKOdodxxxdc:;:c:cl:;:;:::cccldkOOOOO00000KK0KKXXNWWMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMWNNNMMMWWNXKKXNKXXK00Oxlc:lddlllllldxkOkO00000OOO000000KKXXNWWMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMWNNMMMMWNNWXXNNNNNKKXK0kxxO0OO0OO0KXXKKK00000K00K000KXXXNNWWMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMWNXNWWWWNNNNX0KXNNNNNXXXXXKKKKKKKKXKKKKKXXNNNWWWMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMWWWWWNNWWNNNNXXXXXXXXXXXXKXXXNNWWWWWWMMMMMMMMMMMMMMMMMMMM
*/

pragma solidity 0.8.15;

import {INeuralAutomataEngine, NCAParams} from "./interfaces/INeuralAutomataEngine.sol";
import {IFileStore} from "../lib/ethfs/packages/contracts/src/IFileStore.sol";
import {Base64} from "./utils/Base64.sol";

contract NeuralAutomataEngine is INeuralAutomataEngine {

    IFileStore fileStore;

    string public baseScript;

    constructor(address _fileStore, string memory _baseScript){
        fileStore = IFileStore(_fileStore);
        baseScript = _baseScript;
    }

    function parameters(NCAParams memory _params) public pure returns(string memory) {
        return string.concat(
            "let seed = ",
            _params.seed,
            "; let bg = ",
            _params.bg,
            "; let fg1 = ",
            _params.fg1,
            "; let fg2 = ",
            _params.fg2,
            "; let matrix = ",
            _params.matrix,
            ";function activation(x){",
            _params.activation,
            "} function rand() {",
            _params.rand,
            "}"
        );
    }

    function p5() public view returns(string memory) {
        return string.concat(
            "<script type=\"text/javascript+gzip\" src=\"data:text/javascript;base64,",
            fileStore.getFile("p5-v1.5.0.min.js.gz").read(),
            "\"></script>",
            "<script src=\"data:text/javascript;base64,",
            fileStore.getFile("gunzipScripts-0.0.1.js").read(),
            "\"></script>"
        );
    }

    function script(NCAParams memory _params) public view returns(string memory) {
        return string.concat(
            "<script src=\"data:text/javascript;base64,",
            Base64.encode(
                abi.encodePacked(
                    string.concat(
                        parameters(_params),
                        baseScript,
                        _params.mods
                    )
                )
            ),
            "\"></script>"
        );
    }

    function page(NCAParams memory _params) public view returns(string memory) {
        return string.concat(
            "data:text/html;base64,",
            Base64.encode(
                abi.encodePacked(
                    string.concat(
                        "<!DOCTYPE html><html style=\"height: 100%;\"><body style=\"margin: 0;display: flex;justify-content: center;align-items: center;height: 100%;\">",
                        p5(),
                        script(_params),
                        "</body></html>"
                    )
                )
            )
        );
    }
}