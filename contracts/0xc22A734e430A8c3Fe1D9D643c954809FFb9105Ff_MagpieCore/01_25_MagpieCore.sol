// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IMagpieCore.sol";
import "./interfaces/IMagpieRouter.sol";
import "./lib/LibUint256Array.sol";
import "./lib/LibAssetUpgradeable.sol";
import "./lib/LibAddressArray.sol";
import "./security/Pausable.sol";
import "./interfaces/IMagpieBridge.sol";
import "./lib/LibBytes.sol";
import "./lib/LibSwap.sol";

contract MagpieCore is
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    Pausable,
    IMagpieCore
{
    using LibAssetUpgradeable for address;
    using LibBytes for bytes;
    using LibSwap for IMagpieRouter.SwapArgs;
    using LibUint256Array for uint256[];
    using LibAddressArray for address[];

    mapping(address => uint256) public gasFeeAccumulatedByToken;
    mapping(address => mapping(address => uint256)) public gasFeeAccumulated;
    mapping(uint8 => mapping(uint64 => uint256)) public hyphenAmountIns;
    mapping(uint8 => mapping(uint64 => bool)) public sequences;
    Config public config;

    function initialize(Config memory _config) public initializer {
        config = _config;
        __ReentrancyGuard_init();
        __Ownable_init();
        __Pausable_init(_config.pauserAddress);
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "MagpieCore: expired transaction");
        _;
    }

    function updateConfig(Config calldata _config) external override onlyOwner {
        require(_config.weth != address(0), "MagpieCore: invalid weth");
        require(
            _config.hyphenLiquidityPoolAddress != address(0),
            "MagpieCore: invalid hyphenLiquidityPoolAddress"
        );
        require(
            _config.coreBridgeAddress != address(0),
            "MagpieCore: invalid coreBridgeAddress"
        );
        require(
            _config.consistencyLevel > 1,
            "MagpieCore: invalid consistencyLevel"
        );

        config = _config;
        emit ConfigUpdated(config, msg.sender);
    }

    function _prepareAsset(
        IMagpieRouter.SwapArgs memory swapArgs,
        address assetAddress,
        bool wrap
    ) private returns (IMagpieRouter.SwapArgs memory newSwapArgs) {
        uint256 amountIn = swapArgs.getAmountIn();

        if (wrap) {
            require(msg.value == amountIn, "MagpieCore: asset not received");
            IWETH(config.weth).deposit{value: amountIn}();
        }

        for (uint256 i = 0; i < swapArgs.assets.length; i++) {
            if (assetAddress == swapArgs.assets[i]) {
                swapArgs.assets[i] = config.weth;
            }
        }

        newSwapArgs = swapArgs;
    }

    function _getWrapSwapConfig(
        IMagpieRouter.SwapArgs memory swapArgs,
        bool transferFromSender
    ) private view returns (WrapSwapConfig memory wrapSwapConfig) {
        address fromAssetAddress = swapArgs.getFromAssetAddress();
        address toAssetAddress = swapArgs.getToAssetAddress();
        if (fromAssetAddress.isNative() && toAssetAddress == config.weth) {
            wrapSwapConfig.prepareFromAsset = true;
            wrapSwapConfig.prepareToAsset = false;
            wrapSwapConfig.swap = false;
            wrapSwapConfig.unwrapToAsset = false;
        } else if (
            fromAssetAddress == config.weth && toAssetAddress.isNative()
        ) {
            wrapSwapConfig.prepareFromAsset = false;
            wrapSwapConfig.prepareToAsset = true;
            wrapSwapConfig.swap = false;
            wrapSwapConfig.unwrapToAsset = true;
        } else if (
            fromAssetAddress == toAssetAddress && swapArgs.assets.length == 1
        ) {
            wrapSwapConfig.prepareFromAsset = false;
            wrapSwapConfig.prepareToAsset = false;
            wrapSwapConfig.swap = false;
            wrapSwapConfig.unwrapToAsset = false;
        } else {
            wrapSwapConfig.prepareFromAsset = fromAssetAddress.isNative();
            wrapSwapConfig.prepareToAsset = toAssetAddress.isNative();
            wrapSwapConfig.swap = true;
            wrapSwapConfig.unwrapToAsset = toAssetAddress.isNative();
        }
        wrapSwapConfig.transferFromSender =
            !fromAssetAddress.isNative() &&
            transferFromSender;
    }

    function _wrapSwap(
        IMagpieRouter.SwapArgs memory swapArgs,
        WrapSwapConfig memory wrapSwapConfig
    ) private returns (uint256[] memory amountOuts) {
        require(swapArgs.routes.length > 0, "MagpieCore: invalid route size");
        address fromAssetAddress = swapArgs.getFromAssetAddress();
        address toAssetAddress = swapArgs.getToAssetAddress();
        address payable to = swapArgs.to;
        uint256 amountIn = swapArgs.getAmountIn();
        uint256 amountOut = amountIn;

        if (wrapSwapConfig.prepareFromAsset) {
            swapArgs = _prepareAsset(swapArgs, fromAssetAddress, true);
        }

        if (wrapSwapConfig.prepareToAsset) {
            swapArgs = _prepareAsset(swapArgs, toAssetAddress, false);
        }

        if (wrapSwapConfig.transferFromSender) {
            fromAssetAddress.transferFrom(msg.sender, address(this), amountIn);
        }

        if (wrapSwapConfig.swap) {
            swapArgs.getFromAssetAddress().transfer(
                payable(config.magpieRouterAddress),
                amountIn
            );
            amountOuts = IMagpieRouter(config.magpieRouterAddress).swap(
                swapArgs
            );
            amountOut = amountOuts.sum();
        } else {
            amountOuts = new uint256[](1);
            amountOuts[0] = amountIn;
        }

        if (wrapSwapConfig.unwrapToAsset && amountOut > 0) {
            swapArgs.getToAssetAddress().transfer(payable(config.magpieRouterAddress), amountOut);
            IMagpieRouter(config.magpieRouterAddress).withdraw(config.weth, amountOut);
        }

        if (to != address(this) && amountOut > 0) {
            toAssetAddress.transfer(to, amountOut);
        }
    }

    receive() external payable {
        require(config.magpieRouterAddress == msg.sender, "MagpieCore: invalid sender");
    }

    function swap(IMagpieRouter.SwapArgs calldata swapArgs)
        external
        payable
        ensure(swapArgs.deadline)
        whenNotPaused
        nonReentrant
        returns (uint256[] memory amountOuts)
    {
        WrapSwapConfig memory wrapSwapConfig = _getWrapSwapConfig(
            swapArgs,
            true
        );
        amountOuts = _wrapSwap(swapArgs, wrapSwapConfig);

        emit Swapped(swapArgs, amountOuts, msg.sender);
    }

    function swapIn(SwapInArgs calldata args)
        external
        payable
        override
        ensure(args.swapArgs.deadline)
        whenNotPaused
        nonReentrant
        returns (
            uint256[] memory amountOuts,
            uint256 depositAmount,
            uint64 coreSequence,
            uint64 tokenSequence
        )
    {
        require(
            args.swapArgs.to == address(this),
            "MagpieCore: invalid swapArgs to"
        );

        address toAssetAddress = args.swapArgs.getToAssetAddress();

        require(
            config.senderIntermediaries.includes(toAssetAddress),
            "MagpieCore: invalid toAssetAddress"
        );

        WrapSwapConfig memory wrapSwapConfig = _getWrapSwapConfig(
            args.swapArgs,
            true
        );
        amountOuts = _wrapSwap(args.swapArgs, wrapSwapConfig);

        uint256 amountOut = amountOuts.sum();

        toAssetAddress.transfer(payable(config.magpieBridgeAddress), amountOut);

        (depositAmount, coreSequence, tokenSequence) = IMagpieBridge(
            config.magpieBridgeAddress
        ).bridgeIn(args.bridgeType, args.payload, amountOut, toAssetAddress);

        emit SwappedIn(
            args,
            amountOuts,
            depositAmount,
            args.payload.recipientNetworkId,
            coreSequence,
            tokenSequence,
            msg.sender
        );
    }

    function swapOut(SwapOutArgs calldata args)
        external
        override
        ensure(args.swapArgs.deadline)
        whenNotPaused
        nonReentrant
        returns (uint256[] memory amountOuts)
    {
        (
            IMagpieBridge.ValidationOutPayload memory payload,
            uint64 coreSequence
        ) = IMagpieBridge(config.magpieBridgeAddress).getPayload(
                args.encodedVmCore
            );

        require(
            !sequences[payload.senderNetworkId][coreSequence],
            "MagpieCore: already used sequence"
        );

        sequences[payload.senderNetworkId][coreSequence] = true;

        IMagpieRouter.SwapArgs memory swapArgs = args.swapArgs;

        if (
            payload.bridgeType == IMagpieBridge.BridgeType.Hyphen &&
            msg.sender == config.relayerAddress
        ) {
            uint256 hyphenAmountIn = IMagpieBridge(config.magpieBridgeAddress)
                .adjustAssetDecimals(
                    payload.fromAssetAddress,
                    payload.senderIntermediaryDecimals,
                    payload.amountIn
                );
            require(
                hyphenAmountIn >= swapArgs.getAmountIn(),
                "MagpieCore: invalid amountIn"
            );
            uint256 thresholdAmountIn = hyphenAmountIn -
                (hyphenAmountIn * 15) /
                100;
            payload.amountIn = swapArgs.getAmountIn();
            require(
                payload.amountIn >= thresholdAmountIn,
                "MagpieCore: unable to proceed with the current amount"
            );
        }

        uint256 amountIn = IMagpieBridge(config.magpieBridgeAddress).bridgeOut(
            payload,
            coreSequence,
            payload.tokenSequence,
            args.swapArgs.getFromAssetAddress(),
            args.encodedVmBridge,
            args.depositHash,
            msg.sender
        );

        address fromAssetAddress = swapArgs.getFromAssetAddress();
        address toAssetAddress = swapArgs.getToAssetAddress();

        if (payload.to == msg.sender) {
            payload.swapOutGasFee = 0;
            payload.amountOutMin = swapArgs.amountOutMin;
        } else {
            swapArgs.amountOutMin = payload.amountOutMin;
        }

        require(
            swapArgs.getAmountIn() <= amountIn,
            "MagpieCore: invalid amountIn"
        );

        require(
            config.receiverIntermediaries.includes(payload.fromAssetAddress),
            "MagpieCore: fromAssetAddress not supported"
        );

        require(
            payload.fromAssetAddress == fromAssetAddress,
            "MagpieCore: invalid fromAssetAddress"
        );
        require(
            payload.toAssetAddress == toAssetAddress,
            "MagpieCore: invalid toAssetAddress"
        );
        require(
            payload.to == swapArgs.to && payload.to != address(this),
            "MagpieCore: invalid to"
        );
        require(
            payload.recipientCoreAddress == address(this),
            "MagpieCore: invalid recipientCoreAddress"
        );
        require(
            uint256(payload.recipientNetworkId) == config.networkId,
            "MagpieCore: invalid recipientChainId"
        );
        require(
            swapArgs.amountOutMin >= payload.amountOutMin,
            "MagpieCore: invalid amountOutMin"
        );
        require(
            swapArgs.routes[0].amountIn >
                payload.destGasTokenAmount + payload.swapOutGasFee,
            "MagpieCore: invalid amountIn"
        );

        swapArgs.routes[0].amountIn =
            swapArgs.routes[0].amountIn -
            (payload.destGasTokenAmount + payload.swapOutGasFee);

        WrapSwapConfig memory wrapSwapConfig = _getWrapSwapConfig(
            swapArgs,
            false
        );

        amountOuts = _wrapSwap(swapArgs, wrapSwapConfig);

        if (payload.swapOutGasFee > 0) {
            gasFeeAccumulatedByToken[fromAssetAddress] += payload.swapOutGasFee;
            gasFeeAccumulated[fromAssetAddress][msg.sender] += payload
                .swapOutGasFee;
        }

        if (payload.destGasTokenAmount > 0) {
            require(
                args.gasTokenSwapArgs.getAmountIn() ==
                    payload.destGasTokenAmount,
                "MagpieCore: invalid amountIn"
            );
            require(
                args.gasTokenSwapArgs.getFromAssetAddress() ==
                    payload.fromAssetAddress,
                "MagpieCore: invalid fromAssetAddress"
            );
            require(
                args.gasTokenSwapArgs.getToAssetAddress().isNative(),
                "MagpieCore: invalid toAssetAddress"
            );
            require(
                args.gasTokenSwapArgs.to == payable(payload.to),
                "MagpieCore: invalid to"
            );
            require(
                args.gasTokenSwapArgs.amountOutMin >=
                    payload.destGasTokenAmountOutMin,
                "MagpieCore: invalid amountOutMin"
            );
            WrapSwapConfig memory gasWrapSwapConfig = _getWrapSwapConfig(
                args.gasTokenSwapArgs,
                false
            );
            uint256[] memory destGasTokenAmountOuts = _wrapSwap(
                args.gasTokenSwapArgs,
                gasWrapSwapConfig
            );

            require(
                destGasTokenAmountOuts.sum() > 0,
                "MagpieCore: invalid destGasTokenAmountOuts"
            );
        }

        emit SwappedOut(
            args,
            amountOuts,
            payload.senderNetworkId,
            coreSequence,
            msg.sender
        );
    }

    function withdrawGasFee(address tokenAddress)
        external
        whenNotPaused
        nonReentrant
    {
        uint256 _gasFeeAccumulated = gasFeeAccumulated[tokenAddress][
            msg.sender
        ];
        require(_gasFeeAccumulated != 0, "MagpieCore: gas fee earned is 0");
        gasFeeAccumulatedByToken[tokenAddress] =
            gasFeeAccumulatedByToken[tokenAddress] -
            _gasFeeAccumulated;
        gasFeeAccumulated[tokenAddress][msg.sender] = 0;
        tokenAddress.transfer(payable(msg.sender), _gasFeeAccumulated);

        emit GasFeeWithdraw(tokenAddress, msg.sender, _gasFeeAccumulated);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}