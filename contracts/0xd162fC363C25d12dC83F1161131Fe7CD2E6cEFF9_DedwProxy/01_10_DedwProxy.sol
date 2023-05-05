// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity =0.8.18;
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
contract DedwProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address _admin,
        bytes memory _data
    ) TransparentUpgradeableProxy(_logic,_admin, _data) {}
}