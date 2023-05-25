// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ClayFriends is ERC721, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    
    uint256 private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS = 5000;
    uint256 public constant PRICE = 0.2 ether;
    uint256 public constant tierOneMaxMint = 1;
    uint256 public constant tierTwoMaxMint = 2;
    
    string public baseTokenURI;

    address public constant creatorAddress = 0x32c43B4362d7FC78FB802e4aA9d7C0dB4b9d704d;
    address public constant partnerOneAddress = 0x3F527E7cf88CF08de67c1C823C92282d25aB7ceE;
    address public constant partnerTwoAddress = 0xA007CCF234D7E5306615035BBA0D32b0F5D25BdE;
    address public constant devAddress = 0xcf1B69355FA32ad648A8689E342c717a3323FD43;

    bytes32 public tierOneMerkleRoot;
    bytes32 public tierTwoMerkleRoot;

    mapping(address => uint256) public whitelistClaimed;

    bool public publicSaleOpen;

    event CreateItem(uint256 indexed id);
    constructor()
    ERC721("Clay Friends", "CLAY") 
    {
        pause(true);
    }

    modifier saleIsOpen {
        require(_tokenIdTracker <= MAX_ELEMENTS, "Sale end");
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

    function setPublicSale(bool val) public onlyOwner {
        publicSaleOpen = val;
    }

    function mint(uint256 _count, bytes32[] calldata _proof, uint256 _tier) public payable saleIsOpen noContract {
        uint256 total = totalSupply();
        require(msg.value == PRICE * _count, "Value is over or under price.");
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(verifySender(_proof, _tier), "Sender is not whitelisted");
        require(canMintAmount(_count, _tier), "Sender max mint amount already met");

        whitelistClaimed[msg.sender] += _count;
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
        }
    }

    function ownerMint(uint256 _count) public onlyOwner {
        uint256 total = totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Sale end");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
        }

    }

     // EMERGENCY USE ONLY, THERE IS NO PLANNED PUBLIC SALE //
    function publicMint(uint256 _count) public payable saleIsOpen noContract {
        uint256 total = totalSupply();
        require(publicSaleOpen, "Public sale not open yet");
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(_count <= tierOneMaxMint, "Exceeds number");
        require(msg.value == PRICE * _count, "Value is over or under price.");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
        }
    }

    function _mintAnElement(address _to) private {
        uint id = totalSupply();
        _tokenIdTracker += 1;
        _mint(_to, id);
        emit CreateItem(id);
    }

    function canMintAmount(uint256 _count, uint256 _tier) public view returns (bool) {
        uint256 maxMintAmount;

        if (_tier == 1) {
            maxMintAmount = tierOneMaxMint;
        } else if (_tier == 2) {
            maxMintAmount = tierTwoMaxMint;
        }

        return whitelistClaimed[msg.sender] + _count <= maxMintAmount;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot, uint256 _tier) external onlyOwner {
        require(_tier <= 2, "Tier does not exist");

        if (_tier == 1) {
            tierOneMerkleRoot = _merkleRoot;
        } else if (_tier == 2) {
            tierTwoMerkleRoot = _merkleRoot;
        }
    }

    function verifySender(bytes32[] calldata proof, uint256 _tier) public view returns (bool) {
        return _verify(proof, _hash(msg.sender), _tier);
    }

    function _verify(bytes32[] calldata proof, bytes32 addressHash, uint256 _tier) internal view returns (bool) {
        bytes32 whitelistMerkleRoot;

        if (_tier == 1) {
            whitelistMerkleRoot = tierOneMerkleRoot;
        } else if (_tier == 2) {
            whitelistMerkleRoot = tierTwoMerkleRoot;
        }

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

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 creatorShare = balance.mul(76).div(100);
        uint256 partnerOneShare = balance.mul(2).div(100);
        uint256 partnerTwoShare = balance.mul(2).div(100);
        uint256 devShare = balance.mul(20).div(100);
        require(balance > 0);
        _withdraw(creatorAddress, creatorShare);
        _withdraw(partnerOneAddress, partnerOneShare);
        _withdraw(partnerTwoAddress, partnerTwoShare);
        _withdraw(devAddress, devShare);
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