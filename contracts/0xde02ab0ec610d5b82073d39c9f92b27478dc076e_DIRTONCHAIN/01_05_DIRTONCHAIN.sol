// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/*//////////////////////////////////////////////////////////////
                        EXTERNAL IMPORTS
//////////////////////////////////////////////////////////////*/

import "solmate/utils/MerkleProofLib.sol";
import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {Owned} from "solmate/auth/Owned.sol";

/*//////////////////////////////////////////////////////////////
                        INTERNAL IMPORTS
//////////////////////////////////////////////////////////////*/

import "./LilBase64.sol";

/*//////////////////////////////////////////////////////////////
                                EVENTS
//////////////////////////////////////////////////////////////*/

library Events {
    /// @notice Emitted after Merkle root is changed
    /// @param tokenId for which Merkle root was set or updated
    /// @param oldMerkleRoot used for validating claims against a token ID
    /// @param newMerkleRoot used for validating claims against a token ID
    event MerkleRootChanged(
        uint256 tokenId,
        bytes32 oldMerkleRoot,
        bytes32 newMerkleRoot
    );

    /// @notice Emitted after contract is enabled or disabled
    /// @param oldEnabled status of contract
    /// @param newEnabled status of contract
    event EnabledChanged(bool oldEnabled, bool newEnabled);

    /// @notice Emitted after image data is changed
    /// @param tokenId for which image data was set or updated
    /// @param oldImageData used for a token ID
    /// @param newImageData used for a token ID
    event ImageDataChanged(
        uint256 tokenId,
        string oldImageData,
        string newImageData
    );

    /// @notice Emitted after name is changed
    /// @param tokenId for which name was set or updated
    /// @param oldName used for a token ID
    /// @param newName used for a token ID
    event NameChanged(uint256 tokenId, string oldName, string newName);

    /// @notice Emitted after description is changed
    /// @param tokenId for which description was set or updated
    /// @param oldDescription used for a token ID
    /// @param newDescription used for a token ID
    event DescriptionChanged(
        uint256 tokenId,
        string oldDescription,
        string newDescription
    );

    /// @notice Emitted after contract name is changed
    /// @param oldName of contract
    /// @param newName of contract
    event NameChanged(string oldName, string newName);

    /// @notice Emitted after contract symbol is changed
    /// @param oldSymbol of contract
    /// @param newSymbol of contract
    event SymbolChanged(string oldSymbol, string newSymbol);
}

/*//////////////////////////////////////////////////////////////
                            CONTRACT
//////////////////////////////////////////////////////////////*/

/// @title DIRTONCHAIN
/// @notice Commemorative Dirt tokens claimable by members of a Merkle tree
/// @author DefDAO <https://definitely.shop/>
contract DIRTONCHAIN is Owned, ERC1155 {
    /*//////////////////////////////////////////////////////////////
                             MUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Token name (not in ERC1155 standard but still used)
    string public name;

    /// @notice Token symbol (not in ERC1155 standard but still used)
    string public symbol;

    /// @notice Overall contract status
    bool public enabled;

    /// @notice Mapping of Merkle roots for different NFTs
    mapping(uint256 => bytes32) public merkleRoots;

    /// @notice Mapping of image data
    mapping(uint256 => string) public imageData;

    /// @notice Mapping of descriptions
    mapping(uint256 => string) public descriptions;

    /// @notice Mapping of names
    mapping(uint256 => string) public names;

    /// @notice Mapping of mint status for hashed address + ID combos (as integers)
    mapping(uint256 => bool) public mintStatus;

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Throws if called when minting is not enabled
    modifier mintingEnabled() {
        if (!enabled) {
            revert MintingNotEnabled();
        }
        _;
    }

    /// @notice Throws if mint attempted on a token that was already minted
    modifier tokenNotYetClaimed(uint256 tokenId) {
        if (
            mintStatus[uint256(keccak256(abi.encode(msg.sender, tokenId)))] !=
            false
        ) {
            revert NotAllowedToMintAgain();
        }
        _;
    }

    /// @notice Throws if mint attempted on a token that does not exists
    modifier tokenExists(uint256 tokenId) {
        if (merkleRoots[tokenId] == 0) {
            revert TokenDoesNotExist();
        }
        _;
    }

    /// @notice Throws if burn attempted on a token not owned by sender
    modifier hasToken(uint256 tokenId, address burner) {
        if (balanceOf[burner][tokenId] == 0) {
            revert NotAllowedToBurn();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown if minting attempted when contract not enabled
    error MintingNotEnabled();

    /// @notice Thrown if burn attempted on token not owned by address
    error NotAllowedToBurn();

    /// @notice Thrown if address has already minted its token for token ID
    error NotAllowedToMintAgain();

    /// @notice Thrown if address is not part of Merkle tree for token ID
    error NotInMerkle();

    /// @notice Thrown if a non-existent token is queried
    error TokenDoesNotExist();

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a new DIRTONCHAIN contract
    /// @param _enabled to start
    /// @param _initialMerkleRoot to start
    /// @param _initialImageData to start
    constructor(
        bool _enabled,
        bytes32 _initialMerkleRoot,
        string memory _initialImageData,
        string memory _initialName,
        string memory _initialDescription
    ) Owned(msg.sender) {
        enabled = _enabled;
        merkleRoots[1] = _initialMerkleRoot;
        imageData[1] = _initialImageData;
        names[1] = _initialName;
        descriptions[1] = _initialDescription;
        name = "DIRTONCHAIN";
        symbol = "DIRTONCHAIN";
    }

    /* solhint-disable quotes */
    /// @notice Generates base64 payload for token
    /// @param tokenId for this specific token
    /// @return generatedTokenURIBase64 for this specific token
    function generateTokenURIBase64(uint256 tokenId)
        public
        view
        returns (string memory generatedTokenURIBase64)
    {
        generatedTokenURIBase64 = LilBase64.encode(
            bytes(
                string.concat(
                    '{"name": "',
                    names[tokenId],
                    '", "description": "',
                    descriptions[tokenId],
                    '", "image": "',
                    imageData[tokenId],
                    '"}'
                )
            )
        );
    }

    /* solhint-enable quotes */
    /// @notice Mint a token
    /// @param tokenId of token being minted
    /// @param proof of mint eligibility
    function mint(uint256 tokenId, bytes32[] calldata proof)
        external
        tokenExists(tokenId)
        tokenNotYetClaimed(tokenId)
        mintingEnabled
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        bool isValidLeaf = MerkleProofLib.verify(
            proof,
            merkleRoots[tokenId],
            leaf
        );
        if (!isValidLeaf) revert NotInMerkle();

        mintStatus[uint256(keccak256(abi.encode(msg.sender, tokenId)))] = true;
        _mint(msg.sender, tokenId, 1, "");
    }

    /// @notice Burn a token
    /// @param tokenId of token being burned
    function burn(uint256 tokenId) external hasToken(tokenId, msg.sender) {
        _burn(msg.sender, tokenId, 1);
    }

    /// @notice Gets URI for a specific token
    /// @param tokenId of token being queried
    /// @return base64 URI of token being queried
    function uri(uint256 tokenId)
        public
        view
        override
        tokenExists(tokenId)
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    generateTokenURIBase64(tokenId)
                )
            );
    }

    /// @notice Set a new Merkle root for a given token ID
    /// @param tokenId to get a new or updated Merkle root
    /// @param _merkleRoot to be used for validating claims
    function ownerSetMerkleRoot(uint256 tokenId, bytes32 _merkleRoot)
        public
        onlyOwner
    {
        emit Events.MerkleRootChanged(
            tokenId,
            merkleRoots[tokenId],
            _merkleRoot
        );
        merkleRoots[tokenId] = _merkleRoot;
    }

    /// @notice Set new image data for a given token ID
    /// @param tokenId to get new or updated image data
    /// @param _imageData to be used
    function ownerSetImageData(uint256 tokenId, string calldata _imageData)
        public
        onlyOwner
    {
        emit Events.ImageDataChanged(tokenId, imageData[tokenId], _imageData);
        imageData[tokenId] = _imageData;
    }

    /// @notice Set new name for a given token ID
    /// @param tokenId to get new or updated name
    /// @param _name to be used
    function ownerSetName(uint256 tokenId, string calldata _name)
        public
        onlyOwner
    {
        emit Events.NameChanged(tokenId, names[tokenId], _name);
        names[tokenId] = _name;
    }

    /// @notice Set new description for a given token ID
    /// @param tokenId to get new or updated description
    /// @param _description to be used
    function ownerSetDescription(uint256 tokenId, string calldata _description)
        public
        onlyOwner
    {
        emit Events.DescriptionChanged(
            tokenId,
            descriptions[tokenId],
            _description
        );
        descriptions[tokenId] = _description;
    }

    /// @notice Update the contract's enabled status
    /// @param _enabled status for the contract
    function ownerSetEnabled(bool _enabled) public onlyOwner {
        emit Events.EnabledChanged(enabled, _enabled);
        enabled = _enabled;
    }

    /// @notice Update the contract's name
    /// @param _name for the contract
    function ownerSetName(string calldata _name) public onlyOwner {
        emit Events.NameChanged(name, _name);
        name = _name;
    }

    /// @notice Update the contract's symbol
    /// @param _symbol for the contract
    function ownerSetSymbol(string calldata _symbol) public onlyOwner {
        emit Events.SymbolChanged(symbol, _symbol);
        symbol = _symbol;
    }
}