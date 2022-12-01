// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./FlorinToken.sol";
import "./FlorinTreasury.sol";
import "./Util.sol";

/// @title LoanVault
/// @dev
contract LoanVault is ERC4626Upgradeable, ERC20PermitUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    using MathUpgradeable for uint256;

    // LOAN EVENTS
    event RepayLoan(uint256 loanAmount);
    event WriteDownLoan(uint256 estimatedDefaultAmount);
    event WriteUpLoan(uint256 recoveredAmount);
    event FinalizeDefault(uint256 definiteDefaultAmount);

    // REWARDS EVENTS
    event DepositRewards(uint256 rewards);
    event SetApr(uint256 apr);

    // FUNDING EVENTS
    event Fund(address indexed funder, IERC20Upgradeable fundingToken, uint256 fundingTokenAmount, uint256 florinTokens, uint256 shares);
    event AddFundingRequest(uint256 fundingRequestId, uint256 florinTokens);
    event CancelFundingRequest(uint256 fundingRequestId);

    event SetFundingTokenChainLinkFeed(IERC20Upgradeable fundingToken, AggregatorV3Interface fundingTokenChainLinkFeed, bool invertFundingTokenChainLinkFeedAnswer_);
    event SetFundingToken(IERC20Upgradeable token, bool accepted);
    event SetPrimaryFunder(address primaryFunder, bool accepted);
    event SetDelegate(address delegate);

    /////////////////////////////////////////////////////////////////////////
    /////////////////////////////CORE////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////

    /// @dev FlorinTreasury contract. Used by functions which require EUR transfers
    FlorinTreasury public florinTreasury;

    /// @dev Sum of captial actively deployed in loans (does not include defaults) [18 decimals]
    uint256 public loansOutstanding;

    /// @dev Amount of vault debt. This is used to handle edge cases which should not occur outside of extreme situations. Will be 0 usually. [18 decimals]
    uint256 public debt;

    /// @dev Sum of recent loan write downs that are not definite defaults yet. This is used to cap the writeUpLoan function to the upside in order to prevent abuse. [18 decimals]
    uint256 public loanWriteDown;

    /////////////////////////////////////////////////////////////////////////
    /////////////////////////////REWARDS/////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////

    /// @dev Timestamp of when outstandingRewardsSnapshot was updated the last time [unix-timestamp]
    uint256 public outstandingRewardsSnapshotTimestamp;

    /// @dev Rewards that need to be deposited into the vault in order match the APR at the moment of outstandingRewardsSnapshotTimestamp [18 decimals]
    uint256 public outstandingRewardsSnapshot;

    /// @dev APR of the vault [16 decimals (e.g. 5%=0.05*10^18]
    uint256 public apr;

    /////////////////////////////////////////////////////////////////////////
    /////////////////////////////FUNDING/////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////

    /// @dev Constant for FundingRequest id to signal that there is no currently active FundingRequest
    uint256 public constant NO_FUNDING_REQUEST = type(uint256).max;

    /// @dev A FundingRequest enables the delegate to raise money from primaryFunders
    struct FundingRequest {
        /// @dev Identifier for the FundingRequest
        uint256 id;
        /// @dev Delegate which created the FundingRequest
        address delegate;
        /// @dev Required funding [18 decimals (FLR)]
        uint256 amountRequested;
        /// @dev Amount filled / provided funding [18 decimals (FLR)]
        uint256 amountFilled;
        /// @dev State (see FundingRequestState enum)
        FundingRequestState state;
    }

    /// @dev States for the lifecycle of a FundingRequest
    enum FundingRequestState {
        OPEN,
        FILLED,
        PARTIALLY_FILLED,
        CANCELLED
    }

    /// @dev Enforces a function can only be executed by the vaults delegate
    modifier onlyDelegate() {
        require(delegate == msg.sender, "caller must be delegate");
        _;
    }

    /// @dev Delegate of the vault. Can create/cancel FundingRequests and call loan control functions
    address public delegate;

    /// @dev PrimaryFunders are allowed to fill FundingRequests directly. address => primaryFunder status [true/false]
    mapping(address => bool) private primaryFunders;

    /// @dev Contains all FundingRequests
    FundingRequest[] public fundingRequests;

    /// @dev Id of the last proccessed FundingRequest
    uint256 public lastProcessedFundingRequestId;

    /// @dev Token => whether the token can be used to fill FundingRequests
    mapping(IERC20Upgradeable => bool) private fundingTokens;

    /// @dev All funding tokens
    IERC20Upgradeable[] private _fundingTokens;

    /// @dev FudingToken => ChainLink feed which provides a conversion rate for the fundingToken to the vaults loans base currency (e.g. USDC => EURSUD)
    mapping(IERC20Upgradeable => AggregatorV3Interface) private fundingTokenChainLinkFeeds;

    /// @dev FudingToken => whether the data provided by the ChainLink feed should be inverted (not all ChainLink feeds are Token->BaseCurrency, some could be BaseCurrency->Token)
    mapping(IERC20Upgradeable => bool) private invertFundingTokenChainLinkFeedAnswer;

    /////////////////////////////////////////////////////////////////////////
    /////////////////////////////CORE////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {} // solhint-disable-line

    function initialize(string memory name, string memory symbol, FlorinTreasury florinTreasury_) external initializer {
        florinTreasury = florinTreasury_;

        // solhint-disable-next-line not-rely-on-time
        outstandingRewardsSnapshotTimestamp = block.timestamp;
        __ERC20_init_unchained(name, symbol);
        __ERC20Permit_init(name);
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ERC4626_init_unchained(IERC20MetadataUpgradeable(address(florinTreasury.florinToken())));
        _pause();
    }

    function decimals() public view virtual override(ERC4626Upgradeable, ERC20Upgradeable) returns (uint8) {
        return 18;
    }

    /// @dev Pauses the LoanVault. Check functions with whenPaused/whenNotPaused modifier
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Unpauses the LoanVault. Check functions with whenPaused/whenNotPaused modifier
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Unique identifier of the LoanVault
    /// @return the id which is the symbol of the vaults share token
    function id() public view returns (string memory) {
        return symbol();
    }

    /// @dev See {IERC4626-maxDeposit}.
    /// @dev Determines how many FLR can currently be deposited in the LoanVault.
    ///      To avoid oversubscription and consequent dillution of rewards this is capped to loansOutstanding.
    /// @return amount of FLR that can be deposited in the LoanVault currently.
    function maxDeposit(address) public view override returns (uint256) {
        if (loansOutstanding <= totalAssets() || debt > 0) return 0;
        return loansOutstanding - totalAssets();
    }

    /// @dev Increase the vaults assets by minting Florin. If the vault is in debt the debt will be reduced first.
    /// @param amount of FLR to mint into the vault
    function _increaseAssets(uint256 amount) internal {
        if (debt < amount) {
            florinTreasury.mint(address(this), amount - debt);
            debt = 0;
        } else {
            debt -= amount;
        }
    }

    /// @dev See {IERC4626-deposit}. Overridden for whenNotPaused modifier
    function deposit(uint256 assets, address receiver) public virtual override whenNotPaused returns (uint256) {
        return super.deposit(assets, receiver);
    }

    /// @dev See {IERC4626-mint}. Overridden for whenNotPaused modifier
    function mint(uint256 shares, address receiver) public virtual override whenNotPaused returns (uint256) {
        return super.mint(shares, receiver);
    }

    /// @dev See {IERC4626-withdraw}. Overridden for whenNotPaused modifier
    function withdraw(uint256 assets, address receiver, address owner) public virtual override whenNotPaused returns (uint256) {
        return super.withdraw(assets, receiver, owner);
    }

    /////////////////////////////////////////////////////////////////////////
    /////////////////////////////LOAN////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////

    /// @dev Repayment of a matured loan.
    /// @param loanAmount to be repaid in FlorinTreasury.eurToken [18 decimals, see FlorinTreasury.depositEUR]
    function repayLoan(uint256 loanAmount) external onlyDelegate whenNotPaused {
        require(loanAmount <= loansOutstanding, "loanAmount must be <= loansOutstanding");
        _snapshotOutstandingRewards();
        loansOutstanding -= loanAmount;
        florinTreasury.depositEUR(_msgSender(), loanAmount);
        emit RepayLoan(loanAmount);
    }

    /// @dev Write down of loansOutstanding in case of a suspected loan default
    /// @param estimatedDefaultAmount the estimated default amount. Can be corrected via writeUpLoan in terms of recovery
    function writeDownLoan(uint256 estimatedDefaultAmount) external onlyDelegate whenNotPaused {
        require(estimatedDefaultAmount <= loansOutstanding, "estimatedDefaultAmount must be <= loansOutstanding");
        _snapshotOutstandingRewards();
        uint256 flrBurnAmount = MathUpgradeable.min(estimatedDefaultAmount, totalAssets());
        florinTreasury.florinToken().burn(flrBurnAmount);
        loansOutstanding -= estimatedDefaultAmount;
        debt += estimatedDefaultAmount - flrBurnAmount;
        loanWriteDown += estimatedDefaultAmount;
        emit WriteDownLoan(estimatedDefaultAmount);
    }

    /// @dev Write up of loansOutstanding in case of a previously written down loan recovering
    /// @param recoveredAmount the amount the loan has recovered for
    function writeUpLoan(uint256 recoveredAmount) external onlyDelegate whenNotPaused {
        require(recoveredAmount <= loanWriteDown, "recoveredAmount must be <= previous write downs");
        _snapshotOutstandingRewards();

        loansOutstanding += recoveredAmount;
        loanWriteDown -= recoveredAmount;
        _increaseAssets(recoveredAmount);
        emit WriteUpLoan(recoveredAmount);
    }

    /// @dev Lock-in a previously written down loan once it is clear it will not recover any more.
    /// @param definiteDefaultAmount the amount of the loan that as defauled
    function finalizeDefault(uint256 definiteDefaultAmount) external onlyDelegate whenNotPaused {
        require(definiteDefaultAmount <= loanWriteDown, "definiteDefaultAmount must be <= previous write downs");
        loanWriteDown -= definiteDefaultAmount;
        emit FinalizeDefault(definiteDefaultAmount);
    }

    /////////////////////////////////////////////////////////////////////////
    /////////////////////////////REWARDS/////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////

    /// @dev Persists the currently oustanding rewards as calculated by calculateOutstandingRewards to protect it
    /// from being distorted by changes to the underlying variables. This should be called before every deposit/withdraw or other
    //  operation that potentially affects the result of calculateOutstandingRewards
    function _snapshotOutstandingRewards() internal {
        outstandingRewardsSnapshot = calculateOutstandingRewards();
        // solhint-disable-next-line not-rely-on-time
        outstandingRewardsSnapshotTimestamp = block.timestamp;
    }

    /// @dev Calculates the amount of rewards that are owed to the vault at the current moment.
    /// This calculation is based on apr as well as the amount of depositors at the current moment.
    /// @return amount of outstanding rewards [18 decimals]
    function calculateOutstandingRewards() public view returns (uint256) {
        uint256 vaultFlrBalance = IERC20Upgradeable(asset()).balanceOf(address(this));
        // solhint-disable-next-line not-rely-on-time
        uint256 timeSinceLastOutstandingRewardsSnapshot = block.timestamp - outstandingRewardsSnapshotTimestamp;

        if (loansOutstanding == 0 || vaultFlrBalance == 0 || apr == 0 || timeSinceLastOutstandingRewardsSnapshot == 0) {
            return outstandingRewardsSnapshot;
        }

        uint256 rewardsPerSecond = loansOutstanding.mulDiv(apr, 10 ** 18, MathUpgradeable.Rounding.Down) / 365 / 24 / 60 / 60;
        uint256 absoluteVaultSupplied = MathUpgradeable.min(vaultFlrBalance, loansOutstanding);
        uint256 percentVaultSupplied = absoluteVaultSupplied.mulDiv(10 ** 18, loansOutstanding, MathUpgradeable.Rounding.Down);
        uint256 rewardsPerSecondWeighted = rewardsPerSecond.mulDiv(percentVaultSupplied, 10 ** 18, MathUpgradeable.Rounding.Down);
        return outstandingRewardsSnapshot + rewardsPerSecondWeighted * timeSinceLastOutstandingRewardsSnapshot;
    }

    /** @dev See {IERC4626-totalAssets}. */
    function totalAssets() public view virtual override returns (uint256) {
        return IERC20Upgradeable(asset()).balanceOf(address(this)) + calculateOutstandingRewards();
    }

    /// @dev Deposit outstanding rewards to the vault. This function expects the rewards in FlorinTreasury.eurToken
    /// and mints an equal amount of FLR into the vault
    /// @param rewards to be deposited in FlorinTreasury.eurToken [18 decimals, see FlorinTreasury.depositEUR]
    function depositRewards(uint256 rewards) external whenNotPaused {
        _snapshotOutstandingRewards();
        rewards = MathUpgradeable.min(outstandingRewardsSnapshot, rewards);
        outstandingRewardsSnapshot -= rewards;
        _increaseAssets(rewards);
        florinTreasury.depositEUR(_msgSender(), rewards);
        emit DepositRewards(rewards);
    }

    /// @dev Set the APR for the vault. This does NOT affect rewards retroactively.
    /// @param _apr the APR
    function setApr(uint256 _apr) external onlyOwner {
        _snapshotOutstandingRewards();
        apr = _apr;
        emit SetApr(apr);
    }

    /**
     * @dev Deposit/mint common workflow. Only overriden to inject _snapshotOutstandingRewards call
     */
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal virtual override {
        _snapshotOutstandingRewards();
        return super._deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Withdraw/redeem common workflow. Only overriden to inject _snapshotOutstandingRewards call
     */
    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares) internal virtual override {
        _snapshotOutstandingRewards();
        return super._withdraw(caller, receiver, owner, assets, shares);
    }

    /////////////////////////////////////////////////////////////////////////
    /////////////////////////////FUNDING/////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////

    /// @dev Fund a fundingRequest. The funds will be sent to the delegate in the process. In return the funder receives FLR
    /// based on the current exchange rate of their currency
    /// @param fundingToken to be deposited in FlorinTreasury.eurToken [18 decimals, see FlorinTreasury.depositEUR]
    /// @param fundingTokenAmount to be deposited in FlorinTreasury.eurToken [18 decimals, see FlorinTreasury.depositEUR]
    function fund(IERC20Upgradeable fundingToken, uint256 fundingTokenAmount) external whenNotPaused {
        (uint256 nextOpenFundingRequestId, uint256 flrFundingAmount, uint256 shares, uint256 cappedFundingTokenAmount) = _previewFund(
            _msgSender(),
            fundingToken,
            fundingTokenAmount
        );

        FundingRequest storage currentFundingRequest = fundingRequests[nextOpenFundingRequestId];

        lastProcessedFundingRequestId = currentFundingRequest.id;

        currentFundingRequest.state = FundingRequestState.PARTIALLY_FILLED;

        currentFundingRequest.amountFilled += flrFundingAmount;

        if (currentFundingRequest.amountRequested == currentFundingRequest.amountFilled) {
            currentFundingRequest.state = FundingRequestState.FILLED;
        }

        _snapshotOutstandingRewards();

        loansOutstanding += flrFundingAmount;

        _mint(_msgSender(), shares);

        florinTreasury.mint(address(this), flrFundingAmount);

        SafeERC20Upgradeable.safeTransferFrom(fundingToken, _msgSender(), currentFundingRequest.delegate, cappedFundingTokenAmount);

        emit Fund(_msgSender(), fundingToken, cappedFundingTokenAmount, flrFundingAmount, shares);
    }

    function previewFund(address wallet, IERC20Upgradeable fundingToken, uint256 fundingTokenAmount) external view returns (uint256) {
        (, , uint256 shares, ) = _previewFund(wallet, fundingToken, fundingTokenAmount);
        return shares;
    }

    function _previewFund(address wallet, IERC20Upgradeable fundingToken, uint256 fundingTokenAmount) internal view returns (uint256, uint256, uint256, uint256) {
        require(isPrimaryFunder(wallet), "caller must be delegate");
        require(isFundingToken(fundingToken), "unrecognized funding token");
        require(getNextOpenFundingRequestId() != NO_FUNDING_REQUEST, "no open funding request");
        FundingRequest memory currentFundingRequest = fundingRequests[getNextOpenFundingRequestId()];

        (uint256 exchangeRate, uint256 exchangeRateDecimals) = getFundingTokenExchangeRate(fundingToken);

        uint256 currentFundingNeedInFLR = currentFundingRequest.amountRequested - currentFundingRequest.amountFilled;

        uint256 currentFundingNeedInFundingToken = (Util.convertDecimalsERC20(currentFundingNeedInFLR, florinTreasury.florinToken(), fundingToken) * exchangeRate) /
            (uint256(10) ** exchangeRateDecimals);

        uint256 flrFundingAmount;

        if (fundingTokenAmount > currentFundingNeedInFundingToken) {
            fundingTokenAmount = currentFundingNeedInFundingToken;
            flrFundingAmount = currentFundingNeedInFLR;
        } else {
            flrFundingAmount = ((Util.convertDecimalsERC20(fundingTokenAmount, fundingToken, florinTreasury.florinToken()) * (uint256(10) ** exchangeRateDecimals)) / exchangeRate);
        }

        return (currentFundingRequest.id, flrFundingAmount, previewDeposit(flrFundingAmount), fundingTokenAmount);
    }

    function addFundingRequest(uint256 amountRequested) external onlyDelegate whenNotPaused {
        require(amountRequested > 0, "amountRequested must be > 0");
        uint256 fundingRequestId = fundingRequests.length;
        fundingRequests.push(FundingRequest(fundingRequestId, _msgSender(), amountRequested, 0, FundingRequestState.OPEN));
        emit AddFundingRequest(fundingRequestId, amountRequested);
    }

    function cancelFundingRequest(uint256 fundingRequestId) public whenNotPaused {
        require(fundingRequestId < fundingRequests.length, "fundingRequest does not exist");
        FundingRequest storage fundingRequest = fundingRequests[fundingRequestId];

        if (_msgSender() != owner()) {
            require(fundingRequest.delegate == _msgSender(), "caller must be owner or delegate");
            require(fundingRequest.state == FundingRequestState.OPEN, "delegate can only cancel OPEN fundingRequests");
        }

        fundingRequest.state = FundingRequestState.CANCELLED;
        emit CancelFundingRequest(fundingRequestId);
    }

    function getNextOpenFundingRequestId() public view returns (uint256) {
        for (uint256 i = lastProcessedFundingRequestId; i < fundingRequests.length; i++) {
            FundingRequest memory fundingRequest = fundingRequests[i];
            if (fundingRequest.state == FundingRequestState.OPEN || fundingRequest.state == FundingRequestState.PARTIALLY_FILLED) return fundingRequest.id;
        }
        return NO_FUNDING_REQUEST;
    }

    function getLastFundingRequestId() public view returns (uint256) {
        if (fundingRequests.length == 0) return NO_FUNDING_REQUEST;
        return fundingRequests[fundingRequests.length - 1].id;
    }

    function getFundingRequest(uint256 fundingRequestId) public view returns (FundingRequest memory) {
        require(fundingRequestId < fundingRequests.length, "fundingRequest does not exist");
        return fundingRequests[fundingRequestId];
    }

    function getFundingRequests() public view returns (FundingRequest[] memory) {
        return fundingRequests;
    }

    function getFundingTokenExchangeRate(IERC20Upgradeable fundingToken) public view returns (uint256, uint8) {
        require(isFundingToken(fundingToken), "unrecognized funding token");
        require(address(fundingTokenChainLinkFeeds[fundingToken]) != address(0), "no exchange rate available");

        (, int256 exchangeRate, , , ) = fundingTokenChainLinkFeeds[fundingToken].latestRoundData();
        require(exchangeRate != 0, "zero exchange rate");

        uint8 exchangeRateDecimals = fundingTokenChainLinkFeeds[fundingToken].decimals();

        if (invertFundingTokenChainLinkFeedAnswer[fundingToken]) {
            exchangeRate = int256(10 ** (exchangeRateDecimals * 2)) / exchangeRate;
        }

        return (uint256(exchangeRate), exchangeRateDecimals);
    }

    function setFundingTokenChainLinkFeed(
        IERC20Upgradeable fundingToken,
        AggregatorV3Interface fundingTokenChainLinkFeed,
        bool invertFundingTokenChainLinkFeedAnswer_
    ) external onlyOwner {
        fundingTokenChainLinkFeeds[fundingToken] = fundingTokenChainLinkFeed;
        invertFundingTokenChainLinkFeedAnswer[fundingToken] = invertFundingTokenChainLinkFeedAnswer_;
        emit SetFundingTokenChainLinkFeed(fundingToken, fundingTokenChainLinkFeed, invertFundingTokenChainLinkFeedAnswer_);
    }

    function getFundingTokenChainLinkFeed(IERC20Upgradeable _fundingToken) external view returns (AggregatorV3Interface, bool) {
        return (fundingTokenChainLinkFeeds[_fundingToken], invertFundingTokenChainLinkFeedAnswer[_fundingToken]);
    }

    function setFundingToken(IERC20Upgradeable fundingToken, bool accepted) external onlyOwner {
        if (fundingTokens[fundingToken] != accepted) {
            fundingTokens[fundingToken] = accepted;
            emit SetFundingToken(fundingToken, accepted);
            if (accepted) {
                _fundingTokens.push(fundingToken);
            } else {
                Util.removeValueFromArray(fundingToken, _fundingTokens);
            }
        }
    }

    function getFundingTokens() external view returns (IERC20Upgradeable[] memory) {
        return _fundingTokens;
    }

    function isFundingToken(IERC20Upgradeable _fundingToken) public view returns (bool) {
        return fundingTokens[_fundingToken];
    }

    function setPrimaryFunder(address primaryFunder, bool accepted) external onlyOwner {
        if (primaryFunders[primaryFunder] != accepted) {
            primaryFunders[primaryFunder] = accepted;
            emit SetPrimaryFunder(primaryFunder, accepted);
        }
    }

    function isPrimaryFunder(address primaryFunder_) public view returns (bool) {
        return primaryFunders[primaryFunder_];
    }

    function setDelegate(address delegate_) external onlyOwner {
        if (delegate != delegate_) {
            delegate = delegate_;
            emit SetDelegate(delegate);
        }
    }

    function isDelegate(address delegate_) external view returns (bool) {
        return delegate == delegate_;
    }
}