// @@@@@@@@@@@@@&%%#(//*,............,,*/((#%&&@@@@@@@@@@@@@@@@@@@@@@@@@&%##(/**,............,**/(##%&@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@&&&&&%%###((///*************//(((##%%%&&&&&@@@@@@@@@@@@&&&&&&%##((//*,,............,,*//((##%&&&&&@@@@@@@@@@@@@@@
// @@@@&&%%%%######(((((((((((((((((((((((((######%%%&&&@@@@@@&&&%%%###((///**,,,............,,,**//(((###%%%&&&@@@@@@@@@@@
// @@@&%%%#((////((((###%%%%%%%%%%%%%%####((((///((##%%&&@@@@&&%%##((///****,,,,..............,,,,****///((##%%&&@@@@@@@@@@
// @@&%%#((/**,**//(##%%&@@@@@@@@@@@@&&%%#((//*,,*//(##%&&@@@&%%#((/**,,,,,,,,..................,,,,,,,,**/((#%%&@@@@@@@@@@
// &&%%##((//*,*//((#%%&@@@@@@@@@@@@@@@&%%#((/****//((##%&&&&%##(//*,,...,,,,,,,,,,,,,,,,,,,,,,,,,,,,...,,*//(##%&&&&&&&&&&
// %#####((((//((##%%%&&@@@@@@@@@@@@@@@&&%%##((//(((((#######((///**,,.,,,,****////////////////****,,,,.,,**//(((##%%%%%%%%
// (((((((######%%%&&&@@@@@@@@@@@@@@@@@@&&&%%%%######(((((((///***,,,..,,**///((##############((///**,,..,,,***///(((((((((
// **//((##%%%&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&%%##(((//***,,,,,,,...,**//(##%%&&&&&&&&&&&&%%##(//**,...,,,,,,***********
// .,**/(##%&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&%%#((/*,,.........,,,,*/((#%%&@@@@@@@@@@@@@@&%%#((/*,,,,.................
// .,,**/((##%%%&&&&@@@@@@@@@@@@@@@@@@@@@@&&&&&%%%#((//**,,.,,,,,*****//((##%%&@@@@@@@@@@@@@@@&&%%##((//*****,,,,..........
// .,,,**///(((##%%%&&&@@@@@@@@@@@@@@@@@&&%%%###(((//***,,..,,,**///(((##%%%&&&@@@@@@@@@@@@@@@@&&&%%%##(((///**,,,.........
// ..,,,,*****//((##%%&&@@@@@@@@@@@@@@@&&%%#((//*****,,,,,..,**//((##%%%&&&&@@@@@@@@@@@@@@@@@@@@@@&&&&%%%##((//**,.........
// .......,,,,,,*//(#%%&@@@@@@@@@@@@@@&&%##(/**,,,,,,.......,*//(##%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&%##(//*,.........
// **,,,,,,,,..,,*//((#%%&&&&&&&&&&&&&%%#((/**,,..,,,,,,,,***//((##%%&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&%%##((//**********
// (///***,,,,.,,***//((###############((//**,,..,,,****///(((((((#####%%%%&&&@@@@@@@@@@@@@@@@@@&&&%%%%######((((((((((((((
// ###((//**,,..,,,****/////////////////***,,,,..,,**//((#######((((((/((##%%&&@@@@@@@@@@@@@@@@&&%%##((//(((((#############
// &&%##((/**,...,,,,,,,,,,,,,,,,,,,,,,,,,,,,,..,,**/((#%%&&&%%##(//****/((##%&&@@@@@@@@@@@@@@&&%##(//****//(##%%&&&&&&&&&&
// @@&%%#((/**,,,,,,,....................,,,,,,,,*//(##%&&@@@&%%#(//*,,**/((##%&&@@@@@@@@@@@@&&%##((/**,,*/((#%%&@@@@@@@@@@
// @@@&%%##((///****,,,,,.............,,,,*****//((##%%&&@@@@&&%%##((////(((####%%%%%%%%%%%%%%####(((////((##%%&&@@@@@@@@@@
// @@@@&&%%%###(((//***,,.............,,***//(((##%%%&&&@@@@@@&&&%%%#####(((((((((((((((((((((((((((######%%%&&&@@@@@@@@@@@
// @@@@@@&&&&&&%%#((//**,............,,**//(##%%&&&&&@@@@@@@@@@@@&&&&&%%%###((///************///((###%%%&&&&&@@@@@@@@@@@@@@
// @@@@@@@@@@@@@&%%#(//*,............,,*/((#%&&@@@@@@@@@@@@@@@@@@@@@@@@@&%##(/**,............,**/(##%&@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@&&%%#((//*************/((##%%&@@@@@@@@@@@@@@@@@@@@@@@@@@&&%##((//************//((#%%&&@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@&&%%%##((((((((((((((###%%&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&%%%##((((((((((((((##%%%&&@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@&&&&%%%%%%%%%%%%%%%%%&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&%%%%%%%%%%%%%%%%%%&&&@@@@@@@@@@@@@@@@@@@@@@@@
//
// The known is finite, the unknown infinite;
// we stand on an islet
// in the midst of an illimitable ocean of inexplicability
//
// Forgotten Runes Wizard's Cult Infinity Veil
//
// Website: https://www.forgottenrunes.com
// Twitter: https://twitter.com/forgottenrunes
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

contract ForgottenRunesInfinityVeil is ERC1155, Ownable, ERC1155Burnable {
    uint256 public _currentTokenID = 0;
    mapping(uint256 => string) public tokenURIs;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => bool) public frozen;

    constructor() ERC1155('') {}

    function uri(uint256 id) public view override returns (string memory) {
        require(bytes(tokenURIs[id]).length > 0, 'That token does not exist');
        return tokenURIs[id];
    }

    function _createToken(
        address initialOwner,
        uint256 totalTokenSupply,
        string calldata tokenUri,
        bytes calldata data
    ) internal returns (uint256) {
        require(bytes(tokenUri).length > 0, 'uri required');
        require(totalTokenSupply > 0, 'supply must be more than 0');
        uint256 _id = _currentTokenID;
        _currentTokenID++;

        tokenURIs[_id] = tokenUri;
        tokenSupply[_id] = totalTokenSupply;
        emit URI(tokenUri, _id);
        _mint(initialOwner, _id, totalTokenSupply, data);
        return _id;
    }

    function create(
        address initialOwner,
        uint256 totalTokenSupply,
        string calldata tokenUri,
        bytes calldata data
    ) public onlyOwner returns (uint256) {
        return _createToken(initialOwner, totalTokenSupply, tokenUri, data);
    }

    function mint(
        address initialOwner,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) public onlyOwner {
        require(amount > 0, 'amount must be more than 0');
        require(!frozen[tokenId], 'token is frozen');
        tokenSupply[tokenId] = tokenSupply[tokenId] + amount;
        _mint(initialOwner, tokenId, amount, data);
    }

    function freeze(uint256 tokenId) public onlyOwner {
        frozen[tokenId] = true;
    }

    function setTokenURI(uint256 tokenId, string calldata tokenUri)
        public
        onlyOwner
    {
        require(!frozen[tokenId], 'token is frozen');
        emit URI(tokenUri, tokenId);
        tokenURIs[tokenId] = tokenUri;
    }
}