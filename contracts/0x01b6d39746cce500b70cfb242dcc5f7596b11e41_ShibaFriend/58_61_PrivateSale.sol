//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./external/AggregatorV3Interface.sol";

contract PrivateSale is AccessControlUpgradeable, PausableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    AggregatorV3Interface internal bnbPriceFeed;

    uint private soldAmountToken;
    uint private soldAmountBNB;

    // total number of Token will be sold
    uint private maxPool;

    uint public minAmount;
    uint public maxAmount;

    uint public tokenPrice;

    uint private decimalTokenPrice;

    // 18 months or 24 months
    uint public unlockDuration;

    address public tokenAddress;

    address private marketingWallet;
    address private managerWallet;

    struct Info {
        address user;

        uint32 referrerCode;

        EnumerableSet.AddressSet affLv1;
        EnumerableSet.AddressSet affLv2;
        EnumerableSet.AddressSet affLv3;

        uint totalTokenAmount;
        uint claimedTokenAmount;
        uint boughtAt;
    }

    // User retrieves information
    struct InfoView {
        address user;

        uint32 referrerCode;

        uint affLv1;
        uint affLv2;
        uint affLv3;

        uint totalTokenAmount;
        uint claimedTokenAmount;
        uint boughtAt;
    }

    EnumerableMap.AddressToUintMap investorsMap;
    mapping(uint32 => Info) investorDetails;

    uint32 public affiliateRateLv1;
    uint32 public affiliateRateLv2;
    uint32 public affiliateRateLv3;

    uint private countAffTier1;
    uint private countAffTier2;
    uint private countAffTier3;

    uint private startCountdown;

    // Private sale is activate. User only can buy when private sale is active
    bool public isActive;

    function initialize() initializer public {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __Pausable_init_unchained();

        soldAmountToken = 0;
        soldAmountBNB = 0;
        maxPool = 650*10**6;

        tokenPrice = 36;    //decimal = 10**4
        decimalTokenPrice = 10**4;

        unlockDuration = 18;

        minAmount = 100;
        maxAmount = 10000;

        affiliateRateLv1 = 7;
        affiliateRateLv2 = 5;
        affiliateRateLv3 = 3;

        countAffTier1 = 0;
        countAffTier2 = 0;
        countAffTier3 = 0;

        startCountdown = 0;
    }

    /*
        Admin's function BEGIN
    */
    function getAllInvestors()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(InfoView [] memory)
    {
        InfoView[] memory investors = new InfoView [](investorsMap.length());

        for(uint i = 0; i<investorsMap.length(); i++) {
            address addTemp;
            (addTemp, ) = investorsMap.at(i);
            investors[i] = _getUserInfo(addTemp);
        }
        
        return investors;
    }

    function setTokenCurrency(address _currency)
        external
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "PrivateSale: Caller is not an admin"
        );
        tokenAddress = _currency;
    }
    function setTokenPrice(uint _price)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_price >= 1, "PrivateSale: Price too small");
        tokenPrice = _price;
    }
    // priceFeed should be something like BUSD/BNB or DAI/BNB
    function setBnbPriceFeed(address _priceFeed, string calldata _description)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        bnbPriceFeed = AggregatorV3Interface(_priceFeed);
        require(_memcmp(bytes(bnbPriceFeed.description()), bytes(_description)),"PrivateSale: Incorrect Feed");
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
            uint32 code = _createNewAffiliateInformation(_investors[i]);
            investorDetails[code].totalTokenAmount = _amounts[i];
            investorDetails[code].claimedTokenAmount = 0;
            investorDetails[code].boughtAt = block.timestamp;
        }
    }

    /*
       @dev admin can withdraw all funds
    */
    function adminClaim(address _currencyAddress)
        external
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "PrivateSale: Caller is not an admin"
        );
        // withdraw native currency
        if (_currencyAddress == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20 currencyContract = IERC20(_currencyAddress);
            currencyContract.transfer(msg.sender, currencyContract.balanceOf(address(this)));
        }
    }

    /*
        @dev This function will set maximum and minimum USD that user can pay to buy
    */
    function setAmountMoney(uint256 _minPrice, uint256 _maxPrice)
        external
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "PrivateSale: Caller is not admin");
        require(_minPrice > 0, "PrivateSale: Minimum price not accepted");
        require(_maxPrice >= _minPrice, "PrivateSale: Maximum price not accepted");
        minAmount = _minPrice;
        maxAmount = _maxPrice;
    }

    /*
        Admin can set the maximum Tokens in private sale
        @param: _maxPool - Before call this function, ERC20 of contract must greater or equal _maxPool
    */
    function setMaxPool(uint _maxPool)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_maxPool > 0, "PrivateSale: pool amount must greater than 0");
        // require(_maxPool <= IERC20(tokenAddress).balanceOf(address(this)), "PrivateSale: pool amount too large");
        maxPool = _maxPool;
    }

    function setMarketingWallet(address _marketingWallet)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_marketingWallet != address(0), "PrivateSale: Marketing wallet cannot be address 0");
        marketingWallet = _marketingWallet;
    }

    function setManagerWallet(address _managerWallet)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_managerWallet != address(0), "PrivateSale: Marketing wallet cannot be address 0");
        managerWallet = _managerWallet;
    }

    /*
        Admin can start and stop private sale
    */
    function activePrivateSale(bool _isActive)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(tokenAddress != address(0), "PrivateSale: Token address not specified");
        require(marketingWallet != address(0), "PrivateSale: Marketing wallet not specified");
        require(managerWallet != address(0), "PrivateSale: Manager wallet not specified");
        isActive = _isActive;
    }

    /*
        Admin can set unlock duration (in month)
    */
    function setUnlockDuration(uint _unlockDuration)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        unlockDuration = _unlockDuration;
    }

    /*
        Admin can change the time to start countdown
    */
    function setCountDownTime(uint _startCountdown)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        startCountdown = _startCountdown;
    }

    /*
        Admin can check amount of token sold
    */
    function getAmountToken()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(uint)
    {
        return soldAmountToken;
    }

    /*
        Admin can check amount of BNB sold
    */
    function getAmountBNB()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(uint)
    {
        return soldAmountBNB;
    }

    function countAffiliateTier1()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(uint)
    {
        return countAffTier1;
    }

    function countAffiliateTier2()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(uint)
    {
        return countAffTier2;
    }

    function countAffiliateTier3()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(uint)
    {
        return countAffTier3;
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
        require(price > 0, "PrivateSale: Invalid price");
        return uint(price) * salePrice; // since rateDecimals is 18, the same as BNB, we don't need to do anything
    }

    /*
        Referral system
    */

    /*
        Generate an unique code for a user
    */
    function _generateReferralCode(address _user)
        internal
        view
        returns(uint32)
    {
        require(_user != address(0), "PrivateSale: cannot generate affiliate code for address zero");

        uint32 refCode = 0;
        string memory input = "";
        do {
            input = string(abi.encodePacked(input, _user));
            uint hashValue = uint(keccak256(abi.encodePacked(input)));
            uint32 range = 0xffffffff;
            refCode = uint32(hashValue % range);
        } while (refCode != 0 && investorDetails[refCode].user != address(0)); // make sure this referral code has not been issued to any user yet

        return uint32(refCode);
    }

    /*
        Create new user's referral information
    */
    function _createNewAffiliateInformation(address _user)
        internal
        returns(uint32)
    {
        uint32 code = _generateReferralCode(_user);
        investorsMap.set(_user, code);
        // add detail
        investorDetails[code].user = _user;
        investorDetails[code].referrerCode = 0;
        investorDetails[code].boughtAt = 0;

        return uint32(investorsMap.get(_user));
    }

    /*
        code validity
    */
    function isValidCode(uint32 _code)
        public
        view
        returns(bool)
    {
        if(_code != 0 && investorDetails[_code].user == address(0)) {
            // "PrivateSale: affiliate code incorrect"
            return false;
        }
        else {
            return true;
        }
    }

    function _distributeCommision(uint32 _code, uint _value)
        internal
    {
        // Affilivate program
        // level 1
        uint commisionAmount = 0;
        if(_code != 0) {
            commisionAmount = commisionAmount + _payCommisionAffiliate(_code, _value, 1);

            // level 2
            uint32 refCodeLv2 = investorDetails[_code].referrerCode;
            if(refCodeLv2 != 0) {
                commisionAmount = commisionAmount + _payCommisionAffiliate(refCodeLv2, _value, 2);

                // level 3
                uint32 refCodeLv3 = investorDetails[refCodeLv2].referrerCode;
                if(refCodeLv3 != 0) {
                    commisionAmount = commisionAmount + _payCommisionAffiliate(refCodeLv3, _value, 3);
                }
            }
        }

        uint theRestAmount = _value - commisionAmount;
        // address private marketingWallet - 11.76%
        uint valueForMarketing = theRestAmount * 1176 / 10000;
        payable(marketingWallet).transfer(valueForMarketing);
        // address private managerWallet;
        // uint valueForManager = _value - commisionAmount - valueForMarketing;
        // payable(managerWallet).transfer(valueForManager);
    }

    /*
        pay commision to referrer
    */
    function _payCommisionAffiliate(uint32 _referrerCode, uint _price, uint128 _affLv)
        internal
        returns(uint)
    {
        uint rate = affiliateRateLv1;
        if(_affLv == 1) {
            investorDetails[_referrerCode].affLv1.add(msg.sender);
            countAffTier1 = countAffTier1 + 1;
        }
        else if (_affLv == 2) {
            rate = affiliateRateLv2;
            investorDetails[_referrerCode].affLv2.add(msg.sender);
            countAffTier2 = countAffTier2 + 1;
        }
        else {
            rate = affiliateRateLv3;
            investorDetails[_referrerCode].affLv3.add(msg.sender);
            countAffTier3 = countAffTier3 + 1;
        }
        payable(investorDetails[_referrerCode].user).transfer(_price * rate / 100);

        return _price * rate / 100;
    }

    function _canBuy(address _user)
        internal
        view
        returns(bool)
    {
        return !investorsMap.contains(_user);
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
        return tokenAmountOfUser * (10 ** 9);
    }
	
	receive () external payable {}

    function buy(uint32 _code)
        external
        payable
        returns(uint32)
    {
        require(isActive, "PrivateSale: Not in a private sale");
        require(isValidCode(_code), "PrivateSale: Invalid code");
        require(_canBuy(msg.sender), "PrivateSale: A wallet can buy 1 time only");

        uint tokenAmountOfUser = getTokenAmountToBuy(msg.value);
        // require(soldAmountToken + tokenAmountOfUser <= maxPool, "PrivateSale: The purchase limit has been reached");

        soldAmountToken = soldAmountToken + tokenAmountOfUser;
        soldAmountBNB = soldAmountBNB + msg.value;

        // gen a code for new user
        uint32 code = _createNewAffiliateInformation(msg.sender);
        investorDetails[code].totalTokenAmount = tokenAmountOfUser;
        investorDetails[code].claimedTokenAmount = 0;
        investorDetails[code].boughtAt = block.timestamp;

        // add referrer
        if(_code != 0) {
            investorDetails[uint32(investorsMap.get(msg.sender))].referrerCode = _code;
        }

        uint minAmountInBNB = getLatestPrice(minAmount);
        uint maxAmountInBNB = getLatestPrice(maxAmount);

        require(msg.value >= minAmountInBNB && msg.value <= maxAmountInBNB, "PrivateSale: BNB amount invalid");

        _distributeCommision(_code, msg.value);

        return uint32(investorsMap.get(msg.sender));
    }

    /*
        Admin can retrieve information of a user
    */
    function _getUserInfo(address _user)
        internal
        view
        returns(InfoView memory)
    {
        InfoView memory rs;

        uint32 code = uint32(investorsMap.get(_user));
        rs.user = investorDetails[code].user;

        rs.referrerCode = investorDetails[code].referrerCode;

        rs.affLv1 = investorDetails[code].affLv1.length();
        rs.affLv2 = investorDetails[code].affLv2.length();
        rs.affLv3 = investorDetails[code].affLv3.length();

        rs.totalTokenAmount = investorDetails[code].totalTokenAmount;
        rs.claimedTokenAmount = investorDetails[code].claimedTokenAmount;
        rs.boughtAt = investorDetails[code].boughtAt;

        return rs;
    }

    /*
        User can retrieve his information
    */
    function getInfo()
        external
        view
        returns(InfoView memory)
    {
        return _getUserInfo(msg.sender);
    }

    /*
        Retrieve affiliate code of user
    */
    function getAffiliateCode()
        external
        view
        returns(uint32)
    {
        return uint32(investorsMap.get(msg.sender));
    }

    function getClaimable()
        public
        view
        returns(uint)
    {
        uint32 code = uint32(investorsMap.get(msg.sender));
        uint timeLock = startCountdown + 7 days;
        if (block.timestamp <= timeLock) {
            return 0;
        }
        uint daysDiff = (block.timestamp - timeLock) / 1 days;

        uint unlockDays = 30 * unlockDuration;

        uint unlockedToken = (investorDetails[code].totalTokenAmount < investorDetails[code].totalTokenAmount * daysDiff / unlockDays) ?
                              investorDetails[code].totalTokenAmount : investorDetails[code].totalTokenAmount * daysDiff / unlockDays;
        uint claimableToken = unlockedToken - investorDetails[code].claimedTokenAmount;

        return claimableToken;
    }

    function userClaim()
        external
    {
        uint32 code = uint32(investorsMap.get(msg.sender));
        uint claimableToken = getClaimable();
        investorDetails[code].claimedTokenAmount += claimableToken;
        IERC20(tokenAddress).transfer(msg.sender, claimableToken);
    }
}