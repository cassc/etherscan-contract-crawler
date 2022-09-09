pragma solidity ^0.8.12;

import "./ERC721ACustom.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "hardhat/console.sol";

contract KumaToy is ERC721ACustom, Ownable {

    uint256 public immutable maxSupply;

    bool public holderSaleActive;
    bool public presaleActive;
    bool public saleActive;

    string public baseTokenURI;

    bytes32 public holdersMerkleRoot = 0x0;
    bytes32 public whitelistMerkleRoot = 0x0;
    mapping(address => bool) public whitelistClaimed;
    mapping(address => uint256) public publicClaimed;
    mapping(address => uint256) public holdersClaimed;

    error SaleInactive();
    error MaxSupplyExceeded();
    error MaxMint();
    error ValueSentIncorrect();
    error MaxCollectionReached();
    error NotWhitelisted();

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        uint256 _maxSupply
    ) ERC721ACustom(_name, _symbol){
        baseTokenURI = _baseTokenURI;
        maxSupply = _maxSupply;
    }

    function mint(uint256 _quantity) external payable {
        if (!saleActive) revert SaleInactive();
        if (totalSupply() + _quantity > maxSupply) revert MaxSupplyExceeded();
        if (publicClaimed[msg.sender] + _quantity > 3) revert MaxMint();

        publicClaimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function mintWhitelist(bytes32[] calldata _merkleProof) external payable {
        if (!presaleActive) revert SaleInactive();
        if (totalSupply() + 1 > maxSupply) revert MaxSupplyExceeded();
        if (!isWhitelisted(_merkleProof, msg.sender)) revert NotWhitelisted();
        if (whitelistClaimed[msg.sender]) revert MaxMint();

        whitelistClaimed[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function mintHolder(uint256 _quantity, uint256 _maxQuantity, bytes32[] calldata _merkleProof) external payable {
        if (!holderSaleActive) revert SaleInactive();
        if (totalSupply() + _quantity > maxSupply) revert MaxSupplyExceeded();
        if (!checkHolderValidity(_merkleProof, msg.sender, _maxQuantity)) revert NotWhitelisted();
        if (holdersClaimed[msg.sender] + _quantity > _maxQuantity) revert MaxMint();

        holdersClaimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function checkHolderValidity(bytes32[] calldata _merkleProof, address _address, uint256 _maxQuantity) internal view returns (bool){
        bytes32 leaf = keccak256(abi.encodePacked(_address, _maxQuantity));
        return MerkleProof.verify(_merkleProof, holdersMerkleRoot, leaf);
    }

    function isWhitelisted(bytes32[] calldata _merkleProof, address _address) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf);
    }

    function toggleSale() external onlyOwner {
        saleActive = !saleActive;
    }

    function togglePresale() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function toggleHolderSale() external onlyOwner {
        holderSaleActive = !holderSaleActive;
    }

    function reserve(uint256 _quantity) external onlyOwner {
        if (totalSupply() + _quantity > maxSupply) revert MaxSupplyExceeded();
        _safeMint(msg.sender, _quantity);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(
        string calldata _baseTokenURI
    ) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function setHoldersMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        holdersMerkleRoot = _merkleRoot;
    }


    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function withdraw() public onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }
}