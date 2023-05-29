// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AbstractERC1155} from "./abstract/AbstractERC1155.sol";

contract MintPass is AbstractERC1155 {
    /// @notice Mint pass token id
    uint256 public constant MINT_PASS_ID = 0;

    /// @notice Maximum supply of the mint passes
    uint256 public constant MAX_SUPPLY = 10000;

    /// @notice Maximum mints per wallet
    uint256 public constant MAX_PER_WALLET = 7;

    /// @notice Official ERC721 that will exchange the pass
    address erc721Contract;

    /// @notice Tracker for all the passes minted so far
    mapping(address => uint256) public mintedPasses;

    /// @notice Track the state of the sale
    bool public publicSale = false;

    constructor(
        string memory name,
        string memory symbol,
        string memory metadataUri_
    ) AbstractERC1155(symbol, name) {
        setBaseURI(metadataUri_);
    }

    /**
     * @notice Toggles the public sale
     */
    function togglePublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    /**
     * @notice Mint a quantity of passes
     * @param quantity Quantity to mint
     */
    function mint(uint256 quantity) public payable belowMaxSupply(quantity) {
        require(publicSale, "Sale not open");
        require(
            mintedPasses[msg.sender] + quantity <= MAX_PER_WALLET,
            "Max per wallet reached"
        );
        mintedPasses[msg.sender] += quantity;
        _mint(msg.sender, MINT_PASS_ID, quantity, "");
    }

    /**
     * @notice Admin mint passes
     * @param recipient Receiver of the pass
     * @param quantity Quantity to mint
     */
    function adminMint(address recipient, uint256 quantity)
        public
        onlyOwner
        belowMaxSupply(quantity)
    {
        _mint(recipient, MINT_PASS_ID, quantity, "");
    }

    modifier belowMaxSupply(uint256 _quantity) {
        require(
            totalSupply(MINT_PASS_ID) + _quantity <= MAX_SUPPLY,
            "Max limit reached"
        );
        _;
    }

    /**
     * @notice Allow a contract to burn the pass
     * @param recipient Receiver of the pass
     * @param quantity Quantity to burn
     */
    function redeem(address recipient, uint256 quantity) external {
        require(erc721Contract == msg.sender, "Not an official contract");
        _burn(recipient, MINT_PASS_ID, quantity);
    }

    /**
     * @notice Set the ERC721 official contract that will burn the nft in exchange
     *         for additional nft tokens
     * @param erc721Contract_ ERC721 contract address
     */
    function setErc721Contract(address erc721Contract_) external onlyOwner {
        require(erc721Contract == address(0), "Contract already set");
        erc721Contract = erc721Contract_;
    }
}