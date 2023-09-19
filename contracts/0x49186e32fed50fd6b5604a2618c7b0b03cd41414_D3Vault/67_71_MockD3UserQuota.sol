// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "contracts/DODOV3MM/intf/ID3UserQuota.sol";

contract MockD3UserQuota is ID3UserQuota {
    mapping(address => mapping(address => uint256)) internal quota; // user => (token => amount)

    function setUserQuota(address user, address token, uint256 amount) external {
        quota[user][token] = amount;
    }

    function getUserQuota(address user, address token) external view returns (uint256) {
        return quota[user][token];
    }

    function checkQuota(address user, address token, uint256 amount) external view returns (bool) {
        return amount <= quota[user][token];
    }
}