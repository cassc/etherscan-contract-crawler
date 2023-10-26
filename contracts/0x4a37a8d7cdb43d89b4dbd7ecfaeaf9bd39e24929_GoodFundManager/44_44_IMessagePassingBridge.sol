// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ILayerZeroFeeEstimator {
    function estimateSendFee(
        uint16 _dstChainId,
        address _fromAddress,
        address _toAddress,
        uint _normalizedAmount,
        bool _useZro,
        bytes memory _adapterParams
    ) external view returns (uint nativeFee, uint zroFee);
}

interface IMessagePassingBridge {
    enum BridgeService {
        AXELAR,
        LZ
    }

    // A struct for storing bridge fees
    struct BridgeFees {
        uint256 minFee;
        uint256 maxFee;
        uint256 fee;
    }

    // A struct for storing bridge limits
    struct BridgeLimits {
        uint256 dailyLimit;
        uint256 txLimit;
        uint256 accountDailyLimit;
        uint256 minAmount;
        bool onlyWhitelisted;
    }

    function lzEndpoint_() external view returns (address);

    function TESTNET() external view returns (bool);

    function guardian() external view returns (address);

    function bridgeFees() external view returns (uint256 minFee, uint256 maxFee, uint256 fee);

    function bridgeLimits()
        external
        view
        returns (
            uint256 dailyLimit,
            uint256 txLimit,
            uint256 accountDailyLimit,
            uint256 minAmount,
            bool onlyWhitelisted
        );

    function bridgeDailyLimit() external view returns (uint256 lastTransferReset, uint256 bridged24Hours);

    function feeRecipient() external view returns (address);

    function toLzChainId(uint256 chainId) external view returns (uint16 lzChainId);

    function setFeeRecipient(address recipient) external;

    function setBridgeLimits(BridgeLimits memory _limits) external;

    function setBridgeFees(BridgeFees memory _fees) external;

    function setDisabledBridges(bytes32[] memory bridgeKeys, bool[] memory disabled) external;

    function setFaucet(address _faucet) external;

    function setGuardian(address _guardian) external;

    function canBridge(address from, uint256 amount) external view returns (bool isWithinLimit, string memory error);

    function withdraw(address token, uint256 amount) external;

    function pauseBridge(bool isPaused) external;

    function bridgeTo(address target, uint256 targetChainId, uint256 amount, BridgeService bridge) external payable;

    function bridgeToWithLz(
        address target,
        uint256 targetChainId,
        uint256 amount,
        bytes calldata adapterParams
    ) external payable;

    function bridgeToWithAxelar(
        address target,
        uint256 targetChainId,
        uint256 amount,
        address gasRefundAddress
    ) external payable;
}