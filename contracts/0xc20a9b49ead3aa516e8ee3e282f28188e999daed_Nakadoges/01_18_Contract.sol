// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./extensions/ERC721AOpensea.sol";
import "./NFTToken.sol";

/// Exceeds maximum per transaction
error ExceedsMaximumPerTransaction();

/// Exceeds maximum per wallet
error ExceedsMaximumPerWallet();

/// Exceeds maximum supply
error ExceedsMaximumSupply();

/// Exceeds maximum reserve supply
error ExceedsReserveSupply();

/// Attempted access to inactive public sale
error PublicSaleIsNotActive();

/// Failed withdrawal from contract
error WithdrawFailed();

/// The wrong ETH value has been sent with a transaction
error WrongETHValueSent();

/// is not the sender
error NotSender();

// mint not active
error MintingNotActive();

contract Nakadoges is    
    NFTToken,
    ERC721AOpensea
{   
    string private _baseTokenURI;

    uint public MAX_SUPPLY = 8888;
    uint public MAX_FREE_PER_WALLET = 1;
    uint public MAX_TOKENS_PER_PURCHASE = 10;
    uint public MAX_TOKENS_PER_WALLET = 100;    
    uint public COST_AFTER_FREE = 0.0042 ether;

    bool public mintActive = false;
    
    // *************************************************************************
    // MODIFIERS

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "not original sender");
        _;
    }

    modifier supplyAvailable(uint256 quantity_) {
        if (_totalMinted() + quantity_ > MAX_SUPPLY) {
            revert ExceedsMaximumSupply();
        }
        _;
    }

     modifier withinTXLimits(uint256 quantity_) {
        if (quantity_ > MAX_TOKENS_PER_PURCHASE + 1) {
            revert ExceedsMaximumPerTransaction();
        }
        _;
    }

    modifier isMintActive() {
        if (!mintActive) revert MintingNotActive();
        _;
    }


    // *************************************************************************
    // FUNCTIONS

    constructor()
        ERC721A("Nakadoges", "NKDGS")
        ERC721AOpensea()
        NFTToken()
    {}

    function mint(uint qty)
      external
      payable
      callerIsUser      
      isMintActive
      withinTXLimits(qty)
      supplyAvailable(qty)
      {
        uint price = getPrice(qty);

        if (_numberMinted(msg.sender) + qty > MAX_TOKENS_PER_WALLET + 1) revert ExceedsMaximumPerWallet();
     
        _mint(msg.sender, qty);
        _refundOverPayment(price);
    }

    function getPrice(uint qty) public view returns (uint) {
      uint numMinted = _numberMinted(msg.sender);
      uint free = numMinted < MAX_FREE_PER_WALLET ? MAX_FREE_PER_WALLET - numMinted : 0;
      if (qty >= free) {
        return (COST_AFTER_FREE) * (qty - free);
      }
      return 0;
    }

    function _refundOverPayment(uint256 amount) internal {
        if (msg.value < amount) revert WrongETHValueSent();
        if (msg.value > amount) {
            payable(msg.sender).transfer(msg.value - amount);           
        }
    }

    function devMint(uint256 quantity, address to) 
        external 
        onlyOwner
        supplyAvailable(quantity)
        {
        _mint(to, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setMaxPerWallet(uint256 maxPerWallet) external onlyOwner {
        MAX_TOKENS_PER_WALLET = maxPerWallet;
    }

    function setMaxPerPurchase(uint256 maxPerPurchase) external onlyOwner {
        MAX_TOKENS_PER_PURCHASE = maxPerPurchase;
    }

    function setMaxSupply(uint256 maxSupply_) public onlyOwner {
        MAX_SUPPLY = maxSupply_;
    }

    function toggleMintActive() external onlyOwner {
        mintActive = !mintActive;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert WithdrawFailed();
    }

    // *************************************************************************
    // OVERRIDES

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(NFTToken, ERC721AOpensea)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }
}