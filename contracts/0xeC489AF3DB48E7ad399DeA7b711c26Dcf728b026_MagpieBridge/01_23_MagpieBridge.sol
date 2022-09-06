// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IHyphenLiquidityPool.sol";
import "./interfaces/IWormhole.sol";
import "./interfaces/IWormholeCore.sol";
import "./interfaces/IMagpieBridge.sol";
import "./lib/LibAssetUpgradeable.sol";
import "./lib/LibBytes.sol";
import "./lib/LibSwap.sol";

contract MagpieBridge is OwnableUpgradeable, UUPSUpgradeable, IMagpieBridge {
    using LibAssetUpgradeable for address;
    using LibBytes for bytes;
    BridgeConfig public bridgeConfig;

    mapping(uint8 => mapping(uint64 => mapping(bytes => DepositHashStatus)))
        private depositHashes;
    address public magpieCoreAddress;
    mapping(uint8 => mapping(uint64 => uint256)) public hyphenAmountIns;

    modifier onlyMagpieCore() {
        require(
            msg.sender == magpieCoreAddress,
            "MagpieRouter: only MagpieCore allowed"
        );
        _;
    }

    modifier onlyRelayer() {
        require(
            msg.sender == bridgeConfig.relayerAddress,
            "MagpieRouter: only Relayer allowed"
        );
        _;
    }

    function updateMagpieCore(address _magpieCoreAddress)
        external
        override
        onlyOwner
    {
        magpieCoreAddress = _magpieCoreAddress;
    }

    function initialize(BridgeConfig memory _bridgeConfig) public initializer {
        bridgeConfig = _bridgeConfig;
        __Ownable_init();
    }

    function updateConfig(BridgeConfig calldata _bridgeConfig)
        external
        override
        onlyOwner
    {
        bridgeConfig = _bridgeConfig;
    }

    function deposit(
        BridgeType bridgeType,
        ValidationInPayload memory payload,
        uint256 amount,
        address toAssetAddress
    ) private returns (uint256 depositAmount, uint64 tokenSequence) {
        depositAmount = amount;
        if (bridgeType == BridgeType.Wormhole) {
            // Dust management
            uint8 toAssetDecimals = getDecimals(toAssetAddress);
            if (toAssetDecimals > 8) {
                depositAmount = normalize(toAssetDecimals, 8, depositAmount);
                depositAmount = denormalize(8, toAssetDecimals, depositAmount);
            }
            toAssetAddress.increaseAllowance(
                bridgeConfig.tokenBridgeAddress,
                depositAmount
            );
            tokenSequence = IWormhole(bridgeConfig.tokenBridgeAddress)
                .transferTokens(
                    toAssetAddress,
                    depositAmount,
                    payload.recipientBridgeChainId,
                    payload.recipientCoreAddress,
                    0,
                    uint32(block.timestamp % 2**32)
                );
        } else {
            if (toAssetAddress.isNative()) {
                IHyphenLiquidityPool(bridgeConfig.hyphenLiquidityPoolAddress)
                    .depositNative{value: depositAmount}(
                    address(uint160(uint256(payload.recipientCoreAddress))),
                    payload.recipientChainId,
                    "Magpie"
                );
            } else {
                toAssetAddress.increaseAllowance(
                    bridgeConfig.hyphenLiquidityPoolAddress,
                    depositAmount
                );
                IHyphenLiquidityPool(bridgeConfig.hyphenLiquidityPoolAddress)
                    .depositErc20(
                        payload.recipientChainId,
                        toAssetAddress,
                        address(uint160(uint256(payload.recipientCoreAddress))),
                        depositAmount,
                        "Magpie"
                    );
            }
        }
    }

    function bridgeIn(
        BridgeType bridgeType,
        ValidationInPayload memory payload,
        uint256 amount,
        address toAssetAddress
    )
        external
        override
        returns (
            uint256 depositAmount,
            uint64 coreSequence,
            uint64 tokenSequence
        )
    {
        (depositAmount, tokenSequence) = deposit(
            bridgeType,
            payload,
            amount,
            toAssetAddress
        );
        uint8 senderIntermediaryDecimals = getDecimals(toAssetAddress);

        bytes memory payloadOut = bytes.concat(
            abi.encodePacked(
                payload.fromAssetAddress,
                payload.toAssetAddress,
                payload.to,
                payload.recipientCoreAddress,
                payload.amountOutMin
            ),
            abi.encodePacked(
                payload.swapOutGasFee,
                payload.destGasTokenAmount,
                payload.destGasTokenAmountOutMin,
                depositAmount,
                tokenSequence,
                senderIntermediaryDecimals
            ),
            abi.encodePacked(
                bridgeConfig.networkId,
                payload.recipientNetworkId,
                bridgeType
            )
        );

        coreSequence = IWormholeCore(bridgeConfig.coreBridgeAddress)
            .publishMessage(
                uint32(block.timestamp % 2**32),
                payloadOut,
                bridgeConfig.consistencyLevel
            );
    }

    function getPayload(bytes memory encodedVm)
        public
        view
        returns (ValidationOutPayload memory payload, uint64 sequence)
    {
        IWormholeCore.VM memory vm = getVM(encodedVm);

        sequence = vm.sequence;
        payload = vm.payload.parse();
    }

    function getVM(bytes memory encodedVm)
        private
        view
        returns (IWormholeCore.VM memory)
    {
        (
            IWormholeCore.VM memory vm,
            bool valid,
            string memory reason
        ) = IWormholeCore(bridgeConfig.coreBridgeAddress).parseAndVerifyVM(
                encodedVm
            );
        require(valid, reason);

        return vm;
    }

    function bridgeOut(
        ValidationOutPayload memory payload,
        uint64 coreSequence,
        uint64 tokenSequence,
        address assetAddress,
        bytes memory encodedVmBridge,
        bytes memory depositHash,
        address caller
    ) external override returns (uint256 amount) {
        if (payload.bridgeType == BridgeType.Wormhole) {
            amount = adjustAssetDecimals(
                assetAddress,
                payload.senderIntermediaryDecimals,
                payload.amountIn
            );
            IWormholeCore.VM memory vm = getVM(encodedVmBridge);
            require(
                tokenSequence == vm.sequence,
                "MagpieBridge: invalid tokenSequence"
            );
            IWormhole(bridgeConfig.tokenBridgeAddress).completeTransfer(
                encodedVmBridge
            );
        } else {
            amount = payload.amountIn;
            if (caller == bridgeConfig.relayerAddress) {
                require(
                    depositHashes[payload.senderNetworkId][coreSequence][
                        depositHash
                    ] == DepositHashStatus.Pending,
                    "MagpieBridge: invalid depositHash"
                );
            } else {
                require(
                    hyphenAmountIns[payload.senderNetworkId][coreSequence] > 0,
                    "MagpieBridge: unable to proceed with the current amount"
                );
                require(
                    depositHashes[payload.senderNetworkId][coreSequence][
                        depositHash
                    ] == DepositHashStatus.Approved,
                    "MagpieBridge: invalid depositHash"
                );
                amount = hyphenAmountIns[payload.senderNetworkId][coreSequence];
            }
            depositHashes[payload.senderNetworkId][coreSequence][
                depositHash
            ] = DepositHashStatus.Successful;
        }
    }

    function getDecimals(address tokenAddress)
        private
        view
        returns (uint8 tokenDecimals)
    {
        tokenDecimals = 18;

        if (!tokenAddress.isNative()) {
            (, bytes memory queriedDecimals) = tokenAddress.staticcall(
                abi.encodeWithSignature("decimals()")
            );
            tokenDecimals = abi.decode(queriedDecimals, (uint8));
        }
    }

    function normalize(
        uint8 fromDecimals,
        uint8 toDecimals,
        uint256 amount
    ) private pure returns (uint256 amountOut) {
        uint256 exponent;

        exponent = fromDecimals - toDecimals;
        amountOut = amount / 10**exponent;
    }

    function denormalize(
        uint8 fromDecimals,
        uint8 toDecimals,
        uint256 amount
    ) private pure returns (uint256 amountOut) {
        uint256 exponent;

        exponent = toDecimals - fromDecimals;
        amountOut = amount * 10**exponent;
    }

    function adjustAssetDecimals(
        address assetAddress,
        uint8 fromDecimals,
        uint256 amountIn
    ) public view returns (uint256 amount) {
        uint8 receiverIntermediaryDecimals = getDecimals(assetAddress);
        if (fromDecimals > receiverIntermediaryDecimals) {
            amount = normalize(
                fromDecimals,
                receiverIntermediaryDecimals,
                amountIn
            );
        } else {
            amount = denormalize(
                fromDecimals,
                receiverIntermediaryDecimals,
                amountIn
            );
        }
    }

    function approveDepositHash(
        uint8 senderNetworkId,
        uint64 coreSequence,
        bytes memory depositHash,
        uint256 amountIn
    ) external onlyRelayer {
        require(
            depositHashes[senderNetworkId][coreSequence][depositHash] ==
                DepositHashStatus.Pending,
            "MagpieBridge: invalid depositHash"
        );
        depositHashes[senderNetworkId][coreSequence][
            depositHash
        ] = DepositHashStatus.Approved;
        hyphenAmountIns[senderNetworkId][coreSequence] = amountIn;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}