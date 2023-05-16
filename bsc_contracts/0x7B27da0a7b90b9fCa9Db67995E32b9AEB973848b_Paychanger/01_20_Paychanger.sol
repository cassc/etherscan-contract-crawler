//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

library Zero {
  function requireNotZero(uint256 a) internal pure {
    require(a != 0, "require not zero");
  }

  function requireNotZero(address addr) internal pure {
    require(addr != address(0), "require not zero address");
  }

  function notZero(address addr) internal pure returns(bool) {
    return !(addr == address(0));
  }

  function isZero(address addr) internal pure returns(bool) {
    return addr == address(0);
  }
}

library Percent {
  // Solidity automatically throws when dividing by 0
  struct percent {
    uint256 num;
    uint256 den;
  }
  function mul(percent storage p, uint256 a) internal view returns (uint) {
    if (a == 0) {
      return 0;
    }
    return a*p.num/p.den;
  }

  function div(percent storage p, uint256 a) internal view returns (uint) {
    return a/p.num*p.den;
  }

  function sub(percent storage p, uint256 a) internal view returns (uint) {
    uint256 b = mul(p, a);
    if (b >= a) return 0;
    return a - b;
  }

  function add(percent storage p, uint256 a) internal view returns (uint) {
    return a + mul(p, a);
  }
}

contract TokenVesting is Ownable, ReentrancyGuard{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    struct VestingSchedule{
        bool initialized;
        // beneficiary of tokens after they are released
        address  beneficiary;
        // cliff period in seconds
        uint256  cliff;
        // start time of the vesting period
        uint256  start;
        // duration of the vesting period in seconds
        uint256  duration;
        // duration of a slice period for the vesting in seconds
        uint256 slicePeriodSeconds;
        // whether or not the vesting is revocable
        bool  revocable;
        // total amount of tokens to be released at the end of the vesting
        uint256 amountTotal;
        // amount of tokens released
        uint256  released;
        // whether or not the vesting has been revoked
        bool revoked;
    }

    // address of the ERC20 token
    IERC20 immutable private _token;

    bytes32[] private vestingSchedulesIds;
    mapping(bytes32 => VestingSchedule) private vestingSchedules;
    uint256 private vestingSchedulesTotalAmount;
    mapping(address => uint256) private holdersVestingCount;
    mapping(address => uint256) internal holdersVestingTokens;

    event Released(uint256 amount);
    event Revoked();

    /**
    * @dev Reverts if no vesting schedule matches the passed identifier.
    */
    modifier onlyIfVestingScheduleExists(bytes32 vestingScheduleId) {
        require(vestingSchedules[vestingScheduleId].initialized == true);
        _;
    }

    /**
    * @dev Reverts if the vesting schedule does not exist or has been revoked.
    */
    modifier onlyIfVestingScheduleNotRevoked(bytes32 vestingScheduleId) {
        require(vestingSchedules[vestingScheduleId].initialized == true);
        require(vestingSchedules[vestingScheduleId].revoked == false);
        _;
    }

    /**
     * @dev Creates a vesting contract.
     * @param token address of the ERC20 token contract
     */
    constructor(IERC20 token) {
        _token = token;
    }

    receive() external payable {}

    fallback() external payable {}

    /**
    * @dev Returns the number of vesting schedules associated to a beneficiary.
    * @return the number of vesting schedules
    */
    function getVestingSchedulesCountByBeneficiary(address _beneficiary)
    external
    view
    returns(uint256){
        return holdersVestingCount[_beneficiary];
    }

    /**
    * @dev Returns the vesting schedule id at the given index.
    * @return the vesting id
    */
    function getVestingIdAtIndex(uint256 index)
    external
    view
    returns(bytes32){
        require(index < getVestingSchedulesCount(), "TokenVesting: index out of bounds");
        return vestingSchedulesIds[index];
    }

    /**
    * @notice Returns the vesting schedule information for a given holder and index.
    * @return the vesting schedule structure information
    */
    function getVestingScheduleByAddressAndIndex(address holder, uint256 index)
    external
    view
    returns(VestingSchedule memory){
        return getVestingSchedule(computeVestingScheduleIdForAddressAndIndex(holder, index));
    }


    /**
    * @notice Returns the total amount of vesting schedules.
    * @return the total amount of vesting schedules
    */
    function getVestingSchedulesTotalAmount()
    public 
    view
    returns(uint256){
        return vestingSchedulesTotalAmount;
    }

    /**
    * @dev Returns the address of the ERC20 token managed by the vesting contract.
    */
    function getToken()
    external
    view
    returns(address){
        return address(_token);
    }

    /**
    * @notice Creates a new vesting schedule for a beneficiary.
    * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
    * @param _start start time of the vesting period
    * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
    * @param _duration duration in seconds of the period in which the tokens will vest
    * @param _slicePeriodSeconds duration of a slice period for the vesting in seconds
    * @param _revocable whether the vesting is revocable or not
    * @param _amount total amount of tokens to be released at the end of the vesting
    */
    function createVestingSchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        bool _revocable,
        uint256 _amount
    )
        public
        onlyOwner returns(bytes32) {

        require(_duration > 0, "TokenVesting: duration must be > 0");
        require(_amount > 0, "TokenVesting: amount must be > 0");
        require(_slicePeriodSeconds >= 1, "TokenVesting: slicePeriodSeconds must be >= 1");
        bytes32 vestingScheduleId = this.computeNextVestingScheduleIdForHolder(_beneficiary);
        uint256 cliff = _start.add(_cliff);
        vestingSchedules[vestingScheduleId] = VestingSchedule(
            true,
            _beneficiary,
            cliff,
            _start,
            _duration,
            _slicePeriodSeconds,
            _revocable,
            _amount,
            0,
            false
        );
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.add(_amount);
        vestingSchedulesIds.push(vestingScheduleId);
        uint256 currentVestingCount = holdersVestingCount[_beneficiary];
        holdersVestingCount[_beneficiary] = currentVestingCount.add(1);
        holdersVestingTokens[_beneficiary] += _amount;
        return vestingScheduleId;
    }

    /**
    * @notice Revokes the vesting schedule for given identifier.
    * @param vestingScheduleId the vesting schedule identifier
    */
    function revoke(bytes32 vestingScheduleId)
        public
        onlyOwner
        onlyIfVestingScheduleNotRevoked(vestingScheduleId){
        VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
        require(vestingSchedule.revocable == true, "TokenVesting: vesting is not revocable");
        /*uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        if(vestedAmount > 0){
            release(vestingScheduleId, vestedAmount);
        }*/
        uint256 unreleased = vestingSchedule.amountTotal.sub(vestingSchedule.released);
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.sub(unreleased);
        holdersVestingTokens[vestingSchedule.beneficiary] -= unreleased;
        vestingSchedule.revoked = true;
    }

    /**
    * @notice Release vested amount of tokens.
    * @param vestingScheduleId the vesting schedule identifier
    * @param amount the amount to release
    */
    function release(
        bytes32 vestingScheduleId,
        address beneficiary,
        uint256 amount
    )
        public
        nonReentrant
        onlyIfVestingScheduleNotRevoked(vestingScheduleId){
        VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
        bool isBeneficiary = beneficiary == vestingSchedule.beneficiary;
        bool isOwner = beneficiary == owner();
        require(
            isBeneficiary || isOwner,
            "TokenVesting: only beneficiary and owner can release vested tokens"
        );
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        require(vestedAmount >= amount, "TokenVesting: cannot release tokens, not enough vested tokens");
        vestingSchedule.released = vestingSchedule.released.add(amount);
        //address payable beneficiaryPayable = payable(vestingSchedule.beneficiary);
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.sub(amount);
        //_token.safeTransfer(beneficiaryPayable, amount);
        //return amount;
    }

    function getReleasedAmountByScheduleId(bytes32 vestingScheduleId)
        public view returns (uint256) {
        VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];

        return vestingSchedule.released;
    }

    /**
    * @dev Returns the number of vesting schedules managed by this contract.
    * @return the number of vesting schedules
    */
    function getVestingSchedulesCount()
        public
        view
        returns(uint256){
        return vestingSchedulesIds.length;
    }

    /**
    * @notice Computes the vested amount of tokens for the given vesting schedule identifier.
    * @return the vested amount
    */
    function computeReleasableAmount(bytes32 vestingScheduleId)
        public
        onlyIfVestingScheduleNotRevoked(vestingScheduleId)
        view
        returns(uint256){
        VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
        return _computeReleasableAmount(vestingSchedule);
    }

    /**
    * @notice Returns the vesting schedule information for a given identifier.
    * @return the vesting schedule structure information
    */
    function getVestingSchedule(bytes32 vestingScheduleId)
        public
        view
        returns(VestingSchedule memory){
        return vestingSchedules[vestingScheduleId];
    }

    /**
    * @dev Computes the next vesting schedule identifier for a given holder address.
    */
    function computeNextVestingScheduleIdForHolder(address holder)
        public
        view
        returns(bytes32){
        return computeVestingScheduleIdForAddressAndIndex(holder, holdersVestingCount[holder]);
    }

    /**
    * @dev Returns the last vesting schedule for a given holder address.
    */
    function getLastVestingScheduleForHolder(address holder)
        public
        view
        returns(VestingSchedule memory){
        return vestingSchedules[computeVestingScheduleIdForAddressAndIndex(holder, holdersVestingCount[holder] - 1)];
    }

    /**
    * @dev Computes the vesting schedule identifier for an address and an index.
    */
    function computeVestingScheduleIdForAddressAndIndex(address holder, uint256 index)
        public
        pure
        returns(bytes32){
        return keccak256(abi.encodePacked(holder, index));
    }

    /**
    * @dev Computes the releasable amount of tokens for a vesting schedule.
    * @return the amount of releasable tokens
    */
    function _computeReleasableAmount(VestingSchedule memory vestingSchedule)
    internal
    view
    returns(uint256){
        uint256 currentTime = getCurrentTime();
        if ((currentTime < vestingSchedule.cliff) || vestingSchedule.revoked == true) {
            return 0;
        } else if (currentTime >= vestingSchedule.start.add(vestingSchedule.duration)) {
            return vestingSchedule.amountTotal.sub(vestingSchedule.released);
        } else {
            uint256 timeFromStart = currentTime.sub(vestingSchedule.start);
            uint256 secondsPerSlice = vestingSchedule.slicePeriodSeconds;
            uint256 vestedSlicePeriods = timeFromStart.div(secondsPerSlice);
            uint256 vestedSeconds = vestedSlicePeriods.mul(secondsPerSlice);
            uint256 vestedAmount = vestingSchedule.amountTotal.mul(vestedSeconds).div(vestingSchedule.duration);
            vestedAmount = vestedAmount.sub(vestingSchedule.released);
            return vestedAmount;
        }
    }

    function getCurrentTime()
        internal
        virtual
        view
        returns(uint256){
        return block.timestamp;
    }

    function getVestingAmountByAddress(address holder) public view returns(uint256) {
        return holdersVestingTokens[holder];
    }

}

contract UsersStorage is Ownable {

  struct userSubscription {
    uint256 value;
    uint256 valueUsd;
    uint256 releasedUsd;
    uint256 startFrom;
    uint256 endDate;
    uint256 takenFromPool;
    uint256 takenFromPoolUsd;
    bytes32 vestingId;
    bool active;
    bool haveVesting;
    bool vestingPaid;
  }

  struct user {
    uint256 keyIndex;
    uint256 bonusUsd;
    uint256 refBonus;
    uint256 turnoverToken;
    uint256 turnoverUsd;
    uint256 refFirst;
    uint256 careerPercent;
    userSubscription[] subscriptions;
  }

  struct itmap {
    mapping(address => user) data;
    address[] keys;
  }
  
  itmap internal s;

  bool public stopMintBonusUsd;

  constructor(address wallet) {
    insertUser(wallet);
    s.data[wallet].bonusUsd += 1000000;
  }

  function insertUser(address addr) public onlyOwner returns (bool) {
    uint256 keyIndex = s.data[addr].keyIndex;
    if (keyIndex != 0) return false;

    uint256 keysLength = s.keys.length;
    keyIndex = keysLength+1;
    
    s.data[addr].keyIndex = keyIndex;
    s.keys.push(addr);
    return true;
  }

  function insertSubscription(bytes32 vestingId, address addr, uint256 value, uint256 valueUsd) public onlyOwner returns (bool) {
    if (s.data[addr].keyIndex == 0) return false;

    s.data[addr].subscriptions.push(
      userSubscription(value, valueUsd, 0, block.timestamp, 0, 0, 0, vestingId, true, vestingId != bytes32(0) ? true : false, false)
    );

    return true;
  }

  function setNotActiveSubscription(address addr, uint256 index) public onlyOwner returns (bool) {
      s.data[addr].subscriptions[index].endDate = block.timestamp;
      s.data[addr].subscriptions[index].active = false;

      return true;
  }

  function setCareerPercent(address addr, uint256 careerPercent) public onlyOwner {
    s.data[addr].careerPercent = careerPercent;
  }

  function setBonusUsd(address addr, uint256 bonusUsd, bool increment) public onlyOwner returns (bool) {
    if (s.data[addr].keyIndex == 0) return false;

    address systemAddress = s.keys[0];

    if (increment) {
        if (s.data[systemAddress].bonusUsd < bonusUsd && !stopMintBonusUsd) {
            s.data[systemAddress].bonusUsd += 1000000;
        }
        
        if (s.data[systemAddress].bonusUsd >= bonusUsd) {
            s.data[systemAddress].bonusUsd -= bonusUsd;
            s.data[addr].bonusUsd += bonusUsd;
        }
        
    } else {
        s.data[systemAddress].bonusUsd += bonusUsd;
        s.data[addr].bonusUsd -= bonusUsd;
    }
    return true;
  }

  function setTakenFromPool(address addr, uint256 index, uint256 value, uint256 valueUsd) public onlyOwner returns (bool) {
    if (s.data[addr].keyIndex == 0) return false;
    s.data[addr].subscriptions[index].takenFromPool += value;
    s.data[addr].subscriptions[index].takenFromPoolUsd += valueUsd;
    return true;
  }

  function addTurnover(address addr, uint256 turnoverUsd) public onlyOwner {
    s.data[addr].turnoverUsd += turnoverUsd; 
  }
  
  function addRefBonus(address addr, uint256 refBonus, uint256 level) public onlyOwner returns (bool) {
    if (s.data[addr].keyIndex == 0) return false;
    s.data[addr].refBonus += refBonus;

    if (level == 1) {
     s.data[addr].refFirst += refBonus;
    }  
    return true;
  }

  function setStopMintBonusUsd() public onlyOwner {
    stopMintBonusUsd = !stopMintBonusUsd;
  }

  function setSubscriptionReleasedUsd(address addr, uint256 index, uint256 releasedUsd) public onlyOwner returns(bool) {
    s.data[addr].subscriptions[index].releasedUsd += releasedUsd;
    return true;
  }

  function userTurnover(address addr) public view returns(uint, uint, uint) {
    return (
        s.data[addr].turnoverToken,
        s.data[addr].turnoverUsd,
        s.data[addr].careerPercent
    );
  }

  function userReferralBonuses(address addr) public view returns(uint, uint) {
    return (
        s.data[addr].refFirst,
        s.data[addr].refBonus
    );
  }

  function userSingleSubscriptionActive(address addr, uint256 index) public view returns(bytes32, uint256, bool, bool, bool) {
     return (
      s.data[addr].subscriptions[index].vestingId,
      s.data[addr].subscriptions[index].valueUsd,
      s.data[addr].subscriptions[index].active,
      s.data[addr].subscriptions[index].vestingPaid,
      s.data[addr].subscriptions[index].haveVesting
    );   
  }

  function userSubscriptionReleasedUsd(address addr, uint256 index) public view returns(uint256, uint256) {
    return (
        s.data[addr].subscriptions[index].releasedUsd,
        s.data[addr].subscriptions[index].takenFromPoolUsd
    );
  }

  function userSingleSubscriptionStruct(address addr, uint256 index) public view returns(userSubscription memory) {
     return (
      s.data[addr].subscriptions[index]
    );   
  }

  function userSingleSubscriptionPool(address addr, uint256 index) public view returns(uint, uint, uint, uint, uint, bool) {
    return (
      s.data[addr].subscriptions[index].valueUsd,
      s.data[addr].subscriptions[index].startFrom,
      s.data[addr].subscriptions[index].endDate,
      s.data[addr].subscriptions[index].takenFromPool,
      s.data[addr].subscriptions[index].takenFromPoolUsd,
      s.data[addr].subscriptions[index].active
    );
  }

  function contains(address addr) public view returns (bool) {
    return s.data[addr].keyIndex > 0;
  }

  function haveValue(address addr) public view returns (bool) {
    if (s.data[addr].subscriptions.length > 0) {
        for(uint256 i = 0; i < s.data[addr].subscriptions.length; i++) {
            if (s.data[addr].subscriptions[i].active) {
                return true;
            }
        }

        return false;
    } else {
        return false;
    }
  }

  function isFirstValue(address addr) public view returns (bool) {
    if (s.data[addr].subscriptions.length > 0) {
      return false;
    } else {
      return true;
    }
  }

  function getBonusUsd(address addr) public view returns (uint) {
    return s.data[addr].bonusUsd;
  }

  function getCareerPercent(address addr) public view returns (uint) {
    return s.data[addr].careerPercent;
  }

  function getTotalSubscription(address addr) public view returns (uint) {
      return s.data[addr].subscriptions.length;
  }

  function size() public view returns (uint) {
    return s.keys.length;
  }

  function getUserAddress(uint256 index) public view returns (address) {
    return s.keys[index];
  }
}

contract PoolApi is ChainlinkClient, Ownable {
    using Chainlink for Chainlink.Request;
    bytes32 private jobId;
    uint256 private fee;
    bool public canset;
    string public api;
    mapping(address => uint256) public userPools;
    address admin;

    event RequestVolume(bytes32 indexed requestId, string data, address user);

    constructor(address _admin) {
      admin = _admin;
      canset = true;
        setChainlinkToken(0x404460C6A5EdE2D891e8297795264fDe62ADBB75);
        setChainlinkOracle(0x9bA20D237964ce692A73168AdA08163807368040);
        jobId = "cd99bc931eea4432abb6b99e9819101d"; //string
        fee = (15 * LINK_DIVISIBILITY) / 100; // 0,15 * 10**18 (Varies by network and job)
        api = "https://api.paychanger.io/api/v1/contract/poolamount/";
    }

    function setData(address _addr, uint256 _volume) public {
      require(msg.sender == admin, "You havent access to this function");
      require(canset == true, "Manual method blocked");
      userPools[_addr] = _volume;
    }

    function changeOracleData(address _oracle, bytes32 _job, uint256 _fee) public {
      require(msg.sender == admin, "You havent access to this function");
      setChainlinkOracle(_oracle);
      jobId = _job;
      fee = _fee;
    }

    function changeCanSet() public {
      require(msg.sender == admin, "You havent access to this function");
      canset = false;
    }

    function requestVolumeData(address wallet) public onlyOwner returns (bytes32 requestId) {

      Chainlink.Request memory req = buildChainlinkRequest(
          jobId,
          address(this),
          this.fulfill.selector
      );

      req.add(
          "get",
          string(
              abi.encodePacked(
                  api,
                  addressToString(wallet)
              )
          )
      );

      req.add("path1", "poolamount"); 

      int256 timesAmount = 10 ** 18;
      req.addInt("times", timesAmount);

      return sendChainlinkRequest(req, fee);
    }

    /**
     * Receive the response in the form of uint256
     */
    function fulfill(
        bytes32 _requestId,
        string calldata _apidata
    ) public recordChainlinkFulfillment(_requestId) {
        emit RequestVolume(_requestId, _apidata, msg.sender);
        string memory _data = _apidata;
        (uint256 _volume, address _addr) = splitString(_data);
        userPools[_addr] = _volume;
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function getUserPoolAmount(address addr) public view returns (uint256 poolAmount) {
      poolAmount = userPools[addr];
    }

    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(uint160(_address)));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = '0';
        _string[1] = 'x';
        for(uint i = 0; i < 20; i++) {
            _string[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }

    function splitString(string memory input) public pure returns (uint256, address) {
        bytes memory inputBytes = bytes(input);
        uint256 delimiterIndex = indexOf(inputBytes, "_");

        bytes memory uint256Part = new bytes(delimiterIndex);
        bytes memory addressPart = new bytes(inputBytes.length - delimiterIndex - 1);

        for (uint256 i = 0; i < delimiterIndex; i++) {
            uint256Part[i] = inputBytes[i];
        }
        for (uint256 i = 0; i < inputBytes.length - delimiterIndex - 1; i++) {
            addressPart[i] = inputBytes[i + delimiterIndex + 1];
        }

        uint256 value = bytesToUint(uint256Part);
        address addr = bytesToAddress(addressPart);

        return (value, addr);
    }

    function indexOf(bytes memory inputBytes, string memory delimiter) private pure returns (uint256) {
        bytes memory delimiterBytes = bytes(delimiter);
        for (uint256 i = 0; i <= inputBytes.length - delimiterBytes.length; i++) {
            bool found = true;
            for (uint256 j = 0; j < delimiterBytes.length; j++) {
                if (inputBytes[i + j] != delimiterBytes[j]) {
                    found = false;
                    break;
                }
            }
            if (found) {
                return i;
            }
        }
        return inputBytes.length;
    }
    
    function bytesToUint(bytes memory input) private pure returns (uint256) {
        uint256 result = 0;
        for (uint256 i = 0; i < input.length; i++) {
            uint8 digit = uint8(input[i]) - 48; // Convert ASCII to integer (0-9)
            result = result * 10 + digit;
        }
        return result;
    }
    
    function bytesToAddress(bytes memory input) private pure returns (address) {
        require(input.length == 42, "Invalid address length");
        bytes memory addressBytes = new bytes(20);
        for (uint256 i = 2; i < input.length; i += 2) {
            addressBytes[(i - 2) / 2] = bytes1((uint8(fromHexChar(input[i])) * 16) + uint8(fromHexChar(input[i + 1])));
        }
        return address(bytes20(addressBytes));
    }
    
    function fromHexChar(bytes1 c) private pure returns (uint8) {
        if (c >= bytes1("0") && c <= bytes1("9")) {
            return uint8(c) - 48; // ASCII("0") = 48
        }
        if (c >= bytes1("a") && c <= bytes1("f")) {
            return uint8(c) - 87; // ASCII("a") = 97
        }
        if (c >= bytes1("A") && c <= bytes1("F")) {
            return uint8(c) - 55; // ASCII("A") = 65
        }
        revert("Invalid hex character");
    }

    function getContractAddress() public view returns(address) {
      return address(this);
    } 
}

error packageBuy__Failed();
error payment__Failed();

contract Paychanger is Context, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Percent for Percent.percent;
    using Zero for *;

    struct careerInfo {
      uint256 percentFrom;
      uint256 turnoverFrom;
      uint256 turnoverTo;
    }

    careerInfo[] public career;

    struct poolTransaction {
      uint256 date;
      uint256 value;
    }

    poolTransaction[] public pools;

    struct subscriptionInfo {
      bytes32 uid;
      uint256 valueUsd;
      uint256 releasedUsdAmount;
      uint256 takenFromPoolUsd;
      bool active;
      bool vestingPaid;
      bool haveVesting;
    }

    uint256 public freezeInPools;

    mapping(uint256 => uint256[]) public openedSubscriptions;
    mapping(uint256 => uint256[]) public closedSubscriptions;
    mapping(address => uint256) public takenFromPools;
    mapping(address => uint256) public lastApiRequestByUser;

    Percent.percent internal m_adminPercent = Percent.percent(40, 100); // 40/100*100% = 40%
    Percent.percent internal m_adminPercentHalf = Percent.percent(20, 100); // 20/100*100% = 20%
    Percent.percent internal m_poolPercent = Percent.percent(10, 100); // 10/100*100% = 10%
    Percent.percent internal m_bonusUsdPercent = Percent.percent(30, 100); // 30/100*100% = 30%
    Percent.percent internal m_paymentComissionPercent = Percent.percent(10, 100); // 10/100*100% = 10%
    Percent.percent internal m_paymentReferralPercent = Percent.percent(10, 100); // 10/100*100% = 10%
    Percent.percent internal m_paymentCashbackPercent = Percent.percent(10, 100); // 10/100*100% = 10%

    IERC20 public _token;

    IERC20 public _linkToken;

    uint256 public _rate;

    address payable _wallet;

    address public newAddress;

    uint256 public voteScore;

    bool public voteSuccess;

    bool public dataTransfered;

    mapping(address => uint256) public voteWalletWeight;

    mapping(address => bool) public votedWallets;

    address[375] public voteWallets;

    uint public addedCanVoteWalletsCount;

    mapping(address => address) public referral_tree; //referral - sponsor

    uint16[4] public packages = [100,500,1000,2500];

    uint256 internal _durationVesting;

    uint256 internal _periodVesting;

    uint256 internal _cliffVesting;

    uint256 public limitRequest;

    UsersStorage internal _users;

    TokenVesting internal vesting;

    PoolApi private poolApi;

    event AdminWalletChanged(address indexed oldWallet, address indexed newWallet);

    event referralBonusPaid(address indexed from, address indexed to, uint256 indexed tokenAmount, uint256 value, uint256 date);

    event compressionBonusPaid(address indexed from, address indexed to, uint256 indexed package, uint256 value, uint256 date);

    event transactionCompleted(address indexed from, address indexed to, uint256 tokenAmount, string txdata, uint256 date);

    event referralTree(address indexed referral, address indexed sponsor);

    event WithdrawOriginalBNB(address indexed owner, uint256 value);

    event subscriptionBuyed(address indexed user, uint256 indexed subscription, uint256 indexed tokens, bytes32 vestingId, uint256 startDate);

    event bonusUsdSpended(address indexed user, uint256 indexed package, uint256 indexed bonusPackage, uint256 date);

    event bonusUsdAccrued(address indexed user, uint256 indexed bonusAmount, uint256 date);

    event priceChanged(uint256 rate, uint256 date);

    event payedFromPool(address indexed beneficiary, uint256 indexed withdrawAmount, uint256 date);

    event getWithdraw(address indexed beneficiary, uint256 indexed withdrawAmount, uint256 date);

    event vestingReleased(address indexed beneficiary, bytes32 vestingScheduleId, uint256 vestingAmount, uint256 date);

    event vestingRevoked(address indexed beneficiary, bytes32 vestingScheduleId, uint256 date);
    
    modifier checkPackage(uint256 package) {
      require(_havePackage(package) == true, "There is no such subscription");
      _;
    }

    modifier activeSponsor(address walletSponsor) {
      require(_users.contains(walletSponsor) == true,"There is no such sponsor");
      require(walletSponsor.notZero() == true, "Please set a sponsor");
      require(walletSponsor != _msgSender(),"You need a sponsor referral link, not yours");
      _;
    }

    modifier canVote() {
      require(voteWalletWeight[_msgSender()] > 0, "You cannot vote");
      require(votedWallets[_msgSender()] == false, "already vote");
      _;
    }

    modifier checkTransfered() {
        require (dataTransfered == false, "already transfered");
        _;
    }

    constructor(IERC20 token, IERC20 linktoken, UsersStorage userstorage, TokenVesting tokenvesting,  address payable wallet, uint256 rate) {
      _token = token;
      _linkToken = linktoken;
      _wallet = wallet;
      _rate = rate;

      _users = userstorage;

      vesting = tokenvesting;

      poolApi = new PoolApi(_wallet);

      _durationVesting = 31104000; //- 360days in seconds
      _periodVesting = 604800; //- 7 days in seconds
      _cliffVesting = 0;
      limitRequest = 604800;

      career.push(careerInfo(50, 0, 999)); //5%
      career.push(careerInfo(60, 1000, 2499)); //6%
      career.push(careerInfo(70, 2500, 4999)); //7%
      career.push(careerInfo(80, 5000, 9999)); //8%
      career.push(careerInfo(90, 10000, 24999)); //9%
      career.push(careerInfo(100, 25000, 49999)); //10%
      career.push(careerInfo(110, 50000, 99999)); //11%
      career.push(careerInfo(120, 100000, 249999)); //12%
      career.push(careerInfo(135, 250000, 499999)); //13,5%
      career.push(careerInfo(150, 500000, 999999)); //15%
      career.push(careerInfo(165, 1000000, 2499999)); //16,5%
      career.push(careerInfo(175, 2500000, 4999999)); //17,5%
      career.push(careerInfo(185, 5000000, 9999999)); //18,5%
      career.push(careerInfo(190, 10000000, 24999999)); //19%
      career.push(careerInfo(195, 25000000, 49999999)); //19,5%
      career.push(careerInfo(200, 50000000, 10000000000000000)); //20%

      referral_tree[wallet] = address(this);
      emit referralTree(wallet, address(this));
    }

    function _havePackage(uint256 package) internal view returns(bool) {
      for (uint256 i = 0; i < packages.length; i++) {
        if (packages[i] == package) {
          return true;
        }
      }
      return false;
    }

    function buyPackage(uint256 package, address sponsor) public payable activeSponsor(sponsor) checkPackage(package) nonReentrant {
      address beneficiary = _msgSender();

      if (!_users.contains(beneficiary)) {
        _activateReferralLink(sponsor, beneficiary, true);
      }

      uint256 bonusPackage = 0;

      if (_users.contains(beneficiary)) {

        if (_users.getBonusUsd(beneficiary) > 0) {
          if (_users.getBonusUsd(beneficiary) <= m_bonusUsdPercent.mul(package)) {
              bonusPackage = _users.getBonusUsd(beneficiary);
          } else {
              bonusPackage = m_bonusUsdPercent.mul(package);               
          }
        }

        uint256 tokenAmountForPay = _getTokenAmountByUSD(package-bonusPackage);
        uint256 tokenAmount = _getTokenAmountByUSD(package);

        require(_token.balanceOf(beneficiary) >= tokenAmountForPay, "Not enough tokens");

        require(_token.allowance(beneficiary,address(this)) >= tokenAmountForPay, "Please allow fund first");
        bool success = _token.transferFrom(beneficiary, address(this), tokenAmountForPay);

        if (!success) {
          revert packageBuy__Failed();
        } else {
          uint256 adminAmount = 0;
          bytes32 vestingId = bytes32(0);

          if (bonusPackage > 0) {
            adminAmount = m_adminPercent.mul(tokenAmount) - (tokenAmount-tokenAmountForPay);
            _users.setBonusUsd(beneficiary, bonusPackage, false);
            emit bonusUsdSpended(beneficiary, package, bonusPackage, block.timestamp);
          } else {
            adminAmount = m_adminPercent.mul(tokenAmount);
          }

          _token.transfer(_wallet, adminAmount);

          _sendToPools(tokenAmount);

          if (getAvailableTokenAmount() >= tokenAmount) {
            vestingId = vesting.createVestingSchedule(beneficiary, block.timestamp, _cliffVesting, _durationVesting, _periodVesting, true, tokenAmount*2);
          }

          if (referral_tree[beneficiary].isZero()) {
            referral_tree[beneficiary] = sponsor;

            emit referralTree(beneficiary, sponsor);
          }

          if (_users.isFirstValue(beneficiary)) {
            assert(_users.setBonusUsd(referral_tree[beneficiary], 1, true));
            emit bonusUsdAccrued(referral_tree[beneficiary], 1, block.timestamp);
          }

          assert(_users.insertSubscription(vestingId, beneficiary, tokenAmount, package));
          openedSubscriptions[package].push(block.timestamp);
            
          address payable mySponsor = payable(referral_tree[beneficiary]);

          if (_users.haveValue(mySponsor)) {
            _addReferralBonus(beneficiary, mySponsor, tokenAmount, true);
          }	
          _compressionBonus(tokenAmount, package, mySponsor, 0, 1);

          emit subscriptionBuyed(beneficiary, package, tokenAmount, vestingId, block.timestamp);
        }
      }
    }

    /**
    * @dev Returns the amount of tokens that can be use.
    * @return the amount of tokens
    */
    function getAvailableTokenAmount()
      public
      view
      returns(uint256){
      return _token.balanceOf(address(this)).sub(vesting.getVestingSchedulesTotalAmount()).sub(freezeInPools);
    }

    function setPoolAmountToApi() public {
      require((lastApiRequestByUser[_msgSender()] + limitRequest) < block.timestamp, "you already calculate in current period");

      poolApi.requestVolumeData(_msgSender());
      lastApiRequestByUser[_msgSender()] = block.timestamp;
    }

    function setPoolAmountToApiByUser() public {
      address poolApiAddress = poolApi.getContractAddress();

      require(_linkToken.allowance(_msgSender(),poolApiAddress) >= (15/100)*10**18, "Please allow fund first");
      bool success = _linkToken.transferFrom(_msgSender(), poolApiAddress, (15/100)*10**18);
      if (success) {
        poolApi.requestVolumeData(_msgSender());
      }
    }

    function getPoolAmountFromApi(address addr) public view returns (uint256 poolAmount) {
      poolAmount = poolApi.getUserPoolAmount(addr);
      if (poolAmount > freezeInPools) {
        poolAmount = freezeInPools;
      } 
    }

    function _compressionBonus(uint256 tokenAmount, uint256 package, address payable user, uint256 prevPercent, uint256 line) internal {
      address payable mySponsor = payable(referral_tree[user]);

      uint256 careerPercent = _users.getCareerPercent(user);

      _users.addTurnover(user, _getUsdAmount(tokenAmount));
      _checkCareerPercent(user);

      if (_users.haveValue(user)) {

        if (line == 1) {
          prevPercent = careerPercent;
        }
        if (line >= 2) {

          if (prevPercent < careerPercent) {

            uint256 finalPercent = career[careerPercent].percentFrom - career[prevPercent].percentFrom;
            uint256 bonus = tokenAmount*finalPercent/1000;

            if (bonus > 0 && _users.haveValue(user)) {
              assert(_users.addRefBonus(user, bonus, line));
              _token.transfer(user, bonus);
              emit compressionBonusPaid(_msgSender(), user, package, bonus, block.timestamp);

              prevPercent = careerPercent;
            }           
          }
        }
      }
      if (_notZeroNotSender(mySponsor) && _users.contains(mySponsor)) {
        line = line + 1;
        if (line < 51) {
          _compressionBonus(tokenAmount, package, mySponsor, prevPercent, line);
        }
      }
    }

    function withdraw(address payable beneficiary) public payable nonReentrant {
      require(_msgSender() == beneficiary, "you cannot access to release");

      subscriptionInfo memory subs;

      uint256 poolAmount = getPoolAmountFromApi(beneficiary);
      uint256 poolUsdAmount;
      uint256 availablePoolAmount;
      uint256 vestingAmount;
      uint256 vestingUsdAmount;
      uint256 withdrawAmount;
      uint256 subsPoolAmount;

      for (uint256 i = 0; i < _users.getTotalSubscription(beneficiary); i++) {
        subs = updateSubscriptionInfo(beneficiary, i);

        if (subs.active) {
          availablePoolAmount = poolAmount-takenFromPools[beneficiary];
          if (availablePoolAmount > 0) {
            if ((((subs.valueUsd*2)*10**10) - (subs.releasedUsdAmount + subs.takenFromPoolUsd)) >= _getUsdAmount(availablePoolAmount)) {
              poolUsdAmount = _getUsdAmount(availablePoolAmount);
              subsPoolAmount = availablePoolAmount;
            } else {
              subsPoolAmount = _getTokenAmountByUSD(((((subs.valueUsd*2)+1)*10**10) - (subs.releasedUsdAmount + subs.takenFromPoolUsd))/10**10);
              poolUsdAmount = _getUsdAmount(subsPoolAmount);
            }
            _users.setTakenFromPool(beneficiary, i, subsPoolAmount, poolUsdAmount);
            takenFromPools[beneficiary] += subsPoolAmount;
            freezeInPools -= subsPoolAmount;

            emit payedFromPool(beneficiary, subsPoolAmount, block.timestamp);
          } else {
            poolUsdAmount = 0;
            subsPoolAmount = 0;
          }

          if (subs.haveVesting && !subs.vestingPaid) {
            vestingAmount = vesting.computeReleasableAmount(subs.uid);
            vestingUsdAmount = _getUsdAmount(vestingAmount);

            vesting.release(subs.uid, beneficiary, vestingAmount);
            assert(_users.setSubscriptionReleasedUsd(beneficiary, i, vestingUsdAmount));
            emit vestingReleased(beneficiary, subs.uid, vestingAmount, block.timestamp);
            
            if ((vestingUsdAmount+subs.releasedUsdAmount+poolUsdAmount+subs.takenFromPoolUsd) >= ((subs.valueUsd*2)*10**10)) {
              vesting.revoke(subs.uid);
              assert(_users.setNotActiveSubscription(beneficiary, i));
              closedSubscriptions[subs.valueUsd].push(block.timestamp);
              emit vestingRevoked(beneficiary, subs.uid, block.timestamp);
            }
          } else {
            vestingAmount = 0;
            if ((poolUsdAmount+subs.takenFromPoolUsd) >= ((subs.valueUsd*2)*10**10)) {
              assert(_users.setNotActiveSubscription(beneficiary, i));
              closedSubscriptions[subs.valueUsd].push(block.timestamp);
            }
          }
          if (subsPoolAmount > 0 || vestingAmount > 0) {
            withdrawAmount += calculateAmountForWithdraw(subs.releasedUsdAmount, subs.takenFromPoolUsd, subs.valueUsd, (vestingAmount+subsPoolAmount));
          }       
        }
      }
      if (withdrawAmount > 0) {
        _token.transfer(beneficiary, withdrawAmount);

        emit getWithdraw(beneficiary, withdrawAmount, block.timestamp);
      }
    }

    function updateSubscriptionInfo(address beneficiary, uint256 index) internal view returns (subscriptionInfo memory subs) {
      (subs.uid, subs.valueUsd, subs.active, subs.vestingPaid, subs.haveVesting) = _users.userSingleSubscriptionActive(beneficiary, index);
      (subs.releasedUsdAmount, subs.takenFromPoolUsd) = _users.userSubscriptionReleasedUsd(beneficiary, index);
      return subs;
    }

    function calculateAmountForWithdraw(uint256 releasedAmount, uint256 releasedFromPools, uint256 availableAmount, uint256 neededAmount) internal view returns (uint256 withdrawAmount) {
      int leftAmountUsd = (int(availableAmount*2)*10**10) - (int(releasedAmount)+int(releasedFromPools));
      if (leftAmountUsd > 0) {
        uint256 leftAmount = _getTokenAmountByUSD(uint256(leftAmountUsd)/10**10);
        withdrawAmount = (int(leftAmount) - int(neededAmount)) >= 0 ? neededAmount : leftAmount;
      }
    }

    function _addReferralBonus(address user, address payable sponsor, uint256 tokenAmount, bool isPackage) internal {
      uint256 reward;

      if (isPackage == true) {
        uint256 careerPercent = _users.getCareerPercent(sponsor);
        reward = tokenAmount*career[careerPercent].percentFrom/1000;
        assert(_users.addRefBonus(sponsor, reward, 1));
      } else {
        reward = m_paymentReferralPercent.mul(tokenAmount);
      }
      _token.transfer(sponsor, reward);
      emit referralBonusPaid(user, sponsor, tokenAmount, reward, block.timestamp);
    }

    function payment(uint256 tokenAmount, address receiver, string calldata txdata) public payable nonReentrant {
      require(_token.balanceOf(_msgSender()) >= tokenAmount, "Not enough tokens");

      require(_token.allowance(_msgSender(),address(this)) >= tokenAmount, "Please allow fund first");
      bool success = _token.transferFrom(_msgSender(), address(this), tokenAmount);

      if (!success) {
        revert payment__Failed();
      } else {

        if (!_users.contains(_msgSender())) {
            assert(_users.insertUser(_msgSender()));
            referral_tree[_msgSender()] = address(this);
            emit referralTree(_msgSender(), address(this));
        }

        if (!_users.contains(receiver)) {
            assert(_users.insertUser(receiver));
            referral_tree[receiver] = address(this);
            emit referralTree(receiver, address(this));
        }

        uint256 tokenCommission = m_paymentComissionPercent.mul(tokenAmount);

        address payable sponsorSenderOne = payable(referral_tree[_msgSender()]);
        address payable sponsorReceiverOne = payable(referral_tree[receiver]);       
        

        if (_users.contains(sponsorSenderOne)) {
          assert(_users.setBonusUsd(sponsorSenderOne, 1, true));
          emit bonusUsdAccrued(sponsorSenderOne, 1, block.timestamp);
          if (_users.haveValue(sponsorSenderOne)) {
            _addReferralBonus(_msgSender(), sponsorSenderOne, tokenCommission, false);
          }
        }

        if (_users.contains(sponsorReceiverOne)) {
          assert(_users.setBonusUsd(sponsorReceiverOne, 1, true));
          emit bonusUsdAccrued(sponsorReceiverOne, 1, block.timestamp);
          if (_users.haveValue(sponsorReceiverOne)) {
            _addReferralBonus(receiver, sponsorReceiverOne, tokenCommission, false);
          }
        }
        
        _token.transfer(_wallet, m_adminPercentHalf.mul(tokenCommission));

        _sendToPools(tokenCommission);

        uint256 package = _getUsdAmount(tokenCommission);

        if (getAvailableTokenAmount() >= (tokenCommission*3)) {
          bytes32 vestingSenderId = vesting.createVestingSchedule(_msgSender(), block.timestamp, _cliffVesting, _durationVesting, _periodVesting, false, tokenCommission*2); //sender
          bytes32 vestingReceiverId = vesting.createVestingSchedule(receiver, block.timestamp, _cliffVesting, _durationVesting, _periodVesting, false, tokenCommission); //reciever
          assert(_users.insertSubscription(vestingSenderId, _msgSender(), tokenCommission, package));
          assert(_users.insertSubscription(vestingReceiverId, receiver, tokenCommission, package));
        }

        _token.transfer(receiver, (tokenAmount-tokenCommission));

        emit transactionCompleted(_msgSender(), receiver, tokenAmount, txdata, block.timestamp);
      }
    }

    function _checkCareerPercent(address addr) internal {
      (, uint256 turnoverUsd, uint256 careerPercent) = _users.userTurnover(addr);

      uint256 cleanTurnoverUsd = turnoverUsd/10**10;
      if (career[careerPercent+1].turnoverFrom <= cleanTurnoverUsd && career[careerPercent+1].turnoverTo >= cleanTurnoverUsd) {
        _users.setCareerPercent(addr, careerPercent+1);
      } else if (career[careerPercent+2].turnoverFrom <= cleanTurnoverUsd && career[careerPercent+2].turnoverTo >= cleanTurnoverUsd) {
        _users.setCareerPercent(addr, careerPercent+2);
      }
    }

    function usersNumber() public view returns(uint) {
      return _users.size();
    }

    function _notZeroNotSender(address addr) internal view returns(bool) {
      return addr.notZero() && addr != _msgSender();
    }

    function _getUsdAmount(uint256 tokenAmount) internal view returns (uint256){
      return tokenAmount.mul(_rate).div(10**18);   
    }

    function _getTokenAmountByUSD(uint256 usdAmount) internal view returns(uint256) {
      return usdAmount.mul(10**28).div(_rate);
    }

    function _sendToPools(uint256 tokenAmount) internal {
      uint256 toPool = m_poolPercent.mul(tokenAmount);
      freezeInPools += toPool*4;
      pools.push(poolTransaction(block.timestamp, toPool));
    }

    function activateReferralLinkByOwner(address sponsor, address referral, bool needBonusUsd) public onlyOwner activeSponsor(sponsor) returns(bool) {
      _activateReferralLink(sponsor, referral, needBonusUsd);
      return true;
    }

    function activateReferralLinkByUser(address sponsor) public nonReentrant returns(bool) {
      _activateReferralLink(sponsor, _msgSender(), true);
      return true;
    }

    function _activateReferralLink(address sponsor, address referral, bool needBonusUsd) internal activeSponsor(sponsor) {
      require(_users.contains(referral) == false, "already activate");

      assert(_users.insertUser(referral));
      referral_tree[referral] = sponsor;

      emit referralTree(referral, sponsor);

      if (needBonusUsd) {
        assert(_users.setBonusUsd(sponsor, 1, true));
        emit bonusUsdAccrued(sponsor, 1, block.timestamp);
      }
    }
 
    function changeAdminWallet(address payable wallet) public onlyOwner {
      require(wallet != address(0), "New admin address is the zero address");
      address oldWallet = _wallet;
      _wallet = wallet;
      emit AdminWalletChanged(oldWallet, wallet);
    }

    function setRate(uint256 rate) public onlyOwner {
      require(rate < 1e11, "support only 10 decimals"); //max token price 99,99 usd
      require(rate > 0, "price should be greater than zero");
      _rate = rate; //10 decimal
      emit priceChanged(rate, block.timestamp);
    } 

    function sendBonusUsd(address beneficiary, uint256 amount) public onlyOwner {
      require(_users.contains(beneficiary) == true, "This address does not exists");
      _users.setBonusUsd(beneficiary, amount, true);
      emit bonusUsdAccrued(beneficiary, 1, block.timestamp);
    }

    function stopMintBonusUsd() public onlyOwner {
        _users.setStopMintBonusUsd();
    }

    function setVote(address addr) public onlyOwner {
      newAddress = addr;
    }

    function cancelVote() public onlyOwner {
      voteScore = 0;
      newAddress = address(0);
      voteSuccess = false;
      for(uint256 i = 0; i < voteWallets.length; i++) {
        votedWallets[voteWallets[i]] = false;
      }
    }

    function vote() public canVote {
      require(newAddress.notZero() == true, "No votes at this moment");
      voteScore += voteWalletWeight[_msgSender()];
      votedWallets[_msgSender()] = true;
      if (voteScore >= 360) {
        voteSuccess = true;
      }
    }

    function addVoteWallet(address wallet, uint256 weight) public onlyOwner {
      require(addedCanVoteWalletsCount < 375, "No more wallets can be added.");
      require(weight < 4, "Weight can be only between 1 and 3");

      voteWalletWeight[wallet] = weight;
      voteWallets[addedCanVoteWalletsCount] = wallet;
      addedCanVoteWalletsCount++;
    }

    function setNewContract(bool newOwnerContracts) public onlyOwner {
      if (voteSuccess) {
        if (newOwnerContracts) {
          _users.transferOwnership(newAddress);
          vesting.transferOwnership(newAddress);
          _token.transfer(newAddress, _token.balanceOf(address(this)));
        } else {
          _token.transfer(newAddress, getAvailableTokenAmount());
        }        
        voteSuccess = false;
        voteScore = 0;
        newAddress = address(0);
      }
    }

    function changeLimitRequest(uint256 _limitRequest) public onlyOwner {
      limitRequest = _limitRequest;
    }

    function withdrawBNB() public onlyOwner {
      uint256 weiAmount = address(this).balance;
      _wallet.transfer(weiAmount);
      emit WithdrawOriginalBNB(_msgSender(), weiAmount);
    }

    function transferNftOwner(address newowner) public {
      require(voteWalletWeight[_msgSender()] > 0, "You dont have a vote access");
      uint256 weight = voteWalletWeight[_msgSender()];
      delete voteWalletWeight[_msgSender()];
      for(uint256 i = 0; i < voteWallets.length; i++) {
        if (voteWallets[i] == _msgSender()) {
          voteWallets[i] = newowner;
        }
      }
      voteWalletWeight[newowner] = weight;
    }

    function setReferralTree(address sponsor, address referral) public checkTransfered onlyOwner {
        require(_users.contains(referral) == true, "user is no exist");
        require(referral_tree[referral] == address(0), "user is exist");

        referral_tree[referral] = sponsor;
        emit referralTree(referral, sponsor);
    }

    function setFreezeInPools(uint256 _freezeInPools) public checkTransfered onlyOwner {
        freezeInPools = _freezeInPools;
    }

    function setTakeFromPool(address beneficiary, uint256 amount) public checkTransfered onlyOwner {
        require(takenFromPools[beneficiary] == 0, "already set");
        takenFromPools[beneficiary] = amount;
    }

    function setDataTransfered() public checkTransfered onlyOwner {
        dataTransfered = true;
    }

}