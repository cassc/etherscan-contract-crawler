// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20Metadata} from "ERC20.sol";
import {Clones} from "Clones.sol";
import {Address} from "Address.sol";
import {IFlexiblePortfolio} from "IFlexiblePortfolio.sol";
import {IDebtInstrument} from "IDebtInstrument.sol";
import {IValuationStrategy} from "IValuationStrategy.sol";
import {ITransferController} from "ITransferController.sol";
import {IDepositController} from "IDepositController.sol";
import {IWithdrawController} from "IWithdrawController.sol";
import {IFeeStrategy} from "IFeeStrategy.sol";
import {PortfolioFactory} from "PortfolioFactory.sol";

contract FlexiblePortfolioFactory is PortfolioFactory {
    using Address for address;

    struct ControllersData {
        /// @dev Implementation of the controller applied when calling deposit-related functions
        address depositControllerImplementation;
        /// @dev Encoded args with initialize method selector from deposit controller
        bytes depositControllerInitData;
        /// @dev Implementation of the controller applied when calling withdraw-related functions
        address withdrawControllerImplementation;
        /// @dev Encoded args with initialize method selector from withdraw controller
        bytes withdrawControllerInitData;
        /// @dev Implementation of the controller used when calling transfer-related functions
        address transferControllerImplementation;
        /// @dev Encoded args with initialize method selector from transfer controller
        bytes transferControllerInitData;
        /// @dev Address of valuation strategy directly set as valuationStrategy in the portfolio
        address valuationStrategy;
        /// @dev Implementation of the strategy used when calling fee-related functions
        address feeStrategyImplementation;
        /// @dev Encoded args with initialize method selector from fee strategy
        bytes feeStrategyInitData;
    }

    function createPortfolio(
        IERC20Metadata _asset,
        uint256 _duration,
        uint256 _maxSize,
        ControllersData memory controllersData,
        IDebtInstrument[] calldata _allowedInstruments,
        IFlexiblePortfolio.ERC20Metadata calldata tokenMetadata
    ) public onlyRole(MANAGER_ROLE) {
        IFlexiblePortfolio.Controllers memory controllers = setupControllers(controllersData);
        bytes memory initCalldata = setupPortfolioInitData(
            _asset,
            _duration,
            _maxSize,
            controllers,
            _allowedInstruments,
            tokenMetadata
        );
        _deployPortfolio(initCalldata);
    }

    function setupPortfolioInitData(
        IERC20Metadata _asset,
        uint256 _duration,
        uint256 _maxSize,
        IFlexiblePortfolio.Controllers memory controllers,
        IDebtInstrument[] calldata _allowedInstruments,
        IFlexiblePortfolio.ERC20Metadata calldata tokenMetadata
    ) internal view virtual returns (bytes memory) {
        return
            abi.encodeWithSelector(
                IFlexiblePortfolio.initialize.selector,
                protocolConfig,
                _duration,
                _asset,
                msg.sender,
                _maxSize,
                controllers,
                _allowedInstruments,
                tokenMetadata
            );
    }

    function setupControllers(ControllersData memory controllersData) internal returns (IFlexiblePortfolio.Controllers memory) {
        address depositController = Clones.clone(controllersData.depositControllerImplementation);
        depositController.functionCall(controllersData.depositControllerInitData);

        address withdrawController = Clones.clone(controllersData.withdrawControllerImplementation);
        withdrawController.functionCall(controllersData.withdrawControllerInitData);

        address transferController = Clones.clone(controllersData.transferControllerImplementation);
        transferController.functionCall(controllersData.transferControllerInitData);

        address feeStrategy = Clones.clone(controllersData.feeStrategyImplementation);
        feeStrategy.functionCall(controllersData.feeStrategyInitData);

        return
            IFlexiblePortfolio.Controllers(
                IDepositController(depositController),
                IWithdrawController(withdrawController),
                ITransferController(transferController),
                IValuationStrategy(controllersData.valuationStrategy),
                IFeeStrategy(feeStrategy)
            );
    }
}