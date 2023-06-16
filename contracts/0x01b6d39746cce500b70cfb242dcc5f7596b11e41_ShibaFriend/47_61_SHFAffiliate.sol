//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./external/AggregatorV3Interface.sol";
import "./SHFStore.sol";
import "./SHFMarketPlace_v2.sol";

contract SHFAffiliate is AccessControlUpgradeable, PausableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    AggregatorV3Interface internal bnbPriceFeed;

    // Referral system
    struct Referral {
        address user;                       // user owns this code
        uint32 referrerCode;                // the referrer code of user which referred this code
        uint256 totalAmount;                // total earnings of this code from buying NFT
        uint256 totalAmountGenRefCode;      // total earnings of this code from generate affiliate code
        uint256 currentAmountGenRefCode;    // claimable earnings of this code from generate affiliate code
        bool isActive;                      // allow user to join earning program
    }
    // Referral code of each user
    mapping(address => uint32) private referralLists;
    // Detail of affiliate tier 1
    mapping(uint32 => EnumerableSet.AddressSet) private referralLv1;
    // Detail of affiliate tier 2
    mapping(uint32 => EnumerableSet.AddressSet) private referralLv2;
    // Detail of all referrals
    mapping(uint32 => Referral) private referralDetails;

    bytes32 public constant STORE_ROLE = keccak256("STORE_ROLE");

    uint32 public earningRateLv1;
    uint32 public earningRateLv2;

    uint256 public referralPrice;

    function initialize() initializer public {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __Pausable_init_unchained();

        earningRateLv1 = 15;
        earningRateLv2 = 3;
        referralPrice = 10;
    }

    /*
        Admin's function BEGIN
    */
    // priceFeed should be something like BUSD/BNB or DAI/BNB
    function setBnbPriceFeed(address _priceFeed, string calldata _description) 
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        bnbPriceFeed = AggregatorV3Interface(_priceFeed);
        require(_memcmp(bytes(bnbPriceFeed.description()), bytes(_description)),"SHFAffiliate: Incorrect Feed");
    }

    function _memcmp(bytes memory a, bytes memory b)
        internal
        pure
        returns(bool)
    {
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    /*
        @dev This function will set EarningRateLv1 - price of a referral code
    */
    function setEarningRateLv1(uint32 _earningRateLv1)
        external
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "SHFAffiliate: Caller is not admin");
        require(_earningRateLv1 > 0, "SHFAffiliate: Rate not accepted");
        earningRateLv1 = _earningRateLv1;
    }

    /*
        @dev This function will set EarningRateLv2 - price of a referral code
    */
    function setEarningRateLv2(uint32 _earningRateLv2)
        external
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "SHFAffiliate: Caller is not admin");
        require(_earningRateLv2 > 0, "SHFAffiliate: Rate not accepted");
        earningRateLv2 = _earningRateLv2;
    }

    /*
        @dev This function will set referralPrice - price of a referral code
    */
    function setReferralPrice(uint256 _price)
        external
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "SHFAffiliate: Caller is not admin");
        require(_price > 0, "SHFAffiliate: Price not accepted");
        referralPrice = _price;
    }

    /*
       @dev admin can withdraw all funds
    */
    function adminClaim(address _currencyAddress)
        external
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "SHFAffiliate: Caller is not an admin"
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
        Admin's function END
    */

    function _getLatestPrice(uint256 salePrice)
        internal
        view 
        returns (uint)
    {
        (
            , int price, , ,
        ) = bnbPriceFeed.latestRoundData();
        // rateDecimals = bnbPriceFeed.decimals();
        // price is BUSD / BNB * (amount)
        require(price > 0, "SHFAffiliate: Invalid price");
        return uint(price) * salePrice; // since rateDecimals is 18, the same as BNB, we don't need to do anything
    }

    /*
        We have to convert NFT's price from BUSD to BNB/SHF
    */
    function convertPrice(
        uint256 _amount,
        address _currencyTarget
    )
        public
        view
        returns (uint)
    {
        if(_currencyTarget == address(0)){
            return _getLatestPrice(_amount);
        } else {
            // TODO: process if _currencyTarget = SHF
            uint busd2shfRate = 500 * 10** 9;  // busd/shf = 1/500, rateDecimals is 9
            return busd2shfRate * _amount;
        }
    }

    /*
        User can retrieve fee of referral registration in BNB
    */
    function getReferralPriceInBNB()
        public
        view
        returns(uint256)
    {
        return _getLatestPrice(uint256(referralPrice));
    }

    /*
        User can retrieve fee of referral registration in USD
    */
    function getReferralPriceInUSD()
        public
        view
        returns(uint256)
    {
        return uint256(referralPrice);
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
        require(_user != address(0), "SHFAffiliate: cannot generate referral code for address zero");
        
        uint32 refCode = 0;
        string memory input = "";
        do {
            input = string(abi.encodePacked(input, _user));
            uint hashValue = uint(keccak256(abi.encodePacked(input)));
            uint32 range = 0xffffffff;
            refCode = uint32(hashValue % range);
        } while (refCode != 0 && referralDetails[refCode].user != address(0)); // make sure this referral code has not been issued to any user yet
        
        return uint32(refCode);
    }

    /*
        Create new user's referral information
    */
    function _createNewReferralInformation(address _user)
        internal
        returns(uint32)
    {
        if(referralLists[_user] == 0) {
            // add to list codes
            referralLists[_user] = _generateReferralCode(_user);
            // add detail
            referralDetails[referralLists[_user]].user = _user;
            referralDetails[referralLists[_user]].referrerCode = 0;
            referralDetails[referralLists[_user]].totalAmount = 0;
            referralDetails[referralLists[_user]].totalAmountGenRefCode = 0;
            referralDetails[referralLists[_user]].currentAmountGenRefCode = 0;
            referralDetails[referralLists[_user]].isActive = false;
        }
        return referralLists[_user];
    }

    /*
        User can buy referral code to earning program by deposit money
    */
    function registerReferral()
        external
        payable
        returns(uint32)
    {
        uint referralPriceInBNB = _getLatestPrice(referralPrice);
        // deposit $referralPrice
        require(msg.value >= referralPriceInBNB, "SHFAffiliate: Not enough balance");

        // Generate new referral code if this user is a new user
        if(referralLists[msg.sender] == 0) {
            _createNewReferralInformation(msg.sender);
        }
        // Activate earning program for this referral code
        referralDetails[referralLists[msg.sender]].isActive = true;

        // Distribute commission for referrers
        uint32 refCode = referralLists[msg.sender];
        if(referralDetails[refCode].referrerCode != 0) {
            // referrer level 1 code
            uint32 refLv1 = referralDetails[refCode].referrerCode;
            _addCommisionReferral(refLv1, referralPriceInBNB, earningRateLv1);
            
            if(referralDetails[refLv1].referrerCode != 0) {
                // referrer level 2 code
                uint32 refLv2 = referralDetails[refLv1].referrerCode;
                _addCommisionReferral(refLv2, referralPriceInBNB, earningRateLv2);
            }

            
            
        }
        return referralLists[msg.sender];
    }

    /*
        For special case of "User can buy referral code to earning program by deposit money"
    */
    function registerReferralWithCode(uint32 _referrerCode)
        external
        payable
    {
        uint referralPriceInBNB = _getLatestPrice(referralPrice);
        // deposit $referralPrice
        require(msg.value >= referralPriceInBNB, "SHFAffiliate: Not enough balance");

        // Generate new referral code if this user is a new user
        if(referralLists[msg.sender] == 0) {
            _createNewReferralInformation(msg.sender);
        }
        // Activate earning program for this referral code
        referralDetails[referralLists[msg.sender]].isActive = true;

        uint32 refCode = referralLists[msg.sender];
        // if referrer of user is empty and referrerCode is valid
        if(referralDetails[refCode].referrerCode == 0 && checkReferralCode(_referrerCode) == 0) {
            // add _referrerCode for this user
            referralDetails[refCode].referrerCode = _referrerCode;
            // Distribute commission for referrers
            // referrer level 1 code
            uint32 refLv1 = _referrerCode;
            _addCommisionReferral(refLv1, referralPriceInBNB, earningRateLv1);
            
            if(referralDetails[refLv1].referrerCode != 0) {
                // referrer level 2 code
                uint32 refLv2 = referralDetails[refLv1].referrerCode;
                _addCommisionReferral(refLv2, referralPriceInBNB, earningRateLv2);
            }
        }
    }

    /*
        add commision to totalAmountGenRefCode and currentAmountGenRefCode of user history
    */
    function _addCommisionReferral(uint32 _referrerCode, uint _price, uint128 _rate)
        internal
    {
        referralDetails[_referrerCode].totalAmountGenRefCode += (_price * _rate / 100);
        referralDetails[_referrerCode].currentAmountGenRefCode += (_price * _rate / 100);
        if(_rate == earningRateLv1) {
            referralLv1[_referrerCode].add(msg.sender);
        }
        else {
            referralLv2[_referrerCode].add(msg.sender);
        }
    }

    /*
        Retrieve referral code of user
    */
    function getReferralCode()
        public
        view
        returns(uint32)
    {
        return referralLists[msg.sender];
    }

    /*
        Retrieve referral data of user
    */
    function getReferralData()
        external
        view
        returns(Referral memory)
    {
        require(msg.sender != address(0), "SHFAffiliate: cannot get referral data for address zero");
        require(referralLists[msg.sender] != 0, "SHFAffiliate: Newbie has no referral code");
        Referral memory rs = referralDetails[referralLists[msg.sender]];
        return rs;
    }

    function checkReferralCode(uint32 _code)
        public
        view
        returns(uint)
    {
        if (_code == 0) {
            // "SHFAffiliate: _code cannot equal 0"
            return uint(3);
        }
        else if(referralDetails[_code].user == address(0)) {
            // "SHFAffiliate: referral code incorrect"
            return uint(1);
        }
        else if (referralDetails[_code].isActive == false) {
            // "SHFAffiliate: user not joined the referral program"
            return uint(2);
        }
        else {
            return uint(0);
        }
    }

    /*
        if user had referrer before
    */
    function hasReferrer()
        public
        view
        returns(bool)
    {
        return _hasReferrerTier1(msg.sender);
    }

    /*
        if user had referrer before
    */
    function hasReferrerTier1ForStore(address _user)
        public
        view
        returns(bool)
    {
        return _hasReferrerTier1(_user);
    }

    /*
        if user had referrer lv 1
    */
    function _hasReferrerTier1(address _user)
        internal
        view
        returns(bool)
    {
        return (referralLists[_user] != 0 && referralDetails[referralLists[_user]].referrerCode != 0);
    }

    /*
        if user had referrer lv 1
    */
    function hasReferrerTier2ForStore(address _user)
        public
        view
        returns(bool)
    {
        return (_hasReferrerTier1(_user) && referralDetails[_getReferrerCodeTier1(_user)].referrerCode != 0);
    }

    /*
        check sender has referral code
    */
    function isNewbie()
        public
        view
        returns(bool)
    {
        return referralLists[msg.sender] == 0;
    }

    /*
        User can add his referrer
        @dev user must be newbie (never buy any NFT from store. If he owns NFT from gifts or deposit loan, he's still newbie)
        @dev referrer's code must belong to some other user
        @dev before adding referrer, user will be issued a new referral code for him self.
        @dev check if user own NFT, activate earning program for him.
        @dev add this user to list referral of referrer.
        @param _code: referrer code
    */
    function addReferrer(address _user, uint32 _code)
        external
    {
        require(
            hasRole(STORE_ROLE, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "SHFAffiliate: Caller is not a Store"
        );
        if( referralDetails[_code].user != address(0) && referralDetails[_code].isActive == true) {
            // Generate new referral code if this user is a new user
            if(referralLists[_user] == 0) {
                _createNewReferralInformation(_user);
            }
            
            // prevent self-referral AND referrer not exist
            if(referralLists[_user] != _code && !_hasReferrerTier1(_user)) {
                // Add referral detail for this user
                referralDetails[referralLists[_user]].referrerCode = _code;     // this user has referrer
            
                // // add this user to referrer's list referrals
                // referralLv1[_code].add(_user);
                // referralLv2[referralDetails[_code].referrerCode].add(_user);
            }
        }
    }

    /*
        User can retrieve his referrer's code
    */
    function getReferrerCode()
        external
        view
        returns(uint32)
    {
        return _getReferrerCodeTier1(msg.sender);       
    }

    /*
        Store can retrieve his referrer's code
    */
    function getReferrerCodeTier1ForStore(address _user)
        external
        view
        returns(uint32)
    {
        return _getReferrerCodeTier1(_user);       
    }

    /*
        User can retrieve his referrer's code
    */
    function _getReferrerCodeTier1(address _user)
        internal
        view
        returns(uint32)
    {
        if(_hasReferrerTier1(_user)) {
            return referralDetails[referralLists[_user]].referrerCode;
        } else {
            return 0;
        }        
    }

    /*
        Store can retrieve his referrer's code
    */
    function getReferrerCodeTier2ForStore(address _user)
        external
        view
        returns(uint32)
    {
        if(hasReferrerTier2ForStore(_user)) {
            return referralDetails[_getReferrerCodeTier1(_user)].referrerCode;
        } else {
            return 0;
            
        }        
    }

    /*
        User can claim get amount of money from generate referral link
    */
    function getClaimableBNB()
        external
        view
        returns(uint256)
    {
        return referralDetails[referralLists[msg.sender]].currentAmountGenRefCode;
    }

    /*
        User can claim money from generate referral link
    */
    function userClaimEarning()
        external
    {
        require(referralLists[msg.sender] != 0, "SHFAffiliate: Newbie has no referral code");
        Referral storage refDetail = referralDetails[referralLists[msg.sender]];
        require(refDetail.currentAmountGenRefCode > 0, "SHFAffiliate: User not enough money to claim");
        require(address(this).balance >= refDetail.currentAmountGenRefCode, "SHFAffiliate: Insufficient balance in the account");

        uint256 claimableAmount = refDetail.currentAmountGenRefCode;

        // clean claimable amount
        refDetail.currentAmountGenRefCode = 0;

        payable(msg.sender).transfer(claimableAmount);
    }

    function addBuyCommisionHistory(address _receiver, uint256 _price)
        external
    {
        referralDetails[referralLists[_receiver]].totalAmount += (_price);
    }

    function getEarningRateLv1()
        external
        view
        returns(uint32)
    {
        return earningRateLv1;
    }

    function getEarningRateLv2()
        external
        view
        returns(uint32)
    {
        return earningRateLv2;
    }

    function getAddressOfCode(uint32 _code)
        external
        view
        returns(address)
    {
        return referralDetails[_code].user;
    }

    function countAffiliateTier1()
        external
        view
        returns(uint256)
    {
        return referralLv1[referralLists[msg.sender]].length();
    }

    function countAffiliateTier2()
        external
        view
        returns(uint256)
    {
        return referralLv2[referralLists[msg.sender]].length();
    }

    // for test
    function getAffiliateTier1At(uint _indx)
        external
        view
        returns(address)
    {
        return referralLv1[referralLists[msg.sender]].at(_indx);
    }
    function getAffiliateTier2At(uint _indx)
        external
        view
        returns(address)
    {
        return referralLv2[referralLists[msg.sender]].at(_indx);
    }
}