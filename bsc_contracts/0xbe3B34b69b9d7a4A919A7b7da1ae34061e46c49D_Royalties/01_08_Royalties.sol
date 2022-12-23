// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IWETH.sol";

interface IThenian {
    function originalMinters(address) external view returns(uint);
    function totalSupply() external view returns(uint);
    function reservedAmount() external view returns(uint);
}

contract Royalties is ReentrancyGuard {

    using SafeERC20 for IERC20;

    IERC20 public wbnb;

    uint public DISTRIBUTION = 7 * 86400;

    uint256 public epoch;

    IThenian public thenian;
    address public owner;

    mapping(uint => uint) public feesPerEpoch;
    mapping(uint => uint) public totalSupply;
    mapping(uint => uint) public reservedAmounts;
    mapping(address => bool) public depositors;
    mapping(address => uint) public userCheckpoint;

    modifier onlyOwner {
        require(msg.sender == owner, 'not owner');
        _;
    }

    modifier allowed {
        require(depositors[msg.sender] == true || msg.sender == owner, 'not allowed');
        _;
    }

    event Deposit(uint256 amount);
    event VestingUpdate(uint256 balance, uint256 vesting_period, uint256 tokenPerSec);

    constructor(address _wbnb, address _thenian) {
        owner = msg.sender;
        wbnb = IERC20(_wbnb);
        thenian = IThenian(_thenian);
        epoch = 0;
    }


    function deposit(uint256 amount) external payable allowed {

        require(amount > 0 || msg.value > 0);
        uint256 _amount = 0;
        if(msg.value == 0){
            wbnb.safeTransferFrom(msg.sender, address(this), amount);
            _amount = amount;
        } else {
            IWETH(address(wbnb)).deposit{value: address(this).balance}();
            _amount = msg.value;
        }

        feesPerEpoch[epoch] = _amount;
        totalSupply[epoch] = thenian.totalSupply();
        reservedAmounts[epoch] = thenian.reservedAmount();
        epoch++;
    }

    function withdrawERC20(address _token) external onlyOwner {
        require(_token != address(0));
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, _balance);
    }


    function claim(address to) external nonReentrant {
        require(to != address(0));
        
        // get amount
        uint256 _toClaim = claimable(msg.sender);
        require(_toClaim <= wbnb.balanceOf(address(this)), 'too many rewards');
        require(_toClaim > 0, 'wait next');
        
        // update checkpoint
        userCheckpoint[msg.sender] = epoch;

        // send and enjoy
        wbnb.safeTransfer(to, _toClaim);
    }   



    function claimable(address user) public view returns(uint) {
        require(user != address(0));
        //Total fees * Thenian.originalMinters[msg.sender] / (Thenian.totalSupply - Thenian.reservedAmount)
        uint256 cp = userCheckpoint[msg.sender];
        if(cp >= epoch){
            return 0;
        }
        uint i;
        uint256 _reward = 0;
        for(i == cp; i < epoch; i++){
            uint256 _resAmnt = reservedAmounts[i];
            uint256 _tot = totalSupply[i];
            uint256 _fee = feesPerEpoch[i]; 
            uint256 weight = thenian.originalMinters(msg.sender);
            _reward += _fee * weight / (_tot - _resAmnt);
        }  
        return _reward;
    }
    
    /* 
        OWNER FUNCTIONS
    */

    function setDepositor(address depositor) external onlyOwner {
        require(depositors[depositor] == false);
        depositors[depositor] = true;
    }

    function removeDepositor(address depositor) external onlyOwner {
        require(depositors[depositor] == true);
        depositors[depositor] = false;
    }

    function setOwner(address _owner) external onlyOwner{
        require(_owner != address(0));
        owner = _owner;
    }
    

    receive() external payable {}

}