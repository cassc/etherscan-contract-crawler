// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./BaseDAO.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract BaseDAOProxy is
    BaseDAO,
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable
{}