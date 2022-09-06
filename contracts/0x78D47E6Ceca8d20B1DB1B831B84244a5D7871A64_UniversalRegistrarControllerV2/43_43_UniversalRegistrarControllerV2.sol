// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "@ensdomains/ens-contracts/contracts/resolvers/Resolver.sol";
import "../common/StringUtils.sol";
import "../common/PremiumPriceOracle.sol";
import "./NameStore.sol";
import "./BaseUniversalRegistrarControllerV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev A registrar controller for registering and renewing second level domains.
 */
contract UniversalRegistrarControllerV2 is Ownable, BaseUniversalRegistrarControllerV2 {
    using StringUtils for *;

    uint constant public MIN_REGISTRATION_DURATION = 28 days;

    bytes4 constant private INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 constant private COMMITMENT_CONTROLLER_ID = bytes4(
        keccak256("rentPrice(bytes32,string,uint256)") ^
        keccak256("available(bytes32,string)") ^
        keccak256("makeCommitment(bytes32,string,address,bytes32)") ^
        keccak256("commit(bytes32)") ^
        keccak256("register(bytes32,string,address,uint256,bytes32)") ^
        keccak256("renew(bytes32,string,uint256)")
    );

    bytes4 constant private COMMITMENT_WITH_CONFIG_CONTROLLER_ID = bytes4(
        keccak256("registerWithConfig(bytes32,string,address,uint256,bytes32,address,address)") ^
        keccak256("makeCommitmentWithConfig(bytes32,string,address,bytes32,address,address)")
    );

    bytes4 constant private RESERVED_NAMES_CONTROLLER_ID = bytes4(
        keccak256("registerReservedWithConfig(bytes32,string,address,uint256,address,address)") ^
        keccak256("availabilityInfo(bytes32,string)")
    );

    PremiumPriceOracle prices;
    NameStore store;
    uint public minCommitmentAge;
    uint public maxCommitmentAge;

    mapping(bytes32 => uint) public commitments;

    event NameRegistered(bytes32 indexed tld, string name, bytes32 indexed label, address indexed owner, uint cost, uint expires);
    event NameRenewed(bytes32 indexed tld, string name, bytes32 indexed label, uint cost, uint expires);
    event NewPriceOracle(address indexed oracle);

    constructor(
        UniversalRegistrar base_,
        PremiumPriceOracle prices_,
        NameStore store_,
        uint minCommitmentAge_,
        uint maxCommitmentAge_,
        uint256 ownerShare_,
        uint256 registryShare_
    ) BaseUniversalRegistrarControllerV2(base_, ownerShare_, registryShare_) {
        require(maxCommitmentAge_ > minCommitmentAge_);

        store = store_;
        prices = prices_;
        minCommitmentAge = minCommitmentAge_;
        maxCommitmentAge = maxCommitmentAge_;
    }

    function _tokenID(bytes32 node, bytes32 label) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(node, label)));
    }

    function rentPrice(bytes32 node, string memory name, uint duration) view public returns (uint) {
        bytes32 label = keccak256(bytes(name));
        return prices.price(node, name, base.nameExpires(_tokenID(node, label)), duration);
    }

    function valid(string memory name) public pure returns (bool) {
        return name.strlen() >= 1;
    }

    function available(bytes32 node, string memory name) public view returns (bool) {
        bytes32 label = keccak256(bytes(name));
        return _available(node, name, label) && store.available(node, label);
    }

    function _available(bytes32 node, string memory name, bytes32 label) internal view returns(bool) {
        return valid(name) && base.available(_tokenID(node, label));
    }

    // 0 - unavailable, 1 - available, 2 - reserved, 3 - paused
    function availabilityInfo(bytes32 node, string memory name) public view returns (uint8, address) {
        bytes32 label = keccak256(bytes(name));

        if (!valid(name) ||
            !base.available(_tokenID(node, label))) {
            return (0, address(0));
        }
        if (store.reserved(node, label) != address(0)) {
            return (2, store.reserved(node, label));
        }
        if (store.registrationsPaused(node)) {
            return (3, address(0));
        }
        return (1, address(0));
    }

    function makeCommitment(bytes32 node, string memory name, address owner, bytes32 secret) pure public returns (bytes32) {
        return makeCommitmentWithConfig(node, name, owner, secret, address(0), address(0));
    }

    function makeCommitmentWithConfig(bytes32 node, string memory name,
        address owner, bytes32 secret, address resolver, address addr) pure public returns (bytes32) {
        bytes32 label = keccak256(bytes(name));
        return _makeCommitmentWithConfig(node, label, owner, secret, resolver, addr);
    }

    function _makeCommitmentWithConfig(bytes32 node, bytes32 label,
        address owner, bytes32 secret, address resolver, address addr) pure internal returns (bytes32) {
        if (resolver == address(0) && addr == address(0)) {
            return keccak256(abi.encodePacked(node, label, owner, secret));
        }
        require(resolver != address(0));
        return keccak256(abi.encodePacked(node, label, owner, resolver, addr, secret));
    }

    function commit(bytes32 commitment) public {
        require(commitments[commitment] + maxCommitmentAge < block.timestamp);
        commitments[commitment] = block.timestamp;
    }

    function register(bytes32 node, string calldata name, address owner, uint duration, bytes32 secret) external payable {
        registerWithConfig(node, name, owner, duration, secret, address(0), address(0));
    }

    function registerWithConfig(bytes32 node, string memory name, address owner,
        uint duration, bytes32 secret, address resolver, address addr) public payable {

        bytes32 label = keccak256(bytes(name));
        uint cost = _consumeCommitment
        (
            node,
            name,
            label,
            duration,
            _makeCommitmentWithConfig(node, label, owner, secret, resolver, addr)
        );

        store.adopt(node, label);

        uint expires;
        if (resolver != address(0)) {
            // Set this contract as the (temporary) owner, giving it
            // permission to set up the resolver.
            expires = base.register(node, label, address(this), duration);

            // The nodehash of this label
            bytes32 nodehash = keccak256(abi.encodePacked(node, label));

            // Set the resolver
            base.ens().setResolver(nodehash, resolver);

            // Configure the resolver
            if (addr != address(0)) {
                Resolver(resolver).setAddr(nodehash, addr);
            }

            // Now transfer full ownership to the expeceted owner
            base.reclaim(node, label, owner);
            base.transferFrom(address(this), owner, uint256(nodehash));
        } else {
            require(addr == address(0));
            expires = base.register(node, label, owner, duration);
        }

        // Record revenue generated by this node
        _addPayment(node, cost);

        emit NameRegistered(node, name, label, owner, cost, expires);

        // Refund any extra payment
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    function registerReservedWithConfig(bytes32 node, string memory name, address owner,
        uint duration, address resolver, address addr) public payable {
        bytes32 label = keccak256(bytes(name));
        require(_available(node, name, label) && !store.registrationsPaused(node));
        require(store.reserved(node, label) == msg.sender, "unauthorised to register reserved name");

        uint cost = rentPrice(node, name, duration);
        require(duration >= MIN_REGISTRATION_DURATION);
        require(msg.value >= cost);

        store.adopt(node, label);

        // address is no longer reserved once registered
        store.reserve(node, name, address(0));

        uint expires;
        if (resolver != address(0)) {
            // Set this contract as the (temporary) owner, giving it
            // permission to set up the resolver.
            expires = base.register(node, label, address(this), duration);

            // The nodehash of this label
            bytes32 nodehash = keccak256(abi.encodePacked(node, label));

            // Set the resolver
            base.ens().setResolver(nodehash, resolver);

            // Configure the resolver
            if (addr != address(0)) {
                Resolver(resolver).setAddr(nodehash, addr);
            }

            // Now transfer full ownership to the expeceted owner
            base.reclaim(node, label, owner);
            base.transferFrom(address(this), owner, uint256(nodehash));
        } else {
            require(addr == address(0));
            expires = base.register(node, label, owner, duration);
        }

        // Record revenue generated by this node
        _addPayment(node, cost);

        emit NameRegistered(node, name, label, owner, cost, expires);

        // Refund any extra payment
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    function renew(bytes32 node, string calldata name, uint duration) external payable {
        uint cost = rentPrice(node, name, duration);
        require(msg.value >= cost);

        bytes32 label = keccak256(bytes(name));
        uint expires = base.renew(node, label, duration);

        // Record revenue generated by this node
        _addPayment(node, cost);

        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }

        emit NameRenewed(node, name, label, cost, expires);
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == INTERFACE_META_ID ||
        interfaceID == COMMITMENT_CONTROLLER_ID ||
        interfaceID == COMMITMENT_WITH_CONFIG_CONTROLLER_ID ||
        interfaceID == RESERVED_NAMES_CONTROLLER_ID;
    }

    function _consumeCommitment(bytes32 node, string memory name, bytes32 label, uint duration, bytes32 commitment) internal returns (uint256) {
        // Require a valid commitment
        require(commitments[commitment] + minCommitmentAge <= block.timestamp);

        // If the commitment is too old, or the name is registered, stop
        require(commitments[commitment] + maxCommitmentAge > block.timestamp);
        require(_available(node, name, label) && store.available(node, label));

        delete (commitments[commitment]);

        uint cost = rentPrice(node, name, duration);
        require(duration >= MIN_REGISTRATION_DURATION);
        require(msg.value >= cost);

        return cost;
    }
}