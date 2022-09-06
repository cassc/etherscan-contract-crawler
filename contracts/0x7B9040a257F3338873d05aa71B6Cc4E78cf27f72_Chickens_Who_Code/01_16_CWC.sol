//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Chickens_Who_Code is Ownable, ERC721Enumerable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public _baseURIextended = "https://chickenswhocode-api.herokuapp.com/chicken/";

    //ERC721 params
    string private tokenName = 'Chickens Who Code';
    string private tokenId = 'CWC';

    //Premint List 
    mapping(address => uint8) private _premintList;

    //Mint status 
    bool public mintStatus = false;
    //Public Mint or AllowList Mint
    bool public publicMint = false;
    string public PROVENANCE;
    uint16 public totalNfts = 1000;
    uint256 public currentToken;
    // Withdraw address
    address public withdraw_address = 0x4a36d0CAFE9a052493725B99AeF80A70C25598cD;

    //function has been tested
    modifier mintModifier(uint256 numberOfTokens) {
        require(mintStatus, "Minting not yet open");
        require(_tokenIds.current() + numberOfTokens <= totalNfts, "Exceeds total supply");
        require(numberOfTokens > 0, "Can't mint 0 amount");
        require(numberOfTokens <= 10, "Exceeded max token purchase");
        _;
    }

    constructor() ERC721(tokenName, tokenId) {}

    //function has been tested
    function addAddressToPremintList(address[] calldata _addresses) external onlyOwner {
        for (uint32 i = 0; i < _addresses.length; i++) {
            require(_premintList[_addresses[i]] != 2, 'Already in premint list');
            _premintList[_addresses[i]] = 2;
        }
    }

    //function has been tested
    function changeMintStatus() external onlyOwner{
        mintStatus = !mintStatus;
    }

    //function has been tested
    function changePublicMintStatus() external onlyOwner {
        publicMint = !publicMint;
    }

    //function has been tested
    function mint(uint256 numberOfTokens) 
    public 
    nonReentrant
    mintModifier(numberOfTokens)
    {
        // publicMint == false means premint (allowlist) minting is happening
        if (publicMint == false) {
            require(numberOfTokens <= _premintList[msg.sender], "Exceeded mint limit");
            for (uint16 i = 0; i < numberOfTokens; i++) {
                _tokenIds.increment();
                currentToken = _tokenIds.current();
                _premintList[msg.sender] -= 1;
                _safeMint(msg.sender, currentToken);
            }
        } else {
            for (uint16 i = 0; i < numberOfTokens; i++) {
                _tokenIds.increment();
                currentToken = _tokenIds.current();
                _safeMint(msg.sender, currentToken);
            }
        }
    }

    //function has been tested
    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    //function has been tested
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    //function has been tested and used to test `addAddressToPremintList`
    function searchWalletAddressPremint(address walletAddress) public view returns (bool) {
        if (_premintList[walletAddress] > 0) {
            return true;
        }
        return false;
    }
}