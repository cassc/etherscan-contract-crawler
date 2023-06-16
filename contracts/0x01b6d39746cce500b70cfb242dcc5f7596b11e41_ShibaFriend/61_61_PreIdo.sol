//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./external/AggregatorV3Interface.sol";

contract PreIdo is AccessControlUpgradeable, PausableUpgradeable {
    AggregatorV3Interface internal bnbPriceFeed;

    address public tokenAddress;

    struct Info {
        address user;
        uint totalTokenAmount;
        uint claimedTokenAmount;
        uint boughtAt;
    }

    mapping(address => uint) investorsMap;
    Info[] investorDetails;

    struct IDOInfor {
        address tokenAddress;
        uint soldAmountToken;
        uint soldAmountBNB;
        uint minAmount;
        uint tokenPrice;
        uint decimalTokenPrice;
        uint decimalToken;
        uint ideTime;
        uint firstUnlock;
        uint secondUnlock;
        uint rateIDE;
        uint rateFirstTime;
        uint rateSecondTime;
        bool isActive;
    }

    uint private soldAmountToken;
    uint private soldAmountBNB;

    uint public minAmount;

    uint public tokenPrice;
    uint private decimalTokenPrice;

    uint private decimalToken;

    uint public ideTime;
    uint public firstUnlock;
    uint public secondUnlock;

    uint public rateIDE;
    uint public rateFirstTime;
    uint public rateSecondTime;

    bool public isActive;

    function initialize() initializer public {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __Pausable_init_unchained();

        soldAmountToken = 0;
        soldAmountBNB = 0;

        tokenPrice = 54;    //decimal = 10**4
        decimalTokenPrice = 10**4;
        decimalToken = 10**9;

        ideTime = 0;
        firstUnlock = 60;
        secondUnlock = 90;

        rateIDE = 30;
        rateFirstTime = 35;
        rateSecondTime = 35;

        minAmount = 100;
    }

    /*
        Admin's function BEGIN
    */
    function getPreIDOInfor()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(IDOInfor memory)
    {
        IDOInfor memory rs;
        rs.tokenAddress = tokenAddress;
        rs.soldAmountToken = soldAmountToken;
        rs.soldAmountBNB = soldAmountBNB;
        rs.minAmount = minAmount;
        rs.tokenPrice = tokenPrice;
        rs.decimalTokenPrice = decimalTokenPrice;
        rs.decimalToken = decimalToken;
        rs.ideTime = ideTime;
        rs.firstUnlock = firstUnlock;
        rs.secondUnlock = secondUnlock;
        rs.rateIDE = rateIDE;
        rs.rateFirstTime = rateFirstTime;
        rs.rateSecondTime = rateSecondTime;
        rs.isActive = isActive;
        return rs;
    }

    function getAllInvestors()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(Info [] memory)
    {
        Info[] memory investors = new Info [](investorDetails.length);

        for(uint i = 0; i<investorDetails.length; i++) {
            investors[i] = investorDetails[i];
        }
        
        return investors;
    }

    function setTokenAddress(address _currency)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tokenAddress = _currency;
    }

    function setTokenPrice(uint _price)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_price >= 1, "PreIdo: Price too small");
        tokenPrice = _price;
    }
    
    // priceFeed should be something like BUSD/BNB or DAI/BNB
    function setBnbPriceFeed(address _priceFeed, string calldata _description)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        bnbPriceFeed = AggregatorV3Interface(_priceFeed);
        require(_memcmp(bytes(bnbPriceFeed.description()), bytes(_description)),"PreIdo: Incorrect Feed");
    }

    function _memcmp(bytes memory a, bytes memory b)
        internal
        pure
        returns(bool)
    {
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    /*
       @dev admin can add information of private sale investors
    */
    function adminAddInvestors(address[] calldata _investors, uint256[] calldata _amounts)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for(uint i = 0; i<_investors.length; i++) {
            soldAmountToken = soldAmountToken + _amounts[i];

            investorsMap[_investors[i]] = investorDetails.length;

            investorDetails.push(Info(_investors[i], _amounts[i], 0, block.timestamp));
        }
    }

    /*
       @dev admin can withdraw all funds
    */
    function adminClaim(address _currencyAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // withdraw native currency
        if (_currencyAddress == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20 currencyContract = IERC20(_currencyAddress);
            currencyContract.transfer(msg.sender, currencyContract.balanceOf(address(this)));
        }
    }

    /*
        @dev This function will set minimum USD that user can pay to buy
    */
    function setMinimumMoney(uint256 _minPrice)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_minPrice > 0, "PreIdo: Minimum price not accepted");
        minAmount = _minPrice;
    }

    /*
        Admin can start and stop private sale
    */
    function activePreIDO(bool _isActive)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(tokenAddress != address(0), "PreIdo: Token address not specified");
        isActive = _isActive;
    }

    /*
        Admin can set timestamp of IDE and claim rate
    */
    function setIdeTime(uint _ideTime, uint _rate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        ideTime = _ideTime;
        rateIDE = _rate;
    }

    /*
        Admin can set the period of the first unlock and unlock rate
    */
    function setFirstUnlockTime(uint _firstUnlock, uint _rate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        firstUnlock = _firstUnlock;
        rateFirstTime = _rate;
    }

    /*
        Admin can set the period of the second unlock and unlock rate
    */
    function setSecondUnlockTime(uint _secondUnlock, uint _rate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        secondUnlock = _secondUnlock;
        rateSecondTime = _rate;
    }

    /*
        Admin's function END
    */

    function getLatestPrice(uint256 salePrice)
        public
        view
        returns (uint)
    {
        (
            , int price, , ,
        ) = bnbPriceFeed.latestRoundData();
        // rateDecimals = bnbPriceFeed.decimals();
        // price is BUSD / BNB * (amount)
        require(price > 0, "PreIdo: Invalid price");
        return uint(price) * salePrice; // since rateDecimals is 18, the same as BNB, we don't need to do anything
    }

    // user bought pre IDO or not
    function isBought(address _user)
        public
        view
        returns(bool)
    {
        return (investorsMap[_user] != 0) || 
               (investorDetails.length > 0 && investorDetails[investorsMap[_user]].user == _user);
    }

    /*
        we can get amount of token corresponding with amount of BNB
        @param - _amount: amount of BNB
    */
    function getTokenAmountToBuy(uint _amount)
        public
        view
        returns(uint)
    {
        uint tokenAmountOfUser = _amount * decimalTokenPrice / getLatestPrice(tokenPrice);
        return tokenAmountOfUser * decimalToken;
    }
	
    function buy()
        external
        payable
    {
        require(isActive, "PreIdo: Not in a private sale");
        require(!isBought(msg.sender), "PreIdo: A wallet can buy 1 time only");

        uint tokenAmountOfUser = getTokenAmountToBuy(msg.value);

        soldAmountToken = soldAmountToken + tokenAmountOfUser;
        soldAmountBNB = soldAmountBNB + msg.value;

        investorsMap[msg.sender] = investorDetails.length;

        investorDetails.push(Info(msg.sender, tokenAmountOfUser, 0, block.timestamp));

        uint minAmountInBNB = getLatestPrice(minAmount);

        require(msg.value >= minAmountInBNB, "PreIdo: BNB amount invalid");
    }

    /*
        User can retrieve his information
    */
    function getInfo()
        external
        view
        returns(Info memory)
    {
        Info memory rs;

        if(isBought(msg.sender)) {
            uint code = investorsMap[msg.sender];

            rs.user = investorDetails[code].user;
            rs.totalTokenAmount = investorDetails[code].totalTokenAmount;
            rs.claimedTokenAmount = investorDetails[code].claimedTokenAmount;
            rs.boughtAt = investorDetails[code].boughtAt;
        }

        return rs;
    }

    function getClaimable()
        public
        view
        returns(uint)
    {
        uint claimableToken = 0;

        if(isBought(msg.sender)) {
            uint unlockedToken = 0;
            if (block.timestamp >= (ideTime + (secondUnlock * 1 days))) {

                unlockedToken = investorDetails[investorsMap[msg.sender]].totalTokenAmount;

            }else if(block.timestamp >= (ideTime + (firstUnlock * 1 days))) {

                unlockedToken = investorDetails[investorsMap[msg.sender]].totalTokenAmount * (rateIDE + rateFirstTime) / 100;

            } else if(block.timestamp >= ideTime) {

                unlockedToken = investorDetails[investorsMap[msg.sender]].totalTokenAmount * rateIDE / 100;

            }
            claimableToken = unlockedToken - investorDetails[investorsMap[msg.sender]].claimedTokenAmount;
        }

        return claimableToken;
    }

    function userClaim()
        external
    {
        require(isBought(msg.sender), "PreIdo: User must buy pre IDO");

        uint code = investorsMap[msg.sender];
        uint claimableToken = getClaimable();
        investorDetails[code].claimedTokenAmount += claimableToken;
        IERC20(tokenAddress).transfer(msg.sender, claimableToken);
    }
}