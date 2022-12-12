/**
 *Submitted for verification at Etherscan.io on 2022-12-12
*/

// File: IKEY3.sol


pragma solidity ^0.8.9;

interface IKEY3 {
    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function setRecord(
        bytes32 node,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) external returns (bytes32);

    function setResolver(bytes32 node, address resolver) external;

    function setOwner(bytes32 node, address owner) external;

    function setTTL(bytes32 node, uint64 ttl) external;

    function setApprovalForAll(address operator, bool approved) external;

    function owner(bytes32 node) external view returns (address);

    function resolver(bytes32 node) external view returns (address);

    function ttl(bytes32 node) external view returns (uint64);

    function recordExists(bytes32 node) external view returns (bool);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

// File: KEY3Registry.sol


pragma solidity ^0.8.9;


contract KEY3Registry is IKEY3 {
    struct Record {
        address owner;
        address resolver;
        uint64 ttl;
    }

    mapping(bytes32 => Record) records;
    mapping(address => mapping(address => bool)) operators;

    // Permits modifications only by the owner of the specified node.
    modifier authorised(bytes32 node_) {
        address currentOwner = records[node_].owner;
        require(
            currentOwner == msg.sender || operators[currentOwner][msg.sender],
            "you're not the owner of this did"
        );
        _;
    }

    /**
     * @dev Constructs a new KEY3 registrar.
     */
    constructor() {
        records[0x0].owner = msg.sender;
    }

    /**
     * @dev Sets the record for a node.
     * @param node_ The node to update.
     * @param owner_ The address of the new owner.
     * @param resolver_ The address of the resolver.
     * @param ttl_ The TTL in seconds.
     */
    function setRecord(
        bytes32 node_,
        address owner_,
        address resolver_,
        uint64 ttl_
    ) external {
        setOwner(node_, owner_);
        _setResolverAndTTL(node_, resolver_, ttl_);
    }

    /**
     * @dev Sets the record for a subnode.
     * @param node_ The parent node.
     * @param label_ The hash of the label specifying the subnode.
     * @param owner_ The address of the new owner.
     * @param resolver_ The address of the resolver.
     * @param ttl_ The TTL in seconds.
     */
    function setSubnodeRecord(
        bytes32 node_,
        bytes32 label_,
        address owner_,
        address resolver_,
        uint64 ttl_
    ) external {
        bytes32 subnode = setSubnodeOwner(node_, label_, owner_);
        _setResolverAndTTL(subnode, resolver_, ttl_);
    }

    /**
     * @dev Transfers ownership of a node to a new address. May only be called by the current owner of the node.
     * @param node_ The node to transfer ownership of.
     * @param owner_ The address of the new owner.
     */
    function setOwner(bytes32 node_, address owner_) public authorised(node_) {
        _setOwner(node_, owner_);
        emit Transfer(node_, owner_);
    }

    /**
     * @dev Transfers ownership of a subnode keccak256(node, label) to a new address. May only be called by the owner of the parent node.
     * @param node_ The parent node.
     * @param label_ The hash of the label specifying the subnode.
     * @param owner_ The address of the new owner.
     */
    function setSubnodeOwner(
        bytes32 node_,
        bytes32 label_,
        address owner_
    ) public authorised(node_) returns (bytes32) {
        bytes32 subnode = keccak256(abi.encodePacked(node_, label_));
        _setOwner(subnode, owner_);
        emit NewOwner(node_, label_, owner_);
        return subnode;
    }

    /**
     * @dev Sets the resolver address for the specified node.
     * @param node_ The node to update.
     * @param resolver_ The address of the resolver.
     */
    function setResolver(bytes32 node_, address resolver_)
        public
        authorised(node_)
    {
        emit NewResolver(node_, resolver_);
        records[node_].resolver = resolver_;
    }

    /**
     * @dev Sets the TTL for the specified node.
     * @param node_ The node to update.
     * @param ttl_ The TTL in seconds.
     */
    function setTTL(bytes32 node_, uint64 ttl_) public authorised(node_) {
        emit NewTTL(node_, ttl_);
        records[node_].ttl = ttl_;
    }

    /**
     * @dev Enable or disable approval for a third party ("operator") to manage
     *  all of `msg.sender`'s KEY3 records. Emits the ApprovalForAll event.
     * @param operator_ Address to add to the set of authorized operators.
     * @param approved_ True if the operator is approved, false to revoke approval.
     */
    function setApprovalForAll(address operator_, bool approved_) external {
        operators[msg.sender][operator_] = approved_;
        emit ApprovalForAll(msg.sender, operator_, approved_);
    }

    /**
     * @dev Returns the address that owns the specified node.
     * @param node_ The specified node.
     * @return address of the owner.
     */
    function owner(bytes32 node_) public view returns (address) {
        address addr = records[node_].owner;
        if (addr == address(this)) {
            return address(0x0);
        }

        return addr;
    }

    /**
     * @dev Returns the address of the resolver for the specified node.
     * @param node_ The specified node.
     * @return address of the resolver.
     */
    function resolver(bytes32 node_) public view returns (address) {
        return records[node_].resolver;
    }

    /**
     * @dev Returns the TTL of a node, and any records associated with it.
     * @param node_ The specified node.
     * @return ttl of the node.
     */
    function ttl(bytes32 node_) public view returns (uint64) {
        return records[node_].ttl;
    }

    /**
     * @dev Returns whether a record has been imported to the registry.
     * @param node_ The specified node.
     * @return Bool if record exists
     */
    function recordExists(bytes32 node_) public view returns (bool) {
        return records[node_].owner != address(0x0);
    }

    /**
     * @dev Query if an address is an authorized operator for another address.
     * @param owner_ The address that owns the records.
     * @param operator_ The address that acts on behalf of the owner.
     * @return True if `operator` is an approved operator for `owner`, false otherwise.
     */
    function isApprovedForAll(address owner_, address operator_)
        external
        view
        returns (bool)
    {
        return operators[owner_][operator_];
    }

    function _setOwner(bytes32 node_, address owner_) internal {
        records[node_].owner = owner_;
    }

    function _setResolverAndTTL(
        bytes32 node_,
        address resolver_,
        uint64 ttl_
    ) internal {
        if (resolver_ != records[node_].resolver) {
            records[node_].resolver = resolver_;
            emit NewResolver(node_, resolver_);
        }

        if (ttl_ != records[node_].ttl) {
            records[node_].ttl = ttl_;
            emit NewTTL(node_, ttl_);
        }
    }
}