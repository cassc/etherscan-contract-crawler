// SPDX-License-Identifier: MIT

/////////////     ////        ////        ///////////
    ////          ////        ////        ///
    ////          ////        ////        ///
    ////          ////////////////        ///
    ////          ////        ////        ///
    ////          ////        ////        ///
    ////          ////        ////        ///////////


////        ////    //////////////    /////////////     ////        ////
////        ////         ////         ////              ////        ////
////        ////         ////         ////              ////        ////
////////////////         ////         ////   ///////    ////////////////
////        ////         ////         ////      ////    ////        ////
////        ////         ////         ////      ////    ////        ////
////        ////     /////////////    //////////////    ////        ////


      /////          /////////////    //////////////    ////////////////
   ////  ////        ///       ///    ////              ////
////       ////      ///       ///    ////              ////
///         ///      ///       ///    ////              ////
///////////////      /////////////    ///////////       ////////////////
/// /////// ///      ///              ////                          ////
///         ///      ///              ////                          ////
///         ///      ///              //////////////    ////////////////


// Advancement of CHEETH Anonymice Contract, Credits to the devs

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract THCToken is ERC20Burnable, Ownable {

    struct StakedHighApe {
        uint256 tokenId;
        uint256 stakedSince;
        uint256 jointEmision;
    }

    using EnumerableSet for EnumerableSet.UintSet;
    uint256 public constant HighApesLimit = 25;

    address public highApes;

    mapping (uint256 => string) private _initialAccessSetter;

    // Staked Apes

    mapping(address => EnumerableSet.UintSet) private stakedApes;

    // Staked Apes to Timestamp Staked

    mapping(uint256 => uint256) public apesStakeTimes;
    mapping(uint256 => uint256) public apesClaimTimes;

    constructor() ERC20("Joint", "JOINT") {
    }

    function stakeapesByIds(uint256[] memory _apesIds) external {
        require(
            _apesIds.length + stakedApes[msg.sender].length() <= HighApesLimit,
            "THC: Can stake maximum of 25 Apes!"
        );
        
        for (uint256 i = 0; i < _apesIds.length; i++) {
            _stakeHighApe(_apesIds[i]);
        }
    }

    function unstakeapesByIds(uint256[] memory _apesIds) public {
        for (uint256 i = 0; i < _apesIds.length; i++) {
            _unstakeHighApe(_apesIds[i]);
        }
    }

    function claimRewardsByIds(uint256[] memory _apesIds) external {
        uint256 runningjointAllowance;

        for (uint256 i = 0; i < _apesIds.length; i++) {
            uint256 thisApeID = _apesIds[i];
            require(
                stakedApes[msg.sender].contains(thisApeID),
                "THC: You can only claim Apes you've staked!"
            );
            runningjointAllowance += getjointOwedToThisHighApe(thisApeID);

            apesClaimTimes[thisApeID] = block.timestamp;
        }
        _mint(msg.sender, runningjointAllowance);
    }

    function claimAllRewards() external {
        uint256 runningjointAllowance;

        for (uint256 i = 0; i < stakedApes[msg.sender].length(); i++) {
            uint256 thisApeID = stakedApes[msg.sender].at(i);
            runningjointAllowance += getjointOwedToThisHighApe(thisApeID);

            apesClaimTimes[thisApeID] = block.timestamp;
        }
        _mint(msg.sender, runningjointAllowance);
    }

    function unstakeAll() external {
        unstakeapesByIds(stakedApes[msg.sender].values());
    }

    function _stakeHighApe(uint256 _ApesID) internal onlyApesOwner(_ApesID) {

        // Transfer their token

        IERC721Enumerable(highApes).transferFrom(
            msg.sender,
            address(this),
            _ApesID
        );

        // Add the apes to the owner's set

        stakedApes[msg.sender].add(_ApesID);

        // Set this HighApeId timestamp to now

        apesStakeTimes[_ApesID] = block.timestamp;
        apesClaimTimes[_ApesID] = 0;
    }

    function _unstakeHighApe(uint256 _ApesID)
        internal
        onlyApesStaker(_ApesID)
    {
        uint256 jointOwedToThisHighApe = getjointOwedToThisHighApe(_ApesID);
        _mint(msg.sender, jointOwedToThisHighApe);

        IERC721(highApes).transferFrom(
            address(this),
            msg.sender,
            _ApesID
        );

        stakedApes[msg.sender].remove(_ApesID);
    }

    // GETTERS

    function getStakedapesData(address _address)
        external
        view
        returns (StakedHighApe[] memory)
    {
        uint256[] memory ids = stakedApes[_address].values();
        StakedHighApe[] memory stakedapes = new StakedHighApe[](ids.length);
        for (uint256 index = 0; index < ids.length; index++) {
            uint256 _ApesID = ids[index];
            stakedapes[index] = StakedHighApe(
                _ApesID,
                apesStakeTimes[_ApesID],
                getApesJointEmission(_ApesID)
            );
        }

        return stakedapes;
    }

    function tokensStaked(address _address)
        external
        view
        returns (uint256[] memory)
    {
        return stakedApes[_address].values();
    }

    function stakedapesQuantity(address _address)
        external
        view
        returns (uint256)
    {
        return stakedApes[_address].length();
    }

    function getjointOwedToThisHighApe(uint256 _ApesID)
        public
        view
        returns (uint256)
    {
        uint256 elapsedTime = block.timestamp - apesStakeTimes[_ApesID];
        uint256 elapsedDays = elapsedTime < 1 days ? 0 : elapsedTime / 1 days;
        uint256 leftoverSeconds = elapsedTime - elapsedDays * 1 days;

        if (apesClaimTimes[_ApesID] == 0) {
            return _calculatejoint(elapsedDays, leftoverSeconds);
        }

        uint256 elapsedTimeSinceClaim = apesClaimTimes[_ApesID] -
            apesStakeTimes[_ApesID];
        uint256 elapsedDaysSinceClaim = elapsedTimeSinceClaim < 1 days
            ? 0
            : elapsedTimeSinceClaim / 1 days;
        uint256 leftoverSecondsSinceClaim = elapsedTimeSinceClaim -
            elapsedDaysSinceClaim *
            1 days;

       return _calculatejoint(elapsedDays, leftoverSeconds) - _calculatejoint(elapsedDaysSinceClaim, leftoverSecondsSinceClaim);
        
    }

    function getTotalRewardsForUser(address _address)
        external
        view
        returns (uint256)
    {
        uint256 runningjointTotal;
        uint256[] memory apesIds = stakedApes[_address].values();
        for (uint256 i = 0; i < apesIds.length; i++) {
            runningjointTotal += getjointOwedToThisHighApe(apesIds[i]);
        }
        return runningjointTotal;
    }

    function getApesJointEmission(uint256 _ApesID)
        public
        view
        returns (uint256)
    {
        uint256 elapsedTime = block.timestamp - apesStakeTimes[_ApesID];
        uint256 elapsedDays = elapsedTime < 1 days ? 0 : elapsedTime / 1 days;
        return _jointDailyIncrement(elapsedDays);
    }

    function _calculatejoint(uint256 _days, uint256 _leftoverSeconds)
        internal
        pure
        returns (uint256)
    {
        uint256 progressiveDays = Math.min(_days, 100);
        uint256 progressiveReward = progressiveDays == 0
            ? 0
            : (progressiveDays *
                (80.2 ether + 0.2 ether * (progressiveDays - 1) + 80.2 ether)) /
                2;

        uint256 dailyIncrement = _jointDailyIncrement(_days);
        uint256 leftoverReward = _leftoverSeconds > 0
            ? (dailyIncrement * _leftoverSeconds) / 1 days
            : 0;

        if (_days <= 100) {
            return progressiveReward + leftoverReward;
        }
        return progressiveReward + (_days - 100) * 100 ether + leftoverReward;
    }

    function _jointDailyIncrement(uint256 _days)
        internal
        pure
        returns (uint256)
    {
        return _days > 100 ? 100 ether : 80 ether + _days * 0.2 ether;
    }
  
    // Only THC Boss

    function setAddresses(address _highApes)
        public
        onlyOwner
    {
        highApes = _highApes;
    }

    function initialSupplyCreation(address to, uint256 amount) public onlyOwner {

        require(bytes(_initialAccessSetter[0]).length == 0, "THC: Access is Disabled Permanently");

        // Will not work after condition is set

        _mint(to, amount);
    }

    function setInitialAccess(string memory setaccess) public onlyOwner {
          _initialAccessSetter[0] = setaccess;
       }

    // Apes Modifiers

    modifier onlyApesOwner(uint256 _ApesID) {
        require(
            IERC721Enumerable(highApes).ownerOf(_ApesID) == msg.sender,
            "THC: You can only stake the Apes you own!"
        );
        _;
    }

    modifier onlyApesStaker(uint256 _ApesID) {
        require(
            stakedApes[msg.sender].contains(_ApesID),
            "THC: You can only unstake the Apes you staked!"
        );
        _;
    }
}