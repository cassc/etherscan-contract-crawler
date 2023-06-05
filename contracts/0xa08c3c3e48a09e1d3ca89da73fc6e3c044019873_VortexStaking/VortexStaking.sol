/**
 *Submitted for verification at Etherscan.io on 2023-05-30
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(
            address from,
            address to,
            uint256 amount
        ) external returns (bool);
}

contract VortexStaking {

        uint256 public      yieldRate = 180; // % APY
        uint256 public      yieldFund;
        uint256 public      min_staking_period; // in days
        address public      stakeTokenAddress;
        uint256 public      endStakeDate;
        address internal    _owner;

        struct Farmers {
           uint256 money;
           uint256 timestamp;
        }
        mapping(address => Farmers) public farmers;
        
        constructor(address _StakeToken) {
            _owner = msg.sender;
            endStakeDate = block.timestamp + 24*3600*31;
            stakeTokenAddress = _StakeToken;
        }
        modifier onlyOwner() {
            require(_owner == msg.sender, "Ownable: caller is not the owner");
            _;
        }
        function depositFund(uint256 amount) public {
            yieldFund = yieldFund + amount;
            IERC20(stakeTokenAddress).transferFrom(msg.sender, address(this), amount);
        }
        function deposit(uint256 amount) public {
            require(endStakeDate > block.timestamp);
            address user = msg.sender;
            if (getUserYield(user) > 0) {
                 claimTokens();
            }
            IERC20(stakeTokenAddress).transferFrom(msg.sender, address(this), amount);
            farmers[user].timestamp = block.timestamp;
            farmers[user].money += amount; 
        }
        function claimTokens() public {
            //require(yieldFund  > getUserYield(msg.sender), "Not enough yield fund");
            if (yieldFund  > getUserYield(msg.sender)) {
                yieldFund = yieldFund -  getUserYield(msg.sender);
                IERC20(stakeTokenAddress).transfer(msg.sender, getUserYield(msg.sender));
                farmers[msg.sender].timestamp = block.timestamp;     
            } else {               
                IERC20(stakeTokenAddress).transfer(msg.sender, yieldFund);
                yieldFund = 0;
                farmers[msg.sender].timestamp = block.timestamp; 
            }         
        }
        function unstake() public {
            require(farmers[msg.sender].timestamp + min_staking_period * 3600*24 < block.timestamp, "Minimum staking period has not expired");
            address user = msg.sender;
            IERC20(stakeTokenAddress).transfer(user, farmers[user].money);
            claimTokens();
            farmers[user].money = 0;
        }
        function getUserYield(address user)  public view returns (uint256) {
              return yieldFund  > 0? (timestamp() - farmers[user].timestamp) * farmers[user].money * yieldRate / (100*3600*24*365) : 0;
        }

        function timestamp()  public view returns (uint256) {
             return endStakeDate > block.timestamp? block.timestamp : endStakeDate;
        }

        function setYieldRate(uint256  _yieldRate) public onlyOwner {
              yieldRate = _yieldRate;
        }

        function set_endStakeDate(uint256  _endStakeDate) public onlyOwner {
              endStakeDate = _endStakeDate;
        }

        function set_min_staking_period(uint256  _min_staking_period) public onlyOwner {
              min_staking_period = _min_staking_period;
        }

        function withdraw() external onlyOwner {
              IERC20(stakeTokenAddress).transfer(msg.sender,  yieldFund);
              yieldFund = 0;
        }
}