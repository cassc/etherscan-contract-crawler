// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../utils/Pausable.sol";

import "../utils/ExchangePoolProcessor.sol";
import "../utils/LenientReentrancyGuard.sol";
import "./ITreasuryHandler.sol";

/**
 * @title Treasury handler alpha contract
 * @dev Sells tokens that have accumulated through taxes and sends the resulting BUSD to the treasury. If
 * `taxBasisPoints` has been set to a non-zero value, then that percentage will instead be collected at the designated
 * treasury address.
 */
contract TreasuryHandlerAlpha is
    Initializable,
    OwnableUpgradeable,
    Pausable,
    ITreasuryHandler,
    LenientReentrancyGuard,
    ExchangePoolProcessor
{
    using AddressUpgradeable for address payable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /// @notice The treasury address.
    address public treasury;

    /// @notice The BUSD token address.
    IERC20Upgradeable public busdToken;
    /// @notice The token that accumulates through taxes. This will be sold for BUSD.
    IERC20Upgradeable public token;

    /// @notice The Uniswap router that handles the sell and liquidity operations.
    IUniswapV2Router02 public router;

    /// @notice Emitted when the treasury address is updated.
    event TreasuryAddressUpdated(
        address oldTreasuryAddress,
        address newTreasuryAddress
    );

    /// @notice Emitted when the busd address is updated.
    event BUSDAddressUpdated(address oldBUSDAddress, address newBUSDAddress);

    /// @notice Emitted when the token address is updated.
    event TokenAddressUpdated(address oldTokenAddress, address newTokenAddress);

    /// @notice Emitted when the router address is updated.
    event RouterAddressUpdated(
        address oldRouterAddress,
        address newRouterAddress
    );

    /**
     * @param treasuryAddress Address of treasury to use.
     * @param busdTokenAddress Address of busd token.
     * @param tokenAddress Address of token to accumulate and sell.
     * @param routerAddress Address of Uniswap router for sell and liquidity operations.
     */
    function initialize(
        address treasuryAddress,
        address busdTokenAddress,
        address tokenAddress,
        address routerAddress
    ) public initializer {
        __Ownable_init();
        __PausableUpgradeable_init();
        __LenientReentrancyGuard_init();
        treasury = treasuryAddress;
        busdToken = IERC20Upgradeable(busdTokenAddress);
        token = IERC20Upgradeable(tokenAddress);
        router = IUniswapV2Router02(routerAddress);
    }

    /**
     * @notice Perform operations before a buy or sell action is executed. The accumulated tokens are
     * then sold for BUSD and sent to the treasury.
     * @param benefactor Address of the benefactor.
     * @param beneficiary Address of the beneficiary.
     * @param amount Number of tokens in the transfer.
     */
    function beforeTransferHandler(
        address benefactor,
        address beneficiary,
        uint256 amount
    ) external override nonReentrant whenNotPaused {
        // Silence a few warnings. This will be optimized out by the compiler.
        benefactor;
        amount;

        // No actions are done on transfers other than buy or sells.
        if (
            !_exchangePools.contains(benefactor) &&
            !_exchangePools.contains(beneficiary)
        ) {
            return;
        }

        uint256 contractTokenBalance = token.balanceOf(address(this));
        if (contractTokenBalance > 0) {
            uint256 currentBUSDBalance = busdToken.balanceOf(address(this));
            _swapTokensForBUSD(amount);
            uint256 busdEarned = busdToken.balanceOf(address(this)) -
                currentBUSDBalance;
            busdToken.transfer(address(treasury), busdEarned);

            // It's cheaper to get the active balance rather than calculating based off of the `currentBUSDBalance`
            uint256 remainingBUSDBalance = busdToken.balanceOf(address(this));
            if (remainingBUSDBalance > 0) {
                busdToken.transfer(msg.sender, remainingBUSDBalance);
            }
        }
    }

    /**
     * @notice Perform post-transfer operations. This contract ignores those operations, hence nothing happens.
     * @param benefactor Address of the benefactor.
     * @param beneficiary Address of the beneficiary.
     * @param amount Number of tokens in the transfer.
     */
    function afterTransferHandler(
        address benefactor,
        address beneficiary,
        uint256 amount
    ) external override nonReentrant {
        // Silence a few warnings. This will be optimized out by the compiler.
        benefactor;
        beneficiary;
        amount;

        return;
    }

    /**
     * @notice Set new treasury address.
     * @param _newTreasuryAddress New treasury address.
     */
    function setTreasury(address _newTreasuryAddress) external onlyOwner {
        require(
            _newTreasuryAddress != address(0),
            "TreasuryHandlerAlpha:setTreasury:ZERO_TREASURY: Cannot set zero address as treasury."
        );

        address oldTreasuryAddress = address(treasury);
        treasury = payable(_newTreasuryAddress);

        emit TreasuryAddressUpdated(oldTreasuryAddress, _newTreasuryAddress);
    }

    /**
     * @notice Set new BUSD address.
     * @param _newBUSDAddress New BUSD address.
     */
    function updateBUSDAddress(address _newBUSDAddress) external onlyOwner {
        require(
            _newBUSDAddress != address(0),
            "TreasuryHandlerAlpha:updateBUSDAddress:ZERO_BUSD: Cannot set zero address as BUSD."
        );

        address oldBUSDAddress = address(busdToken);
        busdToken = IERC20Upgradeable(_newBUSDAddress);

        emit BUSDAddressUpdated(oldBUSDAddress, _newBUSDAddress);
    }

    /**
     * @notice Set new Token address.
     * @param _newTokenAddress New Token address.
     */
    function updateTokenAddress(address _newTokenAddress) external onlyOwner {
        require(
            _newTokenAddress != address(0),
            "TreasuryHandlerAlpha:updateTokenAddress:ZERO_TOKEN: Cannot set zero address as Token."
        );

        address oldTokenAddress = address(token);
        token = IERC20Upgradeable(_newTokenAddress);

        emit TokenAddressUpdated(oldTokenAddress, _newTokenAddress);
    }

    /**
     * @notice Set new Router address.
     * @param _newRouterAddress New Router address.
     */
    function updateRouterAddress(address _newRouterAddress) external onlyOwner {
        require(
            _newRouterAddress != address(0),
            "TreasuryHandlerAlpha:updateRouterAddress:ZERO_ROUTER: Cannot set zero address as Router."
        );

        address oldRouterAddress = address(router);
        router = IUniswapV2Router02(_newRouterAddress);

        emit RouterAddressUpdated(oldRouterAddress, _newRouterAddress);
    }

    /**
     * @notice Withdraw any tokens or BUSD stuck in the treasury handler.
     * @param tokenAddress Address of the token to withdraw. If set to the zero address, BUSD will be withdrawn.
     * @param amount The number of tokens to withdraw.
     */
    function withdraw(address tokenAddress, uint256 amount) external onlyOwner {
        require(
            tokenAddress != address(token),
            "TreasuryHandlerAlpha:withdraw:INVALID_TOKEN: Not allowed to withdraw token required for swaps."
        );

        if (tokenAddress == address(0)) {
            busdToken.transfer(msg.sender, amount);
        } else {
            IERC20Upgradeable(tokenAddress).transferFrom(
                address(this),
                address(treasury),
                amount
            );
        }
    }

    /**
     * @dev Swap accumulated tokens for BUSD.
     * @param tokenAmount Number of tokens to swap for BUSD.
     */
    function _swapTokensForBUSD(uint256 tokenAmount) private {
        // The BUSD/token pool is the primary pool. It always exists.
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(busdToken);

        // Ensure the router can perform the swap for the designated number of tokens.
        token.approve(address(router), tokenAmount);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    /**
     * @notice Allow contract to accept BUSD.
     */
    receive() external payable {}
}