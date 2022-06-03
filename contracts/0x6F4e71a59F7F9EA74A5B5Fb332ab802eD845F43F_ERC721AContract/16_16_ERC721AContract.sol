// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

abstract contract MintPass {
    function balanceOf(address owner, uint256 id)
        public
        view
        virtual
        returns (uint256 balance);
    function burnForAddress(
        uint256 _id, 
        uint256 _quantity,
        address _address
    ) public virtual;
}

contract ERC721AContract is ERC721A, Ownable, PaymentSplitter, ReentrancyGuard {

    struct InitialParameters {
        uint256 launchpassId;
        string name;
        string symbol;
        string uri;
        uint24 maxSupply;
        uint24 maxPerWallet;
        uint24 maxPerTransaction;
        uint72 preSalePrice;
        uint72 pubSalePrice;
    }

    mapping(address => uint) public hasMinted;
    bytes32 public merkleRoot;
    uint24 public maxSupply;
    uint24 public maxPerWallet;
    uint24 public maxPerTransaction;
    uint8 public preSalePhase;
    uint72 public preSalePrice;
    uint72 public pubSalePrice;
    bool public preSaleIsActive = false;
    bool public saleIsActive = false;
    bool public supplyLock = false;
    uint256 public launchpassId;
    string private uri;
    bool public burnMintPass = false;
    uint256 public mintpassId;
    address public mintpassAddress;
    MintPass mintpass;
    address public fiatMinterAddress;

    modifier onlyFiatMinter() {
        require(msg.sender == fiatMinterAddress, "Not authorized to perfrom this action");
        _;
    }

    constructor(
        address[] memory _payees,
        uint256[] memory _shares,
        address _owner,
        InitialParameters memory initialParameters
    ) ERC721A(initialParameters.name, initialParameters.symbol)
      PaymentSplitter(_payees, _shares) {
        launchpassId = initialParameters.launchpassId;
        uri = initialParameters.uri;
        maxSupply = initialParameters.maxSupply;
        maxPerWallet = initialParameters.maxPerWallet;
        maxPerTransaction = initialParameters.maxPerTransaction;
        preSalePrice = initialParameters.preSalePrice;
        pubSalePrice = initialParameters.pubSalePrice;
        transferOwnership(_owner);
    }

    function setFiatMinter(address _address) public onlyOwner {
        fiatMinterAddress = _address;
    }

    function setMintPass(uint256 _id, address _address, bool _burn) external onlyOwner {
        mintpassAddress = _address;
        mintpassId = _id;
        burnMintPass = _burn;
        mintpass = MintPass(_address);
    }

    function setRoot(bytes32 _root) public onlyOwner {
        merkleRoot = _root;
    }

    function setMaxSupply(uint24 _supply) public onlyOwner {
        require(!supplyLock, "Supply is locked.");
        maxSupply = _supply;
    }

    function lockSupply() public onlyOwner {
        supplyLock = true;
    }

    function setPreSalePrice(uint72 _price) public onlyOwner {
        preSalePrice = _price;
    }

    function setPublicSalePrice(uint72 _price) public onlyOwner {
        pubSalePrice = _price;
    }

    function setPreSalePhase(uint8 _phase) public onlyOwner {
        // 1 = mintpasses, 2 = whitelist
        if (_phase == 1) {
            require(mintpassAddress != address(0), "MintPass is undefined.");
        }
        if (_phase == 2) {
            require(merkleRoot != "", "Merkle root is undefined.");
        }
        require(_phase == 1 || _phase == 2, "Invalid presale phase.");
        preSalePhase = _phase;
    }

    function setMaxPerWallet(uint24 _quantity) public onlyOwner {
        maxPerWallet = _quantity;
    }

    function setMaxPerTransaction(uint24 _quantity) public onlyOwner {
        maxPerTransaction = _quantity;
    }

    function setBaseTokenURI(string memory _uri) public onlyOwner {
        uri = _uri;
    }

    function setSaleState(bool _isActive) public onlyOwner {
        saleIsActive = _isActive;
    }

    function setPreSaleState(bool _isActive) public onlyOwner {
        if (_isActive && preSalePhase == 1) {
            require(mintpassAddress != address(0), "MintPass is undefined.");
        }
        if (_isActive && preSalePhase == 2) {
            require(merkleRoot != "", "Merkle root is undefined.");
        }
        preSaleIsActive = _isActive;
    }

    function baseTokenURI() virtual public view returns (string memory) {
        return uri;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }

    function verify(bytes32 leaf, bytes32[] memory proof) public view returns (bool) {
        bytes32 computedHash = leaf;
        for (uint i = 0; i < proof.length; i++) {
          bytes32 proofElement = proof[i];
          if (computedHash <= proofElement) {
            computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
          } else {
            computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
          }
        }
        return computedHash == merkleRoot;
    }

    function getClaimIneligibilityReason(address userWallet, uint256 quantity) public view returns (string memory) {
        return saleIsActive && !preSaleIsActive ? "" : "NOT_LIVE";
    }

    function unclaimedSupply() public view returns (uint256) {
        return maxSupply - totalSupply();
    }

    function price() public view returns (uint256) {
        if (preSaleIsActive) {
            return preSalePrice;
        } else {
            return pubSalePrice;
        }
    }

    function mint(uint _quantity, bytes32[] memory _proof) public payable nonReentrant {
        require(price() * _quantity <= msg.value, "ETH sent is incorrect.");
        uint _maxSupply = maxSupply;
        uint _maxPerWallet = maxPerWallet;
        uint _maxPerTransaction = maxPerTransaction;
        bool _saleIsActive = saleIsActive;
        bool _preSaleIsActive = preSaleIsActive;
        uint _currentSupply = totalSupply();
        require(_saleIsActive, "Sale is not active.");
        require(_currentSupply <= _maxSupply, "Sold out.");
        require(_currentSupply + _quantity <= _maxSupply, "Requested quantity would exceed total supply.");
        if(_preSaleIsActive) {
            uint mintedAmount = hasMinted[msg.sender] + _quantity;
            require(mintedAmount <= _maxPerWallet, "Exceeds per wallet presale limit.");
            if (preSalePhase == 1) {
                require(mintpass.balanceOf(msg.sender, mintpassId) > 0, "You do not have a MintPass.");
                require(_quantity <= mintpass.balanceOf(msg.sender, mintpassId) , "Exceeds wallet presale limit.");
                if (burnMintPass) mintpass.burnForAddress(mintpassId, _quantity, msg.sender);
            }
            if (preSalePhase == 2) {
                require(_quantity <= _maxPerWallet, "Exceeds wallet presale limit.");
                bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
                require(verify(leaf, _proof), "You are not whitelisted.");
            }
            hasMinted[msg.sender] = mintedAmount;
        } else {
            require(_quantity <= _maxPerTransaction, "Exceeds per transaction limit for public sale.");
        }
        _safeMint(msg.sender, _quantity);
    }

    function claimTo(address userWallet, uint256 quantity) public payable nonReentrant {
        require(fiatMinterAddress != address(0), "Fiat minter is undefined.");
        require(totalSupply() + quantity <= maxSupply, "Requested quantity would exceed total supply.");
        _safeMint(userWallet, quantity);
    }

    function claimFree(uint256 _quantity, bytes32[] memory _proof) public nonReentrant {
        bytes32 leaf = keccak256(abi.encode(msg.sender, _quantity));
        require(verify(leaf, _proof), "Bad proof.");
        _safeMint(msg.sender, _quantity);
    }

    function releaseERC721(address _address, uint256 _tokenId) public onlyOwner nonReentrant {
        IERC721 nft = IERC721(_address);
        nft.safeTransferFrom(address(this), msg.sender, _tokenId);
    }

    function reserve(address _address, uint _quantity) public nonReentrant onlyOwner {
        require(totalSupply() + _quantity <= maxSupply, "Requested quantity would exceed total supply.");
        _safeMint(_address, _quantity);
    }
}