// SPDX-License-Identifier: UNLICENSED
//
//           ████████████████████
//         ██                    ██
//       ██    ██          ██      ██
//     ██      ████        ████      ██
//     ██            ████            ██
//     ██                            ██
//   ████████████████████████████████████
//   ██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██
//     ████████████████████████████████
//   ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██
//     ██░░██░░░░██████░░░░░░██░░░░████
//     ████  ████      ██████  ████  ██
//     ██                            ██
//       ████████████████████████████
//
// The CheezburgerFactory are a set of immutable and non-upgradeable smart contracts that enables
// easy deployment of new tokens with automated liquidity provisioning against either native ETH
// or ERC20 token specified with any Uniswap V2 compatible routers.
//
// By supporting both ETH and ERC20 tokens as liquidity, the Factory provides flexibility for
// projects to launch with the assets they have available. Automating the entire process
// dramatically lowers the barrier to creating a new token with smart tokenomics, built-in
// liquidity management and DEX listing in a completely trustless and decentralized way.
//
// Read more on Cheezburger: https://chz.lol
//
pragma solidity ^0.8.21;

import "solady/src/tokens/ERC20.sol";
import "solady/src/auth/Ownable.sol";
import "solady/src/utils/SafeTransferLib.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./utils/ReentrancyGuard.sol";
import "./CheezburgerBun.sol";
import "./CheezburgerSanitizer.sol";

contract CheezburgerFactory is ReentrancyGuard, Ownable, CheezburgerSanitizer {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error InsufficientLiquidityWei(uint256 amount);
    error ExistingTokenAsRightSide(address token);
    error InvalidRouter(address router);
    error CannotReceiveEtherDirectly();
    error PairNotEmpty();
    error FactoryNotOpened();
    error InvalidLiquidityPoolFee(uint8 newFee);
    error CannotSetZeroAsRightSide();
    error InvalidPair(
        address tokenA,
        address tokenB,
        address leftSide,
        address rightSide
    );

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCT                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Settings and contracts for a token pair and its liquidity pool.
    struct Token {
        /// @dev The Uniswap factory contract
        IUniswapV2Factory factory;
        /// @dev The Uniswap router contract
        IUniswapV2Router02 router;
        /// @dev The Uniswap pair contract
        IUniswapV2Pair pair;
        /// @dev The token creator
        address creator;
        /// @dev The left side of the pair
        CheezburgerBun leftSide;
        /// @dev The right side ERC20 token of the pair
        ERC20 rightSide;
        /// @dev Liquidity settings
        LiquiditySettings liquidity;
        /// @dev Dynamic fee settings
        DynamicSettings fee;
        /// @dev Dynamic wallet settings
        DynamicSettings wallet;
        /// @dev Referral settings
        ReferralSettings referral;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event TokenDeployed(Token token);
    event CommissionsTaken(uint256 factoryFee, uint256 referralFee);
    event SwapAndLiquify(
        address tokenLeft,
        address tokenRight,
        uint256 half,
        uint256 initialBalance,
        uint256 newRightBalance
    );

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    bool public factoryOpen = false;
    uint8 public factoryLiquidityFee = 4;
    uint256 public totalTokens = 0;
    mapping(address => Token) public burgerRegistry;

    constructor() {
        _initializeOwner(msg.sender);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC UPDATE FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys a new token and adds liquidity with native coin
    /// @param _customization Token details (TokenCustomization)
    /// @param _router Uniswap router address
    /// @param _rightSide Address of token to provide liquidity with
    /// @param _liquidity Liquidity provision settings
    /// @param _fee Early Access Premium / Sell rate settings
    /// @param _wallet Max wallet holding settings
    /// @param _referral Referral settings
    /// @return The address of the deployed token contract
    function deployWithNative(
        TokenCustomization memory _customization,
        address _router,
        // If someone wants to specify a custom WETH() that is not returned by the router
        address _rightSide,
        LiquiditySettings memory _liquidity,
        DynamicSettings memory _fee,
        DynamicSettings memory _wallet,
        ReferralSettings memory _referral
    ) external payable nonReentrant returns (address) {
        Token memory token = deploy(
            _customization,
            _router,
            _liquidity,
            _fee,
            _wallet,
            _referral,
            _rightSide
        );

        // Check at least 10,000 wei are provided for liquidity
        if (msg.value <= 10000 wei) {
            revert InsufficientLiquidityWei(msg.value);
        }

        // Add liquidity
        addLiquidityETH(
            token,
            SafeTransferLib.balanceOf(address(token.leftSide), address(this)),
            msg.value,
            token.creator
        );

        return address(token.leftSide);
    }

    /// @dev Deploys a new token and adds liquidity using a token as right side
    /// @param _customization Token details (TokenCustomization)
    /// @param _router Uniswap router address
    /// @param _rightSide Address of token to provide liquidity with
    /// @param _rightSideAmount Amount of that token for liquidity
    /// @param _liquidity Liquidity provision settings
    /// @param _fee Early Access Premium / Sell fee rate settings
    /// @param _wallet Max wallet holding settings
    /// @param _referral Referral settings
    /// @return The address of the deployed token contract
    function deployWithToken(
        TokenCustomization memory _customization,
        address _router,
        address _rightSide,
        uint256 _rightSideAmount,
        LiquiditySettings memory _liquidity,
        DynamicSettings memory _fee,
        DynamicSettings memory _wallet,
        ReferralSettings memory _referral
    ) external nonReentrant returns (address) {
        Token memory token = deploy(
            _customization,
            _router,
            _liquidity,
            _fee,
            _wallet,
            _referral,
            _rightSide
        );

        // Transfer tokens for liquidity add
        SafeTransferLib.safeTransferFrom(
            address(token.rightSide),
            token.creator,
            address(this),
            _rightSideAmount
        );

        // Add liquidity
        addLiquidityToken(
            token,
            SafeTransferLib.balanceOf(address(token.leftSide), address(this)),
            _rightSideAmount,
            token.creator
        );

        return address(token.leftSide);
    }

    /// Checks for & executes automated liquidity swap if threshold met.
    ///
    /// @param _sender The address that initiated the token transfer
    ///
    /// @return True if check passed
    ///
    /// Verifies transfer didn't come from the router. Gets threshold
    /// and checks if left token balance exceeds it. If so, swaps tokens/adds
    /// liquidity, then distributes LP tokens to fee addresses as percentages
    /// configured in token settings.
    ///
    /// This dynamic threshold approach aims to reduce swap size and price
    /// impact as the pool and price grow over time. Automates ongoing
    /// liquidity additions from transaction volume.
    function afterTokenTransfer(
        address _sender,
        uint256 _leftSideBalance
    ) external returns (bool) {
        Token memory token = burgerRegistry[msg.sender];
        ensurePairValid(token);
        uint256 threshold = _getLiquidityThreshold(token);

        if (_leftSideBalance >= threshold) {
            (
                uint256 addedLP,
                uint256 factoryFeeLP,
                uint256 referralFeeLP
            ) = swapAndLiquify(token, threshold);
            uint256 feeAddressesLength = token.liquidity.feeAddresses.length;

            // Send a portion of the fee to the Factory owner
            if (factoryFeeLP > 0) {
                SafeTransferLib.safeTransfer(
                    address(token.pair),
                    owner(),
                    factoryFeeLP
                );
            }

            if (referralFeeLP > 0) {
                SafeTransferLib.safeTransfer(
                    address(token.pair),
                    token.referral.feeReceiver,
                    referralFeeLP
                );
            }

            // Send LP to designated LP wallets
            unchecked {
                uint8 i;
                while (i < feeAddressesLength) {
                    if (i == feeAddressesLength - 1) {
                        SafeTransferLib.safeTransferAll(
                            address(token.pair),
                            token.liquidity.feeAddresses[i]
                        );
                    } else {
                        uint256 feeAmount = (addedLP *
                            token.liquidity.feePercentages[i]) / 100;
                        SafeTransferLib.safeTransfer(
                            address(token.pair),
                            token.liquidity.feeAddresses[i],
                            feeAmount
                        );
                    }
                    ++i;
                }
            }

            // Send any rightSide dust to the last address
            uint256 rightSideBalance = SafeTransferLib.balanceOf(
                address(token.rightSide),
                address(this)
            );
            if (rightSideBalance > 0) {
                SafeTransferLib.safeTransfer(
                    address(token.rightSide),
                    token.liquidity.feeAddresses[feeAddressesLength - 1],
                    rightSideBalance
                );
            }
        }

        return true;
    }

    /// @dev Allows owner to update the liquidity fee percentage
    /// @param _factoryLiquidityFee New fee percentage, must be 0-4%
    function setLiquidityPoolFee(
        uint8 _factoryLiquidityFee
    ) external onlyOwner {
        // Validate that the new fee is in range
        if (_factoryLiquidityFee > CheezburgerConstants.MAX_LP_FEE) {
            revert InvalidLiquidityPoolFee(_factoryLiquidityFee);
        }

        // Update deploy fee
        factoryLiquidityFee = _factoryLiquidityFee;
    }

    /// @dev Function to open the factory
    function openFactory() external onlyOwner {
        factoryOpen = true;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   PUBLIC READ FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Allows the token to get his pair address
    /// @return _pair The address of the pair
    function selfPair() external view returns (IUniswapV2Pair) {
        Token memory token = burgerRegistry[msg.sender];
        return token.pair;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// Limitations:
    ///
    /// EAP duration: 1 to 24 hours
    /// EAP start: 1% to 40%
    /// EAP end: 0% to 5%
    ///
    /// Wallet duration: 1 day to 4 weeks
    /// Wallet start: >= 1%
    /// Wallet end: 2% to 49%
    ///
    /// @param _customization Token details (TokenCustomization)
    /// @param _router Uniswap router address
    /// @param _liquidity Liquidity settings
    /// @param _fee Fees (Early Access Premium / Sell) settings
    /// @param _wallet Max wallet settings
    /// @param _referral Referral settings
    /// @param _rightSide Address of token to provide liquidity with
    /// @return Token instance
    function deploy(
        TokenCustomization memory _customization,
        address _router,
        LiquiditySettings memory _liquidity,
        DynamicSettings memory _fee,
        DynamicSettings memory _wallet,
        ReferralSettings memory _referral,
        address _rightSide
    ) private returns (Token memory) {
        validateTokenSettings(_router, _customization);
        validateWalletSettings(_wallet);
        validateFeeSettings(_fee);
        validateLiquiditySettings(_liquidity, address(this));
        validateReferralSettings(_referral, address(this));

        Token memory token;
        token.creator = msg.sender;

        // Ensure factory is either opened or the owner is the caller
        if (!factoryOpen && token.creator != owner()) {
            revert FactoryNotOpened();
        }

        // Setup router and factory
        (IUniswapV2Router02 router, IUniswapV2Factory factory) = getRouter(
            _router
        );
        if (address(factory) == address(0) || address(router) == address(0)) {
            revert InvalidRouter(_router);
        }
        token.factory = factory;
        token.router = router;

        // Right side token (WETH, USDC...)
        token.rightSide = ERC20(_rightSide);
        if (address(token.rightSide) == address(0)) {
            token.rightSide = ERC20(token.router.WETH());
            if (address(token.rightSide) == address(0)) {
                revert CannotSetZeroAsRightSide();
            }
        }
        if (burgerRegistry[address(token.rightSide)].creator != address(0)) {
            revert ExistingTokenAsRightSide(address(token.rightSide));
        }

        // Create token
        token.leftSide = new CheezburgerBun{
            salt: _getSalt(_router, _rightSide)
        }(_customization, _fee, _wallet);

        // Create pair
        token.pair = IUniswapV2Pair(
            token.factory.createPair(
                address(token.leftSide),
                address(token.rightSide)
            )
        );
        ensurePairValid(token);
        if (token.pair.totalSupply() > 0) {
            revert PairNotEmpty();
        }

        // Save settings
        token.liquidity = _liquidity;
        token.fee = _fee;
        token.wallet = _wallet;
        token.referral = _referral;

        // Add token to registry
        ++totalTokens;
        burgerRegistry[address(token.leftSide)] = token;

        emit TokenDeployed(token);
        return token;
    }

    /// Generates a salt value for deploying clones.
    ///
    /// The salt is derived from:
    /// - Total number of tokens deployed
    /// - Provided router address
    /// - Provided right token address
    /// - Previous block random number
    /// - Current block number
    /// - Current block timestamp
    ///
    /// @param _router The Uniswap router address
    /// @param _rightSide The address of the right side token
    /// @return The generated salt value
    function _getSalt(
        address _router,
        address _rightSide
    ) private view returns (bytes32) {
        bytes memory data = abi.encodePacked(
            bytes32(uint256(totalTokens)),
            bytes32(abi.encodePacked(_router)),
            bytes32(abi.encodePacked(_rightSide)),
            bytes32(block.prevrandao),
            bytes32(block.number),
            bytes32(block.timestamp)
        );
        return keccak256(data);
    }

    /// Fetches the router and factory contracts for a router address.
    ///
    /// @param _router The address of the router contract
    ///
    /// @return router The router contract
    /// @return factory The factory contract
    ///
    /// This first checks if the provided router address is a valid contract.
    /// If so, it will attempt to call the `factory()` method on the router
    /// to retrieve the factory address.
    ///
    /// If the router address is invalid or the factory() call fails,
    /// zero addresses will be returned for both the router and factory.
    ///
    /// This provides a safe way to fetch the expected router and factory
    /// instances for a given address with proper validation.
    function getRouter(
        address _router
    ) private view returns (IUniswapV2Router02, IUniswapV2Factory) {
        if (_router.code.length > 0) {
            IUniswapV2Router02 router = IUniswapV2Router02(_router);
            try router.factory() returns (address factory) {
                if (factory != address(0)) {
                    return (router, IUniswapV2Factory(factory));
                }
            } catch {}
        }
        return (IUniswapV2Router02(address(0)), IUniswapV2Factory(address(0)));
    }

    /// Calculates the target threshold for dynamic liquidity fees.
    ///
    /// @param token The token settings struct
    ///
    /// @return The calculated fee threshold amount
    ///
    /// Checks the total tokens currently in the liquidity pool pair.
    /// It then calculates a threshold amount as a percentage (set
    /// by `feeThresholdPercent`) of those tokens.
    ///
    /// This dynamic threshold is used to determine if sell
    /// transactions must pay liquidity provider fees. By tying it
    /// to total pool size, the threshold scales automatically to
    /// always be a set % as more liquidity is provided over time.
    ///
    /// This approach aims to smoothly collect trading fees for LP's
    /// in a way that adjusts to pool size, reducing pricing impact.
    function _getLiquidityThreshold(
        Token memory token
    ) private view returns (uint256) {
        uint256 tokensInLiquidity = SafeTransferLib.balanceOf(
            address(token.leftSide),
            address(token.pair)
        );
        unchecked {
            return
                (tokensInLiquidity * token.liquidity.feeThresholdPercent) / 100;
        }
    }

    /// Adds liquidity to the Uniswap ETH pool for a token.
    ///
    /// @param token The token settings struct
    /// @param _leftAmount The amount of left token to add
    /// @param _etherAmount The amount of ETH to deposit
    ///
    /// Approves the token spending and adds liquidity
    /// to Uniswap, calling `addLiquidityETH()` on the router.
    ///
    /// This abstracts away adding liquidity with ETH to simplify
    /// integrating token deployments on Uniswap.
    function addLiquidityETH(
        Token memory token,
        uint256 _leftAmount,
        uint256 _etherAmount,
        address _receiver
    ) private {
        SafeTransferLib.safeApprove(
            address(token.leftSide),
            address(token.router),
            _leftAmount
        );
        token.router.addLiquidityETH{value: _etherAmount}(
            address(token.leftSide),
            _leftAmount,
            0,
            0,
            _receiver,
            block.timestamp
        );
    }

    /// Adds liquidity for a token pair on Uniswap.
    ///
    /// @param token The token settings struct
    /// @param _leftAmount The amount of left token to add
    /// @param _rightAmount The amount of right token to add
    ///
    /// Adds liquidity to the Uniswap pool for the token pair
    /// defined in the `token` struct. The function adds
    /// `_leftAmount` of the left token and `_rightAmount`
    /// of the right token to the pool, creating a liquidity
    /// position for this token pair on Uniswap.
    function addLiquidityToken(
        Token memory token,
        uint256 _leftAmount,
        uint256 _rightAmount,
        address _receiver
    ) private {
        SafeTransferLib.safeApprove(
            address(token.leftSide),
            address(token.router),
            _leftAmount
        );
        SafeTransferLib.safeApproveWithRetry(
            address(token.rightSide),
            address(token.router),
            _rightAmount
        );
        token.router.addLiquidity(
            address(token.leftSide),
            address(token.rightSide),
            _leftAmount,
            _rightAmount,
            0,
            0,
            _receiver,
            block.timestamp
        );
    }

    /// Swaps tokens and adds liquidity to Uniswap in one transaction.
    ///
    /// @param token The token settings struct
    /// @param _amounts The amounts of tokens to swap
    ///
    /// @return The balance of the new LP tokens received
    ///
    /// Swaps the specified token amounts according to the pair
    /// defined in the `token` struct. It then takes the output
    /// of the swap and adds it as liquidity to the Uniswap pool,
    /// returning the amount of LP tokens received for the newly
    /// provided liquidity. This allows swapping and adding
    /// liquidity to be done atomically in a single transaction.
    function swapAndLiquify(
        Token memory token,
        uint256 _amounts
    ) private returns (uint256, uint256, uint256) {
        unchecked {
            uint256 half = _amounts / 2;
            uint256 initialRightBalance = SafeTransferLib.balanceOf(
                address(token.rightSide),
                address(this)
            );
            swapLeftForRightSide(token, half);
            uint256 newRightBalance = SafeTransferLib.balanceOf(
                address(token.rightSide),
                address(this)
            ) - initialRightBalance;
            addLiquidityToken(token, half, newRightBalance, address(this));

            uint256 addedLP = SafeTransferLib.balanceOf(
                address(token.pair),
                address(this)
            );

            uint256 factoryFeeLP = factoryLiquidityFee > 0
                ? (addedLP * factoryLiquidityFee) / 100
                : 0;
            uint256 referralFeeLP = 0;
            if (
                token.referral.feeReceiver != address(0) &&
                token.referral.feePercentage > 0
            ) {
                referralFeeLP = (addedLP * token.referral.feePercentage) / 100;
            }

            emit SwapAndLiquify(
                address(token.leftSide),
                address(token.rightSide),
                half,
                initialRightBalance,
                newRightBalance
            );
            emit CommissionsTaken(factoryFeeLP, referralFeeLP);

            return (
                addedLP - factoryFeeLP - referralFeeLP,
                factoryFeeLP,
                referralFeeLP
            );
        }
    }

    /// Swaps left token for right token.
    ///
    /// @param token The token settings struct
    /// @param _amount The amount of left token to swap
    ///
    /// Swaps the specified amount of the left token for the
    /// right token according to the settings in the token struct.
    function swapLeftForRightSide(Token memory token, uint256 _amount) private {
        SafeTransferLib.safeApprove(
            address(token.leftSide),
            address(token.router),
            _amount
        );
        address[] memory path = new address[](2);
        path[0] = address(token.leftSide);
        path[1] = address(token.rightSide);
        token.router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    /// Validates that the Uniswap pair is properly set up.
    ///
    /// @param token The token settings struct
    ///
    /// Checks that:
    /// - The pair token0 != token1 (no same tokens)
    /// - One of the pair tokens matches the left token
    /// - One of the pair tokens matches the right token
    ///
    /// If any validation fails, reverts with an error.
    ///
    /// This ensures the Uniswap pair is properly set up according
    /// to the provided token contract settings.
    function ensurePairValid(Token memory token) internal view {
        address tokenA = token.pair.token0();
        address tokenB = token.pair.token1();
        address leftSide = address(token.leftSide);
        address rightSide = address(token.rightSide);

        if (tokenA == tokenB || leftSide == rightSide) {
            revert InvalidPair(tokenA, tokenB, leftSide, rightSide);
        }

        if (
            (tokenA != leftSide && tokenA != rightSide) ||
            (tokenB != leftSide && tokenB != rightSide)
        ) {
            revert InvalidPair(tokenA, tokenB, leftSide, rightSide);
        }
    }

    /// @dev Prevents direct Ether transfers to contract
    receive() external payable {
        revert CannotReceiveEtherDirectly();
    }
}