// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./libraries/Ownable.sol";
import "./libraries/EnumerableSet.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IToken.sol";

contract PresaleSettings is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    
    EnumerableSet.AddressSet private ALLOWED_GENERATORS;

    EnumerableSet.AddressSet private EARLY_ACCESS_TOKENS;

    mapping(address => bool) private ALLOWED_BASE_TOKENS;

    mapping(address => AccessTokens) public accessToken;
    struct AccessTokens {
        bool ownedBalance;
        uint256 level1TokenAmount;
        uint256 level2TokenAmount;
        uint256 level3TokenAmount;
        uint256 level4TokenAmount;
    }
    
    EnumerableSet.AddressSet private ALLOWED_REFERRERS;
    mapping(bytes32 => address payable) private REFERRAL_OWNER;
    mapping(address => EnumerableSet.Bytes32Set) private REFERRAL_OWNED_CODES;
    struct ReferralHistory {
        address project;
        address presale;
        address baseToken;
        bool active;
        bool success;
        uint256 presaleRaised;
        uint256 referrerEarned;
    }
    mapping(bytes32 => ReferralHistory[]) public referrerHistory;
    
    struct Settings {
        uint256 BASE_FEE; // base fee divided by 1000
        uint256 TOKEN_FEE; // token fee divided by 1000
        uint256 REFERRAL_FEE; // a referrals percentage of the presale profits divided by 1000
        address payable ETH_FEE_ADDRESS;
        address payable TOKEN_FEE_ADDRESS;
        uint256 ETH_CREATION_FEE; // fee to generate a presale contract on the platform
        uint256 LEVEL_4_ROUND_LENGTH; // length of round level4 in seconds
        uint256 LEVEL_3_ROUND_LENGTH; // length of round level2 in seconds
        uint256 LEVEL_2_ROUND_LENGTH; // length of round level3 in seconds
        uint256 LEVEL_1_ROUND_LENGTH; // length of round level1 in seconds
        uint256 MAX_PRESALE_LENGTH; // maximum difference between start and endblock
        uint256 MIN_EARLY_ACCESS_ALLOWANCE;
        uint256 MIN_SOFTCAP_RATE;
        uint256 MIN_PERCENT_PYESWAP;
    }
    
    Settings public SETTINGS;
    
    constructor() {
        SETTINGS.BASE_FEE = 20; // 2.0%
        SETTINGS.TOKEN_FEE = 20; // 2.0%
        SETTINGS.REFERRAL_FEE = 200; // 20%
        SETTINGS.ETH_CREATION_FEE = 1e18; // 1 bnb
        SETTINGS.ETH_FEE_ADDRESS = payable(msg.sender);
        SETTINGS.TOKEN_FEE_ADDRESS = payable(msg.sender);
        SETTINGS.LEVEL_4_ROUND_LENGTH = 3 hours;
        SETTINGS.LEVEL_3_ROUND_LENGTH = 2 hours; 
        SETTINGS.LEVEL_2_ROUND_LENGTH = 1 hours; 
        SETTINGS.LEVEL_1_ROUND_LENGTH = 30 minutes; 
        SETTINGS.MAX_PRESALE_LENGTH = 2 weeks; 
        SETTINGS.MIN_EARLY_ACCESS_ALLOWANCE = 2500; // 25%
        SETTINGS.MIN_SOFTCAP_RATE = 5000; // 50%
        SETTINGS.MIN_PERCENT_PYESWAP = 500; // 50%
        ALLOWED_BASE_TOKENS[0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c] = true;
        ALLOWED_BASE_TOKENS[0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56] = true;
    }
    
    function getLevel4RoundLength () external view returns (uint256) {
        return SETTINGS.LEVEL_4_ROUND_LENGTH;
    }

    function getLevel3RoundLength () external view returns (uint256) {
        return SETTINGS.LEVEL_3_ROUND_LENGTH;
    }

    function getLevel2RoundLength () external view returns (uint256) {
        return SETTINGS.LEVEL_2_ROUND_LENGTH;
    }

    function getLevel1RoundLength () external view returns (uint256) {
        return SETTINGS.LEVEL_1_ROUND_LENGTH;
    }

    function getMaxPresaleLength () external view returns (uint256) {
        return SETTINGS.MAX_PRESALE_LENGTH;
    }

    function getMinSoftcapRate() external view returns (uint256) {
        return SETTINGS.MIN_SOFTCAP_RATE;
    }

    function getMinEarlyAllowance() external view returns (uint256){
        return SETTINGS.MIN_EARLY_ACCESS_ALLOWANCE;
    }
    
    function getBaseFee () external view returns (uint256) {
        return SETTINGS.BASE_FEE;
    }
    
    function getTokenFee () external view returns (uint256) {
        return SETTINGS.TOKEN_FEE;
    }
    
    function getReferralFee () external view returns (uint256) {
        return SETTINGS.REFERRAL_FEE;
    }
    
    function getEthCreationFee () external view returns (uint256) {
        return SETTINGS.ETH_CREATION_FEE;
    }
    
    function getEthAddress () external view returns (address payable) {
        return SETTINGS.ETH_FEE_ADDRESS;
    }
    
    function getTokenAddress () external view returns (address payable) {
        return SETTINGS.TOKEN_FEE_ADDRESS;
    }

    function getMinimumPercentToPYE () external view returns (uint256) {
        return SETTINGS.MIN_PERCENT_PYESWAP;
    }
    
    function setFeeAddresses(address payable _ethAddress, address payable _tokenFeeAddress) external onlyOwner {
        SETTINGS.ETH_FEE_ADDRESS = _ethAddress;
        SETTINGS.TOKEN_FEE_ADDRESS = _tokenFeeAddress;
    }
    
    function setFees(uint256 _baseFee, uint256 _tokenFee, uint256 _ethCreationFee, uint256 _referralFee) external onlyOwner {
        SETTINGS.BASE_FEE = _baseFee;
        SETTINGS.TOKEN_FEE = _tokenFee;
        SETTINGS.REFERRAL_FEE = _referralFee;
        SETTINGS.ETH_CREATION_FEE = _ethCreationFee;
    }
    
    function setLevel4RoundLength(uint256 _level4RoundLength) external onlyOwner {
        SETTINGS.LEVEL_4_ROUND_LENGTH = _level4RoundLength;
    }

    function setLevel3RoundLength(uint256 _level2RoundLength) external onlyOwner {
        SETTINGS.LEVEL_3_ROUND_LENGTH = _level2RoundLength;
    }

    function setLevel2RoundLength(uint256 _level3RoundLength) external onlyOwner {
        SETTINGS.LEVEL_2_ROUND_LENGTH = _level3RoundLength;
    }

    function setLevel1RoundLength(uint256 _level1RoundLength) external onlyOwner {
        SETTINGS.LEVEL_1_ROUND_LENGTH = _level1RoundLength;
    }

    function setMaxPresaleLength(uint256 _maxLength) external onlyOwner {
        SETTINGS.MAX_PRESALE_LENGTH = _maxLength;
    }

    function setMinSoftcapRate(uint256 _minSoftcapRate) external onlyOwner {
        SETTINGS.MIN_SOFTCAP_RATE = _minSoftcapRate;
    }

    function setMinPercentToPYESwap(uint256 _minPercentToPYE) external onlyOwner {
        require(_minPercentToPYE <= 1000);
        SETTINGS.MIN_PERCENT_PYESWAP = _minPercentToPYE;
    }

    function setMinEarlyAllowance(uint256 _minEarlyAllowance) external onlyOwner {
        SETTINGS.MIN_EARLY_ACCESS_ALLOWANCE = _minEarlyAllowance;
    }
    
    function editAllowedGenerators(address _generator, bool _allow) external onlyOwner {
        if (_allow) {
            ALLOWED_GENERATORS.add(_generator);
        } else {
            ALLOWED_GENERATORS.remove(_generator);
        }
    }

    function editAllowedReferrers(bytes32 _referralCode, address payable _referrer, bool _allow) external onlyOwner {
        if (_allow) {
            require(_referralCode != 0 && REFERRAL_OWNER[_referralCode] == address(0), 'Invalid Code');
            REFERRAL_OWNER[_referralCode] = _referrer;
            REFERRAL_OWNED_CODES[_referrer].add(_referralCode);
            ALLOWED_REFERRERS.add(_referrer);
        } else {
            require(REFERRAL_OWNER[_referralCode] == _referrer, 'Invalid Code');
            delete REFERRAL_OWNER[_referralCode];
            REFERRAL_OWNED_CODES[_referrer].remove(_referralCode);
            ALLOWED_REFERRERS.remove(_referrer);
        }
    }

    function enrollReferrer(bytes32 _referralCode) external {
        require(_referralCode != 0 && REFERRAL_OWNER[_referralCode] == address(0), 'Invalid Code');
        REFERRAL_OWNER[_referralCode] = payable(msg.sender);
        REFERRAL_OWNED_CODES[msg.sender].add(_referralCode);
        ALLOWED_REFERRERS.add(payable(msg.sender));
    }

    function addReferral(bytes32 _referralCode, address _project, address _presale, address _base) external returns (bool, address payable, uint256) {
        require(ALLOWED_GENERATORS.contains(msg.sender), 'Only Generator can call');
        address payable _referralAddress = REFERRAL_OWNER[_referralCode];
        bool _referrerIsValid = ALLOWED_REFERRERS.contains(_referralAddress);
        if(!_referrerIsValid) {
            return (false, payable(0), uint256(0));
        }

        ReferralHistory memory _referralHistory = ReferralHistory({
            project : _project,
            presale : _presale,
            baseToken : _base,
            active : true,
            success : false,
            presaleRaised : 0,
            referrerEarned : 0
        });
        referrerHistory[_referralCode].push(_referralHistory);

        uint256 _index = referrerHistory[_referralCode].length - 1;
        return (_referrerIsValid, _referralAddress, _index);
    }

    function finalizeReferral(bytes32 _referralCode, uint256 _index, bool _active, bool _success, uint256 _raised, uint256 _earned) external {
        require(msg.sender == referrerHistory[_referralCode][_index].presale, 'Caller not Presale');
        referrerHistory[_referralCode][_index].active = _active;
        referrerHistory[_referralCode][_index].success = _success;
        referrerHistory[_referralCode][_index].presaleRaised = _raised;
        referrerHistory[_referralCode][_index].referrerEarned = _earned;
    }
    
    function editEarlyAccessTokens(address _token, uint256 _level1Amount, uint256 _level2Amount, uint256 _level3Amount, uint256 _level4Amount, bool _ownedBalance, bool _allow) external onlyOwner {
        if (_allow) {
            EARLY_ACCESS_TOKENS.add(_token);
        } else {
            EARLY_ACCESS_TOKENS.remove(_token);
        }
        accessToken[_token].level1TokenAmount = _level1Amount;
        accessToken[_token].level2TokenAmount = _level2Amount;
        accessToken[_token].level3TokenAmount = _level3Amount;
        accessToken[_token].level4TokenAmount = _level4Amount;
        accessToken[_token].ownedBalance = _ownedBalance;
    }
    
    // there will never be more than 10 items in this array. Care for gas limits will be taken.
    // We are aware too many tokens in this unbounded array results in out of gas errors.
    function userAllowlistLevel (address _user) external view returns (uint8) {
        if (earlyAccessTokensLength() == 0) {
            return 0;
        }
        uint256 userBalance;
        for (uint i = 0; i < earlyAccessTokensLength(); i++) {
          (address token) = getEarlyAccessTokenAtIndex(i);
            if(accessToken[token].ownedBalance) {
                userBalance = IToken(token).getOwnedBalance(_user);
            } else {
                userBalance = IERC20(token).balanceOf(_user);
            }

            if (userBalance < accessToken[token].level1TokenAmount) {
                return 0;
            } else if (userBalance < accessToken[token].level2TokenAmount) {
                return 1;
            } else if (userBalance < accessToken[token].level3TokenAmount) {
                return 2;
            } else if (userBalance < accessToken[token].level4TokenAmount) {
                return 3;
            } else if (userBalance >= accessToken[token].level4TokenAmount) {
                return 4;
            }
        }
        return 0;
    }
    
    function getEarlyAccessTokenAtIndex(uint256 _index) public view returns (address) {
        address tokenAddress = EARLY_ACCESS_TOKENS.at(_index);
        return (tokenAddress);
    }
    
    function earlyAccessTokensLength() public view returns (uint256) {
        return EARLY_ACCESS_TOKENS.length();
    }
    
    // Referrers
    function allowedReferrersLength() external view returns (uint256) {
        return ALLOWED_REFERRERS.length();
    }
    
    function getReferrerAtIndex(uint256 _index) external view returns (address) {
        return ALLOWED_REFERRERS.at(_index);
    }

    function getReferrerOwnedCodes(address _referrer) external view returns (bytes32[] memory referrerCodes) {
        uint256 length = REFERRAL_OWNED_CODES[_referrer].length();
        referrerCodes = new bytes32[](length);
        for(uint i = 0; i < length; i++) {
            referrerCodes[i] = REFERRAL_OWNED_CODES[_referrer].at(i);
        }
    }

    function getReferredLength(bytes32 _referralCode) external view returns (uint256) {
        return referrerHistory[_referralCode].length;
    }

    function getReffererEarnings(bytes32 _referralCode) external view returns (uint256) {
        uint256 _earned;
        uint256 length = referrerHistory[_referralCode].length;
        for(uint i = 0; i < length; i++) {
            _earned += referrerHistory[_referralCode][i].referrerEarned;
        }
        return _earned;
    }

    function getReffererSuccess(bytes32 _referralCode) external view returns (uint256 numSuccess, uint256 numReferred, uint256[] memory raised, address[] memory base) {
        uint256 length = referrerHistory[_referralCode].length;
        raised = new uint256[](length);
        base = new address[](length);
        numReferred = length;
        for(uint i = 0; i < length; i++) {
            raised[i] = referrerHistory[_referralCode][i].presaleRaised;
            base[i] = referrerHistory[_referralCode][i].baseToken;
            if(referrerHistory[_referralCode][i].success) {
                numSuccess++;
            }
        }
    }
    
    function referrerIsValid(bytes32 _referralCode) external view returns (bool, address payable) {
        address payable _referralAddress = REFERRAL_OWNER[_referralCode];
        bool _referrerIsValid = ALLOWED_REFERRERS.contains(_referralAddress);
        return (_referrerIsValid, _referralAddress);
    }

    function baseTokenIsValid(address _baseToken) external view returns (bool) {
        return ALLOWED_BASE_TOKENS[_baseToken];
    }

    function setAllowedBaseToken(address _baseToken, bool _flag) external onlyOwner {
        ALLOWED_BASE_TOKENS[_baseToken] = _flag;
    }
    
}