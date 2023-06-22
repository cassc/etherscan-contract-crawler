// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./Interfaces/IWhiteUSDCPool.sol";
import "./Interfaces/IWhiteStakingERC20.sol";

/**
 * @author jmonteer & 0mllwntrmt3
 * @title Whiteheart Stablecoin Liquidity Pool
 * @notice Accumulates liquidity in USDC from LPs and distributes P&L in USDC
 */
contract WhiteUSDCPool is
    IWhiteUSDCPool,
    Ownable,
    ERC20("Whiteheart USDC LP Token", "writeUSDC")
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // token that is holded in the pool
    IERC20 public override immutable token;
    // address of fee recipient contract
    IWhiteStakingERC20 public immutable settlementFeeRecipient;
    address public hegicFeeRecipient;

    // storage variable to keep
    uint256 public owedToKeep3r = 0;
    // amount locked as collateral for open positions
    uint256 public lockedAmount;
    // amount of locked premiums
    uint256 public lockedPremium;
    // minimum amount of time to pass between last provide timestamp and withdrawal
    uint256 public lockupPeriod = 2 weeks;
    uint256 public hegicFee = 0;
    uint256 public constant INITIAL_RATE = 1e13;

    // WHAsset contracts allowed to open positions using this pool
    mapping(address => bool) public whAssets;
    // Last provided timestamp for this address
    mapping(address => uint256) public lastProvideTimestamp;
    // Locked Liquidity mapping per WHAsset (whAsset address => id => LockedLiquidity)
    mapping(address => mapping(uint => LockedLiquidity)) public lockedLiquidity;
    // Whether or not the tranfers of Locked funds are allowed
    mapping(address => bool) public _revertTransfersInLockUpPeriod;

    /**
     * @param _token USDC address
     * @param _settlementFeeRecipient Address of contract that will receive the fees
     */
    constructor(IERC20 _token, IWhiteStakingERC20 _settlementFeeRecipient) public {
        token = _token;
        settlementFeeRecipient = _settlementFeeRecipient;
        hegicFeeRecipient = msg.sender;
        IERC20(_token).safeApprove(address(_settlementFeeRecipient), type(uint256).max);
    }

    modifier onlyWHAssets {
        require(whAssets[msg.sender], "whiteheart::pool::not-allowed");
        _;
    }

    /**
     * @notice Used for changing the lockup period
     * @param value New period value
     */
    function setLockupPeriod(uint256 value) external override onlyOwner {
        require(value <= 60 days, "Lockup period is too large");
        lockupPeriod = value;
    }

    /**
     * @notice Used for changing the Hegic fee recipient
     * @param value New value
     */
    function setHegicFeeRecipient(address value) external onlyOwner {
        require(value != address(0));
        hegicFeeRecipient = value;
    }

    /**
     * @notice Used for withdrawing the Hegic fee
     */
    function withdrawHegicFee() external {
      token.safeTransfer(hegicFeeRecipient, hegicFee);
      hegicFee = 0;
    }

    /**
     * @notice Allows new smart contract to open positions using USDC pools
     * @param _whAsset whAsset address
     * @param approved set to true for approval, set to false for rejecting previously granted access
     */
    function setAllowedWHAsset(address _whAsset, bool approved) external override onlyOwner {
        whAssets[_whAsset] = approved;
    }

    /**
     * @notice Lets each user to decide whether or not they want to allow incoming transfers of locked funds
     * @param value bool option. true if the transfer should be reverted, false if it shouldnt
     */
    function revertTransfersInLockUpPeriod(bool value) external {
        _revertTransfersInLockUpPeriod[msg.sender] = value;
    }

    /**
     * @notice called by WHAsset contract to lock funds and premium (when opening a position)
     * @param id Id of the Hedge Contract that is being opened
     * @param amountToLock Amount of funds that should be locked in an option
     * @param totalFee premium paid for the protection. It will be locked until funds are unlocked
     */
    function lock(uint id, uint256 amountToLock, uint256 totalFee) external override onlyWHAssets {
        address creator = msg.sender;
        require(
            lockedAmount.add(amountToLock).mul(10) <= totalBalance().mul(8),
            "Pool Error: Amount is too large."
        );

        uint256 premium = totalFee.mul(30).div(100);
        uint256 settlementFee = totalFee.mul(30).div(100);
        uint256 hegicFeeAmount = totalFee.sub(premium).sub(settlementFee);

        lockedLiquidity[creator][id] = (LockedLiquidity(uint120(amountToLock), uint120(premium), true));
        lockedPremium = lockedPremium.add(premium);
        lockedAmount = lockedAmount.add(amountToLock);

        settlementFeeRecipient.sendProfit(settlementFee);
        hegicFee = hegicFee.add(hegicFeeAmount);
    }

    /**
     * @notice calls by WHAsset contract to unlock funds and premium (when closing a position, either exercising or unlocking funds)
     * @param id Id of the Hedge Contract that is being opened
     */
    function unlock(uint256 id) external override {
        LockedLiquidity storage ll = lockedLiquidity[msg.sender][id];
        require(ll.locked, "LockedLiquidity with such id has already unlocked");
        ll.locked = false;

        lockedPremium = lockedPremium.sub(ll.premium);
        lockedAmount = lockedAmount.sub(ll.amount);

        emit Profit(id, ll.premium);
    }

    /**
     * @notice Function that can only be called by WHAsset contracts to retrieve funds owed to a keep3r
     * @param keep3r address of the function to receive accumulated rewards
     */
    function payKeep3r(address keep3r) external onlyWHAssets override returns (uint amount) {
        amount = owedToKeep3r;
        owedToKeep3r = 0;
        if(amount > 0) token.safeTransfer(keep3r, amount);
    }

    /**
     * @notice function that pays profit (if any) to the hedge contract holder and unlocks premium and liquidity
     * @param id Id of the Hedge Contract that is being closed
     * @param to address to receive profit
     * @param amount profit to be sent
     * @param _payKeep3r amount to be saved for the keep3r unwrapping the asset
     */
    function send(uint id, address payable to, uint256 amount, uint _payKeep3r)
        external
        override
    {
        LockedLiquidity storage ll = lockedLiquidity[msg.sender][id];
        require(ll.locked, "LockedLiquidity with such id has already unlocked");
        require(to != address(0));

        ll.locked = false;
        lockedPremium = lockedPremium.sub(ll.premium);
        lockedAmount = lockedAmount.sub(ll.amount);

        uint transferAmount = amount > ll.amount ? ll.amount : amount;
        token.safeTransfer(to, transferAmount.sub(_payKeep3r));

        if(_payKeep3r > 0) owedToKeep3r = owedToKeep3r.add(_payKeep3r);

        if (transferAmount <= ll.premium)
            emit Profit(id, ll.premium - transferAmount);
        else
            emit Loss(id, transferAmount - ll.premium);
    }

    /**
     * @notice deletes locked liquidity, receiving a gas refund. used to reduce gas usage
     * @param id Id of the Hedge Contract that is being closed
     */
    function deleteLockedLiquidity(uint id) external override {
        delete lockedLiquidity[msg.sender][id];
    }

    /**
     * @notice A provider supplies USDC to the pool and receives writeUSDC tokens
     * @param amount Amount to send to the contract
     * @param minMint minimum amount of writeUSDC tokens to be minted
     * @return mint amount of writeUSDC minted to provider
     */
    function provide(uint256 amount, uint256 minMint) external returns (uint256 mint) {
        lastProvideTimestamp[msg.sender] = block.timestamp;
        uint supply = totalSupply();
        uint balance = totalBalance();
        if (supply > 0 && balance > 0)
            mint = amount.mul(supply).div(balance);
        else
            mint = amount.mul(INITIAL_RATE);

        require(mint >= minMint, "Pool: Mint limit is too large");
        require(mint > 0, "Pool: Amount is too small");
        _mint(msg.sender, mint);
        emit Provide(msg.sender, amount, mint);

        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice A provider supplies writeUSDC to the pool and receives USDC tokens
     * @param amount Amount to withdraw from the pool
     * @param maxBurn maximum amount of writeUSDC to be burned in exchange
     * @return burn amount of writeUSDC burnt from provider
     */
    function withdraw(uint256 amount, uint256 maxBurn) external returns (uint256 burn) {
        require(
            lastProvideTimestamp[msg.sender].add(lockupPeriod) <= block.timestamp,
            "Pool: Withdrawal is locked up"
        );
        require(
            amount <= availableBalance(),
            "Pool Error: You are trying to unlock more funds than have been locked for your contract. Please lower the amount."
        );

        burn = divCeil(amount.mul(totalSupply()), totalBalance());

        require(burn <= maxBurn, "Pool: Burn limit is too small");
        require(burn <= balanceOf(msg.sender), "Pool: Amount is too large");
        require(burn > 0, "Pool: Amount is too small");

        _burn(msg.sender, burn);
        emit Withdraw(msg.sender, amount, burn);
        token.safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Returns provider's share in USDC
     * @param user Provider's address
     * @return share Provider's share in USDC
     */
    function shareOf(address user) external view returns (uint256 share) {
        uint supply = totalSupply();
        if (supply > 0)
            share = totalBalance().mul(balanceOf(user)).div(supply);
        else
            share = 0;
    }

    /**
     * @notice Returns the amount of USDC available for withdrawals
     * @return balance Unlocked amount
     */
    function availableBalance() public view returns (uint256 balance) {
        return totalBalance().sub(lockedAmount);
    }

    /**
     * @notice Returns the USDC total balance provided to the pool
     * @return balance Pool balance
     */
    function totalBalance() public override view returns (uint256 balance) {
        return token.balanceOf(address(this)).sub(lockedPremium).sub(hegicFee);
    }

    /**
     * @notice Internal function that checks if to be transferred tokens are locked and act accordingly
     * @param from sender
     * @param to recipient
     */
    function _beforeTokenTransfer(address from, address to, uint256) internal override {
        if (
            lastProvideTimestamp[from].add(lockupPeriod) > block.timestamp &&
            lastProvideTimestamp[from] > lastProvideTimestamp[to]
        ) {
            require(
                !_revertTransfersInLockUpPeriod[to],
                "the recipient does not accept blocked funds"
            );
            lastProvideTimestamp[to] = lastProvideTimestamp[from];
        }
    }

    // support function that divides and chooses result's ceil
    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        if (a % b != 0)
            c = c + 1;
        return c;
    }
}