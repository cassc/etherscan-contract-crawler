// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../../../../CheckDot.DAOProxyContract/contracts/ProxyDAO.sol";

contract UpgradableCheckDotPoolFactory is ProxyDAO {
    constructor(address _cdtGouvernanceAddress) ProxyDAO(_cdtGouvernanceAddress) { }
}