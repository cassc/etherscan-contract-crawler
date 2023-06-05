//SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

interface IAntisnipe {
    function assureCanTransfer(
        address sender,
        address from,
        address to,
        uint256 amount
    ) external;
}

interface IPair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

error ZeroAddress();

/**
 * @title MinifootballToken
 * @author gotbit
 */

contract MinifootballToken is ERC20, Ownable {
    using SafeERC20 for ERC20;

    uint16 public buyFee; // fee amount during buy from pair, where 500 = 5%
    uint16 public sellFee; // fee amount during sell to pair, where 500 = 5%
    bool public feeEliminated; // if true then fees are equal to zero

    address public liquidityPair; // liquidity pair address
    address public buyFeeWallet; // wallet receiving buy fees
    address public sellFeeWallet; // wallet receiving sell fees

    uint256 public transactionLimit = 10_000_000_000 ether; // limit per one transaction. Does not affect the owner and whitelists
    uint256 public holdingLimit = 10_000_000_000 ether; // limit one wallet can hold. Does not affect owner, fee wallets, pair and whitelists

    uint256 private constant DENOMINATOR = 10_000; // denominator constant for percent math. 10_000 = 100%
    uint256 public constant MAX_FEE = 500; // max buy/sell value. 500 is equal to 5%

    // Antisnipe variables
    IAntisnipe public antisnipe;
    bool public antisnipeDisable;

    mapping(address => bool) public whitelist; // whitelisted address does not pay sell/buy fees and does not have any limits

    constructor(
        address owner_,
        uint256 transactionLimit_,
        uint256 holdingLimit_,
        address buyFeeWallet_,
        address sellFeeWallet_
    ) ERC20('BallCoin', '$BALL') {
        if (buyFeeWallet_ == address(0)) revert ZeroAddress();
        if (sellFeeWallet_ == address(0)) revert ZeroAddress();
        if (owner_ == address(0)) revert ZeroAddress();

        _transferOwnership(owner_);
        _mint(owner_, 10_000_000_000 ether);

        transactionLimit = transactionLimit_;
        holdingLimit = holdingLimit_;
        buyFeeWallet = buyFeeWallet_;
        sellFeeWallet = sellFeeWallet_;
    }

    /// @dev Implementing antisnipe and transaction limit and holding limit logic on transfer
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (!isFirstLiquidity(to)) _validateLimits(from, to, amount);

        if (from == address(0) || to == address(0)) return;
        if (!antisnipeDisable && address(antisnipe) != address(0))
            antisnipe.assureCanTransfer(msg.sender, from, to, amount);
    }

    /// @dev Reverts if transaction/holding limit is exceeded
    function _validateLimits(
        address from,
        address to,
        uint256 amount
    ) internal view {
        if (owner() == from || owner() == to) return;
        if (whitelist[from] || whitelist[to]) return;

        require(amount <= transactionLimit, 'Tx limit exceeded');

        if (to == sellFeeWallet || to == buyFeeWallet || to == liquidityPair) return;

        require(balanceOf(to) + amount <= holdingLimit, 'Holding limit exceeded');
    }

    function isFirstLiquidity(address to) internal view returns (bool) {
        if (liquidityPair == address(0)) return false;

        (uint112 reserve0, , ) = IPair(liquidityPair).getReserves();
        if (reserve0 == 0 && to == liquidityPair) return true;

        return false;
    }

    /// @notice Transfer tokens to recipient. If fee > 0 transfers fee.
    /// @param to is recipient
    /// @param amount is tokens value to send to recipient
    function transfer(address to, uint256 amount) public override returns (bool) {
        address owner = _msgSender();

        uint256 fee = _transferFees(owner, to, amount);
        _transfer(owner, to, amount - fee);

        return true;
    }

    /// @notice Transfer tokens from sender to recipient. If fee > 0 transfers fee.
    /// @param from is tokens sender address
    /// @param to is tokens recipient address
    /// @param amount is tokens value to send from sender to recipient
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);

        uint256 fee = _transferFees(from, to, amount);
        _transfer(from, to, amount - fee);

        return true;
    }

    function _transferFees(
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256 feeAmount) {
        if (owner() == from || owner() == to) return 0;

        if (from == liquidityPair && buyFee != 0 && !whitelist[to]) {
            feeAmount = (amount * buyFee) / DENOMINATOR;
            _transfer(from, buyFeeWallet, feeAmount);
        } else if (to == liquidityPair && sellFee != 0 && !whitelist[from]) {
            feeAmount = (amount * sellFee) / DENOMINATOR;
            _transfer(from, sellFeeWallet, feeAmount);
        }
    }

    /// @notice Disables antisnipe forever, after this function no ability to activate antisnipe
    function setAntisnipeDisable() external onlyOwner {
        require(!antisnipeDisable);
        antisnipeDisable = true;
    }

    /// @notice Sets antisnipe address
    /// @param addr is antisnipe contract address
    function setAntisnipeAddress(address addr) external onlyOwner {
        antisnipe = IAntisnipe(addr);
    }

    /// @notice Owner can add/remove user to/from whitelist
    /// @param user is address to add/remove
    /// @param addToWhitelist if you want to add - true, remove - false
    function setWhitelist(address user, bool addToWhitelist) external onlyOwner {
        require(whitelist[user] != addToWhitelist);
        whitelist[user] = addToWhitelist;
    }

    /// @notice Owner can add and remove users list to and from whitelist in one transaction
    /// @param users array of users
    /// @param addToWhitelist flags for each user to add to whitelist or to remove from it
    function setBatchWhitelist(address[] calldata users, bool[] calldata addToWhitelist)
        external
        onlyOwner
    {
        require(users.length == addToWhitelist.length, 'Bad lengths');
        for (uint256 i; i < users.length; ) {
            whitelist[users[i]] = addToWhitelist[i];
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Owner can set sell fee ( <= 5%) if fees is not eliminated
    /// @param newFee is new fee amount, 5% is 500
    function setSellFee(uint16 newFee) external onlyOwner {
        require(newFee <= MAX_FEE, 'New fee exceeds max value');
        require(!feeEliminated, 'Fees eliminated');
        sellFee = newFee;
    }

    /// @notice Onwer can set buy fee (<= 5%) if fees is not eliminated
    /// @param newFee is new fee amount, 5% is 500
    function setBuyFee(uint16 newFee) external onlyOwner {
        require(newFee <= MAX_FEE, 'New fee exceeds max value');
        require(!feeEliminated, 'Fees eliminated');
        buyFee = newFee;
    }

    /// @notice Owner can disable fees in one direction, after fees are eliminated, they could not be set anymore
    function eliminateFees() external onlyOwner {
        buyFee = 0;
        sellFee = 0;
        feeEliminated = true;
    }

    /// @notice Owner can set new buy fees wallet receiver
    /// @param wallet is buy fees receiver address
    function setBuyFeeWallet(address wallet) external onlyOwner {
        if (wallet == address(0)) revert ZeroAddress();
        buyFeeWallet = wallet;
    }

    /// @notice Owner can set new sell fees wallet receiver
    /// @param wallet is sell fees receiver address
    function setSellFeeWallet(address wallet) external onlyOwner {
        if (wallet == address(0)) revert ZeroAddress();
        sellFeeWallet = wallet;
    }

    /// @notice Owner can set liquidity pair address
    /// @param pair_ is liquidity pair address
    function setLiquidityPair(address pair_) external onlyOwner {
        if (pair_ == address(0)) revert ZeroAddress();
        liquidityPair = pair_;
    }

    /// @notice Owner can set new transaction limit
    /// @param newTransactionLimit is new limit per tokens send
    function setTransactionLimit(uint256 newTransactionLimit) external onlyOwner {
        transactionLimit = newTransactionLimit;
    }

    /// @notice Owner can set new limit for one wallet to hold
    /// @param newHoldingLimit is new limit for hold value buy one wallet
    function setHoldingLimit(uint256 newHoldingLimit) external onlyOwner {
        holdingLimit = newHoldingLimit;
    }

    /// @notice Owner can withdraw any tokens stuck on this contract.
    /// @param token is token address to withdraw
    /// @param amount is tokens value to withdraw
    function withdrawToken(address token, uint256 amount) external onlyOwner {
        ERC20(token).safeTransfer(msg.sender, amount);
    }

    /// @notice Owner can withdraw native token from this contract
    /// @param amount is amount to withdraw
    function withdrawNative(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }
}