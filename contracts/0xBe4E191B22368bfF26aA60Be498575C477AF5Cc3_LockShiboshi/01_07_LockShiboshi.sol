//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ILockShiboshi.sol";
import "./interfaces/ILandAuction.sol";

contract LockShiboshi is ILockShiboshi, Ownable {
    uint256 public immutable AMOUNT_MIN;
    uint256 public immutable AMOUNT_MAX;
    uint256 public immutable DAYS_MIN;
    uint256 public immutable DAYS_MAX;

    IERC721 public immutable SHIBOSHI;

    ILandAuction public landAuction;

    struct Lock {
        uint256[] ids;
        uint256 startTime;
        uint256 numDays;
        address ogUser;
    }

    mapping(address => Lock) private _lockOf;

    constructor(
        address _shiboshi,
        uint256 amountMin,
        uint256 amountMax,
        uint256 daysMin,
        uint256 daysMax
    ) {
        SHIBOSHI = IERC721(_shiboshi);
        AMOUNT_MIN = amountMin;
        AMOUNT_MAX = amountMax;
        DAYS_MIN = daysMin;
        DAYS_MAX = daysMax;
    }

    function lockInfoOf(address user)
        public
        view
        returns (
            uint256[] memory ids,
            uint256 startTime,
            uint256 numDays,
            address ogUser
        )
    {
        return (
            _lockOf[user].ids,
            _lockOf[user].startTime,
            _lockOf[user].numDays,
            _lockOf[user].ogUser
        );
    }

    function weightOf(address user) public view returns (uint256) {
        return _lockOf[user].ids.length * _lockOf[user].numDays;
    }

    function extraShiboshiNeeded(address user, uint256 targetWeight)
        external
        view
        returns (uint256)
    {
        uint256 currentWeight = weightOf(user);

        if (currentWeight >= targetWeight) {
            return 0;
        }

        return (targetWeight - currentWeight) / _lockOf[user].numDays;
    }

    function extraDaysNeeded(address user, uint256 targetWeight)
        external
        view
        returns (uint256)
    {
        uint256 currentWeight = weightOf(user);

        if (currentWeight >= targetWeight) {
            return 0;
        }

        return (targetWeight - currentWeight) / _lockOf[user].ids.length;
    }

    function isWinner(address user) public view returns (bool) {
        return landAuction.winningsBidsOf(user) > 0;
    }

    function unlockAt(address user) public view returns (uint256) {
        Lock memory s = _lockOf[user];

        if (isWinner(user)) {
            return s.startTime + s.numDays * 1 days;
        }

        return s.startTime + 15 days + (s.numDays * 1 days) / 3;
    }

    function setLandAuction(address sale) external onlyOwner {
        landAuction = ILandAuction(sale);
    }

    function lock(uint256[] memory ids, uint256 numDaysToAdd) external {
        Lock storage s = _lockOf[msg.sender];

        uint256 length = ids.length;
        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            SHIBOSHI.transferFrom(msg.sender, address(this), ids[i]);
            s.ids.push(ids[i]);
        }

        length = s.ids.length;
        require(
            AMOUNT_MIN <= length && length <= AMOUNT_MAX,
            "SHIBOSHI count outside of limits"
        );

        if (s.numDays == 0) {
            // no existing lock
            s.startTime = block.timestamp;
            s.ogUser = msg.sender;
        }

        if (numDaysToAdd > 0) {
            s.numDays += numDaysToAdd;
        }

        uint256 numDays = s.numDays;

        require(
            DAYS_MIN <= numDays && numDays <= DAYS_MAX,
            "Days outside of limits"
        );
    }

    function unlock() external {
        Lock storage s = _lockOf[msg.sender];

        uint256 length = s.ids.length;

        require(length > 0, "No SHIBOSHI locked");
        require(unlockAt(msg.sender) <= block.timestamp, "Not unlocked yet");

        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            // NOT using safeTransferFrom intentionally
            SHIBOSHI.transferFrom(address(this), msg.sender, s.ids[i]);
        }

        delete _lockOf[msg.sender];
    }

    function _uncheckedInc(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }

    function transferLock(address newOwner) external {
        require(_lockOf[msg.sender].numDays != 0, "Lock does not exist");
        require(_lockOf[newOwner].numDays == 0, "New owner already has a lock");
        _lockOf[newOwner] = _lockOf[msg.sender];
        delete _lockOf[msg.sender];
    }
}