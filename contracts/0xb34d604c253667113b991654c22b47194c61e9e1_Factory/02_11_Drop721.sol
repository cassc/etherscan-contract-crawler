// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "erc721a-upgradeable/contracts/ERC721A__Initializable.sol";
import "./ERC721A__OwnableUpgradeable.sol";

contract Drop721 is ERC721A__Initializable, ERC721AUpgradeable, ERC721A__OwnableUpgradeable {
    mapping(address => uint256) public mintedByAddress;
    string public baseURI;
    bool public isPublicMintEnabled;
    uint256 public maxSupply;
    uint256 public maxFreeSupply;
    uint256 public costPublic;
    uint256 public maxMintPublic;
    uint256 public freePerWallet;
    address internal withdrawAddress;
    address internal dev;
    uint256 internal dShare;

    function initialize(
        string memory name,
        string memory symbol,
        string memory _baseURI,
        uint256 _maxSupply,
        uint256 _maxFreeSupply,
        uint256 _costPublic,
        uint256 _maxMintPublic,
        uint256 _freePerWallet,
        uint256 _dShare,
        address  _withdrawAddress,
        address  _dev
    ) public initializerERC721A {
        __ERC721A_init(name, symbol);

        baseURI = _baseURI;
        isPublicMintEnabled = false;
        maxSupply = _maxSupply;
        maxFreeSupply = _maxFreeSupply;
        costPublic = _costPublic;
        maxMintPublic = _maxMintPublic;
        freePerWallet = _freePerWallet;
        dShare = _dShare;
        withdrawAddress = _withdrawAddress;
        dev = _dev;

        __Ownable_init();
    }

    function mint(uint _quantity) external payable {
        uint256 _cost = getCost(msg.sender, _quantity);
        require(tx.origin == msg.sender, "No contracts");
        require(isPublicMintEnabled, "Not yet");
        require(totalSupply() + _quantity <= maxSupply, "Too late");
        require(_quantity <= maxMintPublic, "Too many");
        require(msg.value == _cost, "Ether sent is incorrect");
        mintedByAddress[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function airdrop(uint256 _quantity, address _recipient) external onlyOwner {
        require(totalSupply() + _quantity <= maxSupply, "Too many");
        _mint(_recipient, _quantity);
    }

    function devMint(uint256 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= maxSupply, "Too many");
        _mint(msg.sender, _quantity);
    }

    function canClaim(address _address) public view returns (bool) {
        return mintedByAddress[_address] < freePerWallet && totalSupply() < maxFreeSupply;
    }

    function getCost(address _address, uint256 _count) public view returns (uint256) {
        if (canClaim(_address)) {
            uint256 freeCount = freePerWallet - mintedByAddress[_address];
            if (_count <= freeCount) {
                return 0;
            }
            return costPublic * (_count - freeCount);
        }
        return costPublic * _count;
    }

    function setPublicMintEnabled() public onlyOwner {
        isPublicMintEnabled = !isPublicMintEnabled;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        costPublic = _newCost;
    }

    function setMaxBatchSize(uint256 _newBatchSize) public onlyOwner {
        maxMintPublic = _newBatchSize;
    }

    function setFreePerWallet(uint256 _newFreePerWallet) public onlyOwner {
        freePerWallet = _newFreePerWallet;
    }

    function setMaxFreeSupply(uint256 _maxFreeSupply) public onlyOwner {
        maxFreeSupply = _maxFreeSupply;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        uint256 dAmount = (balance * dShare) / 100;
        require(payable(dev).send(dAmount));
        require(payable(withdrawAddress).send(balance - dAmount));
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token not found");
        return string(abi.encodePacked(baseURI, _toString(_tokenId), ".json"));
    }
}