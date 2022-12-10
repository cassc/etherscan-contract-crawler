// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./utils/Utilities.sol";
import "./interfaces/IRevanentStaking.sol";

contract TheModernEthereumTreasury is Ownable, Utilities {

    IERC20 public tme;
    address public staking;

    struct Reward {
        address token;
        uint256 allocPoint;
    }

    uint256 public totalAllocPoint;

    uint256[] public pids;
    mapping (uint256 => Reward) public rewardList;

    receive() external payable {}

    function setTme(address _tme) external onlyOwner {
        tme = IERC20(_tme);
    }

    function setStaking(address _staking) external onlyOwner {
        staking = _staking;
    }

    function addRewardToken(uint256 _pid, address _token, uint _allocPoint) external onlyOwner {
        require(_token != address(0), '!zero address');
        rewardList[_pid] = Reward({
            token: _token,
            allocPoint: _allocPoint
        });

        totalAllocPoint += _allocPoint;
        pids.push(_pid);
    }

    function updateRewardToken(uint256 _pid, address _token, uint _allocPoint) external onlyOwner {
        require(_token != address(0), '!zero address');
        Reward storage reward = rewardList[_pid];
        totalAllocPoint = totalAllocPoint - reward.allocPoint + _allocPoint;
        reward.token = _token;
        reward.allocPoint = _allocPoint;
    }

    function removeRewardToken(uint256 _pid) external onlyOwner {
        Reward storage reward = rewardList[_pid];
        totalAllocPoint -= reward.allocPoint;
        reward.token = address(0);
        reward.allocPoint = 0;
        uint index = 0;
        for(uint i = 0; i < pids.length - 1; i++){
            if (pids[i] == _pid) {
                index = 0;
            }
        }

        for(uint i = index; i < pids.length - 1; i++){
            pids[i] = pids[i + 1];
        }
        pids.pop();
    }

    function swapAndDistribution() external onlyOwner {
        uint balance = address(this).balance;
        for (uint i = 0; i < pids.length; i++) {
            Reward memory reward = rewardList[pids[i]];
            uint share = balance * reward.allocPoint / totalAllocPoint;
            address weth = IUniswapV2Router02(uniswapRouter).WETH();
            address[] memory path = new address[](2);
            path[0] = weth;
            path[1] = reward.token;
            IUniswapV2Router02(uniswapRouter).swapExactETHForTokensSupportingFeeOnTransferTokens{value: share}(0, path, staking, block.timestamp);
        }

        IRevanentStaking(staking).massUpdatePools();
    }

    function withdrawFunds() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}