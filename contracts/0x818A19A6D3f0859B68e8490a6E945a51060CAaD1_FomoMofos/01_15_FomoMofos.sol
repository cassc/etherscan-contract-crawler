// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract FomoMofos is ERC721, Ownable, ERC721Burnable, ERC721Pausable {
    uint256 private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS = 8008;
    uint256 public constant PRESALE_ELEMENTS = 5800;
    uint256 public constant PRICE = 0.08 ether;
    uint256 public constant MAX_BY_MINT = 3;
    uint256 public constant tierOneMaxMint = 1;
    uint256 public constant tierTwoMaxMint = 2;
    uint256 public constant tierThreeMaxMint = 3;
    
    string public baseTokenURI;

    address public withdrawAddress;

    bytes32 public tierOneMerkleRoot;
    bytes32 public tierTwoMerkleRoot;
    bytes32 public tierThreeMerkleRoot;

    mapping(address => uint256) public whitelistClaimed;

    bool public publicSaleOpen;

    event CreateItem(uint256 indexed id);
    constructor()
    ERC721("FOMO MOFOS", "FOMO") 
    {
        pause(true);
        setWithdrawAddress(0xf39B6C4123Bba330eba088ea20d899D80302aad2);
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

    function presaleMint(uint256 _count, bytes32[] calldata _proof, uint256 _tier) public payable saleIsOpen noContract {
        uint256 total = totalSupply();
        require(msg.value == PRICE * _count, "Value is over or under price.");
        require(total + _count <= PRESALE_ELEMENTS, "Max limit");
        require(verifySender(_proof, _tier), "Sender is not whitelisted");
        require(canMintAmount(_count, _tier), "Sender max presale mint amount already met");

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
        } else if (_tier == 3) {
            maxMintAmount = tierThreeMaxMint;
        }

        return whitelistClaimed[msg.sender] + _count <= maxMintAmount;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot, uint256 _tier) external onlyOwner {
        require(_tierExists(_tier), "Tier does not exist");

        if (_tier == 1) {
            tierOneMerkleRoot = _merkleRoot;
        } else if (_tier == 2) {
            tierTwoMerkleRoot = _merkleRoot;
        } else if (_tier == 3) {
            tierThreeMerkleRoot = _merkleRoot;
        }
    }

    function _tierExists(uint256 _tier) private pure returns (bool) {
        return _tier <= 3;
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
        } else if (_tier == 3) {
            whitelistMerkleRoot = tierThreeMerkleRoot;
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
        require(balance > 0);
        _withdraw(withdrawAddress, balance);
    }

    function setWithdrawAddress(address _withdrawAddress) public onlyOwner {
        withdrawAddress = _withdrawAddress;
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