// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract MrAndLittleMiss is Ownable, ReentrancyGuard, ERC721A {
    using Strings for uint256;

    //SALE STATES
    //0 - Sale Disabled
    //1 - Whitelist Sale
    //2 - Public Sale

    uint8 public saleState = 0;
    uint8 public maxPerWallet = 10;
    uint16 public teamAllocation = 510;
    uint16 public maxSupply = 5100;
    uint64 public priceWL = 0.0033 ether;
    uint64 public pricePublic = 0.0049 ether;
    string private baseURI;
    bytes32 private merkleRoot;
    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _team;

    mapping(address => uint8) public minted;

    modifier onlyTeam() {
        require(_shares[msg.sender]!=0, "Not a party to the contract");
        _;
    }

    constructor(address[] memory team_, uint8[] memory allocation_) ERC721A("Mr. and Little Miss", "MALM") {
        for (uint256 i = 0; i < team_.length; i++) {
            _addTeam(team_[i], allocation_[i]);
        }
    }

    function publicMint(uint8 quantity) external payable nonReentrant {
        require(saleState == 2, "Public sale has not started yet");
        require(totalSupply() + quantity <= maxSupply, "Max supply exceeded");
        require(minted[msg.sender] + quantity <= maxPerWallet, "Exceeded per wallet limit");
        require(msg.value >= quantity*pricePublic, "Incorrect ETH amount");
        require(tx.origin == _msgSender(), "No contracts");
        minted[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function whitelistMint(uint8 quantity, bytes32[] calldata _merkleProof) external payable nonReentrant {
        require(saleState == 1, "Whitelist sale has not started yet");
        require(totalSupply() + quantity <= maxSupply, "Max supply exceeded");
        require(minted[msg.sender] + quantity <= maxPerWallet, "Exceeded per wallet limit");
        require(tx.origin == _msgSender(), "No contracts");
        require(msg.value >= quantity*priceWL, "Incorrect ETH amount");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid Merkle Proof");
        minted[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '';
    }

    function setSaleState(uint8 _state) external onlyOwner {
        saleState = _state;
    }

    function setMaxPerWallet(uint8 _perWallet) external onlyOwner {
        maxPerWallet = _perWallet;
    }

    function setBaseURI(string calldata _data) external onlyOwner {
        baseURI = _data;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPrice(uint64 _price, bool _wl) external onlyOwner {
        if (_wl) {
            priceWL = _price;
        } else {
            pricePublic = _price;
        }
    }

    function devMint(address[] memory team_, uint16[] memory allocation_) external onlyOwner {
        require(team_.length == allocation_.length, "Number of wallets and allocations are different");
        uint16 quantity = 0;
        for (uint16 i = 0; i < allocation_.length; i++) {
            quantity += allocation_[i];
        }
        require(totalSupply() + quantity <= teamAllocation, "Team allocation exceeding limit");
        for (uint16 i = 0; i < team_.length; i++) {
            _safeMint(team_[i], allocation_[i]);
        }
    }

    function burnSupply(uint16 _maxSupply) external onlyOwner {
        require(_maxSupply < maxSupply, "New max supply should be lower than current max supply");
        require(_maxSupply > totalSupply(), "New max suppy should be higher than current number of minted tokens");
        maxSupply = _maxSupply;
    }

    function withdraw() external onlyTeam {
        require(address(this).balance > 0, "Nothing to release");
        uint256 totalReceived = address(this).balance + _totalReleased;

        for (uint256 i = 0; i < _team.length; i++) {
            address account = _team[i];
            uint256 payment = (totalReceived * _shares[account]) / _totalShares - _released[account];
            _released[account] += payment;
            _totalReleased += payment;
            Address.sendValue(payable(account), payment);
        }
        // (bool success, ) = owner().call{ value: address(this).balance }('');
        // require(success, 'withdraw failed');
    }
    
    function _addTeam(address account, uint256 shares_) private {
        require(account != address(0), "Account is the zero address");
        require(shares_ > 0, "Shares are 0");
        require(_shares[account] == 0, "Account already has shares");

        _team.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
    }

    receive() external payable {}

}