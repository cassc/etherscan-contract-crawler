// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/ISiloRepository.sol";
import "./interface/ILiquidationHelper.sol";

import "../lib/Ping.sol";
import "./LiquidationRepay.sol";


/// @notice LiquidationHelper IS NOT PART OF THE PROTOCOL. SILO CREATED THIS TOOL, MOSTLY AS AN EXAMPLE.
/// see https://github.com/silo-finance/liquidation#readme for details how liquidation process should look like
contract ManualLiquidation is ILiquidationHelper, IFlashLiquidationReceiver, LiquidationRepay {

    ISiloRepository public immutable SILO_REPOSITORY; // solhint-disable-line var-name-mixedcase

    error InvalidSiloRepository();
    error NotSilo();
    error UsersMustMatchSilos();

    /// @dev event emitted on user liquidation
    /// @param silo Silo where liquidation happen
    /// @param user User that been liquidated
    event LiquidationExecuted(address indexed silo, address indexed user);


    constructor (address _repository) {
        if (!Ping.pong(ISiloRepository(_repository).siloRepositoryPing)) {
            revert InvalidSiloRepository();
        }

        SILO_REPOSITORY = ISiloRepository(_repository);
    }

    receive() external payable {}

    function executeLiquidation(address _user, ISilo _silo) external {
        address[] memory users = new address[](1);
        users[0] = _user;

        _silo.flashLiquidate(users, abi.encode(msg.sender));
    }

    /// @notice this is working example of how to perform manual liquidation, this method will be called by Silo.
    /// Assets for repay will be transferred from tx executor, so there must be allowance set.
    /// After repay all collaterals wil be transfer to tx executor.
    /// @dev after liquidation we always send remaining tokens so contract should never has any leftover
    function siloLiquidationCallback(
        address _user,
        address[] calldata _assets,
        uint256[] calldata _receivedCollaterals,
        uint256[] calldata _shareAmountsToRepaid,
        bytes calldata _flashReceiverData
    ) external override {
        if (!SILO_REPOSITORY.isSilo(msg.sender)) revert NotSilo();

        address payable executor = abi.decode(_flashReceiverData, (address));

        _pullAssetsForRepay(_assets, _shareAmountsToRepaid, executor);

        _repay(ISilo(msg.sender), _user, _assets, _shareAmountsToRepaid);

        _transferChange(_assets, _receivedCollaterals, executor);

        emit LiquidationExecuted(msg.sender, _user);
    }

    function _transferChange(
        address[] calldata _assets,
        uint256[] calldata _receivedCollaterals,
        address _executor
    ) internal {
        // change that left after repay will be send to `_liquidator`
        for (uint256 i = 0; i < _assets.length;) {
            if (_receivedCollaterals[i] != 0) {
                // shareAmountsToRepaid will go entirely to Silo, so no need to transfer
                // we need to handle receivedCollaterals only
                IERC20(_assets[i]).transfer(_executor, _receivedCollaterals[i]);
            }

            // we will never have that many assets to overflow
            unchecked { i++; }
        }
    }

    function _pullAssetsForRepay(
        address[] calldata _assets,
        uint256[] calldata _shareAmountsToRepaid,
        address _executor
    ) internal {
        for (uint256 i = 0; i < _assets.length;) {
            if (_shareAmountsToRepaid[i] != 0) {
                IERC20(_assets[i]).transferFrom(_executor, address(this), _shareAmountsToRepaid[i]);
            }

            // we will never have that many assets to overflow
            unchecked { i++; }
        }
    }
}