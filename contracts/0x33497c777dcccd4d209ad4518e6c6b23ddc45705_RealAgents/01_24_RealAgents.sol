// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

error VerifyFailed();
error Claimed();

contract RealAgents is ERC721AQueryable, ERC721ABurnable, ERC2981, Pausable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public constant NAME = "REAL AGENTS";
    string public constant SYMBOL = "AGENT";
    string private _baseTokenURI;
    bytes32 public merkleRoot;
    uint256 public constant MAX_SUPPLY = 1000;

    mapping(address => bool) private claimed;
    mapping(address => bool) private blockedMarketplaces;

    event Mint(address indexed _to, uint256 _startId);
    event VaultMint(address indexed _to, uint256 _qty);
    event SetMerkleRoot(bytes32 _root);

    constructor(string memory _uri, bytes32 _root) ERC721A(NAME, SYMBOL) {
        _setDefaultRoyalty(address(0x032167473a2A2996754481A26c778Ec4570B2d18), 1000);
        _baseTokenURI = _uri;
        merkleRoot = _root;

        _pause();
    }

    function mint(bytes32[] memory _merkleProof) external nonReentrant whenNotPaused {
        require(_totalMinted() < MAX_SUPPLY, "reached max supply!");
        if (claimed[_msgSender()]) revert Claimed();

        bytes32 node = keccak256(abi.encodePacked(_msgSender()));
        if (!MerkleProof.verify(_merkleProof, merkleRoot, node)) revert VerifyFailed();

        claimed[_msgSender()] = true;
        emit Mint(_msgSender(), _nextTokenId());

        _safeMint(_msgSender(), 1);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function pause() external payable onlyOwner {
        _pause();
    }

    function unpause() external payable onlyOwner {
        _unpause();
    }

    function setBaseURI(string memory _baseURIParam) external payable onlyOwner {
        _baseTokenURI = _baseURIParam;
    }

    function setMerkleRoot(bytes32 _root) external payable onlyOwner {
        merkleRoot = _root;

        emit SetMerkleRoot(_root);
    }

    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints) external payable onlyOwner {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(blockedMarketplaces[operator] != true, "invalid operator!");
        super.setApprovalForAll(operator, approved);
    }

    function setBlockedMarketplaces(address[] memory _market, bool[] memory _status) external payable onlyOwner {
        uint256 length = _market.length;
        for (uint256 i = 0; i < length; ) {
            address _to = _market[i];
            blockedMarketplaces[_to] = _status[i];

            unchecked {
                ++i;
            }
        }
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function vaultMint(address _to, uint256 _qty) external payable onlyOwner {
        _safeMint(_to, _qty);

        emit VaultMint(_to, _qty);
    }
}