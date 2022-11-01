// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

import "../lib/IApePair.sol";
import "../lib/IMasterApe.sol";
import "../lib/IApeFactory.sol";
import "../lib/IPoolManager.sol";
import "../lib/IBEP20RewardApeV6.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LPBalanceChecker is Ownable {
    address constant PCSMasterChefV2 =
        0xa5f8C5Dbd5F286960b9d90548680aE5ebFf07652;
    IMasterApe constant masterApe =
        IMasterApe(0x5c8D727b265DBAfaba67E050f2f739cAeEB4A6F9);
    IPoolManager constant poolManager =
        IPoolManager(0x36524d6A9FB579A0b046edfC691ED47C2de5B8bf);

    address[] public stakingContracts;

    mapping(address => IApeFactory) stakingContractToFactory;

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

    constructor(
        address[] memory _stakingContracts,
        IApeFactory[] memory _factoryContract
    ) Ownable() {
        for (uint256 i = 0; i < _stakingContracts.length; i++) {
            addStakingContract(_stakingContracts[i], _factoryContract[i]);
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

            uint256 poolLength = stakingContract.poolLength();
            uint256 apeSwapPoolLength = masterApe.poolLength();
            uint256 apeSwapJFPoolsCount = poolManager.getActivePoolCount();

            Balance[] memory tempBalances = new Balance[](
                poolLength + apeSwapPoolLength + apeSwapJFPoolsCount
            );

            for (uint256 poolId = 0; poolId < poolLength; poolId++) {
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
                try lpToken.token0() returns (address _token0) {
                    balance.token0 = _token0;
                } catch (bytes memory) {}
                try lpToken.token1() returns (address _token1) {
                    balance.token1 = _token1;
                } catch (bytes memory) {}

                tempBalances[poolId] = balance;
            }

            {
                for (uint256 poolId = 0; poolId < apeSwapPoolLength; poolId++) {
                    address lpTokenAddress;
                    (lpTokenAddress, , , ) = masterApe.poolInfo(poolId);
                    IApePair apeLpToken = IApePair(lpTokenAddress);

                    Balance memory balance;
                    try apeLpToken.token0() returns (address _token0) {
                        balance.token0 = _token0;
                    } catch (bytes memory) {}
                    try apeLpToken.token1() returns (address _token1) {
                        balance.token1 = _token1;
                    } catch (bytes memory) {}

                    if (
                        balance.token0 != address(0) &&
                        balance.token1 != address(0)
                    ) {
                        lpTokenAddress = stakingContractToFactory[
                            address(stakingContract)
                        ].getPair(balance.token0, balance.token1);

                        bool add = true;
                        if (lpTokenAddress != address(0)) {
                            for (uint256 n = 0; n < poolLength; n++) {
                                if (tempBalances[n].lp == lpTokenAddress) {
                                    add = false;
                                    break;
                                }
                            }

                            if (add) {
                                balance.lp = lpTokenAddress;
                                balance.wallet = IApePair(lpTokenAddress)
                                    .balanceOf(user);
                                balance.total = balance.wallet;
                            }
                        }
                    }

                    tempBalances[poolLength + poolId] = balance;
                }
            }

            {
                address[] memory apeSwapJFPools = poolManager.allActivePools();
                for (
                    uint256 poolId = 0;
                    poolId < apeSwapJFPoolsCount;
                    poolId++
                ) {
                    address lpTokenAddress;
                    try
                        IBEP20RewardApeV6(apeSwapJFPools[poolId]).STAKE_TOKEN()
                    returns (address _lpTokenAddress) {
                        lpTokenAddress = _lpTokenAddress;
                    } catch (bytes memory) {
                        continue;
                    }

                    IApePair apeLpToken = IApePair(lpTokenAddress);

                    Balance memory balance;
                    try apeLpToken.token0() returns (address _token0) {
                        balance.token0 = _token0;
                    } catch (bytes memory) {}
                    try apeLpToken.token1() returns (address _token1) {
                        balance.token1 = _token1;
                    } catch (bytes memory) {}

                    if (
                        balance.token0 != address(0) &&
                        balance.token1 != address(0)
                    ) {
                        lpTokenAddress = stakingContractToFactory[
                            address(stakingContract)
                        ].getPair(balance.token0, balance.token1);

                        bool add = true;
                        if (lpTokenAddress != address(0)) {
                            for (
                                uint256 n = 0;
                                n < poolLength + apeSwapPoolLength;
                                n++
                            ) {
                                if (tempBalances[n].lp == lpTokenAddress) {
                                    add = false;
                                    break;
                                }
                            }

                            if (add) {
                                balance.lp = lpTokenAddress;
                                balance.wallet = IApePair(lpTokenAddress)
                                    .balanceOf(user);
                                balance.total = balance.wallet;
                            }
                        }
                    }

                    tempBalances[
                        poolLength + apeSwapPoolLength + poolId
                    ] = balance;
                }
            }

            uint256 balanceCount;
            for (
                uint256 balanceIndex = 0;
                balanceIndex < tempBalances.length;
                balanceIndex++
            ) {
                if (
                    tempBalances[balanceIndex].total > 0 &&
                    tempBalances[balanceIndex].token0 != address(0)
                ) {
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
                if (
                    tempBalances[balanceIndex].total > 0 &&
                    tempBalances[balanceIndex].token0 != address(0)
                ) {
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

    function addStakingContract(
        address stakingContract,
        IApeFactory factoryContract
    ) public onlyOwner {
        stakingContracts.push(stakingContract);
        stakingContractToFactory[stakingContract] = factoryContract;
    }
}