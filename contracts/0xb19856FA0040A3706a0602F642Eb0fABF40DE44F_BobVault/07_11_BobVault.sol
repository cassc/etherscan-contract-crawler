// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./yield/YieldConnector.sol";
import "./proxy/EIP1967Admin.sol";
import "./utils/Ownable.sol";

/**
 * @title BobVault
 * @dev This contract contains logic for buying/selling BOB tokens for multiple underlying collaterals at a fixed flat rate.
 * Locked collateral can be seamlessly invested in arbitrary yield-generating protocols (e.g. Compound or AAVE)
 */
contract BobVault is EIP1967Admin, Ownable, YieldConnector {
    using SafeERC20 for IERC20;

    address public yieldAdmin; // permissioned receiver of swap fees and generated compound yields
    address public investAdmin; // account triggering invest of excess collateral
    IERC20 public immutable bobToken;

    mapping(address => Collateral) public collateral;

    uint64 internal constant MAX_FEE = 0.01 ether; // 1%

    struct Collateral {
        uint128 balance; // accounted required collateral balance
        uint128 buffer; // buffer of tokens that should not be invested and kept as is
        uint96 dust; // small non-withdrawable yield to account for possible rounding issues
        address yield; // address of yield-generating implementation
        uint128 price; // X tokens / 1 bob
        uint64 inFee; // fee for TOKEN->BOB buys
        uint64 outFee; // fee for BOB->TOKEN sells
        uint256 maxBalance; // limit on the amount of the specific collateral
        uint256 maxInvested; // limit on the amount of the specific collateral subject to investment
    }

    struct Stat {
        uint256 total; // current balance of collateral (total == required + farmed)
        uint256 required; // min required balance of collateral
        uint256 farmed; // withdrawable collateral yield
    }

    event AddCollateral(address indexed token, uint128 price);
    event UpdateFees(address indexed token, uint64 inFee, uint64 outFee);
    event UpdateMaxBalance(address indexed token, uint256 maxBalance);
    event EnableYield(address indexed token, address indexed yield, uint128 buffer, uint96 dust, uint256 maxInvested);
    event UpdateYield(address indexed token, address indexed yield, uint128 buffer, uint96 dust, uint256 maxInvested);
    event DisableYield(address indexed token, address indexed yield);

    event Invest(address indexed token, address indexed yield, uint256 amount);
    event Withdraw(address indexed token, address indexed yield, uint256 amount);
    event Farm(address indexed token, address indexed yield, uint256 amount);
    event FarmExtra(address indexed token, address indexed yield);

    event Buy(address indexed token, address indexed user, uint256 amountIn, uint256 amountOut);
    event Sell(address indexed token, address indexed user, uint256 amountIn, uint256 amountOut);
    event Swap(address indexed inToken, address outToken, address indexed user, uint256 amountIn, uint256 amountOut);
    event Give(address indexed token, uint256 amount);

    constructor(address _bobToken) {
        require(Address.isContract(_bobToken), "BobVault: not a contract");
        bobToken = IERC20(_bobToken);
        _transferOwnership(address(0));
    }

    /**
     * @dev Tells if given token address belongs to one of the whitelisted collaterals.
     * @param _token address of the token contract.
     * @return true, if token is a supported collateral.
     */
    function isCollateral(address _token) external view returns (bool) {
        return collateral[_token].price > 0;
    }

    /**
     * @dev Tells the balance-related stats for the specific collateral.
     * @param _token address of the token contract.
     * @return res balance stats struct.
     */
    function stat(address _token) external returns (Stat memory res) {
        Collateral storage token = collateral[_token];
        require(token.price > 0, "BobVault: unsupported collateral");

        res.total = IERC20(_token).balanceOf(address(this));
        res.required = token.balance;
        if (token.yield != address(0)) {
            res.total += _delegateInvestedAmount(token.yield, _token);
            res.required += token.dust;
        }
        res.farmed = res.total - res.required;
    }

    /**
     * @dev Adds a new collateral token.
     * Any tokens with reentrant transfers, such as an ERC777 token, MUST NOT be used as collateral. Otherwise
     * it could lead to inconsistent event orderings or potentially more severe issues.
     * Callable only by the contract owner / proxy admin.
     * @param _token address of added collateral token. Token can be added only once.
     * @param _collateral added collateral settings.
     */
    function addCollateral(address _token, Collateral calldata _collateral) external onlyOwner {
        Collateral storage token = collateral[_token];
        require(token.price == 0, "BobVault: already initialized collateral");

        require(_collateral.price > 0, "BobVault: invalid price");
        require(_collateral.inFee <= MAX_FEE, "BobVault: invalid inFee");
        require(_collateral.outFee <= MAX_FEE, "BobVault: invalid outFee");

        require(_collateral.maxBalance <= type(uint128).max, "BobVault: max balance too large");

        emit UpdateFees(_token, _collateral.inFee, _collateral.outFee);
        emit UpdateMaxBalance(_token, _collateral.maxBalance);

        (token.price, token.inFee, token.outFee, token.maxBalance) =
            (_collateral.price, _collateral.inFee, _collateral.outFee, _collateral.maxBalance);

        if (_collateral.yield != address(0)) {
            _enableCollateralYield(
                _token, _collateral.yield, _collateral.buffer, _collateral.dust, _collateral.maxInvested
            );
        }

        emit AddCollateral(_token, _collateral.price);
    }

    /**
     * @dev Enables yield-earning on the particular collateral token.
     * Callable only by the contract owner / proxy admin.
     * In order to change yield provider for already yield-enabled tokens,
     * disableCollateralYield should be called first.
     * @param _token address of the collateral token.
     * @param _yield address of the yield provider contract.
     * @param _buffer amount of non-invested collateral.
     * @param _dust small amount of non-withdrawable yield.
     * @param _maxInvested max amount to be invested.
     */
    function enableCollateralYield(
        address _token,
        address _yield,
        uint128 _buffer,
        uint96 _dust,
        uint256 _maxInvested
    )
        external
        onlyOwner
    {
        Collateral storage token = collateral[_token];
        require(token.price > 0, "BobVault: unsupported collateral");
        require(token.yield == address(0), "BobVault: yield already enabled");

        _enableCollateralYield(_token, _yield, _buffer, _dust, _maxInvested);
    }

    /**
     * @dev Updates yield-earning parameters on the particular collateral token.
     * Callable only by the contract owner / proxy admin.
     * @param _token address of the collateral token.
     * @param _buffer amount of non-invested collateral.
     * @param _dust small amount of non-withdrawable yield.
     * @param _maxInvested max amount to be invested.
     */
    function updateCollateralYield(
        address _token,
        uint128 _buffer,
        uint96 _dust,
        uint256 _maxInvested
    )
        external
        onlyOwner
    {
        Collateral storage token = collateral[_token];
        require(token.price > 0, "BobVault: unsupported collateral");
        address yield = token.yield;
        require(yield != address(0), "BobVault: yield not enabled");

        (token.buffer, token.dust, token.maxInvested) = (_buffer, _dust, _maxInvested);

        _investExcess(_token, yield, _buffer, _maxInvested);

        emit UpdateYield(_token, yield, _buffer, _dust, _maxInvested);
    }

    /**
     * @dev Internal function that enables yield-earning on the particular collateral token.
     * Delegate-calls initialize and invest functions on the yield provider contract.
     * @param _token address of the collateral token.
     * @param _yield address of the yield provider contract.
     * @param _buffer amount of non-invested collateral.
     * @param _dust small amount of non-withdrawable yield.
     * @param _maxInvested max amount to be invested.
     */
    function _enableCollateralYield(
        address _token,
        address _yield,
        uint128 _buffer,
        uint96 _dust,
        uint256 _maxInvested
    )
        internal
    {
        Collateral storage token = collateral[_token];

        require(Address.isContract(_yield), "BobVault: yield not a contract");

        (token.buffer, token.dust, token.yield, token.maxInvested) = (_buffer, _dust, _yield, _maxInvested);
        _delegateInitialize(_yield, _token);

        _investExcess(_token, _yield, _buffer, _maxInvested);

        emit EnableYield(_token, _yield, _buffer, _dust, _maxInvested);
    }

    /**
     * @dev Disable yield-earning on the particular collateral token.
     * Callable only by the contract owner / proxy admin.
     * Yield can only be disabled on collaterals on which enableCollateralYield was called first.
     * Delegate-calls investedAmount, withdraw and exit functions on the yield provider contract.
     * @param _token address of the collateral token.
     */
    function disableCollateralYield(address _token) external onlyOwner {
        Collateral storage token = collateral[_token];
        require(token.price > 0, "BobVault: unsupported collateral");
        address yield = token.yield;
        require(yield != address(0), "BobVault: yield not enabled");

        (token.buffer, token.dust, token.yield) = (0, 0, address(0));

        uint256 invested = _delegateInvestedAmount(yield, _token);
        _delegateWithdraw(yield, _token, invested);
        emit Withdraw(_token, yield, invested);

        _delegateExit(yield, _token);
        emit DisableYield(_token, yield);
    }

    /**
     * @dev Updates in/out fees on the particular collateral.
     * Callable only by the contract owner / proxy admin.
     * Can only be called on already whitelisted collaterals.
     * @param _token address of the collateral token.
     * @param _inFee fee for TOKEN->BOB buys (or 1 ether to pause buys).
     * @param _outFee fee for BOB->TOKEN sells (or 1 ether to pause sells).
     */
    function setCollateralFees(address _token, uint64 _inFee, uint64 _outFee) external onlyOwner {
        Collateral storage token = collateral[_token];
        require(token.price > 0, "BobVault: unsupported collateral");

        require(_inFee <= MAX_FEE || _inFee == 1 ether, "BobVault: invalid inFee");
        require(_outFee <= MAX_FEE || _outFee == 1 ether, "BobVault: invalid outFee");

        (token.inFee, token.outFee) = (_inFee, _outFee);

        emit UpdateFees(_token, _inFee, _outFee);
    }

    /**
     * @dev Updates max balance of the particular collateral.
     * Callable only by the contract owner / proxy admin.
     * Can only be called on already whitelisted collaterals.
     * @param _token address of the collateral token.
     * @param _maxBalance new max balance of the particular collateral.
     */
    function setMaxBalance(address _token, uint256 _maxBalance) external onlyOwner {
        Collateral storage token = collateral[_token];
        require(token.price > 0, "BobVault: unsupported collateral");
        require(_maxBalance <= type(uint128).max, "BobVault: max balance too large");

        token.maxBalance = _maxBalance;

        emit UpdateMaxBalance(_token, _maxBalance);
    }

    /**
     * @dev Sets address of the yield receiver account.
     * Callable only by the contract owner / proxy admin.
     * Nominated address will be capable of withdrawing accumulated fees and generated yields by calling farm function.
     * @param _yieldAdmin new yield receiver address.
     */
    function setYieldAdmin(address _yieldAdmin) external onlyOwner {
        yieldAdmin = _yieldAdmin;
    }

    /**
     * @dev Sets address of the invest manager.
     * Callable only by the contract owner / proxy admin.
     * Nominated address will be only capable of investing excess collateral tokens by calling invest function.
     * @param _investAdmin new invest manager address.
     */
    function setInvestAdmin(address _investAdmin) external onlyOwner {
        investAdmin = _investAdmin;
    }

    /**
     * @dev Estimates amount of received tokens, when swapping some amount of inToken for outToken.
     * @param _inToken address of the sold token. Can be either the address of BOB token or one of whitelisted collaterals.
     * @param _outToken address of the bought token. Can be either the address of BOB token or one of whitelisted collaterals.
     * @param _inAmount amount of sold _inToken.
     * @return estimated amount of received _outToken.
     */
    function getAmountOut(address _inToken, address _outToken, uint256 _inAmount) public view returns (uint256) {
        require(_inToken != _outToken, "BobVault: tokens should be different");

        if (_outToken == address(bobToken)) {
            Collateral storage token = collateral[_inToken];
            require(token.price > 0, "BobVault: unsupported collateral");
            require(token.inFee <= MAX_FEE, "BobVault: collateral deposit suspended");

            uint256 fee = _inAmount * uint256(token.inFee) / 1 ether;
            uint256 sellAmount = _inAmount - fee;
            uint256 outAmount = sellAmount * 1 ether / token.price;

            require(outAmount <= bobToken.balanceOf(address(this)), "BobVault: exceeds available liquidity");
            require(token.balance + sellAmount <= token.maxBalance, "BobVault: exceeds max balance");

            return outAmount;
        } else if (_inToken == address(bobToken)) {
            Collateral storage token = collateral[_outToken];
            require(token.price > 0, "BobVault: unsupported collateral");
            require(token.outFee <= MAX_FEE, "BobVault: collateral withdrawal suspended");

            uint256 outAmount = _inAmount * token.price / 1 ether;
            // collected outFee should be available for withdrawal after the swap,
            // so collateral liquidity is checked before subtracting the fee
            require(token.balance >= outAmount, "BobVault: insufficient liquidity for collateral");
            outAmount -= outAmount * uint256(token.outFee) / 1 ether;

            return outAmount;
        } else {
            Collateral storage inToken = collateral[_inToken];
            Collateral storage outToken = collateral[_outToken];
            require(inToken.price > 0, "BobVault: unsupported input collateral");
            require(outToken.price > 0, "BobVault: unsupported output collateral");
            require(inToken.inFee <= MAX_FEE, "BobVault: collateral deposit suspended");
            require(outToken.outFee <= MAX_FEE, "BobVault: collateral withdrawal suspended");

            uint256 fee = _inAmount * uint256(inToken.inFee) / 1 ether;
            uint256 sellAmount = _inAmount - fee;
            uint256 bobAmount = sellAmount * 1 ether / inToken.price;

            uint256 outAmount = bobAmount * outToken.price / 1 ether;
            // collected outFee should be available for withdrawal after the swap,
            // so collateral liquidity is checked before subtracting the fee
            require(outToken.balance >= outAmount, "BobVault: insufficient liquidity for collateral");
            outAmount -= outAmount * uint256(outToken.outFee) / 1 ether;

            require(inToken.balance + sellAmount <= inToken.maxBalance, "BobVault: exceeds max balance");

            return outAmount;
        }
    }

    /**
     * @dev Estimates amount of tokens that should be sold, in order to get required amount of out bought tokens,
     * when swapping inToken for outToken.
     * @param _inToken address of the sold token. Can be either the address of BOB token or one of whitelisted collaterals.
     * @param _outToken address of the bought token. Can be either the address of BOB token or one of whitelisted collaterals.
     * @param _outAmount desired amount of bought _outToken.
     * @return estimated amount of _inToken that should be sold.
     */
    function getAmountIn(address _inToken, address _outToken, uint256 _outAmount) public view returns (uint256) {
        require(_inToken != _outToken, "BobVault: tokens should be different");

        if (_outToken == address(bobToken)) {
            Collateral storage token = collateral[_inToken];
            require(token.price > 0, "BobVault: unsupported collateral");
            require(token.inFee <= MAX_FEE, "BobVault: collateral deposit suspended");

            require(_outAmount <= bobToken.balanceOf(address(this)), "BobVault: exceeds available liquidity");

            uint256 sellAmount = _outAmount * token.price / 1 ether;
            uint256 inAmount = sellAmount * 1 ether / (1 ether - uint256(token.inFee));

            require(token.balance + sellAmount <= token.maxBalance, "BobVault: exceeds max balance");

            return inAmount;
        } else if (_inToken == address(bobToken)) {
            Collateral storage token = collateral[_outToken];
            require(token.price > 0, "BobVault: unsupported collateral");
            require(token.outFee <= MAX_FEE, "BobVault: collateral withdrawal suspended");

            uint256 buyAmount = _outAmount * 1 ether / (1 ether - uint256(token.outFee));
            // collected outFee should be available for withdrawal after the swap,
            // so collateral liquidity is checked before subtracting the fee
            require(token.balance >= buyAmount, "BobVault: insufficient liquidity for collateral");

            uint256 inAmount = buyAmount * 1 ether / token.price;

            return inAmount;
        } else {
            Collateral storage inToken = collateral[_inToken];
            Collateral storage outToken = collateral[_outToken];
            require(inToken.price > 0, "BobVault: unsupported input collateral");
            require(outToken.price > 0, "BobVault: unsupported output collateral");
            require(inToken.inFee <= MAX_FEE, "BobVault: collateral deposit suspended");
            require(outToken.outFee <= MAX_FEE, "BobVault: collateral withdrawal suspended");

            uint256 buyAmount = _outAmount * 1 ether / (1 ether - uint256(outToken.outFee));
            // collected outFee should be available for withdrawal after the swap,
            // so collateral liquidity is checked before subtracting the fee
            require(outToken.balance >= buyAmount, "BobVault: insufficient liquidity for collateral");

            uint256 bobAmount = buyAmount * 1 ether / outToken.price;
            uint256 sellAmount = bobAmount * inToken.price / 1 ether;
            uint256 inAmount = sellAmount * 1 ether / (1 ether - uint256(inToken.inFee));

            require(inToken.balance + sellAmount <= inToken.maxBalance, "BobVault: exceeds max balance");

            return inAmount;
        }
    }

    /**
     * @dev Buys BOB with one of the collaterals at a fixed rate.
     * Collateral token should be pre-approved to the vault contract.
     * Swap will revert, if order cannot be fully filled due to the lack of BOB tokens.
     * Swapped amount of collateral will be subject to relevant inFee.
     * @param _token address of the sold collateral token.
     * @param _amount amount of sold collateral.
     * @return amount of received _outToken, i.e. getAmountOut(_token, BOB, _amount).
     */
    function buy(address _token, uint256 _amount) external returns (uint256) {
        Collateral storage token = collateral[_token];
        require(token.price > 0, "BobVault: unsupported collateral");
        require(token.inFee <= MAX_FEE, "BobVault: collateral deposit suspended");

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 fee = _amount * uint256(token.inFee) / 1 ether;
        uint256 sellAmount = _amount - fee;
        uint256 buyAmount = sellAmount * 1 ether / token.price;
        unchecked {
            require(token.balance + sellAmount <= token.maxBalance, "BobVault: exceeds max balance");
            token.balance += uint128(sellAmount);
        }

        bobToken.transfer(msg.sender, buyAmount);

        emit Buy(_token, msg.sender, _amount, buyAmount);

        return buyAmount;
    }

    /**
     * @dev Sells BOB for one of the collaterals at a fixed rate.
     * BOB token should be pre-approved to the vault contract.
     * Swap will revert, if order cannot be fully filled due to the lack of particular collateral.
     * Swapped amount of collateral will be subject to relevant outFee.
     * @param _token address of the received collateral token.
     * @param _amount amount of sold BOB tokens.
     * @return amount of received _outToken, i.e. getAmountOut(BOB, _token, _amount).
     */
    function sell(address _token, uint256 _amount) external returns (uint256) {
        Collateral storage token = collateral[_token];
        require(token.price > 0, "BobVault: unsupported collateral");
        require(token.outFee <= MAX_FEE, "BobVault: collateral withdrawal suspended");

        bobToken.transferFrom(msg.sender, address(this), _amount);

        uint256 buyAmount = _amount * token.price / 1 ether;
        // collected outFee should be available for withdrawal after the swap,
        // so collateral liquidity is checked before subtracting the fee
        require(token.balance >= buyAmount, "BobVault: insufficient liquidity for collateral");
        unchecked {
            token.balance -= uint128(buyAmount);
        }

        buyAmount -= buyAmount * uint256(token.outFee) / 1 ether;

        _transferOut(_token, msg.sender, buyAmount);

        emit Sell(_token, msg.sender, _amount, buyAmount);

        return buyAmount;
    }

    /**
     * @dev Buys one collateral with another collateral by virtually routing swap through BOB token at a fixed rate.
     * Collateral token should be pre-approved to the vault contract.
     * Identical to sequence of buy+sell calls,
     * with the exception that swap does not require presence of the BOB liquidity and has a much lower gas usage.
     * Swap will revert, if order cannot be fully filled due to the lack of particular collateral.
     * Swapped amount of collateral will be subject to relevant inFee and outFee.
     * @param _inToken address of the sold collateral token.
     * @param _outToken address of the bought collateral token.
     * @param _amount amount of sold collateral.
     * @return amount of received _outToken, i.e. getAmountOut(_inToken, _outToken, _amount).
     */
    function swap(address _inToken, address _outToken, uint256 _amount) external returns (uint256) {
        Collateral storage inToken = collateral[_inToken];
        Collateral storage outToken = collateral[_outToken];
        require(_inToken != _outToken, "BobVault: tokens should be different");
        require(inToken.price > 0, "BobVault: unsupported input collateral");
        require(outToken.price > 0, "BobVault: unsupported output collateral");
        require(inToken.inFee <= MAX_FEE, "BobVault: collateral deposit suspended");
        require(outToken.outFee <= MAX_FEE, "BobVault: collateral withdrawal suspended");

        IERC20(_inToken).safeTransferFrom(msg.sender, address(this), _amount);

        // buy virtual bob

        uint256 fee = _amount * uint256(inToken.inFee) / 1 ether;
        uint256 sellAmount = _amount - fee;
        unchecked {
            require(inToken.balance + sellAmount <= inToken.maxBalance, "BobVault: exceeds max balance");
            inToken.balance += uint128(sellAmount);
        }
        uint256 bobAmount = sellAmount * 1 ether / inToken.price;

        // sell virtual bob

        uint256 buyAmount = bobAmount * outToken.price / 1 ether;
        // collected outFee should be available for withdrawal after the swap,
        // so collateral liquidity is checked before subtracting the fee
        require(outToken.balance >= buyAmount, "BobVault: insufficient liquidity for collateral");
        unchecked {
            outToken.balance -= uint128(buyAmount);
        }

        buyAmount -= buyAmount * uint256(outToken.outFee) / 1 ether;

        _transferOut(_outToken, msg.sender, buyAmount);

        emit Swap(_inToken, _outToken, msg.sender, _amount, buyAmount);

        return buyAmount;
    }

    /**
     * @dev Invests excess tokens into the yield provider.
     * Callable only by the contract owner / proxy admin / invest admin.
     * @param _token address of collateral to invest.
     */
    function invest(address _token) external {
        require(msg.sender == investAdmin || _isOwner(), "BobVault: not authorized");

        Collateral storage token = collateral[_token];
        require(token.price > 0, "BobVault: unsupported collateral");

        _investExcess(_token, token.yield, token.buffer, token.maxInvested);
    }

    /**
     * @dev Internal function for investing excess tokens into the yield provider.
     * Delegate-calls invest function on the yield provider contract.
     * @param _token address of collateral to invest.
     */
    function _investExcess(address _token, address _yield, uint256 _buffer, uint256 _maxInvested) internal {
        uint256 balance = IERC20(_token).balanceOf(address(this));

        if (balance > _buffer) {
            uint256 value = balance - _buffer;

            uint256 invested = _delegateInvestedAmount(_yield, _token);
            if (invested < _maxInvested) {
                if (value > _maxInvested - invested) {
                    value = _maxInvested - invested;
                }
                _delegateInvest(_yield, _token, value);
                emit Invest(_token, _yield, value);
            }
        }
    }

    /**
     * @dev Collects accumulated fees and generated yield for the specific collateral.
     * Callable only by the contract owner / proxy admin / yield admin.
     * @param _token address of collateral to collect fess / interest for.
     */
    function farm(address _token) external returns (uint256) {
        require(msg.sender == yieldAdmin || _isOwner(), "BobVault: not authorized");

        Collateral storage token = collateral[_token];
        require(token.price > 0, "BobVault: unsupported collateral");

        uint256 currentBalance = IERC20(_token).balanceOf(address(this));
        uint256 requiredBalance = token.balance;

        if (token.yield != address(0)) {
            currentBalance += _delegateInvestedAmount(token.yield, _token);
            requiredBalance += token.dust;
        }

        if (requiredBalance >= currentBalance) {
            return 0;
        }

        uint256 value = currentBalance - requiredBalance;
        _transferOut(_token, msg.sender, value);
        emit Farm(_token, token.yield, value);

        return value;
    }

    /**
     * @dev Collects extra rewards from the specific yield provider (e.g. COMP tokens).
     * Callable only by the contract owner / proxy admin / yield admin.
     * @param _token address of collateral to collect rewards for.
     * @param _data arbitrary extra data required for rewards collection.
     */
    function farmExtra(address _token, bytes calldata _data) external returns (bytes memory returnData) {
        require(msg.sender == yieldAdmin || _isOwner(), "BobVault: not authorized");

        Collateral memory token = collateral[_token];
        require(token.price > 0, "BobVault: unsupported collateral");

        returnData = _delegateFarmExtra(token.yield, _token, msg.sender, _data);

        emit FarmExtra(_token, token.yield);
    }

    /**
     * @dev Top up balance of the particular collateral.
     * Can be used when migrating liquidity from other sources (e.g. from Uniswap).
     * @param _token address of collateral to top up.
     * @param _amount amount of collateral to add.
     */
    function give(address _token, uint256 _amount) external {
        Collateral storage token = collateral[_token];
        require(token.price > 0, "BobVault: unsupported collateral");

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        unchecked {
            require(token.balance + _amount <= type(uint128).max, "BobVault: amount too large");
            token.balance += uint128(_amount);
        }

        emit Give(_token, _amount);
    }

    /**
     * @dev Withdraws BOB liquidity.
     * Can be used when migrating BOB liquidity into other pools. (e.g. to a different BobVault contract).
     * Will withdraw at most _value tokens, but no more than the current available balance.
     * @param _to address of BOB tokens receiver.
     * @param _value max amount of BOB tokens to withdraw.
     */
    function reclaim(address _to, uint256 _value) external onlyOwner {
        uint256 balance = bobToken.balanceOf(address(this));
        uint256 value = balance > _value ? _value : balance;
        if (value > 0) {
            bobToken.transfer(_to, value);
        }
    }

    /**
     * @dev Internal function for doing collateral payouts.
     * Delegate-calls investedAmount and withdraw functions on the yield provider contract.
     * Seamlessly withdraws the necessary amount of invested liquidity, when needed.
     * @param _token address of withdrawn collateral token.
     * @param _to address of withdrawn collateral receiver.
     * @param _value amount of collateral tokens to withdraw.
     */
    function _transferOut(address _token, address _to, uint256 _value) internal {
        Collateral storage token = collateral[_token];

        uint256 balance = IERC20(_token).balanceOf(address(this));

        if (_value > balance) {
            address yield = token.yield;
            require(yield != address(0), "BobVault: yield not enabled");

            uint256 invested = _delegateInvestedAmount(yield, _token);
            uint256 withdrawValue = token.buffer + _value - balance;
            if (invested < withdrawValue) {
                withdrawValue = invested;
            }
            _delegateWithdraw(token.yield, _token, withdrawValue);
            emit Withdraw(_token, yield, withdrawValue);
        }

        IERC20(_token).safeTransfer(_to, _value);
    }

    /**
     * @dev Tells if caller is the contract owner.
     * Gives ownership rights to the proxy admin as well.
     * @return true, if caller is the contract owner or proxy admin.
     */
    function _isOwner() internal view override returns (bool) {
        return super._isOwner() || _admin() == _msgSender();
    }
}