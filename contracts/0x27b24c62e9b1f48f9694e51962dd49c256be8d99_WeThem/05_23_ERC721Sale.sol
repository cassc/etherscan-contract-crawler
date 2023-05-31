// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./Whitelistable.sol";
import "./TXLimiter.sol";
import "./WalletLimiter.sol";
import "./ERC721Collection.sol";


abstract contract ERC721Sale is Ownable, ERC721Collection, TXLimiter, WalletLimiter {
    using SafeMath for uint256;

    bool public saleIsActive = false;
    uint256 public salePrice = 0; //0 ETH

    /**
     * Virtual function that has to be overridden in child contract.
     */
    function _setPresaleState(bool state) internal virtual {}

    function _getSaleState() internal virtual view returns(bool) {
        return saleIsActive;
    }

    function setSaleState(bool state) public onlyOwner {
        saleIsActive = state;
        if (state) {
            _setPresaleState(false);
        }
    }

    function setSalePrice(uint256 price) public onlyOwner {
        salePrice = price;
    }

    function mintSale(uint numTokens) public payable {
        require(saleIsActive, "Sale is not active");
        require(numTokens <= getMaxTXLimit(), "Minting more than TX limit");
        require(balanceOf(_msgSender()).add(numTokens) <= getMaxWalletLimit(), "Minting more than wallet limit");
        require(totalSupply().add(numTokens) <= getMaxSupply(), "Purchase would exceed max supply");
        require(salePrice.mul(numTokens) <= msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < numTokens; i++) {
            uint index = totalSupply().add(1);
            if (index < getMaxSupply()) {
                _safeMint(_msgSender(), index);
            }
        }
    }
}