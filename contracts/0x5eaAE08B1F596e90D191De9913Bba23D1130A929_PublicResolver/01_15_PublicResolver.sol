// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./NameResolver.sol";
import "./TextResolver.sol";
import "./AddressResolver.sol";
import "./interfaces/IWeb3Registry.sol";

contract PublicResolver is NameResolver, AddressResolver, TextResolver {
    address trustedReverseRegistrar;
    address trustedETHController;
    IWeb3Registry public registry;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function __PublicResolver_init(
        IWeb3Registry _registry,
        address _trustedETHController,
        address _trustedReverseRegistrar
    ) external initializer {
        __PublicResolver_init_unchained(
            _registry,
            _trustedETHController,
            _trustedReverseRegistrar
        );
    }

    function __PublicResolver_init_unchained(
        IWeb3Registry _registry,
        address _trustedETHController,
        address _trustedReverseRegistrar
    ) internal onlyInitializing {
        registry = _registry;
        trustedETHController = _trustedETHController;
        trustedReverseRegistrar = _trustedReverseRegistrar;
    }

    function setApprovalForAll(address operator, bool approved) external {
        require(
            msg.sender != operator,
            "ERC1155: setting approval status for self"
        );

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(
        address account,
        address operator
    ) public view returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function isAuthorized(bytes32 node) internal view override returns (bool) {
        if (
            msg.sender == trustedETHController ||
            msg.sender == trustedReverseRegistrar
        ) {
            return true;
        }
        address owner = registry.owner(node);
        return owner == msg.sender || isApprovedForAll(owner, msg.sender);
    }

    function supportsInterface(
        bytes4 interfaceID
    )
        public
        view
        override(NameResolver, AddressResolver, TextResolver)
        returns (bool)
    {
        return super.supportsInterface(interfaceID);
    }

    // override setters
    function setName(
        bytes32 node,
        string calldata newName
    ) external virtual override authorized(node) {
        names[node] = newName;
        emit NameChanged(node, newName);
        // ens
        bytes32 ensNode = registry.ensNodeMap(node);
        if (ensNode != bytes32(0x0)) {
            names[ensNode] = newName;
            emit NameChanged(ensNode, newName);
        }
    }

    function setAddr(
        bytes32 node,
        uint256 coinType,
        bytes memory a
    ) public override authorized(node) {
        emit AddressChanged(node, coinType, a);
        _addresses[node][coinType] = a;
        // ens
        bytes32 ensNode = registry.ensNodeMap(node);
        if (ensNode != bytes32(0x0)) {
            emit AddressChanged(ensNode, coinType, a);
            _addresses[ensNode][coinType] = a;
        }
    }

    function setText(
        bytes32 node,
        string calldata key,
        string calldata value
    ) external virtual override authorized(node) {
        texts[node][key] = value;
        emit TextChanged(node, key, key);
        // ens
        bytes32 ensNode = registry.ensNodeMap(node);
        if (ensNode != bytes32(0x0)) {
            texts[ensNode][key] = value;
            emit TextChanged(ensNode, key, key);
        }
    }

    uint256[46] private __gap;
}