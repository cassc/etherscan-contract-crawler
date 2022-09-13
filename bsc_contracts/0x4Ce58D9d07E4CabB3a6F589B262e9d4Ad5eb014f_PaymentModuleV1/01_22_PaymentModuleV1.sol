// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";

import "../interfaces/IDepositHandler.sol";
import "../interfaces/ILPTokenProcessor.sol";
import "../interfaces/IPaymentModule.sol";
import "../interfaces/IPricingModule.sol";

contract PaymentModuleV1 is IDepositHandler, IPaymentModule, AccessControlEnumerable {
    using SafeERC20 for IERC20;

    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    address public immutable FLOKI;

    ILPTokenProcessor public lpTokenProcessor;
    IPricingModule public pricingModule;
    IUniswapV2Router01 public routerForFloki;
    address public treasury;
    IERC20 public USDT;

    uint256 public referrerBasisPoints = 2500;
    uint256 public burnBasisPoints = 2500;

    event LPTokenProcessorUpdated(address indexed oldProcessor, address indexed newProcessor);
    event PricingModuleUpdated(address indexed oldModule, address indexed newModule);
    event TreasuryAddressUpdated(address indexed oldTreasury, address indexed newTreasury);

    constructor(
        address flokiAddress,
        address lpTokenProcessorAddress,
        address pricingModuleAddress,
        address treasuryAddress,
        address uniswapV2RouterAddress,
        address usdtAddress
    ) {
        require(
            pricingModuleAddress != address(0),
            "PaymentModuleV1::constructor::ZERO: Pricing module cannot be zero address."
        );
        require(
            uniswapV2RouterAddress != address(0),
            "PaymentModuleV1::constructor::ZERO: Router cannot be zero address."
        );
        require(usdtAddress != address(0), "PaymentModuleV1::constructor::ZERO: USDT cannot be zero address.");

        FLOKI = flokiAddress;
        pricingModule = IPricingModule(pricingModuleAddress);
        lpTokenProcessor = ILPTokenProcessor(lpTokenProcessorAddress);
        routerForFloki = IUniswapV2Router01(uniswapV2RouterAddress);
        treasury = treasuryAddress;
        USDT = IERC20(usdtAddress);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function processPayment(
        address vault,
        address user,
        address referrer,
        FungibleTokenDeposit[] memory fungibleTokenDeposits,
        NonFungibleTokenDeposit[] memory nonFungibleTokenDeposits,
        MultiTokenDeposit[] memory multiTokenDeposits,
        bool isVesting
    ) external override {
        // Store initial USDT balance to check difference against.
        uint256 initialUSDTBalance = USDT.balanceOf(address(this));

        (address[] memory lpTokens, uint256[] memory lpAmounts, uint256 usdtAmount) = pricingModule.getPrice(
            vault,
            user,
            referrer,
            fungibleTokenDeposits,
            nonFungibleTokenDeposits,
            multiTokenDeposits,
            isVesting
        );

        // Process token payments first.
        for (uint256 i = 0; i < fungibleTokenDeposits.length; i++) {
            // First transfer the full sum of the tokens to the payment processor.
            IERC20(fungibleTokenDeposits[i].tokenAddress).safeTransferFrom(
                user,
                address(this),
                fungibleTokenDeposits[i].amount
            );
            // Then transfer tokens that are to be locked to the vault (lpTokens[i] is zero for non-LP tokens).
            IERC20(fungibleTokenDeposits[i].tokenAddress).safeTransfer(
                vault,
                fungibleTokenDeposits[i].amount - lpAmounts[i]
            );
            if (fungibleTokenDeposits[i].tokenAddress == lpTokens[i]) {
                // In case of no referrer the LP share is zero. Setting it
                // at this level allows for easier subtraction later on.
                uint256 referrerLPShare = 0;
                if (referrer != address(0)) {
                    referrerLPShare = (lpAmounts[i] * referrerBasisPoints) / 10000;

                    _liquidateAndTransferReferrerTokens(
                        fungibleTokenDeposits[i].tokenAddress,
                        referrerLPShare,
                        referrer
                    );
                }

                // Any remaining LP tokens are sent to the Keepers-powered (or backend job powered)
                // LP token processor.
                lpTokenProcessor.addLiquidityPoolToken(fungibleTokenDeposits[i].tokenAddress);
                IERC20(fungibleTokenDeposits[i].tokenAddress).safeTransfer(
                    address(lpTokenProcessor),
                    // It's important to know that these subtractions never
                    // cause an underflow. The number in `lpAmounts[i]` is
                    // non-zero after the transfer to the vault. Afterwards
                    // a portion of `lpAmounts[i]` may be used to pay out
                    // referral fees. The remainder is guaranteed to be
                    // non-zero, because `referrerLPShare` is a fraction of
                    // `lpAmounts[i]`.
                    lpAmounts[i] - referrerLPShare
                );
            }
        }

        // Process NFT
        for (uint256 i = 0; i < nonFungibleTokenDeposits.length; i++) {
            IERC721(nonFungibleTokenDeposits[i].tokenAddress).safeTransferFrom(
                user,
                vault,
                nonFungibleTokenDeposits[i].tokenId
            );
        }

        // Process Multi Token
        for (uint256 i = 0; i < multiTokenDeposits.length; i++) {
            IERC1155(multiTokenDeposits[i].tokenAddress).safeTransferFrom(
                user,
                vault,
                multiTokenDeposits[i].tokenId,
                multiTokenDeposits[i].amount,
                ""
            );
        }

        // Process USDT payment in case it's needed.
        processFee(usdtAmount, user, referrer, initialUSDTBalance);
    }

    function processFee(
        uint256 usdtAmount,
        address user,
        address referrer,
        uint256 initialUSDTBalance
    ) internal {
        if (usdtAmount > 0) {
            USDT.safeTransferFrom(user, address(this), usdtAmount);

            uint256 USDTGained = USDT.balanceOf(address(this)) - initialUSDTBalance;
            uint256 referrerUSDTShare = 0;
            if (referrer != address(0)) {
                referrerUSDTShare = (USDTGained * referrerBasisPoints) / 10000;

                USDT.safeTransfer(referrer, referrerUSDTShare);
            }

            uint256 burnShare = 0;
            if (FLOKI != address(0)) {
                burnShare = (USDTGained * burnBasisPoints) / 10000;

                _swapTokens(
                    address(USDT),
                    burnShare,
                    FLOKI,
                    burnAddress,
                    payable(address(this)).balance,
                    address(routerForFloki)
                );
            }

            USDT.safeTransfer(treasury, USDTGained - referrerUSDTShare - burnShare);
        }
    }

    function setLPTokenProcessor(address newProcessor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldProcessor = address(lpTokenProcessor);
        lpTokenProcessor = ILPTokenProcessor(newProcessor);

        emit LPTokenProcessorUpdated(oldProcessor, newProcessor);
    }

    function setPricingModule(address newModule) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldModule = address(pricingModule);
        pricingModule = IPricingModule(newModule);

        emit PricingModuleUpdated(oldModule, newModule);
    }

    function setTreasury(address newTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldTreasury = treasury;
        treasury = newTreasury;

        emit TreasuryAddressUpdated(oldTreasury, newTreasury);
    }

    function _liquidateAndTransferReferrerTokens(
        address lpTokenAddress,
        uint256 lpTokenAmount,
        address referrer
    ) private {
        address routerAddress = lpTokenProcessor.getRouter(lpTokenAddress);
        require(
            routerAddress != address(0),
            "PaymentModuleV1::_liquidateAndTransferReferrerTokens::ZERO: There is no router to handle this LP Token."
        );
        IUniswapV2Router01 router = IUniswapV2Router01(routerAddress);
        address WETHAddress = router.WETH();
        IUniswapV2Pair lpToken = IUniswapV2Pair(lpTokenAddress);
        lpToken.approve(routerAddress, lpTokenAmount);

        IERC20 token0 = IERC20(lpToken.token0());
        IERC20 token1 = IERC20(lpToken.token1());

        if (lpToken.token0() == WETHAddress) {
            router.removeLiquidityETH(lpToken.token1(), lpTokenAmount, 0, 0, address(this), block.timestamp);

            _swapTokens(
                lpToken.token1(),
                token1.balanceOf(address(this)),
                address(USDT),
                referrer,
                payable(address(this)).balance,
                routerAddress
            );
        } else if (lpToken.token1() == WETHAddress) {
            router.removeLiquidityETH(lpToken.token0(), lpTokenAmount, 0, 0, address(this), block.timestamp);

            _swapTokens(
                lpToken.token0(),
                token0.balanceOf(address(this)),
                address(USDT),
                referrer,
                payable(address(this)).balance,
                routerAddress
            );
        } else {
            router.removeLiquidity(
                lpToken.token0(),
                lpToken.token1(),
                lpTokenAmount,
                0,
                0,
                address(this),
                block.timestamp
            );

            _swapTokens(
                lpToken.token0(),
                token0.balanceOf(address(this)),
                address(USDT),
                referrer,
                payable(address(this)).balance,
                routerAddress
            );
            _swapTokens(
                lpToken.token1(),
                token1.balanceOf(address(this)),
                address(USDT),
                referrer,
                payable(address(this)).balance,
                routerAddress
            );
        }
    }

    function _swapTokens(
        address sourceToken,
        uint256 sourceAmount,
        address destinationToken,
        address receiver,
        uint256 initialETHBalance,
        address routerAddress
    ) private returns (bool) {
        IUniswapV2Router01 router = IUniswapV2Router01(routerAddress);
        IERC20 token = IERC20(sourceToken);

        address[] memory path = new address[](2);
        path[0] = sourceToken;
        path[1] = router.WETH();

        token.safeApprove(address(router), sourceAmount);

        try router.swapExactTokensForETH(sourceAmount, 0, path, address(this), block.timestamp) returns (
            uint256[] memory /* amounts */
        ) {} catch (
            bytes memory /* lowLevelData */
        ) {
            return false;
        }

        uint256 ETHGained = payable(address(this)).balance - initialETHBalance;

        // Update path values to swap from ETH to USDT.
        path[0] = path[1];
        path[1] = destinationToken;

        try router.swapExactETHForTokens{ value: ETHGained }(0, path, receiver, block.timestamp) returns (
            uint256[] memory /* amounts */
        ) {} catch (
            bytes memory /* lowLevelData */
        ) {
            return false;
        }

        return true;
    }

    receive() external payable {}
}