// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;
import "../contracts/LockableToken.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FLyToken is LockableToken, Ownable {

    /**
     * @dev Indicates that the contract has been initialized with locked tokens for round 1.
     */
    bool private _initializedRound1;

    /**
     * @dev Indicates that the contract is in the process of being initialized for round 1.
     */
    bool private _initializingRound1;

    /**
     * @dev Indicates that the contract has been initialized with locked tokens for round 2.
     */
    bool private _initializedRound2;

    /**
     * @dev Indicates that the contract is in the process of being initialized for round 2.
     */
    bool private _initializingRound2;

    constructor() public LockableToken(17011706000000, "Franklin", "FLy", 4) {
    }

    function initializeRound1() public initializerR1 onlyOwner  {
        _initRound1();
    }

    function initializeRound2() public initializerR2 onlyOwner  {
        _initRound2();
    }

    function _initRound1() internal   {
        uint256 vestingRound1Seconds = 1617235200 - now;
        uint256 vrAmount = 63964014560;
        uint256 days30 = 2592000;
        //round 1
        _lock('v1_1', vrAmount, vestingRound1Seconds);
        _lock('v1_2', vrAmount, vestingRound1Seconds.add(days30));
        _lock('v1_3', vrAmount, vestingRound1Seconds.add(days30.mul(2)));
        _lock('v1_4', vrAmount, vestingRound1Seconds.add(days30.mul(3)));
        _lock('v1_5', vrAmount, vestingRound1Seconds.add(days30.mul(4)));
        _lock('v1_6', vrAmount, vestingRound1Seconds.add(days30.mul(5)));
        _lock('v1_7', vrAmount, vestingRound1Seconds.add(days30.mul(6)));
        _lock('v1_8', vrAmount, vestingRound1Seconds.add(days30.mul(7)));
        _lock('v1_9', vrAmount, vestingRound1Seconds.add(days30.mul(8)));
        _lock('v1_10', vrAmount, vestingRound1Seconds.add(days30.mul(9)));
        _lock('v1_11', vrAmount, vestingRound1Seconds.add(days30.mul(10)));
        _lock('v1_12', vrAmount, vestingRound1Seconds.add(days30.mul(11)));
        _lock('v1_13', vrAmount, vestingRound1Seconds.add(days30.mul(12)));
        _lock('v1_14', vrAmount, vestingRound1Seconds.add(days30.mul(13)));
        _lock('v1_15', vrAmount, vestingRound1Seconds.add(days30.mul(14)));
        _lock('v1_16', vrAmount, vestingRound1Seconds.add(days30.mul(15)));
        _lock('v1_17', vrAmount, vestingRound1Seconds.add(days30.mul(16)));
        _lock('v1_18', vrAmount, vestingRound1Seconds.add(days30.mul(17)));
        _lock('v1_19', vrAmount, vestingRound1Seconds.add(days30.mul(18)));
        _lock('v1_20', vrAmount, vestingRound1Seconds.add(days30.mul(19)));
        _lock('v1_21', vrAmount, vestingRound1Seconds.add(days30.mul(20)));
        _lock('v1_22', vrAmount, vestingRound1Seconds.add(days30.mul(21)));
        _lock('v1_23', vrAmount, vestingRound1Seconds.add(days30.mul(22)));
        _lock('v1_24', vrAmount, vestingRound1Seconds.add(days30.mul(23)));
        _lock('v1_25', vrAmount, vestingRound1Seconds.add(days30.mul(24)));
        _lock('v1_26', vrAmount, vestingRound1Seconds.add(days30.mul(25)));
        _lock('v1_27', vrAmount, vestingRound1Seconds.add(days30.mul(26)));
        _lock('v1_28', vrAmount, vestingRound1Seconds.add(days30.mul(27)));
        _lock('v1_29', vrAmount, vestingRound1Seconds.add(days30.mul(28)));
        _lock('v1_30', vrAmount, vestingRound1Seconds.add(days30.mul(29)));
        _lock('v1_31', vrAmount, vestingRound1Seconds.add(days30.mul(30)));
        _lock('v1_32', vrAmount, vestingRound1Seconds.add(days30.mul(31)));
        _lock('v1_33', vrAmount, vestingRound1Seconds.add(days30.mul(32)));
        _lock('v1_34', vrAmount, vestingRound1Seconds.add(days30.mul(33)));
        _lock('v1_35', vrAmount, vestingRound1Seconds.add(days30.mul(34)));
        _lock('v1_36', vrAmount, vestingRound1Seconds.add(days30.mul(35)));
        _lock('v1_37', vrAmount, vestingRound1Seconds.add(days30.mul(36)));
        _lock('v1_38', vrAmount, vestingRound1Seconds.add(days30.mul(37)));
        _lock('v1_39', vrAmount, vestingRound1Seconds.add(days30.mul(38)));
        _lock('v1_40', vrAmount, vestingRound1Seconds.add(days30.mul(39)));
        _lock('v1_41', vrAmount, vestingRound1Seconds.add(days30.mul(40)));
        _lock('v1_42', vrAmount, vestingRound1Seconds.add(days30.mul(41)));
        _lock('v1_43', vrAmount, vestingRound1Seconds.add(days30.mul(42)));
        _lock('v1_44', vrAmount, vestingRound1Seconds.add(days30.mul(43)));
        _lock('v1_45', vrAmount, vestingRound1Seconds.add(days30.mul(44)));
        _lock('v1_46', vrAmount, vestingRound1Seconds.add(days30.mul(45)));
        _lock('v1_47', vrAmount, vestingRound1Seconds.add(days30.mul(46)));
        _lock('v1_48', vrAmount, vestingRound1Seconds.add(days30.mul(47)));
        _lock('v1_49', vrAmount, vestingRound1Seconds.add(days30.mul(48)));
        _lock('v1_50', vrAmount, vestingRound1Seconds.add(days30.mul(49)));
        //round 1: transfer locked total 
        transfer(address(this), 3198200728000);
    }

    function _initRound2() internal   {
        uint256 vestingRound2Seconds = 1625097600 - now;
        uint256 days30 = 2592000;
        // round 2 - starting from 01.07.2021 - autogenerated from excel output
        _lock('v2_1', 29770485500, vestingRound2Seconds);
        _lock('v2_2', 30365895210, vestingRound2Seconds.add(days30));
        _lock('v2_3', 30978316626, vestingRound2Seconds.add(days30.mul(2)));
        _lock('v2_4', 31590738042, vestingRound2Seconds.add(days30.mul(3)));
        _lock('v2_5', 32220171164, vestingRound2Seconds.add(days30.mul(4)));
        _lock('v2_6', 32866615992, vestingRound2Seconds.add(days30.mul(5)));
        _lock('v2_7', 33530072526, vestingRound2Seconds.add(days30.mul(6)));
        _lock('v2_8', 34193529060, vestingRound2Seconds.add(days30.mul(7)));
        _lock('v2_9', 34873997300, vestingRound2Seconds.add(days30.mul(8)));
        _lock('v2_10', 35571477246, vestingRound2Seconds.add(days30.mul(9)));
        _lock('v2_11', 36285968898, vestingRound2Seconds.add(days30.mul(10)));
        _lock('v2_12', 37017472256, vestingRound2Seconds.add(days30.mul(11)));
        _lock('v2_13', 37748975614, vestingRound2Seconds.add(days30.mul(12)));
        _lock('v2_14', 38514502384, vestingRound2Seconds.add(days30.mul(13)));
        _lock('v2_15', 39280029154, vestingRound2Seconds.add(days30.mul(14)));
        _lock('v2_16', 40062567630, vestingRound2Seconds.add(days30.mul(15)));
        _lock('v2_17', 40862117812, vestingRound2Seconds.add(days30.mul(16)));
        _lock('v2_18', 41678679700, vestingRound2Seconds.add(days30.mul(17)));
        _lock('v2_19', 42512253294, vestingRound2Seconds.add(days30.mul(18)));
        _lock('v2_20', 43362838594, vestingRound2Seconds.add(days30.mul(19)));
        _lock('v2_21', 44230435600, vestingRound2Seconds.add(days30.mul(20)));
        _lock('v2_22', 45115044312, vestingRound2Seconds.add(days30.mul(21)));
        _lock('v2_23', 46016664730, vestingRound2Seconds.add(days30.mul(22)));
        _lock('v2_24', 46952308560, vestingRound2Seconds.add(days30.mul(23)));
        _lock('v2_25', 47887952390, vestingRound2Seconds.add(days30.mul(24)));
        _lock('v2_26', 48840607926, vestingRound2Seconds.add(days30.mul(25)));
        _lock('v2_27', 49810275168, vestingRound2Seconds.add(days30.mul(26)));
        _lock('v2_28', 50813965822, vestingRound2Seconds.add(days30.mul(27)));
        _lock('v2_29', 51834668182, vestingRound2Seconds.add(days30.mul(28)));
        _lock('v2_30', 52872382248, vestingRound2Seconds.add(days30.mul(29)));
        _lock('v2_31', 53927108020, vestingRound2Seconds.add(days30.mul(30)));
        _lock('v2_32', 54998845498, vestingRound2Seconds.add(days30.mul(31)));
        _lock('v2_33', 56104606388, vestingRound2Seconds.add(days30.mul(32)));
        _lock('v2_34', 57227378984, vestingRound2Seconds.add(days30.mul(33)));
        _lock('v2_35', 58367163286, vestingRound2Seconds.add(days30.mul(34)));
        _lock('v2_36', 59540971000, vestingRound2Seconds.add(days30.mul(35)));
        _lock('v2_37', 60731790420, vestingRound2Seconds.add(days30.mul(36)));
        _lock('v2_38', 61939621546, vestingRound2Seconds.add(days30.mul(37)));
        _lock('v2_39', 63181476084, vestingRound2Seconds.add(days30.mul(38)));
        _lock('v2_40', 64440342328, vestingRound2Seconds.add(days30.mul(39)));
        _lock('v2_41', 65733231984, vestingRound2Seconds.add(days30.mul(40)));
        _lock('v2_42', 67043133346, vestingRound2Seconds.add(days30.mul(41)));
        _lock('v2_43', 68387058120, vestingRound2Seconds.add(days30.mul(42)));
        _lock('v2_44', 69765006306, vestingRound2Seconds.add(days30.mul(43)));
        _lock('v2_45', 71159966198, vestingRound2Seconds.add(days30.mul(44)));
        _lock('v2_46', 72571937796, vestingRound2Seconds.add(days30.mul(45)));
        _lock('v2_47', 74034944512, vestingRound2Seconds.add(days30.mul(46)));
        _lock('v2_48', 94823249244, vestingRound2Seconds.add(days30.mul(47)));
        //round 2: transfer locked total 
        transfer(address(this), 2381638840000);
    }

    function _lock(
        bytes32 _reason,
        uint256 _amount,
        uint256 _time
    ) internal returns (bool) {
        uint256 validUntil = now.add(_time); //solhint-disable-line
        if (locked[_msgSender()][_reason].amount == 0)
            lockReason[_msgSender()].push(_reason);
        locked[_msgSender()][_reason] = lockToken(_amount, validUntil, false);
        return true;
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        unlock(from);
    }

    /**
    * @dev Modifier to protect an initializer function from being invoked twice.
    */
    modifier initializerR1() {
        require(_initializingRound1 || !_initializedRound1, "InitializerR1: contract is already initialized");

        bool isTopLevelCall = !_initializingRound1;
        if (isTopLevelCall) {
            _initializingRound1 = true;
            _initializedRound1 = true;
        }

        _;

        if (isTopLevelCall) {
            _initializingRound1 = false;
        }
    }

    /**
    * @dev Modifier to protect an initializer function from being invoked twice.
    */
    modifier initializerR2() {
        require(_initializingRound2 || !_initializedRound2, "InitializerR2: contract is already initialized");

        bool isTopLevelCall = !_initializingRound2;
        if (isTopLevelCall) {
            _initializingRound2 = true;
            _initializedRound2 = true;
        }

        _;

        if (isTopLevelCall) {
            _initializingRound2 = false;
        }
    }
}