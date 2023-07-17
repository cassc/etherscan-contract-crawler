// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "OwnableUpgradeable.sol";
import "ERC721EnumerableUpgradeable.sol";
import "ERC721URIStorageUpgradeable.sol";
import "MerkleProofUpgradeable.sol";
import "ReentrancyGuardUpgradeable.sol";
import "AddressUpgradeable.sol";


/**
 * @dev NFT Contract that supports
 * - Enumerability
 * - Per token URIs
 *   - See: openzeppelin-contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol
 * - Royalties
 */
contract AICryptoadz is OwnableUpgradeable, ReentrancyGuardUpgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable {
    /**
     * @dev Calls initializers of inherited contracts.
     */
    constructor(
        string memory baseTokenURI,
        bytes32 rootHash
    ) initializer {
        __ERC721_init("AICryptoadz", "AITD");
        __Ownable_init();
        __ReentrancyGuard_init();

        _baseTokenURI = baseTokenURI;
        _rootHash = rootHash;
    }

    ////////////////////////////////////////////////////////////////////////////
    // Interfaces
    ////////////////////////////////////////////////////////////////////////////

    /**
     *  @dev Rarible: RoyaltiesV1
     *
     *  bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *  bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     *
     *  => 0xb9c4d9fb ^ 0x0ebd4c7f = 0xb7799584
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    /**
     *  @dev Foundation
     *
     *  bytes4(keccak256('getFees(uint256)')) == 0xd5a06d4c
     *
     *  => 0xd5a06d4c = 0xd5a06d4c
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_FOUNDATION = 0xd5a06d4c;

    /**
     *  @dev EIP-2981
     *
     * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
     *
     * => 0x2a55205a = 0x2a55205a
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721EnumerableUpgradeable, ERC721Upgradeable) returns (bool) {
        return
            interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE ||
            interfaceId == _INTERFACE_ID_ROYALTIES_FOUNDATION ||
            interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 ||
            super.supportsInterface(interfaceId);
    }

    ////////////////////////////////////////////////////////////////////////////
    // Events
    ////////////////////////////////////////////////////////////////////////////

    event DefaultRoyaltiesUpdated(address payable[] receivers, uint256[] basisPoints);

    ////////////////////////////////////////////////////////////////////////////
    // Vars
    ////////////////////////////////////////////////////////////////////////////

    // Mapping for token URIs
    string private _baseTokenURI;

    // Minting vars
    uint256 constant public MINT_PRICE = 0.06 ether;
    uint256 constant public MINTS_PER_OWNER = 5;
    uint256 constant public MINTS_FREE = 3000;
    uint256 constant public MINTS_TOTAL = 6969;
    MintState public MINT_STATE = MintState.Waiting;

    // Royalties
    address payable[] internal _royaltyReceivers;
    uint256[] internal _royaltyBPS;

    // Merkle Whitelist
    bytes32 _rootHash;

    ////////////////////////////////////////////////////////////////////////////
    // Minting
    ////////////////////////////////////////////////////////////////////////////

    /// Internal mint state, used for controlling who can mint.
    /// @dev Enum      -> int
    /// @dev Waiting   -> 0
    /// @dev Whitelist -> 1
    /// @dev Public    -> 2
    enum MintState {
        Waiting,
        Whitelist,
        Public
    }

    // Mint without setting tokenURI
    function mint(uint16 count) external payable {
        require(
            MINT_STATE == MintState.Public, "Public minting has not begun!");
        require(totalSupply() + count <= MINTS_TOTAL, "Mint exceeds max allowed.");
        require(count + balanceOf(_msgSender()) <= MINTS_PER_OWNER, "Exceeded mints per owner.");

        if (totalSupply() >= MINTS_FREE) {
            require(msg.value >= MINT_PRICE * count, "Not enough ETH.");
        }

        for (uint16 i = 0; i < count; i++) {
            _mint(_msgSender(), "");
        }
    }

    // Mint and set token URI given a valid proof for the minter
    function mint(bytes32[] calldata proof, uint16 count) external payable {
        require(MINT_STATE == MintState.Whitelist, "Not in whitelist mint phase!");
        require(totalSupply() + count <= MINTS_FREE, "No more free mints left!");
        require(count + balanceOf(_msgSender()) <= MINTS_PER_OWNER, "Exceeded mints per owner.");

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProofUpgradeable.verify(proof, _rootHash, leaf), "Bad proof for minter.");

        for (uint16 i = 0; i < count; i++) {
            _mint(_msgSender(), "");
        }
    }

    function ownerMint(address to, uint16 count) external onlyOwner {
        require(count <= 100, "Max mints per tx is 100!");

        for (uint16 i = 0; i < count; i++) {
            _mint(to, "");
        }
    }

    function _mint(address to, string memory uri) internal returns(uint256 tokenId) {
        if (_msgSender() != owner()) {
            require(balanceOf(to) < MINTS_PER_OWNER, "Exceeded mints per owner.");
        }

        tokenId = totalSupply() + 1;
        _safeMint(to, tokenId);

        if (bytes(uri).length > 0) {
            _setTokenURI(tokenId, uri);
        }

        return tokenId;
    }

    function setState(MintState state) external onlyOwner {
        MINT_STATE = state;
    }

    /// Public mint phase details. These are derived from the MintState through
    /// the phaseDetails function.
    /// @dev Enum -> int
    /// @dev Waiting    -> 0
    /// @dev Whitelist  -> 1
    /// @dev PublicFree -> 2
    /// @dev PublicPaid -> 3
    /// @dev SoldOut    -> 4
    enum MintPhase {
        Waiting,
        Whitelist,
        PublicFree,
        PublicPaid,
        SoldOut
    }

    /// Gives details about which state the mint is in.
    /// @return minted Number of minted tokens
    /// @return mintsRemaining Number of mints remaining in this current phase of mint
    /// @return mintPrice Price of mint in Wei to mint
    /// @return mintPhase Phase of the mint
    function phaseDetails() external view returns (
        uint256 minted,
        uint256 mintsRemaining,
        uint256 mintPrice,
        MintPhase mintPhase)
    {
        if (MINT_STATE == MintState.Waiting) {
            return (totalSupply(), 0, 0, MintPhase.Waiting);
        }

        if (MINT_STATE == MintState.Whitelist) {
            return (totalSupply(), MINTS_FREE, 0, MintPhase.Whitelist);
        }

        if (totalSupply() < MINTS_FREE) {
            return (totalSupply(), MINTS_FREE, 0, MintPhase.PublicFree);
        }

        if (totalSupply() >= MINTS_TOTAL) {
            return (totalSupply(), MINTS_TOTAL, MINT_PRICE, MintPhase.SoldOut);
        }

        return (totalSupply(), MINTS_TOTAL, MINT_PRICE, MintPhase.PublicPaid);
    }

    ////////////////////////////////////////////////////////////////////////////
    // Custom URI
    ////////////////////////////////////////////////////////////////////////////

    function setBaseTokenURI(string calldata uri) external onlyOwner {
        _baseTokenURI = uri;
    }

    ////////////////////////////////////////////////////////////////////////////
    // Royalties
    ////////////////////////////////////////////////////////////////////////////

    function setRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints ) external onlyOwner {
        require(receivers.length == basisPoints.length, "Invalid input");

        uint256 totalBasisPoints;

        for (uint i = 0; i < basisPoints.length; i++) {
            totalBasisPoints += basisPoints[i];
        }

        require(totalBasisPoints < 10000, "Invalid total royalties");

        _royaltyReceivers = receivers;
        _royaltyBPS = basisPoints;

        emit DefaultRoyaltiesUpdated(receivers, basisPoints);
    }

    function getRoyalties(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory) {
        require(_exists(tokenId), "Nonexistent token");
        return (_royaltyReceivers, _royaltyBPS);
    }

    function getFeeRecipients(uint256 tokenId) external view returns (address payable[] memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _royaltyReceivers;
    }

    function getFeeBps(uint256 tokenId) external view returns (uint[] memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _royaltyBPS;
    }

    function getFees(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory) {
        require(_exists(tokenId), "Nonexistent token");
        return (_royaltyReceivers, _royaltyBPS);
    }

    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256) {
        require(_exists(tokenId), "Nonexistent token");
        require(_royaltyReceivers.length <= 1, "More than 1 royalty receiver");

        if (_royaltyReceivers.length == 0) {
            return (address(this), 0);
        }

        return (_royaltyReceivers[0], _royaltyBPS[0]*value/10000);
    }

    function withdraw() external onlyOwner nonReentrant {
        require(address(this).balance > 0, "Insufficient balance");
        AddressUpgradeable.sendValue(payable(msg.sender), address(this).balance);
    }

    ////////////////////////////////////////////////////////////////////////////
    // Overrides
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev If the base token URI is set then return the baseURI concatenated
     * with the token Id. Otherwise return the per token token URI.
     *
     * This is useful for hide and reveal drops the tokenURI is used to gather
     * initial user data but once assets are generated and metadata uploaded to
     * IPFS we can update the baseURI for all tokens and ignore the individual
     * tokenURIs.
     */
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        if (bytes(_baseTokenURI).length > 0) {
            return ERC721Upgradeable.tokenURI(tokenId);
        }

        return ERC721URIStorageUpgradeable.tokenURI(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }
}