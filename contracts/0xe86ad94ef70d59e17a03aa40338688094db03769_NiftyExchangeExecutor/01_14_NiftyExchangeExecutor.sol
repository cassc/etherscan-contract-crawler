// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "./single/721/Single721.sol";
import "./single/721/SingleHandler721.sol";
import "./batch/721/Batch721.sol";
import "./batch/721/BatchHandler721.sol";
import "./single/1155/Single1155.sol";
import "./single/1155/SingleHandler1155.sol";
import "./batch/1155/Batch1155.sol";
import "./batch/1155/BatchHandler1155.sol";
import "./switcher/Switcher.sol";
import "./switcher/SwitcherHandler.sol";

/**
 * @notice We're hiring Solidity engineers! Let's get nifty!
 *         https://www.gemini.com/careers/nifty-gateway
 */
contract NiftyExchangeExecutor is Single721, 
                                  SingleHandler721, 
                                  Batch721, 
                                  BatchHandler721, 
                                  Single1155, 
                                  SingleHandler1155, 
                                  Batch1155, 
                                  BatchHandler1155,
                                  Switcher,
                                  SwitcherHandler {

    constructor(address priceCurrencyUSD_, address recoveryAdmin_, address[] memory validSenders_) ExecutorCore(priceCurrencyUSD_, recoveryAdmin_, validSenders_) {
    }

    function withdraw(address recipient, uint256 value) external {
        _requireOnlyValidSender();
        _transferEth(recipient, value);
    }

    function withdraw20(address tokenContract, address recipient, uint256 amount) external {
        _requireOnlyValidSender();
        _transfer20(amount, tokenContract, recipient);
    }

    function withdraw721(address tokenContract, address recipient, uint256 tokenId) external {
        _requireOnlyValidSender();
        IERC721(tokenContract).safeTransferFrom(address(this), recipient, tokenId);
    }

}