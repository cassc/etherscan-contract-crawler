// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CryptoSis is ERC721, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;

    uint256 private _tokenIdTracker;

    uint256 public MAX_ELEMENTS = 10000;
    uint256 public PRESALE_ELEMENTS = 1000;
    uint256 public constant PRE_PRICE = 0.08 ether;
    uint256 public constant PRICE = 0.1 ether;
    uint256 public constant MAX_BY_MINT = 10;
    uint256 public constant MAX_PRESALE_MINT = 3;
    
    string public baseTokenURI;

    bytes32 public whitelistMerkleRoot;
    mapping(address => uint256) public whitelistClaimed;
    bool public publicSaleOpen;

    address public constant creatorAddress = 0x413Eb350944f01c087f1a260894A0B5F7BeA8fb0;
    address public constant managerAddress = 0x2E342B44F8E8A7e096C996Bb3dA34832Ae1BBf16;
    address public constant marketingAddress = 0xf5D71a9d75AbCAB2fC79Cf7306Fbc38e33ED6f2D;
    address public constant investorAddress = 0x2F6c7e2288416c35743D14107d4837e5F51E8fA9;
    address public constant devAddress = 0x54877e27B8f5373761c2E17Ff7c87511d38F3b00;

    event CreateSis(uint256 indexed id);
    constructor()
    ERC721("Crypto Sis", "SIS") 
    {
        setBaseURI('https://api.cryptosisnft.io/sis/');
        pause(true);
    }

    modifier saleIsOpen {
        require(totalSupply() <= MAX_ELEMENTS, "Sale end");
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }

    modifier noContract() {
        address account = msg.sender;
        require(account == tx.origin, "Caller is a contract");
        require(account.code.length == 0, "Caller is a contract");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdTracker;
    }

    function mint(uint256 _count) public payable saleIsOpen noContract {
        uint256 total = totalSupply();
        require(publicSaleOpen, "Public sale not open yet");
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        require(msg.value == PRICE * _count, "Value is over or under price.");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
        }
    }

    function presaleMint(uint256 _count, bytes32[] calldata proof) public payable saleIsOpen noContract  {
        uint256 total = totalSupply();
        require(_count <= MAX_PRESALE_MINT, "Exceeds number");
        require(total + _count <= PRESALE_ELEMENTS, "Max limit");
        require(verifySender(proof), "MerkleWhitelist: Caller is not whitelisted");
        require(canMintAmount(_count), "Sender max presale mint amount already met");
        require(msg.value == PRE_PRICE * _count, "Value is over or under price.");

        whitelistClaimed[msg.sender] += _count;
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
        }

    }

    function ownerMint(uint256 _count) public onlyOwner {
        uint256 total = _tokenIdTracker;
        require(total + _count <= MAX_ELEMENTS, "Sale end");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
        }

    }

    function _mintAnElement(address _to) private {
        uint id = totalSupply();
        _tokenIdTracker += 1;
        _mint(_to, id);
        emit CreateSis(id);
    }

    function verifySender(bytes32[] calldata proof) public view returns (bool) {
        return _verify(proof, _hash(msg.sender));
    }

    function canMintAmount(uint256 _count) public view returns (bool) {
        return whitelistClaimed[msg.sender] + _count <= MAX_PRESALE_MINT;
    }

    function _verify(bytes32[] calldata proof, bytes32 addressHash)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, whitelistMerkleRoot, addressHash);
    }

    function _hash(address _address) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_address));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setPublicSale(bool val) public onlyOwner {
        publicSaleOpen = val;
    }

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 creatorShare = balance.mul(52).div(100);
        uint256 managerShare = balance.mul(10).div(100);
        uint256 investorShare = balance.mul(12).div(100);
        uint256 marketingShare = balance.mul(12).div(100);
        uint256 devShare = balance.mul(14).div(100);
        require(balance > 0);
        _withdraw(creatorAddress, creatorShare);
        _withdraw(managerAddress, managerShare);
        _withdraw(marketingAddress, marketingShare);
        _withdraw(investorAddress, investorShare);
        _withdraw(devAddress, devShare);
    }

    function setMaxElements(uint256 _elements) public onlyOwner {
        MAX_ELEMENTS = _elements;
    }

    function setPresaleElements(uint256 _elements) public onlyOwner {
        PRESALE_ELEMENTS = _elements;
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
}