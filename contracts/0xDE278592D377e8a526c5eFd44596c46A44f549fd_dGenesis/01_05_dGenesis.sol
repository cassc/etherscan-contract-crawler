// SPDX-License-Identifier: MIT

//Made by dGENS for dGENS: Contract by @Wagglefoot & @ITZMIZZLE

pragma solidity ^0.8.16;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract dGenesis is ERC721A, Ownable {
   
    string private baseURI;    
    uint256 constant public maxTokens = 1250;
    uint256 public _reserved = 250;
    uint256 public price = 0.2 ether;
    uint256 public maxPerWallet = 10;
    bool public publicSaleLive = false;
    bool public allowlistLive = false;
    
    mapping(address => uint256) public _allowList;

    constructor() ERC721A("dGenesis Token", "dGEN") {}

    modifier mintCompliance(uint256 _numberOfTokens) {
        uint256 supply = totalSupply();
        require(supply + _numberOfTokens <= maxTokens - _reserved, "Max supply exceeded!");
        require(msg.value >= price * _numberOfTokens, "Deploy more Capital!");
        require(_numberMinted(msg.sender) + _numberOfTokens <= maxPerWallet, "Wallet mints exceeded");
        require(tx.origin == msg.sender, "No contract mint");

        _;
    }

    function mint(uint256 _numberOfTokens) external payable mintCompliance (_numberOfTokens){
        if (allowlistLive) {
            require(_allowList[msg.sender] >= _numberOfTokens, "Slowdown dGEN!");
            _allowList[msg.sender] -= _numberOfTokens;
        } else {
          require(publicSaleLive, "Steady Lads");
        }
        _mint(msg.sender, _numberOfTokens);  
    }

    function founderClaim(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= _reserved, "Not enough reserved tokens left to compelete" );
        _mint(_to, _amount);
        _reserved -= _amount;
    }

    function maxSupply() external view returns(uint256) {
        return totalSupply();
    }

    function setPublicActive(bool _isSaleLive) external onlyOwner {
        publicSaleLive = _isSaleLive;
    }

    function setAllowlistActive(bool _allowlistLive) external onlyOwner {
        allowlistLive = _allowlistLive;
    }

    function setAllowList(address[] calldata _addresses, uint256 _numberOfTokens) external onlyOwner {
        for (uint256 i; i < _addresses.length;) {
            _allowList[_addresses[i]] = _numberOfTokens;
            unchecked { ++i; }
        }
    }

    function setMintPrice(uint256 _howMuch) external onlyOwner {
        price = _howMuch;
    }

    function setWalletLimit(uint256 _howMany) external onlyOwner {
        maxPerWallet = _howMany;
    }

    function setMetadata(string memory _metadata) external onlyOwner {
        baseURI = _metadata;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}