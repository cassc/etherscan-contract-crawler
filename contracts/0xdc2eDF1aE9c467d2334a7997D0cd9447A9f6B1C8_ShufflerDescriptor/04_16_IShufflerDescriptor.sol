// SPDX-License-Identifier: GPL-3.0

/// @title Interface for ShufflerDescriptor

/**************************************************************************
...........................................................................
...........................................................................
...........................................................................
...........................................................................
.....................     ...............      .......      ...............
...................  .?5?:  ........... .::::::. ... .:::::.  .............
.................  :?B&@&B?:  ....... .^7??????!:. .~7??????~: ............
...............  :J#&&&&&&&#J:  .....^7??????JJJ?!!7????JJJ?J?!............
.............  ^Y#&&&&&&&&&&&#Y^  .. !J??YGGP^^~?JJ?5GGJ^^~????: ..........
...........  ^5&@&&&&&&&&&&&&&@&5~   [email protected]@B. [email protected]@Y  :????:...........
.......... :5&&BBB###&&&&#BBB###&&P: [email protected]@B. [email protected]@Y  :???7............
......... ^P&&#:..7J?G&&&5..:??J#&&G~ ~??J55Y!!!????Y5PJ!!!??7.............
......... [email protected]&&#.  7??G&&&5  :??J#&&@7  ^?????JJJ????????JJJ?7..............
......... [email protected]&&#~^^JYJB&&&P^^~JYY#&&@7 ..:~?J??????????????7^...............
......... :JB&&&&&&&&B#&#B&&&&&&&&#J: ..  .~?J????????J?!:. ...............
..........  :?BBBBBB5YB&BY5BBBBBB?:  .....  .~77???J?7!:. .................
............  ....^Y#@@&@@#Y^....  .......... ..^!7~:.. ...................
..............   .!777???777!.   ............   :^^^.   ...................
..................  .^7?7^.  .............. .~Y5#&&&G57: ..................
................  :~???????~:  .............!&&&&&&&&@@5:..................
.............. .:!?J???????J?!:  ......... ~&&&&&&&&&&&@5 .................
............ .:!??JJJ????????J?!:. ......  ^B&&&&&&&&&&&J  ................
............^!JGBG!^^7???YBBP^^~?!^. .   .^^~YG&&&&&&#57^^:   .............
......... :7??J&&&^  [email protected]@B. .?J?7: :?5G&&&#PY#&&&P5B&&&#5Y^ ............
...........~7?J&&&^  [email protected]@B. .?J?~.:Y&@G77?555#&&&Y!7J55P&&#~............
........... .^75557!!7???J55Y!!!7~.  [email protected]&&5  .???#&&&7  ^??Y&&&&: ..........
............. .^7?JJ?????????J7^. .. J&&&5  .??J#&&&7  ^??Y&&&G: ..........
............... .^7?J???????7^. ..... ?#@#55PBG5#&&&5J5PBBB&&P: ...........
................. .:!?JJJ?!:. ........ ^!JBBBGYP&&&&B5PBBBP!!. ............
................... .:!7!:. ...........   ..:JGBGGGGBG5~ ..   .............
..................... ... ................. ............ ..................
...........................................................................
...........................................................................
...........................................................................
...........................................................................
***************************************************************************/

pragma solidity ^0.8.6;

import { IShufflerToken } from './IShufflerToken.sol';

interface IShufflerDescriptor {
    event PartsLocked();

    event DataURIToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    function arePartsLocked() external returns (bool);

    function isDataURIEnabled() external returns (bool);

    function baseURI() external view returns (string memory);

    function palettes(uint8 paletteIndex, uint256 colorIndex) external view returns (string memory);

    function backgrounds(uint256 index) external view returns (string memory);

    function cards(uint256 index) external view returns (bytes memory);

    function sides(uint256 index) external view returns (bytes memory);

    function corners(uint256 index) external view returns (bytes memory);

    function centers(uint256 index) external view returns (bytes memory);

    function backgroundCount() external view returns (uint256);

    function cardCount() external view returns (uint256);

    function sideCount() external view returns (uint256);

    function cornerCount() external view returns (uint256);

    function centerCount() external view returns (uint256);

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external;

    function addManyBackgrounds(string[] calldata backgrounds) external;

    function addManyCards(bytes[] calldata cards) external;

    function addManySides(bytes[] calldata sides) external;

    function addManyCorners(bytes[] calldata corners) external;

    function addManyCenters(bytes[] calldata centers) external;

    function addColorToPalette(uint8 paletteIndex, string calldata color) external;

    function addBackground(string calldata background) external;

    function addSide(bytes calldata side) external;

    function addCorner(bytes calldata corner) external;

    function addCenter(bytes calldata center) external;

    function lockParts() external;

    function toggleDataURIEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(uint256 tokenId, IShufflerToken.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, IShufflerToken.Seed memory seed) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        IShufflerToken.Seed memory seed
    ) external view returns (string memory);

    function generateSVGImage(IShufflerToken.Seed memory seed) external view returns (string memory);

    function isComposable(address addr) external view returns (bool);
}