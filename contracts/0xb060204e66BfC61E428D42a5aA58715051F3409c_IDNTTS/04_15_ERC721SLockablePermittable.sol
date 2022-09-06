// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "./ERC721SLockable.sol";

/// @title ERC721S Extension with EIP2612-like permits
/// @dev   Implements EIP4494 and additionally permitAll

abstract contract ERC721SLockablePermittable is ERC721SLockable {  

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == 0x5604e225 ||           // _INTERFACE_ID_ERC4494 = 0x5604e225
            super.supportsInterface(interfaceId);
    }

    /*///////////////////////////////////////////////////////////////
                            EIP-2612-LIKE STORAGE
    //////////////////////////////////////////////////////////////*/
    
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");

    bytes32 public constant PERMIT_ALL_TYPEHASH = 
        keccak256("Permit(address operator,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(uint256 => uint256) public nonces;

    mapping(address => mapping(address => uint256)) public noncesForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();      
    }

    /*///////////////////////////////////////////////////////////////
                            EIP-2612-LIKE LOGIC
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @dev Uses the permit to approve one token for spender
     */

    function permit(
        address signer,
        address spender,
        uint256 tokenId,
        uint256 deadline,
        bytes memory sig
    ) public virtual {
        require(block.timestamp <= deadline, "PERMIT_DEADLINE_EXPIRED");
        
        address ownerOfToken = ownerOf(tokenId);
        
        // Unchecked because the only math done is incrementing
        // the nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, spender, tokenId, nonces[tokenId]++, deadline))
                )
            );

            require(SignatureChecker.isValidSignatureNow(signer, digest, sig), "INVALID_SIGNATURE");

            // Signature is good, now should check if signer had rights to approve this token
            // Like, only owner or operator can user approve functions, 
            // only owner or operator can sign permits for approval. 
            require(signer == ownerOfToken || isApprovedForAll(ownerOfToken, signer), "INVALID_SIGNER"); 
        }
        
        _tokenApprovals[tokenId] = spender;

        emit Approval(ownerOfToken, spender, tokenId);
    }

    /**
     * @dev Uses the permit to approve all the tokens owned by signer for the operator
     * 
     * Having permit for all can make purchases cheaper for buyers in future, when marketplace can consume only one 
     * permitAll from buyer to all the tokens from given collection, and all next orders won't need to call permit() 
     * for every new token purchase, so buyers won't pay gas for that call
     * this can be more dangerous for seller btw, to approve All of his tokens to the marketplace instead of per token approvals
     */
     
    function permitAll(
        address signer,
        address operator,
        uint256 deadline,
        bytes memory sig
    ) public virtual {
        require(block.timestamp <= deadline, "PERMIT_DEADLINE_EXPIRED");
        
        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_ALL_TYPEHASH, operator, noncesForAll[signer][operator]++, deadline))
                )
            );

            require(SignatureChecker.isValidSignatureNow(signer, digest, sig), "INVALID_SIGNATURE");
        }
        
        // no need to check any kind of ownerships because we always approve operator on behalf of signer,
        // not on behalf of any other owner
        // that does not allow current operators to make isApprovedForAll[owner][one_more_operator] = true
        // but current operator can still aprove explicit tokens with permit(), that is enough I guess
        // and better for security
        _operatorApprovals[signer][operator] = true;

        emit ApprovalForAll(signer, operator, true);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32 domainSeparator) {
        domainSeparator = block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32 domainSeparator) {
        domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

}

//   That's all, folks!