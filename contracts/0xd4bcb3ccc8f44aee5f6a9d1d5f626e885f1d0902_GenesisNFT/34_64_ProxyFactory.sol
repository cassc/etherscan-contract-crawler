// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '../interfaces/IOwnableDelegateProxy.sol';
import '../interfaces/IProxyImplementation.sol';
import './OwnableDelegateProxy.sol';
import '../core/SafeOwnable.sol';
import "hardhat/console.sol";

contract ProxyFactory is SafeOwnable, Initializable {

    bytes32 public constant INIT_CODE_HASH = keccak256(abi.encodePacked(type(OwnableDelegateProxy).creationCode));

    IProxyImplementation public proxyImplementation;

    mapping(address => IOwnableDelegateProxy) public proxies;

    mapping(address => uint) public pending;

    mapping(address => bool) public contracts;

    uint public DELAY_PERIOD = 2 weeks;

    constructor(IProxyImplementation _proxyImplementation) {
        proxyImplementation = _proxyImplementation;
    }

    function startGrantAuthentication (address _addr) external onlyOwner {
        require(!contracts[_addr] && pending[_addr] == 0, "already in contracts or pending");
        pending[_addr] = block.timestamp;
    }

    function endGrantAuthentication (address _addr) external onlyOwner {
        require(!contracts[_addr] && pending[_addr] != 0 && ((pending[_addr] + DELAY_PERIOD) < block.timestamp), "time not right");
        pending[_addr] = 0;
        contracts[_addr] = true;
    }

    function revokeAuthentication (address _addr) external onlyOwner {
        contracts[_addr] = false;
    }

    function registerProxy() external returns (address proxy) {
        require(address(proxies[msg.sender]) == address(0), "already registed");
        bytes memory bytecode = type(OwnableDelegateProxy).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(msg.sender));
        assembly {
            proxy := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        console.log("proxy: ", proxy);
        proxies[msg.sender] = IOwnableDelegateProxy(payable(proxy));
        IOwnableDelegateProxy(payable(proxy)).initialize(proxyImplementation, msg.sender, address(this));
    }

    function grantInitialAuthentication(address authAddress) external onlyOwner initializer {
        contracts[authAddress] = true;
    }
}