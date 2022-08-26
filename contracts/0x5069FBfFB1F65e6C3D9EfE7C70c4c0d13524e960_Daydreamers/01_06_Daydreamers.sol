// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓████████████▓▒░░░░░░░▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░▓██████████████████▓▒▒▓████████████▒░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░▓███████████████████████████████████████▒░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░██████████████████████████████████████████▓░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░█████████████████████████████████████████████░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░▓█████████████████████████████████████████████▓░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░▒▓▓██████████████████▓▒▒▓██████████████████████████▒░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░▒█████████████████████▓░░░░░░████▓▓▓▓██████████████████▓▓▒░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░▒███████████████████████▒░░░░░░▓█▓░░░░░░█████████████████████▓▒░░░░░░░░░░░░░░
░░░░░░░░░░░░███████████████████▓██████▒░░░░▓██▒░░░░░░████████████████████████▒░░░░░░░░░░░░
░░░░░░░░░░░██████████████████▓░░░██████████████▒░░░░▓█████████████████████████▓░░░░░░░░░░░
░░░░░░░░░░▓███████████████████▒░░░▓██████████████████████▓▒████████████████████▓░░░░░░░░░░
░░░░░░░░░░█████████████████████▓░░░░▓██████████████████▒░░░▒████████████████████░░░░░░░░░░
░░░░░░░░░░███████████████████████▓░░░░▒▒▓█████████▓▓▒░░░░▒▓█████████████████████▒░░░░░░░░░
░░░░░░░░░░█████████████████████████▓▒░░░░░░░░░░░░░░░░░▒▓████████████████████████▒░░░░░░░░░
░░░░░░░░░░██████████████████████████████▓▓▓▒▒▒▒▒▓▓▓█████████████████████████████░░░░░░░░░░
░░░░░░░░░░░█████████████████████████████████████████████████████████████████████░░░░░░░░░░
░░░░░░░░░░░░███████████████████████████████████████████████████████████████████░░░░░░░░░░░
░░░░░░░░░░░░░▒███████████████████████████████████████████████████████████████▓░░░░░░░░░░░░
░░░░░░░░░░░░░░░░▓██████████████████████████████████████████████████████████▓░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░▒▒▓▓███████████████████████████████████████████████▓▒░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 
 */

/**
 * @notice This contract inherits from Ownable, an access control contract
 * which grants this contract's owner exclusive access to certain functions.
 * Ownership may be transferred and/or renounced by this contract's owner.
 * Calling the `owner` function of this contract will return the address of the owner.
 * @notice The following outlines how final token metadata will be fairly distributed
 * (inspired by Bored Ape Yacht Club https://boredapeyachtclub.com/#/provenance):
 * 1. A provenance hash is stored in the contract so the order of token metadata
 * cannot be changed at any point. The provenance hash is obtained by hashing each
 * token image using the SHA-256 algorithm, concatenating each result in their
 * final order, then hashing the result using the SHA-256 algorithm.
 * 2. The block number in which the final token has been minted will be used to
 * generate an index into the previously-ordered metadata (see getInitialMetadataSequenceIndex).
 * @author backuardo.eth
 */
contract Daydreamers is ERC721A, Ownable, ReentrancyGuard {
    enum MintPhase {
        NONE,
        PAUSED,
        ALLOWLIST_SALE,
        PUBLIC_SALE,
        SOLD_OUT
    }

    uint16 public constant COLLECTION_SIZE = 7000;
    uint8 public constant MAX_PER_ADDRESS_PUBLIC = 10;
    uint256 public constant MINT_PRICE_PUBLIC = 0.03 ether;

    string private baseURI;
    string public provenanceHash;
    uint256 public initialMetadataSequenceIndex;
    MintPhase public mintPhase = MintPhase.NONE;
    mapping(address => uint8) public maxAllowlistRedemptions;

    /**
     * @param _provenanceHash provenance record
     */
    constructor(string memory _provenanceHash) ERC721A("Daydreamers", "DREAM") {
        provenanceHash = _provenanceHash;
    }

    ////////////////////////
    // MODIFIER FUNCTIONS //
    ////////////////////////

    /**
     * @notice Ensure function cannot be called outside of a given mint phase
     * @param _mintPhase Correct mint phase for function to execute
     */
    modifier inMintPhase(MintPhase _mintPhase) {
        if (mintPhase != _mintPhase) {
            revert IncorrectMintPhase();
        }
        _;
    }

    ////////////////////
    // MINT FUNCTIONS //
    ////////////////////

    /**
     * @notice Mint a quantity of tokens during allowlist mint phase by providing a Merkle proof
     * @param _quantity Number of tokens to mint
     */
    function allowlistMint(uint8 _quantity)
        external
        inMintPhase(MintPhase.ALLOWLIST_SALE)
        nonReentrant
    {
        if (maxAllowlistRedemptions[msg.sender] == 0) {
            revert NotAllowlisted();
        }
        if (totalSupply() + _quantity > COLLECTION_SIZE) {
            revert InsufficientSupply();
        }
        if (
            getRedemptionsAllowlist() + _quantity >
            maxAllowlistRedemptions[msg.sender]
        ) {
            revert ExceedsAllowlistMaxAllocation();
        }

        incrementRedemptionsAllowlist(_quantity);
        if (totalSupply() + _quantity == COLLECTION_SIZE) {
            setInitialMetadataSequenceIndex();
        }

        _safeMint(msg.sender, _quantity);
    }

    /**
     * @notice Mint a quantity of tokens during public mint phase
     * @param _quantity Number of tokens to mint
     */
    function mint(uint8 _quantity)
        external
        payable
        inMintPhase(MintPhase.PUBLIC_SALE)
        nonReentrant
    {
        if (msg.value != MINT_PRICE_PUBLIC * _quantity) {
            revert IncorrectPayment();
        }
        if (totalSupply() + _quantity > COLLECTION_SIZE) {
            revert InsufficientSupply();
        }
        if (getRedemptionsPublic() + _quantity > MAX_PER_ADDRESS_PUBLIC) {
            revert ExceedsPublicMaxAllocation();
        }

        incrementRedemptionsPublic(_quantity);
        if (totalSupply() + _quantity == COLLECTION_SIZE) {
            setInitialMetadataSequenceIndex();
        }

        _safeMint(msg.sender, _quantity);
    }

    //////////////////////
    // SETTER FUNCTIONS //
    //////////////////////

    /**
     * @notice Set the mint phase
     * @notice Use restricted to contract owner
     * @param _mintPhase New mint phase
     */
    function setMintPhase(MintPhase _mintPhase) external onlyOwner {
        mintPhase = _mintPhase;
    }

    /**
     * @notice Add entries to the maxAllowlistRedemptions mapping
     * @notice Use restricted to contract owner
     * @dev Array arguments must have the same ordering, as _addresses[i] will map to _redemptions[i]
     * @param _addresses Array containing addresses to add (keys)
     * @param _redemptions Array containing numbers of redemptions (values)
     */
    function setMaxAllowlistRedemptions(
        address[] calldata _addresses,
        uint8[] calldata _redemptions
    ) external onlyOwner {
        if (_addresses.length != _redemptions.length) {
            revert BadArguments();
        }

        for (uint256 i = 0; i < _addresses.length; i++) {
            maxAllowlistRedemptions[_addresses[i]] = _redemptions[i];
        }
    }

    /**
     * @notice Set the contract base token uri
     * @notice Use restricted to contract owner
     * @param _baseTokenURI New base token uri
     */
    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    /**
     * @notice Set starting index into previously-ordered metadata for reveal
     */
    function setInitialMetadataSequenceIndex() private {
        initialMetadataSequenceIndex =
            uint256(blockhash(block.number - 1)) %
            COLLECTION_SIZE;
    }

    /**
     * @notice Increment number of allowlist token mints redeemed by caller
     * @dev We cast the _numToIncrement argument into uint32, which will not be an issue as
     * mint quantity should never be greater than 2^32 - 1.
     * @dev Number of redemptions are stored in ERC721A auxillary storage, which can help
     * remove an extra cold SLOAD and SSTORE operation. Since we're storing two values
     * (public and allowlist redemptions) we need to pack and unpack two uint32s into a single uint64.
     * See https://chiru-labs.github.io/ERC721A/#/erc721a?id=addressdata
     */
    function incrementRedemptionsAllowlist(uint256 _numToIncrement) private {
        (
            uint32 allowlistMintRedemptions,
            uint32 publicMintRedemptions
        ) = unpackMintRedemptions(_getAux(msg.sender));
        allowlistMintRedemptions += uint32(_numToIncrement);
        _setAux(
            msg.sender,
            packMintRedemptions(allowlistMintRedemptions, publicMintRedemptions)
        );
    }

    /**
     * @notice Increment number of public token mints redeemed by caller
     * @dev We cast the _numToIncrement argument into uint32, which will not be an issue as
     * mint quantity should never be greater than 2^32 - 1.
     * @dev Number of redemptions are stored in ERC721A auxillary storage, which can help
     * remove an extra cold SLOAD and SSTORE operation. Since we're storing two values
     * (public and allowlist redemptions) we need to pack and unpack two uint32s into a single uint64.
     * See https://chiru-labs.github.io/ERC721A/#/erc721a?id=addressdata
     */
    function incrementRedemptionsPublic(uint256 _numToIncrement) private {
        (
            uint32 allowlistMintRedemptions,
            uint32 publicMintRedemptions
        ) = unpackMintRedemptions(_getAux(msg.sender));
        publicMintRedemptions += uint32(_numToIncrement);
        _setAux(
            msg.sender,
            packMintRedemptions(allowlistMintRedemptions, publicMintRedemptions)
        );
    }

    //////////////////////
    // GETTER FUNCTIONS //
    //////////////////////

    /**
     * @notice Unpack and get number of allowlist token mints redeemed by caller
     * @return number of allowlist redemptions used
     * @dev Number of redemptions are stored in ERC721A auxillary storage, which can help
     * remove an extra cold SLOAD and SSTORE operation. Since we're storing two values
     * (public and allowlist redemptions) we need to pack and unpack two uint32s into a single uint64.
     * See https://chiru-labs.github.io/ERC721A/#/erc721a?id=addressdata
     */
    function getRedemptionsAllowlist() public view returns (uint32) {
        (uint32 allowlistMintRedemptions, ) = unpackMintRedemptions(
            _getAux(msg.sender)
        );
        return allowlistMintRedemptions;
    }

    /**
     * @notice Unpack and get number of public token mints redeemed by caller
     * @return number of public redemptions used
     * @dev Number of redemptions are stored in ERC721A auxillary storage, which can help
     * remove an extra cold SLOAD and SSTORE operation. Since we're storing two values
     * (public and allowlist redemptions) we need to pack and unpack two uint32s into a single uint64.
     * See https://chiru-labs.github.io/ERC721A/#/erc721a?id=addressdata
     */
    function getRedemptionsPublic() public view returns (uint32) {
        (, uint32 publicMintRedemptions) = unpackMintRedemptions(
            _getAux(msg.sender)
        );
        return publicMintRedemptions;
    }

    /**
     * @return Current mint phase
     */
    function getMintPhase() public view returns (MintPhase) {
        return mintPhase;
    }

    /**
     * @return Current base token uri
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    //////////////////////
    // HELPER FUNCTIONS //
    //////////////////////

    /**
     * @notice Pack two uint32s (allowlist and public redemptions) into a single uint64 value
     * @return Packed value
     * @dev Performs shift and bit operations to pack two uint32s into a single uint64
     */
    function packMintRedemptions(
        uint32 _allowlistMintRedemptions,
        uint32 _publicMintRedemptions
    ) private pure returns (uint64) {
        return
            (uint64(_allowlistMintRedemptions) << 32) |
            uint64(_publicMintRedemptions);
    }

    /**
     * @notice Unpack a single uint64 value into two uint32s (allowlist and public redemptions)
     * @return allowlistMintRedemptions publicMintRedemptions Unpacked values
     * @dev Performs shift and bit operations to unpack a single uint64 into two uint32s
     */
    function unpackMintRedemptions(uint64 _mintRedemptionPack)
        private
        pure
        returns (uint32 allowlistMintRedemptions, uint32 publicMintRedemptions)
    {
        allowlistMintRedemptions = uint32(_mintRedemptionPack >> 32);
        publicMintRedemptions = uint32(_mintRedemptionPack);
    }

    /////////////////////
    // ADMIN FUNCTIONS //
    /////////////////////

    /**
     * @notice Mint a quantity of tokens to the contract owners address
     * @notice Use restricted to contract owner
     * @param _quantity Number of tokens to mint
     * @dev Must be executed in `MintPhase.NONE` (i.e., before allowlist or public mint begins)
     * @dev Minting in batches will not help prevent overly expensive transfer fees, since
     * token ids are sequential and dev minting occurs before allowlist and public minting.
     * See https://chiru-labs.github.io/ERC721A/#/tips?id=batch-size
     */
    function devMint(uint256 _quantity)
        external
        onlyOwner
        inMintPhase(MintPhase.NONE)
    {
        if (totalSupply() + _quantity > COLLECTION_SIZE) {
            revert InsufficientSupply();
        }

        _safeMint(owner(), _quantity);
    }

    /**
     * @notice Withdraw all funds to the contract owners address
     * @notice Use restricted to contract owner
     * @dev `transfer` and `send` assume constant gas prices. This function
     * is onlyOwner, so we accept the reentrancy risk that `.call.value` carries.
     */
    function withdraw() external onlyOwner {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = owner().call{value: address(this).balance}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @notice Prevent accidental ETH transfer
     */
    fallback() external payable {
        revert NotImplemented();
    }

    /**
     * @notice Prevent accidental ETH transfer
     */
    receive() external payable {
        revert NotImplemented();
    }
}

/**
 * Incorrect mint phase for action
 */
error IncorrectMintPhase();

/**
 * Incorrect payment amount
 */
error IncorrectPayment();

/**
 * Insufficient supply for action
 */
error InsufficientSupply();

/**
 * Not allowlisted
 */
error NotAllowlisted();

/**
 * Exceeds max allocation for public sale
 */
error ExceedsPublicMaxAllocation();

/**
 * Exceeds max allocation for allowlist sale
 */
error ExceedsAllowlistMaxAllocation();

/**
 * Public mint price not set
 */
error PublicMintPriceNotSet();

/**
 * Transfer failed
 */
error TransferFailed();

/**
 * Bad arguments
 */
error BadArguments();

/**
 * Function not implemented
 */
error NotImplemented();