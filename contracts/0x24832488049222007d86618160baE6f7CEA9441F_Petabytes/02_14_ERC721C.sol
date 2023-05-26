// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @notice Extension of Chiru Labs ERC721 implementation, including
 * Merkle proof allowlist validation and a state machine.
 * See https://www.erc721a.org/.
 * @notice This contract inherits from Ownable, an access control contract
 * which grants this contract's owner exclusive access to certain functions.
 * Ownership may be transferred and/or renounced by this contract's owner.
 * Calling the `owner` function of this contract will return the address of the owner.
 * @author backuardo.eth
 */
contract ERC721C is ERC721A, Ownable, ReentrancyGuard {
    // Enum representing the state of the mint
    enum MintPhase {
        NONE,
        PAUSED,
        ALLOWLIST_SALE,
        PUBLIC_SALE,
        SOLD_OUT
    }

    uint256 public immutable collectionSize;
    // Public mint price per token, in wei
    uint256 public immutable mintPricePublic;
    // Allowlist mint price per token, in wei
    uint256 public immutable mintPriceAllowlist;
    uint256 public immutable maxPerWalletPublic;
    uint256 public immutable maxPerWalletAllowlist;

    string private baseURI;
    // Root hash for allowlist merkle tree (generated off-chain)
    bytes32 public merkleRoot;
    // Current state of the mint
    MintPhase public mintPhase = MintPhase.NONE;

    /**
     * @dev `_maxPerWalletPublic` and `_maxPerWalletAllowlist` should be restricted in size
     * to prevent overly expensive transfer fees for tokens minted in large batches. For excessively
     * large values, the `mint` and `allowlistMint` functions should be overridden to implement batching.
     * See https://chiru-labs.github.io/ERC721A/#/tips?id=batch-size
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _collectionSize,
        uint256 _mintPricePublic,
        uint256 _mintPriceAllowlist,
        uint256 _maxPerWalletPublic,
        uint256 _maxPerWalletAllowlist
    ) ERC721A(_name, _symbol) {
        collectionSize = _collectionSize;
        mintPricePublic = _mintPricePublic;
        mintPriceAllowlist = _mintPriceAllowlist;
        maxPerWalletPublic = _maxPerWalletPublic;
        maxPerWalletAllowlist = _maxPerWalletAllowlist;
    }

    ////////////////////////
    // MODIFIER FUNCTIONS //
    ////////////////////////

    /**
     * @notice Ensure function cannot be called outside of a given mint phase
     * @param _mintPhase Correct mint phase for function to execute
     */
    modifier inMintPhase(MintPhase _mintPhase) {
        require(mintPhase == _mintPhase, "ERC721C: incorrect mint phase");
        _;
    }

    ////////////////////
    // MINT FUNCTIONS //
    ////////////////////

    /**
     * @notice Mint a quantity of tokens during allowlist mint phase by providing a Merkle proof
     * @param _quantity Number of tokens to mint
     * @param _proof Merkle proof to verify msg.sender is part of the allowlist
     */
    function allowlistMint(uint256 _quantity, bytes32[] calldata _proof)
        external
        payable
        virtual
        nonReentrant
        inMintPhase(MintPhase.ALLOWLIST_SALE)
    {
        //// CHECKS ////
        require(
            MerkleProof.verify(
                _proof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "ERC721C: invalid proof"
        );
        require(
            msg.value == mintPriceAllowlist * _quantity,
            "ERC721C: incorrect payment"
        );
        require(
            totalSupply() + _quantity <= collectionSize,
            "ERC721C: insufficient supply"
        );
        require(
            getRedemptionsAllowlist() + _quantity <= maxPerWalletAllowlist,
            "ERC721C: exceeds allowlist max"
        );

        //// EFFECTS ////
        incrementRedemptionsAllowlist(_quantity);

        //// INTERACTIONS ////
        _safeMint(msg.sender, _quantity);
    }

    /**
     * @notice Mint a quantity of tokens during public mint phase
     * @param _quantity Number of tokens to mint
     */
    function mint(uint256 _quantity)
        external
        payable
        virtual
        nonReentrant
        inMintPhase(MintPhase.PUBLIC_SALE)
    {
        //// CHECKS ////
        require(
            msg.value == mintPricePublic * _quantity,
            "ERC721C: incorrect payment"
        );
        require(
            totalSupply() + _quantity <= collectionSize,
            "ERC721C: insufficient supply"
        );
        require(
            getRedemptionsPublic() + _quantity <= maxPerWalletPublic,
            "ERC721C: exceeds public max"
        );

        //// EFFECTS ////
        incrementRedemptionsPublic(_quantity);

        //// INTERACTIONS ////
        _safeMint(msg.sender, _quantity);
    }

    //////////////////////
    // SETTER FUNCTIONS //
    //////////////////////

    /**
     * @notice Set the allowlist Merkle root in contract storage
     * @notice Use restricted to contract owner
     * @param _merkleRoot New Merkle root hash
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Set the state machine mint phase
     * @notice Use restricted to contract owner
     * @param _mintPhase New mint phase
     */
    function setMintPhase(MintPhase _mintPhase) external onlyOwner {
        mintPhase = _mintPhase;
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
    function getRedemptionsAllowlist() public view returns (uint256) {
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
    function getRedemptionsPublic() public view returns (uint256) {
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
    function _baseURI() internal view virtual override returns (string memory) {
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
        //// CHECKS ////
        require(
            totalSupply() + _quantity <= collectionSize,
            "ERC721C: insufficient supply"
        );

        //// INTERACTIONS ////
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
        require(success, "ERC721C: transfer failed");
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Prevent accidental ETH transfer
     */
    fallback() external payable {
        require(false, "ERC721C: not implemented");
    }

    /**
     * @notice Prevent accidental ETH transfer
     */
    receive() external payable {
        require(false, "ERC721C: not implemented");
    }
}