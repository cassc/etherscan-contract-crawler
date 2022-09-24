// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

import "../lib/IApePair.sol";
import "../lib/IMasterApe.sol";
import "../lib/IApeFactory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LPBalanceChecker is Ownable {
    address constant PCSMasterChefV2 =
        0xa5f8C5Dbd5F286960b9d90548680aE5ebFf07652;
    address[] public stakingContracts;

    struct Balances {
        address stakingAddress;
        Balance[] balances;
    }

    struct Balance {
        uint256 pid;
        address lp;
        address token0;
        address token1;
        uint256 total;
        uint256 wallet;
        uint256 staked;
    }

    constructor(address[] memory _stakingContracts) Ownable() {
        for (uint256 i = 0; i < _stakingContracts.length; i++) {
            addStakingContract(_stakingContracts[i]);
        }
    }

    function getBalance(address user)
        external
        view
        returns (Balances[] memory pBalances)
    {
        pBalances = new Balances[](stakingContracts.length);
        for (uint256 i = 0; i < stakingContracts.length; i++) {
            IMasterApe stakingContract = IMasterApe(stakingContracts[i]);
            pBalances[i].stakingAddress = address(stakingContract);

            Balance[] memory tempBalances = new Balance[](
                stakingContract.poolLength()
            );
            uint256 balanceCount;

            for (
                uint256 poolId = 0;
                poolId < stakingContract.poolLength();
                poolId++
            ) {
                address lpTokenAddress;
                if (address(stakingContract) == PCSMasterChefV2) {
                    lpTokenAddress = stakingContract.lpToken(poolId); //PCS uses lpToken() instead of poolInfo()[0]
                } else {
                    (lpTokenAddress, , , ) = stakingContract.poolInfo(poolId);
                }
                (uint256 amount, ) = stakingContract.userInfo(poolId, user);

                IApePair lpToken = IApePair(lpTokenAddress);

                Balance memory balance;
                balance.lp = lpTokenAddress;
                balance.pid = poolId;
                balance.wallet = lpToken.balanceOf(user);
                balance.staked = amount;
                balance.total = balance.wallet + balance.staked;

                tempBalances[poolId] = balance;
            }

            for (
                uint256 balanceIndex = 0;
                balanceIndex < tempBalances.length;
                balanceIndex++
            ) {
                if (tempBalances[balanceIndex].total > 0) {
                    balanceCount++;
                }
            }

            Balance[] memory balances = new Balance[](balanceCount);
            uint256 newIndex = 0;

            for (
                uint256 balanceIndex = 0;
                balanceIndex < tempBalances.length;
                balanceIndex++
            ) {
                if (tempBalances[balanceIndex].total > 0) {
                    IApePair lpToken = IApePair(tempBalances[newIndex].lp);
                    try lpToken.token0() returns (address _token0) {
                        tempBalances[newIndex].token0 = _token0;
                    } catch (bytes memory) {
                        continue;
                    }
                    try lpToken.token1() returns (address _token1) {
                        tempBalances[newIndex].token1 = _token1;
                    } catch (bytes memory) {
                        continue;
                    }

                    balances[newIndex] = tempBalances[balanceIndex];
                    newIndex++;
                }
            }

            pBalances[i].balances = balances;
        }
    }

    function removeStakingContract(uint256 index) external onlyOwner {
        require(index < stakingContracts.length);
        stakingContracts[index] = stakingContracts[stakingContracts.length - 1];
        stakingContracts.pop();
    }

    function addStakingContract(address stakingContract) public onlyOwner {
        stakingContracts.push(stakingContract);
    }
}