// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vesting is Ownable {
    uint256 public vestingTime = 7 days; // 7 days
    uint256 public vestingInit;
    address public tokenAddress;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastClaimed;

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    function setVestingInit() public onlyOwner {
        vestingInit = block.timestamp;
    }

    function setAllocation(address _address, uint256 _amount) public onlyOwner {
        balances[_address] = _amount;
        lastClaimed[_address] = vestingInit;
    }

    function setAllocationBulk(address[] memory _addresses, uint256[] memory _amounts) public onlyOwner {
        require((_addresses.length == _amounts.length) || _amounts.length == 1 , "Array length mismatch");
        for (uint256 i = 0; i < _addresses.length; i++) {
            if(_amounts.length > 1) {
                balances[_addresses[i]] = _amounts[i];
            }else{
                balances[_addresses[i]] = _amounts[0];
            }
            lastClaimed[_addresses[i]] = vestingInit;
        }
    }

    function blacklist(address _address) public onlyOwner {
        balances[_address] = 0;
    }

    function deposit(uint256 _amount) public {
        IERC20 token = IERC20(tokenAddress);
        require(token.allowance(msg.sender, address(this)) >= _amount, "Not enough allowance");
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
    }

    function claim() public {
        IERC20 token = IERC20(tokenAddress);
        uint256 amount = availableAmount(msg.sender);
        require(amount > 0, "No tokens available");

        balances[msg.sender] -= amount;
        lastClaimed[msg.sender] = block.timestamp;
        token.transfer(msg.sender, amount);
    }

    function emergencyWithdraw() public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function availableAmount(address _address) public view returns (uint256) {
        uint256 timePassed = block.timestamp - lastClaimed[_address];
        uint256 timeSinceVestingInit = block.timestamp - vestingInit;

        if (timeSinceVestingInit >= vestingTime) {
            return balances[_address];
        } else {
            return (balances[_address] * timePassed) / vestingTime;
        }
    }
}