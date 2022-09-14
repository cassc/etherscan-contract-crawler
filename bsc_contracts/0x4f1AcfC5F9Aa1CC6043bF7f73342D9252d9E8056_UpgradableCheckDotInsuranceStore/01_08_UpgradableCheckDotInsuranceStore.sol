// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../../../../CheckDot.DAOProxyContract/contracts/ProxyDAO.sol";

contract UpgradableCheckDotInsuranceStore is ProxyDAO {
    constructor(address _cdtGouvernanceAddress) ProxyDAO(_cdtGouvernanceAddress) { }
}