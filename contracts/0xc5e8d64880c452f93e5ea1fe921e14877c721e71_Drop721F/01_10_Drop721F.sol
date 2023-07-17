// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "erc721a-upgradeable/contracts/ERC721A__Initializable.sol";
import "./ERC721A__OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

struct InitParams {
    string baseURI;
    uint256 maxSupply;
    uint256 maxFreeSupply;
    uint256 costPublic;
    uint256 maxMintPublic;
    uint256 freePerWallet;
    uint256 platformFee;
    uint256 costWL;
    uint256 maxMintWL;
    address withdrawAddress;
    address dev;
}

contract Drop721F is ERC721A__Initializable, ERC721AUpgradeable, ERC721A__OwnableUpgradeable {
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
    uint256 internal platformFee;
    bool public isWLmintEnabled;
    uint256 public costWL;
    uint256 public maxMintWL;
    bytes32 public whitelistRoot;
    mapping(address => uint256) public mintedByAddressWL;

    function initialize(
        string memory name,
        string memory symbol,
        InitParams memory params
    ) public initializerERC721A {
        __ERC721A_init(name, symbol);
        baseURI = params.baseURI;
        maxSupply = params.maxSupply;
        maxFreeSupply = params.maxFreeSupply;
        costPublic = params.costPublic;
        maxMintPublic = params.maxMintPublic;
        freePerWallet = params.freePerWallet;
        platformFee = params.platformFee;
        costWL = params.costWL;
        maxMintWL = params.maxMintWL;
        withdrawAddress = params.withdrawAddress;
        dev = params.dev;
        
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

    function mintWL(uint _quantity, bytes32[] calldata _merkleProof) external payable {
        require(isWLmintEnabled, "Whitelist minting not enabled");
        require(tx.origin == msg.sender, "No contracts");
        require(isWhitelisted(msg.sender, _merkleProof), "Not whitelisted");
        require(totalSupply() + _quantity <= maxSupply, "Too late");
        require(mintedByAddressWL[msg.sender] + _quantity <= maxMintWL, "Too many");
        require(msg.value == costWL * _quantity, "Ether sent is incorrect");

        mintedByAddressWL[msg.sender] += _quantity;
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

    function isWhitelisted(address _wallet, bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_wallet));
        return MerkleProof.verify(_merkleProof, whitelistRoot, leaf);
    }

    function setWhitelistRoot(bytes32 _merkleRoot) public onlyOwner {
        whitelistRoot = _merkleRoot;
    }

    function setWLmintEnabled() public onlyOwner {
        require(!isPublicMintEnabled, "Public minting is enabled, disable it first");
        isWLmintEnabled = !isWLmintEnabled;
    }

    function setPublicMintEnabled() public onlyOwner {
        require(!isWLmintEnabled, "Whitelist minting is enabled, disable it first");
        isPublicMintEnabled = !isPublicMintEnabled;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setCostPublic(uint256 _newCostPublic) public onlyOwner {
        costPublic = _newCostPublic;
    }

    function setCostWL(uint256 _newCostWL) public onlyOwner {
        costWL = _newCostWL;
    }

    function setMaxMintPublic(uint256 _newMaxMintPublic) public onlyOwner {
        maxMintPublic = _newMaxMintPublic;
    }

    function setMaxMintWL(uint256 _newMaxMintWL) public onlyOwner {
        maxMintWL = _newMaxMintWL;
    }

    function setFreePerWallet(uint256 _newFreePerWallet) public onlyOwner {
        freePerWallet = _newFreePerWallet;
    }

    function setMaxFreeSupply(uint256 _maxFreeSupply) public onlyOwner {
        maxFreeSupply = _maxFreeSupply;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance; 
        require(balance > 0, "No balance to withdraw");
        uint256 feeAmount = (balance * platformFee) / 100; 
        (bool success, ) = payable(dev).call{value: feeAmount}("");
        require(success, "Failed to transfer fees");
        (success, ) = payable(withdrawAddress).call{value: balance - feeAmount}("");
        require(success, "Failed to transfer to withdrawal address");
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token not found");
        return string(abi.encodePacked(baseURI, _toString(_tokenId), ".json"));
    }

    function decreaseMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        require(_newMaxSupply < maxSupply, "Supply can only decrease");
        require(_newMaxSupply >= totalSupply(), "Can't be less than current supply");
        maxSupply = _newMaxSupply;
    }

    function tokensOfOwner(address _address) public virtual view returns (uint256[] memory) {
        uint256 _balance = balanceOf(_address);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = totalSupply();
        for (uint256 i = 0; i < _loopThrough; i++) {
            bool _exists = _exists(i);
            if (_exists) {
                if (ownerOf(i) == _address) { _tokens[_index] = i; _index++; }
            }
            else if (!_exists && _tokens[_balance - 1] == 0) { _loopThrough++; }
        }
        return _tokens;
    }
}