// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

import 'src/Marketplace.sol';
import 'src/lib/Swivel.sol';
import 'src/lib/Pendle.sol';
import 'src/lib/Element.sol';
import 'src/lib/Safe.sol';
import 'src/lib/Cast.sol';
import 'src/lib/RevertMsgExtractor.sol';
import 'src/lib/Maturities.sol';
import 'src/errors/Exception.sol';

import 'src/interfaces/ITempus.sol';
import 'src/interfaces/ITempusAMM.sol';
import 'src/interfaces/ITempusPool.sol';
import 'src/interfaces/ITempusToken.sol';
import 'src/interfaces/IERC20.sol';
import 'src/interfaces/IERC5095.sol';
import 'src/interfaces/ISensePeriphery.sol';
import 'src/interfaces/ISenseDivider.sol';
import 'src/interfaces/IYield.sol';
import 'src/interfaces/ISwivel.sol';
import 'src/interfaces/IElementVault.sol';
import 'src/interfaces/IAPWineAMMPool.sol';
import 'src/interfaces/IAPWineRouter.sol';
import 'src/interfaces/INotional.sol';
import 'src/interfaces/IPendle.sol';
import 'src/interfaces/IPendleMarket.sol';

/// @title Lender
/// @author Sourabh Marathe, Julian Traversa, Rob Robbins
/// @notice The lender contract executes loans on behalf of users
/// @notice The contract holds the principal tokens and mints an ERC-5095 tokens to users to represent their loans
contract Lender {
    /// @notice minimum wait before the admin may withdraw funds or change the fee rate
    uint256 public constant HOLD = 3 days;

    /// @notice address that is allowed to set and withdraw fees, disable principals, etc. It is commonly used in the authorized modifier.
    address public admin;
    /// @notice address of the MarketPlace contract, used to access the markets mapping
    address public marketPlace;
    /// @notice mapping that determines if a principal has been paused by the admin
    mapping(uint8 => bool) public paused;
    /// @notice flag that allows admin to stop all lending and minting across the entire protocol
    bool public halted;

    /// @notice contract used to execute swaps on Swivel's exchange
    address public immutable swivelAddr;
    /// @notice a SushiSwap router used by Pendle to execute swaps
    address public immutable pendleAddr;
    /// @notice a pool router used by APWine to execute swaps
    address public immutable apwineAddr;

    /// @notice a mapping that tracks the amount of unswapped premium by market. This underlying is later transferred to the Redeemer during Swivel's redeem call
    mapping(address => mapping(uint256 => uint256)) public premiums;

    /// @notice this value determines the amount of fees paid on loans
    uint256 public feenominator;
    /// @notice represents a point in time where the feenominator may change
    uint256 public feeChange;
    /// @notice represents a minimum that the feenominator must exceed
    uint256 public constant MIN_FEENOMINATOR = 500;

    /// @notice maps underlying tokens to the amount of fees accumulated for that token
    mapping(address => uint256) public fees;
    /// @notice maps a token address to a point in time, a hold, after which a withdrawal can be made
    mapping(address => uint256) public withdrawals;

    // Reantrancy protection
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status = _NOT_ENTERED;

    // Rate limiting protection
    /// @notice maximum amount of value that can flow through a protocol in a day (in USD)
    uint256 public maximumValue = 250_000e27;
    /// @notice maps protocols to how much value, in USD, has flowed through each protocol
    mapping(uint8 => uint256) public protocolFlow;
    /// @notice timestamp from which values flowing through protocol has begun
    mapping(uint8 => uint256) public periodStart;
    /// @notice estimated price of ether, set by the admin
    uint256 public etherPrice = 2_500;

    /// @notice emitted upon lending to a protocol
    event Lend(
        uint8 principal,
        address indexed underlying,
        uint256 indexed maturity,
        uint256 returned,
        uint256 spent,
        address sender
    );
    /// @notice emitted upon minting Illuminate principal tokens
    event Mint(
        uint8 principal,
        address indexed underlying,
        uint256 indexed maturity,
        uint256 amount
    );
    /// @notice emitted upon scheduling a withdrawal
    event ScheduleWithdrawal(address indexed token, uint256 hold);
    /// @notice emitted upon blocking a scheduled withdrawal
    event BlockWithdrawal(address indexed token);
    /// @notice emitted upon changing the admin
    event SetAdmin(address indexed admin);
    /// @notice emitted upon setting the fee rate
    event SetFee(uint256 indexed fee);
    /// @notice emitted upon scheduling a fee change
    event ScheduleFeeChange(uint256 when);
    /// @notice emitted upon blocking a scheduled fee change
    event BlockFeeChange();
    /// @notice emitted upon pausing or unpausing of a principal
    event PausePrincipal(uint8 principal, bool indexed state);
    /// @notice emitted upon pausing or unpausing minting, lending and redeeming
    event PauseIlluminate(bool state);

    /// @notice ensures that only a certain address can call the function
    /// @param a address that msg.sender must be to be authorized
    modifier authorized(address a) {
        if (msg.sender != a) {
            revert Exception(0, 0, 0, msg.sender, a);
        }
        _;
    }

    /// @notice reverts on all markets where the paused mapping returns true
    /// @param u address of an underlying asset
    /// @param m maturity (timestamp) of the market
    /// @param p principal value according to the MarketPlace's Principals Enum
    modifier unpaused(
        address u,
        uint256 m,
        uint8 p
    ) {
        if (paused[p] || halted) {
            revert Exception(1, p, 0, address(0), address(0));
        }
        _;
    }

    /// @notice reverts if called after maturity
    /// @param m maturity (timestamp) of the market
    modifier matured(uint256 m) {
        if (block.timestamp > m) {
            revert Exception(2, block.timestamp, m, address(0), address(0));
        }
        _;
    }

    /// @notice prevents users from re-entering contract
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        if (_status == _ENTERED) {
            revert Exception(30, 0, 0, address(0), address(0));
        }

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /// @notice initializes the Lender contract
    /// @param s the Swivel contract
    /// @param p the Pendle contract
    /// @param a the APWine contract
    constructor(address s, address p, address a) {
        admin = msg.sender;
        swivelAddr = s;
        pendleAddr = p;
        apwineAddr = a;
        feenominator = 1000;
    }

    /// @notice approves the redeemer contract to spend the principal tokens held by the lender contract.
    /// @param u address of an underlying asset
    /// @param m maturity (timestamp) of the market
    /// @param r the address being approved, in this case the redeemer contract
    /// @return bool true if the approval was successful
    function approve(
        address u,
        uint256 m,
        address r
    ) external authorized(admin) returns (bool) {
        // approve the underlying for max per given principal
        for (uint8 i; i != 9; ) {
            // get the principal token's address
            address token = IMarketPlace(marketPlace).markets(u, m, i);
            // check that the token is defined for this particular market
            if (token != address(0)) {
                // max approve the token
                Safe.approve(IERC20(token), r, type(uint256).max);
            }
            unchecked {
                ++i;
            }
        }
        // approve the redeemer to receive underlying from the lender
        Safe.approve(IERC20(u), r, type(uint256).max);
        return true;
    }

    /// @notice bulk approves the usage of addresses at the given ERC20 addresses.
    /// @dev the lengths of the inputs must match because the arrays are paired by index
    /// @param u array of ERC20 token addresses that will be approved on
    /// @param a array of addresses that will be approved
    /// @return true if successful
    function approve(
        address[] calldata u,
        address[] calldata a
    ) external authorized(admin) returns (bool) {
        for (uint256 i; i != u.length; ) {
            IERC20 uToken = IERC20(u[i]);
            if (address(0) != (address(uToken))) {
                Safe.approve(uToken, a[i], type(uint256).max);
            }
            unchecked {
                ++i;
            }
        }
        return true;
    }

    /// @notice approves market contracts that require lender approval
    /// @param u address of an underlying asset
    /// @param a APWine's router contract
    /// @param e Element's vault contract
    /// @param n Notional's token contract
    /// @param p Sense's periphery contract
    function approve(
        address u,
        address a,
        address e,
        address n,
        address p
    ) external authorized(marketPlace) {
        uint256 max = type(uint256).max;
        IERC20 uToken = IERC20(u);
        if (a != address(0)) {
            Safe.approve(uToken, a, max);
        }
        if (e != address(0)) {
            Safe.approve(uToken, e, max);
        }
        if (n != address(0)) {
            Safe.approve(uToken, n, max);
        }
        if (p != address(0)) {
            Safe.approve(uToken, p, max);
        }
        if (IERC20(u).allowance(address(this), swivelAddr) == 0) {
            Safe.approve(uToken, swivelAddr, max);
        }
    }

    /// @notice sets the admin address
    /// @param a address of a new admin
    /// @return bool true if successful
    function setAdmin(address a) external authorized(admin) returns (bool) {
        admin = a;
        emit SetAdmin(a);
        return true;
    }

    /// @notice sets the feenominator to the given value
    /// @param f the new value of the feenominator, fees are not collected when the feenominator is 0
    /// @return bool true if successful
    function setFee(uint256 f) external authorized(admin) returns (bool) {
        uint256 feeTime = feeChange;
        if (feeTime == 0) {
            revert Exception(23, 0, 0, address(0), address(0));
        } else if (block.timestamp < feeTime) {
            revert Exception(
                24,
                block.timestamp,
                feeTime,
                address(0),
                address(0)
            );
        } else if (f < MIN_FEENOMINATOR) {
            revert Exception(25, 0, 0, address(0), address(0));
        }
        feenominator = f;
        delete feeChange;
        emit SetFee(f);
        return true;
    }

    /// @notice sets the address of the marketplace contract which contains the addresses of all the fixed rate markets
    /// @param m the address of the marketplace contract
    /// @return bool true if the address was set
    function setMarketPlace(
        address m
    ) external authorized(admin) returns (bool) {
        if (marketPlace != address(0)) {
            revert Exception(5, 0, 0, marketPlace, address(0));
        }
        marketPlace = m;
        return true;
    }

    /// @notice sets the ethereum price which is used in rate limiting
    /// @param p the new price
    /// @return bool true if the price was set
    function setEtherPrice(
        uint256 p
    ) external authorized(admin) returns (bool) {
        etherPrice = p;
        return true;
    }

    /// @notice sets the maximum value that can flow through a protocol
    /// @param m the maximum value by protocol
    /// @return bool true if the price was set
    function setMaxValue(uint256 m) external authorized(admin) returns (bool) {
        maximumValue = m;
        return true;
    }

    /// @notice mint swaps the sender's principal tokens for Illuminate's ERC5095 tokens in effect, this opens a new fixed rate position for the sender on Illuminate
    /// @param p principal value according to the MarketPlace's Principals Enum
    /// @param u address of an underlying asset
    /// @param m maturity (timestamp) of the market
    /// @param a amount being minted
    /// @return bool true if the mint was successful
    function mint(
        uint8 p,
        address u,
        uint256 m,
        uint256 a
    ) external nonReentrant unpaused(u, m, p) returns (bool) {
        // Fetch the desired principal token
        address principal = IMarketPlace(marketPlace).markets(u, m, p);

        // Disallow mints if market is not initialized
        if (principal == address(0)) {
            revert Exception(26, 0, 0, address(0), address(0));
        }

        // Get the maturity of the principal token
        uint256 maturity;
        if (p == uint8(MarketPlace.Principals.Illuminate)) {
            revert Exception(32, 0, 0, address(0), address(0));
        } else if (p == uint8(MarketPlace.Principals.Swivel)) {
            maturity = Maturities.swivel(principal);
        } else if (p == uint8(MarketPlace.Principals.Yield)) {
            maturity = Maturities.yield(principal);
        } else if (p == uint8(MarketPlace.Principals.Element)) {
            maturity = Maturities.element(principal);
        } else if (p == uint8(MarketPlace.Principals.Pendle)) {
            maturity = Maturities.pendle(principal);
        } else if (p == uint8(MarketPlace.Principals.Tempus)) {
            maturity = Maturities.tempus(principal);
        } else if (p == uint8(MarketPlace.Principals.Apwine)) {
            maturity = Maturities.apwine(principal);
        } else if (p == uint8(MarketPlace.Principals.Notional)) {
            maturity = Maturities.notional(principal);
        }

        // Confirm that the principal token has not matured yet
        if (block.timestamp > maturity || maturity == 0) {
            revert Exception(
                7,
                maturity,
                block.timestamp,
                address(0),
                address(0)
            );
        }

        // Transfer the users principal tokens to the lender contract
        Safe.transferFrom(IERC20(principal), msg.sender, address(this), a);

        // Calculate how much should be minted based on the decimal difference
        uint256 mintable = convertDecimals(u, principal, a);

        // Confirm that minted iPT amount will not exceed rate limit for the protocol
        rateLimit(p, u, mintable);

        // Mint the tokens received from the user
        IERC5095(principalToken(u, m)).authMint(msg.sender, mintable);

        emit Mint(p, u, m, mintable);

        return true;
    }

    /// @notice lend method for the Illuminate and Yield protocols
    /// @param p principal value according to the MarketPlace's Principals Enum
    /// @param u address of an underlying asset
    /// @param m maturity (timestamp) of the market
    /// @param a amount of underlying tokens to lend
    /// @param y Yield Space Pool for the principal token
    /// @param minimum slippage limit, minimum amount to PTs to buy
    /// @return uint256 the amount of principal tokens lent out
    function lend(
        uint8 p,
        address u,
        uint256 m,
        uint256 a,
        address y,
        uint256 minimum
    ) external nonReentrant unpaused(u, m, p) matured(m) returns (uint256) {
        // Get principal token for this market
        address principal = IMarketPlace(marketPlace).markets(u, m, p);

        // Extract fee
        fees[u] = fees[u] + a / feenominator;

        // Transfer underlying from user to the lender contract
        Safe.transferFrom(IERC20(u), msg.sender, address(this), a);

        // Make sure the Yield Space Pool matches the market
        address fyToken = IYield(y).fyToken();
        if (IYield(y).fyToken() != principal) {
            revert Exception(12, 0, 0, fyToken, principal);
        }
        address base = address(IYield(y).base());
        if (base != u) {
            revert Exception(27, 0, 0, base, u);
        }

        // Set who should get the tokens that are swapped for
        address receiver = address(this);

        // If lending on Illuminate, swap directly to the caller
        if (p == uint8(MarketPlace.Principals.Illuminate)) {
            receiver = msg.sender;
        }

        // Swap underlying for PTs to lender
        uint256 returned = yield(
            u,
            y,
            a - a / feenominator,
            receiver,
            principal,
            minimum
        );

        // Convert decimals from principal token to underlying
        returned = convertDecimals(u, principal, returned);

        // Only mint iPTs to user if lending through Yield protocol
        if (p == uint8(MarketPlace.Principals.Yield)) {
            // Confirm that minted iPT amount will not exceed rate limit for the protocol
            rateLimit(p, u, returned);

            // Mint Illuminate PTs to msg.sender
            IERC5095(principalToken(u, m)).authMint(msg.sender, returned);
        }

        emit Lend(p, u, m, returned, a, msg.sender);

        return returned;
    }

    /// @notice lend method signature for Swivel
    /// @param p principal value according to the MarketPlace's Principals Enum
    /// @param u address of an underlying asset
    /// @param m maturity (timestamp) of the market
    /// @param a array of amounts of underlying tokens lent to each order in the orders array
    /// @param y Yield Space Pool for the Illuminate PT in this market
    /// @param o array of Swivel orders being filled
    /// @param s array of signatures for each order in the orders array
    /// @param e flag to indicate if returned funds should be swapped in Yield Space Pool
    /// @param premiumSlippage slippage limit, minimum amount to PTs to buy
    /// @return uint256 the amount of principal tokens lent out
    function lend(
        uint8 p,
        address u,
        uint256 m,
        uint256[] memory a,
        address y,
        Swivel.Order[] calldata o,
        Swivel.Components[] calldata s,
        bool e,
        uint256 premiumSlippage
    ) external nonReentrant unpaused(u, m, p) matured(m) returns (uint256) {
        // Ensure all the orders are for the underlying asset
        swivelVerify(o, u);

        // Lent represents the total amount of underlying to be lent
        uint256 lent = swivelAmount(a);

        // Get the underlying balance prior to calling initiate
        uint256 starting = IERC20(u).balanceOf(address(this));

        // Transfer underlying token from user to Illuminate
        Safe.transferFrom(IERC20(u), msg.sender, address(this), lent);

        // Calculate fee for the total amount to be lent
        uint256 fee = lent / feenominator;

        {
            // Get last order to be processed's index
            uint256 lastIndex = a.length - 1;

            // Add the accumulated fees to the total
            a[lastIndex] = a[lastIndex] - fee; // Revert here if fee not paid

            // Extract fee
            fees[u] += fee;
        }

        uint256 received;
        {
            // Get the starting amount of principal tokens
            uint256 startingZcTokens = IERC20(
                IMarketPlace(marketPlace).markets(u, m, p)
            ).balanceOf(address(this));

            // Fill the given orders on Swivel
            ISwivel(swivelAddr).initiate(o, a, s);

            // Compute how many principal tokens were received
            received = (IERC20(IMarketPlace(marketPlace).markets(u, m, p))
                .balanceOf(address(this)) - startingZcTokens);

            // Calculate the premium
            uint256 premium = (IERC20(u).balanceOf(address(this)) - starting) -
                fee;

            // Calculate the fee on the premium
            uint256 premiumFee = premium / feenominator;

            // Extract fee from premium
            fees[u] += premiumFee;

            // Remove the fee from the premium
            premium = premium - premiumFee;

            // Store how much the user received in exchange for swapping the premium for iPTs
            uint256 swapped;

            if (e) {
                // Swap the premium for Illuminate principal tokens
                swapped += yield(
                    u,
                    y,
                    premium,
                    msg.sender,
                    IMarketPlace(marketPlace).markets(u, m, 0),
                    premiumSlippage
                );
            } else {
                // Send the premium to the redeemer to hold until redemption
                premiums[u][m] = premiums[u][m] + premium;

                // Account for the premium
                received = received + premium;
            }

            // Mint Illuminate principal tokens to the user
            IERC5095(principalToken(u, m)).authMint(msg.sender, received);

            emit Lend(
                uint8(MarketPlace.Principals.Swivel),
                u,
                m,
                received + swapped,
                lent,
                msg.sender
            );
        }

        // Confirm that minted iPT amount will not exceed rate limit for the protocol
        rateLimit(p, u, received);
        return received;
    }

    /// @notice lend method signature for Element
    /// @param p principal value according to the MarketPlace's Principals Enum
    /// @param u address of an underlying asset
    /// @param m maturity (timestamp) of the market
    /// @param a amount of underlying tokens to lend
    /// @param r slippage limit, minimum amount to PTs to buy
    /// @param d deadline is a timestamp by which the swap must be executed
    /// @param e Element pool that is lent to
    /// @param i the id of the pool
    /// @return uint256 the amount of principal tokens lent out
    function lend(
        uint8 p,
        address u,
        uint256 m,
        uint256 a,
        uint256 r,
        uint256 d,
        address e,
        bytes32 i
    ) external nonReentrant unpaused(u, m, p) matured(m) returns (uint256) {
        // Get the principal token for this market for Element
        address principal = IMarketPlace(marketPlace).markets(u, m, p);

        // Transfer underlying token from user to Illuminate
        Safe.transferFrom(IERC20(u), msg.sender, address(this), a);

        // Track the accumulated fees
        fees[u] = fees[u] + a / feenominator;

        uint256 purchased;
        {
            // Calculate the amount to be lent
            uint256 lent = a - a / feenominator;

            // Create the variables needed to execute an Element swap
            Element.FundManagement memory fund = Element.FundManagement({
                sender: address(this),
                recipient: payable(address(this)),
                fromInternalBalance: false,
                toInternalBalance: false
            });

            Element.SingleSwap memory swap = Element.SingleSwap({
                poolId: i,
                amount: lent,
                kind: Element.SwapKind.GIVEN_IN,
                assetIn: IAny(u),
                assetOut: IAny(principal),
                userData: '0x00000000000000000000000000000000000000000000000000000000000000'
            });

            // Conduct the swap on Element
            purchased = elementSwap(e, swap, fund, r, d);

            // Convert decimals from principal token to underlying
            purchased = convertDecimals(u, principal, purchased);
        }

        // Confirm that minted iPT amount will not exceed rate limit for the protocol
        rateLimit(p, u, purchased);

        // Mint tokens to the user
        IERC5095(principalToken(u, m)).authMint(msg.sender, purchased);

        emit Lend(p, u, m, purchased, a, msg.sender);
        return purchased;
    }

    /// @notice lend method signature for Pendle
    /// @param p principal value according to the MarketPlace's Principals Enum
    /// @param u address of an underlying asset
    /// @param m maturity (timestamp) of the market
    /// @param a amount of underlying tokens to lend
    /// @param r slippage limit, minimum amount to PTs to buy
    /// @param g guess parameters for the swap
    /// @param market contract that corresponds to the market for the PT
    /// @return uint256 the amount of principal tokens lent out
    function lend(
        uint8 p,
        address u,
        uint256 m,
        uint256 a,
        uint256 r,
        Pendle.ApproxParams calldata g,
        address market
    ) external nonReentrant unpaused(u, m, p) matured(m) returns (uint256) {
        // Instantiate market and tokens
        address principal = IMarketPlace(marketPlace).markets(u, m, p);

        // Confirm the market corresponds to this Illuminate market
        (, address marketPrincipal, ) = IPendleMarket(market).readTokens();
        if (marketPrincipal != principal) {
            revert Exception(27, 0, 0, market, principal);
        }

        // Transfer funds from user to Illuminate
        Safe.transferFrom(IERC20(u), msg.sender, address(this), a);

        uint256 returned;
        {
            // Add the accumulated fees to the total
            uint256 fee = a / feenominator;
            fees[u] = fees[u] + fee;

            // Setup the token input
            Pendle.TokenInput memory input = Pendle.TokenInput(
                u,
                a - fee,
                u,
                address(0),
                address(0),
                '0x00000000000000000000000000000000000000000000000000000000000000'
            );

            // Swap on the Pendle Router using the provided market and params
            (returned, ) = IPendle(pendleAddr).swapExactTokenForPt(
                address(this),
                market,
                r,
                g,
                input
            );

            // Convert decimals from principal token to underlying
            returned = convertDecimals(u, principal, returned);
        }

        // Confirm that minted iPT amount will not exceed rate limit for the protocol
        rateLimit(p, u, returned);

        // Mint Illuminate zero coupons
        IERC5095(principalToken(u, m)).authMint(msg.sender, returned);

        emit Lend(p, u, m, returned, a, msg.sender);
        return returned;
    }

    /// @notice lend method signature for Tempus and APWine
    /// @param p value of a specific principal according to the Illuminate Principals Enum
    /// @param u address of an underlying asset
    /// @param m maturity (timestamp) of the market
    /// @param a amount of principal tokens to lend
    /// @param r minimum amount to return when executing the swap (sets a limit to slippage)
    /// @param d deadline is a timestamp by which the swap must be executed
    /// @param x Tempus or APWine AMM that executes the swap
    /// @return uint256 the amount of principal tokens lent out
    function lend(
        uint8 p,
        address u,
        uint256 m,
        uint256 a,
        uint256 r,
        uint256 d,
        address x
    ) external nonReentrant unpaused(u, m, p) matured(m) returns (uint256) {
        address principal = IMarketPlace(marketPlace).markets(u, m, p);

        // Transfer funds from user to Illuminate
        Safe.transferFrom(IERC20(u), msg.sender, address(this), a);

        uint256 lent;
        {
            // Add the accumulated fees to the total
            uint256 fee = a / feenominator;
            fees[u] = fees[u] + fee;

            // Calculate amount to be lent out
            lent = a - fee;
        }

        // Get the starting balance of the principal token
        uint256 start = IERC20(principal).balanceOf(address(this));

        if (p == uint8(MarketPlace.Principals.Tempus)) {
            // Get the Tempus pool from the principal token
            ITempusPool pool = ITempusPool(ITempusToken(principal).pool());

            // Get the pool of the contract the user submitted
            address userPool = ITempusAMM(x).tempusPool();

            // Confirm that the pool matches the principal token
            if (address(pool) != userPool) {
                revert Exception(27, 0, 0, address(pool), userPool);
            }

            // Get the Tempus router from the principal token
            address controller = pool.controller();

            // Swap on the Tempus router using the provided market and params
            ITempus(controller).depositAndFix(x, lent, true, 0, d);
        } else if (p == uint8(MarketPlace.Principals.Apwine)) {
            address poolUnderlying = IAPWineAMMPool(x)
                .getUnderlyingOfIBTAddress();
            if (u != poolUnderlying) {
                revert Exception(27, 0, 0, u, poolUnderlying);
            }
            address poolPrincipal = IAPWineAMMPool(x).getPTAddress();
            if (principal != poolPrincipal) {
                revert Exception(27, 0, 0, principal, poolPrincipal);
            }
            // Swap on the APWine Pool using the provided market and params
            IAPWineRouter(apwineAddr).swapExactAmountIn(
                x,
                apwinePairPath(),
                apwineTokenPath(),
                lent,
                r,
                address(this),
                d,
                address(0)
            );
        }

        // Calculate the amount of Tempus principal tokens received after the deposit
        uint256 received = IERC20(principal).balanceOf(address(this)) - start;

        // Convert decimals from principal token to underlying
        received = convertDecimals(u, principal, received);

        // Verify that a minimum number of principal tokens were received
        if (p == uint8(MarketPlace.Principals.Tempus) && received < r) {
            revert Exception(11, received, r, address(0), address(0));
        }

        // Confirm that minted iPT amount will not exceed rate limit for the protocol
        rateLimit(p, u, received);

        // Mint Illuminate zero coupons
        IERC5095(principalToken(u, m)).authMint(msg.sender, received);

        emit Lend(p, u, m, received, a, msg.sender);
        return received;
    }

    /// @notice lend method signature for Sense
    /// @dev this method can be called before maturity to lend to Sense while minting Illuminate tokens
    /// @dev Sense provides a [divider] contract that splits [target] assets (underlying) into PTs and YTs. Each [target] asset has a [series] of contracts, each identifiable by their [maturity].
    /// @param p principal value according to the MarketPlace's Principals Enum
    /// @param u address of an underlying asset
    /// @param m maturity (timestamp) of the market
    /// @param a amount of underlying tokens to lend
    /// @param r slippage limit, minimum amount to PTs to buy
    /// @param x periphery contract that is used to conduct the swap
    /// @param s Sense's maturity for the given market
    /// @param adapter Sense's adapter necessary to facilitate the swap
    /// @return uint256 the amount of principal tokens lent out
    function lend(
        uint8 p,
        address u,
        uint256 m,
        uint128 a,
        uint256 r,
        address x,
        uint256 s,
        address adapter
    ) external nonReentrant unpaused(u, m, p) matured(m) returns (uint256) {
        // Get the periphery's divider contract to verify that it maps to the prinicpal token of the market
        address divider = ISensePeriphery(x).divider();

        // Get the principal token for the user submitted periphery
        address userPrincipal = ISenseDivider(divider).pt(adapter, s);

        // Retrieve the principal token for this market
        IERC20 token = IERC20(IMarketPlace(marketPlace).markets(u, m, p));

        // Verify that the `x` parameter matches the market's Sense principal token
        if (address(token) != userPrincipal) {
            revert Exception(27, 0, 0, address(token), userPrincipal);
        }

        // Transfer funds from user to Illuminate
        Safe.transferFrom(IERC20(u), msg.sender, address(this), a);

        // Determine the fee
        uint256 fee = a / feenominator;

        // Add the accumulated fees to the total
        fees[u] = fees[u] + fee;

        // Determine lent amount after fees
        uint256 lent = a - fee;

        // Stores the amount of principal tokens received in swap for underlying
        uint256 received;
        {
            // Get the starting balance of the principal token
            uint256 starting = token.balanceOf(address(this));

            // Swap those tokens for the principal tokens
            ISensePeriphery(x).swapUnderlyingForPTs(adapter, s, lent, r);

            // Calculate number of principal tokens received in the swap
            received = token.balanceOf(address(this)) - starting;

            // Verify that we received the principal tokens
            if (received < r) {
                revert Exception(11, 0, 0, address(0), address(0));
            }
        }

        // Get the Illuminate PT
        address ipt = principalToken(u, m);

        // Calculate the mintable amount of tokens for Sense due to decimal mismatch
        uint256 mintable = convertDecimals(u, address(token), received);

        // Confirm that minted iPT amount will not exceed rate limit for the protocol
        rateLimit(p, u, mintable);

        // Mint the Illuminate tokens based on the returned amount
        IERC5095(ipt).authMint(msg.sender, mintable);

        emit Lend(p, u, m, mintable, a, msg.sender);
        return mintable;
    }

    /// @dev lend method signature for Notional
    /// @param p principal value according to the MarketPlace's Principals Enum
    /// @param u address of an underlying asset
    /// @param m maturity (timestamp) of the market
    /// @param a amount of underlying tokens to lend
    /// @param r slippage limit, minimum amount to PTs to buy
    /// @return uint256 the amount of principal tokens lent out
    function lend(
        uint8 p,
        address u,
        uint256 m,
        uint256 a,
        uint256 r
    ) external nonReentrant unpaused(u, m, p) matured(m) returns (uint256) {
        // Confirm that we are using Notional's PT to avoid conflicts with other ERC4626 tokens
        if (p != uint8(MarketPlace.Principals.Notional)) {
            revert Exception(6, p, 0, address(0), address(0));
        }

        // Instantiate Notional princpal token
        address token = IMarketPlace(marketPlace).markets(u, m, p);

        // Transfer funds from user to Illuminate
        Safe.transferFrom(IERC20(u), msg.sender, address(this), a);

        // Determine the fee
        uint256 fee = a / feenominator;

        // Add the accumulated fees to the total
        fees[u] = fees[u] + fee;

        // Swap on the Notional Token wrapper
        uint256 received = INotional(token).deposit(a - fee, address(this));

        // Convert decimals from principal token to underlying
        received = convertDecimals(u, token, received);

        // Verify that we received the principal tokens
        if (received < r) {
            revert Exception(16, received, r, address(0), address(0));
        }

        // Confirm that minted iPT amount will not exceed rate limit for the protocol
        rateLimit(p, u, received);

        // Mint Illuminate zero coupons
        IERC5095(principalToken(u, m)).authMint(msg.sender, received);

        emit Lend(p, u, m, received, a, msg.sender);
        return received;
    }

    /// @notice allows the admin to schedule the withdrawal of tokens
    /// @param e address of (erc20) token to withdraw
    /// @return bool true if successful
    function scheduleWithdrawal(
        address e
    ) external authorized(admin) returns (bool) {
        // Calculate the timestamp that must be passed prior to withdrawal
        uint256 when = block.timestamp + HOLD;

        // Set the timestamp threshold for the token being withdrawn
        withdrawals[e] = when;

        emit ScheduleWithdrawal(e, when);
        return true;
    }

    /// @notice emergency function to block unplanned withdrawals
    /// @param e address of token withdrawal to block
    /// @return bool true if successful
    function blockWithdrawal(
        address e
    ) external authorized(admin) returns (bool) {
        // Resets threshold to 0 for the token, stopping withdrawl of the token
        delete withdrawals[e];

        emit BlockWithdrawal(e);
        return true;
    }

    /// @notice allows the admin to schedule a change to the fee denominators
    function scheduleFeeChange() external authorized(admin) returns (bool) {
        // Calculate the timestamp that must be passed prior to setting thew new fee
        uint256 when = block.timestamp + HOLD;

        // Store the timestamp that must be passed to update the fee rate
        feeChange = when;

        emit ScheduleFeeChange(when);
        return true;
    }

    /// @notice Emergency function to block unplanned changes to fee structure
    function blockFeeChange() external authorized(admin) returns (bool) {
        // Resets threshold to 0 for the token, stopping the scheduling of a fee rate change
        delete feeChange;

        emit BlockFeeChange();
        return true;
    }

    /// @notice allows the admin to withdraw the given token, provided the holding period has been observed
    /// @param e Address of token to withdraw
    /// @return bool true if successful
    function withdraw(address e) external authorized(admin) returns (bool) {
        // Get the minimum timestamp to withdraw the token
        uint256 when = withdrawals[e];

        // Check that the withdrawal was scheduled for the token
        if (when == 0) {
            revert Exception(18, 0, 0, address(0), address(0));
        }

        // Check that it is now past the scheduled timestamp for withdrawing the token
        if (block.timestamp < when) {
            revert Exception(19, 0, 0, address(0), address(0));
        }

        // Reset the scheduled withdrawal
        delete withdrawals[e];

        // Reset the fees for the token (relevant when withdrawing underlying for markets)
        delete fees[e];

        // Send the token to the admin
        IERC20 token = IERC20(e);
        Safe.transfer(token, admin, token.balanceOf(address(this)));

        return true;
    }

    /// @notice withdraws accumulated lending fees of the underlying token
    /// @param e address of the underlying token to withdraw
    /// @return bool true if successful
    function withdrawFee(address e) external authorized(admin) returns (bool) {
        // Get the token to be withdrawn
        IERC20 token = IERC20(e);

        // Get the balance to be transferred
        uint256 balance = fees[e];

        // Reset accumulated fees of the token to 0
        fees[e] = 0;

        // Transfer the accumulated fees to the admin
        Safe.transfer(token, admin, balance);

        return true;
    }

    /// @notice pauses a market and prevents execution of all lending for that principal
    /// @param p principal value according to the MarketPlace's Principals Enum
    /// @param b bool representing whether to pause or unpause
    /// @return bool true if successful
    function pause(uint8 p, bool b) external authorized(admin) returns (bool) {
        // Set the paused state for the principal token in the market
        paused[p] = b;

        emit PausePrincipal(p, b);
        return true;
    }

    /// @notice pauses Illuminate's redeem, mint and lend methods from being used
    /// @param b bool representing whether to pause or unpause Illuminate
    /// @return bool true if successfully set
    function pauseIlluminate(bool b) external authorized(admin) returns (bool) {
        halted = b;
        emit PauseIlluminate(b);
        return true;
    }

    /// @notice Tranfers FYTs to Redeemer (used specifically for APWine redemptions)
    /// @param f FYT contract address
    /// @param a amount of tokens to send to the redeemer
    function transferFYTs(
        address f,
        uint256 a
    ) external authorized(IMarketPlace(marketPlace).redeemer()) {
        // Transfer the Lender's FYT tokens to the Redeemer
        Safe.transfer(IERC20(f), IMarketPlace(marketPlace).redeemer(), a);
    }

    /// @notice Transfers premium from the market to Redeemer (used specifically for Swivel redemptions)
    /// @param u address of an underlying asset
    /// @param m maturity (timestamp) of the market
    function transferPremium(
        address u,
        uint256 m
    ) external authorized(IMarketPlace(marketPlace).redeemer()) {
        Safe.transfer(
            IERC20(u),
            IMarketPlace(marketPlace).redeemer(),
            premiums[u][m]
        );

        premiums[u][m] = 0;
    }

    /// @notice Allows batched call to self (this contract).
    /// @param c An array of inputs for each call.
    function batch(
        bytes[] calldata c
    ) external payable returns (bytes[] memory results) {
        results = new bytes[](c.length);

        for (uint256 i; i < c.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(
                c[i]
            );

            if (!success) revert(RevertMsgExtractor.getRevertMsg(result));
            results[i] = result;
        }
    }

    /// @notice swaps underlying premium via a Yield Space Pool
    /// @dev this method is only used by the Yield, Illuminate and Swivel protocols
    /// @param u address of an underlying asset
    /// @param y Yield Space Pool for the principal token
    /// @param a amount of underlying tokens to lend
    /// @param r the receiving address for PTs
    /// @param p the principal token in the Yield Space Pool
    /// @param m the minimum amount to purchase
    /// @return uint256 the amount of tokens sent to the Yield Space Pool
    function yield(
        address u,
        address y,
        uint256 a,
        address r,
        address p,
        uint256 m
    ) internal returns (uint256) {
        // Get the starting balance (to verify receipt of tokens)
        uint256 starting = IERC20(p).balanceOf(r);

        // Get the amount of tokens received for swapping underlying
        uint128 returned = IYield(y).sellBasePreview(Cast.u128(a));

        // Send the remaining amount to the Yield pool
        Safe.transfer(IERC20(u), y, a);

        // Lend out the remaining tokens in the Yield pool
        IYield(y).sellBase(r, returned);

        // Get the ending balance of principal tokens (must be at least starting + returned)
        uint256 received = IERC20(p).balanceOf(r) - starting;

        // Verify receipt of PTs from Yield Space Pool
        if (received < m) {
            revert Exception(11, received, m, address(0), address(0));
        }

        return received;
    }

    /// @notice returns the amount of underlying tokens to be used in a Swivel lend
    function swivelAmount(uint256[] memory a) internal pure returns (uint256) {
        uint256 lent;

        // Iterate through each order a calculate the total lent and returned
        for (uint256 i; i != a.length; ) {
            {
                // Sum the total amount lent to Swivel
                lent = lent + a[i];
            }

            unchecked {
                ++i;
            }
        }

        return lent;
    }

    /// @notice reverts if any orders are not for the market
    function swivelVerify(Swivel.Order[] memory o, address u) internal pure {
        for (uint256 i; i != o.length; ) {
            address orderUnderlying = o[i].underlying;
            if (u != orderUnderlying) {
                revert Exception(3, 0, 0, u, orderUnderlying);
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @notice executes a swap for and verifies receipt of Element PTs
    function elementSwap(
        address e,
        Element.SingleSwap memory s,
        Element.FundManagement memory f,
        uint256 r,
        uint256 d
    ) internal returns (uint256) {
        // Get the principal token
        address principal = address(s.assetOut);

        // Get the intial balance
        uint256 starting = IERC20(principal).balanceOf(address(this));

        // Conduct the swap on Element
        IElementVault(e).swap(s, f, r, d);

        // Get how many PTs were purchased by the swap call
        uint256 purchased = IERC20(principal).balanceOf(address(this)) -
            starting;

        // Verify that a minimum amount was received
        if (purchased < r) {
            revert Exception(11, 0, 0, address(0), address(0));
        }

        // Return the net amount of principal tokens acquired after the swap
        return purchased;
    }

    /// @notice returns array token path required for APWine's swap method
    /// @return array of uint256[] as laid out in APWine's docs
    function apwineTokenPath() internal pure returns (uint256[] memory) {
        uint256[] memory tokenPath = new uint256[](2);
        tokenPath[0] = 1;
        tokenPath[1] = 0;
        return tokenPath;
    }

    /// @notice returns array pair path required for APWine's swap method
    /// @return array of uint256[] as laid out in APWine's docs
    function apwinePairPath() internal pure returns (uint256[] memory) {
        uint256[] memory pairPath = new uint256[](1);
        pairPath[0] = 0;
        return pairPath;
    }

    /// @notice retrieves the ERC5095 token for the given market
    /// @param u address of an underlying asset
    /// @param m maturity (timestamp) of the market
    /// @return address of the ERC5095 token for the market
    function principalToken(address u, uint256 m) internal returns (address) {
        return IMarketPlace(marketPlace).markets(u, m, 0);
    }

    /// @notice converts principal decimal amount to underlying's decimal amount
    /// @param u address of an underlying asset
    /// @param p address of a principal token
    /// @param a amount denominated in principal token's decimals
    /// @return uint256 in underlying decimals
    function convertDecimals(
        address u,
        address p,
        uint256 a
    ) internal view returns (uint256) {
        // Get the decimals of the underlying asset
        uint8 underlyingDecimals = IERC20(u).decimals();

        // Get the decimals of the principal token
        uint8 principalDecimals = IERC20(p).decimals();

        // Determine which asset has more decimals
        if (underlyingDecimals > principalDecimals) {
            // Shift decimals accordingly
            return a * 10 ** (underlyingDecimals - principalDecimals);
        }
        return a / 10 ** (principalDecimals - underlyingDecimals);
    }

    /// @notice limits the amount of funds (in USD value) that can flow through a principal in a day
    /// @param p principal value according to the MarketPlace's Principals Enum
    /// @param u address of an underlying asset
    /// @param a amount being minted which is normalized to 18 decimals prior to check
    /// @return bool true if successful, reverts otherwise
    function rateLimit(uint8 p, address u, uint256 a) internal returns (bool) {
        // Get amount in USD to be minted
        uint256 valueToMint = a;

        // In case of stETH, we will calculate an approximate USD value
        // 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84 (stETH address)
        if (u == 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84) {
            valueToMint = etherPrice * valueToMint;
        }

        // Normalize the value to be minted to 27 decimals
        valueToMint = valueToMint * 10 ** (27 - IERC20(u).decimals());

        // Cache max value
        uint256 maxValue = maximumValue;

        // Transactions of greater than the max value of USD are rate limited
        if (valueToMint > maxValue) {
            revert Exception(31, protocolFlow[p], p, address(0), address(0));
        }

        // Cache protocol flow value
        uint256 flow = protocolFlow[p] + valueToMint;

        // Update the amount of USD value flowing through the protocol
        protocolFlow[p] = flow;

        // If more than one day has passed, do not rate limit
        if (block.timestamp - periodStart[p] > 1 days) {
            // Reset the flow amount
            protocolFlow[p] = valueToMint;

            // Reset the period
            periodStart[p] = block.timestamp;
        }
        // If more than the max USD has flowed through the protocol, revert
        else if (flow > maxValue) {
            revert Exception(31, protocolFlow[p], p, address(0), address(0));
        }

        return true;
    }
}