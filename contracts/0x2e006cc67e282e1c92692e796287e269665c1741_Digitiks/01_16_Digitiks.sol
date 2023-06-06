// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Digitiks is ERC721, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;

    uint256 private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS = 999;
    uint256 public constant PRICE = 0.069 ether;
    uint256 public maxMint = 1;
    uint256 public vipMaxMint = 2;
    
    string public baseTokenURI;

    address public creatorAddress = 0x2B3E7FdeBC282a3F18fE9F3C759cbcfB666E5096;
    address public teamOneAddress = 0x1E35435F753142325aC9a73a72ACCf95B3f6d08e;
    address public teamTwoAddress = 0xc4493481E5591E8b8c778b1D3DA646b974715720;
    address public teamThreeAddress = 0x3399976F0359FA7e860A1721273d8609452456c6;
    address public devAddress = 0xB47730FbAc38f6FFc6ad51068F572B7C575F0ef5;

    bytes32 public merkleRoot;
    bytes32 public vipMerkleRoot;

    mapping(address => uint256) public whitelistClaimed;

    bool public saleOpen;
    bool public publicSaleOpen;

    event CreateItem(uint256 indexed id);
    constructor()
    ERC721("Digitiks", "DGTKS") 
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

    function setSale(bool val) public onlyOwner {
        saleOpen = val;
    }

    function setPublicSale(bool val) public onlyOwner {
        publicSaleOpen = val;
    }

    function whitelistMint(uint256 _count, bytes32[] calldata _proof, uint256 _tier) public payable saleIsOpen noContract {
        uint256 total = totalSupply();
        require(saleOpen, "Sale not open at this time.");
        require(msg.value == PRICE * _count, "Value is over or under price.");
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(verifySender(_proof, _tier), "Sender is not whitelisted");
        require(canMintAmount(_count, _tier), "Sender max presale mint amount already met");

        whitelistClaimed[msg.sender] += _count;
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
        }
    }

    // public sale not expected
    function mint(uint256 _count) public payable saleIsOpen noContract {
        uint256 total = totalSupply();
        require(publicSaleOpen, "Public sale not open");
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(_count <= maxMint, "Exceeds number");
        require(msg.value == PRICE * _count, "Value is over or under price.");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
        }
    }

    // collect for 0x2B3E7FdeBC282a3F18fE9F3C759cbcfB666E5096
    function ownerMint(uint256 _count, address addr) public onlyOwner {
        uint256 total = totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Sale end");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(addr);
        }

    }

    function _mintAnElement(address _to) private {
        uint id = totalSupply();
        _tokenIdTracker += 1;
        _mint(_to, id);
        emit CreateItem(id);
    }

    function canMintAmount(uint256 _count, uint256 _tier) public view returns (bool) {
        require(_tierExists(_tier), "Tier does not exist");
        uint256 maxMintAmount;

        if (_tier == 1) {
            maxMintAmount = maxMint;
        } else if (_tier == 2) {
            maxMintAmount = vipMaxMint;
        }

        return whitelistClaimed[msg.sender] + _count <= maxMintAmount;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot, uint256 _tier) external onlyOwner {
        require(_tierExists(_tier), "Tier does not exist");

        if (_tier == 1) {
            merkleRoot = _merkleRoot;
        } else if (_tier == 2) {
            vipMerkleRoot = _merkleRoot;
        }
    }

    function raiseMaxMints() public onlyOwner {
        maxMint = 2;
        vipMaxMint = 3;
    } 

    function _tierExists(uint256 _tier) private pure returns (bool) {
        return _tier <= 2;
    }

    function verifySender(bytes32[] calldata proof, uint256 _tier) public view returns (bool) {
        return _verify(proof, _hash(msg.sender), _tier);
    }

    function _verify(bytes32[] calldata proof, bytes32 addressHash, uint256 _tier) internal view returns (bool) {
        require(_tierExists(_tier), "Tier does not exist");
        bytes32 whitelistMerkleRoot;

        if (_tier == 1) {
            whitelistMerkleRoot = merkleRoot;
        } else if (_tier == 2) {
            whitelistMerkleRoot = vipMerkleRoot;
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
        uint256 creatorShare = balance.mul(50).div(100);
        uint256 teamOneShare = balance.mul(10).div(100);
        uint256 teamTwoShare = balance.mul(10).div(100);
        uint256 teamThreeShare = balance.mul(10).div(100);
        uint256 devShare = balance.mul(20).div(100);
        require(balance > 0);
        _withdraw(creatorAddress, creatorShare);
        _withdraw(teamOneAddress, teamOneShare);
        _withdraw(teamTwoAddress, teamTwoShare);
        _withdraw(teamThreeAddress, teamThreeShare);
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