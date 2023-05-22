// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {Clone} from "clones-with-immutable-args/Clone.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {ISettings} from "./ISettings.sol";
import {ILSSVMPair} from "../ILSSVMPair.sol";

contract Splitter is Clone {
    using SafeTransferLib for ERC20;
    using SafeTransferLib for address payable;

    uint256 constant BASE = 10_000;

    function getParentSettings() public pure returns (address) {
        return _getArgAddress(0);
    }

    function getPairAddressForSplitter() public pure returns (address) {
        return _getArgAddress(20);
    }

    function withdrawAllETHInSplitter() public {
        withdrawETH(address(this).balance);
    }

    function withdrawETH(uint256 ethAmount) public {
        ISettings parentSettings = ISettings(getParentSettings());
        uint256 amtToSendToSettingsFeeRecipient = (parentSettings.getFeeSplitBps() * ethAmount) / BASE;
        parentSettings.settingsFeeRecipient().safeTransferETH(amtToSendToSettingsFeeRecipient);
        uint256 amtToSendToPairFeeRecipient = ethAmount - amtToSendToSettingsFeeRecipient;
        payable(parentSettings.getPrevFeeRecipientForPair(getPairAddressForSplitter())).safeTransferETH(
            amtToSendToPairFeeRecipient
        );
    }

    function withdrawAllBaseQuoteTokens() public {
        ERC20 token = ILSSVMPair(getPairAddressForSplitter()).token();
        uint256 tokenBalance = token.balanceOf(address(this));
        withdrawTokens(token, tokenBalance);
    }

    function withdrawAllTokens(ERC20 token) public {
        uint256 tokenBalance = token.balanceOf(address(this));
        withdrawTokens(token, tokenBalance);
    }

    function withdrawTokens(ERC20 token, uint256 tokenAmount) public {
        ISettings parentSettings = ISettings(getParentSettings());
        uint256 amtToSendToSettingsFeeRecipient = (parentSettings.getFeeSplitBps() * tokenAmount) / BASE;
        token.safeTransfer(parentSettings.settingsFeeRecipient(), amtToSendToSettingsFeeRecipient);
        uint256 amtToSendToPairFeeRecipient = tokenAmount - amtToSendToSettingsFeeRecipient;
        token.safeTransfer(
            parentSettings.getPrevFeeRecipientForPair(getPairAddressForSplitter()), amtToSendToPairFeeRecipient
        );
    }

    fallback() external payable {}
}