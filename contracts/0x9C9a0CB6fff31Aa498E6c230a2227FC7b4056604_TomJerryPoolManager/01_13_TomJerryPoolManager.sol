/*

88888888888                           .d8888b.            888888                                   
    888                              d88P  "88b             "88b                                   
    888                              Y88b. d88P              888                                   
    888   .d88b.  88888b.d88b.        "Y8888P"               888  .d88b.  888d888 888d888 888  888 
    888  d88""88b 888 "888 "88b      .d88P88K.d88P           888 d8P  Y8b 888P"   888P"   888  888 
    888  888  888 888  888  888      888"  Y888P"            888 88888888 888     888     888  888 
    888  Y88..88P 888  888  888      Y88b .d8888b            88P Y8b.     888     888     Y88b 888 
    888   "Y88P"  888  888  888       "Y8888P" Y88b          888  "Y8888  888     888      "Y88888 
                                                           .d88P                               888 
                                                         .d88P"                           Y8b d88P 
                                                        888P"                              "Y88P"  

Website: https://tomjerryeth.com
Telegram: https://t.me/TomJerryETH
Twitter: https://twitter.com/TomJerryETH

*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IPool.sol";

contract TomJerryPoolManager is ReentrancyGuard, AccessControl {
    using SafeMath for uint;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    address[] public pools;
    uint public poolsLength;

    address private immutable admin;

    constructor () {
        admin = _msgSender();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
    }

    /** VIEW FUNCTIONS */

    function earned(address account) public view returns (uint rewards) {
        for (uint index = 0; index < poolsLength; index++) {
            rewards = rewards.add(IPool(pools[index]).getReward(account));
        }
    }

    /** PUBLIC FUNCTIONS */

    function claim() external nonReentrant {
        for (uint index = 0; index < poolsLength; index++) {
            IPool(pools[index]).claim(_msgSender());
        }
    }

    /** RESTRICTED FUNCTIONS */

    function addPool(address _pool) external onlyRole(MANAGER_ROLE) {
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

    function recoverTokens(address _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(_token).transfer(admin, IERC20(_token).balanceOf(address(this)));
    }
}