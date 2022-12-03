// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @notice This contract handles minting Awakened tokens.
 */
contract Awakened is
    ERC721A,
    ERC721AQueryable,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    using Strings for uint256;
    // Used to validate authorized presale mint addresses
    address private presaleSignerAddress =
        0x445A551977f4a1A128e6514CE667a48C0326b5A1;
    bool public isPresaleActive = false;
    bool public isPublicSaleActive = false;
    // Permanently freezes metadata so it can never be changed
    bool public metadataFrozen = false;
    string public baseTokenURI =
        "ipfs://bafkreiefd6hz7dgi667tvyhxl4dysh2or2gazef4gy7zs3u44jiwyl3e5m";
    // Maximum supply of tokens that can be minted
    uint256 public constant MAX_SUPPLY = 333;
    // Total number of tokens available for minting in the presale
    uint256 public constant PRESALE_MAX_SUPPLY = 333;
    uint256 public presaleMintsAllowedPerAddress = 1;
    uint256 public presaleMintsAllowedPerTransaction = 1;
    uint256 public presalePrice = 0.1 ether;
    uint256 public publicMintsAllowedPerAddress = 2;
    uint256 public publicMintsAllowedPerTransaction = 2;
    uint256 public publicPrice = 0.15 ether;
    bytes32 public merkleRoot;
    address public communityWallet = 0x99C1ad64498174dD2aeb71D21213EEE66ac257cf;
    address public payoutAddress = 0x52852eC693CC222b75B6a488950388D875Dc5067;

    constructor() ERC721A("Awakened NFT Genesis Pass", "AWAKN") {
        // mint 33 to community wallet
        _safeMint(communityWallet, 33);
    }

    modifier originalUser() {
        require(tx.origin == msg.sender, "Cannot call from contract address");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev Overrides the default ERC721A _startTokenId() so tokens begin at 1 instead of 0
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Update the base token URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        require(!metadataFrozen, "METADATA_HAS_BEEN_FROZEN");
        baseTokenURI = _newBaseURI;
    }

    function setPayoutAddress(address _newPayoutAddress) external onlyOwner {
        payoutAddress = _newPayoutAddress;
    }

    /**
     * @notice Freeze metadata so it can never be changed again
     */
    function freezeMetadata() external onlyOwner {
        require(!metadataFrozen, "METADATA_HAS_ALREADY_BEEN_FROZEN");
        metadataFrozen = true;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice To be updated by contract owner to allow public sale minting
     */
    function setPublicSaleState(bool _saleActiveState) external onlyOwner {
        require(
            isPublicSaleActive != _saleActiveState,
            "NEW_STATE_IDENTICAL_TO_OLD_STATE"
        );
        isPublicSaleActive = _saleActiveState;
    }

    /**
     * @notice Update the public mint price
     */
    function setPublicPrice(uint256 _publicPrice) external onlyOwner {
        publicPrice = _publicPrice;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Set the maximum mints allowed per a given address in the public sale
     */
    function setPublicMintsAllowedPerAddress(
        uint256 _mintsAllowed
    ) external onlyOwner {
        publicMintsAllowedPerAddress = _mintsAllowed;
    }

    /**
     * @notice Set the maximum public mints allowed per a given transaction
     */
    function setPublicMintsAllowedPerTransaction(
        uint256 _mintsAllowed
    ) external onlyOwner {
        publicMintsAllowedPerTransaction = _mintsAllowed;
    }

    /**
     * @notice Allow for public minting of tokens
     */
    function mint(
        uint256 numTokens
    ) external payable nonReentrant originalUser {
        require(isPublicSaleActive, "PUBLIC_SALE_IS_NOT_ACTIVE");

        require(
            numTokens <= publicMintsAllowedPerTransaction,
            "MAX_MINTS_PER_TX_EXCEEDED"
        );
        require(
            _numberMinted(msg.sender) + numTokens <=
                publicMintsAllowedPerAddress,
            "MAX_MINTS_EXCEEDED"
        );
        require(totalSupply() + numTokens <= MAX_SUPPLY, "MAX_SUPPLY_EXCEEDED");
        require(msg.value == publicPrice * numTokens, "PAYMENT_INCORRECT");

        _safeMint(msg.sender, numTokens);

        if (totalSupply() >= MAX_SUPPLY) {
            isPublicSaleActive = false;
        }
    }

    /**
     * @notice To be updated by contract owner to allow presale minting
     */
    function setPresaleState(bool _saleActiveState) external onlyOwner {
        require(
            isPresaleActive != _saleActiveState,
            "NEW_STATE_IDENTICAL_TO_OLD_STATE"
        );
        isPresaleActive = _saleActiveState;
    }

    /**
     * @notice Update the presale mint price
     */
    function setPresalePrice(uint256 _presalePrice) external onlyOwner {
        presalePrice = _presalePrice;
    }

    /**
     * @notice Set the maximum mints allowed per a given address in the presale
     */
    function setPresaleMintsAllowedPerAddress(
        uint256 _mintsAllowed
    ) external onlyOwner {
        presaleMintsAllowedPerAddress = _mintsAllowed;
    }

    /**
     * @notice Set the maximum presale mints allowed per a given transaction
     */
    function setPresaleMintsAllowedPerTransaction(
        uint256 _mintsAllowed
    ) external onlyOwner {
        presaleMintsAllowedPerTransaction = _mintsAllowed;
    }

    function ownerMint(uint256 _numTokens) external onlyOwner {
        require(
            totalSupply() + _numTokens <= MAX_SUPPLY,
            "MAX_SUPPLY_EXCEEDED"
        );
        _safeMint(msg.sender, _numTokens);
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();

        return string(abi.encodePacked(baseTokenURI));
    }

    /**
     * @notice Set the signer address used to verify presale minting
     */
    function setPresaleSignerAddress(
        address _presaleSignerAddress
    ) external onlyOwner {
        require(_presaleSignerAddress != address(0));
        presaleSignerAddress = _presaleSignerAddress;
    }

    /**
     * @notice Allow for allowlist minting of tokens
     */
    function presaleMint(
        uint256 numTokens,
        bytes32[] calldata merkleProof
    ) external payable nonReentrant originalUser {
        require(isPresaleActive, "PRESALE_IS_NOT_ACTIVE");

        require(
            numTokens <= presaleMintsAllowedPerTransaction,
            "MAX_MINTS_PER_TX_EXCEEDED"
        );
        require(
            _numberMinted(msg.sender) + numTokens <=
                presaleMintsAllowedPerAddress,
            "MAX_MINTS_PER_ADDRESS_EXCEEDED"
        );
        require(
            totalSupply() + numTokens <= PRESALE_MAX_SUPPLY,
            "MAX_SUPPLY_EXCEEDED"
        );
        require(msg.value == presalePrice * numTokens, "PAYMENT_INCORRECT");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(msg.sender, numTokens));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "INVALID_MERKLE_PROOF"
        );

        _safeMint(msg.sender, numTokens);

        if (totalSupply() >= PRESALE_MAX_SUPPLY) {
            isPresaleActive = false;
        }
    }

    /**
     * @notice Withdraws all funds held within contract
     */
    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(payoutAddress).call{value: address(this).balance}(
            ""
        );
        require(os);
    }
}