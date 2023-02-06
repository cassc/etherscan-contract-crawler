// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../Erc20/Ownable.sol";

contract Erc20C09FeaturePermitTransfer is
Ownable
{
    bool public isUseOnlyPermitTransfer;
    bool public isCancelOnlyPermitTransferOnFirstTradeOut;

    bool internal _isFirstTradeOut = true;

    function setIsUseOnlyPermitTransfer(bool isUseOnlyPermitTransfer_)
    external
    onlyOwner
    {
        isUseOnlyPermitTransfer = isUseOnlyPermitTransfer_;
    }

    function setIsCancelOnlyPermitTransferOnFirstTradeOut(bool isCancelOnlyPermitTransferOnFirstTradeOut_)
    external
    onlyOwner
    {
        isCancelOnlyPermitTransferOnFirstTradeOut = isCancelOnlyPermitTransferOnFirstTradeOut_;
    }
}