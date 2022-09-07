// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IStargateRouter.sol";
import "./interfaces/IStargateFactory.sol";
import "./interfaces/IStargatePool.sol";
import "./interfaces/IStargateFeeLibrary.sol";
import "./interfaces/IWormhole.sol";
import "./interfaces/IWormholeCore.sol";
import "./interfaces/IMagpieBridge.sol";
import "./lib/LibAsset.sol";
import "./lib/LibBytes.sol";
import "./lib/LibSwap.sol";

contract MagpieBridge is Ownable, IMagpieBridge {
    using LibAsset for address;
    using LibBytes for bytes;

    BridgeConfig public bridgeConfig;
    address public magpieCoreAddress;

    mapping(uint8 => mapping(uint64 => uint256)) public sequences;

    modifier onlyMagpieCore() {
        require(
            msg.sender == magpieCoreAddress,
            "MagpieBridge: only MagpieCore allowed"
        );
        _;
    }

    constructor(BridgeConfig memory _bridgeConfig) {
        bridgeConfig = _bridgeConfig;
    }

    function updateMagpieCore(address _magpieCoreAddress)
        external
        override
        onlyOwner
    {
        magpieCoreAddress = _magpieCoreAddress;
    }

    function updateConfig(BridgeConfig calldata _bridgeConfig)
        external
        override
        onlyOwner
    {
        bridgeConfig = _bridgeConfig;
    }

    function depositWormhole(
        ValidationInPayload memory payload,
        uint256 amount,
        address toAssetAddress
    ) private returns (uint256 depositAmount, uint64 tokenSequence) {
        depositAmount = amount;
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
    }

    function depositStargate(
        ValidationInPayload memory payload,
        uint64 coreSequence,
        uint256 amount,
        address refundAddress,
        address toAssetAddress
    ) private {
        toAssetAddress.increaseAllowance(
            bridgeConfig.stargateRouterAddress,
            amount
        );
        IStargateRouter(bridgeConfig.stargateRouterAddress).swap{
            value: msg.value
        }(
            uint16(payload.layerZeroRecipientChainId),
            payload.sourcePoolId,
            payload.destPoolId,
            payable(refundAddress),
            amount,
            getMinAmountLD(amount, payload),
            IStargateRouter.lzTxObj(0, 0, abi.encodePacked(refundAddress)),
            abi.encodePacked(
                address(uint160(uint256(payload.recipientCoreAddress)))
            ),
            bytes.concat(
                abi.encodePacked(
                    bridgeConfig.networkId,
                    bytes32(uint256(uint160(magpieCoreAddress)))
                ),
                abi.encodePacked(coreSequence)
            )
        );
    }

    function bridgeIn(
        BridgeType bridgeType,
        ValidationInPayload memory payload,
        uint256 amount,
        address toAssetAddress,
        address refundAddress
    )
        external
        payable
        override
        onlyMagpieCore
        returns (
            uint256 depositAmount,
            uint64 coreSequence,
            uint64 tokenSequence
        )
    {
        depositAmount = amount;
        tokenSequence = 0;

        if (bridgeType == BridgeType.Wormhole) {
            (depositAmount, tokenSequence) = depositWormhole(
                payload,
                amount,
                toAssetAddress
            );
        }
        uint8 senderIntermediaryDecimals = getDecimals(toAssetAddress);

        bytes memory payloadOut = bytes.concat(
            abi.encodePacked(
                payload.fromAssetAddress,
                payload.toAssetAddress,
                payload.to,
                payload.recipientCoreAddress,
                bytes32(uint256(uint160(magpieCoreAddress))),
                payload.amountOutMin
            ),
            abi.encodePacked(
                payload.swapOutGasFee,
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

        require(payloadOut.length == 268, "MagpieBridge: invalid payloadOut"); // Validating payloadOut

        coreSequence = IWormholeCore(bridgeConfig.coreBridgeAddress)
            .publishMessage(
                uint32(block.timestamp % 2**32),
                payloadOut,
                bridgeConfig.consistencyLevel
            );

        if (bridgeType == BridgeType.Stargate) {
            depositStargate(
                payload,
                coreSequence,
                amount,
                refundAddress,
                toAssetAddress
            );
        }
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
        BridgeArgs memory bridgeArgs,
        uint64 tokenSequence,
        address assetAddress
    ) external override onlyMagpieCore returns (uint256 amount) {
        if (payload.bridgeType == BridgeType.Wormhole) {
            amount = adjustAssetDecimals(
                assetAddress,
                payload.senderIntermediaryDecimals,
                payload.amountIn
            );
            IWormholeCore.VM memory vm = getVM(bridgeArgs.encodedVmBridge);
            require(
                tokenSequence == vm.sequence,
                "MagpieBridge: invalid tokenSequence"
            );
            IWormhole(bridgeConfig.tokenBridgeAddress).completeTransfer(
                bridgeArgs.encodedVmBridge
            );
        } else {
            IStargateRouter(bridgeConfig.stargateRouterAddress).clearCachedSwap(
                    bridgeArgs.senderStargateChainId,
                    bridgeArgs.senderStargateBridgeAddress,
                    bridgeArgs.nonce
                );
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

    function getSgPayload(bytes memory encodedBytes)
        public
        pure
        returns (
            uint8 networkId,
            bytes32 sender,
            uint64 coreSequence
        )
    {
        (networkId, sender, coreSequence) = encodedBytes.parseSgPayload();
    }

    function getMinAmountLD(uint256 amount, ValidationInPayload memory payload)
        private view
        returns (uint256)
    {
        address stargateFactoryAddress = IStargateRouter(
            bridgeConfig.stargateRouterAddress
        ).factory();
        address poolAddress = IStargateFactory(stargateFactoryAddress).getPool(
            payload.sourcePoolId
        );
        address feeLibraryAddress = IStargatePool(poolAddress).feeLibrary();
        uint256 convertRate = IStargatePool(poolAddress).convertRate();
        IStargatePool.SwapObj memory s = IStargateFeeLibrary(feeLibraryAddress)
            .getFees(
                payload.sourcePoolId,
                payload.destPoolId,
                uint16(payload.layerZeroRecipientChainId),
                address(this),
                amount
            );
        s.amount =
            (amount /
                convertRate -
                (s.eqFee + s.protocolFee + s.lpFee) +
                s.eqReward) *
            convertRate;
        return s.amount;
    }
}