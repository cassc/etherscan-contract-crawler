// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Address.sol';

contract ExodiaFireEmblem is ERC721A, Ownable {
    uint256 public maxMintSupply = 3000;
    uint256 public maxUserMintAmount = 1;

    // Sale Status
    bool public publicSaleActive;
    bool public presaleActive;

    bytes32 public merkleRoot;

    bool public locked;
    string private baseURI;

    event SetMerkleRoot(bytes32 root);
    event SetBaseUri(string uri);
    event TogglePresaleStatus(bool presaleStatus);
    event TogglePublicSaleStatus(bool publicSaleStatus);

    constructor() ERC721A('ExodiaFireEmblem', 'FIRE') {}

    function ownerMint(address to, uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= maxMintSupply, 'Max supply');
        _safeMint(to, quantity);
    }

    /**
     * @dev Allows specific users to mint during presale
     *
     * Requirements:
     *
     * - Presale must be active
     * - Caller must be in allowlist
     * - Total user amount minted cannot be above max user mint amount
     * - Total number minted cannot be above max mint supply
     */
    function mintPresale(uint256 quantity, bytes32[] calldata proof) external {
        require(presaleActive, 'Not active');
        require(_isAllowlisted(msg.sender, proof, merkleRoot), 'Allowlist');
        require(_numberMinted(msg.sender) + quantity <= maxUserMintAmount, 'Max amount');
        require(totalSupply() + quantity <= maxMintSupply, 'Max supply');
        _safeMint(msg.sender, quantity);
    }

    /**
     * @dev Allows anyone to mint during public sale
     *
     * Requirements:
     *
     * - Public sale must be active
     * - Total user amount minted cannot be above max user mint amount
     * - Total number minted cannot be above max mint supply
     */
    function mint(uint256 quantity) external payable {
        require(publicSaleActive, 'Not active');
        require(_numberMinted(msg.sender) + quantity <= maxUserMintAmount, 'Max amount');
        require(totalSupply() + quantity <= maxMintSupply, 'Max supply');
        _safeMint(msg.sender, quantity);
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    function togglePresaleStatus() external onlyOwner {
        presaleActive = !presaleActive;
        emit TogglePresaleStatus(presaleActive);
    }

    function togglePublicSaleStatus() external onlyOwner {
        publicSaleActive = !publicSaleActive;
        emit TogglePublicSaleStatus(publicSaleActive);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        require(!locked, 'Locked');
        baseURI = uri;
        emit SetBaseUri(uri);
    }

    function setMaxUserMintAmount(uint256 _maxUserMintAmount) external onlyOwner {
        maxUserMintAmount = _maxUserMintAmount;
    }

    function lockMetadata() external onlyOwner {
        locked = true;
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
        emit SetMerkleRoot(_root);
    }

    function _leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _isAllowlisted(
        address _account,
        bytes32[] calldata _proof,
        bytes32 _root
    ) internal pure returns (bool) {
        return MerkleProof.verify(_proof, _root, _leaf(_account));
    }
}