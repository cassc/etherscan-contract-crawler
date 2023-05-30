// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721A, IERC721A, ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {ERC721ABurnable} from "erc721a/contracts/extensions/ERC721ABurnable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";

/**
 * @title FYVM
 * @author @fyvmclub
 *
 * Attention, fvckers!
 * To all of the scammers, phishers, and rug pullers. Fvck them all, it's our world.
 * It's time to push back and get your one of a kind message to any and everyone.
 */
contract FYVM is
    DefaultOperatorFilterer,
    ERC2981,
    ERC721AQueryable,
    ERC721ABurnable,
    Ownable,
    ReentrancyGuard
{
    using PRBMathUD60x18 for uint256;
    using Strings for uint256;

    struct MintState {
        bool isWhitelistOpen;
        bool isPublicOpen;
        bool isFreeOpen;
        uint256 liveAt;
        uint256 expiresAt;
        bytes32 merkleRoot;
        bytes32 freeMerkleRoot;
        uint256 maxSupply;
        uint256 totalSupply;
        uint256 price;
        uint256 minted;
        bool freeMinted;
    }

    uint256 private constant ONE_PERCENT = 10000000000000000; // 1% (18 decimals)

    /// @dev The free mint merkle root
    bytes32 public freeMerkleRoot;

    /// @dev The whitelist merkle root
    bytes32 public merkleRoot;

    /// @dev Treasury
    address public treasury =
        payable(0x54f54b0adFb8c7Df938dD0eB0B84d2f0BeD29685);

    // @dev Base uri for the nft
    string private baseURI = "ipfs://cid/";

    // @dev Hidden uri for the nft
    string private hiddenURI = "ipfs://hiddencid/";

    /// @dev The total supply of the collection (n-1)
    uint256 public maxSupply = 5556;

    /// @dev The max per wallet (n-1)
    uint256 public maxPerWallet = 3;

    /// @dev The max per tx (n-1)
    uint256 public maxPerTransaction = 3;

    /// @notice ETH mint price
    uint256 public price = 0.015 ether;

    /// @notice Live timestamp
    uint256 public liveAt = 1674928800;

    /// @notice Expires timestamp
    uint256 public expiresAt = 1674943200;

    /// @notice Whitelist mint
    bool public isWhitelistOpen = true;

    /// @notice Free mint
    bool public isFreeOpen = false;

    /// @notice Public mint
    bool public isPublicOpen = false;

    /// @notice Is Revealed
    bool public isRevealed = false;

    /// @notice An address mapping mints
    mapping(address => uint256) public addressToMinted;

    /// @notice An address free mint
    mapping(address => bool) public addressToFreeMint;

    constructor() ERC721A("FYVM", "FYVM") {
        _setDefaultRoyalty(treasury, 1000);
        // Run placeholder mint
        _mintERC2309(_msgSenderERC721A(), 1);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    modifier withinThreshold(uint256 _amount) {
        require(_amount < maxPerTransaction, "Max per transaction reached.");
        require(totalSupply() + _amount < maxSupply, "Max mint reached.");
        _;
    }

    modifier isWhitelist(bytes32 _merkleRoot, bytes32[] calldata _proof) {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSenderERC721A()));
        require(
            MerkleProof.verify(_proof, _merkleRoot, leaf),
            "Invalid proof."
        );
        _;
    }

    modifier isCorrectPrice(uint256 _amount, uint256 _price) {
        require(msg.value >= _amount * _price, "Not enough funds.");
        _;
    }

    /**************************************************************************
     * Minting
     *************************************************************************/

    /**
     * @notice Whitelist mint function
     * @dev Restricted to price, threshold, merkle root, and max WL (3)
     * @param _amount The amount to mint
     * @param _proof The generated merkel proof
     */
    function whitelistMint(
        uint256 _amount,
        bytes32[] calldata _proof
    )
        external
        payable
        isCorrectPrice(_amount, price)
        withinThreshold(_amount)
        isWhitelist(merkleRoot, _proof)
    {
        require(isLive() && isWhitelistOpen, "Whitelist mint is not active.");
        address recipient = _msgSenderERC721A();
        require(addressToMinted[recipient] + _amount < maxPerWallet, "Over.");
        addressToMinted[recipient] += _amount;
        _mint(recipient, _amount);
    }

    /**
     * @notice Public mint function
     * @dev Restricted to price, threshold, and max per wallet
     * @param _amount The amount to mint
     */
    function mint(
        uint256 _amount
    ) external payable withinThreshold(_amount) isCorrectPrice(_amount, price) {
        require(isLive() && isPublicOpen, "Public mint is not active.");
        address recipient = _msgSenderERC721A();
        require(
            addressToMinted[recipient] + _amount < maxPerWallet,
            "Minted max."
        );
        addressToMinted[recipient] += _amount;
        _mint(recipient, _amount);
    }

    /**
     * @notice Free mint function
     * @dev Restricted to threshold, free merkle root, and cannot have minted free
     * @param _proof The generated merkel proof
     */
    function freeMint(
        bytes32[] calldata _proof
    ) external withinThreshold(1) isWhitelist(freeMerkleRoot, _proof) {
        require(isLive() && isFreeOpen, "Free mint is not active.");
        address recipient = _msgSenderERC721A();
        require(!addressToFreeMint[recipient], "Already minted free.");
        addressToFreeMint[recipient] = true;
        _mint(recipient, 1);
    }

    /// @dev Check if mint is live
    function isLive() public view returns (bool) {
        return block.timestamp >= liveAt && block.timestamp <= expiresAt;
    }

    /**
     * @notice Returns current mint state for a particular address
     * @param _address The address
     */
    function getMintState(
        address _address
    ) external view returns (MintState memory) {
        return
            MintState({
                isWhitelistOpen: isWhitelistOpen,
                isPublicOpen: isPublicOpen,
                isFreeOpen: isFreeOpen,
                liveAt: liveAt,
                expiresAt: expiresAt,
                merkleRoot: merkleRoot,
                freeMerkleRoot: freeMerkleRoot,
                maxSupply: maxSupply,
                totalSupply: totalSupply(),
                price: price,
                minted: addressToMinted[_address],
                freeMinted: addressToFreeMint[_address]
            });
    }

    /**
     * @notice Returns the URI for a given token id
     * @param _tokenId A tokenId
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override(IERC721A, ERC721A) returns (string memory) {
        if (!_exists(_tokenId)) revert OwnerQueryForNonexistentToken();

        if (!isRevealed) {
            return string(abi.encodePacked(hiddenURI, "prereveal.json"));
        }

        return
            string(
                abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json")
            );
    }

    /**************************************************************************
     * Admin
     *************************************************************************/

    /**
     * @notice Sets the hidden URI of the NFT
     * @param _hiddenURI A base uri
     */
    function setHiddenURI(string calldata _hiddenURI) external onlyOwner {
        hiddenURI = _hiddenURI;
    }

    /**
     * @notice Sets the base URI of the NFT
     * @param _baseURI A base uri
     */
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @notice Sets the reveal state
     * @param _isRevealed The reveal state
     */
    function setIsRevealed(bool _isRevealed) external onlyOwner {
        isRevealed = _isRevealed;
    }

    /**
     * @notice Sets the collection max supply
     * @param _maxSupply The max supply of the collection
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    /**
     * @notice Sets the collection max per transaction
     * @param _maxPerTransaction The max per transaction
     */
    function setMaxPerTransaction(
        uint256 _maxPerTransaction
    ) external onlyOwner {
        maxPerTransaction = _maxPerTransaction;
    }

    /**
     * @notice Sets the collection max per wallet
     * @param _maxPerWallet The max per wallet
     */
    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    /**
     * @notice Sets eth price
     * @param _price The price in wei
     */
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    /**
     * @notice Sets the treasury recipient
     * @param _treasury The treasury address
     */
    function setTreasury(address _treasury) public onlyOwner {
        treasury = payable(_treasury);
    }

    /**
     * @notice Sets the merkle root for the mint
     * @param _merkleRoot The merkle root to set
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Sets the merkle root for the free mint
     * @param _freeMerkleRoot The merkle root to set
     */
    function setFreeMerkleRoot(bytes32 _freeMerkleRoot) external onlyOwner {
        freeMerkleRoot = _freeMerkleRoot;
    }

    /**
     * @notice Sets the mint states
     * @param _isWhitelistOpen The whitelist is open
     * @param _isPublicMintOpen The public mint is open
     * @param _isFreeOpen The free mint is open
     */
    function setMintStates(
        bool _isWhitelistOpen,
        bool _isPublicMintOpen,
        bool _isFreeOpen
    ) external onlyOwner {
        isWhitelistOpen = _isWhitelistOpen;
        isPublicOpen = _isPublicMintOpen;
        isFreeOpen = _isFreeOpen;
    }

    /**
     * @notice Sets timestamps for live and expires timeframe
     * @param _liveAt A unix timestamp for live date
     * @param _expiresAt A unix timestamp for expiration date
     */
    function setMintWindow(
        uint256 _liveAt,
        uint256 _expiresAt
    ) external onlyOwner {
        liveAt = _liveAt;
        expiresAt = _expiresAt;
    }

    /**
     * @notice Changes the contract defined royalty
     * @param _receiver - The receiver of royalties
     * @param _feeNumerator - The numerator that represents a percent out of 10,000
     */
    function setDefaultRoyalty(
        address _receiver,
        uint96 _feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    /// @notice Withdraws funds from contract
    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool s1, ) = payable(0x54830A9E5d68Cd89D7C8f722e2432c6489F9f4C1).call{
            value: amount.mul(ONE_PERCENT * 34)
        }("");
        (bool s2, ) = payable(0xb408daBe8976305c6243326320631Bd6CA6f8491).call{
            value: amount.mul(ONE_PERCENT * 33)
        }("");
        (bool s3, ) = payable(0x42311bb4baaE9dD8AB137D7FF53aC64a26344DCa).call{
            value: amount.mul(ONE_PERCENT * 33)
        }("");
        if (s1 && s2 && s3) return;
        // fallback
        (bool s4, ) = treasury.call{value: amount}("");
        require(s4, "Payment failed");
    }

    /// @notice Withdraws funds from contract
    function fallbackWithdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = treasury.call{value: balance}("");
        require(success, "Unable to withdraw ETH");
    }

    /**
     * @dev Airdrop function
     * @param _to The address to mint to
     * @param _amount The amount to mint
     */
    function airdrop(address _to, uint256 _amount) external onlyOwner {
        require(totalSupply() + _amount < maxSupply, "Max mint reached.");
        _mint(_to, _amount);
    }

    /**************************************************************************
     * Royalties
     *************************************************************************/

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC721A, ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}