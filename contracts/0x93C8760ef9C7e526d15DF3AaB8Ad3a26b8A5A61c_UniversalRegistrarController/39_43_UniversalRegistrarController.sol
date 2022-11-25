// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/Resolver.sol";
import "./OwnableCloneable.sol";
import "./StringUtils.sol";
import "./NameStore.sol";
import "./UniversalRegistrar.sol";
import "./BaseUniversalRegistrarController.sol";
import "./SLDPriceOracle.sol";

/**
 * @dev A registrar controller for registering second level domains.
 */
contract UniversalRegistrarController is Ownable, BaseUniversalRegistrarController {
    using StringUtils for *;

    bytes4 constant private INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 constant private COMMITMENT_CONTROLLER_ID = bytes4(
        keccak256("price(bytes32,string)") ^
        keccak256("available(bytes32,string)") ^
        keccak256("makeCommitment(bytes32,string,address,bytes32)") ^
        keccak256("commit(bytes32)") ^
        keccak256("register(bytes32,string,address,bytes32)") ^
        keccak256("ownerRegister(bytes32,string,address,bytes32)") ^
        keccak256("domainPassRegister(bytes32,string,address,bytes32,bytes32[])") ^
        keccak256("domainPassForNodeRegister(bytes32,string,address,bytes32,bytes32[])") ^
        keccak256("whitelistRegister(bytes32,string,address,bytes32,bytes32[])")
    );

    bytes4 constant private COMMITMENT_WITH_CONFIG_CONTROLLER_ID = bytes4(
        keccak256("registerWithConfig(bytes32,string,address,bytes32,address,address)") ^
        keccak256("ownerRegisterWithConfig(bytes32,string,address,bytes32,address,address)") ^
        keccak256("domainPassRegisterWithConfig(bytes32,string,address,bytes32,address,address,bytes32[])") ^
        keccak256("domainPassForNodeRegisterWithConfig(bytes32,string,address,bytes32,address,address,bytes32[])") ^
        keccak256("whitelistRegisterWithConfig(bytes32,string,address,bytes32,address,address,bytes32[])") ^
        keccak256("makeCommitmentWithConfig(bytes32,string,address,bytes32,address,address)")
    );

    SLDPriceOracle prices;
    NameStore store;
    uint public minCommitmentAge;
    uint public maxCommitmentAge;

    mapping(bytes32 => uint) public commitments;

    event NameRegistered(bytes32 indexed node, string name, bytes32 indexed label, address indexed owner, uint cost);
    event NewPriceOracle(address indexed oracle);

     constructor(
         UniversalRegistrar base_,
         SLDPriceOracle prices_,
         NameStore store_,
         uint minCommitmentAge_,
         uint maxCommitmentAge_
     ) BaseUniversalRegistrarController(base_) {
        require(maxCommitmentAge_ > minCommitmentAge_);

        setNameStore(store_);
        prices = prices_;
        minCommitmentAge = minCommitmentAge_;
        maxCommitmentAge = maxCommitmentAge_;
    }

    function setCommitmentAges(uint _minCommitmentAge, uint _maxCommitmentAge) public onlyOwner {
        minCommitmentAge = _minCommitmentAge;
        maxCommitmentAge = _maxCommitmentAge;
    }

    function _tokenID(bytes32 node, bytes32 label) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(node, label)));
    }

    function _node(bytes32 node, string calldata name) internal pure returns (bytes32) {
        bytes32 label = keccak256(bytes(name));
        return keccak256(abi.encodePacked(node, label));
    }

    function price(bytes32 node, string memory name) view public returns (uint) {
        return prices.price(node, name);
    }

    function valid(string memory name) public pure returns (bool) {
        return name.strlen() >= 1;
    }

    function available(bytes32 node, string memory name) public view returns (bool) {
        bytes32 label = keccak256(bytes(name));
        return valid(name) && base.available(_tokenID(node, label));
    }

    function makeCommitment(bytes32 node, string memory name, address owner, bytes32 secret) pure public returns (bytes32) {
        return makeCommitmentWithConfig(node, name, owner, secret, address(0), address(0));
    }

    function makeCommitmentWithConfig(bytes32 node, string memory name,
        address owner, bytes32 secret, address resolver, address addr) pure public returns (bytes32) {
        bytes32 label = keccak256(bytes(name));
        
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

    function register(bytes32 node, string calldata name, address owner, bytes32 secret) external payable {
        registerWithConfig(node, name, owner, secret, address(0), address(0));
    }

    function registerWithConfig(bytes32 node, string memory name, address owner,
        bytes32 secret, address resolver, address addr) public payable {
        require(!store.registrationsPaused(node), "Registration is paused!");

        uint cost = _consumeCommitment
        (
            node,
            name,
            makeCommitmentWithConfig(node, name, owner, secret, resolver, addr)
        );

        _register(node, name, owner, resolver, addr, cost);

        // Record revenue generated by this node
        _addPayment(node, cost);

        // Refund any extra payment
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    function domainPassRegister(bytes32 node, string calldata name, address owner, bytes32 secret, bytes32[] calldata merkleProof) external {
        domainPassRegisterWithConfig(node, name, owner, secret, address(0), address(0), merkleProof);
    }

    function domainPassRegisterWithConfig(bytes32 node, string memory name, address owner,
        bytes32 secret, address resolver, address addr, bytes32[] calldata merkleProof) public {
        require(!store.registrationsPaused(node) || store.whitelistEnabled(node), "Registration is paused!");
        require(store.domainPassEnabled(), "Domain Pass Registration is disabled!");
        require(!store.isDomainPassUsed(msg.sender), "Caller has already used domain pass!");
        require(name.strlen() >= store.domainPassLetterLimit(), "Name length must be above limit!");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
          MerkleProof.verify(merkleProof, store.domainPassMerkleRoot(), leaf),
          "Invalid proof!"
        );

        bytes32 commitment = makeCommitmentWithConfig(node, name, owner, secret, resolver, addr);

        // Require a valid commitment
        require(commitments[commitment] + minCommitmentAge <= block.timestamp);

        // If the commitment is too old, or the name is registered, stop
        require(commitments[commitment] + maxCommitmentAge > block.timestamp);
        require(available(node, name));
 
        delete (commitments[commitment]);

        store.useDomainPass(node, msg.sender);

        _register(node, name, owner, resolver, addr, 0);
    }

    function domainPassForNodeRegister(bytes32 node, string calldata name, address owner, bytes32 secret, bytes32[] calldata merkleProof) external {
        domainPassForNodeRegisterWithConfig(node, name, owner, secret, address(0), address(0), merkleProof);
    }

    function domainPassForNodeRegisterWithConfig(bytes32 node, string memory name, address owner,
        bytes32 secret, address resolver, address addr, bytes32[] calldata merkleProof) public {
        require(!store.registrationsPaused(node) || store.whitelistEnabled(node), "Registration is paused!");
        require(store.domainPassEnabledForNode(node), "Domain Pass Registration for this node is disabled!");
        require(!store.isDomainPassUsedForNode(node, msg.sender), "Caller has already used domain pass!");
        require(name.strlen() >= store.domainPassLetterLimitForNode(node), "Name length must be above limit!");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
          MerkleProof.verify(merkleProof, store.domainPassMerkleRootForNode(node), leaf),
          "Invalid proof!"
        );

        bytes32 commitment = makeCommitmentWithConfig(node, name, owner, secret, resolver, addr);

        // Require a valid commitment
        require(commitments[commitment] + minCommitmentAge <= block.timestamp);

        // If the commitment is too old, or the name is registered, stop
        require(commitments[commitment] + maxCommitmentAge > block.timestamp);
        require(available(node, name));
 
        delete (commitments[commitment]);

        store.useDomainPassForNode(node, msg.sender);

        _register(node, name, owner, resolver, addr, 0);
    }

    function whitelistRegister(bytes32 node, string calldata name, address owner, bytes32 secret, bytes32[] calldata merkleProof) external payable {
        whitelistRegisterWithConfig(node, name, owner, secret, address(0), address(0), merkleProof);
    }

    function whitelistRegisterWithConfig(bytes32 node, string memory name, address owner,
        bytes32 secret, address resolver, address addr, bytes32[] calldata merkleProof) public payable {
        require(store.whitelistEnabled(node), "Whitelist is not enabled for this TLD!");    
        require(store.isEligibleForWhitelist(node, msg.sender), "Address already claimed!");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
          MerkleProof.verify(merkleProof, store.whitelistMerkleRoot(node), leaf),
          "Invalid proof!"
        );

        uint cost = _consumeCommitment
        (
            node,
            name,
            makeCommitmentWithConfig(node, name, owner, secret, resolver, addr)
        );

        store.increaseWhitelistRegistered(node, msg.sender);

        _register(node, name, owner, resolver, addr, cost);

        // Record revenue generated by this node
        _addPayment(node, cost);

        // Refund any extra payment
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    function ownerRegister(bytes32 node, string calldata name, address owner, bytes32 secret) public onlyOwner {
        ownerRegisterWithConfig(node, name, owner, secret, address(0), address(0));
    }

    function ownerRegisterWithConfig(bytes32 node, string memory name, address owner,
        bytes32 secret, address resolver, address addr) public onlyOwner {

        bytes32 commitment = makeCommitmentWithConfig(node, name, owner, secret, resolver, addr);

        // Require a valid commitment
        require(commitments[commitment] + minCommitmentAge <= block.timestamp);

        // If the commitment is too old, or the name is registered, stop
        require(commitments[commitment] + maxCommitmentAge > block.timestamp);
        require(available(node, name));

        delete (commitments[commitment]);

        _register(node, name, owner, resolver, addr, 0);
    }

    function _register(bytes32 node, string memory name, address owner, address resolver, address addr, uint cost) private {
        bytes32 label = keccak256(bytes(name));
        bytes32 nodehash = keccak256(abi.encodePacked(node, label));

        if(store.reserved(node, label) != address(0)) {
            require(store.reserved(node, label) == msg.sender, "Name is Reserved!");
        
            store.reserve(node, name, address(0));
        }

        if (resolver != address(0)) {
            // Set this contract as the (temporary) owner, giving it
            // permission to set up the resolver.
            base.register(node, label, address(this));

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
            base.register(node, label, owner);
        }

        emit NameRegistered(node, name, label, owner, cost);
    }

    function setPriceOracle(SLDPriceOracle _prices) public onlyOwner {
        prices = _prices;
        emit NewPriceOracle(address(prices));
    }

    function setNameStore(NameStore _store) public onlyOwner {
        store = _store;
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == INTERFACE_META_ID ||
        interfaceID == COMMITMENT_CONTROLLER_ID ||
        interfaceID == COMMITMENT_WITH_CONFIG_CONTROLLER_ID;
    }

    function _consumeCommitment(bytes32 node, string memory name, bytes32 commitment) internal returns (uint256) {
        // Require a valid commitment
        require(commitments[commitment] + minCommitmentAge <= block.timestamp);

        // If the commitment is too old, or the name is registered, stop
        require(commitments[commitment] + maxCommitmentAge > block.timestamp);
        require(available(node, name));

        delete (commitments[commitment]);

        uint cost = price(node, name);
        require(msg.value >= cost);

        return cost;
    }
}