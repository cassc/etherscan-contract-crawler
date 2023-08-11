pragma solidity >=0.5.16;
pragma experimental ABIEncoderV2;

import "./EIP20Interface.sol";
import "./SafeMath.sol";

contract EsgSHIPV2{
    using SafeMath for uint256;
    /// @notice ESG token
    EIP20Interface public esg;

    /// @notice Emitted when referral set invitee
    event SetInvitee(address inviteeAddress);

    /// @notice Emitted when owner set referral
    event SetInviteeByOwner(address referralAddress);

    /// @notice Emitted when ESG is invest  
    event EsgInvest(address account, uint amount, uint month, bool useInterest);

    /// @notice Emitted when ESG is invest by owner  
    event EsgInvestByOwner(address account, uint amount, uint month, uint starttime, uint endtime);

    /// @notice Emitted when ESG is withdrawn 
    event EsgWithdraw(address account, uint amount);

    /// @notice Emitted when ESG is claimed 
    event EsgClaimed(address account, uint amount);

    /// @notice Emitted when change referral info
    event EsgChangeReferrerInfo(address referralAddress, address inviteeAddress, address newInviteeAddress);

    /// @notice Emitted when change Lock info
    event EsgChangeLockInfo(address _user, uint256 _amount, uint256 _start, uint256 _end, uint256 _month, uint256 i);

    struct Lock {
        uint256 amount;
        uint256 start;
        uint256 end;
        uint256 month;
    }

    mapping(uint256 => uint256) public lockRates;

    mapping(address => Lock[]) public locks;

    mapping(address => uint256) public interests;

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    struct Referrer {
        address[] referrals;
        uint256 totalInvestment;
        bool dynamicReward;
    }

    mapping(address => Referrer) public referrers;

    struct User {
        address referrer_addr;
    }

    mapping (address => User) public referrerlist;

    uint256 public referralThreshold = 3000 * 1e18;

    uint256 public dynamicRewardThreshold = 100000 * 1e18;

    uint256 public onetimeRewardPercentage = 7;

    uint256 public dynamicRewardPercentage = 4;

    uint256 public dynamicRewardPercentageEvery = 10;

    uint256 public burnPercentage = 5;

    uint256 public total_deposited;

    uint256 public total_user;

    bool public allow_get_esg = true;

    constructor(address esgAddress) public {
        owner = msg.sender;
        lockRates[9] = 50;
        lockRates[12] = 60;
        lockRates[18] = 100;
        esg = EIP20Interface(esgAddress);
    }

    function setLockRate(uint256 _months, uint256 _rate) public onlyOwner {
        lockRates[_months] = _rate;
    }

    function setReferralThreshold(uint256 _amount) public onlyOwner {
        referralThreshold = _amount;
    }

    function setDynamicRewardThreshold(uint256 _amount) public onlyOwner {
        dynamicRewardThreshold = _amount;
    }

    function setOnetimeRewardPercentage(uint256 _percentage) public onlyOwner {
        onetimeRewardPercentage = _percentage;
    }

    function setDynamicRewardPercentage(uint256 _percentage) public onlyOwner {
        dynamicRewardPercentage = _percentage;
    }

    function setDynamicRewardPercentageEvery(uint256 _percentage) public onlyOwner {
        dynamicRewardPercentageEvery = _percentage;
    }

    function setBurnPercentage(uint256 _percentage) public onlyOwner {
        burnPercentage = _percentage;
    }

    function setInvitee(address inviteeAddress) public returns (bool) {
        require(inviteeAddress != address(0), "inviteeAddress cannot be 0x0.");

        User storage user = referrerlist[inviteeAddress];
        require(user.referrer_addr == address(0), "This account had been invited!");

        Lock[] storage referrerLocks = locks[msg.sender];
        require(referrerLocks.length > 0, "Referrer has no locked amount.");

        uint256 referrerAmount = 0;

        for (uint256 i = 0; i < referrerLocks.length; i++) {
            Lock storage lock = referrerLocks[i];
            referrerAmount += lock.amount;
        }

        require(referrerAmount >= referralThreshold,"Referrer has no referral qualification.");

        Lock[] storage inviteeLocks = locks[inviteeAddress];
        require(inviteeLocks.length == 0, "This account had staked!");

        Referrer storage referrer = referrers[msg.sender];
        referrer.referrals.push(inviteeAddress);

        User storage _user = referrerlist[inviteeAddress];
        _user.referrer_addr = msg.sender;

        emit SetInvitee(inviteeAddress);
        return true;   
    }

    function setInviteeByOwner(address referrerAddress, address[] memory inviteeAddress) public onlyOwner returns (bool) {
        require(referrerAddress != address(0), "referrerAddress cannot be 0x0.");
        require(inviteeAddress.length > 0, "inviteeAddress cannot be 0.");

        Referrer storage referrer = referrers[referrerAddress];
        referrer.referrals = inviteeAddress;

        for(uint256 i = 0; i < inviteeAddress.length; i++){
            address _inviteeAddress = inviteeAddress[i];
            User storage _user = referrerlist[_inviteeAddress];
            if(_user.referrer_addr == address(0)){
                _user.referrer_addr = referrerAddress;
            }
        }

        emit SetInviteeByOwner(referrerAddress);
        return true;   
    }

    function getInviteelist(address referrerAddress) public view returns (address[] memory) {
        require(referrerAddress != address(0), "referrerAddress cannot be 0x0.");
        Referrer storage referrer = referrers[referrerAddress];
        return referrer.referrals;
    }

    function getReferrer(address inviteeAddress) public view returns (address) {
        require(inviteeAddress != address(0), "inviteeAddress cannot be 0x0.");
        User storage user = referrerlist[inviteeAddress];
        return user.referrer_addr;
    }

    function invest(uint256 _months, uint256 _amount, bool _useInterest) public returns (bool) {
        require(allow_get_esg == true, "No invest allowed!");
        require(lockRates[_months] > 0, "Invalid lock period.");
        require(_amount > 0, "Invalid amount.");

        if (_useInterest) {
            uint256 interest = calculateInterest(msg.sender);
            require(interest >= _amount, "Insufficient interest.");
            interests[msg.sender] -= _amount;
        } else {
            esg.transferFrom(msg.sender, address(this), _amount);
        }

        locks[msg.sender].push(
            Lock(
                _amount,
                block.timestamp,
                block.timestamp + _months * 30 days,
                _months
            )
        );

        total_deposited = total_deposited + _amount;
        total_user = total_user + 1;
            
        User storage user = referrerlist[msg.sender];

        if(user.referrer_addr != address(0)){
            referrers[user.referrer_addr].totalInvestment += _amount;

            if (referrers[user.referrer_addr].totalInvestment >= dynamicRewardThreshold) {
                referrers[user.referrer_addr].dynamicReward = true;
            }
            uint256 onetimeTotalReward = _amount.mul(lockRates[_months]).div(100).mul(onetimeRewardPercentage).div(100);
            uint256 onetimeReward = onetimeTotalReward.div(12).mul(_months);
            esg.transfer(user.referrer_addr, onetimeReward);
        }

        emit EsgInvest(msg.sender, _amount, _months, _useInterest);
        return true;
    }

    function investByOwner(uint256 start, uint256 end, uint256 _amount, uint256 month, address inviteeAddress) public onlyOwner returns (bool) {
        require(start > 0, "start cannot be 0.");
        require(end > 0, "start cannot be 0.");
        require(_amount > 0, "Invalid amount.");
        require(month > 0, "month cannot be 0.");
        require(inviteeAddress != address(0), "inviteeAddress cannot be 0x0.");

        locks[inviteeAddress].push(
            Lock(
                _amount,
                start,
                end,
                month
            )
        );

        total_deposited = total_deposited + _amount;
        total_user = total_user + 1;
            
        User storage user = referrerlist[inviteeAddress];

        if(user.referrer_addr != address(0)){
            referrers[user.referrer_addr].totalInvestment += _amount;

            if (referrers[user.referrer_addr].totalInvestment >= dynamicRewardThreshold) {
                referrers[user.referrer_addr].dynamicReward = true;
            }
        }

        emit EsgInvestByOwner(inviteeAddress, _amount, month, start, end);
        return true;
    }

    function withdraw() public returns (bool) {
        require(allow_get_esg == true, "No withdrawal allowed!");
        Lock[] storage userLocks = locks[msg.sender];
        require(userLocks.length > 0, "No locked amount.");

        uint256 totalAmount = 0;
        uint256 index = 0;
        uint256 totalInterest = interests[msg.sender];

        while (index < userLocks.length) {
            Lock storage lock = userLocks[index];
            if (block.timestamp >= lock.end) {
                totalAmount += lock.amount;
                userLocks[index] = userLocks[userLocks.length - 1];
                userLocks.pop();
                uint256 interest = (block.timestamp.sub(lock.start)).mul(lock.amount).mul(lockRates[lock.month]).div(100).div(360).div(86400);
                if (interest > 0) {
                    totalInterest += interest;
                    lock.start = block.timestamp;
                    totalAmount += totalInterest;
                }
            } else {
                index++;
            }
        }

        require(totalAmount > 0, "No amount to withdraw.");

        esg.transfer(msg.sender, totalAmount);

        interests[msg.sender] = 0;
        total_deposited -= totalAmount;

        User storage user = referrerlist[msg.sender];

        if (user.referrer_addr != address(0)) {
            referrers[user.referrer_addr].totalInvestment -= totalAmount;

            if (referrers[user.referrer_addr].totalInvestment < dynamicRewardThreshold) {
                referrers[user.referrer_addr].dynamicReward = false;
            }
        }

        uint256 userAmount = 0;

        for (uint256 i = 0; i < userLocks.length; i++) {
            Lock storage lock = userLocks[i];
            userAmount += lock.amount;
        }

        if (userAmount < referralThreshold) {
            Referrer storage referrer = referrers[msg.sender];
            if(referrer.referrals.length > 0){
                for(uint256 i = 0; i < referrer.referrals.length; i++){
                    address invitee_add = referrer.referrals[i];
                    delete referrerlist[invitee_add];
                }
            }
            delete referrers[msg.sender].referrals;
        }

        emit EsgWithdraw(msg.sender, totalAmount); 
        return true;
    }

    function claim() public returns (bool) {
        require(allow_get_esg == true, "No claim allowed!");
        Lock[] storage userLocks = locks[msg.sender];
        require(userLocks.length > 0, "No locked amount.");

        uint256 totalInterest = interests[msg.sender];

        for (uint256 i = 0; i < userLocks.length; i++) {
            Lock storage lock = userLocks[i];
            uint256 interest = (block.timestamp.sub(lock.start)).mul(lock.amount).mul(lockRates[lock.month]).div(100).div(360).div(86400);
            if (interest > 0) {
                totalInterest += interest;
                lock.start = block.timestamp;
            }
        }

        require(totalInterest > 0, "No interest to claim.");

        interests[msg.sender] = 0;

        uint256 burnAmount = totalInterest.mul(burnPercentage).div(1000);
        esg.transfer(address(esg), burnAmount);
        totalInterest -= burnAmount;

        esg.transfer(msg.sender, totalInterest);

        Referrer storage referrer = referrers[msg.sender];
        User storage user = referrerlist[msg.sender];

        if (user.referrer_addr != address(0)) {
            uint256 dynamicRewardEvery = totalInterest.mul(dynamicRewardPercentageEvery).div(100);
            esg.transfer(user.referrer_addr, dynamicRewardEvery);
            if (referrers[user.referrer_addr].dynamicReward) {
                uint256 dynamicReward = totalInterest.mul(dynamicRewardPercentage).div(100);
                esg.transfer(user.referrer_addr, dynamicReward);
            }
        }

        emit EsgClaimed (msg.sender, totalInterest); 
        return true;
    }

    function calculateInterest(address _user) public view returns (uint256) {
        Lock[] storage userLocks = locks[_user];
        if (userLocks.length == 0) {
            return 0;
        }
        uint256 totalInterest = interests[_user];

        for (uint256 i = 0; i < userLocks.length; i++) {
            Lock storage lock = userLocks[i];
            uint256 interest = (block.timestamp.sub(lock.start)).mul(lock.amount).mul(lockRates[lock.month]).div(100).div(360).div(86400);
            if (interest > 0) {
                totalInterest += interest;
            }
        }

        return totalInterest;
    }

    function getLockInfo(address _user) public view returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        Lock[] storage userLocks = locks[_user];
                uint256 length = userLocks.length;

        uint256[] memory amounts = new uint256[](length);
        uint256[] memory starts = new uint256[](length);
        uint256[] memory ends = new uint256[](length);
        uint256[] memory rates = new uint256[](length);
        uint256[] memory interest = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            Lock storage lock = userLocks[i];
            amounts[i] = lock.amount;
            starts[i] = lock.start;
            ends[i] = lock.end;
            rates[i] = lockRates[lock.month];
            interest[i] = (block.timestamp.sub(lock.start)).mul(lock.amount).mul(lockRates[lock.month]).div(100).div(360).div(86400);
        }

        return (amounts, starts, ends, rates, interest);
    }

    function changeReferrerInfo(address referralAddress, address inviteeAddress, address newInviteeAddress) public onlyOwner returns (bool) {
        require(referralAddress != address(0), "referralAddress cannot be 0x0.");
        require(inviteeAddress != address(0), "inviteeAddress cannot be 0x0.");
        require(newInviteeAddress != address(0), "newInviteeAddress cannot be 0x0.");

        Referrer storage referrer = referrers[referralAddress];
        if(referrer.referrals.length > 0){
            for(uint256 i = 0; i < referrer.referrals.length; i++){
                address invitee_add = referrer.referrals[i];
                if(inviteeAddress == invitee_add){
                    referrer.referrals[i] = newInviteeAddress;
                    break;
                }
            }
        }

        delete referrerlist[inviteeAddress];
        User storage _user = referrerlist[newInviteeAddress];
        _user.referrer_addr = referralAddress;

        emit EsgChangeReferrerInfo(referralAddress, inviteeAddress, newInviteeAddress);
        return true;
    }

    function changeLockInfo(address _user, uint256 _amount, uint256 _start, uint256 _end, uint256 _month, uint256 i) public onlyOwner returns (bool) {
        require(_user != address(0), "_user cannot be 0x0.");
        Lock storage userLocks = locks[_user][i];
        userLocks.amount = _amount;
        userLocks.start = _start;
        userLocks.end = _end;
        userLocks.month = _month;

        emit EsgChangeLockInfo(_user, _amount, _start, _end, _month, i);
        return true;
    }

    function close() public onlyOwner {
        allow_get_esg = false;
    }

    function open() public onlyOwner {
        allow_get_esg = true;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }
}