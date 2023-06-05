//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// contract by @wagglefoot

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error MintNotOpen();
error NoContractCall();
error ExceedsMaxMint();
error SupplyExhausted();
error ALSupplyExhausted();
error IncorrectAmountSent();
error NotOnAllowList();
error AllocationExhausted();
error NotCrossmint();
error NonExistantToken();
error NotDev();

contract ThreeSixFive is ERC721A, Ownable {
    using Strings for uint256;
    // ERC4906
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    bytes32 public merkleRoot;
    uint256 public constant SUPPLY = 366;
    uint256 public allowListSupply;
    uint256 public maxPerWallet = 8;
    uint256 public maxPerAllowList = 3;
    uint256 public price = 0.08 ether;
    address public crossmintAddress;
    address public devAddress;
    string private baseURI;
    bool public revealed;
    bool public mintOpen;

    constructor(address _dev) ERC721A("Three Six Five", "365") {
        devAddress = _dev;
    }

    modifier noContract {
        if (tx.origin != msg.sender) revert NoContractCall();
        _;
    }

    modifier mintCompliance(uint256 quantity) {
        if (!mintOpen) revert MintNotOpen();
        if (msg.value != (price * quantity)) revert IncorrectAmountSent();
        _;
    }

    function mint(uint256 quantity) external payable mintCompliance(quantity) noContract {
        if (_numberMinted(msg.sender) + quantity > maxPerWallet) revert ExceedsMaxMint();
        if (totalSupply() + quantity > SUPPLY - allowListSupply) revert SupplyExhausted();
        _mint(msg.sender, quantity);
    }

    function allowListMint(uint256 quantity, bytes32[] calldata proof)
        external
        payable
        mintCompliance(quantity)
        noContract
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verifyCalldata(proof, merkleRoot, leaf)) revert NotOnAllowList();
        if (_numberMinted(msg.sender) + quantity > maxPerAllowList) revert AllocationExhausted();
        if (quantity > allowListSupply) revert ALSupplyExhausted();

        allowListSupply -= quantity;
        _mint(msg.sender, quantity);
    }

    function crossmint(uint256 quantity, address _to) public payable mintCompliance(quantity) {
        if (msg.sender != crossmintAddress) revert NotCrossmint();
        if (totalSupply() + quantity > SUPPLY - allowListSupply) revert SupplyExhausted();

        _safeMint(_to, quantity);
    }

    function setCrossmintAddress(address _crossmintAddress) public onlyOwner {
        crossmintAddress = _crossmintAddress;
    }

    function setMerkleRoot(bytes32 _newRoot) external onlyOwner {
        merkleRoot = _newRoot;
    }

    function toggleMintState() external onlyOwner {
        mintOpen = !mintOpen;
    }

    function changePrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function changeMaxPerWallet(uint256 _newMax) external onlyOwner {
        maxPerWallet = _newMax;
    }

    function changeMaxAllowList(uint256 _newMax) external onlyOwner {
        maxPerAllowList = _newMax;
    }

    function changeAllowListSupply(uint256 _newSupply) external onlyOwner {
        allowListSupply = _newSupply;
    }

    function setBaseURI(string calldata _baseURI, bool reveal) external onlyOwner {
        if (!revealed && reveal) revealed = reveal; 
        baseURI = _baseURI;

        emit BatchMetadataUpdate(1, totalSupply());
    }

    function ownerMint(address _to, uint256 _quantity) external onlyOwner {
        if (totalSupply() + _quantity > SUPPLY) revert SupplyExhausted();
        _mint(_to, _quantity);
    }

    function updateDevAddress(address _dev) external {
        if (msg.sender != devAddress) revert NotDev();
        devAddress = _dev;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 devCut = (balance * 7) / 100;
        uint256 ownerCut = (balance * 93) / 100;
        (bool os, ) = payable(devAddress).call{value: devCut}("");
        require(os);
        (os, ) = payable(owner()).call{value: ownerCut}("");
        require(os);
    }

    function numberMinted(address _address) public view returns (uint256) {
        return _numberMinted(_address);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if (!_exists(_tokenId)) revert NonExistantToken();
        if (revealed) {
            return string(abi.encodePacked(baseURI, _tokenId.toString()));
        } else {
            return baseURI;
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}