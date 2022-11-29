// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20Metadata} from "ERC20.sol";
import {IProtocolConfig} from "IProtocolConfig.sol";
import {IDebtInstrument} from "IDebtInstrument.sol";
import {IDepositController} from "IDepositController.sol";
import {IWithdrawController} from "IWithdrawController.sol";
import {IValuationStrategy} from "IValuationStrategy.sol";
import {ITransferController} from "ITransferController.sol";
import {IFeeStrategy} from "IFeeStrategy.sol";
import {IPortfolio} from "IPortfolio.sol";

interface IFlexiblePortfolio is IPortfolio {
    struct ERC20Metadata {
        string name;
        string symbol;
    }

    struct Controllers {
        IDepositController depositController;
        IWithdrawController withdrawController;
        ITransferController transferController;
        IValuationStrategy valuationStrategy;
        IFeeStrategy feeStrategy;
    }

    function initialize(
        IProtocolConfig _protocolConfig,
        uint256 _duration,
        IERC20Metadata _asset,
        address _manager,
        uint256 _maxSize,
        Controllers calldata _controllers,
        IDebtInstrument[] calldata _allowedInstruments,
        ERC20Metadata calldata tokenMetadata
    ) external;

    function fundInstrument(IDebtInstrument loans, uint256 instrumentId) external;

    function repay(
        IDebtInstrument loans,
        uint256 instrumentId,
        uint256 amount
    ) external;
}