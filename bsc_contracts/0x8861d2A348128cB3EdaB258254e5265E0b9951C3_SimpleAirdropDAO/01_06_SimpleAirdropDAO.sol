// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IVotingEscrow.sol";

interface IThenian {
    function originalMinters(address) external view returns(uint);
    function totalSupply() external view returns(uint);
    function reservedAmount() external view returns(uint);
}

contract SimpleAirdropDAO {

    using SafeERC20 for IERC20;

    address public owner;
    address public secondOwner;
    address public ve;
    address public thena;

    address[] public users;

    uint256 public amountPerUser;

    modifier onlyOwner {
        require(msg.sender == owner || msg.sender == secondOwner, 'not owner');
        _;
    }


    event Deposit(uint256 amount);
    event VestingUpdate(uint256 balance, uint256 vesting_period, uint256 tokenPerSec);

    constructor() {
        owner = msg.sender;
        ve = address(0xfBBF371C9B0B994EebFcC977CEf603F7f31c070D);
        thena = address(0xF4C8E32EaDEC4BFe97E0F595AdD0f4450a863a11);
        secondOwner = address(0x1c6C2498854662FDeadbC4F14eA2f30ca305104b);
        amountPerUser = 100 * 1e18; //544.14
    }

    function setAmountPerUser(uint256 _amount) external onlyOwner {
        amountPerUser = _amount;
    }

    function distributeAirdrop() external onlyOwner {
        uint i = 0;
        address _user;
        for(i; i < users.length; i++){
            _user = users[i];
            IERC20(thena).approve(ve, 0);
            IERC20(thena).approve(ve, amountPerUser);
            IVotingEscrow(ve).create_lock_for(amountPerUser, 86400 * 365 * 2, _user);
        }
    }

    function pushUser(address[] memory _users) external onlyOwner{
        uint i = 0;
        for(i; i < _users.length; i++){
            users.push(_users[i]);
        }
    }


    function withdrawERC20(address _token) external onlyOwner {
        require(_token != address(0));
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, _balance);
    }


   
    function setOwner(address _owner) external onlyOwner{
        require(_owner != address(0));
        owner = _owner;
    }
    function setOwner2(address _owner) external onlyOwner{
        require(_owner != address(0));
        secondOwner = _owner;
    }
    

}