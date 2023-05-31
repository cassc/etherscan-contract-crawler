pragma solidity 0.8.18;
import '@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol';

contract BridgeQueueProxy is ERC1967Proxy {
    constructor(address _logic, bytes memory _data) payable ERC1967Proxy(_logic, _data) {}
}