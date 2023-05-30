// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { UpgradeableProxyOwnable } from "./UpgradeableProxyOwnable.sol";

contract ReleaseProxy is UpgradeableProxyOwnable {
    address public FMB;
    uint256 public CLIFF;
    uint256 public PERIOD;
    uint256 public RELEASE;
    uint256 public tokenInitTS;
    uint256 public lastReleasedTS;
    address public beneficiary; 
    

    constructor() {
        _setOwner(msg.sender);
    }


    /**
     * @dev suppress compiler warning
     */
    receive() external payable {}
}