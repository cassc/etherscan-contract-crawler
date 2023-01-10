// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract AvengersBMP is Initializable {
    using SafeMath for uint256;

    struct ROIDeposit {
        uint128 amount;
        uint64 startTime;
        uint8 plan;
    }
    struct TimePackDeposit {
        uint128 amount;
        uint64 startTime;
        uint8 plan;
        uint16 duration;
        bool withdrawn;
    }

    event NewBie(
        address indexed user,
        address indexed referrer,
        uint256 amount,
        uint8 plan
    );
    event Deposit(
        address indexed user,
        uint256 amount,
        uint8 plan,
        uint16 duration
    );
    event Withdraw(
        address indexed user,
        uint256 amount,
        uint8 plan,
        uint16 duration
    );

    address public ceoWallet;
    address public devWallet;
    address public adminWallet;
    address public insuranceWallet;
    address public marketingWallet;
    address public tradingWallet;
    address public communityWallet;
    address public owner;

    uint256 public constant DAY = 1 days;
    uint256 public constant BNB = 1 ether;
    uint256[4] public refPercents;

    mapping(address => ROIDeposit[]) public ROIDeposits;
    mapping(address => TimePackDeposit[]) public TimePackDeposits;
    mapping(address => uint256) public THORCheckpoints;
    mapping(address => uint256) public IRONMANCheckpoints;
    mapping(address => uint256) public CAPTAINCheckpoints;
    mapping(address => uint256) public HULKCheckpoints;
    mapping(address => uint256) public TimePackCheckpoints;
    mapping(address => address) public referrers;

    // constructor
    function initialize(
        address _devWallet,
        address _ceoWallet,
        address _marketingWallet,
        address _insuranceWallet,
        address _adminWallet,
        address _communityWallet,
        address _tradingWallet
    ) public initializer {
        ceoWallet = _ceoWallet;
        devWallet = _devWallet;
        adminWallet = _adminWallet;
        insuranceWallet = _insuranceWallet;
        marketingWallet = _marketingWallet;
        tradingWallet = _tradingWallet;
        communityWallet = _communityWallet;

        refPercents = [3, 1, 1, 1];

        owner = msg.sender;
        THORCheckpoints[msg.sender] = block.timestamp;
        ROIDeposits[msg.sender].push(
            ROIDeposit(uint128(0.1 ether), uint32(block.timestamp), 1)
        );
    }

    function depositROI(address _referrer, uint8 plan) external payable {
        require(plan >= 1 && plan <= 4, "invalid roi code");
        require(msg.value >= getMinDepositAmount(plan), "insufficient bnb");
        checkNewUserSender(_referrer, 1);

        ROIDeposits[msg.sender].push(
            ROIDeposit(uint128(msg.value), uint32(block.timestamp), plan)
        );

        payReferralSender();
        payOwners(msg.value);
        payable(tradingWallet).transfer(msg.value.mul(17).div(100));
        payable(communityWallet).transfer(msg.value.mul(5).div(1000));

        emit Deposit(msg.sender, msg.value, plan, 0);
    }

    function withdrawROI(uint8 plan) external {
        uint256 checkpoint = withdrawCheckpoint(msg.sender);
        require(checkpoint.add(DAY) < block.timestamp, "only once per day");
        require(ROIDeposits[msg.sender].length > 0, "No plan");

        uint256 dividends = getDividends(msg.sender, plan);
        updateSenderCheckpoint(plan);

        payOwners(dividends);
        payable(tradingWallet).transfer(
            dividends.mul(tradingTaxWithdraw(plan)).div(1000)
        );
        payable(msg.sender).transfer(
            dividends.mul(uint256(1000).sub(reinvestAmount(plan))).div(1000)
        );

        emit Withdraw(msg.sender, dividends, plan, 0);
    }

    function depositTimePack(
        address _referrer,
        uint8 _plan,
        uint16 _duration
    ) external payable {
        ensureTimePackParams(msg.value, _plan, _duration);
        checkNewUserSender(_referrer, 5);

        TimePackDeposits[msg.sender].push(
            TimePackDeposit(
                uint128(msg.value),
                uint64(block.timestamp),
                _plan,
                _duration,
                false
            )
        );

        payReferralSender();
        payOwners(msg.value);
        payable(tradingWallet).transfer(msg.value.mul(17).div(100));
        payable(communityWallet).transfer(msg.value.mul(5).div(1000));

        emit Deposit(msg.sender, msg.value, 5, _duration);
    }

    function withdrawTimePack(uint256 id) external {
        uint256 checkpoint = withdrawCheckpoint(msg.sender);
        require(checkpoint.add(DAY) < block.timestamp, "only once per day");
        require(
            TimePackDeposits[msg.sender].length > 0 &&
                id < TimePackDeposits[msg.sender].length &&
                !TimePackDeposits[msg.sender][id].withdrawn,
            "No plan"
        );

        TimePackDeposit storage deposit = TimePackDeposits[msg.sender][id];
        uint256 paid = ensureTimePackWithdraw(deposit);

        TimePackCheckpoints[msg.sender] = block.timestamp;
        deposit.withdrawn = true;

        payOwners(paid);
        payable(tradingWallet).transfer(
            paid.mul(tradingTaxWithdraw(deposit.plan)).div(1000)
        );
        payable(msg.sender).transfer(paid);

        emit Withdraw(msg.sender, paid, deposit.plan, deposit.duration);
    }

    function ensureTimePackWithdraw(
        TimePackDeposit storage deposit
    ) private view returns (uint256) {
        uint256 paid;
        if (deposit.plan == 5) {
            if (deposit.duration == 100) {
                require(
                    block.timestamp.sub(deposit.startTime) > 100 * DAY,
                    "Wait 100 days"
                );
                paid = uint256(deposit.amount).mul(2);
            } else if (deposit.duration == 150) {
                require(
                    block.timestamp.sub(deposit.startTime) > 150 * DAY,
                    "Wait 150 days"
                );
                paid = uint256(deposit.amount).mul(4);
            } else {
                require(
                    block.timestamp.sub(deposit.startTime) > 200 * DAY,
                    "Wait 200 days"
                );
                paid = uint256(deposit.amount).mul(7);
            }
        } else {
            if (deposit.duration == 200) {
                require(
                    block.timestamp.sub(deposit.startTime) > 200 * DAY,
                    "Wait 200 days"
                );
                paid = uint256(deposit.amount).mul(4);
            } else if (deposit.duration == 250) {
                require(
                    block.timestamp.sub(deposit.startTime) > 250 * DAY,
                    "Wait 250 days"
                );
                paid = uint256(deposit.amount).mul(5);
            } else {
                require(
                    block.timestamp.sub(deposit.startTime) > 400 * DAY,
                    "Wait 400 days"
                );
                paid = uint256(deposit.amount).mul(7);
            }
        }
        return paid;
    }

    function ensureTimePackParams(
        uint256 _amount,
        uint8 _plan,
        uint16 _duration
    ) private pure {
        require(_plan == 5 || _plan == 6, "invalid timepack code");

        if (_plan == 5) {
            require(_amount >= BNB.div(2), "insufficient amount for hawkeye");
            require(
                _duration == 100 || _duration == 150 || _duration == 200,
                "invalid hawkeye duration"
            );
        }
        if (_plan == 6) {
            require(
                _amount >= BNB.mul(5),
                "insufficient amount for blackwidow"
            );

            require(
                _duration == 200 || _duration == 250 || _duration == 400,
                "invalid blackwidow duration"
            );
        }
    }

    function checkNewUserSender(address _referrer, uint8 plan) private {
        if (msg.sender == owner) return;
        if (referrers[msg.sender] == address(0)) {
            require(isActive(_referrer), "invalid referrer");
            referrers[msg.sender] = _referrer;
            updateSenderCheckpoint(plan);
            emit NewBie(msg.sender, _referrer, msg.value, plan);
        }
    }

    function updateSenderCheckpoint(uint8 plan) private {
        if (plan == 1) THORCheckpoints[msg.sender] = block.timestamp;
        else if (plan == 2) IRONMANCheckpoints[msg.sender] = block.timestamp;
        else if (plan == 3) CAPTAINCheckpoints[msg.sender] = block.timestamp;
        else if (plan == 4) HULKCheckpoints[msg.sender] = block.timestamp;
        else TimePackCheckpoints[msg.sender] = block.timestamp;
    }

    function payOwners(uint256 _amount) private {
        payable(ceoWallet).transfer(_amount.mul(25).div(1000));
        payable(devWallet).transfer(_amount.mul(25).div(1000));
        payable(adminWallet).transfer(_amount.mul(25).div(1000));
        payable(insuranceWallet).transfer(_amount.mul(25).div(1000));
        payable(marketingWallet).transfer(_amount.mul(25).div(1000));
    }

    function payReferralSender() private {
        address upline = referrers[msg.sender];
        for (uint256 i = 0; i < refPercents.length; i++) {
            if (upline != address(0)) {
                payable(upline).transfer(
                    refPercents[i].mul(msg.value).div(100)
                );
                upline = referrers[upline];
            } else break;
        }
    }

    function getMinDepositAmount(uint8 plan) public pure returns (uint256) {
        if (plan == 1) return BNB.div(10);
        if (plan == 2) return BNB.div(2);
        if (plan == 3) return BNB;
        if (plan == 4) return BNB.mul(3);
        if (plan == 5) return BNB.div(2);
        if (plan == 6) return BNB.mul(5);
        return 0;
    }

    function tradingTaxWithdraw(uint8 _plan) public pure returns (uint) {
        if (_plan == 1) return 100;
        if (_plan == 2) return 150;
        if (_plan == 3) return 250;
        if (_plan == 4) return 250;
        if (_plan == 5) return 125;
        if (_plan == 6) return 125;
        return 0;
    }

    function reinvestAmount(uint8 _plan) public pure returns (uint) {
        if (_plan == 1) return 100;
        if (_plan == 2) return 150;
        if (_plan == 3) return 400;
        if (_plan == 4) return 500;
        return 0;
    }

    function getDividends(
        address _user,
        uint8 plan
    ) public view returns (uint256) {
        uint256 total;
        uint256 planLength;
        uint256 checkpoint;
        uint256 rate = 5;
        if (plan == 1) {
            planLength = 2 ** 200; //infinit
            checkpoint = THORCheckpoints[_user];
            rate = 5;
        } else if (plan == 2) {
            planLength = 236 * DAY;
            checkpoint = IRONMANCheckpoints[_user];
            rate = 13;
        } else if (plan == 3) {
            planLength = 125 * DAY;
            checkpoint = CAPTAINCheckpoints[_user];
            rate = 24;
        } else if (plan == 4) {
            planLength = 54 * DAY;
            checkpoint = HULKCheckpoints[_user];
            rate = 50;
        }
        ROIDeposit[] memory deposits = ROIDeposits[_user];
        for (uint i = 0; i < deposits.length; i++) {
            ROIDeposit memory dep = deposits[i];
            if (dep.plan != plan) continue;
            uint256 endTime = uint256(dep.startTime).add(planLength);
            checkpoint = checkpoint < dep.startTime
                ? dep.startTime
                : checkpoint;
            if (endTime <= checkpoint) continue;
            endTime = endTime < block.timestamp ? endTime : block.timestamp;
            uint256 dividend = endTime.sub(checkpoint).mul(dep.amount);

            total = total.add(dividend);
        }
        return total.mul(rate).div(1000).div(DAY);
    }

    function isActive(address _user) public view returns (bool) {
        return
            ROIDeposits[_user].length > 0 || TimePackDeposits[_user].length > 0;
    }

    function withdrawCheckpoint(
        address _address
    ) public view returns (uint256) {
        uint256 checkpoint = THORCheckpoints[_address];
        if (IRONMANCheckpoints[_address] > checkpoint)
            checkpoint = IRONMANCheckpoints[_address];
        if (CAPTAINCheckpoints[_address] > checkpoint)
            checkpoint = CAPTAINCheckpoints[_address];
        if (HULKCheckpoints[_address] > checkpoint)
            checkpoint = HULKCheckpoints[_address];
        if (TimePackCheckpoints[_address] > checkpoint)
            checkpoint = TimePackCheckpoints[_address];

        return checkpoint;
    }

    function getROIDeposits(
        address _adr
    ) public view returns (ROIDeposit[] memory) {
        return ROIDeposits[_adr];
    }

    function getTimePacks(
        address _adr
    ) public view returns (TimePackDeposit[] memory) {
        return TimePackDeposits[_adr];
    }

    receive() external payable {}
}

library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}