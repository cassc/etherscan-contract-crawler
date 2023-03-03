// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "hardhat/console.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DataTypes} from "./libraries/DataTypes.sol";
import "./interfaces/ISERSHVestingEscrow.sol";
import "./interfaces/ISERSHVesting.sol";
import "./libraries/TokenHelper.sol";

contract SERSHVestingEscrow is ISERSHVestingEscrow, Ownable, ReentrancyGuard {
    // VestingEscrow vesting = new VestingEscrow(category, cliff, linear, amount, buyer, requestHash, receiver, timestamp);

    uint256 private _amount;
    DataTypes.VestingCategory private _category;
    // uint256 private _beginAt;
    address private _buyer;
    address private _buyer2;

    // uint private _cliff;
    // uint private _linear;
    DataTypes.VestingPlan private _vestingPlan;

    string private _requestHash;
    address private _receiver;
    address private _vestingToken;

    bool private _finished;
    uint64 private _unvestingStep;

    uint private _version;

    address private _vestingRoot;

    event Unvested(
        address indexed unlocker,
        uint256 indexed amount,
        uint256 indexed when
    );
    event FinishedAll(
        address indexed lastUnlocker,
        uint256 indexed lastAmount,
        uint256 indexed when
    );

    modifier onlyOwnerOrBuyer() {
        require(
            owner() == _msgSender() || _msgSender() == _buyer || (_buyer2 != address(0) && _msgSender() == _buyer2),
            "Only Owner or Buyer can call this function."
        );
        _;
    }

    modifier onlyBuyer() {
        require(_msgSender() == _buyer || (_buyer2 != address(0) && _msgSender() == _buyer2), "Only Buyer can call this function.");
        _;
    }

    modifier notFinished() {
        require(_finished == false, "Unvested all.");
        _;
    }

    constructor(
        DataTypes.VestingCategory category,
        DataTypes.VestingPlan memory plan,
        uint256 amount,
        address buyer,
        string memory requestHash,
        address receiver,
        address vestingToken,
        uint version,
        address root,
        address buyer2ForSeed
    ) {
        _version = version;
        _category = category;
        _vestingPlan = plan;
        _amount = amount;
        _buyer = buyer;
        _requestHash = requestHash;
        _receiver = receiver;
        _vestingToken = vestingToken;
        _vestingRoot = root;
        _buyer2 = buyer2ForSeed;
    }

    function getVersion() external view returns (uint) {
        return _version;
    }

    function getBuyer() external view returns (address) {
        return _buyer;
    }

    function isFinished() external view returns (bool) {
        return _finished;
    }

    function getBeginAt() public view returns (uint256 beginAt) {
        return ISERSHVesting(_vestingRoot).getTGETimestamp();
    }

    function getVestingToken() public view returns(address) {
        return _vestingToken;
    }

    function getUnvestingStep() public view returns (uint64) {
        return _unvestingStep;
    }

    function getVestingData()
        external
        view
        returns (
            uint256 amount,
            DataTypes.VestingCategory category,
            uint256 beginAt,
            address buyer,
            uint cliffMonths,
            uint linearMonths,
            uint256 tgeRate,
            uint256 cliffRate,
            uint256 vestingRate,
            string memory requestHash,
            address receiver,
            address buyer2
        )
    {
        amount = _amount;
        category = _category;

        beginAt = getBeginAt();

        buyer = _buyer;
        cliffMonths = _vestingPlan.cliffMonths;
        linearMonths = _vestingPlan.linearMonths;
        tgeRate = _vestingPlan.tgeRate;
        cliffRate = _vestingPlan.cliffRate;
        vestingRate = _vestingPlan.vestingRate;

        requestHash = _requestHash;
        receiver = _receiver;
        buyer2 = _buyer2;
    }

    function getReceiver() public view returns (address) {
        return _receiver;
    }

    function setReceiver(
        address receiver
    ) external onlyBuyer nonReentrant notFinished {
        require(receiver != address(0), "Invalid receiver");
        require(receiver != _receiver, "Already set");

        _receiver = receiver;
    }

    function getUnvestingRateArray() private view returns (uint256[] memory) {
        uint256 len = 2 + _vestingPlan.linearMonths;

        uint256[] memory plans = new uint256[](len);
        plans[0] = _vestingPlan.tgeRate;
        plans[1] = _vestingPlan.cliffRate;

        uint i = 2;
        for (i; i < len; i += 1) {
            plans[i] = _vestingPlan.vestingRate;
        }

        return plans;
    }

    function getUnvestingTimeArray() private view returns (uint256[] memory) {
        uint256 beginAt = getBeginAt();

        if (beginAt == 0) {
            return new uint256[](0);
        }

        uint256 len = 2 + _vestingPlan.linearMonths;

        uint256[] memory times = new uint256[](len);
        times[0] = beginAt + 4 weeks;
        times[1] = beginAt + _vestingPlan.cliffMonths * 4 weeks;

        uint i = 2;
        for (i; i < len; i += 1) {

            times[i] = times[i-1] + 4 weeks;
        }

        return times;
    }

    function getNextTimeForUnvesting(
        uint64 nextStep
    ) external view returns (uint256, uint64) {
        //* uint256 nextTime, uint64 expectedNextStep
        // todo unvesting steps = [0]: tge, [1]: cliff, [2,3,4,5,6] : (1,2,3,4,5,) -> linear months

        uint256 beginAt = getBeginAt();

        if (beginAt == 0) {
            return (0, 0); // Vesting is not began yet.
        }


        uint256[] memory plans = getUnvestingRateArray();
        uint256[] memory times = getUnvestingTimeArray();


        if(nextStep >= plans.length) {
            return (1,1); // over plans
        }

        uint64  i = nextStep + 1;

        uint256 nextTime = times[nextStep];
        uint64 expectedNextStep = 0;

        for (i; i<plans.length; i++) {
            if (plans[i] > 0) {
                // nextTime = times[i];
                expectedNextStep = i;
                break;
            }
        }

        // if ( expectedNextStep == 0) {
        //     // todo there is no unvesting step more.
        //     return (1,1);
        // }
        
        return (nextTime, expectedNextStep);

    }


    function calcDustAmount () public view returns (uint256) {
        uint256[] memory plans = getUnvestingRateArray();

         if ( plans.length < 2) {
            //! exceptional case
            return 0;
        }

        uint256 sum = plans[0] + plans[1];

        uint256 i=2;
        for (i; i<plans.length; i++) {
            sum += plans[i];
        }

        if (sum > 10000) {
            return 0;
        }

        uint256 dustRate = 10000 - sum;
        return _amount * dustRate / 10000;
    }

    function getUnvestingAmount(uint64 step) external view returns (uint256) {

        uint256[] memory plans = getUnvestingRateArray();

        if (step >= plans.length || step < 0) {
            //! exceptional case
            return 0;
        }

        uint256 rate = plans[step];

        uint256 amount = _amount * rate / 10000;

        if (step == plans.length - 1) {
            // todo: add dust amount ( remaining aomunt by round )

            uint256 dust = calcDustAmount();

            amount += dust;
        }

        return amount;

    }

    function canUnvesting() external view returns (bool, string memory) {
        if (_receiver == address(0)) {
            return (false, "Invalid receiver address.");
        }

        if (_finished == true) {
            return (false, 'Already unvested all.');
        }
        uint256 expectedTimeForUnVesting = 0;
         (expectedTimeForUnVesting, ) = this.getNextTimeForUnvesting(_unvestingStep);
        uint256 current = block.timestamp;

        if (
            expectedTimeForUnVesting <= 0 || expectedTimeForUnVesting > current
        ) {
            return (false, "It is not the time for unvesting.");
        }

        if (expectedTimeForUnVesting == 1) {
            return (false, "All unvesting is finished.");
        }

        uint256 unvestingAmount = this.getUnvestingAmount(_unvestingStep);

        if (unvestingAmount <= 0) {
            return (false, "Nothing to unvest more.");
        }

        if (IERC20(_vestingToken).balanceOf(address(this)) < unvestingAmount) {
            return (
                false,
                "Insufficient balance of vesting token. Ask support team to deposit more."
            );
        }

        return (true, "");
    }

    function unvesting() external onlyOwnerOrBuyer nonReentrant notFinished {
        // require(!_finished, 'All unvested.');
        console.log('_finsihed at unvesting: ', _finished);
        require(!_finished, 'All unvested.');
        require(_receiver != address(0), "Invalid receiver address.");
        uint256 expectedTimeForUnVesting = 0;
        uint64 newNextStep = 0 ;

        (expectedTimeForUnVesting, newNextStep) = this.getNextTimeForUnvesting(_unvestingStep);

        require(!(expectedTimeForUnVesting == 0 && newNextStep == 0), 'Vesting is not began.');
        require(!(expectedTimeForUnVesting == 1 && newNextStep == 1), 'No vesting step more.');
        
        uint256 current = block.timestamp;

        require(
            expectedTimeForUnVesting > 0 && expectedTimeForUnVesting <= current,
            "It is not the time for unvesting."
        );

        uint256 unvestingAmount = this.getUnvestingAmount(_unvestingStep);

        require(unvestingAmount > 0, "Nothing to unvest.");

        require(
            IERC20(_vestingToken).balanceOf(address(this)) >= unvestingAmount,
            "Insufficient balance of vesting token. Ask support team to deposit more."
        );

        TokenHelper.safeApprove(_vestingToken, address(this), unvestingAmount);

        TokenHelper.safeTransferFrom(
            _vestingToken,
            address(this),
            _receiver,
            unvestingAmount
        );

        uint64 oldstep = _unvestingStep;
        _unvestingStep = newNextStep;

        console.log('new unvesting step : ', _unvestingStep);

        if (_unvestingStep == 0) {
            
            _finished = true;
            console.log('Updated finished status:', _finished);
            ISERSHVesting(_vestingRoot).triggerUnvestedEvent(_requestHash, address(this), _receiver, unvestingAmount, current, 1, oldstep);
            emit FinishedAll(_msgSender(), unvestingAmount, current);
        } else {
            ISERSHVesting(_vestingRoot).triggerUnvestedEvent(_requestHash, address(this), _receiver, unvestingAmount, current, 0, oldstep);
            emit Unvested(_msgSender(), unvestingAmount, current);
        }
    }
}