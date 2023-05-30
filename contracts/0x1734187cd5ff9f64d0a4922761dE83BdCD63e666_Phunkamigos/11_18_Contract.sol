// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./extensions/ERC721AOpensea.sol";
import "./NFTToken.sol";

error TooManyPerTX();
error TooManyPerWallet();
error TooManyForSupply();
error PaymentValueIncorrect();
error NotSender();
error CannotMintRN();
error WithdrawalFail();

contract Phunkamigos is NFTToken, ERC721AOpensea {   
    string private _baseTokenURI;
    uint public maxSupply = 20000;
    uint public totalFree = 1;
    uint public maxPerTX = 20;
    uint public maxPerWallet = 100;    
    uint public cost = 0.0042 ether;
    bool public mintEnabled = false;

    modifier sameOrigin() {
        require(tx.origin == msg.sender, "not original sender");
        _;
    }

    modifier enoughSupply(uint256 quantity_) {
        if (_totalMinted() + quantity_ > maxSupply) {
            revert TooManyForSupply();
        }
        _;
    }

     modifier allowedAmountForTX(uint256 quantity_) {
        if (quantity_ > maxPerTX + 1) {
            revert TooManyPerTX();
        }
        _;
    }

    modifier canMint() {
        if (!mintEnabled) revert CannotMintRN();
        _;
    }

    constructor()
        ERC721A("Phunkamigos", "PHAMGS")
        ERC721AOpensea()
        NFTToken()
    {}

    function reserve(uint256 quantity, address to) 
        external 
        onlyOwner
        enoughSupply(quantity)
        {
        _mint(to, quantity);
    }
    
    function mint(uint qty)
      external
      payable
      sameOrigin      
      canMint
      allowedAmountForTX(qty)
      enoughSupply(qty)
      {
        uint price = calcTotalCost(qty);

        if (_numberMinted(msg.sender) + qty > maxPerWallet + 1) revert TooManyPerWallet();
     
        _mint(msg.sender, qty);
        _refundOverPayment(price);
    }

    function calcTotalCost(uint qty) public view returns (uint) {
      uint userTotal = _numberMinted(msg.sender);
      uint free = userTotal < totalFree ? totalFree - userTotal : 0;
      if (qty >= free) {
        return (cost) * (qty - free);
      }
      return 0;
    }

    function _refundOverPayment(uint256 amount) internal {
        if (msg.value < amount) revert PaymentValueIncorrect();
        if (msg.value > amount) {
            payable(msg.sender).transfer(msg.value - amount);           
        }
    }

    function setMaxPerWallet(uint256 val) external onlyOwner {
        maxPerWallet = val;
    }

    function setMaxPerTX(uint256 val) external onlyOwner {
        maxPerTX = val;
    }

    function setMaxSupply(uint256 val) public onlyOwner {
        maxSupply = val;
    }

    function mintSwitcher() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function totalMintedPerOwner(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

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

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert WithdrawalFail();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}