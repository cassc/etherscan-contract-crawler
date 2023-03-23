// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../Pausable.sol";
import "../Initializable.sol";

abstract contract AbstractBridge is Initializable, Pausable {
    struct BindingInfo {
        string executionAsset;
        uint256 minAmount;
        uint256 minFee;
        uint256 thresholdFee;
        uint128 beforePercentFee;
        uint128 afterPercentFee;
        bool enabled;
    }

    event ExecutionChainUpdated(uint128 feeChainId, address caller);
    event FeeChainUpdated(uint128 feeChainId, address caller);
    event CallerContractUpdated(bytes32 executorContract, address caller);
    event FeeRecipientUpdated(string feeRecipient, address caller);
    event SignerUpdated(address caller, address oldSigner, address signer);
    event ReferrerFeeUpdated(
        uint128 chainId,
        string referrer,
        uint128 feeInPercent
    );

    uint128 constant PERCENT_FACTOR = 10 ** 6;

    uint16 public feeChainId;
    string public feeRecipient;
    address public adapter;
    address public executor;
    bytes32 callerContract;
    mapping(uint128 => bool) public chains;
    mapping(uint128 => mapping(string => uint128)) public referrersFeeInPercent;

    modifier onlyExecutor() {
        require(msg.sender == executor, "only executor");
        _;
    }

    function init(
        address admin_,
        address adapter_,
        uint16 feeChainId_,
        string calldata feeRecipient_,
        address executor_,
        bytes32 callerContract_
    ) external whenNotInitialized {
        require(admin_ != address(0), "zero address");
        require(adapter_ != address(0), "zero address");
        require(executor_ != address(0), "zero address");
        feeChainId = feeChainId_;
        pauser = admin_;
        admin = admin_;
        feeRecipient = feeRecipient_;
        adapter = adapter_;
        executor = executor_;
        callerContract = callerContract_;
        isInited = true;
    }

    function updateExecutionChain(
        uint128 executionChainId_,
        bool enabled
    ) external onlyAdmin {
        emit ExecutionChainUpdated(executionChainId_, msg.sender);
        chains[executionChainId_] = enabled;
    }

    function updateFeeChain(uint16 feeChainId_) external onlyAdmin {
        emit FeeChainUpdated(feeChainId_, msg.sender);
        feeChainId = feeChainId_;
    }

    function updateCallerContract(bytes32 callerContract_) external onlyAdmin {
        emit CallerContractUpdated(callerContract_, msg.sender);
        callerContract_ = callerContract_;
    }

    function updateFeeRecipient(
        string calldata feeRecipient_
    ) external onlyAdmin {
        emit FeeRecipientUpdated(feeRecipient_, msg.sender);
        feeRecipient = feeRecipient_;
    }

    function updateReferrer(
        uint128 executionChainId_,
        string calldata referrer_,
        uint128 percentFee_
    ) external onlyAdmin {
        require(percentFee_ <= 2e5); // up 20% max
        require(chains[executionChainId_], "execution chain is disable");
        emit ReferrerFeeUpdated(executionChainId_, referrer_, percentFee_);
        referrersFeeInPercent[executionChainId_][referrer_] = percentFee_;
    }
}