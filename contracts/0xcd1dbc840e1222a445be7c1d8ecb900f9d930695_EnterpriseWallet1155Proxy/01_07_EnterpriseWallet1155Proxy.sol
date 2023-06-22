pragma solidity ^0.6.2;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EnterpriseWallet1155Proxy is TransparentUpgradeableProxy {
    constructor(address _logic, address _admin, bytes memory _data) public TransparentUpgradeableProxy(_logic, _admin, _data) {
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _admin();
    }
}