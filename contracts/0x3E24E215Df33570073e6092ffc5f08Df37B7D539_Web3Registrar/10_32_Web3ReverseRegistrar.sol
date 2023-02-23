// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./interfaces/IWeb3Registry.sol";
import "./Controllable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract NameResolver {
    function setName(bytes32 node, string memory name) public virtual;
}

contract Web3ReverseRegistrar is Controllable {
    IWeb3Registry public registry;
    NameResolver public defaultResolver;

    bytes32 constant lookup = 0x3031323334353637383961626364656600000000000000000000000000000000;
    bytes32 constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

    event ReverseClaimed(address indexed addr, bytes32 indexed node);

    function __Web3ReverseRegistrar_init(IWeb3Registry _registry) external initializer {
        __Controllable_init_unchained();
        registry = _registry;

        Web3ReverseRegistrar oldRegistrar = Web3ReverseRegistrar(
            _registry.owner(ADDR_REVERSE_NODE)
        );
        if (address(oldRegistrar) != address(0x0)) {
            oldRegistrar.claim(msg.sender);
        }
    }

    modifier authorized(address addr) {
        require(
            addr == msg.sender ||
            controllers[msg.sender] ||
            registry.isApprovedForAll(addr, msg.sender) ||
            ownsContract(addr),
            "not authorized"
        );
        _;
    }

    function setDefaultResolver(address resolver) public onlyOwner {
        require(
            address(resolver) != address(0),
            "Resolver address must not be 0"
        );
        defaultResolver = NameResolver(resolver);
    }

    function claim(address owner) public returns (bytes32) {
        return claimForAddr(msg.sender, owner, address(defaultResolver));
    }

    function claimForAddr(
        address addr,
        address owner,
        address resolver
    ) public authorized(addr) returns (bytes32) {
        bytes32 labelHash = sha3HexAddress(addr);
        bytes32 reverseNode = keccak256(
            abi.encodePacked(ADDR_REVERSE_NODE, labelHash)
        );
        emit ReverseClaimed(addr, reverseNode);
        registry.setSubnodeRecord(ADDR_REVERSE_NODE, labelHash, owner, resolver);
        return reverseNode;
    }

    function claimWithResolver(address owner, address resolver)
    public
    returns (bytes32)
    {
        return claimForAddr(msg.sender, owner, resolver);
    }

    function setName(string memory name) public returns (bytes32) {
        return
        setNameForAddr(
            msg.sender,
            msg.sender,
            address(defaultResolver),
            name
        );
    }

    function setNameForAddr(
        address addr,
        address owner,
        address resolver,
        string memory name
    ) public returns (bytes32) {
        bytes32 node = claimForAddr(addr, owner, resolver);
        NameResolver(resolver).setName(node, name);
        return node;
    }

    function node(address addr) public pure returns (bytes32) {
        return
        keccak256(
            abi.encodePacked(ADDR_REVERSE_NODE, sha3HexAddress(addr))
        );
    }

    function sha3HexAddress(address addr) private pure returns (bytes32 ret) {
        assembly {
            for {
                let i := 40
            } gt(i, 0) {

            } {
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
            }

            ret := keccak256(0, 40)
        }
    }

    function ownsContract(address addr) internal view returns (bool) {
        try Ownable(addr).owner() returns (address owner) {
            return owner == msg.sender;
        } catch {
            return false;
        }
    }

    uint256[48] private __gap;
}