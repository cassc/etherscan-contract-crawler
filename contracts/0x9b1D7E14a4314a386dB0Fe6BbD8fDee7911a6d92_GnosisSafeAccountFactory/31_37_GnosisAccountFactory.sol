// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "./EIP4337Manager.sol";
import "../utils/Exec.sol";
/**
 * A wrapper factory contract to deploy GnosisSafe as an Account-Abstraction wallet contract.
 */
contract GnosisSafeAccountFactory {

    bytes32 public immutable prefix;

    GnosisSafeProxyFactory public immutable proxyFactory;
    address public immutable safeSingleton;
    EIP4337Manager public immutable eip4337Manager;

    event AccountCreated(address indexed account, address indexed owner, uint salt);

    constructor(
        bytes32 _prefix,
        GnosisSafeProxyFactory _proxyFactory,
        address _safeSingleton,
        EIP4337Manager _eip4337Manager
    ) {
        prefix = _prefix;
        proxyFactory = _proxyFactory;
        safeSingleton = _safeSingleton;
        eip4337Manager = _eip4337Manager;
    }

    function encodeSalt(address owner, uint256 salt) public view returns(uint256) {
        return uint256(keccak256(
            abi.encodePacked(prefix, owner, salt)
        ));
    }

    function createAccount(address owner, uint salt) public returns (address addr) {
        addr = getAddress(owner, salt);
        uint codeSize = addr.code.length;
        if (codeSize > 0) {
            return addr;
        }

        address account = address(proxyFactory.createProxyWithNonce(
            safeSingleton, "", encodeSalt(owner, salt)
        ));
        emit AccountCreated(account, owner, salt);

        (bool success, bytes memory ret) = addr.call(getInitializer(owner));
        require(success, string(ret));
    }

    function getInitializer(address owner) internal view returns (bytes memory) {
        address[] memory owners = new address[](1);
        owners[0] = owner;
        uint threshold = 1;
        address eip4337fallback = eip4337Manager.eip4337Fallback();

        bytes memory setup4337Modules = abi.encodeCall(
            EIP4337Manager.setup4337Modules, (eip4337Manager));

        return abi.encodeCall(GnosisSafe.setup, (
            owners, threshold,
            address (eip4337Manager), setup4337Modules,
            eip4337fallback,
            address(0), 0, payable(0) //no payment receiver
        ));
    }

    /**
    * calculate the counterfactual address of this account as it would be returned by createAccount()
    * (uses the same "create2 signature" used by GnosisSafeProxyFactory.createProxyWithNonce)
    */
    function getAddress(address owner, uint salt) public view returns (address) {
        //copied from deployProxyWithNonce
        bytes32 salt2 = keccak256(abi.encodePacked(keccak256(""), encodeSalt(owner, salt)));
        bytes memory deploymentData = abi.encodePacked(proxyFactory.proxyCreationCode(), uint256(uint160(safeSingleton)));
        return Create2.computeAddress(bytes32(salt2), keccak256(deploymentData), address (proxyFactory));
    }
}