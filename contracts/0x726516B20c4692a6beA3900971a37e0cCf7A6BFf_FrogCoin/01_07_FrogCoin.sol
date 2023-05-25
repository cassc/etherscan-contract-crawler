// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20Taxable} from "./extensions/ERC20Taxable.sol";

/**
 * MMMMMMMMMMMMMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMWXOxdlllloxOKNWNXXK000OOO000KXXX0OOkOO0XWMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMW0o:,''''''''';cc:;;,,,'''''',,;;;,''''',;cd0WMMMMMMMMMMMMM
 * MMMMMMMMMMNx;'''''''''''''''''''''''''''''''''''''''''',dXMMMMMMMMMMMM
 * MMMMMMMMMM0:',lol;'.';cllc,',''',,,,,''''',''''''''''''''dNMMMMMMMMMMM
 * MMMMMMMMMM0c':kkc'';;;d00x;'',,'','''''',lxl,....,:cll;'';xXWMMMMMMMMM
 * MMMMMMMMMMXo';dx;.':;'lOkc,'',,,,,'''''';dOc'.;c;,o00Ol'''':xXMMMMMMMM
 * MMMMMMMMMWO:'';:,'..'';::,',''''','''''',cd;..,:,,d0Od;''''''lKWMMMMMM
 * MMMMMMMMMKl,''''''''','''',,',,',,'''''''','''''',clc,''''''''cKMMMMMM
 * MMMMMMMMNd,''''','''''''''''''''''',,,'''''''''''''''''''''''''dNMMMMM
 * MMMMMMMWk;'','''''''''''''''''''''''''''''''''''','','','''''''cKMMMMM
 * MMMMMMW0c,','',''''''''''''''',,,,'''''''''''''',,,,;;;,,''''''cKMMMMM
 * MMMMMNkl::;,,,,,,'''''''''''''''',''''''',,,,;;::ccccllc;''''''oNMMMMM
 * MMMMMXo:lllllc:;;;;,,,,,,,,,,,,,,,;;;;::::::ccccllllllc;,''''':OMMMMMM
 * MMMMMWx:cccccccccc::::::::::::::::::::ccccccccllllcc:;,'''''';kWMMMMMM
 * MMMMMW0occlllllcccccccccccccccccccccclllllllcc::;,,,'''''''':OWMMMMMMM
 * MMMMMMWN0xoc:::::ccccclllllllccccccc::::;;,,,,'''''''''''',oKWMMMMMMMM
 * MMMMMMMMMMWX0koc,'',,,,,,,,,,,,,,,''''''',,''''''''''''';o0WMMMMMMMMMM
 * MMMMMMMMMMMMMMWN0xo;'''''''''''''''''''''''''''''''.';lxKWMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMWKko:,''''''''''''''''''''''.',;cdkKWMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMWNKOxolc:;,,'''''',,,;:codk0XWMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMWNNXK000OOO00KKXNWMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 *
 * @title FrogCoin
 * @custom:website www.plaguenft.com
 * @author @lozzereth (www.allthingsweb3.com)
 * @notice ERC20 implementation with variable, but optional, transfers taxing.
 */
contract FrogCoin is ERC20Taxable {
    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply_
    ) ERC20Taxable(name, symbol) {
        _mint(msg.sender, totalSupply_);
    }
}