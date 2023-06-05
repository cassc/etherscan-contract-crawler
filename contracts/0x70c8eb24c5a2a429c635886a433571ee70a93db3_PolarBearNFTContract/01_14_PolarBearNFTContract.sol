// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721B.sol";

contract PolarBearNFTContract is ERC2981, ERC721B, EIP712, AccessControl, Ownable {

    using Strings for uint256;
    
    event MintedPolarBear(address indexed recipient, uint256 quantity, uint256 nonce);
    event ManualMintedPolarBear(address indexed recipient, uint256 quantity);
    event SetBaseURI(string baseURI);
    event SetRoyalty(address royaltyAddress, uint96 fee);
    
    string private baseURI;
    uint256 private constant MAX_SUPPLY = 5000;
    bytes32 public constant VERIFY_ROLE = keccak256("VERIFY_ROLE");
    bytes32 constant public POLARBEARNFT_TYPEHASH = keccak256("PolarBearNFT(address account,uint256 quantity,uint256 nonce,uint256 deadline)");

    constructor(
        string memory name_, 
        string memory symbol_
    ) ERC721B(name_, symbol_) EIP712("PolarBearNFTContract", "1.0.0") {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721B, ERC2981, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setRoyalty(address _royaltyAddress, uint96 fee) external onlyOwner {
        require(fee < 100 * 1e2, "Incorrect royalty fee");
        _setDefaultRoyalty(_royaltyAddress, fee);
        emit SetRoyalty(_royaltyAddress, fee);
    }
    
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (!_exists(_tokenId)) revert OwnerQueryForNonexistentToken();
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId+1), ".json"));
    }

    /**
    @dev Setup verify role
     */
    function setupVerifyRole(address account) external onlyOwner {
        _grantRole(VERIFY_ROLE, account);
    }

    /**
     * Set base URI of NFT
     */
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit SetBaseURI(_baseURI);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function mint(
        uint256 quantity,
        uint256 nonce,
        uint256 deadline,
        bytes calldata signature
    ) external {
        require(_msgSender() == tx.origin, "Can not mint NFT to contract address");
        require(block.timestamp <= deadline, "Invalid expiration in mint");
        require(_owners.length + quantity <= MAX_SUPPLY, "Can not mint NFT more than MAX_SUPPLY");
        require(_verify(_hash(_msgSender(), quantity, nonce, deadline), signature), "Invalid signature");
        _mint(_msgSender(), quantity);

        emit MintedPolarBear(_msgSender(), quantity, nonce);
    }

    function manualMint(
        address to, 
        uint256 quantity
    ) external onlyOwner {
        require(_owners.length + quantity <= MAX_SUPPLY, "Can not mint NFT more than MAX_SUPPLY");
        _mint(to, quantity);

        emit ManualMintedPolarBear(to, quantity);
    }

    function _hash(address account, uint256 quantity, uint256 nonce, uint256 deadline)
    internal view returns (bytes32)
    {
        return _hashTypedDataV4(keccak256(abi.encode(
            POLARBEARNFT_TYPEHASH,
            account,
            quantity,
            nonce,
            deadline
        )));
    }

    function _verify(bytes32 digest, bytes memory signature)
    internal view returns (bool)
    {
        return hasRole(VERIFY_ROLE, ECDSA.recover(digest, signature));
    }
}