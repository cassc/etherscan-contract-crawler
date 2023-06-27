// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract TimelockDemo is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public contractOwner;
    uint256 public publicFee = 0.05 ether;

    struct Item {
        string lockName;
        address lockOwner;
        address lpToken;
        uint256 lpAmount;
        uint256 unlockTime;
        bool withdrawn;
    }

    mapping (address => Item[]) public ownerLocks;
    Item[] public totalLocks;

    constructor () {
        contractOwner = msg.sender;
    }

    modifier onlyContractOwner() {
        require(msg.sender == contractOwner, 'Only owner can call this function');
        _;
    }

    function createLPLock (
        string memory _lpLockName,
        address _lpToken,
        uint256 _lpAmount,
        uint256 _unlockTime
    ) external payable returns (uint256 _id) {
        require(_lpAmount > 0, "LP tokens amount must be greater than 0.");
        require(_unlockTime < 10000000000, 'Unix timestamp must be in seconds, not milliseconds.');
        require(_unlockTime > block.timestamp, 'Unlock time must be in future.');
        require(msg.value >= publicFee, 'ETH fee not provided');

         IERC20 lpToken = IERC20(_lpToken);
        lpToken.safeTransferFrom(msg.sender, address(this), _lpAmount);

        uint256 fee = msg.value;
        payTo(owner(), fee);

        uint256 id = totalLocks.length;
        Item memory lock = Item(_lpLockName, msg.sender, _lpToken, _lpAmount, _unlockTime, false);
        ownerLocks[msg.sender].push(lock);
        totalLocks.push(lock);

        return id;
    }
 
    function withdraw(uint256 _id) external {
        require(ownerLocks[msg.sender].length > 0, "You haven't made any lock.");
        require(_id < totalLocks.length, "Invalid lock ID.");

        Item storage lock = totalLocks[_id];
        require(lock.lockOwner == msg.sender, "You are not the owner of this lock.");
        require(!lock.withdrawn, "Tokens have already been withdrawn.");
        require(lock.unlockTime <= block.timestamp, "Tokens are still locked.");

        IERC20 lpToken = IERC20(lock.lpToken);
        lpToken.safeTransfer(msg.sender, lock.lpAmount);
        lock.withdrawn = true;
    }
    
    function transferLockOwnership(uint _id, address _newOwner) external {
        require(_id < totalLocks.length, "Invalid lock ID.");

        Item storage lock = totalLocks[_id];
        require(lock.lockOwner == msg.sender, "You are not the owner of this lock.");

         lock.lockOwner = _newOwner;
         ownerLocks[msg.sender].push(lock);
    }

    function getTotalLocks() public view returns(Item[] memory){
        return totalLocks;
    }

   function setLockingFee(uint price) public onlyOwner {
      require(price > 0, "Price must be greater than zero");
      publicFee = price;
    }

   function payTo(address _to, uint256 _amount) internal returns (bool) {
       (bool success,) = payable(_to).call{value: _amount}("");
       require(success, "Payment failed");
       return true;
   }
}