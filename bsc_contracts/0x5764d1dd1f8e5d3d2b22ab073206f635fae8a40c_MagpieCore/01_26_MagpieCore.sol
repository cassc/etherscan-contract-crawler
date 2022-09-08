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
import "./interfaces/IStargateReceiver.sol";

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

    event DepositReceived(
        uint8 networkId,
        bytes32 senderAddress,
        uint64 coreSequence,
        uint256 amount
    );

    mapping(address => uint256) public gasFeeAccumulatedByToken;
    mapping(address => mapping(address => uint256)) public gasFeeAccumulated;
    mapping(uint8 => mapping(uint64 => bool)) public sequences;
    mapping(uint8 => mapping(bytes32 => mapping(uint64 => uint256)))
        public deposits;
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

    modifier onlyStargate() {
        require(
            msg.sender == config.stargateAddress,
            "MagpieCore: only stargate allowed"
        );
        _;
    }

    function updateConfig(Config calldata _config) external override onlyOwner {
        require(_config.weth != address(0), "MagpieCore: invalid weth");
        require(
            _config.stargateAddress != address(0),
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
            require(msg.value >= amountIn, "MagpieCore: asset not received");
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
            swapArgs.getToAssetAddress().transfer(
                payable(config.magpieRouterAddress),
                amountOut
            );
            IMagpieRouter(config.magpieRouterAddress).withdraw(
                config.weth,
                amountOut
            );
        }

        if (to != address(this) && amountOut > 0) {
            toAssetAddress.transfer(to, amountOut);
        }
    }

    receive() external payable {
        require(
            config.magpieRouterAddress == msg.sender,
            "MagpieCore: invalid sender"
        );
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

        WrapSwapConfig memory wrapSwapConfig = _getWrapSwapConfig(
            args.swapArgs,
            true
        );
        amountOuts = _wrapSwap(args.swapArgs, wrapSwapConfig);

        uint256 amountOut = amountOuts.sum();

        toAssetAddress.transfer(payable(config.magpieBridgeAddress), amountOut);

        uint256 bridgeFee = 0;

        if (msg.value > 0 && msg.value != args.swapArgs.getAmountIn()) {
            bridgeFee = msg.value;
            if (args.swapArgs.getFromAssetAddress().isNative()) {
                bridgeFee = msg.value > args.swapArgs.getAmountIn()
                    ? msg.value - args.swapArgs.getAmountIn()
                    : 0;
            }
        }

        (depositAmount, coreSequence, tokenSequence) = IMagpieBridge(
            config.magpieBridgeAddress
        ).bridgeIn{value: bridgeFee}(
            args.bridgeType,
            args.payload,
            amountOut,
            toAssetAddress,
            msg.sender
        );

        emit SwappedIn(
            args,
            amountOuts,
            depositAmount,
            args.payload.recipientNetworkId,
            coreSequence,
            tokenSequence,
            config.magpieBridgeAddress,
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
                args.bridgeArgs.encodedVmCore
            );

        require(
            !sequences[payload.senderNetworkId][coreSequence],
            "MagpieCore: already used sequence"
        );

        sequences[payload.senderNetworkId][coreSequence] = true;

        IMagpieRouter.SwapArgs memory swapArgs = args.swapArgs;

        uint256 depositAmount = deposits[payload.senderNetworkId][
            payload.senderAddress
        ][coreSequence];

        uint256 amountIn = depositAmount > 0
            ? depositAmount
            : IMagpieBridge(config.magpieBridgeAddress).bridgeOut(
                payload,
                args.bridgeArgs,
                payload.tokenSequence,
                args.swapArgs.getFromAssetAddress()
            );

        if (amountIn == 0) {
            amountIn = deposits[payload.senderNetworkId][
               payload.senderAddress
            ][coreSequence];
        }

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
            payload.fromAssetAddress == fromAssetAddress,
            "MagpieCore: invalid fromAssetAddress"
        );
        if (msg.sender != payload.to) {
            require(
                payload.toAssetAddress == toAssetAddress,
                "MagpieCore: invalid toAssetAddress"
            );
        }
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
            swapArgs.routes[0].amountIn > payload.swapOutGasFee,
            "MagpieCore: invalid amountIn"
        );

        swapArgs.routes[0].amountIn =
            swapArgs.routes[0].amountIn -
            payload.swapOutGasFee;

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

    function sgReceive(
        uint16 senderChainId,
        bytes memory stargateBridgeAddress,
        uint256 nonce,
        address assetAddress,
        uint256 amount,
        bytes memory payload
    ) external onlyStargate {
        (uint8 networkId, bytes32 senderAddress, uint64 coreSequence) = payload
            .parseSgPayload();
        deposits[networkId][senderAddress][coreSequence] = amount;
        emit DepositReceived(networkId, senderAddress, coreSequence, amount);
    }
}