/**
 *Submitted for verification at Etherscan.io on 2023-09-03
*/

// SPDX-License-Identifier: MIT

// File: contracts/IERC20.sol
pragma solidity ^0.8.16;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: contracts/Context.sol

pragma solidity ^0.8.16;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: contracts/Ownable.sol

pragma solidity ^0.8.16;
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.16;
contract PopoStaking is Ownable {
    IERC20 POPO;
    mapping(address => uint256) public staked;
    mapping(address => uint256) public claimalbeRewards;
    mapping(address => bool) public stakersKnown;
    address[] public stakers;
    uint256 public rounds = 1;
    uint256 public claimableTime = block.timestamp + 60 * 60 * 8;
    uint256 public claimedAmount;
    function setPopo (address _popo) public onlyOwner{
        POPO = IERC20(_popo);
    }

    function stake (uint256 amount) public {
        require(POPO.balanceOf(msg.sender)>=amount, "insufficient amount");
        POPO.transferFrom(msg.sender, address(this), amount);
        staked[msg.sender] += amount;
        if (stakersKnown[msg.sender] == false){
            stakers.push(msg.sender);
            stakersKnown[msg.sender] = true;
        }
    }

    function unstake (uint256 amount) public {
        require(staked[msg.sender]>=amount, "insufficient amount");
        POPO.transfer(msg.sender, amount);
        staked[msg.sender] -= amount;
    }

    function getCurrentRewards () public view returns(uint256 _rewards){
        _rewards = address(this).balance - claimedAmount;
        return(_rewards);
    }

    function distributeRewards() public onlyOwner{
        uint256 rewards = address(this).balance - claimedAmount;
        uint256 totalStaked = POPO.balanceOf(address(this));
         for (uint i =0; i<stakers.length; i++){
            claimalbeRewards[stakers[i]] += rewards * staked[stakers[i]] / totalStaked;
        }
        rounds ++;
        claimableTime = block.timestamp + 60 * 60 * 8;
        claimedAmount += rewards;
    }

    function resetClaimableTime() public onlyOwner{
        claimableTime = block.timestamp + 60 * 60 * 8;
    }

    function claim(address payable wallet) public{
        require(claimalbeRewards[wallet] > 0, "Nothing to Claim");
        wallet.transfer(claimalbeRewards[wallet]);
        claimedAmount -= claimalbeRewards[wallet];
        claimalbeRewards[wallet] = 0;
    }

    function emergencyWithdraw (address payable wallet) public onlyOwner{
        uint256 ETHbalance = address(this).balance;
        wallet.transfer(ETHbalance);
    }
    receive() external payable {}

}