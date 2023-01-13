// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "hardhat/console.sol";

contract DeadDegens is ERC721A, Ownable, Pausable, DefaultOperatorFilterer {
    using SafeMath for uint256;
    uint256 public constant _maxPerWallet = 1;
    string public _contractBaseURI = "ipfs://kackmahaaa/";
    uint256 public _maxSupply = 4444;
    bool public _burnActive = false;
    bool public _whitelistActive = true;
    uint256 public _activeMerkleRootIndex;
    mapping(uint256 => bytes32) public _merkleRoots;

    constructor() ERC721A("DeadDegens", "DD") {
        _pause();
    }

    function setMerkleRoot(
        uint256 index,
        bytes32 merkleRoot
    ) external onlyOwner {
        _merkleRoots[index] = merkleRoot;
    }

    function setMerkleRootIndex(uint256 index) external onlyOwner {
        _activeMerkleRootIndex = index;
    }

    function teamMint(address to, uint256 quantity) external onlyOwner {
        unchecked {
            _defaultMintValidation(quantity);
            _safeMint(to, quantity);
        }
    }

    function publicMint(uint256 quantity) external payable whenNotPaused {
        unchecked {
            require(!_whitelistActive, "Whitelist minting is still active");
            require(quantity <= _maxPerWallet, "Max one mint per wallet");
            require(
                balanceOf(msg.sender) < _maxPerWallet,
                "Max one mint per wallet"
            );
            _defaultMintValidation(quantity);
            _safeMint(msg.sender, quantity);
        }
    }

    function whitelistMint(
        uint256 quantity,
        bytes32[] calldata merkleProof
    ) external payable whenNotPaused {
        unchecked {
            require(
                _isWhitelisted(msg.sender, merkleProof),
                "Address is not whitelisted"
            );
            require(quantity <= _maxPerWallet, "Max one mint per wallet");
            require(
                balanceOf(msg.sender) < _maxPerWallet,
                "Max one mint per wallet"
            );
            _defaultMintValidation(quantity);
            _safeMint(msg.sender, quantity);
        }
    }

    function isWhitelisted(
        address addr,
        bytes32[] calldata merkleProof
    ) external view returns (bool) {
        return _isWhitelisted(addr, merkleProof);
    }

    function burn(uint256 tokenId) external payable {
        require(_burnActive, "Burn function is not active");
        _burn(tokenId, true);
    }

    function setWhitelistActive(bool whitelistActive) external onlyOwner {
        _whitelistActive = whitelistActive;
    }

    function toggleBurn() external onlyOwner {
        _burnActive = !_burnActive;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        _contractBaseURI = _uri;
    }

    function _isWhitelisted(
        address addr,
        bytes32[] calldata merkleProof
    ) internal view returns (bool) {
        return
            MerkleProof.verify(
                merkleProof,
                _merkleRoots[_activeMerkleRootIndex],
                _toBytes32(addr)
            );
    }

    function _defaultMintValidation(uint256 quantity) internal view {
        unchecked {
            require(quantity > 0, "Quantity must be larger than 0");
            require(
                quantity <= _maxSupply - totalSupply(),
                "Not enough of tokens left"
            );
        }
    }

    function _toBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function _baseURI() internal view override returns (string memory) {
        return _contractBaseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}