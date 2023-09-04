// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/**
 * @title OGPass
 * @dev Implements a non-fungible token contract with merkle tree verification for minting
 */

contract OGPass is DefaultOperatorFilterer, ERC721Enumerable, Ownable, Pausable {
    using Strings for uint256;

    enum SaleState {
        FIRST_PRIVATE,
        SECOND_PRIVATE,
        PUBLIC
    }

    uint256 public constant MAX_SUPPLY = 555;
    uint256 public constant COST = 555 ether;
    uint256 public constant MAX_PUBLIC_BATCH = 2;
    uint256 public privateMaxBatch = 1;

    uint256 public maxAllowedPrivate = 1;
    uint256 public maxAllowedPublic = 2;

    IERC20 public APE_COIN;

    bytes32 public whitelistMerkleTreeRoot;
    bytes32 public freeMintMerkleTreeRoot;

    SaleState public saleState = SaleState.FIRST_PRIVATE;

    string private baseURI;

    mapping(address => uint256) public firstPrivateMinted;
    mapping(address => uint256) public secondPrivateMinted;
    mapping(address => uint256) public publicMinted;
    mapping(address => bool) public freeClaim;

    constructor(
        string memory _name,
        string memory _symbol,
        address _apeCoin
    ) ERC721(_name, _symbol) {
        APE_COIN = IERC20(_apeCoin);
        _pause();
    }

    /**
     * @dev Sets the flag for private sale
     * @param _status The status of the private sale
     */
    function setSaleState(SaleState _status) external onlyOwner {
        saleState = _status;
    }

    /**
     * @dev Pause minting
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause minting
     */
    function unPause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Transfers the $APE balance from the contract to its owner
     */
    function withdraw() external onlyOwner {
        APE_COIN.transfer(_msgSender(), APE_COIN.balanceOf(address(this)));
    }

    /**
     * @dev Sets the max private batch for private sale
     * @param _privateMaxBatch new max private batch
     */
    function setPrivateMaxBatch(uint256 _privateMaxBatch) external onlyOwner {
        privateMaxBatch = _privateMaxBatch;
    }

    /**
     * @dev Sets the maximum allowed mint amount in private sale
     * @param _maxAllowedPrivate The new maximal value for private sale
     */
    function setMaxAllowedPrivate(uint256 _maxAllowedPrivate) external onlyOwner {
        maxAllowedPrivate = _maxAllowedPrivate;
    }

    /**
     * @dev Sets the maximum allowed mint amount in public sale
     * @param _maxAllowedPublic The new maximal value for public sale
     */
    function setMaxAllowedPublic(uint256 _maxAllowedPublic) external onlyOwner {
        maxAllowedPublic = _maxAllowedPublic;
    }

    /**
     * @dev Sets the base URI for all tokens.
     * @param _newBaseURI The new base URI.
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @dev Mint to owner address
     * @param _amount The amount of tokens to be minted
     */
    function reserve(uint256 _amount) external onlyOwner {
        uint256 _totalSupply = totalSupply();

        require(_totalSupply + _amount <= MAX_SUPPLY, "Exceeds max supply");

        uint256 _tokenMaxId = _totalSupply + _amount;

        while (_tokenMaxId > _totalSupply) {
            _safeMint(_msgSender(), --_tokenMaxId);
        }
    }

    /**
     * @dev Sets the merkle tree root for mint whitelist check
     * @param _merkleTreeRoot The root of the merkle tree
     */
    function setWhitelistMerkleTreeRoot(bytes32 _merkleTreeRoot) external onlyOwner {
        whitelistMerkleTreeRoot = _merkleTreeRoot;
    }

    /**
     * @dev Sets the merkle tree root for the free mint whitelist check
     * @param _freeMintMerkleTreeRoot The root of the merkle tree
     */
    function setFreeMintMerkleTreeRoot(bytes32 _freeMintMerkleTreeRoot) external onlyOwner {
        freeMintMerkleTreeRoot = _freeMintMerkleTreeRoot;
    }

    /**
     * @dev Returns the URI for a given token ID.
     * @param _tokenId The token ID to retrieve the URI for.
     * @return A string representing the URI for the given token ID.
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
                : "";
    }

    /**
     * @dev Generates the leaf node for a given address
     * @param account The address of the account
     * @return The leaf node for the account
     */
    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    /**
     * @dev Verifies the merkle tree proof for a given leaf node
     * @param _leafNode The leaf node for the account
     * @param _root The root of the merkle tree to be used
     * @param _proof The merkle tree proof
     * @return True if the proof is valid, false otherwise
     */
    function _verify(bytes32 _root, bytes32 _leafNode, bytes32[] memory _proof) internal pure returns (bool) {
        return MerkleProof.verify(_proof, _root, _leafNode);
    }

    /**
     * @dev Returns the base URI for all tokens.
     * @return A string representing the base URI for all tokens.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Mints a given amount of tokens to the caller of the contract
     * @param _amount The amount of tokens to mint
     * @param _whitelistProof The merkle tree proof for the caller
     */
    function mintPrivate(
        uint256 _amount,
        bytes32[] calldata _whitelistProof
    ) external whenNotPaused {
        require(saleState != SaleState.PUBLIC, "Private sale has not started yet");
        require(_amount <= privateMaxBatch, "Provided amount exceeds allowed batch");

        require(
            _amount + (
                saleState != SaleState.SECOND_PRIVATE
                    ? firstPrivateMinted[_msgSender()]
                    : secondPrivateMinted[_msgSender()]
            )  <= maxAllowedPrivate,
            "Requested amount to mint exceeds allocation"
        );

        require(
            _verify(whitelistMerkleTreeRoot, _leaf(_msgSender()), _whitelistProof),
            "You are not a member of the whitelist"
        );

        uint256 _totalSupply = totalSupply();
        require(_totalSupply + _amount <= MAX_SUPPLY, "Requested amount exceeds remaining supply");

        uint256 _tokenMaxId = _totalSupply + _amount;

        while (_tokenMaxId > _totalSupply) {
            _safeMint(_msgSender(), --_tokenMaxId);
        }

        if (saleState == SaleState.SECOND_PRIVATE) {
            secondPrivateMinted[_msgSender()] += _amount;
        } else {
            firstPrivateMinted[_msgSender()] += _amount;
        }

        require(APE_COIN.transferFrom(_msgSender(), address(this), _amount * COST), "$APE transfer failed");

        delete _tokenMaxId;
        delete _totalSupply;
    }

    /**
     * @dev Mints a given amount of tokens to the caller of the contract
     * @param _amount The amount of tokens to mint
     */
    function mintPublic(uint256 _amount) external whenNotPaused {
        require(saleState == SaleState.PUBLIC, "Public sale has not started yet");
        require(_amount <= MAX_PUBLIC_BATCH, "Provided amount exceeds allowed batch");
        require(_amount + publicMinted[_msgSender()] <= maxAllowedPublic, "Requested amount to mint exceeds allocation");

        uint256 _totalSupply = totalSupply();

        require(_totalSupply + _amount <= MAX_SUPPLY, "Requested amount exceeds remaining supply");

        uint256 _tokenMaxId = _totalSupply + _amount;

        while (_tokenMaxId > _totalSupply) {
            _safeMint(_msgSender(), --_tokenMaxId);
        }

        publicMinted[_msgSender()] += _amount;

        require(APE_COIN.transferFrom(_msgSender(), address(this), _amount * COST), "$APE transfer failed");

        delete _tokenMaxId;
        delete _totalSupply;
    }

    /**
     * @dev Mints one pass for the caller that is part of the free mint whitelist
     * @param _freeMintProof Merkle proof to check free mint whitelist membership
     */
    function claim(bytes32[] calldata _freeMintProof) external whenNotPaused {
        require(
            _verify(freeMintMerkleTreeRoot, _leaf(_msgSender()), _freeMintProof),
            "Not a member of the free mint whitelist"
        );

        require(!freeClaim[_msgSender()], "Already claimed your pass");

        uint256 _totalSupply = totalSupply();

        require(_totalSupply + 1 <= MAX_SUPPLY, "Requested amount exceeds remaining supply");

        _safeMint(_msgSender(), _totalSupply);

        freeClaim[_msgSender()] = true;
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override(ERC721, IERC721)
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}