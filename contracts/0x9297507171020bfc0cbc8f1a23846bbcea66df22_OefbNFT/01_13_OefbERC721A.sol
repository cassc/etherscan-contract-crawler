// SPDX-License-Identifier: MIT
// developed by Ahoi Kapptn! - https://ahoikapptn.com

/**
     _    _           _   _  __                 _         _ 
    / \  | |__   ___ (_) | |/ /__ _ _ __  _ __ | |_ _ __ | |
   / _ \ | '_ \ / _ \| | | ' // _` | '_ \| '_ \| __| '_ \| |
  / ___ \| | | | (_) | | | . \ (_| | |_) | |_) | |_| | | |_|
 /_/   \_\_| |_|\___/|_| |_|\_\__,_| .__/| .__/ \__|_| |_(_)
                                   |_|   |_|                                                                                                             
 */

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @author ahoikapptn.com
/// @title OEFB NFT
contract OefbNFT is ERC721A, Ownable, Pausable {
    /**
     @dev number of minted reserved NFTs
     */
    uint16 public mintedReserved = 0;
    /**
     @dev total number of reserved NFTs
     */
    uint16 public constant MAX_RESERVED = 50;
    /**
     @dev number of total minted NFTs - start must match MAX_RESERVED
     */
    uint16 public mintedPublic = 50;
    /**
     @dev maximum number of NFTs
     */
    uint16 public constant MAX_MINT = 810;
    /**
     @dev maximum number NFTs per transaction
     */
    uint16 public constant MAX_TRANSACTION_AMOUNT = 10;
    /**
    @dev open sale on 3rd March 19:04 CET (UTC+1)
     */
    uint32 public openSaleTimestamp = 1646330640;
    /**
     @dev the PRICE of the NFT
     */
    uint128 public constant PRICE = 0.08 ether;

    /**
     @dev the base url - initially pointing to unrevealed data and later to revealed uri,
     */
    string public baseURIString =
        "ipfs://QmP9siVrz6stVEh6fR8ropCvXRtCRZy6rjd3ADBqsc535s/";

    /**
     @dev events
     */
    event ReceivedETH(address, uint256);
    event NewTokenURI(string);

    constructor() ERC721A("THE OEFB NFT", "OEFB NFT") {}

    function mintNFT(uint8 amount) external payable {
        require(amount > 0, "No amount specified");
        require(amount <= MAX_TRANSACTION_AMOUNT, "Max amount exceeded");
        require(msg.value >= PRICE * amount, "Not enough ETH sent");
        require(mintedPublic + amount <= MAX_MINT, "No more NFTs");
        require(saleIsOpen(), "Sale not open");

        _safeMint(msg.sender, amount);
        mintedPublic += amount;
    }

    function mintReserved(address to, uint8 amount) external onlyOwner {
        require(amount > 0, "No amount specified");
        require(mintedReserved + amount <= MAX_RESERVED, "No more reserved");
        _safeMint(to, amount);
        mintedReserved += amount;
    }

    /**
     * @dev set a new baseURI
     *
     * Requirements:
     *
     * - the contract must not be frozen.
     */
    function setNewURI(string memory _newURI) external onlyOwner {
        baseURIString = _newURI;
        emit NewTokenURI(_newURI);
    }

    function setOpenSaleTimestamp(uint32 _timestamp) external onlyOwner {
        openSaleTimestamp = _timestamp;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURIString;
    }

    /**
    @dev withdraw all eth from contract to owner address
    */
    function withdrawAll() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function saleIsOpen() public view returns (bool open) {
        return !paused() && (block.timestamp >= openSaleTimestamp);
    }

    /**
     @dev overrides
     */
    /**
     * @dev override ERC721A
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        require(!paused(), "Token transfer while paused");
    }

    /**
    @dev receive ether if sent directly to this contract
    */
    receive() external payable {
        if (msg.value > 0) {
            emit ReceivedETH(msg.sender, msg.value);
        }
    }
}