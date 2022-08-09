// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Address.sol';

contract ExodiaFrostEmblem is ERC721A, Ownable {
    uint256 public maxMintSupply = 3000;
    uint256 public maxUserMintAmount = 3;
    uint256 public eliteFreeMintAmount = 2;
    uint256 public emblemsFreeMintAmount = 1;
    uint256 public mintPrice = 0.01 ether;

    // Sale Status
    bool public publicSaleActive;
    bool public presaleActive;

    bytes32 public eliteMerkleRoot;
    bytes32 public emblemsMerkleRoot;
    bytes32 public wlMerkleRoot;

    bool public locked;
    string private baseURI;

    event SetEliteMerkleRoot(bytes32 root);
    event SetEmblemsMerkleRoot(bytes32 root);
    event SetWLMerkleRoot(bytes32 root);

    event SetBaseUri(string uri);
    event TogglePresaleStatus(bool presaleStatus);
    event TogglePublicSaleStatus(bool publicSaleStatus);

    constructor() ERC721A('ExodiaFrostEmblem', 'FROST') {}

    function ownerMint(address to, uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= maxMintSupply, 'Max supply');
        _safeMint(to, quantity);
    }

    /**
     * @dev Allows Exodia Elite NFT holders to mint emblemsFreeMintAmount for free
     *
     * Requirements:
     *
     * - Presale must be active
     * - Caller must be in in elite addresses list
     * - Total number minted cannot be above max mint supply
     * - Mint quantity above zero
     * - Total user amount minted cannot be above max user mint amount
     * - If user wants to mint more than emblemsFreeMintAmount, he will get emblemsFreeMintAmount free mints and pay for the rest
     */
    function mintElite(uint256 quantity, bytes32[] calldata proof) external payable {
        require(presaleActive, 'Not active');
        require(_isListed(msg.sender, proof, eliteMerkleRoot), 'Elite');
        require(totalSupply() + quantity <= maxMintSupply, 'Max supply');
        require(quantity > 0, 'Above Zero');
        require(_numberMinted(msg.sender) + quantity <= maxUserMintAmount, 'Max amount');
        require(
            (_numberMinted(msg.sender) + quantity <= eliteFreeMintAmount) ||
                (msg.value >= mintPrice * (quantity - eliteFreeMintAmount)),
            'Value'
        );

        _safeMint(msg.sender, quantity);
    }

    /**
     * @dev Allows holders of both the Fire Emblem NFT & the Thunder Emblem NFT to mint emblemsFreeMintAmount for free
     *
     * Requirements:
     *
     * - Presale must be active
     * - Caller must be in in holders of both emblems addresses list
     * - Total number minted cannot be above max mint supply
     * - Mint quantity above zero
     * - Total user amount minted cannot be above max user mint amount
     * - If user wants to mint more than emblemsFreeMintAmount, he will get emblemsFreeMintAmount free mints and pay for the rest
     */
    function mintEmblems(uint256 quantity, bytes32[] calldata proof) external payable {
        require(presaleActive, 'Not active');
        require(_isListed(msg.sender, proof, emblemsMerkleRoot), 'Emblems');
        require(totalSupply() + quantity <= maxMintSupply, 'Max supply');
        require(quantity > 0, 'Above Zero');
        require(_numberMinted(msg.sender) + quantity <= maxUserMintAmount, 'Max amount');
        require(
            (_numberMinted(msg.sender) + quantity <= emblemsFreeMintAmount) ||
                (msg.value >= mintPrice * (quantity - emblemsFreeMintAmount)),
            'Value'
        );

        _safeMint(msg.sender, quantity);
    }

    /**
     * @dev Allows specific users to mint during presale
     *
     * Requirements:
     *
     * - Presale must be active
     * - Caller must be in waitlist
     * - Total number minted cannot be above max mint supply
     * - Mint quantity above zero
     * - Total user amount minted cannot be above max user mint amount
     * - User needs to pay mint price per each mint
     */
    function mintWL(uint256 quantity, bytes32[] calldata proof) external payable {
        require(presaleActive, 'Not active');
        require(_isListed(msg.sender, proof, wlMerkleRoot), 'WL');
        require(totalSupply() + quantity <= maxMintSupply, 'Max supply');
        require(quantity > 0, 'Above Zero');
        require(_numberMinted(msg.sender) + quantity <= maxUserMintAmount, 'Max amount');
        require(msg.value >= mintPrice * quantity, 'Value');

        _safeMint(msg.sender, quantity);
    }

    /**
     * @dev Allows anyone to mint during public sale
     *
     * Requirements:
     *
     * - Public sale must be active
     * - Total number minted cannot be above max mint supply
     * - Total user amount minted cannot be above max user mint amount
     * - User needs to pay mint price per each mint
     */
    function mint(uint256 quantity) external payable {
        require(publicSaleActive, 'Not active');
        require(totalSupply() + quantity <= maxMintSupply, 'Max supply');
        require(_numberMinted(msg.sender) + quantity <= maxUserMintAmount, 'Max amount');
        require(msg.value >= mintPrice * quantity, 'Value');

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

    function numberMinted(address user) public view returns (uint256) {
        return _numberMinted(user);
    }

    function setBaseURI(string memory uri) external onlyOwner {
        require(!locked, 'Locked');
        baseURI = uri;
        emit SetBaseUri(uri);
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxUserMintAmount(uint256 _maxUserMintAmount) external onlyOwner {
        maxUserMintAmount = _maxUserMintAmount;
    }

    function setEliteFreeMintAmount(uint256 _eliteFreeMintAmount) external onlyOwner {
        eliteFreeMintAmount = _eliteFreeMintAmount;
    }

    function setEmblemsFreeMintAmount(uint256 _emblemsFreeMintAmount) external onlyOwner {
        emblemsFreeMintAmount = _emblemsFreeMintAmount;
    }

    function lockMetadata() external onlyOwner {
        locked = true;
    }

    function setEliteMerkleRoot(bytes32 _root) external onlyOwner {
        eliteMerkleRoot = _root;
        emit SetEliteMerkleRoot(_root);
    }

    function setEmblemsMerkleRoot(bytes32 _root) external onlyOwner {
        emblemsMerkleRoot = _root;
        emit SetEmblemsMerkleRoot(_root);
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