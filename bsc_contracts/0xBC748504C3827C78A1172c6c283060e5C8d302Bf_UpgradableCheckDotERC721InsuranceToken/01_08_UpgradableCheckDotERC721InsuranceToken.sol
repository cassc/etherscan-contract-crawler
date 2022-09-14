// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../../../../CheckDot.DAOProxyContract/contracts/ProxyDAO.sol";

contract UpgradableCheckDotERC721InsuranceToken is ProxyDAO {
    constructor(address _cdtGouvernanceAddress) ProxyDAO(_cdtGouvernanceAddress) { }
}