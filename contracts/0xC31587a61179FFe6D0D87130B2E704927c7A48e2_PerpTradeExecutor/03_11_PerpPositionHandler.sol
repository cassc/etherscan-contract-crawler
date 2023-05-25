//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./OptimismWrapper.sol";
import "./SocketV1Controller.sol";
import "../../interfaces/BasePositionHandler.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../PerpL2/interfaces/IPositionHandler.sol";

/// @title PerpPositionHandlerL1
/// @author 0xAd1
/// @notice Used to control the short position handler deployed on Optimism which interacts with PerpV2
contract PerpPositionHandler is
    BasePositionHandler,
    OptimismWrapper,
    SocketV1Controller
{
    /*///////////////////////////////////////////////////////////////
                          STRUCTS FOR DECODING
  //////////////////////////////////////////////////////////////*/

    /// @notice Params required to open a position
    /// @dev send these params encoded in bytes
    /// @param _amount Amount of quoteTokens to open position
    /// @param _isShort true if short, false if long
    /// @param _slippage slippage in 10^4 BPS
    /// @param _gasLimit gaslimit for relaying txn on optimism
    struct OpenPositionParams {
        uint256 _amount;
        bool _isShort;
        uint24 _slippage;
        uint32 _gasLimit;
    }

    /// @notice Params required to close a position
    /// @dev send these params encoded in bytes
    /// @param _slippage slippage in 10^4 BPS
    /// @param _gasLimit gaslimit for relaying txn on optimism
    struct ClosePositionParams {
        uint24 _slippage;
        uint32 _gasLimit;
    }

    /// @notice Params required to send wantToken to PerpHandler on L2
    /// @dev send these params encoded in bytes. Calldata sent to socketRegistry will be decoded and verified
    /// @param _amount Amount of wantToken to send
    /// @param _allowanceTarget Address to provide allowance to
    /// @param _socketRegistry Socket registry to send txn to
    /// @param _socketData calldata of txn to send
    struct DepositParams {
        uint256 _amount;
        address _allowanceTarget;
        address _socketRegistry;
        bytes _socketData;
    }

    /// @notice Params required to send wantToken from PerpHandler on L2 to this contract
    /// @dev send these params encoded in bytes. Calldata sent to socketRegistry will be decoded and verified
    /// @param _amount Amount of wantToken to send
    /// @param _allowanceTarget Address to provide allowance to
    /// @param _socketRegistry Socket registry to send txn to
    /// @param _socketData calldata of txn to send
    /// @param _gasLimit gaslimit for relaying txn on optimism
    struct WithdrawParams {
        uint256 _amount;
        address _allowanceTarget;
        address _socketRegistry;
        bytes _socketData;
        uint32 _gasLimit;
    }

    /*///////////////////////////////////////////////////////////////
                           STATE VARIABLES
  //////////////////////////////////////////////////////////////*/

    /// @notice returns address of wantToken of vault
    address public wantTokenL1;

    /// @notice returns address of wantToken equivalent on L2
    address public wantTokenL2;

    /// @notice returns address of PerpHandler on L2
    address public positionHandlerL2Address;

    /// @notice returns address of socketRegistry on L1
    address public socketRegistry;

    /// @notice returns details of position on PerpHandler on L2
    Position public override positionInWantToken;

    /// @notice Struct to store deposit related stats
    /// @param lastDeposit amount of want tokens sent to PerpHandler on L2
    /// @param totalDeposit total amount deposited to L2 contract yet
    struct DepositStats {
        uint256 lastDeposit;
        uint256 totalDeposit;
    }

    /// @notice returns deposit stats for position handler on L1
    DepositStats public depositStats;

    /*///////////////////////////////////////////////////////////////
                          INITIALIZING
  //////////////////////////////////////////////////////////////*/

    /// @notice Required to init variables in Trade Executor constructor
    /// @param _wantTokenL1 address of wantToken of vault
    /// @param _wantTokenL2 address of wantToken equivalent on L2
    /// @param _positionHandlerL2Address address of PerpHandler on L2
    /// @param _L1CrossDomainMessenger address of optimism gateway cross domain messenger
    /// @param _socketRegistry address of socketRegistry on L1
    function _initHandler(
        address _wantTokenL1,
        address _wantTokenL2,
        address _positionHandlerL2Address,
        address _L1CrossDomainMessenger,
        address _socketRegistry
    ) internal {
        wantTokenL1 = _wantTokenL1;
        wantTokenL2 = _wantTokenL2;
        positionHandlerL2Address = _positionHandlerL2Address;
        L1CrossDomainMessenger = _L1CrossDomainMessenger;
        socketRegistry = _socketRegistry;
    }

    /*///////////////////////////////////////////////////////////////
                      DEPOSIT / WITHDRAW LOGIC
  //////////////////////////////////////////////////////////////*/

    /// @notice Sends tokens to positionHandlerL2 using Socket
    /// @dev Check `sendTokens` implementation in SocketV1Controller for more info
    /// @param data Encoded DepositParams as data
    function _deposit(bytes calldata data) internal override {
        DepositParams memory depositParams = abi.decode(data, (DepositParams));
        require(
            depositParams._socketRegistry == socketRegistry,
            "INVALID_SOCKET_REGISTRY"
        );
        depositStats.lastDeposit = depositParams._amount;
        depositStats.totalDeposit += depositParams._amount;
        sendTokens(
            wantTokenL1,
            depositParams._allowanceTarget,
            depositParams._socketRegistry,
            positionHandlerL2Address,
            depositParams._amount,
            10,
            depositParams._socketData
        );

        emit Deposit(depositParams._amount);
    }

    /// @notice Sends message to SPHL2 to send tokens back to strategy using Socket
    /// @dev Check `withdraw` implementation in SPHL2 for more info
    /// @param data Encoded WithdrawParams as data
    function _withdraw(bytes calldata data) internal override {
        WithdrawParams memory withdrawParams = abi.decode(
            data,
            (WithdrawParams)
        );
        bytes memory L2calldata = abi.encodeWithSelector(
            IPositionHandler.withdraw.selector,
            withdrawParams._amount,
            withdrawParams._allowanceTarget,
            withdrawParams._socketRegistry,
            withdrawParams._socketData
        );
        sendMessageToL2(
            positionHandlerL2Address,
            L2calldata,
            withdrawParams._gasLimit
        );
        emit Withdraw(withdrawParams._amount);
    }

    /*///////////////////////////////////////////////////////////////
                      OPEN / CLOSE LOGIC
  //////////////////////////////////////////////////////////////*/

    /// @notice Sends message to SPHL2 to open a position on PerpV2
    /// @dev Check `openPosition` implementation in SPHL2 for more info
    /// @param data Encoded OpenPositionParams as data
    function _openPosition(bytes calldata data) internal override {
        OpenPositionParams memory openPositionParams = abi.decode(
            data,
            (OpenPositionParams)
        );
        bytes memory L2calldata = abi.encodeWithSelector(
            IPositionHandler.openPosition.selector,
            openPositionParams._isShort,
            openPositionParams._amount,
            openPositionParams._slippage
        );

        sendMessageToL2(
            positionHandlerL2Address,
            L2calldata,
            openPositionParams._gasLimit
        );
    }

    /// @notice Sends message to SPHL2 to close existing position on PerpV2
    /// @dev Check `closePosition` implementation in SPHL2 for more info
    /// @param data Encoded ClosePositionParams as data
    function _closePosition(bytes calldata data) internal override {
        ClosePositionParams memory closePositionParams = abi.decode(
            data,
            (ClosePositionParams)
        );
        bytes memory L2calldata = abi.encodeWithSelector(
            IPositionHandler.closePosition.selector,
            closePositionParams._slippage
        );
        sendMessageToL2(
            positionHandlerL2Address,
            L2calldata,
            closePositionParams._gasLimit
        );
    }

    /// @dev No rewards to claim on Perp
    function _claimRewards(bytes calldata _data) internal override {
        /// Nothing to claim
    }

    /// @notice L2 position value setter, called by keeper
    /// @param _posValue new position value on L2
    function _setPosValue(uint256 _posValue) internal {
        positionInWantToken.posValue = _posValue;
        positionInWantToken.lastUpdatedBlock = block.number;
    }
}