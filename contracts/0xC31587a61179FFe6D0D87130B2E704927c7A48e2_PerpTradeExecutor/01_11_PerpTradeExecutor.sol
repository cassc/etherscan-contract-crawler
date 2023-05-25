//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../BaseTradeExecutor.sol";
import "./PerpPositionHandler.sol";
import "../../interfaces/IVault.sol";

/// @title PerpTradeExecutor
/// @author 0xAd1
/// @notice A contract to execute manage a Perp Position Handler on Optimism
contract PerpTradeExecutor is BaseTradeExecutor, PerpPositionHandler {
    /// @notice Constructor of the Trade Executor
    /// @param vault Address of the Vault contract
    /// @param _wantTokenL2 address of wantToken equivalent on L2
    /// @param _l2HandlerAddress address of PerpHandler on L2
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
                            VIEW FUNCTONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns total wantTokens present in PerpHandler L2 and this Trade Executor
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
        PerpPositionHandler._setPosValue(_posValue);
    }

    /// @notice Socket registry setter, called by keeper
    /// @param _socketRegistry address of new socket registry
    function setSocketRegistry(address _socketRegistry) public onlyGovernance {
        socketRegistry = _socketRegistry;
    }

    /// @notice Method to update handler info, called by keeper
    /// @param _wantTokenL2 address of wantToken equivalent on L2
    /// @param _l2HandlerAddress address of PerpHandler on L2
    /// @param _L1CrossDomainMessenger address of optimism gateway cross domain messenger
    /// @param _socketRegistry address of socketRegistry on L1
    function setHandler(
        address _wantTokenL2,
        address _l2HandlerAddress,
        address _L1CrossDomainMessenger,
        address _socketRegistry
    ) public onlyGovernance {
        _initHandler(
            vaultWantToken(),
            _wantTokenL2,
            _l2HandlerAddress,
            _L1CrossDomainMessenger,
            _socketRegistry
        );
    }

    /*///////////////////////////////////////////////////////////////
                        DEPOSIT / WITHDRAW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice To initiate transfer of want tokens to L2
    /// @param _data DepositParams encoded in bytes
    function _initateDeposit(bytes calldata _data) internal override {
        PerpPositionHandler._deposit(_data);
    }

    /// @notice To confirm transfer of want tokens to L2
    /// @dev Handle anything related to deposit confirmation
    function _confirmDeposit() internal override {}

    /// @notice To initiate transfer of want tokens from L2 to this address
    /// @param _data WithdrawParams encoded in bytes
    function _initiateWithdraw(bytes calldata _data) internal override {
        PerpPositionHandler._withdraw(_data);
    }

    /// @notice To confirm transfer of want tokens to L2
    /// @dev Handle anything related to deposit confirmation
    function _confirmWithdraw() internal override {}

    /*///////////////////////////////////////////////////////////////
                        OPEN / CLOSE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice To initiate open position on L2
    /// @param _data OpenPositionParams encoded in bytes
    function openPosition(bytes calldata _data) public onlyKeeper {
        PerpPositionHandler._openPosition(_data);
    }

    /// @notice To initiate close position on L2
    /// @param _data ClosePositionParams encoded in bytes
    function closePosition(bytes calldata _data) public onlyKeeper {
        PerpPositionHandler._closePosition(_data);
    }
}