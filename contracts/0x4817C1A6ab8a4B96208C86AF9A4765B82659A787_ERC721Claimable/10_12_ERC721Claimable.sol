// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/security/Pausable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract ERC721Claimable is ERC721A, Pausable, AccessControl, EIP712 {
    using Strings for uint;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MINTER_TYPEHASH = keccak256("Claim(uint256 tokenId,uint256 nonce)");

    uint public startMintId;
    address public ownerAddress;
    string public contractURI;
    string public baseTokenURI;
    string public baseTokenURIClaimed;
    mapping(uint => bool) public claimed;
    mapping(bytes32 => bool) public signatureUsed;
    address public feeCollectorAddress;
    address public signerAddress;

    bool public claimStarted;
    bool public publicMint;
    uint public max;

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "Must have minter role.");
        _;
    }
    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Must have admin role.");
        _;
    }

    modifier requiresSignature(
        bytes calldata signature,
        uint tokenId,
        uint nonce
    ) {
        // Verify EIP-712 signature by recreating the data structure
        // that we signed on the client side, and then using that to recover
        // the address that signed the signature for this data.
        bytes32 structHash = keccak256(abi.encode(MINTER_TYPEHASH, tokenId, nonce));
        bytes32 digest = _hashTypedDataV4(structHash); /*Calculate EIP712 digest*/
        require(!signatureUsed[digest], "signature used");
        require(!claimed[tokenId], "tokenId already claimed");
        signatureUsed[digest] = true;
        // Use the recover method to see what address was used to create
        // the signature on this data.
        // Note that if the digest doesn't exactly match what was signed we'll
        // get a random recovered address.
        address recoveredAddress = ECDSA.recover(digest, signature);
        require(signerAddress == recoveredAddress, "Invalid Signature");
        _;
    }

    /// @notice Constructor for the ONFT
    /// @param _name the name of the token
    /// @param _symbol the token symbol
    /// @param _contractURI the contract URI
    /// @param _baseTokenURI the base URI for computing the tokenURI
    /// @param _baseTokenURIClaimed //the base URI after token has been claimed
    /// @param _feeCollectorAddress the address fee collector
    /// @param _max amount of nfts to be created
    constructor(string memory _name, string memory _symbol, string memory _contractURI, string memory _baseTokenURI, string memory _baseTokenURIClaimed, address _feeCollectorAddress, uint _max, address _signerAddress) ERC721A(_name, _symbol) EIP712("ERC721Claimable", "1") {
        contractURI = _contractURI;
        baseTokenURI = _baseTokenURI;
        baseTokenURIClaimed = _baseTokenURIClaimed;
        startMintId = 0;
        max = _max;
        feeCollectorAddress = _feeCollectorAddress;
        signerAddress = _signerAddress;
        claimStarted = false;

        ownerAddress = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function claim(bytes calldata _sig, uint _tokenId, uint _nonce) external requiresSignature(_sig, _tokenId, _nonce) {
        require(claimStarted, "Claim period has not begun");
        require(ownerOf(_tokenId) == msg.sender, "Must be owner");
        claimed[_tokenId] = true;
    }

    function mint(address to, uint quantity) external onlyMinter {
        require(startMintId < max, "No more left");
        _mint(to, quantity);
        startMintId = quantity + startMintId;
    }

    function mintDirect(address to, uint quantity) external onlyOwner {
        require(startMintId < max, "No more left");
        _mint(to, quantity);
        startMintId = quantity + startMintId;
    }

    function pauseSendTokens(bool pause) external onlyOwner {
        pause ? _pause() : _unpause();
    }

    function tokenURI(uint tokenId) public view override returns (string memory) {
        if (claimed[tokenId]) {
            return string(abi.encodePacked(baseTokenURIClaimed, tokenId.toString()));
        }
        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }

    function setFeeCollector(address _feeCollectorAddress) external onlyOwner {
        feeCollectorAddress = _feeCollectorAddress;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function setOwner(address _newOwner) public onlyOwner {
        ownerAddress = _newOwner;
    }

    function setMaxQuantity(uint _quantity) public onlyOwner {
        max = _quantity;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setBaseURIClaimed(string memory _baseTokenURIClaimed) public onlyOwner {
        baseTokenURIClaimed = _baseTokenURIClaimed;
    }

    function setClaimStart(bool _isStarted) public onlyOwner {
        claimStarted = _isStarted;
    }

    function _beforeTokenTransfers(address from, address to, uint tokenId, uint quantity) internal virtual override {
        super._beforeTokenTransfers(from, to, tokenId, quantity);

        require(!claimed[tokenId], "ERC721Claimable: token has already been claimed");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId) || ERC721A.supportsInterface(interfaceId);
    }

    function owner() external view returns (address) {
        return ownerAddress;
    }
}