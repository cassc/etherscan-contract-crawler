//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { MetaTopeChrysalis } from "./MetaTopeChrysalis.sol";
import { MetaTopeSkins } from "./MetaTopeSkins.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Contract for MetaTope Swap
 * Copyright 2022 MetaTope
 */
contract MetaTopeSwap is Ownable {
    MetaTopeChrysalis public swapFromToken;
    MetaTopeSkins public swapToToken;
    bool public swappingAvailable;
    uint128 public mintTokenId = 1;
    uint128 public constant SWAP_AMOUNT = 1;
    uint256 public constant META_SKIN = 0;

    event Swap(
        address indexed user,
        address swapFromToken,
        address swapToToken,
        uint128 mintTokenId,
        uint128 swappedAt
    );

    modifier onlySwappingStarted() {
        require(swappingAvailable == true, "Swapping should be started");
        _;
    }

    /**
     * @dev Constructor
     * @param _swapFromToken token to swap from
     * @param _swapToToken token to swap to
     */
    constructor(
        MetaTopeChrysalis _swapFromToken,
        MetaTopeSkins _swapToToken
    ) {
        swapFromToken = _swapFromToken;
        swapToToken = _swapToToken;
    }

    /**
     * @dev Function to swap
     */
    function swap() external onlySwappingStarted {
        uint256 swapFromTokenAmount = swapFromToken.balanceOf(msg.sender, META_SKIN);
        require(swapFromTokenAmount > 0, "Insufficient tokens");
        swapFromToken.burn(msg.sender, SWAP_AMOUNT);
        swapToToken.safeMint(msg.sender, mintTokenId);

        emit Swap(
            msg.sender,
            address(swapFromToken),
            address(swapToToken),
            mintTokenId,
            uint128(block.timestamp)
        );
        mintTokenId += 1;
    }

    /**
     * @dev Function to set swapping status
     */
    function toggleSwapping() external onlyOwner {
        swappingAvailable = !swappingAvailable;
    }
}