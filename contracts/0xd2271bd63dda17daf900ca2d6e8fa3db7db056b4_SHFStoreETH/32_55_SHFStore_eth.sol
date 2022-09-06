//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "./ShibaFriendNFT.sol";
import "./external/AggregatorV3Interface.sol";

contract SHFStoreETH is AccessControlUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    AggregatorV3Interface internal ethPriceFeed;
    AggregatorV3Interface internal shibPriceFeed;
    uint public sftRate;
    uint public sftRateDecimals;

    address public sftAddress;
    address public shibAddress;

    address private managerWallet;

    enum GroupStatus {
        Expired,
        Ongoing
    }

    mapping(string => GroupStatus) public nftGroupStatus;

    uint public rollingPrice;
    uint private totalSold;
    uint public sftReduceRate;

    address public nftContractAddress;

    struct Info {
        address user;
        uint32 code;
        uint32 referrer;

        uint ethEarning;
        uint sftEarning;
        uint shibEarning;

        uint affLv1;
        uint affLv2;
        uint affLv3;
    }
    EnumerableMap.AddressToUintMap private investorsMap;
    mapping(uint32 => Info) private investorDetails;

    uint32[] public affiliateRate;

    uint public bigReward;
    uint public smallReward;

    uint32 private managerRate;

    event SpecialRewardDropped(address _receiver, uint _value, address _currency);
    event Rolling(address _receiver, uint[] _rollingResult, uint _rewardValue);

    function initialize() initializer public {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __Pausable_init_unchained();

        rollingPrice = 5*10**16;
        sftReduceRate = 20;

        sftRateDecimals = 10**4;
        sftRate = 54;           // with usdT

        affiliateRate.push(25);
        affiliateRate.push(15);
        affiliateRate.push(10);

        bigReward = 1000;       // in USDT
        smallReward = 500;      // in USDT

        managerRate = 11;
    }

    /*
     *  BEGIN: Admin's funcitions
    */
    function setRollingPrice(uint _rollingPrice)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_rollingPrice > 0, "SHFStoreETH: Price must be positive");
        rollingPrice = _rollingPrice;
    }

    function getTotalSold()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(uint)
    {
        return totalSold;
    }

    function setSftReduceRate(uint _sftReduceRate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_sftReduceRate >= 0 && _sftReduceRate < 100, "SHFStoreETH: Rate not allowed");
        sftReduceRate = _sftReduceRate;
    }

    function setAffiliateRates(
        uint32 _affiliateRateLv1,
        uint32 _affiliateRateLv2,
        uint32 _affiliateRateLv3
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_affiliateRateLv1 > 0 &&
                _affiliateRateLv2 > 0 &&
                _affiliateRateLv3 > 0
            , "SHFStoreETH: Rates must be positive");
        
        affiliateRate[0] = _affiliateRateLv1;
        affiliateRate[1] = _affiliateRateLv2;
        affiliateRate[2] = _affiliateRateLv3;
    }
    

    function setSpecialRewards(uint _bigReward, uint _smallReward)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_bigReward > 0 &&
                _smallReward > 0
        , "SHFStoreETH: Rewards must be positive");
        bigReward = _bigReward;
        smallReward = _smallReward;
    }

    function allowNFTContract(address _nftContractAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(IERC1155(_nftContractAddress).supportsInterface(type(IERC1155).interfaceId), "SHFStoreETH: Contract should be IERC1155");
        
        nftContractAddress = _nftContractAddress;
    }

    function setSFTRate(uint _sftRate, uint _sftRateDecimals)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_sftRate > 0 && _sftRateDecimals > 0, "SHFStoreETH: Price must be positive");
        sftRate = _sftRate;
        sftRateDecimals = _sftRateDecimals;
    }

    function setCurrenciesAddress(address _sftAddress, address _shibAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        sftAddress = _sftAddress;
        shibAddress = _shibAddress;
    }

    function setManagerWallet(address _managerWallet)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_managerWallet != address(0), "SHFStoreETH: Marketing wallet cannot be address 0");
        managerWallet = _managerWallet;
    }

    function addSale(
        uint32 _numberOfType,
        string memory _groupNamePrefix
        )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(sftAddress != address(0) && shibAddress != address(0), "SHFStoreETH: SFT and SHIB address must be specified");
        require(_numberOfType > 0, "SHFStoreETH: Number of tier should positive");

        ShibaFriendNFT(nftContractAddress).addGroupNFT(_groupNamePrefix, _numberOfType);
    }

    /*
       @dev admin can withdraw all funds
    */
    function adminClaim(address currencyAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // withdraw native currency
        if (currencyAddress == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20 currencyContract = IERC20(currencyAddress);
            currencyContract.transfer(msg.sender, currencyContract.balanceOf(address(this)));
        }
    }

    function memcmp(bytes memory a, bytes memory b)
        internal
        pure
        returns(bool)
    {
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    // "0x8dD1CD88F43aF196ae478e91b9F5E4Ac69A97C61", "SHIB / ETH"
    function setSHIBPriceFeed(address _priceFeed, string calldata _description)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        shibPriceFeed = AggregatorV3Interface(_priceFeed);
        require(memcmp(bytes(shibPriceFeed.description()), bytes(_description)),"SHFStoreETH: Incorrect Feed");
    }

    // "0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46", "USDT / ETH"
    function setETHPriceFeed(address _priceFeed, string calldata _description)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        ethPriceFeed = AggregatorV3Interface(_priceFeed);
        require(memcmp(bytes(ethPriceFeed.description()), bytes(_description)),"SHFStoreETH: Incorrect Feed");
    }

    /*
     *  END: Admin's funcitions
    */

    // _salePrice in ETH
    function getLatestPrice(uint256 _salePrice, address _currency)
        public
        view
        returns (uint)
    {
        if(_currency == address(0)) {
            return _salePrice;
        }
        else if(_currency == shibAddress) {
            // SHIB / ETH
            ( , int price, , , ) = shibPriceFeed.latestRoundData();     // SHIB / ETH
            require(price > 0, "SHFStoreETH: Invalid price");
            return _salePrice / uint(price) * 10**18;
        }
        else{
            ( , int price, , , ) = ethPriceFeed.latestRoundData();      // USDT / ETH
            uint toUSDT = _salePrice / uint(price);
            return (toUSDT * sftRateDecimals / sftRate)*10**9;
        }
    }

    function roll(
        uint _numberOfRolling,
        address _currency,
        uint32 _code
    )
        external
        payable
    {
        require(_numberOfRolling > 0 && _numberOfRolling < 499, "SHFStoreETH: Number of rolling incorrect");

        if (!investorsMap.contains(msg.sender)) {
            // gen a code for new user
            _createNewAffiliateInformation(msg.sender);
        }
        // add referrer
        if( investorDetails[uint32(investorsMap.get(msg.sender))].referrer == 0 &&
            _code != 0 && isValidCode(_code)) {

            investorDetails[uint32(investorsMap.get(msg.sender))].referrer = _code;

            investorDetails[_code].affLv1 = investorDetails[_code].affLv1 + 1;
            
            uint32 ref2 = investorDetails[_code].referrer;
            if(ref2 != 0) {
                investorDetails[ref2].affLv2 = investorDetails[ref2].affLv2 + 1;
            }

            uint32 ref3 = investorDetails[ref2].referrer;
            if(ref3 != 0) {
                investorDetails[ref3].affLv3 = investorDetails[ref3].affLv3 + 1;
            }
        }

        uint rewardValue = 0;
        
        // nft and reward
        if ((totalSold + _numberOfRolling) % 1000 < totalSold % 1000) {
            totalSold = totalSold + 1;
            ( , int price, , , ) = ethPriceFeed.latestRoundData();      // USDT / ETH
            require(price > 0, "SHFStoreETH: Invalid price");
            _sendSpecialReward(msg.sender, bigReward * uint(price), address(0));
            _numberOfRolling = _numberOfRolling - 1;
            rewardValue = bigReward;
        }
        else if ((totalSold + _numberOfRolling) % 500 < totalSold % 500) {
            totalSold = totalSold + 1;
            _sendSpecialReward(msg.sender, (smallReward * sftRateDecimals / sftRate)*10**9, sftAddress);
            _numberOfRolling = _numberOfRolling - 1;
            rewardValue = smallReward;
        }

        uint[] memory nftID = _mintAndTransferNFT(msg.sender, _numberOfRolling);

        uint256 petSalePrice = _getToken(_numberOfRolling, _currency);

        uint32 refCode = investorDetails[uint32(investorsMap.get(msg.sender))].referrer;
        _distributeCommision(refCode, petSalePrice, _currency);

        emit Rolling(msg.sender, nftID, rewardValue);
    }

    function _getToken(uint _numberOfRolling, address _currency)
        internal
        returns(uint256)
    {
        require((_currency == address(0)) || 
                (_currency == sftAddress) ||
                (_currency == shibAddress), 
                "SHFStoreETH: Currency not allowed");

        uint256 petSalePrice = rollingPrice * _numberOfRolling;

        if (_currency == address(0)) {
            //Native currency
            require(msg.value >= petSalePrice, "SHFStoreETH: Not enough balance");
        } else{
            petSalePrice = getLatestPrice(petSalePrice, _currency);
            if(_currency == sftAddress) {
                petSalePrice = petSalePrice * (100 - sftReduceRate) / 100;
            }
            IERC20(_currency).transferFrom(msg.sender, address(this), petSalePrice);
        }
        return petSalePrice;
    }

    function _mintAndTransferNFT(address _receiver, uint _numberNFT)
        internal
        returns(uint[] memory)
    {
        if (_numberNFT < 3) {
            uint numberNFT = ShibaFriendNFT(nftContractAddress).TotalType();
            uint[] memory rs = new uint[](numberNFT);
            for (uint i = 0; i < _numberNFT; i++) {
                uint idxID = _getOneRandomSaleID(numberNFT, block.timestamp, _receiver, totalSold);
                rs[idxID] = rs[idxID] + 1;

                uint shibaPrefix = ShibaFriendNFT(nftContractAddress).NFTGroupPrefixs("shiba");
                uint housePrefix = ShibaFriendNFT(nftContractAddress).NFTGroupPrefixs("house");

                if(idxID >= ShibaFriendNFT(nftContractAddress).NumberOfTypeNFT(shibaPrefix)) {
                    // idxID >= 15 (number of Shiba) => random house
                    uint nftID = housePrefix + (idxID - ShibaFriendNFT(nftContractAddress).NumberOfTypeNFT(shibaPrefix));
                    ShibaFriendNFT(nftContractAddress).mint(_receiver, nftID, 1, "");
                }
                else {
                    // idxID <= 14 => random shiba
                    uint nftID = shibaPrefix + idxID;
                    ShibaFriendNFT(nftContractAddress).mint(_receiver, nftID, 1, "");
                }
                
                totalSold = totalSold + 1;
                
            }
            return rs;
        }
        else {
            uint[] memory nftIDs = ShibaFriendNFT(nftContractAddress).getAllNFTID();
            (uint[] memory randomNumbers, uint count) = _getRandomSaleIDs(nftIDs.length, block.timestamp, _receiver, totalSold, _numberNFT);
        
            uint[] memory diffIDs = new uint[](count);
            uint[] memory diffCounts = new uint[](count);
            uint diffIdx = 0;
            for(uint i = 0; i < nftIDs.length; i++) {
                if (randomNumbers[i] != 0) {
                    diffIDs[diffIdx] = nftIDs[i];
                    diffCounts[diffIdx] = randomNumbers[i];
                    diffIdx = diffIdx + 1;
                }
            }

            totalSold = totalSold + _numberNFT;

            ShibaFriendNFT(nftContractAddress).mintBatch(_receiver, diffIDs, diffCounts, "");

            return randomNumbers;
        }
    }

    function _getOneRandomSaleID(uint _numberOfType, uint _time, address _receiver, uint _bonusSeed)
        internal
        pure
        returns (uint)
    {
        uint randomHash = uint(keccak256(abi.encodePacked(_time, _receiver, _bonusSeed)));

        uint randomID = randomHash % _numberOfType;
        
        return randomID;
    }

    
    function _getRandomSaleIDs(uint _numberOfType, uint _time, address _receiver, uint _bonusSeed, uint _numberRandom)
        internal
        pure
        returns (uint[] memory, uint)
    {
        uint[] memory rs = new uint[](_numberOfType);
        uint count = 0;

        for(uint i = 0; i < _numberRandom; i++) {
            uint randomHash = uint(keccak256(abi.encodePacked(_time, _receiver, _bonusSeed + i, _numberRandom)));

            uint randomID = randomHash % _numberOfType;

            if(rs[randomID] == 0)
            {
                count = count + 1;      // number of difference NFT IDs
            }
            rs[randomID] = rs[randomID] + 1;
        }
        
        return (rs, count);
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
        require(_user != address(0), "SHFStoreETH: cannot generate affiliate code for address zero");

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
        investorDetails[code].code = code;

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
            return false;
        }
        else {
            return true;
        }
    }

    function _distributeCommision(uint32 _code, uint _value, address _currency)
        internal
    {
        // manager
        if (_currency == address(0)) {
            payable(managerWallet).transfer(_value * managerRate / 100);
        }
        else {
            IERC20 currencyContract = IERC20(_currency);
            currencyContract.transfer(managerWallet, _value * managerRate / 100);
        }
        // Affilivate program
        // level 1
        if(_code != 0) {
            _payCommisionAffiliate(_code, _value, _currency, 1);

            // level 2
            uint32 refCodeLv2 = investorDetails[_code].referrer;
            if(refCodeLv2 != 0) {
                _payCommisionAffiliate(refCodeLv2, _value, _currency, 2);

                // level 3
                uint32 refCodeLv3 = investorDetails[refCodeLv2].referrer;
                if(refCodeLv3 != 0) {
                    _payCommisionAffiliate(refCodeLv3, _value, _currency, 3);
                }
            }
        }
    }

    /*
        pay commision to referrer
    */
    function _payCommisionAffiliate(uint32 _referrerCode, uint _price, address _currency, uint128 _affLv)
        internal
    {
        uint rate = affiliateRate[_affLv-1];

        uint amount = _price * rate / 100;
        if (_currency == address(0)) {
            investorDetails[_referrerCode].ethEarning = investorDetails[_referrerCode].ethEarning + amount;
        }
        else if (_currency == sftAddress){
            investorDetails[_referrerCode].sftEarning = investorDetails[_referrerCode].sftEarning + amount;
        }
        else if (_currency == shibAddress){
            investorDetails[_referrerCode].shibEarning = investorDetails[_referrerCode].shibEarning + amount;
        }
    }

    function _sendSpecialReward(address _user, uint _amount, address _currency)
        internal
        nonReentrant
    {
        if(_currency == address(0)) {
            (bool success, ) = address(_user).call{ value: _amount }("");
            require(success, "SHFStoreETH: Reward failed to send");
        }
        else {
            IERC20(sftAddress).transfer(_user, _amount);
        }
        emit SpecialRewardDropped(_user, _amount, _currency);
    }

    function getAffiliateInfor()
        external
        view
        returns(Info memory)
    {
        return _getAffiliateInfor(msg.sender);
    }

    function adminGetAffiliateInfor(address _user)
        external
        view
        returns(Info memory)
    {
        return _getAffiliateInfor(_user);
    }

    function _getAffiliateInfor(address _user)
        internal
        view
        returns(Info memory)
    {
        Info memory rs = investorDetails[uint32(investorsMap.get(_user))];
        return rs;
    }

    function userClaim(address _currency)
        external
        nonReentrant
    {
        require(investorsMap.get(msg.sender) > 0, "SHFStoreETH: User not join affiliate system");
        Info storage userInfor = investorDetails[uint32(investorsMap.get(msg.sender))];
        if (_currency == address(0)) {
            require(userInfor.ethEarning > 0, "SHFStoreETH: ETH earning too small");
            uint amount = userInfor.ethEarning;
            userInfor.ethEarning = 0;
            (bool success, ) = address(msg.sender).call{ value: amount }("");
            require(success, "SHFStoreETH: Earning failed to send");
        }
        else if(_currency == sftAddress){
            require(userInfor.sftEarning > 0, "SHFStoreETH: SFT earning too small");
            uint amount = userInfor.sftEarning;
            userInfor.sftEarning = 0;
            IERC20(sftAddress).transfer(msg.sender, amount);
        }
        else if(_currency == shibAddress){
            require(userInfor.shibEarning > 0, "SHFStoreETH: SHIB earning too small");
            uint amount = userInfor.shibEarning;
            userInfor.shibEarning = 0;
            IERC20(shibAddress).transfer(msg.sender, amount);
        }
    }
}