// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "./StakingPool101.sol";

contract StakeMaster is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Burnable;
    using SafeERC20 for IERC20;

    address[] pools;

    event StakingPoolCreated(address owner, address pool, address stakingToken, address poolToken, uint256 startTime, uint256 finishTime, uint256 poolTokenAmount);

    function createStakingPool(
        IERC20 _stakingToken,
        IERC20 _poolToken,
        uint256 _startTime,
        uint256 _finishTime,
        uint256 _poolTokenAmount,
        bool _hasWhitelisting
    ) external onlyOwner {

        StakingPool stakingPool =
        new StakingPool(
            _stakingToken,
            _poolToken,
            _startTime,
            _finishTime,
            _poolTokenAmount,
            _hasWhitelisting
        );
        stakingPool.transferOwnership(msg.sender);

        _poolToken.safeTransferFrom(
            msg.sender,
            address(stakingPool),
            _poolTokenAmount
        );

        require(_poolToken.balanceOf(address(stakingPool)) == _poolTokenAmount, "Unsupported token");

        pools.push(address(stakingPool));

        emit StakingPoolCreated(msg.sender, address(stakingPool), address(_stakingToken), address(_poolToken), _startTime, _finishTime, _poolTokenAmount);
    }

    function getPools() public view returns (address[] memory) {
        return pools;
    }

    function addPools(address[] calldata _addrs) external onlyOwner {
        uint arrayLength = _addrs.length;
        for (uint i = 0; i < arrayLength; i++) {
            pools.push(_addrs[i]);
        }
    }

    function removePool(address _pool) external onlyOwner {
        uint index;
        for (uint i = 0; i < pools.length; i++) {
            if (pools[i] == _pool) {
                index = i;
                for (; index < pools.length - 1; index++) {
                    pools[index] = pools[index + 1];
                }
                pools.pop();
                return;
            }
        }
    }

    // ============ Version Control ============
    function version() external pure returns (uint256) {
        return 101;
        // 1.0.1
    }
}