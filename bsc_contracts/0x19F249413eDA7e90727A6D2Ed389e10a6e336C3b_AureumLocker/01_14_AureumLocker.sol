// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IFeed.sol";
import "hardhat/console.sol";
import "./IAreumToken.sol";
import "./IterableMapping.sol";

contract AureumLocker is AccessControl {
    using IterableMapping for IterableMapping.Map;
    using IterableMapping for IterableMapping.SwapLock;
    event Lock(
        uint256 indexed id,
        address indexed owner,
        uint256 indexed value
    );
    uint256 public lockId;

    using Address for address;
    address public tokenAerum =
        address(0x000000000000000000000000000000000000007E);

    IterableMapping.Map private activeLocks;
    IterableMapping.Map private archivedLocks;

    function getNewLockId() internal returns (uint256) {
        lockId = lockId + 1;
        return lockId;
    }

    bytes32 public constant LOCKER_ROLE = keccak256("LOCKER_ROLE");

    constructor(address tokenAerum_, address locker_) {
        tokenAerum = tokenAerum_;
        _setupRole(DEFAULT_ADMIN_ROLE, locker_);
        _setupRole(LOCKER_ROLE, locker_);
    }

    function lock(uint256 tokenValue_) public {
        require(
            IERC20(tokenAerum).balanceOf(_msgSender()) > 0,
            "Not enough funds."
        );

        IERC20(tokenAerum).transferFrom(
            _msgSender(),
            address(this),
            tokenValue_
        );

        IterableMapping.SwapLock memory lockForAdd;
        lockForAdd.owner = _msgSender();
        lockForAdd.tokenValue = tokenValue_;
        lockForAdd.status = 1;

        uint256 id = getNewLockId();
        activeLocks.set(id, lockForAdd);

        emit Lock(id, _msgSender(), tokenValue_);
    }

    function getActiveLockLenght() public view returns (uint256 size) {
        return activeLocks.getSize();
    }

    function getActiveLockById(uint256 id_)
        public
        view
        returns (IterableMapping.SwapLock memory lock)
    {
        return activeLocks.get(id_);
    }

    function getActiveLockIdByIndex(uint256 id_) public view returns (uint256) {
        return activeLocks.getKeyAtIndex(id_);
    }

    function unlockBurn(uint256 id_) public {
        require(hasRole(LOCKER_ROLE, msg.sender), "Caller is not a Locker");
        IterableMapping.SwapLock memory lock = getActiveLockById(id_);
        IAreumToken(tokenAerum).burn(lock.tokenValue);
        lock.status = 2;
        activeLocks.remove(id_);
        archivedLocks.set(id_, lock);
    }

    function unlockReturn(uint256 id_) public {
        require(hasRole(LOCKER_ROLE, msg.sender), "Caller is not a Locker");
        IterableMapping.SwapLock memory lock = getActiveLockById(id_);
        IERC20(tokenAerum).transfer(lock.owner, lock.tokenValue);
        lock.status = 3;
        activeLocks.remove(id_);
        archivedLocks.set(id_, lock);
    }

    function getArchivedLockLenght() public view returns (uint256 size) {
        return archivedLocks.getSize();
    }

    function getArchivedLockById(uint256 id_)
        public
        view
        returns (IterableMapping.SwapLock memory lock)
    {
        return archivedLocks.get(id_);
    }

    function getArchivedLockIdByIndex(uint256 id_)
        public
        view
        returns (uint256)
    {
        return archivedLocks.getKeyAtIndex(id_);
    }
}