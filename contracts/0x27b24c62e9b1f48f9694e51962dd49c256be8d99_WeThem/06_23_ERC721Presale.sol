// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./Whitelistable.sol";
import "./TXLimiter.sol";
import "./WalletLimiter.sol";
import "./ERC721Collection.sol";

abstract contract ERC721Presale is Ownable, ERC721Collection, Whitelistable, TXLimiter, WalletLimiter {
    using SafeMath for uint256;

    bool public presaleIsActive = false;
    uint256 public presaleSupply = 300;
    uint256 public presalePrice = 0; //0 ETH

    /**
     * Virtual function that has to be overridden in child contract.
     */
    function _getSaleState() internal virtual returns(bool) {} 

    function _getPresaleState() internal view returns(bool) {
        return presaleIsActive;
    }

    function _setPresaleState(bool state) internal virtual {
        presaleIsActive = state;
    }

    function setPresaleState(bool state) public onlyOwner {
        require(!_getSaleState(), "Can not change presale state while sale is active");
        _setPresaleState(state);
    }

    function setPresaleSupply(uint256 supply) public onlyOwner {
        require(supply > 0 && supply < getMaxSupply(), "Invalid presale supply");
        presaleSupply = supply;
    }

    function setPresalePrice(uint256 price) public onlyOwner {
        presalePrice = price;
    }

    function mintPresale(uint numTokens) public payable onlyWhitelisted {
        require(presaleIsActive, "Presale is not active");
        require(numTokens <= getMaxTXLimit(), "Minting more than TX limit");
        require(balanceOf(_msgSender()).add(numTokens) <= getMaxWalletLimit(), "Minting more than wallet limit");
        require(totalSupply().add(numTokens) <= presaleSupply, "Purchase would exceed max presale supply");
        require(totalSupply().add(numTokens) <= getMaxSupply(), "Purchase would exceed max supply");
        require(presalePrice.mul(numTokens) <= msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < numTokens; i++) {
            uint index = totalSupply();
            if (totalSupply() < getMaxSupply()) {
                _safeMint(_msgSender(), index);
            }
        }
    }
}