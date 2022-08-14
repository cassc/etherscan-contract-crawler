// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
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

contract Balloontown is ERC721A, Ownable, PaymentSplitter {

    using Strings for uint256;

    struct Token {
        uint16 maxSupply;
        uint16 maxPerWallet;
        uint16 maxPerTransaction;
        bool preSaleIsActive;
        bool saleIsActive;
        bool supplyLock;
        uint8 salePhase;
    }

    mapping(address => bool) public fiatAllowlist;
    mapping(address => uint16) public hasMinted;
    mapping(uint8 => uint256) public salePrice;
    bytes32 public saleMerkleRoot;
    Token public token;
    string private baseURI;
    address public mintpassAddress;
    MintPass public mintpass;

    modifier onlyFiatMinter() {
        require(fiatAllowlist[msg.sender], "Not authorized");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address[] memory _payees,
        uint256[] memory _shares,
        address _owner,
        Token memory _token
    ) ERC721A(_name, _symbol)
      PaymentSplitter(_payees, _shares) {
        baseURI = _uri;
        token = _token;
        transferOwnership(_owner);
    }

    function _startTokenId() override internal pure returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }

    function getClaimIneligibilityReason(address _address, uint256 _quantity) public view returns (string memory) {
        if (totalSupply() + _quantity > uint256(token.maxSupply)) return "NOT_ENOUGH_SUPPLY";
        if (token.preSaleIsActive || !token.saleIsActive) return "NOT_LIVE";
        if (!token.preSaleIsActive && token.saleIsActive) return "";
    }

    function unclaimedSupply() public view returns (uint256) {
        return uint256(token.maxSupply - uint16(totalSupply()));
    }

    function canMint(address _address) public view returns (uint256) {
        if (token.salePhase == 1) {
            return mintpass.balanceOf(_address, 3) * 5;
        }
        if (token.salePhase == 2) {
            uint256 balance3 = mintpass.balanceOf(_address, 3);
            uint256 balance2 = mintpass.balanceOf(_address, 2);
            uint256 balance1 = mintpass.balanceOf(_address, 1);
            return balance3 * 5 + balance2 * 3 + balance1;
        }
        if (token.salePhase == 3) {
            return token.maxPerWallet - hasMinted[_address];
        }
        return token.maxPerTransaction;
    }

    function price() public view returns (uint256) {
        return salePrice[token.salePhase];
    }

    function addFiatMinter(address _address) public onlyOwner {
        fiatAllowlist[_address] = true;
    }

    function removeFiatMinter(address _address) public onlyOwner {
        delete fiatAllowlist[_address];
    }

    function setMintPass(address _address) external onlyOwner {
        mintpassAddress = _address;
        mintpass = MintPass(_address);
    }

    function setSaleRoot(bytes32 _root) public onlyOwner {
        saleMerkleRoot = _root;
    }

    function lockSupply() public onlyOwner {
        token.supplyLock = true;
    }

    function updateConfig(
        uint16 _maxSupply,
        uint16 _maxPerWallet,
        uint16 _maxPerTransaction
    ) public onlyOwner {
        require(_maxSupply >= totalSupply(), "Invalid supply");
        if (token.supplyLock) {
            require(_maxSupply == token.maxSupply, "Supply is locked");
        }
        token.maxSupply = _maxSupply;
        token.maxPerWallet = _maxPerWallet;
        token.maxPerTransaction = _maxPerTransaction;
    }

    function updatePrice(
        uint256 _price,
        uint8 _salePhase
    ) public onlyOwner {
        salePrice[_salePhase] = _price;
    }

    function setBaseTokenURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function updateSaleState(
        bool _preSaleIsActive,
        bool _saleIsActive,
        uint8 _salePhase
    ) public onlyOwner {
        require(_salePhase == 1 || _salePhase == 2 || _salePhase == 3 || _salePhase == 4, "Invalid phase.");
        if ((_preSaleIsActive && _salePhase == 1) || (_preSaleIsActive && _salePhase == 2)) {
            require(mintpassAddress != address(0), "MintPass undefined.");
        }
        if (_preSaleIsActive && _salePhase == 3) {
            require(saleMerkleRoot != "", "Root undefined");
        }
        token.preSaleIsActive = _preSaleIsActive;
        token.saleIsActive = _saleIsActive;
        token.salePhase = _salePhase;
    }

    function mint(uint16 _quantity, bytes32[] memory _proof) public payable {
        require(price() * _quantity <= msg.value, "ETH incorrect");
        uint16 _maxSupply = token.maxSupply;
        uint16 _maxPerWallet = token.maxPerWallet;
        uint16 _maxPerTransaction = token.maxPerTransaction;
        bool _saleIsActive = token.saleIsActive;
        bool _preSaleIsActive = token.preSaleIsActive;
        require(uint16(totalSupply()) + _quantity <= _maxSupply, "Insufficient supply");
        require(_saleIsActive, "Sale inactive");
        if(_preSaleIsActive) {
            if (token.salePhase == 1) {
                uint256 balance = mintpass.balanceOf(msg.sender, 3);
                require(balance * 5 >= _quantity, "Invalid quantity");
                mintpass.burnForAddress(3, balance, msg.sender);
            }
            if (token.salePhase == 2) {
                uint256 balance3 = mintpass.balanceOf(msg.sender, 3);
                uint256 balance2 = mintpass.balanceOf(msg.sender, 2);
                uint256 balance1 = mintpass.balanceOf(msg.sender, 1);
                require(balance3 * 5 + balance2 * 3 + balance1 >= _quantity, "Invalid quantity");
                if (balance3 > 0) mintpass.burnForAddress(3, balance3, msg.sender);
                if (balance2 > 0) mintpass.burnForAddress(2, balance2, msg.sender);
                if (balance1 > 0) mintpass.burnForAddress(1, balance1, msg.sender);
            }
            if (token.salePhase == 3) {
                uint16 mintedAmount = hasMinted[msg.sender] + _quantity;
                require(mintedAmount <= _maxPerWallet, "Invalid quantity");
                bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
                require(MerkleProof.verify(_proof, saleMerkleRoot, leaf), "Not whitelisted");
                hasMinted[msg.sender] = mintedAmount;
            }
        } else {
            require(_quantity <= _maxPerTransaction, "Invalid quantity");
        }
        _safeMint(msg.sender, _quantity);
    }

    function claimTo(address _address, uint256 _quantity) public payable onlyFiatMinter {
        require(token.saleIsActive, "Sale is not active.");
        require(totalSupply() + _quantity <= uint256(token.maxSupply), "Insufficient supply");
        require(price() * _quantity <= msg.value, "ETH incorrect");
        _safeMint(_address, _quantity);
    }

    function reserve(address _address, uint16 _quantity) public onlyOwner {
        require(totalSupply() + _quantity <= token.maxSupply, "Insufficient supply");
        _safeMint(_address, _quantity);
    }
}