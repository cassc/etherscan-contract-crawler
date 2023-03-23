// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

interface IRegistration {
    function isRegistered(address _user) external view returns(bool);
    function getReferrerAddresses(address _user) external view returns(address[] memory _referrers);
}

contract DeXaPresale is OwnableUpgradeable, ReentrancyGuardUpgradeable {

    IERC20 public dexa;
    IERC20 public ntr;
    IERC20 public busd;
    IRegistration public register;
    mapping (address => uint256) public refRewardByBUSD;
    mapping (address => uint256) public refRewardByNTR;
    uint256 public ntrAmountForCoreTeam;
    uint256 public busdAmountForCoreTeam;
    uint256 public ntrAmountForOwner;
    uint256 public busdAmountForOwner;
    address public coreTeamAddress;
    address public companyAddress;
    uint32 public percentForCoreTeam;

    struct ContributionInfo {
        uint256 contributedBusdAmount;
        uint256 contributedNtrAmount;
        uint256 purchaseTimeForBusd;
        uint256 purchaseTimeForNtr;
        uint256 claimedTokenAmountForBusd;
        uint256 claimedTokenAmountForNtr;
        uint256 totalClaimableTokenAmountForBusd;
        uint256 totalClaimableTokenAmountForNtr;
    }

    struct RoundInfo {
        uint256 priceForBusd;
        uint256 priceForNtr;
        uint256 startTime;
        uint256 endTime;
        uint8 lockMonths;
        uint256 maxDexaAmountToSell;
        bool busdEnabled;
        bool ntrEnabled;
        uint256 busdRaised;
        uint256 ntrRaised;
        uint256 minContributionForBusd;
        uint256 minContributionForNtr;
        uint256 maxContributionForBusd;
        uint256 maxContributionForNtr;
        mapping(address => ContributionInfo) contributions;
    }
    RoundInfo[3] public roundInfo;

    uint8 public constant referralDeep = 6;
    uint8[referralDeep] public referralRate;
    uint256 private constant MONTH = 86400 * 30;
    uint32 private constant MULTIPLER = 100000;

    uint32 public releaseMonth;

    event TokenPurchaseWithNTR(address indexed beneficiary, uint8 round, uint256 ntrAmount, uint256 ntrAmountForOwner);
    event TokenPurchaseWithBUSD(address indexed beneficiary, uint8 round, uint256 busdAmount, uint256 busdAmountForOwner);
    event TokenClaim(address indexed beneficiary, uint8 round, uint256 tokenAmount);
    event RefRewardClaimBUSD(address indexed referrer, uint256 amount);
    event RefRewardClaimNTR(address indexed referrer, uint256 amount);
    event SetRefRewardBUSD(address indexed referrer, address indexed user, uint8 level, uint8 round, uint256 amount);
    event SetRefRewardNTR(address indexed referrer, address indexed user, uint8 level, uint8 round, uint256 amount);
    
    modifier onlyRegisterUser {
      require(register.isRegistered(msg.sender), "No registered.");
      _;
    }

    function  initialize (
        address _dexa,
        address _ntr,
        address _busd,
        address _register,
        address _company,
        address _coreTeam
    )  public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        dexa = IERC20(_dexa);
        ntr = IERC20(_ntr);
        busd = IERC20(_busd);
        register = IRegistration(_register);
        coreTeamAddress = _coreTeam;
        companyAddress = _company;
        percentForCoreTeam = 10000;
        releaseMonth = 10;
    }

    function getRound() public view returns(int8) {
        int8 ret = -1;
        uint256 nowTime = block.timestamp;
        
        if(nowTime < roundInfo[0].startTime) {
            ret = -1; // any round is not started
        } else if(nowTime >= roundInfo[0].startTime && nowTime < roundInfo[0].endTime) {
            ret = 0; // in round 1
        } else if(nowTime >= roundInfo[0].endTime && nowTime < roundInfo[1].startTime) {
            ret = -2; // round 2 is not started
        } else if(nowTime >= roundInfo[1].startTime && nowTime < roundInfo[1].endTime) {
            ret = 1; // in round 2
        } else if(nowTime >= roundInfo[1].endTime && nowTime < roundInfo[2].startTime) {
            ret = -3; // round 3 is not started
        } else if(nowTime >= roundInfo[2].startTime && nowTime < roundInfo[2].endTime) {
            ret = 2; // in round 3
        } else if(nowTime >= roundInfo[2].endTime) {
            ret = -4; // all round is ended
        }
        return ret;
    }

    function tokenPurchaseWithBUSD(uint256 _busdAmount) public onlyRegisterUser {
        int8 _round = getRound();
        require(_round == 0 || _round == 1 || _round == 2, "Not started any Round.");

        require(!hasSoldOut(uint8(_round), true), "Dexa is already sold out!");

        RoundInfo storage info = roundInfo[uint8(_round)];
        require(info.busdEnabled, "Not enable to purchase with BUSD");

        require(_busdAmount >= info.minContributionForBusd, "Min contribution criteria not met");
        require(_busdAmount <= info.maxContributionForBusd, "Max contribution criteria not met");

        busd.transferFrom(msg.sender, address(this), _busdAmount);

        info.busdRaised = info.busdRaised + _busdAmount;

        info.contributions[msg.sender].contributedBusdAmount += _busdAmount;
        if (info.contributions[msg.sender].purchaseTimeForBusd == 0) {
            info.contributions[msg.sender].purchaseTimeForBusd = block.timestamp;
        }

        uint256 busdForCoreTeam = _busdAmount * percentForCoreTeam / MULTIPLER;

        busdAmountForCoreTeam += busdForCoreTeam;

        uint256 busdForOwner = _busdAmount - busdForCoreTeam; 

        uint256 tokenAmount = _busdAmount * MULTIPLER / info.priceForBusd;
        
        info.contributions[msg.sender].totalClaimableTokenAmountForBusd += tokenAmount;

        address[] memory referrers = register.getReferrerAddresses(msg.sender);
        for(uint8 i = 0; i < referralDeep; i++) {
            if(referrers[i] == address(0)) {
                break;
            }
            uint256 bonus = _busdAmount * referralRate[i] / MULTIPLER;
            refRewardByBUSD[referrers[i]] += bonus;
            busdForOwner -= bonus;
            emit SetRefRewardBUSD(referrers[i], msg.sender, uint8(i + 1), uint8(_round), bonus);
        }

        busdAmountForOwner += busdForOwner;

        emit TokenPurchaseWithBUSD(msg.sender, uint8(_round), _busdAmount, busdForOwner);
    }

    function tokenPurchaseWithNtr(uint256 _ntrAmount) public onlyRegisterUser {
        int8 _round = getRound();
        require(_round == 0 || _round == 1 || _round == 2, "Not started any Round.");

        require(!hasSoldOut(uint8(_round), false), "Dexa is already sold out!");

        RoundInfo storage info = roundInfo[uint8(_round)];
        require(info.ntrEnabled, "Not enable to purchase with NTR");

        require(_ntrAmount >= info.minContributionForNtr, "Min contribution criteria not met");
        require(_ntrAmount <= info.maxContributionForNtr, "Max contribution criteria not met");

        ntr.transferFrom(msg.sender, address(this), _ntrAmount);

        info.ntrRaised = info.ntrRaised + _ntrAmount;

        info.contributions[msg.sender].contributedNtrAmount += _ntrAmount;
        
        if (info.contributions[msg.sender].purchaseTimeForNtr == 0) {
            info.contributions[msg.sender].purchaseTimeForNtr = block.timestamp;
        }

        uint256 ntrForCoreTeam = _ntrAmount * percentForCoreTeam / MULTIPLER;

        ntrAmountForCoreTeam += ntrForCoreTeam;

        uint256 ntrForOwner = _ntrAmount - ntrForCoreTeam;

        uint256 tokenAmount = _ntrAmount * MULTIPLER / info.priceForNtr;
        
        info.contributions[msg.sender].totalClaimableTokenAmountForNtr += tokenAmount;

        address[] memory referrers = register.getReferrerAddresses(msg.sender);
        for(uint8 i = 0; i < referralDeep; i++) {
            if(referrers[i] == address(0)) {
                break;
            }
            uint256 bonus = _ntrAmount * referralRate[i] / MULTIPLER;
            refRewardByNTR[referrers[i]] += bonus;
            ntrForOwner -= bonus;
            emit SetRefRewardNTR(referrers[i], msg.sender, uint8(i + 1), uint8(_round), bonus);
        }

        ntrAmountForOwner += ntrForOwner;

        emit TokenPurchaseWithNTR(msg.sender, uint8(_round), _ntrAmount, ntrForOwner);
    }

    function claimTokensFromBusd(uint8 _round) external nonReentrant onlyRegisterUser {
        ContributionInfo storage cInfo = roundInfo[_round].contributions[msg.sender];
        require(cInfo.contributedBusdAmount > 0, "Nothing to claim");
        require((block.timestamp - cInfo.purchaseTimeForBusd) / MONTH >= roundInfo[_round].lockMonths, "Locked");
        
        uint256 tokenAmount = getClaimableTokenAmountFromBusd(_round, msg.sender);
        cInfo.claimedTokenAmountForBusd += tokenAmount;
        
        dexa.transfer(msg.sender, tokenAmount);

        emit TokenClaim(msg.sender, _round, tokenAmount);
    }

    function claimTokensFromNtr(uint8 _round) external nonReentrant onlyRegisterUser {
        ContributionInfo storage cInfo = roundInfo[_round].contributions[msg.sender];
        require(cInfo.contributedNtrAmount > 0, "Nothing to claim");
        require((block.timestamp - cInfo.purchaseTimeForNtr) / MONTH >= roundInfo[_round].lockMonths, "Locked");

        uint256 tokenAmount = getClaimableTokenAmountFromNtr(_round, msg.sender);
        cInfo.claimedTokenAmountForNtr += tokenAmount;
                
        dexa.transfer(msg.sender, tokenAmount);

        emit TokenClaim(msg.sender, _round, tokenAmount);
    }

    function claimRefRewardBUSD() external nonReentrant onlyRegisterUser {
        int8 _round = getRound();
        if((_round == 0 || _round == 1 || _round == 2) && hasSoldOut(uint8(_round), true)) {} 
        else require(_hasEnded(), "Round is not over");
        require(refRewardByBUSD[msg.sender] > 0, "Nothing to claim.");
        uint256 _amount = refRewardByBUSD[msg.sender];
        refRewardByBUSD[msg.sender] = 0;
        busd.transfer(msg.sender, _amount);
        emit RefRewardClaimBUSD(msg.sender, _amount);
    }

    function claimRefRewardNTR() external nonReentrant onlyRegisterUser {
        int8 _round = getRound();
        if((_round == 0 || _round == 1 || _round == 2) && hasSoldOut(uint8(_round), false)) {} 
        else require(_hasEnded(), "Round is not over");
        require(refRewardByNTR[msg.sender] > 0, "Nothing to claim.");
        uint256 _amount = refRewardByNTR[msg.sender];
        refRewardByNTR[msg.sender] = 0;
        busd.transfer(msg.sender, _amount);
        emit RefRewardClaimNTR(msg.sender, _amount);
    }
    
    function getClaimableTokenAmountFromBusd(uint8 _round, address _user) public view returns (uint256) {
        RoundInfo storage info = roundInfo[_round];
        ContributionInfo memory contribution = info.contributions[_user];
        if ((block.timestamp - contribution.purchaseTimeForBusd) / MONTH > info.lockMonths) {
            uint256 months = (block.timestamp - contribution.purchaseTimeForBusd) / MONTH - info.lockMonths;
            if(months > releaseMonth) months = releaseMonth;
            uint256 tokenAmount = months * contribution.totalClaimableTokenAmountForBusd / releaseMonth - contribution.claimedTokenAmountForBusd;
            return tokenAmount;
        } else {
            return 0;
        }
    }

    function getClaimableTokenAmountFromNtr(uint8 _round, address _user) public view returns (uint256) {
        RoundInfo storage info = roundInfo[_round];
        ContributionInfo memory contribution = info.contributions[_user];
        if ((block.timestamp - contribution.purchaseTimeForNtr) / MONTH > info.lockMonths) {
            uint256 months = (block.timestamp - contribution.purchaseTimeForNtr) / MONTH - info.lockMonths;
            if(months > releaseMonth) months = releaseMonth;
            uint256 tokenAmount = months * contribution.totalClaimableTokenAmountForNtr / releaseMonth - contribution.claimedTokenAmountForNtr;
            return tokenAmount;
        } else {
            return 0;
        }
    }

    function hasSoldOut(uint8 _round, bool _isBusd) public view returns (bool) {
        RoundInfo storage info = roundInfo[_round];
        uint256 dexaAmount = 0;
        if(_isBusd) dexaAmount = info.busdRaised * MULTIPLER / info.priceForBusd;
        else dexaAmount = info.ntrRaised * MULTIPLER / info.priceForNtr;

        if(dexaAmount > info.maxDexaAmountToSell) return true;
        else return false;
    }

    function _hasEnded() internal view returns(bool) {
        int8 _round = getRound();
        if(_round == -2 || _round == -3 || _round == -4) 
            return true;
        else
            return false;
    }

    function getContribute(address _user, uint8 _round) public view returns (ContributionInfo memory) {
        return roundInfo[_round].contributions[_user];
    }

    function getReferralRateAndAddresses() public view returns (uint8[referralDeep] memory _referralRate, uint32 _percentForCoreTeam, 
        address _coreTeamAddress, address _companyAddress) {
        _referralRate = referralRate;
        _percentForCoreTeam = percentForCoreTeam;
        _coreTeamAddress = coreTeamAddress;
        _companyAddress = companyAddress;
    }

    /////////////////////////////////////
    //////// Owner Functions ////////////
    /////////////////////////////////////

    function withdrawBusdForCoreTeam() external onlyOwner {
        int8 _round = getRound();
        if((_round == 0 || _round == 1 || _round == 2) && hasSoldOut(uint8(_round), true)) {} 
        else require(_hasEnded(), "Round is not over");
        require(busdAmountForCoreTeam > 0, "Nothing to claim.");
        uint256 amount = busdAmountForCoreTeam;
        busdAmountForCoreTeam = 0;
        busd.transfer(coreTeamAddress, amount);
    }

    function withdrawNtrForCoreTeam() external onlyOwner {
        int8 _round = getRound();
        if((_round == 0 || _round == 1 || _round == 2) && hasSoldOut(uint8(_round), false)) {} 
        else require(_hasEnded(), "Round is not over");
        require(ntrAmountForCoreTeam > 0, "Nothing to claim.");
        uint256 amount = ntrAmountForCoreTeam;
        ntrAmountForCoreTeam = 0;
        ntr.transfer(coreTeamAddress, amount);
    }

    function withdrawBUSD() external onlyOwner {
        int8 _round = getRound();
        if((_round == 0 || _round == 1 || _round == 2) && hasSoldOut(uint8(_round), true)) {} 
        else require(_hasEnded(), "Round is not over");
        uint256 amount = busdAmountForOwner;
        busdAmountForOwner = 0;
        busd.transfer(companyAddress, amount);
    }

    function withdrawNtr() public onlyOwner {
        int8 _round = getRound();
        if((_round == 0 || _round == 1 || _round == 2) && hasSoldOut(uint8(_round), false)) {} 
        else require(_hasEnded(), "Round is not over");
        require(ntrAmountForOwner > 0, "Nothing to claim.");
        uint256 amount = ntrAmountForOwner;
        ntrAmountForOwner = 0;
        ntr.transfer(companyAddress, amount);
    }

    function withdrawDexa() public onlyOwner {
        require(_hasEnded(), "Round is not over");
        uint256 tokens = dexa.balanceOf(address(this));
        dexa.transfer(msg.sender, tokens);
    }

    function setRoundInfoForBusd(
        uint8 _index, 
        uint256 _priceForBusd,
        uint256 _startTime, 
        uint256 _endTime,
        uint8 _lockMonths,
        uint256 _maxDexaAmountToSell,
        uint256 _minContributionForBusd,
        uint256 _maxContributionForBusd
    ) public onlyOwner() {
        RoundInfo storage info = roundInfo[_index];
        info.priceForBusd = _priceForBusd;
        info.priceForNtr = 0;
        info.startTime = _startTime;
        info.endTime = _endTime;
        info.lockMonths = _lockMonths;
        info.maxDexaAmountToSell = _maxDexaAmountToSell;
        info.busdEnabled = true;
        info.ntrEnabled = false;
        info.minContributionForBusd = _minContributionForBusd;
        info.minContributionForNtr = 0;
        info.maxContributionForBusd = _maxContributionForBusd;
        info.maxContributionForNtr = 0;
    }

    function setRoundInfoForNtr(
        uint8 _index,
        uint256 _priceForNtr, 
        uint256 _startTime, 
        uint256 _endTime,
        uint8 _lockMonths,
        uint256 _maxDexaAmountToSell,
        uint256 _minContributionForNtr,
        uint256 _maxContributionForNtr
    ) public onlyOwner() {
        RoundInfo storage info = roundInfo[_index];
        info.priceForBusd = 0;
        info.priceForNtr = _priceForNtr;
        info.startTime = _startTime;
        info.endTime = _endTime;
        info.lockMonths = _lockMonths;
        info.maxDexaAmountToSell = _maxDexaAmountToSell;
        info.busdEnabled = false;
        info.ntrEnabled = true;
        info.minContributionForBusd = 0;
        info.minContributionForNtr = _minContributionForNtr;
        info.maxContributionForBusd = 0;
        info.maxContributionForNtr = _maxContributionForNtr;
    }

    function setReferralRate(uint8[] memory _rates) public onlyOwner {
        require(_rates.length == referralDeep, "Invalid Input.");
        for(uint8 i = 0; i < _rates.length; i++) {
            referralRate[i] = _rates[i];
        }
    }

    function setRateForCoreTeam(uint32 _rate) public onlyOwner {
        percentForCoreTeam = _rate;
    }

    function setReleaseMonths(uint32 _releaseMonths) public onlyOwner {
        releaseMonth = _releaseMonths;
    }

    function changeRegisterAddress(address _newAddress) public onlyOwner {
        register = IRegistration(_newAddress);
    }

    function changeDexaAddress(address _newAddress) public onlyOwner {
        dexa = IERC20(_newAddress);
    }

    function changeNtrAddress(address _newAddress) public onlyOwner {
        ntr = IERC20(_newAddress);
    }

    function changeCoreTeamAddress(address _newAddress) public onlyOwner {
        coreTeamAddress = _newAddress;
    }

    function changeCompanyAddress(address _newAddress) public onlyOwner {
        companyAddress = _newAddress;
    }
}