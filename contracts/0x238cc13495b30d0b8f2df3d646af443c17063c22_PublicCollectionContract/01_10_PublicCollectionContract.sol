// SPDX-License-Identifier: Business Source License 1.1 see LICENSE.txt
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./libraries/UniERC20.sol";

interface DepositInterface {
    function deposit(uint nDays) external returns(uint256 newTokensToMint);
}

interface PoolInterface {
    function nTokens() external view returns (uint);
    function tokenAt(uint i) external view returns (address);
    function findBalanceAndMultiplier(ERC20 token) external view returns(uint256 balance, uint256 M, uint256 marketWeight);
    function depositContract() external view returns (address);
}

// Interface used for checking deposits
interface BlackListInterface {
    function blocked(address depositor) external view returns (bool);
}


contract PublicCollectionContract is ReentrancyGuard {
    using UniERC20 for ERC20;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public clipperPool;
    address approvalContract;

    address constant CLIPPER_ETH_SIGIL = address(0);
    uint256 constant ONE_IN_DEFAULT_DECIMALS = 1e18;
    uint256 constant ONE_IN_16_DECIMALS = 1e16;
    uint8 constant DEFAULT_DECIMALS = 18;
    uint8 constant DAYS_UNTIL_FAILURE = 90;
    uint8 constant MINIMUM_SATISFYING_ASSET_PERCENT = 98;
    uint32 constant SECONDS_IN_A_DAY = 86400;
    
    bool public depositHasBeenMade = false;
    uint256 public totalPoolTokens;
    uint256 public totalDeposit;
    
    uint256 public immutable withdrawalTimestamp;
    uint256 public immutable fundraiseFailTimestamp;
    uint256 public immutable maxUserDeposit;
    uint256 public immutable totalDollarTarget;

    mapping(address => uint256) public userDollarDeposits;
    mapping(ERC20 => uint256) public assetDollarTargets;
    EnumerableSet.AddressSet private assetSet;

    event Deposited(
        address indexed account,
        address indexed token,
        uint256 rawAmount,
        uint256 dollarAmount
    );

    event TokensWithdrawn(
        address indexed account,
        uint256 poolTokens
    );

    event DepositWithdrawn(
        address indexed account,
        uint256 dollarAmount
    );

    modifier atFundraisingState() {
        require(!depositHasBeenMade && block.timestamp < fundraiseFailTimestamp, "Not at Fundraising state");
        _;
    }

    modifier atEscapeState() {
        require(!depositHasBeenMade && block.timestamp >= fundraiseFailTimestamp, "Not at Escape state");
        _;
    }

    modifier atWithdrawalState() {
        require(depositHasBeenMade && block.timestamp >= withdrawalTimestamp, "Not at Withdrawal state");
        _;
    }

    // @param _maxDeposit maximum dollar deposit value allowed per address. 1 = $1 (i.e. 10000 = $10,000 USD)
    // @param _totalTargetValue maximum total dollar value.  1 = $1 (i.e. 50000 = $50,000 USD)
    // @param _poolAddress
    // @param _approvalContract
    // @param _withdrawalTimestamp Seconds since epoch. E.g. 90 days from now.
    constructor(uint256 _maxDeposit, uint256 _totalTargetValue, address _poolContract, address _approvalContract, uint256 _withdrawalTimestamp) {
        require(_maxDeposit > 0, "Max deposit value has to be greater than 0");
        require(_totalTargetValue > _maxDeposit, "Target value has to be greater than the max deposit value");
        
        clipperPool = _poolContract;
        maxUserDeposit = _maxDeposit * ONE_IN_DEFAULT_DECIMALS; 
        totalDollarTarget = _totalTargetValue * ONE_IN_DEFAULT_DECIMALS;
        approvalContract = _approvalContract;
        fundraiseFailTimestamp = block.timestamp + (DAYS_UNTIL_FAILURE*SECONDS_IN_A_DAY);
        withdrawalTimestamp = _withdrawalTimestamp;

        // calculate dollar targets per asset
        // Dollar target for each asset should be proportional to 1/multiplier
        // Pool fraction for asset i is 1/multiplier i (1/sum j (1/multiplier j))
        // that would be translated to something like this for an asset with 100 as marketWeight:
        // (1/100)*(1/(1/100 + 1/100 + 1/188 + 1/250 + 1/250)) = 0.3001277139
        // As we are getting the dollar amount we replace 1 by the total amount so we get the actual
        // dollar amount instead of the percentage proportion
        // 
        ERC20 token;
        uint i = 0;
        uint n = PoolInterface(clipperPool).nTokens();
        uint256 sumInverseMarketWeight = 0;
        uint256 assetMarketWeightMultiplier;

        // other ERC20 tokens
        while(i < n) {
            token = ERC20(PoolInterface(clipperPool).tokenAt(i));
            (uint256 balance, uint256 M, uint256 marketWeight) = PoolInterface(clipperPool).findBalanceAndMultiplier(token);
            sumInverseMarketWeight += _divideWithDefaultDecimals(_totalTargetValue, marketWeight);
            assetSet.add(address(token));
            i++;
        }

        {// scope to avoid stack too deep errors
            // ETH
            token = ERC20(CLIPPER_ETH_SIGIL);
            (uint256 balance, uint256 M, uint256 marketWeight) = PoolInterface(clipperPool).findBalanceAndMultiplier(token);
            sumInverseMarketWeight += _divideWithDefaultDecimals(_totalTargetValue, marketWeight);
            assetMarketWeightMultiplier = _divideWithDefaultDecimals(_totalTargetValue, sumInverseMarketWeight);

            // ETH target dollar
            assetDollarTargets[token] = _divideWithDefaultDecimals(_totalTargetValue, marketWeight) * assetMarketWeightMultiplier;
            assetSet.add(address(token));
        }

        // other ERC20 tokens target dollar
        i = 0;
        while(i < n) {
            token = ERC20(PoolInterface(clipperPool).tokenAt(i));
            (uint256 balance, uint256 M, uint256 marketWeight) = PoolInterface(clipperPool).findBalanceAndMultiplier(token);
            assetDollarTargets[token] = _divideWithDefaultDecimals(_totalTargetValue, marketWeight) * assetMarketWeightMultiplier;
            i++;
        }
    }

    // We want to be able to receive ETH
    receive() external payable {}

    // @dev calculates the quotient by using DEFAULT_DECIMALS on the numerator
    // it is meant to be used for integer amounts that are not converted to the DEFAULT_DECIMALS 
    // without losing the precision when solidity rounds down on divisions
    // i.e. 1/188 -> 100000000000000000/188
    // @param _numerator is an integer
    // @param _denominator is an integer
    // @return quotient in DEFAULT_DECIMALS
    function _divideWithDefaultDecimals(uint256 _numerator, uint256 _denominator)
        private
        pure
        returns(uint256 quotient)
    {
        _numerator  = _numerator * ONE_IN_DEFAULT_DECIMALS;
        quotient = _numerator / _denominator;
    }

    // @dev calculates the dollar amount for a token amount given
    // @param multiplier 
    // @param marketWeight
    // @param tokenAmount using the token decimals
    // @return dollarAmount in DEFAULT_DECIMALS
    function _getDollarAmountInDefaultDecimals(uint256 multiplier, uint256 marketWeight, uint256 tokenAmount)
        private
        pure
        returns (uint256 dollarAmount)
    {
        // as M/Marketwight is in 34 decimals we adjust to 18
        dollarAmount = ((multiplier / marketWeight) * tokenAmount) / ONE_IN_16_DECIMALS;
    }

    // @dev holds the user deposit validations
    // it will revert if the validations fail
    // @param tokenAddress 
    // @param amount in raw with the asset decimals
    // @return dollarAmount in DEFAULT_DECIMALS
    function canDeposit(address tokenAddress, uint256 amount)
        public
        view
        atFundraisingState
        returns (uint256 dollarAmount) 
    {
        require(assetSet.contains(tokenAddress) && (amount > 0), "Invalid deposit input");

        // sender address cannot be in the black list or a contract
        require(!BlackListInterface(approvalContract).blocked(msg.sender) && !address(msg.sender).isContract(), "Sender address is forbidden");

        // only single deposits by address are allowed
        require(userDollarDeposits[msg.sender] == 0, "Sender address already has a deposit");

        // get dollar price and value
        ERC20 token = ERC20(tokenAddress);
        (uint256 balance, uint256 M, uint256 marketWeight) = PoolInterface(clipperPool).findBalanceAndMultiplier(token);
        uint256 currBalanceValue = _getDollarAmountInDefaultDecimals(M, marketWeight, token.uniBalanceOf(address(this)));
        dollarAmount = _getDollarAmountInDefaultDecimals(M, marketWeight, amount);

        require(currBalanceValue <= assetDollarTargets[token], "Target value for the token was already reached");
        require(dollarAmount <= maxUserDeposit, "Deposit value is greater than the maximum allowed amount");
    }

    // @dev deposits an asset token amount into the contract
    // it will revert if the validations fail
    // @param tokenAddress 
    // @param amount in raw with the asset decimals
    // @return dollarAmount in DEFAULT_DECIMALS
    function userDeposit(address tokenAddress, uint256 amount)
        external
        payable
        atFundraisingState
        returns (uint256 dollarAmount)
    {
        // this will revert if the user cannot make a deposit
        dollarAmount = canDeposit(tokenAddress, amount);
        
        // transfer of amount to contract
        ERC20 token = ERC20(tokenAddress);
        token.uniTransferFromSender(amount, address(this));

        // register deposit
        userDollarDeposits[msg.sender] = dollarAmount;
        totalDeposit += dollarAmount;

        emit Deposited(msg.sender, tokenAddress, amount, dollarAmount);
    }

    // @dev handles the deposit of the assets to the pool contract
    function deposit()
        external
        atFundraisingState
    {   
        // transition to vesting state
        // Checks-Effects-Interactions pattern
        depositHasBeenMade = true;

        uint i = 0;
        uint n = assetSet.length();
        while(i < n) {
            ERC20 token = ERC20(assetSet.at(i));
            (uint256 balance, uint256 M, uint256 marketWeight) = PoolInterface(clipperPool).findBalanceAndMultiplier(token);
            uint256 dollarTarget = assetDollarTargets[token];
            uint256 tokenBalance = token.uniBalanceOf(address(this));
            uint256 tokenDollarBalanceInDefaultDecimals = _getDollarAmountInDefaultDecimals(M, marketWeight, tokenBalance);
            uint256 minTarget = (dollarTarget * MINIMUM_SATISFYING_ASSET_PERCENT) / 100;
            
            if (tokenDollarBalanceInDefaultDecimals >= minTarget) {
                token.uniTransfer(clipperPool, tokenBalance);
            } else {
                revert("Required minimum deposits for all tokens has not been reached");
            }

            i++;
        }

        // make deposit
        address depositContract = PoolInterface(clipperPool).depositContract();
        totalPoolTokens = DepositInterface(depositContract).deposit(0);
    }

    // @dev it handles the withdrawal of a pro-rata share of the tokens
    // back to the user
    // it only works on ESCAPE state
    function escapeDeposit()
    external
    nonReentrant
    atEscapeState
    {
        uint256 userDeposit = userDollarDeposits[msg.sender];
        require(userDeposit > 0, "Sender does not have a deposit");

        // calculate pro rata tokens
        uint256 fractionInDefaultDecimals = _divideWithDefaultDecimals(userDeposit, totalDeposit);
        require(fractionInDefaultDecimals > 0, "Sender pro rata must be greater than 0");

        // Checks-Effects-Interactions pattern
        delete userDollarDeposits[msg.sender];
        totalDeposit -= userDeposit;

        uint i = 0;
        uint n = assetSet.length();
        while(i < n) {
            ERC20 token = ERC20(assetSet.at(i));
            uint256 balance = token.uniBalanceOf(address(this));
            uint256 toTransfer = (fractionInDefaultDecimals * balance) / ONE_IN_DEFAULT_DECIMALS;
            token.uniTransfer(msg.sender, toTransfer);
            i++;
        }

        emit DepositWithdrawn(msg.sender, userDeposit);
    }

    // @dev it handles the withdrawal of a pro-rata share of the pool tokens
    // back to the user
    // it only works on WITHDRAWAL state
    // @return userPoolTokens is the amount of Pool tokens earned by the user
    function withdrawPoolTokens()
        external
        nonReentrant
        atWithdrawalState
        returns (uint256 _userPoolTokens)
    {
        _userPoolTokens = poolTokens();

        // Checks-Effects-Interactions pattern
        delete userDollarDeposits[msg.sender];

        // send tokens to user
        ERC20 poolToken = ERC20(clipperPool);
        poolToken.uniTransfer(msg.sender, _userPoolTokens);

        emit TokensWithdrawn(msg.sender, _userPoolTokens);
    }

    // @dev it handles the calculation of a pro-rata share of the pool tokens
    // @return userPoolTokens is the amount of Pool tokens that the user will earn with the current deposit
    function poolTokens()
        public
        view
        returns (uint256 _userPoolTokens)
    {
        uint256 userDeposit = userDollarDeposits[msg.sender];
        require(userDeposit > 0, "Sender does not have a deposit");

        // calculate pro rata tokens
        uint256 fraction = _divideWithDefaultDecimals(userDeposit, totalDeposit);

        _userPoolTokens = (fraction * totalPoolTokens) / ONE_IN_DEFAULT_DECIMALS;
    }
}