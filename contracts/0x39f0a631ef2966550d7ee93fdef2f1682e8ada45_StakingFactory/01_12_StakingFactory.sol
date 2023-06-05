//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IVault.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IStakingFactory.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakingFactory is AccessControl, IStruct, IStakingFactory {
    bytes32 public constant STAKING_ROLE = keccak256("STAKING_ROLE");

    address public masterStaking;
    address public vault;

    address[] public allPools;
    mapping(address => address[]) public userStakes;
    // pool -> (user -> index and status)
    mapping(address => mapping(address => PoolStatus)) private userPoolIndexies;

    struct PoolStatus {
        bool status;
        uint256 index;
    }

    modifier initialized() {
        require(
            masterStaking != address(0) && vault != address(0),
            "Initialize"
        );
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Only admin");
        _;
    }

    modifier onlyStaking() {
        require(hasRole(STAKING_ROLE, _msgSender()), "Only admin");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function initialize(address _masterStaking, address _vault)
        external
        onlyAdmin
    {
        require(masterStaking == address(0) && _masterStaking != address(0));
        require(vault == address(0) && _vault != address(0));
        masterStaking = _masterStaking;
        vault = _vault;
    }

    function createStaking(GeneralVariables memory _generalInfo)
        external
        initialized
        onlyAdmin
    {
        require(
            _generalInfo.openTime < _generalInfo.closeTime &&
                _generalInfo.openTime > block.timestamp &&
                _generalInfo.APR > 0 &&
                _generalInfo.maxStakeAmount > 0 &&
                _generalInfo.maxGoalOfStaking > _generalInfo.maxStakeAmount,
            "Wrong params"
        );

        address newStaking = Clones.clone(masterStaking);
        IStaking(newStaking).initStaking(_generalInfo);
        IVault(vault).setStaking(newStaking);
        _setupRole(STAKING_ROLE, newStaking);
        allPools.push(newStaking);
    }

    function addUserStaking(address user) external override onlyStaking {
        address pool = _msgSender();
        PoolStatus storage poolInfo = userPoolIndexies[pool][user];
        if (!poolInfo.status) {
            poolInfo.status = true;
            poolInfo.index = userStakes[user].length;
            userStakes[user].push(pool);
        }
    }

    function removeUserStaking(address user) external override onlyStaking {
        address pool = _msgSender();
        PoolStatus storage poolInfo = userPoolIndexies[pool][user];
        require(poolInfo.status);
        uint256 lastIndex = userStakes[user].length - 1;
        if (poolInfo.index != lastIndex) {
            address lastPool = userStakes[user][lastIndex];
            userStakes[user][poolInfo.index] = lastPool;
            userPoolIndexies[lastPool][user].index = poolInfo.index;
        }
        userStakes[user].pop();
        poolInfo.status = false;
        poolInfo.index = 0;
    }

    function getUserStakes(address usr)
        external
        view
        returns (address[] memory)
    {
        return userStakes[usr];
    }

    function getUserStakesLength(address usr)
        external
        view
        returns (uint256)
    {
        return userStakes[usr].length;
    }
}