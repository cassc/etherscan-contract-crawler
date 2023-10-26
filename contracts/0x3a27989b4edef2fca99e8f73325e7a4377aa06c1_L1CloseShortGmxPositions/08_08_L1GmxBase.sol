pragma solidity ^0.8.9;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract L1GmxBase is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    address public constant CROSS_CHAIN_PORTAL =
        0x4Dbd4fc535Ac27206064B68FfCf827b0A60BAB3f;
    address public constant ARB_RECEIVER =
        0x9aCD66b065303cB211AD6b49c676C9fCF233d612;
    uint64 public constant GAS_LIMIT_FOR_CALL = 3_500_000;
    uint256 public constant MAX_FEE_PER_GAS = 1 gwei;
    uint256 public constant MAX_SUBMISSION_COST = 0.001 ether;

    uint256[50] private _gap;
    
    function initialize() public initializer {
        __Ownable_init();
    }

}