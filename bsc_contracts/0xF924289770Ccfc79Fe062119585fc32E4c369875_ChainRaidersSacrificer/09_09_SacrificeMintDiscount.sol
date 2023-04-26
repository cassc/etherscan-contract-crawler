// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {Forwarder} from "./Forwarder.sol";

abstract contract SacrificeMintDiscount is Forwarder {
    address public immutable token;
    address public constant dead = 0x000000000000000000000000000000000000dEaD;

    uint256 public amountToSacrificeForFreeMint = 2;
    uint256 public discountedForSacrifice   = 5_000; // 50%
    uint256 public constant discountBase = 10_000; // 100%

    uint256 public freeMintSupply;
    uint256 public discountMintSupply;

    constructor(address _token) Forwarder(_token) {
        token = _token;
    }

    function sacrificeAndMint(uint256[] calldata tokenIdsToSacrifice) external payable {
        uint256 sacrifices = tokenIdsToSacrifice.length;
        uint256 priceBPS;

        if (sacrifices == amountToSacrificeForFreeMint) {
            require(freeMintSupply > 0, "No free mints left");
            --freeMintSupply;
            priceBPS = 0;
        } else if (sacrifices == 1) {
            require(discountMintSupply > 0, "No discounted mints left");
            --discountMintSupply;
            priceBPS = discountedForSacrifice;
        } else {
            revert("Invalid amount of sacrifices");
        }

        for (uint256 i = 0; i < sacrifices; ++i) {
            IERC721(token).transferFrom(msg.sender, dead, tokenIdsToSacrifice[i]);
        }
        
        _mintWithDiscount(msg.sender, 1, priceBPS);
    }

    function setSupplies(uint256 _freeMintSupply, uint256 _discountMintSupply) external onlyOwner {
        freeMintSupply = _freeMintSupply;
        discountMintSupply = _discountMintSupply;
    }

    function setSacrificeDiscounts(uint256 _discountedForSacrifice, uint256 _amountToSacrificeForFreeMint) external onlyOwner {
        require(_amountToSacrificeForFreeMint > 0, "Invalid amount");
        require(_discountedForSacrifice > 0 && _discountedForSacrifice < 10_000, "Invalid discount");
        amountToSacrificeForFreeMint = _amountToSacrificeForFreeMint;
        discountedForSacrifice = _discountedForSacrifice;
    }

    function _mintWithDiscount(address _to, uint256 _amount, uint256 _discount) internal {
        uint256 price = _getPrice(_to);
        uint256 discounted = price * _discount / discountBase;
        uint256 value = discounted * _amount;

        require(msg.value == value, "Value sent does not match price");

        _setPrice(_to, discounted);
        _mint(_to, _amount, value);
        _setPrice(_to, price);
    }

    function _mint(
        address _to,
        uint256 _amount,
        uint256 _value
    ) internal virtual;

    function _setPrice(address _for, uint256 _value) internal virtual;

    function _getPrice(address _for) internal virtual view returns (uint256);
}