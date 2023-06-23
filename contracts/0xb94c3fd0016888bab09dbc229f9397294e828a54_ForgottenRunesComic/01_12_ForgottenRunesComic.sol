// Forgotten Runes Wizard's Cult Comics
// https://forgottenrunes.com
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "./interfaces/IForgottenRunesComic.sol";

contract ForgottenRunesComic is
    IForgottenRunesComic,
    ERC1155,
    Ownable,
    ERC1155Burnable
{
    mapping(uint256 => string) public tokenURIs;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => uint256) public maxTokenSupply;

    address public minter1;
    address public minter2;

    modifier onlyOwnerOrMinter() {
        address operator = _msgSender();
        require(
            owner() == operator || operator == minter1 || operator == minter2,
            "Caller is neither owner nor minter"
        );
        _;
    }

    constructor() ERC1155("") {}

    function mint(
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) public onlyOwnerOrMinter {
        require(
            tokenSupply[tokenId] + amount <= maxTokenSupply[tokenId],
            "Not enough tokens left"
        );
        tokenSupply[tokenId] = tokenSupply[tokenId] + amount;
        _mint(to, tokenId, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) public onlyOwnerOrMinter {
        require(
            tokenIds.length == amounts.length,
            "tokenIds and amounts length mismatch"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 amount = amounts[i];
            require(
                tokenSupply[tokenId] + amount <= maxTokenSupply[tokenId],
                "Not enough tokens left"
            );
            tokenSupply[tokenId] = tokenSupply[tokenId] + amount;
        }

        _mintBatch(to, tokenIds, amounts, data);
    }

    /**
     * @dev Mints same token and amount to multiple addresses (useful for airdrops)
     */
    function mintToMultipleRecipients(
        address[] calldata recipients,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) public onlyOwnerOrMinter {
        uint256 totalAmount = (amount * recipients.length);

        require(
            tokenSupply[tokenId] + totalAmount <= maxTokenSupply[tokenId],
            "Not enough tokens left"
        );
        tokenSupply[tokenId] = tokenSupply[tokenId] + totalAmount;

        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], tokenId, amount, data);
        }
    }

    function setMinter1(address newMinter1) public onlyOwner {
        minter1 = newMinter1;
    }

    function setMinter2(address newMinter2) public onlyOwner {
        minter2 = newMinter2;
    }

    function setMaxSupply(uint256 tokenId, uint256 newMaxSupply)
        public
        onlyOwner
    {
        maxTokenSupply[tokenId] = newMaxSupply;
    }

    function setTokenURI(uint256 tokenId, string calldata tokenUri)
        public
        onlyOwner
    {
        tokenURIs[tokenId] = tokenUri;
        emit URI(tokenUri, tokenId);
    }

    function uri(uint256 id) public view override returns (string memory) {
        return tokenURIs[id];
    }
}