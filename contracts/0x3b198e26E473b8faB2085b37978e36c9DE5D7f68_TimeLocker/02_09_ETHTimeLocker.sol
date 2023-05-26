// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./utils/token/SafeERC20.sol";
import "./utils/ECDSA.sol";
import "./Validators.sol";

contract TimeLocker is Validators {

    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    event Locked(address indexed _from, uint256 indexed _toChainId, uint256 indexed _lockId, uint256 _amount);
    event Unlocked(address indexed _from, uint256 indexed _fromChainId, uint256 indexed _burnId, uint256 _amount);

    IERC20 public erc20Time;
    bool private initialized;

    uint256 public lastLockId;
    mapping(uint256 =>  mapping(uint256 => bool)) public burnIdsUsed;

    function init(address _erc20Time) external onlyOwner {
        require(!initialized, "Initialized");
        erc20Time = IERC20(_erc20Time);
        initialized = true;
    }

    function onTokenTransfer(address _sender, uint256 _amount, bytes memory _data) external {
        require(address(erc20Time) == _msgSender(), "Sender address does not match expected");
        require(_amount > 0, "The amount of the lock must not be zero");
        (uint256 _toChainId) = abi.decode(_data, (uint256));
        (bool found,) = indexOfChainId(_toChainId);
        require(found, "ChainId not allowed");
        lastLockId ++;
        emit Locked(_sender, _toChainId, lastLockId, _amount);
    }

    function lock(uint256 _toChainId, uint256 _amount) external {
        require(_amount > 0, "The amount of the lock must not be zero");
        (bool found,) = indexOfChainId(_toChainId);
        require(found, "ChainId not allowed");
        require(erc20Time.allowance(_msgSender(), address(this)) >= _amount, "Not enough allowance");
        erc20Time.safeTransferFrom(_msgSender(), address(this), _amount);
        lastLockId ++;
        emit Locked(_msgSender(), _toChainId, lastLockId, _amount);
    }

    function unlock(uint256 _fromChainId, uint256 _burnId, uint256 _amount, bytes[] memory _signatures) external {
        require(!burnIdsUsed[_fromChainId][_burnId], "Burn id already used");
        bytes32 messageHash = keccak256(abi.encodePacked(_msgSender(), _fromChainId, block.chainid, _burnId, _amount));
        require(checkSignatures(messageHash, _signatures), "Incorrect signature(s)");
        burnIdsUsed[_fromChainId][_burnId] = true;
        erc20Time.safeTransfer(_msgSender(), _amount);
        emit Unlocked(_msgSender(), _fromChainId, _burnId, _amount);
    }
}