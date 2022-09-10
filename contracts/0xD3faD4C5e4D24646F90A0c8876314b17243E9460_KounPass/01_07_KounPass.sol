// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract KounPassERC721A is ERC721A, Ownable, ReentrancyGuard {
    // Enum representing the state of the mint
    enum MintPhase {
        INACTIVE,
        ALLOWLIST_SALE,
        PUBLIC_SALE,
        SOLD_OUT
    }

    uint256 public collectionSize;
    // Public mint price per token, in wei
    uint256 public mintPricePublic;
    // Allowlist mint price per token, in wei
    uint256 public mintPriceAllowlist;
    uint256 public maxPerWalletPublic;
    uint256 public maxPerWalletAllowlist;

    string private baseURI;
    string private hiddenURI;
    // Root hash for allowlist merkle tree (generated off-chain)
    bytes32 public merkleRoot;
    // Current state of the mint
    MintPhase public mintPhase = MintPhase.INACTIVE;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _hiddenTokenURI,
        uint256 _collectionSize,
        uint256 _mintPricePublic,
        uint256 _mintPriceAllowlist,
        uint256 _maxPerWalletPublic,
        uint256 _maxPerWalletAllowlist
    ) ERC721A(_name, _symbol) {
        hiddenURI = _hiddenTokenURI;
        collectionSize = _collectionSize;
        mintPricePublic = _mintPricePublic;
        mintPriceAllowlist = _mintPriceAllowlist;
        maxPerWalletPublic = _maxPerWalletPublic;
        maxPerWalletAllowlist = _maxPerWalletAllowlist;
    }

    /**
     * @notice Ensure function cannot be called outside of a given mint phase
     * @param _mintPhase Correct mint phase for function to execute
     */
    modifier inMintPhase(MintPhase _mintPhase) {
        require(mintPhase == _mintPhase, "incorrect mint phase");
        _;
    }

    /**
     * @notice Mint a quantity of tokens during allowlist mint phase by providing a Merkle proof
     * @param _quantity Number of tokens to mint
     * @param _proof Merkle proof to verify msg.sender is part of the allowlist
     */
    function allowlistMint(uint256 _quantity, bytes32[] calldata _proof) external payable virtual nonReentrant inMintPhase(MintPhase.ALLOWLIST_SALE) {
        require(MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "invalid proof");
        require(msg.value == mintPriceAllowlist * _quantity, "incorrect payment");
        require(totalSupply() + _quantity <= collectionSize, "insufficient supply");
        require(getRedemptionsAllowlist() + _quantity <= maxPerWalletAllowlist,"exceeds allowlist max");

        incrementRedemptionsAllowlist(_quantity);
        _safeMint(msg.sender, _quantity);
    }

    /**
     * @notice Mint a quantity of tokens during public mint phase
     * @param _quantity Number of tokens to mint
     */
    function mint(uint256 _quantity) external payable virtual nonReentrant inMintPhase(MintPhase.PUBLIC_SALE) {
        require(msg.value == mintPricePublic * _quantity, "incorrect payment");
        require(totalSupply() + _quantity <= collectionSize, "insufficient supply");
        require(getRedemptionsPublic() + _quantity <= maxPerWalletPublic, "exceeds public max");

        incrementRedemptionsPublic(_quantity);
        _safeMint(msg.sender, _quantity);
    }

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
     * @param _mintPhase New mint phase, 0 = INACTIVE / 1 = ALLOWLIST_MINT / 2 = PUBLIC_MINT / 3 = SOLD_OUT
     */
    function setMintPhase(MintPhase _mintPhase) external onlyOwner {
        mintPhase = _mintPhase;
    }

    /**
     * @notice Set the contract base token uri
     * @notice Use restricted to contract owner
     * @param _baseTokenURI New base token uri
     */
    function setBaseURI(string calldata _baseTokenURI) public onlyOwner {
        baseURI = _baseTokenURI;
    }

    /**
     * @notice Set the contract hidden token uri
     * @notice Use restricted to contract owner
     * @param _hiddenTokenURI New hidden token uri
     */
    function setHiddenURI(string calldata _hiddenTokenURI) public onlyOwner {
        hiddenURI = _hiddenTokenURI;
    }

    /**
     * @notice Increment number of allowlist token mints redeemed by caller
     * @dev We cast the _numToIncrement argument into uint32, which will not be an issue as
     * mint quantity should never be greater than 2^32 - 1.
     * @dev Number of redemptions are stored in ERC721A auxillary storage, which can help
     */
    function incrementRedemptionsAllowlist(uint256 _numToIncrement) private {
        (uint32 allowlistMintRedemptions, uint32 publicMintRedemptions) = unpackMintRedemptions(_getAux(msg.sender));
        allowlistMintRedemptions += uint32(_numToIncrement);
        _setAux(msg.sender, packMintRedemptions(allowlistMintRedemptions, publicMintRedemptions));
    }

    /**
     * @notice Increment number of public token mints redeemed by caller
     * @dev We cast the _numToIncrement argument into uint32, which will not be an issue as
     * mint quantity should never be greater than 2^32 - 1.
     * @dev Number of redemptions are stored in ERC721A auxillary storage, which can help
     */
    function incrementRedemptionsPublic(uint256 _numToIncrement) private {
        (uint32 allowlistMintRedemptions, uint32 publicMintRedemptions) = unpackMintRedemptions(_getAux(msg.sender));
        publicMintRedemptions += uint32(_numToIncrement);
        _setAux(msg.sender, packMintRedemptions(allowlistMintRedemptions, publicMintRedemptions));
    }

    /**
     * @notice Unpack and get number of allowlist token mints redeemed by caller
     * @return number of allowlist redemptions used
     * @dev Number of redemptions are stored in ERC721A auxillary storage, which can help
     */
    function getRedemptionsAllowlist() public view returns (uint256) {
        (uint32 allowlistMintRedemptions, ) = unpackMintRedemptions(_getAux(msg.sender));
        return allowlistMintRedemptions;
    }

    /**
     * @notice Unpack and get number of public token mints redeemed by caller
     * @return number of public redemptions used
     * @dev Number of redemptions are stored in ERC721A auxillary storage, which can help
     */
    function getRedemptionsPublic() public view returns (uint256) {
        (, uint32 publicMintRedemptions) = unpackMintRedemptions(_getAux(msg.sender));
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

    /**
     * @return Current hidden token uri
     */
    function _hiddenURI() internal view virtual returns (string memory) {
        return hiddenURI;
    }

    /**
     * @notice Pack two uint32s (allowlist and public redemptions) into a single uint64 value
     * @return Packed value
     * @dev Performs shift and bit operations to pack two uint32s into a single uint64
     */
    function packMintRedemptions(uint32 _allowlistMintRedemptions, uint32 _publicMintRedemptions) private pure returns (uint64) {
        return (uint64(_allowlistMintRedemptions) << 32) | uint64(_publicMintRedemptions);
    }

    /**
     * @notice Unpack a single uint64 value into two uint32s (allowlist and public redemptions)
     * @return allowlistMintRedemptions publicMintRedemptions Unpacked values
     * @dev Performs shift and bit operations to unpack a single uint64 into two uint32s
     */
    function unpackMintRedemptions(uint64 _mintRedemptionPack) private pure returns (uint32 allowlistMintRedemptions, uint32 publicMintRedemptions) {
        allowlistMintRedemptions = uint32(_mintRedemptionPack >> 32);
        publicMintRedemptions = uint32(_mintRedemptionPack);
    }

    /**
     * @notice Mint a quantity of tokens to the contract owners address
     * @notice Use restricted to contract owner
     * @param _quantity Number of tokens to mint
     * @dev Must be executed in `MintPhase.INACTIVE` (i.e., before allowlist or public mint begins)
     */
    function ownerMint(uint256 _quantity) external onlyOwner inMintPhase(MintPhase.INACTIVE) {
        require(totalSupply() + _quantity <= collectionSize, "insufficient supply");
        _safeMint(owner(), _quantity);
    }

    /**
     * @notice Withdraw all funds to the contract owners address
     * @notice Use restricted to contract owner
     */
    function withdraw() external onlyOwner {
        address shareHolder55 = 0xb92535c47C6108b8a7cF1Dc9e08be449E6bE9d51;
        address shareHolder35 = 0x9691b70b81524E60B937eb490af9E8Ee16bB08e8;
        address shareHolder10 = 0x26a8aE8435Bb9653c7c66c64217D15E397A4523e;

        uint256 share55 = address(this).balance * 55 / 100;
        uint256 share35 = address(this).balance * 35 / 100;
        uint256 share10 = address(this).balance - share55 - share35;

        (bool success, ) = shareHolder55.call{value: share55}("");
        require(success, "transfer failed");
        (success, ) = shareHolder35.call{value: share35}("");
        require(success, "transfer failed");
        (success, ) = shareHolder10.call{value: share10}("");
        require(success, "transfer failed");
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Prevent accidental ETH transfer
     */
    fallback() external payable {
        require(false, "not implemented");
    }

    /**
     * @notice Prevent accidental ETH transfer
     */
    receive() external payable {
        require(false, "not implemented");
    }
}

contract KounPass is KounPassERC721A {
    mapping(address => uint256) public extAddressMintQuota;
    uint256 maxMintForExtAddress = 5;

    uint256 revealedMaxId = 0;

    constructor() KounPassERC721A("KOUN PASS", "TPZ-KP", "ipfs://QmX2z2CtFzj4VsHV4cHnCeg5ZsdMAUbDyredGW47LWKuYY", 1200, 0.06 ether, 0.049 ether, 5, 5) {}

    /**
     * @notice Mint for external address for a quantity of tokens during public mint
     * @notice Each minter have limited amount of quota to mint for external address
     * @param _quantity Number of tokens to 
     * @dev Can only be executed in `MintPhase.PUBLIC_SALE`
     */
    function mintForAddress(address _recipient, uint256 _quantity) external payable nonReentrant inMintPhase(MintPhase.PUBLIC_SALE) {
        require(msg.sender != _recipient, "Can only mint for different address");
        require(extAddressMintQuota[msg.sender] + _quantity <= maxMintForExtAddress, "Exceed mint external max!");
        require(msg.value == mintPricePublic * _quantity, "incorrect payment");
        require(totalSupply() + _quantity <= collectionSize, "insufficient supply");

        _safeMint(_recipient, _quantity);
        extAddressMintQuota[msg.sender] += _quantity;
    }

    /**
     * @notice Update mint price for public mint
     * @notice Use restricted to contract owner
     * @param _newPrice New mint price in wei
     */
    function updatePublicPrice(uint256 _newPrice) external onlyOwner {
        mintPricePublic = _newPrice;
    }

    /**
     * @notice Update mint price for allowlist mint
     * @notice Use restricted to contract owner
     * @param _newPrice New mint price in wei
     */
    function updateAllowlistPrice(uint256 _newPrice) external onlyOwner {
        mintPriceAllowlist = _newPrice;
    }

    /**
     * @notice Reveal max token by id with original metadata, needs to update base URI to prevent metadata tracking
     * @notice Use restricted to contract owner
     * @param _baseTokenURI New base token 
     * @param _maxId maximum token id to reveal
     */
    function reveal(string calldata _baseTokenURI, uint256 _maxId) external onlyOwner {
        setBaseURI(_baseTokenURI);
        revealedMaxId = _maxId;
    }

    /**
     * @dev Returns the token metadata URI.
     * @notice if tokenId is greater than revealedMaxId, it will returns the hiddenURI
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (tokenId > revealedMaxId) {
            return _hiddenURI();
        } else {
            string memory currentBaseURI = _baseURI();
            return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _toString(tokenId), ".json")) : "";
        }
    }
}