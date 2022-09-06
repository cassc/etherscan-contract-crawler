// SPDX-License-Identifier: GPL-3.0

/// @title The Shuffler NFT descriptor

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

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';
import { IShufflerDescriptor } from './interfaces/IShufflerDescriptor.sol';
import { IShufflerToken } from './interfaces/IShufflerToken.sol';
import { NFTDescriptor } from './libs/NFTDescriptor.sol';
import { MultiPartRLEToSVG } from './libs/MultiPartRLEToSVG.sol';

contract ShufflerDescriptor is IShufflerDescriptor, Ownable {
    using Strings for uint256;

    // prettier-ignore
    // https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt
    bytes32 constant COPYRIGHT_CC0_1_0_UNIVERSAL_LICENSE = 0xa2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499;

    // Whether or not new Shuffler parts can be added
    bool public override arePartsLocked;

    // Whether or not `tokenURI` should be returned as a data URI (Default: true)
    bool public override isDataURIEnabled = true;

    // Base URI
    string public override baseURI = "ipfs://bafkreibjf4si2fmawhsh6j4vk3dws35poak5pf5rssar4sgedxgk7psdki";

    //  Color Palettes (Index => Hex Colors)
    mapping(uint8 => string[]) public override palettes;

    // Shuffler Backgrounds (Hex Colors)
    string[] public override backgrounds;

    // Shuffler card （Custom RLE)
    bytes[] public override cards;

    // Shuffler frames (Custom RLE)
    bytes[] public override sides;

    // Shuffler ranks and suites (Custom RLE)
    bytes[] public override corners;

    // Shuffler centers (Custom RLE)
    bytes[] public override centers;

    mapping (address => bool) public composableContracts;

    constructor() {
        composableContracts[NFTDescriptor.NOUNS_CONTRACT] = true;
        composableContracts[NFTDescriptor.PUNK_ORIGINAL_CONTRACT] = true;
        composableContracts[NFTDescriptor.BLITMAP_CONTRACT] = true;
        composableContracts[NFTDescriptor.CHAIN_RUNNER_CONTRACT] = true;
        composableContracts[NFTDescriptor.LOOT_CONTRACT] = true;
        composableContracts[NFTDescriptor.ONCHAIN_MONKEY_CONTRACT] = true;
    }

    /**
     * @notice Require that the parts have not been locked.
     */
    modifier whenPartsNotLocked() {
        require(!arePartsLocked, 'Parts are locked');
        _;
    }

    /**
     * @notice Get the number of available Shuffler `backgrounds`.
     */
    function backgroundCount() external view override returns (uint256) {
        return backgrounds.length;
    }

    /**
     * @notice Get the number of available `cards``
     */
    function cardCount() external view override returns (uint256) {
        return cards.length;
    }

    /**
     * @notice Get the number of available `frames`.
     */
    function sideCount() external view override returns (uint256) {
        return sides.length;
    }

    /**
     * @notice Get the number of available `corners`.
     */
    function cornerCount() external view override returns (uint256) {
        return corners.length;
    }

    /**
     * @notice Get the number of available `centers`.
     */
    function centerCount() external view override returns (uint256) {
        return centers.length;
    }

    /**
     * @notice Add colors to a color palette.
     * @dev This function can only be called by the owner.
     */
    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external override onlyOwner {
        require(palettes[paletteIndex].length + newColors.length <= 256, 'Palettes can only hold 256 colors');
        for (uint256 i = 0; i < newColors.length; i++) {
            _addColorToPalette(paletteIndex, newColors[i]);
        }
    }

    /**
     * @notice Batch add backgrounds.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyBackgrounds(string[] calldata _backgrounds) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _backgrounds.length; i++) {
            _addBackground(_backgrounds[i]);
        }
    }

    /**
     * @notice Batch add cards
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyCards(bytes[] calldata _cards) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _cards.length; i++) {
            _addCard(_cards[i]);
        }
    }

    /**
     * @notice Batch add frames.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManySides(bytes[] calldata _sides) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _sides.length; i++) {
            _addSide(_sides[i]);
        }
    }

    /**
     * @notice Batch add corners.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyCorners(bytes[] calldata _corners) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _corners.length; i++) {
            _addCorner(_corners[i]);
        }
    }

    /**
     * @notice Batch add centers.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyCenters(bytes[] calldata _centers) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _centers.length; i++) {
            _addCenter(_centers[i]);
        }
    }

    /**
     * @notice Add a single color to a color palette.
     * @dev This function can only be called by the owner.
     */
    function addColorToPalette(uint8 _paletteIndex, string calldata _color) external override onlyOwner {
        require(palettes[_paletteIndex].length <= 255, 'Palettes can only hold 256 colors');
        _addColorToPalette(_paletteIndex, _color);
    }

    /**
     * @notice Add a background.
     * @dev This function can only be called by the owner when not locked.
     */
    function addBackground(string calldata _background) external override onlyOwner whenPartsNotLocked {
        _addBackground(_background);
    }

    /**
     * @notice Add a frame.
     * @dev This function can only be called by the owner when not locked.
     */
    function addSide(bytes calldata _side) external override onlyOwner whenPartsNotLocked {
        _addSide(_side);
    }

    /**
     * @notice Add a corner.
     * @dev This function can only be called by the owner when not locked.
     */
    function addCorner(bytes calldata _corner) external override onlyOwner whenPartsNotLocked {
        _addCorner(_corner);
    }

    /**
     * @notice Add a center.
     * @dev This function can only be called by the owner when not locked.
     */
    function addCenter(bytes calldata _center) external override onlyOwner whenPartsNotLocked {
        _addCenter(_center);
    }

    /**
     * @notice Lock all parts.
     * @dev This cannot be reversed and can only be called by the owner when not locked.
     */
    function lockParts() external override onlyOwner whenPartsNotLocked {
        arePartsLocked = true;

        emit PartsLocked();
    }

    /**
     * @notice Toggle a boolean value which determines if `tokenURI` returns a data URI
     * or an HTTP URL.
     * @dev This can only be called by the owner.
     */
    function toggleDataURIEnabled() external override {
        // using tx.origin instead of msg.sender here because we want to
        // allow the blind box reveal and data uri toggling done in one transaction
        // security is not a big concern here since the action is easily reversible
        require(owner() == tx.origin, "Ownable: caller is not the owner");
        bool enabled = !isDataURIEnabled;

        isDataURIEnabled = enabled;
        emit DataURIToggled(enabled);
    }

    /**
     * @notice Set the base URI for all token IDs. It is automatically
     * added as a prefix to the value returned in {tokenURI}, or to the
     * token ID if {tokenURI} is empty.
     * @dev This can only be called by the owner.
     */
    function setBaseURI(string calldata _baseURI) external override onlyOwner {
        baseURI = _baseURI;

        emit BaseURIUpdated(_baseURI);
    }

    /**
     * @notice Given a token ID and seed, construct a token URI for the give Onchain Shuffler token
     * @dev The returned value may be a base64 encoded data URI or an API URL.
     */
    function tokenURI(uint256 tokenId, IShufflerToken.Seed memory seed) external view override returns (string memory) {
        if (isDataURIEnabled) {
            return dataURI(tokenId, seed);
        }
        return baseURI;
    }

    /**
     * @notice Given a token ID and seed, construct a base64 encoded data URI
     */
    function dataURI(uint256 tokenId, IShufflerToken.Seed memory seed) public view override returns (string memory) {
        string memory shufflerId = tokenId.toString();
        string memory name = string(abi.encodePacked('Onchain Shuffler #', shufflerId));

        return genericDataURI(name, "", seed);
    }

    /**
     * @notice Given a name, description, and seed, construct a base64 encoded data URI.
     */
    function genericDataURI(
        string memory name,
        string memory description,
        IShufflerToken.Seed memory seed
    ) public view override returns (string memory) {
        NFTDescriptor.TokenURIParams memory params = NFTDescriptor.TokenURIParams({
            name: name,
            description: description,
            parts: _getPartsForSeed(seed),
            background: backgrounds[seed.background],
            override_contract: seed.override_contract,
            override_token_id: seed.override_token_id
        });
        return NFTDescriptor.constructTokenURI(params, palettes);
    }

    /**
     * @notice Given a seed, construct a base64 encoded SVG image.
     */
    function generateSVGImage(IShufflerToken.Seed memory seed) external view override returns (string memory) {
        MultiPartRLEToSVG.SVGParams memory params = MultiPartRLEToSVG.SVGParams({
            parts: _getPartsForSeed(seed),
            background: backgrounds[seed.background],
            center_svg: NFTDescriptor.fetchTokenSvg(seed.override_contract, seed.override_token_id)
        });
        return NFTDescriptor.generateSVGImage(params, palettes);
    }

    /**
     * @notice Add a single color to a color palette.
     */
    function _addColorToPalette(uint8 _paletteIndex, string calldata _color) internal {
        palettes[_paletteIndex].push(_color);
    }

    /**
     * @notice Add a background.
     */
    function _addBackground(string calldata _background) internal {
        backgrounds.push(_background);
    }

    /**
     * @notice Add a card.
     */
    function _addCard(bytes calldata _card) internal {
        cards.push(_card);
    }

    /**
     * @notice Add a frame.
     */
    function _addSide(bytes calldata _side) internal {
        sides.push(_side);
    }

    /**
     * @notice Add a corner.
     */
    function _addCorner(bytes calldata _corner) internal {
        corners.push(_corner);
    }

    /**
     * @notice Add a center.
     */
    function _addCenter(bytes calldata _center) internal {
        centers.push(_center);
    }

    /**
     * @notice Get all parts for the passed `seed`.
     */
    function _getPartsForSeed(IShufflerToken.Seed memory seed) internal view returns (bytes[] memory) {
        bytes[] memory _parts = new bytes[](4);
        _parts[0] = cards[seed.card];
        _parts[1] = sides[seed.side];
        _parts[2] = corners[seed.corner];
        _parts[3] = centers[seed.center];
        return _parts;
    }

    function isComposable(address addr) external view override returns (bool) {
        return composableContracts[addr];
    }
}