pragma solidity 0.8.6;


import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";


contract TProxy is TransparentUpgradeableProxy {

    constructor(
        address logic_,
        address admin_,
        bytes memory data_
    ) payable TransparentUpgradeableProxy(logic_, admin_, data_) { }

}