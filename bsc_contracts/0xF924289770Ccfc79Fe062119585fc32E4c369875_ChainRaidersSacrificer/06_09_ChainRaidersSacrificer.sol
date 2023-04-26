// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RareboardSacrificeMintDiscount, SacrificeMintDiscount} from "./erc721/sacrifice/RareboardSacrificeMintDiscount.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IToken {
    function setPrice(uint256 _price) external;
    function setPriceWithMintpass(uint256 _price) external;
    function price() external view returns (uint256);
    function priceWithMintpass() external view returns (uint256);
}

contract ChainRaidersSacrificer is
    RareboardSacrificeMintDiscount
{
    IERC721 public constant mintpass = IERC721(0x6Ce701Cb2442FD7e7a9aA1ce9A8e3E04635A0121);
    
    constructor() SacrificeMintDiscount(0xB341054bDE0800f70fDFe9768730C77dDEE3A144) {}

    function _setPrice(address _for, uint256 _value) internal virtual override {
        if (_hasMintpass(_for)) {
            IToken(token).setPriceWithMintpass(_value);
        } else {
            IToken(token).setPrice(_value);
        }
    }

    function _getPrice(address _for) internal virtual override view returns (uint256) {
        if (_hasMintpass(_for)) {
            return IToken(token).priceWithMintpass();
        } else {
            return IToken(token).price();
        }
    }

    function _hasMintpass(address _user) internal view returns (bool) {
        return mintpass.balanceOf(_user) > 0;
    }
}