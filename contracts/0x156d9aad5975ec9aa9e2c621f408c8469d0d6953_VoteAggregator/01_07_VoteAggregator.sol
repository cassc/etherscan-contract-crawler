// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../common/Constants.sol";

interface IGROVesting {
    function vestedBalance(address account) external view returns (uint256);

    function vestingBalance(address account) external view returns (uint256);
}

interface IGROBaseVesting {
    function totalBalance(address account) external view returns (uint256);

    function vestedBalance(address account) external view returns (uint256 vested, uint256 available);
}

struct UserInfo {
    uint256 amount;
    int256 rewardDebt;
}

interface IGROStaker {
    function userInfo(uint256 poolId, address account) external view returns (UserInfo memory);
}

interface IGROStakerMigration {
    function userMigrated(address account, uint256 poolId) external view returns (bool);
}

interface IUniswapV2Pool {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );
}

interface IBalanceVault {
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );
}

interface IBalanceV2Pool {
    function getVault() external view returns (IBalanceVault);

    function getPoolId() external view returns (bytes32);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

contract VoteAggregator is Ownable, Constants {
    IERC20 public immutable GRO;
    IGROVesting public mainVesting;
    IGROBaseVesting public empVesting;
    IGROBaseVesting public invVesting;
    address public stakerOld;
    address public stakerNew;

    // Make 0 pool in staker for single gro always
    uint256 public constant SINGLE_GRO_POOL_ID = 0;

    IUniswapV2Pool[] public uniV2Pools;
    IBalanceV2Pool[] public balV2Pools;

    // weight decimals is 4
    uint256 public groWeight;
    mapping(address => uint256[2]) public vestingWeights;
    mapping(address => uint256[]) public lpWeights;

    mapping(address => uint256) public groPools;

    event LogSetGroWeight(uint256 newWeight);
    event LogSetVestingWeight(address indexed vesting, uint256 newLockedWeight, uint256 newUnlockedWeight);
    event LogAddUniV2Pool(address pool, uint256[] weights, uint256 groPoolId);
    event LogRemoveUniV2Pool(address pool);
    event LogAddBalV2Pool(address pool, uint256[] weights, uint256 groPoolId);
    event LogRemoveBalV2Pool(address pool);
    event LogSetLPPool(address indexed pool, uint256[] weights, uint256 groPoolId);

    event LogSetMainVesting(address newVesting);
    event LogSetInvVesting(address newVesting);
    event LogSetEmpVesting(address newVesting);
    event LogSetOldStaker(address staker);
    event LogSetNewStaker(address staker);

    constructor(
        address _gro,
        address _mainVesting,
        address _empVesting,
        address _invVesting,
        address _stakerOld,
        address _stakerNew
    ) {
        GRO = IERC20(_gro);
        mainVesting = IGROVesting(_mainVesting);
        empVesting = IGROBaseVesting(_empVesting);
        invVesting = IGROBaseVesting(_invVesting);
        stakerOld = _stakerOld;
        stakerNew = _stakerNew;
    }

    function setMainVesting(address newVesting) external onlyOwner {
        mainVesting = IGROVesting(newVesting);
        emit LogSetMainVesting(newVesting);
    }

    function setInvVesting(address newVesting) external onlyOwner {
        invVesting = IGROBaseVesting(newVesting);
        emit LogSetInvVesting(newVesting);
    }

    function setEmpVesting(address newVesting) external onlyOwner {
        empVesting = IGROBaseVesting(newVesting);
        emit LogSetEmpVesting(newVesting);
    }

    function setOldStaker(address staker) external onlyOwner {
        stakerOld = staker;
        emit LogSetOldStaker(staker);
    }

    function setNewStaker(address staker) external onlyOwner {
        stakerNew = staker;
        emit LogSetNewStaker(staker);
    }

    function setGroWeight(uint256 weight) external onlyOwner {
        groWeight = weight;
        emit LogSetGroWeight(weight);
    }

    function setVestingWeight(
        address vesting,
        uint256 lockedWeight,
        uint256 unlockedWeight
    ) external onlyOwner {
        vestingWeights[vesting][0] = lockedWeight;
        vestingWeights[vesting][1] = unlockedWeight;
        emit LogSetVestingWeight(vesting, lockedWeight, unlockedWeight);
    }

    function addUniV2Pool(
        address pool,
        uint256[] calldata weights,
        uint256 groPoolId
    ) external onlyOwner {
        lpWeights[pool] = weights;
        groPools[pool] = groPoolId;
        uniV2Pools.push(IUniswapV2Pool(pool));
        emit LogAddUniV2Pool(pool, weights, groPoolId);
    }

    function removeUniV2Pool(address pool) external onlyOwner {
        uint256 len = uniV2Pools.length;
        bool find;
        for (uint256 i = 0; i < len - 1; i++) {
            if (find) {
                uniV2Pools[i] = uniV2Pools[i + 1];
            } else {
                if (pool == address(uniV2Pools[i])) {
                    find = true;
                    uniV2Pools[i] = uniV2Pools[i + 1];
                }
            }
        }
        uniV2Pools.pop();
        delete lpWeights[pool];
        delete groPools[pool];
        emit LogRemoveUniV2Pool(pool);
    }

    function addBalV2Pool(
        address pool,
        uint256[] calldata weights,
        uint256 groPoolId
    ) external onlyOwner {
        lpWeights[pool] = weights;
        groPools[pool] = groPoolId;
        balV2Pools.push(IBalanceV2Pool(pool));
        emit LogAddBalV2Pool(pool, weights, groPoolId);
    }

    function removeBalV2Pool(address pool) external onlyOwner {
        uint256 len = balV2Pools.length;
        bool find;
        for (uint256 i = 0; i < len - 1; i++) {
            if (find) {
                balV2Pools[i] = balV2Pools[i + 1];
            } else {
                if (pool == address(balV2Pools[i])) {
                    find = true;
                    balV2Pools[i] = balV2Pools[i + 1];
                }
            }
        }
        balV2Pools.pop();
        delete lpWeights[pool];
        delete groPools[pool];
        emit LogRemoveBalV2Pool(pool);
    }

    function setLPPool(
        address pool,
        uint256[] calldata weights,
        uint256 groPoolId
    ) external onlyOwner {
        if (weights.length > 0) {
            lpWeights[pool] = weights;
        }
        if (groPoolId > 0) {
            groPools[pool] = groPoolId;
        }
        emit LogSetLPPool(pool, weights, groPoolId);
    }

    function balanceOf(address account) external view returns (uint256 value) {
        // calculate gro weight amount

        uint256 amount = GRO.balanceOf(account);
        amount += getLPAmountInStaker(SINGLE_GRO_POOL_ID, account);
        value = (amount * groWeight) / PERCENTAGE_DECIMAL_FACTOR;

        // calculate vesting weight amount

        // vestings[0] - main vesting address
        // vestings[1] - employee vesting address
        // vestings[2] - investor vesting address
        address[3] memory vestings;
        // amounts[0][0] - main vesting locked amount
        // amounts[0][1] - main vesting unlocked amount
        // amounts[1][0] - employee vesting locked amount
        // amounts[1][1] - employee vesting unlocked amount
        // amounts[2][0] - investor vesting locked amount
        // amounts[2][1] - investor vesting unlocked amount
        uint256[2][3] memory amounts;

        vestings[0] = address(mainVesting);
        amounts[0][0] = mainVesting.vestingBalance(account);
        amounts[0][1] = mainVesting.vestedBalance(account);

        uint256 totalUnlocked;
        amounts[1][0] = empVesting.totalBalance(account);
        if (amounts[1][0] > 0) {
            (totalUnlocked, amounts[1][1]) = empVesting.vestedBalance(account);
            amounts[1][0] = amounts[1][0] - totalUnlocked;
            vestings[1] = address(empVesting);
        }

        amounts[2][0] = invVesting.totalBalance(account);
        if (amounts[2][0] > 0) {
            (totalUnlocked, amounts[2][1]) = invVesting.vestedBalance(account);
            amounts[2][0] = amounts[2][0] - totalUnlocked;
            vestings[2] = address(invVesting);
        }

        for (uint256 i = 0; i < vestings.length; i++) {
            if (amounts[i][0] > 0 || amounts[i][1] > 0) {
                uint256[2] storage weights = vestingWeights[vestings[i]];
                uint256 lockedWeight = weights[0];
                uint256 unlockedWeight = weights[1];
                value += (amounts[i][0] * lockedWeight + amounts[i][1] * unlockedWeight) / PERCENTAGE_DECIMAL_FACTOR;
            }
        }

        value += calculateUniWeight(account);
        value += calculateBalWeight(account);
    }

    function calculateUniWeight(address account) public view returns (uint256 uniValue) {
        uint256 len = uniV2Pools.length;
        for (uint256 i = 0; i < len; i++) {
            IUniswapV2Pool pool = uniV2Pools[i];
            uint256 lpAmount = pool.balanceOf(account);
            lpAmount += getLPAmountInStaker(address(pool), account);

            if (lpAmount > 0) {
                (uint112 res0, uint112 res1, ) = pool.getReserves();
                uint256 ts = pool.totalSupply();
                uint256[] memory amounts = new uint256[](2);
                amounts[0] = res0;
                amounts[1] = res1;
                address[] memory tokens = new address[](2);
                tokens[0] = pool.token0();
                tokens[1] = pool.token1();
                uint256[] memory weights = lpWeights[address(pool)];

                uniValue += calculateLPWeightValue(amounts, lpAmount, ts, tokens, weights);
            }
        }
    }

    function calculateBalWeight(address account) public view returns (uint256 balValue) {
        uint256 len = balV2Pools.length;
        for (uint256 i = 0; i < len; i++) {
            IBalanceV2Pool pool = balV2Pools[i];
            uint256 lpAmount = pool.balanceOf(account);
            lpAmount += getLPAmountInStaker(address(pool), account);

            if (lpAmount > 0) {
                IBalanceVault vault = pool.getVault();
                bytes32 poolId = pool.getPoolId();
                (address[] memory tokens, uint256[] memory balances, ) = vault.getPoolTokens(poolId);
                uint256 ts = pool.totalSupply();
                uint256[] memory weights = lpWeights[address(pool)];

                balValue += calculateLPWeightValue(balances, lpAmount, ts, tokens, weights);
            }
        }
    }

    function getUniV2Pools() external view returns (IUniswapV2Pool[] memory) {
        return uniV2Pools;
    }

    function getBalV2Pools() external view returns (IBalanceV2Pool[] memory) {
        return balV2Pools;
    }

    function getVestingWeights(address vesting) external view returns (uint256[2] memory) {
        return vestingWeights[vesting];
    }

    function getLPWeights(address pool) external view returns (uint256[] memory) {
        return lpWeights[pool];
    }

    function getLPAmountInStaker(address lpPool, address account) private view returns (uint256 amount) {
        uint256 poolId = groPools[lpPool];
        if (poolId > 0) {
            amount = getLPAmountInStaker(poolId, account);
        }
    }

    function getLPAmountInStaker(uint256 poolId, address account) private view returns (uint256 amount) {
        UserInfo memory ui = IGROStaker(stakerNew).userInfo(poolId, account);
        amount = ui.amount;
        if (stakerOld != address(0) && !IGROStakerMigration(stakerNew).userMigrated(account, poolId)) {
            ui = IGROStaker(stakerOld).userInfo(poolId, account);
            amount += ui.amount;
        }
    }

    function calculateLPWeightValue(
        uint256[] memory tokenAmounts,
        uint256 lpAmount,
        uint256 lpTotalSupply,
        address[] memory tokens,
        uint256[] memory weights
    ) private view returns (uint256 value) {
        for (uint256 i = 0; i < tokenAmounts.length; i++) {
            uint256 amount = (tokenAmounts[i] * lpAmount) / lpTotalSupply;
            uint256 decimals = ERC20(tokens[i]).decimals();
            uint256 weight = weights[i];

            value += (amount * weight * DEFAULT_DECIMALS_FACTOR) / (uint256(10)**decimals) / PERCENTAGE_DECIMAL_FACTOR;
        }
    }
}