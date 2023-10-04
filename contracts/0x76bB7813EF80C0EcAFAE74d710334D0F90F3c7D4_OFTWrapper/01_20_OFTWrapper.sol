// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { ReentrancyGuard } from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import { IOFTV2 } from '@layerzerolabs/solidity-examples/contracts/token/oft/v2/IOFTV2.sol';
import { BalanceManagement } from '../BalanceManagement.sol';
import { CallerGuard } from '../CallerGuard.sol';
import { Pausable } from '../Pausable.sol';
import { SystemVersionId } from '../SystemVersionId.sol';
import '../helpers/TransferHelper.sol' as TransferHelper;

/**
 * @title OFTWrapper
 * @notice The OFT wrapper contract
 */
contract OFTWrapper is SystemVersionId, Pausable, ReentrancyGuard, CallerGuard, BalanceManagement {
    /**
     * @notice OFT `sendFrom` parameters structure
     * @param from The owner of token
     * @param dstChainId The destination chain identifier
     * @param toAddress Can be any size depending on the `dstChainId`
     * @param amount The quantity of tokens in wei
     * @param callParams LayerZero call parameters
     */
    struct SendFromParams {
        address from;
        uint16 dstChainId;
        bytes32 toAddress;
        uint256 amount;
        IOFTV2.LzCallParams callParams;
    }

    /**
     * @notice OFT `estimateSendFee` parameters structure
     * @param dstChainId The destination chain identifier
     * @param toAddress Can be any size depending on the `dstChainId`
     * @param amount The quantity of tokens in wei
     * @param useZro The ZRO token payment flag
     * @param adapterParams LayerZero adapter parameters
     */
    struct EstimateSendFeeParams {
        uint16 dstChainId;
        bytes32 toAddress;
        uint256 amount;
        bool useZro;
        bytes adapterParams;
    }

    /**
     * @dev The address of the fee collector
     */
    address public feeCollector;

    /**
     * @notice Emitted when the address of the fee collector is set
     * @param feeCollector The address of the fee collector
     */
    event SetFeeCollector(address indexed feeCollector);

    /**
     * @notice Emitted when the oftSendFrom function is invoked
     * @param from The owner of token
     * @param oft The address of the OFT
     * @param underlyingToken The address of the underlying token
     * @param amount The quantity of tokens in wei
     * @param processingFee The processing fee value
     * @param timestamp The timestamp of the action (in seconds)
     */
    event OftSendFrom(
        address indexed from,
        IOFTV2 indexed oft,
        IERC20 indexed underlyingToken,
        uint256 amount,
        uint256 processingFee,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the caller is not the token sender
     */
    error SenderError();

    /**
     * @notice Deploys the OFTWrapper contract
     * @param _feeCollector The address of the fee collector
     * @param _owner The address of the initial owner of the contract
     * @param _managers The addresses of initial managers of the contract
     * @param _addOwnerToManagers The flag to optionally add the owner to the list of managers
     */
    constructor(
        address _feeCollector,
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    ) {
        _setFeeCollector(_feeCollector);

        _initRoles(_owner, _managers, _addOwnerToManagers);
    }

    /**
     * @notice Sets the address of the fee collector
     * @param _feeCollector The address of the fee collector
     */
    function setFeeCollector(address _feeCollector) external onlyManager {
        _setFeeCollector(_feeCollector);
    }

    /**
     * @notice Sends tokens to the destination chain
     * @param _oft The address of the OFT
     * @param _underlyingToken The address of the underlying token
     * @param _params The `sendFrom` parameters
     * @param _processingFee The processing fee value
     */
    function oftSendFrom(
        IOFTV2 _oft,
        IERC20 _underlyingToken,
        SendFromParams calldata _params,
        uint256 _processingFee
    ) external payable whenNotPaused nonReentrant checkCaller {
        if (_params.from != msg.sender) {
            revert SenderError();
        }

        bool useUnderlyingToken = (address(_underlyingToken) != address(0));

        if (useUnderlyingToken) {
            TransferHelper.safeTransferFrom(
                address(_underlyingToken),
                _params.from,
                address(this),
                _params.amount
            );

            TransferHelper.safeApprove(address(_underlyingToken), address(_oft), _params.amount);

            _oft.sendFrom{ value: msg.value - _processingFee }(
                address(this),
                _params.dstChainId,
                _params.toAddress,
                _params.amount,
                _params.callParams
            );

            TransferHelper.safeApprove(address(_underlyingToken), address(_oft), 0);
        } else {
            _oft.sendFrom{ value: msg.value - _processingFee }(
                _params.from,
                _params.dstChainId,
                _params.toAddress,
                _params.amount,
                _params.callParams
            );
        }

        TransferHelper.safeTransferNative(feeCollector, _processingFee);

        emit OftSendFrom(
            _params.from,
            _oft,
            _underlyingToken,
            _params.amount,
            _processingFee,
            block.timestamp
        );
    }

    /**
     * @notice Estimates the cross-chain transfer fees
     * @param _oft The address of the OFT
     * @param _params The `estimateSendFee` parameters
     * @param _processingFee The processing fee value
     */
    function oftEstimateSendFee(
        IOFTV2 _oft,
        EstimateSendFeeParams calldata _params,
        uint256 _processingFee
    ) external view returns (uint256 nativeFee, uint256 zroFee) {
        (uint256 oftNativeFee, uint256 oftZroFee) = _oft.estimateSendFee(
            _params.dstChainId,
            _params.toAddress,
            _params.amount,
            _params.useZro,
            _params.adapterParams
        );

        return (oftNativeFee + _processingFee, oftZroFee);
    }

    function _setFeeCollector(address _feeCollector) private {
        feeCollector = _feeCollector;

        emit SetFeeCollector(_feeCollector);
    }
}