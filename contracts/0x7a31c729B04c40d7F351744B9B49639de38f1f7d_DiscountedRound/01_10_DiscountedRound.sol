// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;


/**
 * @dev Modifier 'onlyOwner' becomes available, where owner is the contract deployer
 */ 
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev ERC20 token interface
 */
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Allows use of SafeERC20 transfer functions
 */
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev Chainlink price oracle interface
 */
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @dev Makes mofifier nonReentrant available for use
 */
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @dev SBT interface
 */
import "./Interfaces/ISBT.sol";



contract DiscountedRound is Ownable, ReentrancyGuard {

    
    using SafeERC20 for IERC20;


    // --- VARIABLES -- //

    ISBT sbt;
    AggregatorV3Interface internal priceFeed;

    address[] stables;

    address public claimContract;

    uint public roundStartTime;
    uint public roundEndTime;

    uint public tokenPrice = 0.5*10**6; // $0.50
    uint public walletTokenLimit = (36900*2)*10**18; // $36,900 worth of XCAL
    uint public totalTokenLimit; // 18 decimal

    uint public totalTokens; // 18 decimal

    bool public withdrawalsEnabled;



    // --- CONSTRUCTOR -- //

    
    constructor(
        uint _totalTokenLimit, // 6m mainnet ($3m) / 3m arb ($1.5m)
        address _dai,   // Eth main net: 0x6B175474E89094C44Da98b954EedeAC495271d0F  --- Arb: 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1
        address _frax,  // Eth main net: 0x853d955aCEf822Db058eb8505911ED77F175b99e  --- Arb: 0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F
        address _usdc,  // Eth main net: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48  --- Arb: 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8
        address _usdt,  // Eth main net: 0xdAC17F958D2ee523a2206206994597C13D831ec7  --- Arb: 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9
        address _sbtAddress,
        address _aggregatorContract // Eth main net: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419  --- Arb: 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612
        ) {
        
        totalTokenLimit = _totalTokenLimit;

        stables = [_dai, _frax, _usdc, _usdt];

        for (uint i=1; i<=stables.length; i++) {
            acceptedStables[stables[i-1]] = i;
        }

        sbt = ISBT(_sbtAddress);

        priceFeed = AggregatorV3Interface(_aggregatorContract);
    }

    

    // --- MAPPINGS -- //

    mapping(address => uint) acceptedStables;
    mapping(address => uint) userToXCAL;

    /* user -> (
        ETH: 0, 
        DAI: 1, 
        FRAX: 2,
        USDC: 3
        USDT: 4
        ) -> balance
    */
    mapping(address => mapping(uint => uint)) userDeposits;


    // --- EVENTS --- //

    event TokensPurchased(address indexed benificiary, uint amount);

    

    // --- USER FUNCTIONS -- //

    /// @dev Accepts direct ETH deposits. Functions the same as buyWithEth.
    receive() external payable {
        buyWithEth();
    }

    
    /**
     * @dev Exchange Ether for SBT representing ownership of XCAL tokens claimable upon XCAL token launch
     */
    function buyWithEth() public payable nonReentrant {

        require(
            msg.value > 0,
            "invalid amount"
        );

        require(
            block.timestamp >= roundStartTime && block.timestamp < roundEndTime,
            "Round not live"
        );

        uint numberOfTokens = (msg.value * uint(getLatestPrice())) / (tokenPrice * 10**2); 
        
        tokenPurchase(msg.sender, numberOfTokens);
        userDeposits[msg.sender][0] += msg.value;
    }


    /**
     * @dev Exchange DAI, FRAX, USDC or USDT for a SBT representing ownership of XCAL tokens claimable upon XCAL token launch
     * @param _amount - amount of stable coin to exchange
     * Note: Stable coin must already have been approved for spend
     */
    function buyWithStable(uint _amount, address _stable) public nonReentrant {

        require(
            acceptedStables[_stable] != 0,
            "Stable coin not accepted"
        );

        require(
            block.timestamp >= roundStartTime && block.timestamp < roundEndTime,
            "Round not live"
        );

        IERC20(_stable).safeTransferFrom(msg.sender, address(this), _amount);

        uint numberOfTokens;

        // if DAI or FRAX
        if (_stable == stables[0] || _stable == stables[1]) {
            numberOfTokens = (_amount*10**6) / tokenPrice; // accounting for DAI & FRAX 18 token decimals
        } else {
            numberOfTokens = (_amount*10**18) / tokenPrice;
        }

        tokenPurchase(msg.sender, numberOfTokens);
        userDeposits[msg.sender][acceptedStables[_stable]] += _amount;
    }


    function depositorEtherWithdrawal(address payable _recipient) public nonReentrant {

        require(
            withdrawalsEnabled,
            "Still within product launch window"
        );

        require(
            userDeposits[msg.sender][0] > 0,
            "No Ether to withdraw"
        );

        uint amount = userDeposits[msg.sender][0];
        userDeposits[msg.sender][0] = 0;

        _recipient.transfer(amount);

    }


    function depositorStableWithdrawal(address _stable, address _recipient) public nonReentrant {

        require(
            withdrawalsEnabled,
            "Still within product launch window"
        );

        require(
            userDeposits[msg.sender][acceptedStables[_stable]] > 0,
            "No tokens to withdraw"
        );

        uint amount = userDeposits[msg.sender][acceptedStables[_stable]];
        userDeposits[msg.sender][acceptedStables[_stable]] = 0;

        IERC20(_stable).safeTransfer(_recipient, amount);

    }


    // --- INTERNAL FUNCTIONS --- //

    /**
     * @dev Mints SBT if not already in possesion of one
     * @param _user - user address to mint SBT to and attribute owed XCAL to
     * @param _numberOfTokens - amount of XCAL owed to _user upon XCAL token launch
     */
    function tokenPurchase(address _user, uint _numberOfTokens) internal {

        require(
            userToXCAL[_user] + _numberOfTokens <= walletTokenLimit,
            "Purchasing that many would exceed wallet token limit"
        );

        require(
            totalTokens + _numberOfTokens <= totalTokenLimit,
            "Purchasing that many would exceed total token limit"
        );

        userToXCAL[_user] += _numberOfTokens;
        totalTokens += _numberOfTokens;

        // no need to mint new SBT if _user already owns one
        if ((sbt.balanceOf(_user)) < 1) {
            sbt.mint(_user);
        }

        emit TokensPurchased(_user, _numberOfTokens);
    }


    // --- VIEW FUNCTIONS -- //


    /**
     * @dev Returns the amount of ETH still possible to deposit for a given address
     */
    function remainingEthDeposit(address _depositer) public view returns(uint) {

        uint remainingUsdValue = (walletTokenLimit - userToXCAL[_depositer]) / 2; // 18 decimal

        return (remainingUsdValue *10**8) / uint(getLatestPrice()); // 18 decimal
    }
   
    /**
     * @dev Returns the latest price of ETH/USD as proposed by Chainlink's price oracle
     */
    function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

        return price;
    }

    /**
     * @dev View number of XCAL tokens owed to _user (18 token decimal)
     * @param _user - address of user XCAL balance to view
     * Note: only callable by contract owner OR if msg.sender == _user
     */
    function viewUserTokens(address _user) public view returns(uint) {

        require(
            msg.sender == _user || msg.sender == owner() || msg.sender == claimContract,
            "msg.sender must be '_user' OR contract owner"
        );

        return userToXCAL[_user];
    }

    /**
     * @dev View user deposits
     * @param _user - address of depositor
     * @param _tokenId - 0: ETH, 1: DAI, 2: FRAX, 3: USDC, 4: USDT
     */
    function viewUserDeposits(address _user, uint _tokenId) public view returns(uint) {
        return userDeposits[_user][_tokenId];
    }
    


    // --- ONLY OWNER --- //

    /**
     * @dev Set the start and end timestamps of the round
     * @param _startTimestamp - unix timestamp of round start
     * @param _endTimestamp - unix timestamp of round end
     * Note: only callable by contract owner
     */
    function setRoundTimestamps(uint _startTimestamp, uint _endTimestamp) public onlyOwner {

        require(
            roundStartTime == 0 && roundEndTime == 0,
            "Round start and end times can only be set once"
        );
        
        require(
            _endTimestamp > _startTimestamp,
            "round cannot end before it starts"
        );

        roundStartTime = _startTimestamp;
        roundEndTime = _endTimestamp;
    }

    /**
     * @dev Set the address of the SBT contract
     * @param _sbtAddress - address of SBT contract
     * Note: only callable by contract owner
     */
    function setSBT(address _sbtAddress) public onlyOwner {
        sbt = ISBT(_sbtAddress);
    }

    /**
     * @dev Set the address of the Claim contract
     * @param _claimAddress - address of Claim contract
     * Note: only callable by contract owner
     */
    function setClaimContract(address _claimAddress) public onlyOwner {
        claimContract = _claimAddress;
    }

    /**
     * @dev Set the maximum number of tokens availbale for purcahse by any one wallet (18 token decimal)
     * @param _walletTokenLimit - number of tokens availbale for purcahse by any one wallet
     * Note: only callable by contract owner
     */
    function setWalletTokenLimit(uint _walletTokenLimit) public onlyOwner {
        walletTokenLimit = _walletTokenLimit;
    }

    /**
     * @dev Set the maximum number of tokens availbale for purcahse via this contract (18 token decimal)
     * @param _totalTokenLimit - number of tokens availbale for purcahse through this contract
     * Note: only callable by contract owner
     */
    function setTotalTokenLimit(uint _totalTokenLimit) public onlyOwner {
        totalTokenLimit = _totalTokenLimit;
    }

    /**
     * @dev Set the status of withdrawalsEnabled. To be used in the event 3six9 does not launch in agreed window.
     * @param _status - bool of whether deposited funds are available for withdrawal
     * Note: only callable by contract owner
     */
    function setWithdrawalStatus(bool _status) public onlyOwner {
        withdrawalsEnabled = _status;
    }

    /**
     * @dev Withdraw ERC20 tokens from contract
     * @param _token - address of token to withdraw
     * @param _to - recipient of token transfer
     * @param _amount - amount of tokens to trasnfer
     */
    function withdrawERC20(
        address _token,
        address _to,
        uint _amount
        ) external onlyOwner {

        require(
            _amount <= IERC20(_token).balanceOf(address(this)),
            "Withdrawal amount greater than contract balance"
        );

        IERC20(_token).safeTransfer(_to, _amount);
    }

    /**
     * @dev Withdraw Ether from contract
     * @param _to - recipient of transfer
     * @param _amount - amount of Ether to trasnfer (18 token decimals)
     */
    function withdrawEther(
        address payable _to,
        uint _amount
        ) external onlyOwner {

        require(
            _amount <= address(this).balance,
            "Withdrawal amount greater than contract balance"
        );

        _to.transfer(_amount);
    }

}