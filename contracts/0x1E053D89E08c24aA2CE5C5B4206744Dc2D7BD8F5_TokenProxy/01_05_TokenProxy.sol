pragma solidity 0.4.24;

import "zos-lib/contracts/upgradeability/AdminUpgradeabilityProxy.sol";

contract TokenProxy is AdminUpgradeabilityProxy {
    constructor(address _implementation, address _admin, bytes memory _data)
        AdminUpgradeabilityProxy(_implementation, _admin, _data) public payable {
    }
}