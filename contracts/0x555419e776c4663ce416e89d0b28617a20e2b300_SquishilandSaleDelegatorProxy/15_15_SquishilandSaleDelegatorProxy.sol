// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNOdlod0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMWKx:'....,lkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMWKxc'..;cll:,..,lkXWMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMWXkc'..,cldddddol;'..,lOXWMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMWXkl,..,:lddoodoooooool:'..;oOXWMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMWXOl,..';lodddooodddollloodol;...;o0NWMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMWNOl,..';cloddddxxxxxddollodddddoc:,...;o0NWMMMMMMMMMMMMM
 * MMMMMMMMMMMNOo;..';coooodxxxxxkkxdddoodxxxddddooolc;...:d0NMMMMMMMMMMM
 * MMMMMMMMN0o;...;coddddddxxxxxddddddddxkOkkxdxxxxddddo:,...:xKNMMMMMMMM
 * MMMMMN0d:...;lodddddxxxxxxxxdddxxxddxkkkxxxxdxxxxxxddolc;'..'cxKWMMMMM
 * MMN0d:'..,:odxxddddxxkOOkxxxddodxxxxdddddddddxxxxxddollllol:,..'cxKWMM
 * Kd:'..,:coodddddddxxxkkkkxxxddoodddddxxxxxdxkOO00kdolllloooool:,..'ckX
 * :..';cooooodddddddddddddddddddoooooddxxxxxxxxk00Okddoolloooodddol:'..l
 * '..:cloooooddddddddddddddddxxdddoooooddddddxxxxxxdoooooddddddollcl;..:
 * ;..',;coddddddddddddddddxxxdddddddddddoooddxxxxxdolllloooooooolc::,..c
 * c....',;clooooddddddddxxxxxddddddddddddddddddxxxollllllllclllcc;;;'..o
 * o.......';::cldddddddxxxxxxxdddddddddddddddddooolllooooolc:::;;,,,'..d
 * x. .......'',:loddddddddddddddxkkxddddddddddddollloooolc:,;,,,''',. .x
 * k. ..........',;clooooooddddddxO0Okkxddoooddddoolcccc:;,''''''''''..'O
 * O' .............',;;:clloddddxkOOkkkxooooollllool:;,,,''''''''.'''..;0
 * O,..................';:cloodddxxdooollooooolccccc:,''',,,,'''.......:K
 * 0;...................',,;:clddooloddoloddolc::::;,,''',,,''.........lX
 * 0:......................'',;clooodxxdolllc:;,,,,,'''''''''..........dN
 * Kc. .......................',,:coxxddl:;;,,''''''',,,''.'......... .xN
 * Xo. .........................',;:loll:;,''''''''',,,''............ 'kW
 * Nd. ...........................',;:::;,,,,'',,,''',''............. 'OW
 * Wk' ............................',;;;,,,;,'',,,'''''.............. 'OM
 * M0;. ............ ..............',,,;;;,,'''''''...................;0M
 * MNk;.  ..........................',,;;,''''''''...................:OWM
 * MMWXOl'.  ............ ..........',,,,''''''''.................,lONWMM
 * MMMMMWKx:.. .....................',,,,''...'''..............'ckXWMMMMM
 * MMMMMMMMNOo,.  ..................',,,''...................,d0NMMMMMMMM
 * MMMMMMMMMMWKkc..  ...............'',''.................'lkXWMMMMMMMMMM
 * MMMMMMMMMMMMMW0o,.  ..............'''................;dKWMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMWXkc'.  ...........................,lONWMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMN0d;.   ......................:xXWMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMWXkc'.  ........''.......,o0NMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMWKx:.. ............'ckXWMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMNOo,..........;d0NMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkc'....'lOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOocld0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * @title SquishilandSaleDelegator
 * @custom:website www.squishiland.com
 * @author Lozz (@lozzereth / www.allthingsweb3.com)
 * @notice Delegation proxy contract for Squishiland by Squishiverse
 */
contract SquishilandSaleDelegatorProxy is ERC1967Proxy {
    constructor(address _implementation, bytes memory _data)
        ERC1967Proxy(_implementation, _data)
    {}
}