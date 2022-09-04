// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AccessControlModifiers} from "../AccessControl/AccessControlModifiers.sol";
import {SaleStateModifiers} from "../BaseNFTModifiers.sol";
import {PausableModifiers} from "../Pausable/PausableModifiers.sol";
import {FirstMintDiscountLib} from "./FirstMintDiscountLib.sol";

contract FirstMintDiscountFacet is
    AccessControlModifiers,
    SaleStateModifiers,
    PausableModifiers
{
    function setDiscountPrice(uint256 _discountPrice)
        public
        whenNotPaused
        onlyOwner
    {
        FirstMintDiscountLib.setDiscountPrice(_discountPrice);
    }

    function discountPrice() public view returns (uint256) {
        return FirstMintDiscountLib.firstMintDiscountStorage().discountPrice;
    }

    function setDiscountCountPerUser(uint256 _discountCountPerUser)
        public
        whenNotPaused
        onlyOwner
    {
        FirstMintDiscountLib.setDiscountCountPerUser(_discountCountPerUser);
    }

    function discountCountPerUser() public view returns (uint256) {
        return
            FirstMintDiscountLib
                .firstMintDiscountStorage()
                .discountCountPerUser;
    }

    function setMaxMintableViaDiscount(uint256 _max)
        public
        whenNotPaused
        onlyOwner
    {
        FirstMintDiscountLib.setMaxMintableViaDiscount(_max);
    }

    function maxMintableViaDiscount() public view returns (uint256) {
        return
            FirstMintDiscountLib
                .firstMintDiscountStorage()
                .maxMintableViaDiscount;
    }

    function totalMintedViaDiscount() public view returns (uint256) {
        return
            FirstMintDiscountLib
                .firstMintDiscountStorage()
                .totalMintedViaDiscount;
    }

    function discountPriceInfo(uint256 _count, address _minter)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return FirstMintDiscountLib.discountPriceInfo(_count, _minter);
    }

    function discountAllowlistMint(
        uint256 _count,
        uint256 _quantityAllowListEntries,
        bytes32[] calldata _merkleProof
    ) public payable whenNotPaused onlyAtSaleState(4) {
        FirstMintDiscountLib.discountAllowlistMint(
            _count,
            _quantityAllowListEntries,
            _merkleProof
        );
    }

    function discountLazyMint(uint256 _count)
        public
        payable
        whenNotPaused
        onlyAtSaleState(5)
    {
        FirstMintDiscountLib.discountLazyMint(_count);
    }

    function setFirstMintDiscountConfig(
        uint256 _discountPrice,
        uint256 _discountCountPerUser,
        uint256 _maxMintableViaDiscount
    ) public whenNotPaused onlyOwner {
        FirstMintDiscountLib.setFirstMintDiscountConfig(
            _discountPrice,
            _discountCountPerUser,
            _maxMintableViaDiscount
        );
    }

    function firstMintDiscountConfig()
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        FirstMintDiscountLib.FirstMintDiscountStorage
            storage s = FirstMintDiscountLib.firstMintDiscountStorage();
        return (
            s.discountPrice,
            s.discountCountPerUser,
            s.maxMintableViaDiscount
        );
    }
}