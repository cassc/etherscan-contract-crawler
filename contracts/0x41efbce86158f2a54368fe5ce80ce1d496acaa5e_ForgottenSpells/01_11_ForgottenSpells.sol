// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@#@@@@@@@@@@%***********///(@@@@@@@@@@/&@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@/*/@&*******#@@@@@@@@@@&//***/**@//*/@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@&//((/*&@@@@@@@@@@@@@@@@@@@@@(///***&@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@**//**#////*(@@@@@@@@@@@@@@@****//***&*/&@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@/*//@&***@@@@//***(@@@@@@@*****#@@@//*/@@/**(@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@*#(/@@@@/***@@@@@@/*#***#*****@@@@@@****@@@@@***@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@//*@@@@@@@***/@@@@@@@@/*****/@@@@@@@(/**#@@@@@@//*(@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@***@@@@@@@@@***/@@@@*****@@******@@@@/**%@@@@@@@@%**#@@@@@@@@@@@@@
// @@@@@@@@@@@@@**&@@@@@@@@@@#/**(***/&@@@@@@@@@/****#/*(@@@@@@@@@@@**@@@@@@@@@@@@@
// @@@@@@@@@@@@#**&@@@@@@@@@@@#***&@@@@@@@@@@@@@@@@/*****@@@@@@@@@@@/*/@@@@@@@@@@@@
// @@@@@@@@@@@@(//@@@@@@@@@****(***@@@@@@@@@@@@@@@@(/**(/***&@@@@@@@%%&@@@@@@@@@@@@
// @@@@@@@@@@@@***@@@@@@#/**%@@@#/**@@@@@@@@@@@@@@@**/@@@@/#/*#%@@@@/**@@@@@@@@@@@@
// @@@@@@@@@@@@***@@%****@@@@@@@@****@@@@@@@@@@@@@///@@@@@@@@/*****@***@@@@@@@@@@@@
// @@@@@@@@@@@@@(/****@@@@@@@@@@@@****@@@@@@@@@@@//*(@@@@@@@@@@@&(##*/&@@@@@@@@@@@@
// @@@@@@@@@@&**************//**********************(/*//************/****(@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@***@@@@@@@@@/*/@@@@@@@@@@@@@@@((#@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@///(@@@@@@@@@@@@@@&***@@@@@@@((/@@@@@@@@@@@@@@@//(@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@***@@@@@@@@@@@@@@#***@@@@@***%@@@@@@@@@@@@@**//@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@%((#@@@@@@@@@@@@/***@@@/*/(@@@@@@@@@@@@**//@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@****@&**/@@@@@@@@@@////&@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@*/////@@@@@@@**/****@@@@@@%/////&@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@(********@/*//*#*//////*@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@**/@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

// ForgottenPunks: ForgottenSpells
//
// Website: https://forgottenpunks.wtf
// Twitter: https://twitter.com/forgottenpunk
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract ForgottenSpells is ERC1155, Ownable, ERC1155Burnable {
    uint256 public _currentTokenID = 0;
    mapping(uint256 => string) public tokenURIs;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => bool) public frozen;
    mapping(address => bool) public minters;

    modifier onlyMinterOrOwner() {
        require(
            minters[msg.sender] || msg.sender == owner(),
            "only minter or owner can call this function"
        );
        _;
    }

    constructor() ERC1155("") {}

    function uri(uint256 id) public view override returns (string memory) {
        require(bytes(tokenURIs[id]).length > 0, "MISSING_TOKEN");
        return tokenURIs[id];
    }

    function addMinter(address minter) public onlyOwner {
        minters[minter] = true;
    }

    function _createToken(
        address initialOwner,
        uint256 totalTokenSupply,
        string calldata tokenUri,
        bytes calldata data
    ) internal returns (uint256) {
        require(bytes(tokenUri).length > 0, "URI_REQUIRED");
        require(totalTokenSupply > 0, "INVALID_SUPPLY");
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
    ) public onlyMinterOrOwner {
        require(amount > 0, "INVALID_AMOUNT");
        require(!frozen[tokenId], "TOKEN_FROZEN");
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
        require(!frozen[tokenId], "TOKEN_FROZEN");
        emit URI(tokenUri, tokenId);
        tokenURIs[tokenId] = tokenUri;
    }
}