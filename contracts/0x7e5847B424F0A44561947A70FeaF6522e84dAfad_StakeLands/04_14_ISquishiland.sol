// Squishiland by Squishiverse (www.squishiland.com / www.squishiverse.com)

// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNOdlod0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMWKx:'....,lkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMWKxc'..;cll:,..,lkXWMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMWXkc'..,cldddddol;'..,lOXWMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMWXkl,..,:lddoodoooooool:'..;oOXWMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMWXOl,..';lodddooodddollloodol;...;o0NWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMWNOl,..';cloddddxxxxxddollodddddoc:,...;o0NWMMMMMMMMMMMMM
// MMMMMMMMMMMNOo;..';coooodxxxxxkkxdddoodxxxddddooolc;...:d0NMMMMMMMMMMM
// MMMMMMMMN0o;...;coddddddxxxxxddddddddxkOkkxdxxxxddddo:,...:xKNMMMMMMMM
// MMMMMN0d:...;lodddddxxxxxxxxdddxxxddxkkkxxxxdxxxxxxddolc;'..'cxKWMMMMM
// MMN0d:'..,:odxxddddxxkOOkxxxddodxxxxdddddddddxxxxxddollllol:,..'cxKWMM
// Kd:'..,:coodddddddxxxkkkkxxxddoodddddxxxxxdxkOO00kdolllloooool:,..'ckX
// :..';cooooodddddddddddddddddddoooooddxxxxxxxxk00Okddoolloooodddol:'..l
// '..:cloooooddddddddddddddddxxdddoooooddddddxxxxxxdoooooddddddollcl;..:
// ;..',;coddddddddddddddddxxxdddddddddddoooddxxxxxdolllloooooooolc::,..c
// c....',;clooooddddddddxxxxxddddddddddddddddddxxxollllllllclllcc;;;'..o
// o.......';::cldddddddxxxxxxxdddddddddddddddddooolllooooolc:::;;,,,'..d
// x. .......'',:loddddddddddddddxkkxddddddddddddollloooolc:,;,,,''',. .x
// k. ..........',;clooooooddddddxO0Okkxddoooddddoolcccc:;,''''''''''..'O
// O' .............',;;:clloddddxkOOkkkxooooollllool:;,,,''''''''.'''..;0
// O,..................';:cloodddxxdooollooooolccccc:,''',,,,'''.......:K
// 0;...................',,;:clddooloddoloddolc::::;,,''',,,''.........lX
// 0:......................'',;clooodxxdolllc:;,,,,,'''''''''..........dN
// Kc. .......................',,:coxxddl:;;,,''''''',,,''.'......... .xN
// Xo. .........................',;:loll:;,''''''''',,,''............ 'kW
// Nd. ...........................',;:::;,,,,'',,,''',''............. 'OW
// Wk' ............................',;;;,,,;,'',,,'''''.............. 'OM
// M0;. ............ ..............',,,;;;,,'''''''...................;0M
// MNk;.  ..........................',,;;,''''''''...................:OWM
// MMWXOl'.  ............ ..........',,,,''''''''.................,lONWMM
// MMMMMWKx:.. .....................',,,,''...'''..............'ckXWMMMMM
// MMMMMMMMNOo,.  ..................',,,''...................,d0NMMMMMMMM
// MMMMMMMMMMWKkc..  ...............'',''.................'lkXWMMMMMMMMMM
// MMMMMMMMMMMMMW0o,.  ..............'''................;dKWMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWXkc'.  ...........................,lONWMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMN0d;.   ......................:xXWMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMWXkc'.  ........''.......,o0NMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMWKx:.. ............'ckXWMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMNOo,..........;d0NMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkc'....'lOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOocld0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {IERC721, IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @title ISquishiland
 * @author @lozzereth (www.allthingsweb3.com)
 * @notice Interface for the Squishiland ERC721 contract.
 */
interface ISquishiland is IERC721 {
    /// @dev Land sizes
    enum LandSize {
        Rare,
        Epic,
        Legendary,
        Mythic
    }

    /// @dev Attribute for each piece of land
    struct LandAttribute {
        uint256 price;
        uint256 supply;
        uint256 startingId;
        uint256 minted;
        uint256 burnt;
    }

    /**
     * @notice Fetch total supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Fetch total burnt
     */
    function totalBurnt() external view returns (uint256);

    /**
     * @notice Burn a piece of land
     */
    function burn(uint256 tokenId) external;

    /**
     * @notice Fetch the total minted on a per size basis
     */
    function totalSupplyBySize(LandSize _size) external view returns (uint256);

    /**
     * @notice Fetch the total burnt on a per size basis
     */
    function totalBurntBySize(LandSize _size) external view returns (uint256);

    /**
     * @notice Get the land size for a token
     */
    function getLandSize(uint256 _tokenId) external view returns (LandSize);
}