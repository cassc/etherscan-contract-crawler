// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface IAthStaking {
    function athLevel(address user_) external view returns(uint256 level);
}

/// @title IDOPool
/// @notice IDO contract useful for launching NewIDO
//solhint-disable-next-line max-states-count
contract IDOPool is Ownable, ReentrancyGuard {
    enum InvestorType {
        LEVEL_0,
        LEVEL_1,
        LEVEL_2,
        LEVEL_3
    }

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev Struct to store information of each Sale
     * @param investor Address of user/investor
     * @param amount Amount of tokens to be purchased
     * @param tokensWithdrawn Amount of Tokens Withdrawal
     * @param tokenWithdrawnStatus Tokens Withdrawal status
     */
    struct Sale {
        address investor;
        uint256 amount;
        uint256 feePaid;
        uint256 allocatedAmount;
        uint256 tokensWithdrawn;
        bool tokenWithdrawnStatus;
    }

    // Token for sale
    IERC20 public token;
    // Token Decimal
    uint256 public tokenDecimal;
    // Token used to buy
    IERC20 public currency;
    // Ath Staking contract
    IAthStaking public athStaking;

    // DEV TEAM Address
    address public devAddress;
    // List investors
    address[] private investorList;
    // Info of each investor that buy tokens.
    mapping(address => Sale) public sales;
    // pre-sale start time
    uint256 public startTime;
    // pre-sale end time
    uint256 public endTime;
    // funding Period
    uint256 public fundingPeriod;
    // Price of each token
    uint256 public price;
    // Amount of tokens remaining
    uint256 public availableTokens;
    // Total amount of tokens to be sold
    uint256 public totalAmount;
    // Total amount sold
    uint256 public totalAmountSold;
    // Release time
    uint256 public releaseTime;
    // total collected Fee
    uint256 public collectedFee;
    // total fund rasied
    uint256 public totalFundRaised;
    // total pre-sale token suppiled
    uint256 public totalIDOTokenSupplied;
    // total pre-sale token claimed by user
    uint256 public totalIDOTokenClaimed;
    // Number of investors
    uint256 public numberParticipants;
    // Amount of tokens remaining w.r.t Tier
    mapping(uint8 => uint256) public tierMaxAmountThatCanBeInvested;
    // Participation fee based on Ath Staking Level
    mapping(uint8 => uint256) public participationFee;

    /************************* Event's *************************/

    event Buy(address indexed _user, uint256 _amount, uint256 fee, uint256 _tokenAmount);
    event Claim(address indexed _user, uint256 _amount);
    event Withdraw(address indexed _user, uint256 _amount);
    event EmergencyWithdraw(address indexed _user, uint256 _amount);
    event TokenRecovered(address indexed _user, address indexed _token, uint256 _amount);
    event TokenAddressUpdated(address indexed _user, address indexed _token);
    event AthStakingUpdated(address indexed _user, address _oldStaking, address _newStaking);
    event DevAddressUpdated(address indexed _user, address _oldDev, address _newDev);
    event IDOTokenSupplied(address indexed _user, uint256 _amount);

    /**************************************************************/

    /************************* Modifier's *************************/

    modifier publicSaleActive() {
        require(
            block.timestamp >= startTime,
            "Public sale is not yet activated"
        );
        _;
    }

    modifier publicSaleEnded() {
        require((block.timestamp > endTime || availableTokens == 0), "Public sale not yet ended");
        _;
    }

    modifier canClaim() {
        require(block.timestamp >= releaseTime, "Please wait until release time for claiming tokens");
        _;
    }

    /**********************************************************/

    /**
     * @dev Initialzes the TierIDO Pool contract
     * @param _token The ERC20 token contract address
     * @param _tokenDecimal The ERC20 token decimal
     * @param _currency The curreny used for the IDO
     * @param _startTime Timestamp of when pre-Sale starts
     * @param _fundingPeriod funding Period in seconds
     * @param _releaseTime Timestamp of when the token will be released
     * @param _price Price of the token for the IDO
     * @param _totalAmount The total amount for the IDO
     */
    //solhint-disable-next-line function-max-lines
    constructor(
        address _token,
        uint256 _tokenDecimal,
        address _currency,
        uint256 _startTime,
        uint256 _fundingPeriod,
        uint256 _releaseTime,
        uint256 _price,
        uint256 _totalAmount
    ) public {
        require(_tokenDecimal > 0, "_tokenDecimal must be greater Zero");
        require(_currency != address(0), "Currency address cannot be address zero");
        require(_startTime >= block.timestamp, "start time > current time");
        require(_fundingPeriod >= 1 hours, "_fundingPeriod time > 1 hour");
        require(_releaseTime > _startTime + _fundingPeriod, "release time > end time");
        require(_totalAmount > 0, "Total amount must be > 0");

        token = IERC20(_token);
        tokenDecimal = _tokenDecimal;
        currency = IERC20(_currency);
        startTime = _startTime;
        endTime = _startTime + _fundingPeriod;
        fundingPeriod = _fundingPeriod;
        releaseTime = _releaseTime;
        price = _price;
        totalAmount = _totalAmount;
        availableTokens = _totalAmount;

        athStaking = IAthStaking(0x48E5Fc0cD874fB2eC9C5dd67d3e141C0DA152DA3);
    }

    /************************* Internal function's *************************/

    /**
     * @dev To determine whether investor can buy depending on the investor type
     */
    function isParticipationTimeCrossed(InvestorType _investoryType) public view returns (bool) {
        uint256 lockPeriod = fundingPeriod.div(4);
        if (_investoryType == InvestorType.LEVEL_0) {
            return (now >= startTime.add(lockPeriod.mul(3)));
        } else if (_investoryType == InvestorType.LEVEL_1) {
            return (now >= startTime.add(lockPeriod.mul(2)));
        } else if (_investoryType == InvestorType.LEVEL_2) {
            return (now >= (startTime + lockPeriod));
        } else if (_investoryType == InvestorType.LEVEL_3) {
            return (now >= startTime);
        } else {
            return false;
        }
    }

    /**
     * @dev To transfer Currency token
     */
    function transferCurrencyToken() internal {
        uint256 currencyBalance = currency.balanceOf(address(this));

        currency.safeTransfer(owner(), collectedFee);
        emit Withdraw(owner(), collectedFee);

        currency.safeTransfer(devAddress, currencyBalance.sub(collectedFee));
        emit Withdraw(devAddress, currencyBalance.sub(collectedFee));
    }

    /***********************************************************************/

    /*************************** view function's ***************************/

    /**
     * @dev claimable amount of IDO token
     * Returns amount IDO token available to claim
     */
    function claimableAmount(address _user) public view returns (uint256 _tokenAmount){
        Sale memory sale = sales[_user];

        if (block.timestamp < releaseTime || sale.tokenWithdrawnStatus || sale.allocatedAmount == 0) {
            return 0;
        }

        uint256 tAmount = sale.allocatedAmount.mul(totalIDOTokenSupplied).div(totalAmountSold);
        _tokenAmount = tAmount.sub(sale.tokensWithdrawn);
    }


    /**
     * @dev To get investor of the IDO
     * Returns array of investor addresses and their invested funds
     */
    function getInvestorsDetails() external view returns (address[] memory, uint256[] memory, uint256[] memory) {
        address[] memory addrs = new address[](numberParticipants);
        uint256[] memory funds = new uint256[](numberParticipants);
        uint256[] memory allocatedfunds = new uint256[](numberParticipants);

        for (uint256 i = 0; i < numberParticipants; i++) {
            addrs[i] = sales[investorList[i]].investor;
            funds[i] = sales[investorList[i]].amount;
            allocatedfunds[i] = sales[investorList[i]].allocatedAmount;
        }

        return (addrs, funds, allocatedfunds);
    }

    /**
     * @dev To get investor address of the IDO
     * Returns only array of investor addresses
     */
    function getInvestorList() external view returns(address[] memory) {
        return investorList;
    }

    /**
     * @dev To get type of investor depending on amount Ath staked
     */
    function getInvestorType(address _user) public view returns (InvestorType level) {
        level = InvestorType(athStaking.athLevel(_user));
        require(level <= InvestorType.LEVEL_3, "Derived Level is out of Range");
    }

    /***********************************************************************/

    /************************ Restricted function's ************************/

    /**
     * @dev To withdraw tokens after the sale ends and burns the remaining tokens
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     * - the public sale must have ended
     * - this call is non reentrant
     */
    function withdraw() external onlyOwner publicSaleEnded nonReentrant {
        if (availableTokens > 0) {
            availableTokens = 0;
        }

        transferCurrencyToken();
    }

    /**
     * @dev To withdraw in case of any possible hack/vulnerability
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     * - this call is non reentrant
     */
    function emergencyWithdraw() external onlyOwner nonReentrant {
        if (availableTokens > 0) {
            availableTokens = 0;
        }

        if (totalIDOTokenSupplied > 0 &&
            totalIDOTokenSupplied > totalIDOTokenClaimed) {
                token.transfer(owner(), totalIDOTokenSupplied.sub(totalIDOTokenClaimed));
        }
        transferCurrencyToken();
    }

    /**
     * @dev To add users and tiers to the contract storage
     * @param _participationFees An array of participation fee as per tiers
     * @param _maxAmountThatCanBeInvestedInTiers An array of max investments amount in tiers
     */
    function setTierInfo(
            uint256[] memory _participationFees,
            uint256[] memory _maxAmountThatCanBeInvestedInTiers
    )
        public onlyOwner
    {
        for (uint8 i = 0; i < _maxAmountThatCanBeInvestedInTiers.length; i++) {
            require(_maxAmountThatCanBeInvestedInTiers[i] > 0, "Tier allocation amount must be > 0");
            // Since we have named Tier1, Tier2, Tier3 & Tier4
            tierMaxAmountThatCanBeInvested[i + 1] = _maxAmountThatCanBeInvestedInTiers[i];
            participationFee[i + 1] = _participationFees[i];
        }
    }

    /**
     * @dev To set the Ath Staking address
     * @param _athStaking ath staking contract address
     */
    function setAthStaking(address _athStaking) external onlyOwner {
        require(_athStaking != address(0x0), "_athStaking should be valid address");

        emit AthStakingUpdated(msg.sender, address(athStaking), _athStaking);
        athStaking = IAthStaking(_athStaking);
    }

    /**
     * @dev To set the DEV address
     * @param _devAddr dev wallet address.
     */
    function setDevAddress(address _devAddr) external onlyOwner {
        require(_devAddr != address(0x0), "_devAddr should be valid Address");

        emit DevAddressUpdated(msg.sender, devAddress, _devAddr);
        devAddress = _devAddr;
    }

    /**
     * @dev To set the Token address
     * @param _token token address.
     */
    function setTokenAddress(address _token) external onlyOwner {
        require(_token != address(0x0), "_token should be valid Address");

        token = IERC20(_token);
        tokenDecimal = token.decimals();

        emit TokenAddressUpdated(msg.sender, _token);
    }

    /**
     * @dev To recover ERC20 token sent to contract by mistake
     * @param _tokenAddress ERC20 token address which need to recover
     * @param _amount amount of token to be recover
     */
    function recoverToken(address _tokenAddress, uint256 _amount) external onlyOwner {
        IERC20 _token = IERC20(_tokenAddress);
        _token.safeTransfer(msg.sender, _amount);

        emit TokenRecovered(msg.sender, _tokenAddress, _amount);
    }

    /**
     * @dev To supply IDO token to contract
     * @param _amount amount of token to be supplied to contract
     */
    function supplyIDOToken(uint256 _amount) external onlyOwner {
        require(totalIDOTokenSupplied.add(_amount) <= totalAmountSold,
                    "IDO token amount is overflooded!!");

        token.safeTransferFrom(msg.sender, address(this), _amount);
        totalIDOTokenSupplied += _amount;

        emit IDOTokenSupplied(msg.sender, _amount);
    }

    /***********************************************************************/

    /************************* External function's *************************/
    /**
     * @dev To buy tokens
     *
     * @param amount The amount of tokens to buy
     *
     * Requirements:
     * - can be invoked only when the public sale is active
     * - this call is non reentrant
     */
    function buy(uint256 amount) external publicSaleActive nonReentrant {
        require(availableTokens > 0,
                "All tokens were purchased");

        require(amount > 0,
                "Amount must be > 0");


        require(currency.balanceOf(msg.sender) >= amount,
                "Insufficient currency balance of caller");

        InvestorType investorType = getInvestorType(msg.sender);
        require(isParticipationTimeCrossed(investorType),
                "Participation time is not yet crossed. Please wait.");

        uint8 tier = uint8(investorType) + 1;
        uint256 fee = amount.mul(participationFee[tier]).div(10000);
        if (fee > 0) {
            collectedFee = collectedFee.add(fee);
        }

        uint256 amountAfterFee = amount.sub(fee);
        uint256 allocatedToken = (amountAfterFee).mul(10 ** tokenDecimal).div(price);

        require(allocatedToken <= availableTokens,
                "Not enough tokens to buy");

        Sale storage sale = sales[msg.sender];
        require(sale.allocatedAmount.add(allocatedToken) <= tierMaxAmountThatCanBeInvested[tier],
                "amount exceeds buy limit");

        availableTokens = availableTokens.sub(allocatedToken);
        totalAmountSold = totalAmountSold.add(allocatedToken);
        totalFundRaised = totalFundRaised.add(amountAfterFee);

        currency.safeTransferFrom(msg.sender, address(this), amount);

        if (sale.allocatedAmount == 0) {
            sales[msg.sender] = Sale(msg.sender,
                                        amount,
                                        fee,
                                        allocatedToken,
                                        0,
                                        false);
            numberParticipants += 1;
            investorList.push(msg.sender);
        } else {
            sales[msg.sender] = Sale(msg.sender,
                                        sale.amount.add(amount),
                                        sale.feePaid.add(fee),
                                        sale.allocatedAmount.add(allocatedToken),
                                        0,
                                        false);
        }

        emit Buy(msg.sender, amount, fee, allocatedToken);
    }

    /**
     * @dev To withdraw purchased tokens after release time
     *
     * Requirements:
     * - this call is non reentrant
     * - cannot claim within release time
     */
    function claimTokens() external canClaim nonReentrant {
        Sale storage sale = sales[msg.sender];
        require(!sale.tokenWithdrawnStatus, "Already withdrawn");
        require(sale.allocatedAmount > 0, "Only investors");

        uint256 tokenAmount = claimableAmount(msg.sender);
        token.transfer(sale.investor, tokenAmount);

        sale.tokensWithdrawn += tokenAmount;
        totalIDOTokenClaimed += tokenAmount;
        if (sale.tokensWithdrawn == sale.allocatedAmount) {
            sale.tokenWithdrawnStatus = true;
        }

        emit Claim(msg.sender, tokenAmount);
    }

    /***********************************************************************/
}