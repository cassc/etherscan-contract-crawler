// SPDX-License-Identifier: MIT

/*
 * BNBPower 
 * App:             https://bnbpower.io
 * Twitter:         https://twitter.com/bnbpwr
 */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IReferrals.sol";

interface IHelp {
    function Bytecode_1_0_3() external view returns (bool);
}

contract BNBPower is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint40;
    using SafeMath for uint8;
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    struct packagesStruct {
        bool isExist;
        uint rate;
        uint percent;
        uint min;
        uint giveway;
        uint commission;
        uint256[5] refPercent;
    }

    struct UserInfo {
        uint256 amount;
        uint256 lastClaim;
        uint256 profit;
        uint256 withdraw;
    }

    mapping(uint => packagesStruct) public packages;
    mapping(address => UserInfo) public users;
    mapping(address => bool) public gainSponsorsCheck;
    mapping(uint => address) public countGainSponsorsCheck;
    mapping(address => mapping(address => bool)) public firstDeposit;

    uint public lastPackage;
    uint256 public timeStart;
    uint256 public totalStaked;
    uint256 public totalWithdraws;
    uint256 public totalStakedProject;
    uint256 public totalPoolClaim;
    uint256 public totalRecompound;
    IReferrals Referrals;

    uint256 constant public factor = 10000; // 100 = 1%
    address payable public dev;
    uint256 public devFee = 1000;
    uint256 public devHarvestFee = 0;
    uint256 public harvestFee = 1000;
    
    constructor(address payable _dev, uint256 _timeStart, IReferrals _Referrals, uint _rate, uint _percent, uint _min, uint _giveway, uint _commission, uint256[5] memory _refPercents) {
        dev = _dev;
        timeStart = _timeStart;
        Referrals = _Referrals;
        packagesStruct memory packages_struct;
        packages_struct = packagesStruct({
            isExist: true,
            rate: _rate,
            percent: _percent,
            min: _min,
            giveway: _giveway,
            commission: _commission,
            refPercent: _refPercents
        });
        packages[lastPackage] = packages_struct;
        lastPackage++;
    }

    // transfer commissions to sponsors
    function _referrals(uint _package, address _user, uint256 _amount) internal {
        address _sponsor = _user;

        for(uint i = 0; i < 5; i++) {
            _sponsor = Referrals.getSponsor(_sponsor);
            if(_sponsor == address(0)) break;
            if(_sponsor == _user) break;

            if(gainSponsorsCheck[_sponsor] == true) {
                continue;
            }

            UserInfo storage user = users[_sponsor];

            if(user.amount > 0) {
                uint256 fee = _amount.mul(packages[_package].refPercent[i]).div(factor);
                _transfer(_sponsor, fee);
                Referrals.updateEarn(_sponsor, fee);
                gainSponsorsCheck[_sponsor] = true;
                countGainSponsorsCheck[i] = _sponsor;
            }

        }

        for(uint i = 0; i < 5; i++) {
            gainSponsorsCheck[countGainSponsorsCheck[i]] = false;
            countGainSponsorsCheck[i] = address(0);
        }

    }

    // transfer the ether to the user
    function _transfer(address _user, uint256 _amount) internal {
        if(_amount > 0){
            Referrals.transfer(_user, _amount);
        }
    }

    // deposit ether to the contract
    function deposit(address _ref) external nonReentrant payable {
        uint256 amount = msg.value;
        uint256 currentBlockTimestamp = uint256(block.timestamp);
        bool hasLaunchPassed = currentBlockTimestamp > timeStart;
        require(packages[0].isExist, "Package not found");
        require(amount >= packages[0].min, "Minimum deposit error!");
        require(hasLaunchPassed == true, "We still havent launched yet!");

        if(amount > 0 && address(this).balance > 0){
            payable(address(Referrals)).transfer(amount);
        }

        packagesStruct storage package = packages[0];
        UserInfo storage user = users[msg.sender];

        _transfer(dev, amount.mul(devFee).div(factor));
        
        if(Referrals.isMember(msg.sender) == false){
            Referrals.registerUser(msg.sender, _ref);
        } else {
            _ref = Referrals.getSponsor(msg.sender);
        }

        UserInfo storage sponsor = users[_ref];

        if(sponsor.amount > 0 && firstDeposit[_ref][msg.sender] == false) {
            uint256 amountFeeComission = amount.mul(package.commission).div(factor);
            _transfer(_ref, amountFeeComission);
            Referrals.updateEarn(_ref, amountFeeComission);
            firstDeposit[_ref][msg.sender] = true;
        }

        _transfer(msg.sender, amount.mul(package.giveway).div(factor));

        _referrals(0, msg.sender, amount);

        totalStaked = totalStaked.add(amount);

        totalStakedProject = totalStakedProject.add(amount);

        if(user.amount > 0 && this.pendingReward(msg.sender) > 0) {
            _claim(msg.sender);
        }

        user.amount = user.amount.add(amount);
        user.lastClaim = block.timestamp;

    }

    // recompound ether to the contract
    function recompound() external nonReentrant 
    {
        UserInfo storage user = users[msg.sender];
        uint256 pending = this.pendingReward(msg.sender);
        require(user.amount > 0 && pending > 0, "You have no rewards!");
        
        uint256 amount = pending;

        _transfer(dev, amount.mul(devFee).div(factor));
        
        _referrals(0, msg.sender, amount);

        totalStaked = totalStaked.add(amount);

        totalStakedProject = totalStakedProject.add(amount);

        totalRecompound = totalRecompound.add(amount);

        user.amount = user.amount.add(amount);
        user.lastClaim = block.timestamp;

    }

    // claim earnings
    function _claim(address _user) internal {
        packagesStruct storage package = packages[0];
        UserInfo storage user = users[_user];
        
        uint256 pending = this.pendingReward(_user);

        if(user.amount > 0 && pending > 0) {
            user.lastClaim = block.timestamp;

            bool finish = false;
            uint256 max = (user.amount * package.percent / factor);
            uint256 toSend = user.profit + pending;
            
            if(toSend >= max) {
                pending = max.sub(user.profit);
                finish = true;
            }

            if(pending > address(Referrals).balance) {
                pending = address(Referrals).balance;
            }

            if (pending > 0) {
                user.profit = user.profit.add(pending);

                uint256 amountClaimDev = pending.mul(devHarvestFee).div(factor);
                uint256 amountClaimPool = pending.mul(harvestFee).div(factor);
                uint256 amountClaimUser = pending.sub(amountClaimDev.add(amountClaimPool));

                totalPoolClaim = totalPoolClaim.add(amountClaimPool);

                _transfer(dev, amountClaimDev);

                _transfer(address(Referrals), amountClaimPool);

                _transfer(_user, amountClaimUser);

                user.withdraw = user.withdraw.add(pending);
                totalWithdraws = totalWithdraws.add(pending);
            }

            if(finish) {
                totalStaked = totalStaked.sub(user.amount);
                user.profit = 0;
                user.amount = 0;
                user.lastClaim = 0;
            }

        }
    }

    // claim earnings
    function withdraw(address _user) external nonReentrant {
        _claim(_user);
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = users[_user];
        packagesStruct storage package = packages[0];
        if(user.amount > 0 && user.lastClaim > 0){
            uint256 dayInSeconds = 1 days;
            uint256 timeBetweenLast = block.timestamp.sub(user.lastClaim);
            return (user.amount.mul(package.rate)
            .mul(timeBetweenLast))
            .div(dayInSeconds)
            .div(factor);
        }
        return 0;
    }

    // Update package variables
    function updatePackages(uint _rate, uint _percent, uint _min, uint _giveway, uint _commission, uint256[5] memory _refPercents) external onlyOwner nonReentrant {
        packagesStruct storage package = packages[0];
        package.rate = _rate;
        package.percent = _percent;
        package.min = _min;
        package.giveway = _giveway;
        package.commission = _commission;
        package.refPercent = _refPercents;
    }

    // Update the rate
    function updateRate(uint _value) external onlyOwner nonReentrant {
        packagesStruct storage package = packages[0];
        package.rate = _value;
    }

    // Update the percent
    function updatePercent(uint _value) external onlyOwner nonReentrant {
        packagesStruct storage package = packages[0];
        package.percent = _value;
    }

    // Update the min
    function updateMin(uint _value) external onlyOwner nonReentrant {
        packagesStruct storage package = packages[0];
        package.min = _value;
    }

    // Update the giveway
    function updateGiveway(uint _value) external onlyOwner nonReentrant {
        packagesStruct storage package = packages[0];
        package.giveway = _value;
    }

    // Update the commission
    function updateCommission(uint _value) external onlyOwner nonReentrant {
        packagesStruct storage package = packages[0];
        package.commission = _value;
    }

    // Update the refPercent
    function updateRefPercent(uint256[5] memory _value) external onlyOwner nonReentrant {
        packagesStruct storage package = packages[0];
        package.refPercent = _value;
    }

    // returns packet information
    function getPackage() external view returns(uint, uint, uint, uint, uint) {
        packagesStruct storage p = packages[0];
        return (p.rate, p.percent, p.min, p.giveway, p.commission);
    }

    // returns referral information
    function getRefPercent() external view returns(uint, uint, uint, uint, uint) {
        packagesStruct storage p = packages[0];
        return (p.refPercent[0], p.refPercent[1], p.refPercent[2], p.refPercent[3], p.refPercent[4]);
    }

    // returns user information
    function infoUser(address _user) external view returns(uint, uint, uint, uint) {
        UserInfo storage u = users[_user];
        return(u.amount, u.lastClaim, u.profit, u.withdraw);
    }

    // returns balance contract
    function getBalance() external view returns(uint256) {
        return address(this).balance;
    }

    // withdraw lost tokens
    function withdrawERC20(address _token) public onlyOwner {
        IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }

    // adjust fee Dev
    function setdevFee(uint256 _devFee) public onlyOwner {
       devFee = _devFee;
    }

    // adjust fee harvest Dev
    function setdevHarvestFee(uint256 _devHarvestFee) public onlyOwner {
       devHarvestFee = _devHarvestFee;
    }

    // adjust fee Harvest
    function setharvestFee(uint256 _harvestFee) public onlyOwner {
       harvestFee = _harvestFee;
    }

}