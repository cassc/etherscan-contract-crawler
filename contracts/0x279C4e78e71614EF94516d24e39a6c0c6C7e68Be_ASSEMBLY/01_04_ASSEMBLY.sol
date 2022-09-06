// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*

███╗   ███╗███████╗████████╗ █████╗ ██╗      █████╗ ██████╗ ███████╗██╗
████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██║     ██╔══██╗██╔══██╗██╔════╝██║
██╔████╔██║█████╗     ██║   ███████║██║     ███████║██████╔╝█████╗  ██║
██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██║     ██╔══██║██╔══██╗██╔══╝  ██║
██║ ╚═╝ ██║███████╗   ██║   ██║  ██║███████╗██║  ██║██████╔╝███████╗███████╗
╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝

 █████╗ ███████╗███████╗███████╗███╗   ███╗██████╗ ██╗  ██╗   ██╗     ██████╗  ██████╗  ██╗
██╔══██╗██╔════╝██╔════╝██╔════╝████╗ ████║██╔══██╗██║  ╚██╗ ██╔╝    ██╔═████╗██╔═████╗███║
███████║███████╗███████╗█████╗  ██╔████╔██║██████╔╝██║   ╚████╔╝     ██║██╔██║██║██╔██║╚██║
██╔══██║╚════██║╚════██║██╔══╝  ██║╚██╔╝██║██╔══██╗██║    ╚██╔╝      ████╔╝██║████╔╝██║ ██║
██║  ██║███████║███████║███████╗██║ ╚═╝ ██║██████╔╝███████╗██║       ╚██████╔╝╚██████╔╝ ██║
╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝     ╚═╝╚═════╝ ╚══════╝╚═╝        ╚═════╝  ╚═════╝  ╚═╝


Metalabel — ASSEMBLY 001 Member

Holders of the ASSEMBLY 001 membership NFT are graduates of Metalabel's
application-only laboratory program exploring creativity in multiplayer mode.
The only way to hold this NFT is to be part of a cultural collective or creative
project that completed ASSEMBLY 001.

Deployed by Metalabel with 💖 as a permanent application on the Ethereum blockchain.

https://assembly.metalabel.xyz/

Anna Bulbrook
Lauren Dorman
Rob Kalin
Austin Robey
Yancey Strickler
Brandon Valosek
Ilya Yudanov

*/

import {ERC721} from "solmate/src/tokens/ERC721.sol";
import {Owned} from "solmate/src/auth/Owned.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

interface IMetadataResolver {
    function resolve(address _contract, uint256 _id)
        external
        view
        returns (string memory);
}

contract ASSEMBLY is ERC721, Owned {
    // ---
    // events
    // ---

    /// @notice The external metadata resolver was set.
    event MetadataResolverSet(IMetadataResolver resolver);

    /// @notice The contract metadata URI was set.
    event ContractURISet(string uri);

    /// @notice The token metadata base URI was set.
    event TokenMetadataBaseURISet(string uri);

    /// @notice The transfer lock was permanently removed.
    event TokenTransferLockBurned();

    /// @notice The owner transfer control was permanently removed.
    event OwnerTransferControlBurned();

    // ---
    // storage
    // ---

    /// @notice If set, metadata is resolved by an external contract.
    IMetadataResolver public metadataResolver;

    /// @notice Total number of minted tokens.
    uint256 public totalSupply;

    /// @notice The URI for the collection-level metadata, checked by OpenSea.
    string public contractURI;

    /// @notice the URI prefix for token-level metadata.
    string public tokenMetadataBaseURI;

    /// @notice If true, normal token transfers are enabled. Once set, it cannot be unset.
    bool public isTransferLockBurned;

    /// @notice If true, contract owner no longer has unilateral transfer
    /// privileges. Once set, it cannot be unset.
    bool public isOwnerTransferControlBurned;

    // ---
    // constructor
    // ---

    constructor(string memory _contractURI, string memory _tokenURI)
        ERC721("Metalabel ASSEMBLY 001", "ASSEMBLY-001")
        Owned(msg.sender)
    {
        contractURI = _contractURI;
        tokenMetadataBaseURI = _tokenURI;
    }

    // ---
    // Owner functionality
    // ---

    /// @notice Mint NFTs to an array of recipients. Only callable by owner.
    function batchMint(address[] calldata recipients) external onlyOwner {
        // copy to memory to avoid incrementing the storage variable
        uint256 tokenId = totalSupply;

        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], ++tokenId);
        }

        // update total supply to be last issued token ID
        totalSupply = tokenId;
    }

    /// @notice Set the metadata resolver. Only callable by owner.
    function setMetadataResolver(IMetadataResolver resolver)
        external
        onlyOwner
    {
        metadataResolver = resolver;
        emit MetadataResolverSet(resolver);
    }

    /// @notice Update the contract metadata URI. Only callable by owner.
    function setContractURI(string calldata uri) external onlyOwner {
        contractURI = uri;
        emit ContractURISet(uri);
    }

    //// @notice Update the token metadata base URI. Only callable by owner.
    function setTokenURI(string calldata uri) external onlyOwner {
        tokenMetadataBaseURI = uri;
        emit TokenMetadataBaseURISet(uri);
    }

    /// @notice Permanently remove the transfer lock. Only callable by owner.
    function burnTransferLock() external onlyOwner {
        isTransferLockBurned = true;
        emit TokenTransferLockBurned();
    }

    /// @notice Permanently remove the owner transfer control. Only callable by owner.
    function burnOwnerTransferControl() external onlyOwner {
        isOwnerTransferControlBurned = true;
        emit OwnerTransferControlBurned();
    }

    /// @notice Transfer a token to a new owner. Only callable by owner. Not
    /// callable if the owner transfer control fuse has been burned.
    function adminTransfer(uint256 tokenId, address to) external onlyOwner {
        require(
            !isOwnerTransferControlBurned,
            "OWNER_TRANSFER_CONTROL_DISABLED"
        );

        address currentOwner = _ownerOf[tokenId];
        require(currentOwner != address(0), "NOT_MINTED");

        // transfer logic, copy-pasted from underlying erc721 implementation.
        // unchecked math since overflow not feasible.
        _ownerOf[tokenId] = to;
        unchecked {
            _balanceOf[currentOwner]--;
            _balanceOf[to]++;
        }
        emit Transfer(currentOwner, to, tokenId);
    }

    // ---
    // transfer functionality
    // ---

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        require(isTransferLockBurned, "TRANSFER_LOCKED");

        ERC721.transferFrom(from, to, id);
    }

    // ---
    // metadata logic
    // ---

    /// @notice Return the metadata URI for a token.
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        // default to using an external resolver if we override it
        if (metadataResolver != IMetadataResolver(address(0))) {
            return metadataResolver.resolve(address(this), tokenId);
        }

        // otherwise concatenate the base URI and the token ID
        return
            string(
                abi.encodePacked(
                    tokenMetadataBaseURI,
                    Strings.toString(tokenId),
                    ".json"
                )
            );
    }
}