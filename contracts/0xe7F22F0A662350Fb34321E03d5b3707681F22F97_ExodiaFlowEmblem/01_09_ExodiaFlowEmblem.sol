// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Address.sol';

contract ExodiaFlowEmblem is ERC721A, Ownable {
    uint256 public maxMintSupply = 3000;
    uint256 public maxUserMintAmount = 2;
    uint256 public wlFreeMintAmount = 1;
    uint256 public mintPrice = 0.01 ether;

    // Sale Status
    bool public publicSaleActive;
    bool public presaleActive;

    bytes32 public alMerkleRoot;
    bytes32 public wlMerkleRoot;

    bool public locked;
    string private baseURI;

    event SetALMerkleRoot(bytes32 root);
    event SetWLMerkleRoot(bytes32 root);
    event SetBaseUri(string uri);
    event TogglePresaleStatus(bool presaleStatus);
    event TogglePublicSaleStatus(bool publicSaleStatus);

    constructor() ERC721A('ExodiaFlowEmblem', 'FLOW') {}

    function ownerMint(address to, uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= maxMintSupply, 'Max supply');
        _safeMint(to, quantity);
    }

    /**
     * @dev Allows AL users to mint maxUserMintAmount for free
     *
     * Requirements:
     *
     * - Presale must be active
     * - Caller must be in AL
     * - Total number minted cannot be above max mint supply
     * - Total user amount minted cannot be above max user mint amount
     */
    function mintAL(uint256 quantity, bytes32[] calldata proof) external {
        require(presaleActive, 'Not active');
        require(_isListed(msg.sender, proof, alMerkleRoot), 'Allowlist');
        require(totalSupply() + quantity <= maxMintSupply, 'Max supply');
        require(_numberMinted(msg.sender) + quantity <= maxUserMintAmount, 'Max amount');
        _safeMint(msg.sender, quantity);
    }

    /**
     * @dev Allows WL users to mint wlFreeMintAmount for free
     *
     * Requirements:
     *
     * - Presale must be active
     * - Caller must be in WL
     * - Total number minted cannot be above max mint supply
     * - Total user amount minted cannot be above max user mint amount
     * - If WL user wants to mint more than wlFreeMintAmount, he will get wlFreeMintAmount free mints and pay for the rest
     */
    function mintWL(uint256 quantity, bytes32[] calldata proof) external payable {
        require(presaleActive, 'Not active');
        require(_isListed(msg.sender, proof, wlMerkleRoot), 'Waitlist');
        require(totalSupply() + quantity <= maxMintSupply, 'Max supply');
        require(_numberMinted(msg.sender) + quantity <= maxUserMintAmount, 'Max amount');
        require(
            (_numberMinted(msg.sender) + quantity <= wlFreeMintAmount) || (msg.value >= mintPrice),
            'Value'
        );
        _safeMint(msg.sender, quantity);
    }

    /**
     * @dev Allows users to skip mint list during presale by paying full price
     *
     * Requirements:
     *
     * - Presale must be active
     * - Total number minted cannot be above max mint supply
     * - Total user amount minted cannot be above max user mint amount
     * - Value should equal or be bigger than mint price times quantity
     */
    function mintSkipList(uint256 quantity) external payable {
        require(presaleActive, 'Not active');
        require(totalSupply() + quantity <= maxMintSupply, 'Max supply');
        require(_numberMinted(msg.sender) + quantity <= maxUserMintAmount, 'Max amount');
        require(msg.value >= mintPrice * quantity, 'Value');
        _safeMint(msg.sender, quantity);
    }

    /**
     * @dev Allows anyone to mint maxUserMintAmount during public sale for free
     *
     * Requirements:
     *
     * - Public sale must be active
     * - Total number minted cannot be above max mint supply
     * - Total user amount minted cannot be above max user mint amount
     */
    function mint(uint256 quantity) external {
        require(publicSaleActive, 'Not active');
        require(totalSupply() + quantity <= maxMintSupply, 'Max supply');
        require(_numberMinted(msg.sender) + quantity <= maxUserMintAmount, 'Max amount');
        _safeMint(msg.sender, quantity);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function numberMinted(address user) public view returns (uint256) {
        return _numberMinted(user);
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

    function setBaseURI(string memory uri) external onlyOwner {
        require(!locked, 'Locked');
        baseURI = uri;
        emit SetBaseUri(uri);
    }

    function setMaxUserMintAmount(uint256 _maxUserMintAmount) external onlyOwner {
        maxUserMintAmount = _maxUserMintAmount;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setWLFreeMintAmount(uint256 _wlFreeMintAmount) external onlyOwner {
        wlFreeMintAmount = _wlFreeMintAmount;
    }

    function lockMetadata() external onlyOwner {
        locked = true;
    }

    function setALMerkleRoot(bytes32 _root) external onlyOwner {
        alMerkleRoot = _root;
        emit SetALMerkleRoot(_root);
    }

    function setWLMerkleRoot(bytes32 _root) external onlyOwner {
        wlMerkleRoot = _root;
        emit SetWLMerkleRoot(_root);
    }

    function _leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _isListed(
        address _account,
        bytes32[] calldata _proof,
        bytes32 _root
    ) internal pure returns (bool) {
        return MerkleProof.verify(_proof, _root, _leaf(_account));
    }
}