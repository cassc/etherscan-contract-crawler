// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@prb/math/contracts/PRBMathUD60x18.sol";

import "../interfaces/ISnacksBase.sol";

abstract contract SnacksBase is ISnacksBase, IERC20Metadata, Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using PRBMathUD60x18 for uint256;
    
    address private constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 private constant ONE_SNACK = 1e18;
    uint256 private constant MINT_FEE_PERCENT = 500;
    uint256 private constant REDEEM_FEE_PERCENT = 1000;
    uint256 internal constant BASE_PERCENT = 10000;
    
    address public payToken;
    address public pulse;
    address public poolRewardDistributor;
    address public seniorage;
    address public authority;
    uint256 public adjustmentFactor = PRBMathUD60x18.fromUint(1);
    uint256 internal _totalSupply;
    uint256 private immutable _step;
    uint256 private immutable _correlationFactor;
    uint256 private immutable _totalSupplyFactor;
    uint256 private immutable _pulseFeePercent;
    uint256 private immutable _poolRewardDistributorFeePercent;
    uint256 private immutable _seniorageFeePercent;
    string private _name;
    string private _symbol;
    
    mapping(address => uint256) internal _adjustedBalances;
    mapping(address => mapping(address => uint256)) private _allowedAmount;
    EnumerableSet.AddressSet internal _excludedHolders;
    
    event Buy(
        address indexed buyer,
        uint256 totalSupplyBefore,
        uint256 buyTokenAmount,
        uint256 buyTokenAmountToBuyer,
        uint256 fee,
        uint256 payTokenAmount
    );
    event Redeem(
        address indexed seller,
        uint256 totalSupplyAfter,
        uint256 buyTokenAmount,
        uint256 buyTokenAmountToRedeem,
        uint256 fee,
        uint256 payTokenAmountToSeller
    );
    event RewardForHolders(uint256 indexed reward);
    
    modifier onlyAuthority {
        require(
            msg.sender == authority,
            "SnacksBase: caller is not authorised"
        );
        _;
    }

    modifier validOwnerAndSpender(address owner_, address spender_) {
        require(
            owner_ != address(0), 
            "SnacksBase: approve from the zero address");
        require(
            spender_ != address(0), 
            "SnacksBase: approve to the zero address"
        );
        _;
    }
    
    
    /**
    * @param step_ An arithmetic progression step.
    * @param correlationFactor_ The transition from Snacks/BtcSnacks/EthSnacks token 
    * to Zoinks/Binance-Peg BTCB/Binance-Peg Ethereum token is made by
    * the counted number divided by the `correlationFactor` 
    * @param totalSupplyFactor_ `_totalSupply` is divided by the `totalSupplyFactor_` to get 
    * the cost of the last Snacks/BtcSnacks/EthSnacks token purchased.
    * @param pulseFeePercent_ Percent of the Pulse contract from the commission for 12 hours.
    * @param poolRewardDistributorFeePercent_ Percent of the PoolRewardDistributor contract 
    * from the commission for 12 hours.
    * @param seniorageFeePercent_ Percent of the Seniorage contract from the commission for 12 hours.
    * @param name_ Token name.
    * @param symbol_ Token symbol.
    */
    constructor(
        uint256 step_,
        uint256 correlationFactor_,
        uint256 totalSupplyFactor_,
        uint256 pulseFeePercent_,
        uint256 poolRewardDistributorFeePercent_,
        uint256 seniorageFeePercent_,
        string memory name_,
        string memory symbol_
    ) {
        _step = step_;
        _correlationFactor = correlationFactor_;
        _totalSupplyFactor = totalSupplyFactor_;
        _pulseFeePercent = pulseFeePercent_;
        _poolRewardDistributorFeePercent = poolRewardDistributorFeePercent_;
        _seniorageFeePercent = seniorageFeePercent_;
        _name = name_;
        _symbol = symbol_;
    }
    
    /**
    * @notice Configures the contract.
    * @dev Could be called by the owner in case of resetting addresses.
    * @param payToken_ Zoinks/Binance-Peg BTCB/Binance-Peg Ethereum token address.
    * @param pulse_ Pulse contract address.
    * @param poolRewardDistributor_ PoolRewardDistributor contract address.
    * @param seniorage_ Seniorage contract address.
    * @param snacksPool_ SnacksPool contract address.
    * @param pancakeSwapPool_ PancakeSwapPool contract address.
    * @param lunchBox_ LunchBox contract address.
    * @param authority_ Authorised address.
    */
    function _configure(
        address payToken_,
        address pulse_,
        address poolRewardDistributor_,
        address seniorage_,
        address snacksPool_,
        address pancakeSwapPool_,
        address lunchBox_,
        address authority_
    )
        internal
        onlyOwner
    {
        payToken = payToken_;
        pulse = pulse_;
        poolRewardDistributor = poolRewardDistributor_;
        seniorage = seniorage_;
        authority = authority_;
        for (uint256 i = 0; i < _excludedHolders.length(); i++) {
            address excludedHolder = _excludedHolders.at(i);
            _excludedHolders.remove(excludedHolder);
        }
        _excludedHolders.add(payToken_);
        _excludedHolders.add(pulse_);
        _excludedHolders.add(poolRewardDistributor_);
        _excludedHolders.add(seniorage_);
        _excludedHolders.add(snacksPool_);
        _excludedHolders.add(pancakeSwapPool_);
        _excludedHolders.add(lunchBox_);
        _excludedHolders.add(address(this));
        _excludedHolders.add(address(0));
        _excludedHolders.add(DEAD_ADDRESS);
    }

    /**
    * @notice Triggers stopped state.
    * @dev Could be called by the owner in case of resetting addresses.
    */
    function pause() external onlyOwner {
        _pause();
    }

    /**
    * @notice Returns to normal state.
    * @dev Could be called by the owner in case of resetting addresses.
    */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
    * @notice Distributes fees between the contracts and holders.
    * @dev Called by the authorised address once every 12 hours.
    */
    function distributeFee() external whenNotPaused onlyAuthority {
        uint256 undistributedFee = balanceOf(address(this));
        _beforeDistributeFee(undistributedFee);
        if (undistributedFee != 0) {
            _transfer(
                address(this),
                pulse,
                undistributedFee * _pulseFeePercent / BASE_PERCENT
            );
            _transfer(
                address(this),
                poolRewardDistributor,
                undistributedFee * _poolRewardDistributorFeePercent / BASE_PERCENT
            );
            _transfer(
                address(this),
                seniorage,
                undistributedFee * _seniorageFeePercent / BASE_PERCENT
            );
        }
        _afterDistributeFee(balanceOf(address(this)));
    }
    
    /**
    * @notice Mints Snacks/BtcSnacks/EthSnacks token.
    * @dev The fee charged from the user is 5%. Thus, he will receive 95% of `buyTokenAmount_`.
    * @param buyTokenAmount_ Amount of Snacks/BtcSnacks/EthSnacks token to mint.
    * @return Amount of Snacks/BtcSnacks/EthSnacks token received.
    */
    function mintWithBuyTokenAmount(
        uint256 buyTokenAmount_
    ) 
        external 
        whenNotPaused
        nonReentrant 
        returns (uint256)
    {
        uint256 payTokenAmount = calculatePayTokenAmountOnMint(buyTokenAmount_);
        IERC20(payToken).safeTransferFrom(msg.sender, address(this), payTokenAmount);
        uint256 fee = buyTokenAmount_ * MINT_FEE_PERCENT / BASE_PERCENT;
        _mint(address(this), fee);
        _mint(msg.sender, buyTokenAmount_ - fee);
        emit Buy(
            msg.sender,
            _totalSupply - buyTokenAmount_,
            buyTokenAmount_,
            buyTokenAmount_ - fee,
            fee,
            payTokenAmount
        );
        return buyTokenAmount_ - fee;
    }
    
    /**
    * @notice Mints Snacks/BtcSnacks/EthSnacks token.
    * @dev The fee charged from the user is 5%. Thus, he will receive 95% of calculated `buyTokenAmount`.
    * @param payTokenAmount_ Amount of Zoinks/Binance-Peg BTCB/Binance-Peg Ethereum token to spend.
    * @return Amount of Snacks/BtcSnacks/EthSnacks token received.
    */
    function mintWithPayTokenAmount(
        uint256 payTokenAmount_
    ) 
        external 
        whenNotPaused
        nonReentrant 
        returns (uint256)
    {
        uint256 buyTokenAmount = calculateBuyTokenAmountOnMint(payTokenAmount_);
        IERC20(payToken).safeTransferFrom(msg.sender, address(this), payTokenAmount_);
        uint256 fee = buyTokenAmount * MINT_FEE_PERCENT / BASE_PERCENT;
        _mint(address(this), fee);
        _mint(msg.sender, buyTokenAmount - fee);
        emit Buy(
            msg.sender,
            _totalSupply - buyTokenAmount,
            buyTokenAmount,
            buyTokenAmount - fee,
            fee,
            payTokenAmount_
        );
        return buyTokenAmount - fee;
    }
    
    /**
    * @notice Redeems Snacks/BtcSnacks/EthSnacks token.
    * @dev The fee charged from the user is 10%. Thus, he will receive 
    * Zoinks/Binance-Peg BTCB/Binance-Peg Ethereum token for 90% of `buyTokenAmount_`.
    * @param buyTokenAmount_ Amount of Snacks/BtcSnacks/EthSnacks token to redeem.
    * @return Amount of Zoinks/Binance-Peg BTCB/Binance-Peg Ethereum token received.
    */
    function redeem(
        uint256 buyTokenAmount_
    ) 
        external 
        whenNotPaused
        nonReentrant 
        returns (uint256)
    {
        uint256 fee = buyTokenAmount_ * REDEEM_FEE_PERCENT / BASE_PERCENT;
        _transfer(msg.sender, address(this), fee);
        uint256 payTokenAmount = calculatePayTokenAmountOnRedeem(buyTokenAmount_ - fee);
        IERC20(payToken).safeTransfer(msg.sender, payTokenAmount);
        _burn(msg.sender, buyTokenAmount_ - fee);
        emit Redeem(
            msg.sender,
            _totalSupply,
            buyTokenAmount_,
            buyTokenAmount_ - fee,
            fee,
            payTokenAmount
        );
        return payTokenAmount;
    }
    
    /**
    * @notice Sets `amount_` as the allowance of `spender_` over the caller's tokens.
    * @dev Caller and `spender_` cannot be zero addresses.
    * @param spender_ Spender address.
    * @param amount_ Amount to approve.
    * @return Boolean value indicating whether the operation succeeded.
    */
    function approve(
        address spender_, 
        uint256 amount_
    ) 
        external 
        override
        whenNotPaused
        validOwnerAndSpender(msg.sender, spender_)
        returns (bool) 
    {
        _allowedAmount[msg.sender][spender_] = amount_;
        emit Approval(msg.sender, spender_, amount_);
        return true;
    }
    
    /**
    * @notice Atomically increases the allowance granted to `spender_` by the caller.
    * @dev Caller and `spender_` cannot be zero addresses.
    * @param spender_ Spender address.
    * @param amount_ Amount to increase.
    * @return Boolean value indicating whether the operation succeeded.
    */
    function increaseAllowance(
        address spender_,
        uint256 amount_
    )
        external
        whenNotPaused
        validOwnerAndSpender(msg.sender, spender_)
        returns (bool)
    {
        _allowedAmount[msg.sender][spender_] += amount_;
        emit Approval(msg.sender, spender_, _allowedAmount[msg.sender][spender_]);
        return true;
    }
    
    /**
    * @notice Atomically decreases the allowance granted to `spender_` by the caller.
    * @dev Caller and `spender_` cannot be zero addresses.
    * @param spender_ Spender address.
    * @param amount_ Amount to decrease.
    * @return Boolean value indicating whether the operation succeeded.
    */
    function decreaseAllowance(
        address spender_,
        uint256 amount_
    )
        external
        whenNotPaused
        validOwnerAndSpender(msg.sender, spender_)
        returns (bool)
    {
        uint256 oldAmount = _allowedAmount[msg.sender][spender_];
        if (amount_ >= oldAmount) {
            _allowedAmount[msg.sender][spender_] = 0;
        } else {
            _allowedAmount[msg.sender][spender_] = oldAmount - amount_;
        }
        emit Approval(msg.sender, spender_, _allowedAmount[msg.sender][spender_]);
        return true;
    }
    
    /**
    * @notice Moves `amount_` tokens from the caller's account to `to_`.
    * @dev `to_` cannot be the zero address. The caller must have a balance of at least `amount_`.
    * @param to_ Address to which tokens are sent.
    * @param amount_ Amount to transfer.
    * @return Boolean value indicating whether the operation succeeded.
    */
    function transfer(
        address to_,
        uint256 amount_
    )
        external
        override
        whenNotPaused
        returns (bool)
    {
        _transfer(msg.sender, to_, amount_);
        return true;
    }
    
    /**
    * @notice Moves `amount_` tokens from `from_` to `to_` using the
    * allowance mechanism. `amount_` is then deducted from the caller's allowance.
    * @dev `from_` and `to_` cannot be the zero address. `from_` must have a balance of at least `amount_`.
    * The caller must have allowance for `from_`'s tokens of at least `amount_`.
    * @param from_ Address from which tokens are sent.
    * @param to_ Address to which tokens are sent.
    * @param amount_ Amount to transfer.
    */
    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    )
        external
        override
        whenNotPaused
        returns (bool)
    {
        _allowedAmount[from_][msg.sender] -= amount_;
        _transfer(from_, to_, amount_);
        return true;
    }

    /**
    * @notice Adds an account to the excluded holders list.
    * @dev The excluded holders don't receive fee for holding. 
    * @param account_ Account address.
    */
    function addToExcludedHolders(address account_) external onlyOwner {
        require(
            _excludedHolders.add(account_),
            "SnacksBase: already excluded"
        );
        _adjustedBalances[account_] = _adjustedBalances[account_].mul(adjustmentFactor);
    }

    /**
    * @notice Removes an account from excluded holders list.
    * @dev Not excluded holders do receive fee for holding. 
    * @param account_ Account address.
    */
    function removeFromExcludedHolders(address account_) external onlyOwner {
        require(
            _excludedHolders.remove(account_),
            "SnacksBase: not excluded"
        );
        _adjustedBalances[account_] = _adjustedBalances[account_].div(adjustmentFactor);
    }

    /**
    * @notice Checks whether the account is an excluded holder.
    * @dev If the account is an excluded holder then it doesn't receive fee for holding.
    * @param account_ Account address.
    * @return Boolean value indicating whether the account is excluded holder or not.
    */
    function isExcludedHolder(address account_) external view returns (bool) {
        return _excludedHolders.contains(account_);
    }

    /**
    * @notice Checks whether `buyTokenAmount_` is enough 
    * to buy Snacks/BtcSnacks/EthSnacks token at least on 1 wei 
    * of Zoinks/Binance-Peg BTCB/Binance-Peg Ethereum token.
    * @dev See description to `calculatePayTokenAmountOnMint()` function for math explanation.
    * @param buyTokenAmount_ Amount of Snacks/BtcSnacks/EthSnacks token to mint.
    * @return Boolean value indicating whether `buyTokenAmount_` is enough to buy
    * Snacks/BtcSnacks/EthSnacks token at least on 1 wei 
    * of Zoinks/Binance-Peg BTCB/Binance-Peg Ethereum token.
    */
    function sufficientBuyTokenAmountOnMint(
        uint256 buyTokenAmount_
    )
        external
        view
        returns (bool)
    {
        uint256 next = _totalSupply + ONE_SNACK;
        uint256 last = _totalSupply + buyTokenAmount_;
        return (next + last) * buyTokenAmount_ >= 2 * _correlationFactor;
    }
    
    /**
    * @notice Checks whether `payTokenAmount_` is above or 
    * equal to next Snacks/BtcSnacks/EthSnacks token price.
    * @dev See description to `calculateBuyTokenAmountOnMint()` function for math explanation.
    * @param payTokenAmount_ Amount of Zoinks/Binance-Peg BTCB/Binance-Peg Ethereum token to spend.
    * @return Boolean value indicating whether `payTokenAmount_` is above or equal to 
    * next Snacks/BtcSnacks/EthSnacks token price.
    */
    function sufficientPayTokenAmountOnMint(
        uint256 payTokenAmount_
    )
        external
        view
        returns (bool)
    {
        uint256 nextSnackPrice = _step + _totalSupply / _totalSupplyFactor;
        return payTokenAmount_ >= nextSnackPrice;
    }

    /**
    * @notice Checks whether `buyTokenAmount_` is enough 
    * to redeem Snacks/BtcSnacks/EthSnacks token at least on 1 wei 
    * of Zoinks/Binance-Peg BTCB/Binance-Peg Ethereum token.
    * @dev See description to `calculatePayTokenAmountOnRedeem()` function for math explanation.
    * @param buyTokenAmount_ Amount of Snacks/BtcSnacks/EthSnacks token to redeem.
    * @return Boolean value indicating whether `buyTokenAmount_` is enough to redeem
    * Snacks/BtcSnacks/EthSnacks token at least on 1 wei 
    * of Zoinks/Binance-Peg BTCB/Binance-Peg Ethereum token.
    */
    function sufficientBuyTokenAmountOnRedeem(
        uint256 buyTokenAmount_
    )
        external
        view
        returns (bool)
    {
        uint256 fee = buyTokenAmount_ * REDEEM_FEE_PERCENT / BASE_PERCENT;
        buyTokenAmount_ -= fee;
        uint256 start = _totalSupply - buyTokenAmount_ + ONE_SNACK;
        return (start + _totalSupply) * buyTokenAmount_ >= 2 * _correlationFactor;
    }
    
    /**
    * @notice Retrieves the amount of tokens in existence.
    * @dev The returned value is imperceptibly different from the real amount of tokens 
    * in existence because of the reflection mechanism.
    * @return Amount of tokens in existence.
    */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    
    /**
    * @notice Retrieves the remaining number of tokens that `spender_` will be
    * allowed to spend on behalf of `owner_` through `transferFrom()` function. This is
    * zero by default.
    * @dev This value changes when `approve()` or `transferFrom()` functions are called.
    * @param owner_ Owner address.
    * @param spender_ Spender address.
    * @return Remaining number of tokens that `spender_` will be
    * allowed to spend on behalf of `owner_` through `transferFrom()` function.
    */
    function allowance(
        address owner_, 
        address spender_
    ) 
        external 
        view 
        override 
        returns (uint256) 
    {
        return _allowedAmount[owner_][spender_];
    }
    
    /**
    * @notice Retrieves the name of the token.
    * @dev Standard ERC20.
    * @return Name of the token.
    */
    function name() external view override returns (string memory) {
        return _name;
    }
    
    /**
    * @notice Returns the symbol of the token, usually a shorter version of the name.
    * @dev Standard ERC20.
    * @return Symbol of the token.
    */
    function symbol() external view override returns (string memory) {
        return _symbol;
    }
    
    /**
    * @notice Returns the number of decimals utilized to get its human-readable representation.
    * @dev Standard ERC20.
    * @return Number of decimals.
    */
    function decimals() external pure override returns (uint8) {
        return 18;
    }
    
    /**
    * @notice Returns the amount of tokens owned by account.
    * @dev If account is not excluded holder then his balance 
    * automatically increases after each distribution of fee.
    * @param account_ Account address.
    * @return Amount of tokens owned by account.
    */
    function balanceOf(address account_) public view override returns (uint256) {
        if (_excludedHolders.contains(account_)) {
            return _adjustedBalances[account_];
        } else {
            return _adjustedBalances[account_].mul(adjustmentFactor);
        }
    }
    
    /**
    * @notice Returns the amount of tokens owned by all excluded holders.
    * @dev Utilized to correctly calculate the balance of holders when recalculating the adjustment factor.
    * @return Amount of tokens owned by all excluded holders.
    */
    function getExcludedBalance() public view virtual returns (uint256) {
        uint256 excludedBalance;
        for (uint256 i = 0; i < _excludedHolders.length(); i++) {
            excludedBalance += balanceOf(_excludedHolders.at(i));
        }
        return excludedBalance;
    }
    
    /**
    * @notice Calculates an amount of Zoinks/Binance-Peg BTCB/Binance-Peg Ethereum token 
    * which caller will spend in exchange for `buyTokenAmount_` Snacks/BtcSnacks/EthSnacks token.
    * @dev When calculating, the following formula is used: `S(n, m) = (n + m) * (m - n + 1) / 2 * d`, where 
    * `n = next`, `m = last`. After substituting the values, we get 
    * `S(next, last) = (next + last) * (last - next + ONE_SNACK) / 2 * d =
    * (next + last) * buyTokenAmount_ / (2 * _correlationFactor)`.
    * @param buyTokenAmount_ Amount of Zoinks/Binance-Peg BTCB/Binance-Peg Ethereum token which caller will spend
    * in exchange for `buyTokenAmount_` Snacks/BtcSnacks/EthSnacks token. 
    * WARNING: the fees for mint are not accounted.
    */
    function calculatePayTokenAmountOnMint(
        uint256 buyTokenAmount_
    )
        public
        view
        returns (uint256)
    {
        uint256 next = _totalSupply + ONE_SNACK;
        uint256 last = _totalSupply + buyTokenAmount_;
        uint256 numerator = (next + last) * buyTokenAmount_;
        require(
            numerator >= 2 * _correlationFactor,
            "SnacksBase: invalid buy token amount"
        );
        return numerator / (2 * _correlationFactor);
    }
    
    /**
    * @notice Calculates an amount of Snacks/BtcSnacks/EthSnacks token which caller will spend
    * in exchange for `payTokenAmount_` Zoinks/Binance-Peg BTCB/Binance-Peg Ethereum token.
    * @dev When calculating, the following formula is used: `S = (2 * a + d * (n - 1)) / 2 * n`, where
    * `a = nextSnackPrice`. From this formula we need to find the value of n, so after transformations 
    * we obtain that we need to solve the quadratic equation `d * n ^ 2 + (2 * a - d) * n - 2 * S = 0`.
    * @param payTokenAmount_ Amount of Zoinks/Binance-Peg BTCB/Binance-Peg Ethereum token to spend. 
    * WARNING: the fees for the mint are not accounted.
    * @return Amount of Snacks/BtcSnacks/EthSnacks token which caller will spend
    * in exchange for `payTokenAmount_` Zoinks/Binance-Peg BTCB/Binance-Peg Ethereum token.
    */
    function calculateBuyTokenAmountOnMint(
        uint256 payTokenAmount_
    )
        public
        view
        returns (uint256)
    {
        uint256 nextSnackPrice = _step + _totalSupply / _totalSupplyFactor;
        require(
            payTokenAmount_ >= nextSnackPrice,
            "SnacksBase: invalid pay token amount"
        );
        uint256 a = _step;
        uint256 b = 2 * nextSnackPrice - a;
        uint256 c = 2 * payTokenAmount_;
        uint256 discriminant = (b ** 2) + 4 * a * c;
        uint256 squareRoot = Math.sqrt(discriminant);
        return (squareRoot - b).div(2 * a);
    }
    
    /**
    * @notice Calculates an amount of Zoinks/Binance-Peg BTCB/Binance-Peg Ethereum token which caller will receive
    * on redeem `buyTokenAmount_` Snacks/BtcSnacks/EthSnacks token (10% fee not included).
    * @dev When calculating, the following formula is used: `S(n, m) = (n + m) * (m - n + 1) / 2 * d`, where
    * `n = start`, `m = _totalSupply`. After substituting the values, we get 
    * `S(start, _totalSuply) = (start + _totalSupply) * (_totalSupply - start + ONE_SNACK) / 2 * d =
    * (start + _totalSupply) * buyTokenAmount_ / (2 * _correlationFactor)`.
    * @param buyTokenAmount_ Amount of Snacks/BtcSnacks/EthSnacks token to redeem. 
    * WARNING: the fees for redeem are not accounted.
    * @return Amount of Zoinks/Binance-Peg BTCB/Binance-Peg Ethereum token which caller will receive
    * on redeem `buyTokenAmount_` Snacks/BtcSnacks/EthSnacks token (10% fee not included).
    */
    function calculatePayTokenAmountOnRedeem(
        uint256 buyTokenAmount_
    )
        public
        view
        returns (uint256)
    {
        uint256 start = _totalSupply + ONE_SNACK - buyTokenAmount_;
        uint256 numerator = (start + _totalSupply) * buyTokenAmount_;
        require(
            numerator >= 2 * _correlationFactor,
            "SnacksBase: invalid buy token amount"
        );
        return numerator / (2 * _correlationFactor);
    }
    
    /**
    * @notice Hook that is called inside `distributeFee()` function.
    * @dev Used only by BtcSnacks and EthSnacks contracts.
    */
    function _beforeDistributeFee(uint256) internal virtual {}
    
    /** 
    * @notice Hook that is called inside `distributeFee()` function.
    * @dev Recalculates adjustmentFactor according to formula: 
    * `adjustmentFactor = a * (b + c) / b`, where `a = current adjustment factor`,
    * `b = not excluded holders balance` and `c = left undistributed fee`.
    * @param undistributedFee_ Amount of left undistributed fee.
    */
    function _afterDistributeFee(uint256 undistributedFee_) internal virtual {
        uint256 excludedBalance = getExcludedBalance();
        uint256 holdersBalance = _totalSupply - excludedBalance;
        if (undistributedFee_ != 0) {
            uint256 seniorageFeeAmount = undistributedFee_ / 10;
            _transfer(address(this), seniorage, seniorageFeeAmount);
            if (holdersBalance != 0) {
                undistributedFee_ -= seniorageFeeAmount;
                adjustmentFactor = adjustmentFactor.mul((holdersBalance + undistributedFee_).div(holdersBalance));
                _adjustedBalances[address(this)] = 0;
                emit RewardForHolders(undistributedFee_);
            }
        }
    }
    
    /**
    * @notice Hook that is called right after any 
    * transfer of tokens. This includes minting and burning.
    * @dev Used only by the Snacks contract.
    */
    function _afterTokenTransfer(address, address) internal virtual {}
    
    /**
    * @notice Moves `amount_` of tokens from `from_` to `to_`.
    * @dev `from_` and `to_` cannot be the zero address. `from_` must have a balance of at least `amount_`. 
    * Takes into account the current `adjustmentFactor`.
    * @param from_ Address from which tokens are sent.
    * @param to_ Address to which tokens are sent.
    * @param amount_ Amount to transfer.
    */
    function _transfer(
        address from_,
        address to_,
        uint256 amount_
    )
        internal
    {
        require(
            from_ != address(0),
            "SnacksBase: transfer from the zero address"
        );
        require(
            to_ != address(0),
            "SnacksBase: transfer to the zero address"
        );
        uint256 adjustedAmount = amount_.div(adjustmentFactor);
        if (!_excludedHolders.contains(from_) && _excludedHolders.contains(to_)) {
            _adjustedBalances[from_] -= adjustedAmount;
            _adjustedBalances[to_] += amount_;
        } else if (_excludedHolders.contains(from_) && !_excludedHolders.contains(to_)) {
            _adjustedBalances[from_] -= amount_;
            _adjustedBalances[to_] += adjustedAmount;
        } else if (!_excludedHolders.contains(from_) && !_excludedHolders.contains(to_)) {
            _adjustedBalances[from_] -= adjustedAmount;
            _adjustedBalances[to_] += adjustedAmount;
        } else {
            _adjustedBalances[from_] -= amount_;
            _adjustedBalances[to_] += amount_;
        }
        emit Transfer(from_, to_, amount_);
        _afterTokenTransfer(from_, to_);
    }
    
    /**
    * @notice Creates the `amount_` tokens and assigns them to an `account_`, increasing the total supply.
    * @dev Takes into account the current `adjustmentFactor`.
    * @param account_ Account address.
    * @param amount_ Amount of tokens to mint.
    */
    function _mint(address account_, uint256 amount_) private {
        _totalSupply += amount_;
        uint256 adjustedAmount = amount_.div(adjustmentFactor);
        if (_excludedHolders.contains(account_)) {
            _adjustedBalances[account_] += amount_;
        } else {
            _adjustedBalances[account_] += adjustedAmount;
        }
        emit Transfer(address(0), account_, amount_);
        _afterTokenTransfer(address(0), account_);
    }
    
    /**
    * @notice Burns the `amount_` tokens from an `account_`, reducing the total supply.
    * @dev Takes into account the current `adjustmentFactor`.
    * @param account_ Account address.
    * @param amount_ Amount of tokens to burn.
    */
    function _burn(address account_, uint256 amount_) private {
        _totalSupply -= amount_;
        uint256 adjustedAmount = amount_.div(adjustmentFactor);
        if (_excludedHolders.contains(account_)) {
            _adjustedBalances[account_] -= amount_;
        } else {
            _adjustedBalances[account_] -= adjustedAmount;
        }
        emit Transfer(account_, address(0), amount_);
        _afterTokenTransfer(account_, address(0));
    }
}