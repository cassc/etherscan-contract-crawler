// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IStrongXMiningPool.sol";

contract StrongXMiningPoolManager is ReentrancyGuard, AccessControl {
    using SafeMath for uint;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    IERC20 public immutable token;
    address[] public pools;
    uint public poolsLength;

    address private singleAssetPool;
    address private immutable admin;

    constructor (
        address _token
    ) {
        admin = _msgSender();
        token = IERC20(_token);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
    }

    /** VIEW FUNCTIONS */

    function earned(address account) public view returns (uint rewards) {
        for (uint index = 0; index < poolsLength; index++) {
            rewards = rewards.add(IStrongXMiningPool(pools[index]).earned(account));
        }
    }

    /** PUBLIC FUNCTIONS */

    function stake(address pool, uint amount) external nonReentrant {
        _stake(pool, _msgSender(), amount, false);
    }

    function withdraw(address pool, uint amount) external nonReentrant {
        _withdraw(pool, _msgSender(), amount);
    }

    function claim() external nonReentrant {
        for (uint index = 0; index < poolsLength; index++) {
            IStrongXMiningPool(pools[index]).claim(_msgSender(), false);
        }
    }

    function compound() external nonReentrant {
        uint rewards = earned(_msgSender());

        if (rewards > 0) {
            for (uint index = 0; index < poolsLength; index++) {
                IStrongXMiningPool(pools[index]).claim(_msgSender(), true);
            }

            token.approve(singleAssetPool, rewards);
            _stake(singleAssetPool, _msgSender(), rewards, true);
        }
    }

    /** INTERNAL FUNCTIONS */

    function _stake(address pool, address account, uint amount, bool isCompound) internal {
        bool foundPool = false;

        for (uint i; i < poolsLength; i++) {
            if (pools[i] == pool) {
                foundPool = true;
                break;
            }
        }

        require(foundPool, "Pool doesn't exists");

        IStrongXMiningPool(pool).stake(account, amount, isCompound);
    }

    function _withdraw(address pool, address account, uint amount) internal {
        bool foundPool = false;

        for (uint i; i < poolsLength; i++) {
            if (pools[i] == pool) {
                foundPool = true;
                break;
            }
        }

        require(foundPool, "Pool doesn't exist");

        IStrongXMiningPool(pool).withdraw(account, amount);
    }

    function _setSingleAssetPool(address _pool) internal {
        require(_pool != address(0), "Invalid single asset pool");
        singleAssetPool = _pool;
    }

    /** RESTRICTED FUNCTIONS */

    function addPool(address _pool, bool _isSingleAsset) external onlyRole(MANAGER_ROLE) {
        bool foundPool;

        for (uint i; i < poolsLength; i++) {
            if (pools[i] == _pool) {
                foundPool = true;
                break;
            }
        }

        require(!foundPool, "Pool already exists");
        pools.push(_pool);
        poolsLength++;

        if (_isSingleAsset) _setSingleAssetPool(_pool);
    }

    function removePool(address _pool) external onlyRole(MANAGER_ROLE) {
        for (uint i; i < poolsLength; i++) {
            if (pools[i] == _pool) {
                pools[i] = pools[pools.length - 1];
                pools.pop();
                poolsLength--;
                break;
            }
        }
    }

    function setSingleAssetPool(address _pool) external onlyRole(MANAGER_ROLE) {
        _setSingleAssetPool(_pool);
    }

    function recoverTokens(address _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(_token).transfer(admin, IERC20(_token).balanceOf(address(this)));
    }
}