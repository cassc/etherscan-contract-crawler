// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./AelinERC20.sol";
import "./interfaces/IAelinDeal.sol";
import "./MinimalProxyFactory.sol";
import "./AelinFeeEscrow.sol";

contract AelinDeal is AelinERC20, MinimalProxyFactory, IAelinDeal {
    using SafeERC20 for IERC20;
    uint256 public maxTotalSupply;

    address public underlyingDealToken;
    uint256 public underlyingDealTokenTotal;
    uint256 public totalUnderlyingClaimed;
    address public holder;
    address public futureHolder;
    address public aelinTreasuryAddress;

    uint256 public underlyingPerDealExchangeRate;

    address public aelinPool;
    uint256 public vestingCliffExpiry;
    uint256 public vestingCliffPeriod;
    uint256 public vestingPeriod;
    uint256 public vestingExpiry;
    uint256 public holderFundingExpiry;

    bool private calledInitialize;
    address public aelinEscrowAddress;
    AelinFeeEscrow public aelinFeeEscrow;

    bool public depositComplete;
    mapping(address => uint256) public amountVested;

    Timeline public openRedemption;
    Timeline public proRataRedemption;

    /**
     * @dev the constructor will always be blank due to the MinimalProxyFactory pattern
     * this allows the underlying logic of this contract to only be deployed once
     * and each new deal created is simply a storage wrapper
     */
    constructor() {}

    /**
     * @dev the initialize method replaces the constructor setup and can only be called once
     * NOTE the deal tokens wrapping the underlying are always 18 decimals
     */
    function initialize(
        string calldata _poolName,
        string calldata _poolSymbol,
        DealData calldata _dealData,
        address _aelinTreasuryAddress,
        address _aelinEscrowAddress
    ) external initOnce {
        _setNameSymbolAndDecimals(
            string(abi.encodePacked("aeDeal-", _poolName)),
            string(abi.encodePacked("aeD-", _poolSymbol)),
            DEAL_TOKEN_DECIMALS
        );

        holder = _dealData.holder;
        underlyingDealToken = _dealData.underlyingDealToken;
        underlyingDealTokenTotal = _dealData.underlyingDealTokenTotal;
        maxTotalSupply = _dealData.maxDealTotalSupply;

        aelinPool = msg.sender;
        vestingCliffPeriod = _dealData.vestingCliffPeriod;
        vestingPeriod = _dealData.vestingPeriod;
        proRataRedemption.period = _dealData.proRataRedemptionPeriod;
        openRedemption.period = _dealData.openRedemptionPeriod;
        holderFundingExpiry = _dealData.holderFundingDuration;
        aelinTreasuryAddress = _aelinTreasuryAddress;
        aelinEscrowAddress = _aelinEscrowAddress;

        depositComplete = false;

        /**
         * calculates the amount of underlying deal tokens you get per wrapped deal token accepted
         */
        underlyingPerDealExchangeRate = (_dealData.underlyingDealTokenTotal * 1e18) / maxTotalSupply;
        emit SetHolder(_dealData.holder);
    }

    modifier initOnce() {
        require(!calledInitialize, "can only initialize once");
        calledInitialize = true;
        _;
    }

    modifier finalizeDeposit() {
        require(block.timestamp < holderFundingExpiry, "deposit past deadline");
        require(!depositComplete, "deposit already complete");
        _;
    }

    /**
     * @dev the holder may change their address
     */
    function setHolder(address _holder) external onlyHolder {
        require(_holder != address(0));
        futureHolder = _holder;
    }

    function acceptHolder() external {
        require(msg.sender == futureHolder, "only future holder can access");
        holder = futureHolder;
        emit SetHolder(futureHolder);
    }

    /**
     * @dev the holder finalizes the deal for the pool created by the
     * sponsor by depositing funds using this method.
     *
     * NOTE if the deposit was completed with a transfer instead of this method
     * the deposit still needs to be finalized by calling this method with
     * _underlyingDealTokenAmount set to 0
     */
    function depositUnderlying(uint256 _underlyingDealTokenAmount) external finalizeDeposit lock returns (bool) {
        if (_underlyingDealTokenAmount > 0) {
            uint256 currentBalance = IERC20(underlyingDealToken).balanceOf(address(this));
            IERC20(underlyingDealToken).safeTransferFrom(msg.sender, address(this), _underlyingDealTokenAmount);
            uint256 balanceAfterTransfer = IERC20(underlyingDealToken).balanceOf(address(this));
            uint256 underlyingDealTokenAmount = balanceAfterTransfer - currentBalance;

            emit DepositDealToken(underlyingDealToken, msg.sender, underlyingDealTokenAmount);
        }

        if (IERC20(underlyingDealToken).balanceOf(address(this)) >= underlyingDealTokenTotal) {
            depositComplete = true;
            proRataRedemption.start = block.timestamp;
            proRataRedemption.expiry = block.timestamp + proRataRedemption.period;
            vestingCliffExpiry = block.timestamp + proRataRedemption.period + openRedemption.period + vestingCliffPeriod;
            vestingExpiry = vestingCliffExpiry + vestingPeriod;

            if (openRedemption.period > 0) {
                openRedemption.start = proRataRedemption.expiry;
                openRedemption.expiry = proRataRedemption.expiry + openRedemption.period;
            }

            address aelinEscrowStorageProxy = _cloneAsMinimalProxy(aelinEscrowAddress, "Could not create new escrow");
            aelinFeeEscrow = AelinFeeEscrow(aelinEscrowStorageProxy);
            aelinFeeEscrow.initialize(aelinTreasuryAddress, underlyingDealToken);

            emit DealFullyFunded(
                aelinPool,
                proRataRedemption.start,
                proRataRedemption.expiry,
                openRedemption.start,
                openRedemption.expiry
            );
            return true;
        }
        return false;
    }

    /**
     * @dev the holder can withdraw any amount accidentally deposited over
     * the amount needed to fulfill the deal or all amount if deposit was not completed
     */
    function withdraw() external onlyHolder {
        uint256 withdrawAmount;
        if (!depositComplete && block.timestamp >= holderFundingExpiry) {
            withdrawAmount = IERC20(underlyingDealToken).balanceOf(address(this));
        } else {
            withdrawAmount =
                IERC20(underlyingDealToken).balanceOf(address(this)) -
                (underlyingDealTokenTotal - totalUnderlyingClaimed);
        }
        IERC20(underlyingDealToken).safeTransfer(holder, withdrawAmount);
        emit WithdrawUnderlyingDealToken(underlyingDealToken, holder, withdrawAmount);
    }

    /**
     * @dev after the redemption period has ended the holder can withdraw
     * the excess funds remaining from purchasers who did not accept the deal
     *
     * Requirements:
     * - both the pro rata and open redemption windows are no longer active
     */
    function withdrawExpiry() external onlyHolder {
        require(proRataRedemption.expiry > 0, "redemption period not started");
        require(
            openRedemption.expiry > 0
                ? block.timestamp >= openRedemption.expiry
                : block.timestamp >= proRataRedemption.expiry,
            "redeem window still active"
        );
        uint256 withdrawAmount = IERC20(underlyingDealToken).balanceOf(address(this)) -
            ((underlyingPerDealExchangeRate * totalSupply()) / 1e18);
        IERC20(underlyingDealToken).safeTransfer(holder, withdrawAmount);
        emit WithdrawUnderlyingDealToken(underlyingDealToken, holder, withdrawAmount);
    }

    modifier onlyHolder() {
        require(msg.sender == holder, "only holder can access");
        _;
    }

    modifier onlyPool() {
        require(msg.sender == aelinPool, "only AelinPool can access");
        _;
    }

    /**
     * @dev a view showing the number of claimable deal tokens and the
     * amount of the underlying deal token a purchser gets in return
     */
    function claimableTokens(address purchaser)
        public
        view
        returns (uint256 underlyingClaimable, uint256 dealTokensClaimable)
    {
        underlyingClaimable = 0;
        dealTokensClaimable = 0;

        uint256 maxTime = block.timestamp > vestingExpiry ? vestingExpiry : block.timestamp;
        if (
            balanceOf(purchaser) > 0 &&
            (maxTime > vestingCliffExpiry || (maxTime == vestingCliffExpiry && vestingPeriod == 0))
        ) {
            uint256 timeElapsed = maxTime - vestingCliffExpiry;

            dealTokensClaimable = vestingPeriod == 0
                ? balanceOf(purchaser)
                : ((balanceOf(purchaser) + amountVested[purchaser]) * timeElapsed) / vestingPeriod - amountVested[purchaser];
            underlyingClaimable = (underlyingPerDealExchangeRate * dealTokensClaimable) / 1e18;
        }
    }

    /**
     * @dev allows a user to claim their underlying deal tokens or a partial amount
     * of their underlying tokens once they have vested according to the schedule
     * created by the sponsor
     */
    function claim() external returns (uint256) {
        return _claim(msg.sender);
    }

    function _claim(address recipient) internal returns (uint256) {
        (uint256 underlyingDealTokensClaimed, uint256 dealTokensClaimed) = claimableTokens(recipient);
        if (dealTokensClaimed > 0) {
            amountVested[recipient] += dealTokensClaimed;
            totalUnderlyingClaimed += underlyingDealTokensClaimed;
            _burn(recipient, dealTokensClaimed);
            IERC20(underlyingDealToken).safeTransfer(recipient, underlyingDealTokensClaimed);
            emit ClaimedUnderlyingDealToken(underlyingDealToken, recipient, underlyingDealTokensClaimed);
        }
        return dealTokensClaimed;
    }

    /**
     * @dev allows the purchaser to mint deal tokens. this method is also used
     * to send deal tokens to the sponsor. It may only be called from the pool
     * contract that created this deal
     */
    function mint(address dst, uint256 dealTokenAmount) external onlyPool {
        require(depositComplete, "deposit not complete");
        _mint(dst, dealTokenAmount);
    }

    /**
     * @dev allows the protocol to handle protocol fees coming in deal tokens.
     * It may only be called from the pool contract that created this deal
     */
    function protocolMint(uint256 dealTokenAmount) external onlyPool {
        require(depositComplete, "deposit not complete");
        uint256 underlyingProtocolFees = (underlyingPerDealExchangeRate * dealTokenAmount) / 1e18;
        IERC20(underlyingDealToken).safeTransfer(address(aelinFeeEscrow), underlyingProtocolFees);
    }

    modifier blockTransfer() {
        require(msg.sender == aelinTreasuryAddress, "cannot transfer deal tokens");
        _;
    }

    /**
     * @dev a function only the treasury can use so they can send both the all
     * unvested deal tokens as well as all the vested underlying deal tokens in a
     * single transaction for distribution to $AELIN stakers.
     */
    function treasuryTransfer(address recipient) external returns (bool) {
        require(msg.sender == aelinTreasuryAddress, "only Rewards address can access");
        (uint256 underlyingClaimable, uint256 claimableDealTokens) = claimableTokens(msg.sender);
        transfer(recipient, balanceOf(msg.sender) - claimableDealTokens);
        IERC20(underlyingDealToken).safeTransferFrom(msg.sender, recipient, underlyingClaimable);
        return true;
    }

    /**
     * @dev below are helpers for transferring deal tokens. NOTE the token holder transferring
     * the deal tokens must pay the gas to claim their vested tokens first, which will burn their vested deal
     * tokens. They must also pay for the receivers claim and burn any of their vested tokens in order to ensure
     * the claim calculation is always accurate for all parties in the system
     */
    function transferMax(address recipient) external blockTransfer returns (bool) {
        (, uint256 claimableDealTokens) = claimableTokens(msg.sender);
        return transfer(recipient, balanceOf(msg.sender) - claimableDealTokens);
    }

    function transferFromMax(address sender, address recipient) external blockTransfer returns (bool) {
        (, uint256 claimableDealTokens) = claimableTokens(sender);
        return transferFrom(sender, recipient, balanceOf(sender) - claimableDealTokens);
    }

    function transfer(address recipient, uint256 amount) public virtual override blockTransfer returns (bool) {
        _claim(msg.sender);
        _claim(recipient);
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override blockTransfer returns (bool) {
        _claim(sender);
        _claim(recipient);
        return super.transferFrom(sender, recipient, amount);
    }

    event SetHolder(address indexed holder);
    event DealFullyFunded(
        address indexed poolAddress,
        uint256 proRataRedemptionStart,
        uint256 proRataRedemptionExpiry,
        uint256 openRedemptionStart,
        uint256 openRedemptionExpiry
    );
    event DepositDealToken(
        address indexed underlyingDealTokenAddress,
        address indexed depositor,
        uint256 underlyingDealTokenAmount
    );
    event WithdrawUnderlyingDealToken(
        address indexed underlyingDealTokenAddress,
        address indexed depositor,
        uint256 underlyingDealTokenAmount
    );
    event ClaimedUnderlyingDealToken(
        address indexed underlyingDealTokenAddress,
        address indexed recipient,
        uint256 underlyingDealTokensClaimed
    );
}