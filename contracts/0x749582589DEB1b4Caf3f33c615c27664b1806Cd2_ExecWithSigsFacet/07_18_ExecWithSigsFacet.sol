// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BFacetOwner} from "../facets/base/BFacetOwner.sol";
import {LibDiamond} from "../libraries/diamond/standard/LibDiamond.sol";
import {ExecWithSigsBase} from "./base/ExecWithSigsBase.sol";
import {GelatoCallUtils} from "../libraries/GelatoCallUtils.sol";
import {
    _getBalance,
    _simulateAndRevert,
    _revertWithFee
} from "../functions/Utils.sol";
import {
    ExecWithSigs,
    ExecWithSigsFeeCollector,
    ExecWithSigsRelayContext,
    Message,
    MessageFeeCollector,
    MessageRelayContext
} from "../types/CallTypes.sol";
import {_isCheckerSigner} from "./storage/SignerStorage.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {
    _encodeRelayContext,
    _encodeFeeCollector
} from "@gelatonetwork/relay-context/contracts/functions/GelatoRelayUtils.sol";

contract ExecWithSigsFacet is ExecWithSigsBase, BFacetOwner {
    using GelatoCallUtils for address;
    using LibDiamond for address;

    //solhint-disable-next-line const-name-snakecase
    string public constant name = "ExecWithSigsFacet";
    //solhint-disable-next-line const-name-snakecase
    string public constant version = "1";

    address public immutable feeCollector;

    event LogExecWithSigs(
        bytes32 correlationId,
        Message msg,
        address indexed executorSigner,
        address indexed checkerSigner,
        uint256 estimatedGasUsed,
        address sender
    );

    event LogExecWithSigsFeeCollector(
        bytes32 correlationId,
        MessageFeeCollector msg,
        address indexed executorSigner,
        address indexed checkerSigner,
        uint256 fee,
        uint256 estimatedGasUsed,
        address sender
    );

    event LogExecWithSigsRelayContext(
        bytes32 correlationId,
        MessageRelayContext msg,
        address indexed executorSigner,
        address indexed checkerSigner,
        uint256 observedFee,
        uint256 estimatedGasUsed,
        address sender
    );

    constructor(address _feeCollector) {
        feeCollector = _feeCollector;
    }

    // solhint-disable function-max-lines
    /// @param _call Execution payload packed into ExecWithSigs struct
    /// @return estimatedGasUsed Estimated gas used using gas metering
    function execWithSigs(ExecWithSigs calldata _call)
        external
        returns (uint256 estimatedGasUsed)
    {
        uint256 startGas = gasleft();

        _requireSignerDeadline(
            _call.msg.deadline,
            "ExecWithSigsFacet.execWithSigs._requireSignerDeadline:"
        );

        bytes32 digest = _getDigest(_getDomainSeparator(), _call.msg);

        address executorSigner = _requireExecutorSignerSignature(
            digest,
            _call.executorSignerSig,
            "ExecWithSigsFacet.execWithSigs._requireExecutorSignerSignature:"
        );

        address checkerSigner = _requireCheckerSignerSignature(
            digest,
            _call.checkerSignerSig,
            "ExecWithSigsFacet.execWithSigs._requireCheckerSignerSignature:"
        );

        // call forward
        _call.msg.service.revertingContractCall(
            _call.msg.data,
            "ExecWithSigsFacet.execWithSigs:"
        );

        estimatedGasUsed = startGas - gasleft();

        emit LogExecWithSigs(
            _call.correlationId,
            _call.msg,
            executorSigner,
            checkerSigner,
            estimatedGasUsed,
            msg.sender
        );
    }

    // solhint-disable function-max-lines
    /// @param _call Execution payload packed into ExecWithSigsFeeCollector struct
    /// @return estimatedGasUsed Estimated gas used using gas metering
    /// @return observedFee The fee transferred to the fee collector
    function execWithSigsFeeCollector(ExecWithSigsFeeCollector calldata _call)
        external
        returns (uint256 estimatedGasUsed, uint256 observedFee)
    {
        uint256 startGas = gasleft();

        _requireSignerDeadline(
            _call.msg.deadline,
            "ExecWithSigsFacet.execWithSigsFeeCollector._requireSignerDeadline:"
        );

        bytes32 digest = _getDigestFeeCollector(
            _getDomainSeparator(),
            _call.msg
        );

        address executorSigner = _requireExecutorSignerSignature(
            digest,
            _call.executorSignerSig,
            "ExecWithSigsFacet.execWithSigsFeeCollector._requireExecutorSignerSignature:"
        );

        address checkerSigner = _requireCheckerSignerSignature(
            digest,
            _call.checkerSignerSig,
            "ExecWithSigsFacet.execWithSigsFeeCollector._requireCheckerSignerSignature:"
        );

        {
            uint256 preFeeTokenBalance = _getBalance(
                _call.msg.feeToken,
                feeCollector
            );

            // call forward + append fee collector
            _call.msg.service.revertingContractCall(
                _encodeFeeCollector(_call.msg.data, feeCollector),
                "ExecWithSigsFacet.execWithSigsFeeCollector:"
            );

            uint256 postFeeTokenBalance = _getBalance(
                _call.msg.feeToken,
                feeCollector
            );

            observedFee = postFeeTokenBalance - preFeeTokenBalance;
        }

        estimatedGasUsed = startGas - gasleft();

        emit LogExecWithSigsFeeCollector(
            _call.correlationId,
            _call.msg,
            executorSigner,
            checkerSigner,
            observedFee,
            estimatedGasUsed,
            msg.sender
        );
    }

    // solhint-disable function-max-lines
    /// @param _call Execution payload packed into ExecWithSigsRelayContext struct
    /// @return estimatedGasUsed Estimated gas used using gas metering
    /// @return observedFee The fee transferred to the fee collector
    function execWithSigsRelayContext(ExecWithSigsRelayContext calldata _call)
        external
        returns (uint256 estimatedGasUsed, uint256 observedFee)
    {
        uint256 startGas = gasleft();

        _requireSignerDeadline(
            _call.msg.deadline,
            "ExecWithSigsFacet.execWithSigsRelayContext._requireSignerDeadline:"
        );

        bytes32 digest = _getDigestRelayContext(
            _getDomainSeparator(),
            _call.msg
        );

        address executorSigner = _requireExecutorSignerSignature(
            digest,
            _call.executorSignerSig,
            "ExecWithSigsFacet.execWithSigsRelayContext._requireExecutorSignerSignature:"
        );

        address checkerSigner = _requireCheckerSignerSignature(
            digest,
            _call.checkerSignerSig,
            "ExecWithSigsFacet.execWithSigsRelayContext._requireCheckerSignerSignature:"
        );

        {
            uint256 preFeeTokenBalance = _getBalance(
                _call.msg.feeToken,
                feeCollector
            );

            // call forward + append fee collector, feeToken, fee
            _call.msg.service.revertingContractCall(
                _encodeRelayContext(
                    _call.msg.data,
                    feeCollector,
                    _call.msg.feeToken,
                    _call.msg.fee
                ),
                "ExecWithSigsFacet.execWithSigsRelayContext:"
            );

            uint256 postFeeTokenBalance = _getBalance(
                _call.msg.feeToken,
                feeCollector
            );

            observedFee = postFeeTokenBalance - preFeeTokenBalance;
        }

        estimatedGasUsed = startGas - gasleft();

        emit LogExecWithSigsRelayContext(
            _call.correlationId,
            _call.msg,
            executorSigner,
            checkerSigner,
            observedFee,
            estimatedGasUsed,
            msg.sender
        );
    }

    /// @dev Used for off-chain simulation only!
    function simulateExecWithSigs(address _service, bytes memory _data)
        external
    {
        _simulateAndRevert(_service, gasleft(), _data);
    }

    /// @dev Used for off-chain simulation only!
    function simulateExecWithSigsFeeCollector(
        address _service,
        bytes calldata _data,
        address _feeToken
    ) external {
        uint256 startGas = gasleft();

        uint256 preFeeTokenBalance = _getBalance(_feeToken, feeCollector);

        (bool success, ) = _service.call(
            _encodeFeeCollector(_data, feeCollector)
        );

        uint256 postFeeTokenBalance = _getBalance(_feeToken, feeCollector);

        _revertWithFee(
            success,
            startGas - gasleft(),
            postFeeTokenBalance - preFeeTokenBalance
        );
    }

    /// @dev Used for off-chain simulation only!
    function simulateExecWithSigsRelayContext(
        address _service,
        bytes calldata _data,
        address _feeToken,
        uint256 _fee
    ) external {
        uint256 startGas = gasleft();

        uint256 preFeeTokenBalance = _getBalance(_feeToken, feeCollector);

        (bool success, ) = _service.call(
            _encodeRelayContext(_data, feeCollector, _feeToken, _fee)
        );

        uint256 postFeeTokenBalance = _getBalance(_feeToken, feeCollector);

        _revertWithFee(
            success,
            startGas - gasleft(),
            postFeeTokenBalance - preFeeTokenBalance
        );
    }

    //solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _getDomainSeparator();
    }

    function _getDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        bytes(
                            //solhint-disable-next-line max-line-length
                            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                        )
                    ),
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    block.chainid,
                    address(this)
                )
            );
    }
}