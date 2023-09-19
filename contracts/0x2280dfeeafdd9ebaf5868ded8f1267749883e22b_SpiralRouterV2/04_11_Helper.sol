pragma solidity 0.8.16;

import {IStaking} from "../interfaces/IStaking.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IVirtualRebaseViewer} from "../Token/VirtualRebaseViewer.sol";

interface IBalancerVault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    function getPool(bytes32 poolId) external view returns (address, bytes memory);
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (address[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);

    function swap(SingleSwap memory singleSwap, FundManagement memory funds, uint256 limit, uint256 deadline)
        external
        payable
        returns (uint256);
}

interface IBalancerPool {
    function getNormalizedWeights() external view returns (uint256[] memory);
    function getSwapFeePercentage() external view returns (uint256);
}

interface ICurveZap {
    function get_dy(address, uint256, uint256, uint256) external view returns (uint256);
    function exchange(address, uint256, uint256, uint256, uint256) external payable returns (uint256);
}

interface ICurvePool {
    function get_dy(uint256, uint256, uint256) external view returns (uint256);
    function coins(uint256) external view returns (address);
}

interface IMaverickPool {
    function swap(
        address recipient,
        uint256 amount,
        bool tokenAIn,
        bool exactOutput,
        uint256 sqrtPriceLimit,
        bytes calldata data
    ) external returns (uint256 amountIn, uint256 amountOut);

    struct SwapCallbackData {
        bytes path;
        address payer;
        bool exactOutput;
    }
}

interface IMaverickFactory {
    function isFactoryPool(address) external view returns (bool);
}

library RouterConstants {
    IERC20 internal constant usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 internal constant coil = IERC20(0x823E1B82cE1Dc147Bbdb25a203f046aFab1CE918);
    IERC20 internal constant spiral = IERC20(0x85b6ACaBa696B9E4247175274F8263F99b4B9180);
    IStaking internal constant staking = IStaking(0x6701E792b7CD344BaE763F27099eEb314A4b4943);
    ICurveZap internal constant curveZap = ICurveZap(0x5De4EF4879F4fe3bBADF2227D2aC5d0E2D76C895);
    address internal constant curvePool = 0xAF4264916B467e2c9C8aCF07Acc22b9EDdDaDF33;

    IBalancerVault internal constant balVault = IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    IBalancerPool internal constant balancerPool = IBalancerPool(0x42FBD9F666AaCC0026ca1B88C94259519e03dd67);
    bytes32 internal constant balancerPoolId = 0x42fbd9f666aacc0026ca1b88c94259519e03dd67000200000000000000000507;

    IVirtualRebaseViewer internal constant virtualRebaseViewer =
        IVirtualRebaseViewer(0xab1789b0A1830d897F55e7aDAE87612264271309);
    IMaverickPool internal constant maverickPool = IMaverickPool(0xF04984FDc904F310D3ca0B7B105453E14129CDa2);
    IMaverickFactory internal constant maverickFactory = IMaverickFactory(0xEb6625D65a0553c9dBc64449e56abFe519bd9c9B);
}