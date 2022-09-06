// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/ResolverBase.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/Multicallable.sol";

// @custom:security-contact [email protected]
interface INameWrapper {
    function ownerOf(uint256 id) external view returns (address);
}

interface IRedirectResolver {
    event RedirectChanged(bytes32 indexed node, bytes32 target);

    function redirect(bytes32 node) external view returns (bytes32);
}

abstract contract RedirectResolver is 
    IRedirectResolver, 
    ResolverBase 
{
    mapping(bytes32 => bytes32) private _redirect;

    function setRedirect(bytes32 node, bytes32 target)
        external 
        virtual 
        authorised(node)
    {
        _redirect[node] = target;
        emit RedirectChanged(node, target);
    }

    function redirect(bytes32 node) 
        public
        view 
        virtual
        override
        returns (bytes32)
    {
        return _redirect[node];
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceID == type(IRedirectResolver).interfaceId 
            || super.supportsInterface(interfaceID);
    }
} 

contract withApproval {
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setApprovalForAll(address operator, bool approved) 
        external
    {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address account, address operator)
        public
        view
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }
}

contract PublicRedirectResolver is 
    RedirectResolver, 
    Multicallable,
    withApproval
{
    ENS immutable ens;
    
    constructor(ENS _ens) {
        ens = _ens;
    }

    fallback() 
        external 
    {
        // Extract node from call. For resolver, this is always the first argument just after the selector
        bytes32 node;
        assembly {
            node := calldataload(0x04)
        }

        // Apply redirect
        node = redirect(node);

        // Get resolver for the redirect target
        address target = ens.resolver(node);

        // Forward call
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0x00, 0x00, calldatasize())
            
            // Replace node with redirect target
            mstore(0x04, node)

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := staticcall(gas(), target, 0x00, calldatasize(), 0x00, 0x00)

            // Copy the returned data.
            returndatacopy(0x00, 0x00, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0  { revert(0x00, returndatasize()) }
            default { return(0x00, returndatasize()) }
        }
    }

    function isAuthorised(bytes32 node) internal view override returns (bool) {
        address owner = ens.owner(node);
        return owner == msg.sender || isApprovedForAll(owner, msg.sender);
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        override(
            Multicallable,
            RedirectResolver
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceID);
    }
}