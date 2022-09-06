// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract ToSomewhere is ERC721Enumerable, Ownable, ReentrancyGuard {
    event Mint(address indexed account, uint256 indexed tokenid);

    uint256 constant public MAX_TOKEN = 1000;
    uint256 constant public MAX_TOKENS_PER_ACCOUNT_FOR_FREE = 2;
    mapping(address => uint256) public freeMintNum;

    uint256 constant public MAX_TEAM_KEEP = 50;
    uint256 public teamKeep = MAX_TEAM_KEEP;
    bool public freeMintStarting;
    string private _internalbaseURI;
    uint256 private _lastTokenId;

    constructor(string memory baseURI_, string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        _internalbaseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _internalbaseURI;
    }

    function freeMint(uint256 num) external callerIsUser mintStarting nonReentrant {
        require(totalSupply() + num + teamKeep <= MAX_TOKEN, "over free supply");
        require(freeMintNum[msg.sender] + num <= MAX_TOKENS_PER_ACCOUNT_FOR_FREE, "over per account amount");
        freeMintNum[msg.sender] += num;
        _batchMint(msg.sender, num);
    }

    function batchClaim(address[] calldata _accounts, uint256[] calldata _quantity) external onlyOwner nonReentrant {
        uint256 total = 0;
        for (uint i = 0; i < _quantity.length; i++) {
            total += _quantity[i];
        }
        require(totalSupply() + total + teamKeep <= MAX_TOKEN, "over free supply");

        for (uint i = 0; i < _accounts.length; i++) {
            _batchMint(_accounts[i], _quantity[i]);
        }
    }

    function teamMint(uint256 num) external onlyOwner {
        require(num <= teamKeep, "over team amount");
        _batchMint(msg.sender, num);
        teamKeep-= num;
    }

    function _batchMint(address to, uint256 num) internal {
        for (uint i = 0; i < num; i++) {
            uint256 tokenid = _lastTokenId;
            super._safeMint(to, tokenid);
            emit Mint(to, tokenid);
            unchecked {
                _lastTokenId++;
            }
        }
    }

    function claim() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setBaseURI(string memory uri) external onlyOwner {
        _internalbaseURI = uri;
    }

    function mintStart() external onlyOwner {
        freeMintStarting = true;
    }

    modifier mintStarting() {
        require(freeMintStarting, "sale not starting");
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function arrayTokenIds(address account, uint256 _from, uint256 _to) public view returns(uint256[] memory) {
        require(_to < balanceOf(account), "Wrong max array value");
        require((_to - _from) <= balanceOf(account), "Wrong array range");
        uint256[] memory ids = new uint256[](_to - _from + 1);
        uint index = 0;
        for (uint i = _from; i <= _to; i++) {
            uint id = tokenOfOwnerByIndex(account, i);
            ids[index] = id;
            index++;
        }
        return (ids);
    }
}