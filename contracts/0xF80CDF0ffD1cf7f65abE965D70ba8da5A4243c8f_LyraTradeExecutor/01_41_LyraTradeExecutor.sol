//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "../BaseTradeExecutor.sol";
import "./LyraPositionHandler.sol";
import "../../interfaces/IVault.sol";

/// @title LyraTradeExecutor
/// @author Pradeep
/// @notice A contract to execute manage a Lyra Position Handler on Optimism
contract LyraTradeExecutor is BaseTradeExecutor, LyraPositionHandler {
    /// @notice Constructor of the Trade Executor
    /// @param vault Address of the Vault contract
    /// @param _wantTokenL2 address of wantToken equivalent on L2
    /// @param _l2HandlerAddress address of LyraHandler on L2
    /// @param _L1CrossDomainMessenger address of optimism gateway cross domain messenger
    /// @param _socketRegistry address of socketRegistry on L1
    constructor(
        address vault,
        address _wantTokenL2,
        address _l2HandlerAddress,
        address _L1CrossDomainMessenger,
        address _socketRegistry
    ) BaseTradeExecutor(vault) {
        _initHandler(
            vaultWantToken(),
            _wantTokenL2,
            _l2HandlerAddress,
            _L1CrossDomainMessenger,
            _socketRegistry
        );
    }

    /*///////////////////////////////////////////////////////////////
                            EVENT LOGS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when socket registry is updated.
    /// @param oldRegistry The address of the current Registry.
    /// @param newRegistry The address of new Registry.
    event UpdatedSocketRegistry(
        address indexed oldRegistry,
        address indexed newRegistry
    );

    /*///////////////////////////////////////////////////////////////
                            VIEW FUNCTONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns total wantTokens present in LyraHandler L2 and this Trade Executor
    /// @return posValue total want token amount
    /// @return lastUpdatedBlock block number of last pos update on L1
    function totalFunds()
        public
        view
        override
        returns (uint256 posValue, uint256 lastUpdatedBlock)
    {
        return (
            positionInWantToken.posValue +
                IERC20(vaultWantToken()).balanceOf(address(this)),
            positionInWantToken.lastUpdatedBlock
        );
    }

    /*///////////////////////////////////////////////////////////////
                        STATE MODIFICATION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice L2 position value setter, called by keeper
    /// @param _posValue new position value retrived from L2
    function setPosValue(uint256 _posValue) public keeperOrGovernance {
        LyraPositionHandler._setPosValue(_posValue);
    }

    /// @notice Socket registry setter, called by keeper
    /// @param _socketRegistry address of new socket registry
    function setSocketRegistry(address _socketRegistry) public onlyGovernance {
        emit UpdatedSocketRegistry(socketRegistry, _socketRegistry);
        socketRegistry = _socketRegistry;
    }

    /// @notice L2 Position Handler setter, called by keeper
    /// @param _l2HandlerAddress address of new position handler on L2
    function setL2Handler(address _l2HandlerAddress) public onlyGovernance {
        positionHandlerL2Address = _l2HandlerAddress;
    }

    /*///////////////////////////////////////////////////////////////
                        DEPOSIT / WITHDRAW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice To initiate transfer of want tokens to L2
    /// @param _data DepositParams encoded in bytes
    function _initateDeposit(bytes calldata _data) internal override {
        LyraPositionHandler._deposit(_data);
    }

    /// @notice To confirm transfer of want tokens to L2
    /// @dev Handle anything related to deposit confirmation
    function _confirmDeposit() internal override {}

    /// @notice To initiate transfer of want tokens from L2 to this address
    /// @param _data WithdrawParams encoded in bytes
    function _initiateWithdraw(bytes calldata _data) internal override {
        LyraPositionHandler._withdraw(_data);
    }

    /// @notice To confirm transfer of want tokens from L2 back to this contract
    /// @dev Handle anything related to deposit confirmation
    function _confirmWithdraw() internal override {}

    /*///////////////////////////////////////////////////////////////
                        OPEN / CLOSE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice To initiate open position on L2
    /// @param _data OpenPositionParams encoded in bytes
    function openPosition(bytes calldata _data) public onlyKeeper {
        LyraPositionHandler._openPosition(_data);
    }

    /// @notice To initiate close position on L2
    /// @param _data ClosePositionParams encoded in bytes
    function closePosition(bytes calldata _data) public onlyKeeper {
        LyraPositionHandler._closePosition(_data);
    }
}