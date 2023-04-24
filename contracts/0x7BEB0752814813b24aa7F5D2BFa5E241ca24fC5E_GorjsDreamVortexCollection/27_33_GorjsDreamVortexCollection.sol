// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    MerkleProof
} from "../../lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

import {
    ERC721PartnerSeaDropUpgradeable
} from "../ERC721PartnerSeaDropUpgradeable.sol";

/**
 * @title GorjsDreamVortexCollection
 * @author Harry.
 * @dev Implementation of Genesis nft collection based on OS Seadrop
 */
contract GorjsDreamVortexCollection is ERC721PartnerSeaDropUpgradeable {
    enum MintStage {
        Pause,
        Fkwme
    }

    /// @notice Track the allow list merkle roots.
    bytes32 private _allowListMerkleRoot;

    /// @notice Current mint stage.
    MintStage public mintStage;

    /// @notice Mint status for each user for pahse 1.
    mapping(address => uint256) private mintStatus;
    
    /**
     * @notice Initialize the token contract with its name, symbol,
     *         administrator, and allowed SeaDrop addresses.
     */
    function initialize(
        string memory name,
        string memory symbol,
        address administrator,
        address[] memory allowedSeaDrop
    ) external initializer initializerERC721A {
        __ERC721PartnerSeaDrop_init(
            name,
            symbol,
            administrator,
            allowedSeaDrop
        );
    }

    /**
     * @dev Mint stage can only be set by an Admin.
     * @param _mintStage New mint stage to be set.
     * @param merkleRoot_ New hash of root node of merkle tree.
     */
    function setMintStage(MintStage _mintStage, bytes32 merkleRoot_) external onlyOwner {
        mintStage = _mintStage;
        _allowListMerkleRoot = merkleRoot_;
    }

    /**
     * @notice Mint from an allow list.
     *
     * @param quantity         The number of tokens to mint.
     * @param proof            The proof for the leaf of the allow list.
     */
    function mint(uint256 quantity, bytes32[] calldata proof) external {
        require(tx.origin == msg.sender, "Caller is SC");

        require(
            mintStage != MintStage.Pause
        );

        require(mintStatus[msg.sender] == 0, "Already minted");
        
        // Verify the proof.
        require(
            MerkleProof.verify(
                proof,
                _allowListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, quantity))
            ), 
            "Not whitelisted"
        );

        // Set mint status as 1
        mintStatus[msg.sender] = 1;
        
        // Mint the token(s), split the payout, emit an event.
        require(_totalMinted() + quantity <= maxSupply(), "You can't mint more than maximum supply.");

        // Mint the quantity of tokens to the minter.
        _safeMint(msg.sender, quantity);
    }

    /**
     * @notice Burns `tokenIds`. The caller must own `tokenIds` or be an
     *         approved operator.
     *
     * @param tokenIds The array of token ids to burn.
     */
    // solhint-disable-next-line comprehensive-interface
    function burn(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; ) {
            _burn(tokenIds[i], true);

            unchecked {
                ++i;
            }
        }
    }

    /** Querable function */
    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner)
        external
        view
        virtual
        returns (uint256[] memory)
    {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (
                uint256 i = _startTokenId();
                tokenIdsIdx != tokenIdsLength;
                ++i
            ) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    /**
    * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return baseURI;
    }

}