// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "../contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 


contract BenNFT is ERC721A, Ownable {


    event Payout(address indexed _to, uint256 _value);

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.17 ether;
    uint256 public whitelistCost = 0.17 ether;
    uint256 public maxSupply = 5555;
    uint256 public maxMintAmount = 100;
    bool public paused = false;
    mapping(address => bool) public whitelisted;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory _initBaseURI
    ) ERC721A(name_, symbol_) {

        setBaseURI(_initBaseURI);
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPause(bool _pauseBool) public onlyOwner {
        paused = _pauseBool;
    }

    function whitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = true;
    }

    function add699Whitelists(address[698] memory _users) public onlyOwner {
        for (uint256 i = 0; i < 698; i++) {
            whitelisted[_users[i]] = true;
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(tokenId),
                        baseExtension
                    )
                )
                : "";
    }


    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    function nextTokenId() public view returns (uint256) {
        return _nextTokenId();
    }

    function getAux(address owner) public view returns (uint64) {
        return _getAux(owner);
    }

    function setAux(address owner, uint64 aux) public {
        _setAux(owner, aux);
    }

    function getBaseURI() public view returns (string memory) {
        return _baseURI();
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function safeMint(address to, uint256 quantity) public payable {
        uint256 supply = totalSupply();
        require(quantity > 0);
        require(quantity <= maxMintAmount, "mint too large, less than 101 please!");
        require(supply + quantity <= maxSupply);
        require(paused == false);
        //if not owner
        if (msg.sender != owner()) {
                require(msg.value >= cost * quantity);
            }   

        _safeMint(to, quantity);
    }

    function safeMintPresale(address to, uint256 quantity) public payable {
        uint256 supply = totalSupply();
        require(quantity > 0);
        require(quantity <= maxMintAmount);
        require(supply + quantity <= maxSupply);
        require(paused == false);
        //if not owner
        if (msg.sender != owner()) {
            if (whitelisted[msg.sender] != true) {
                //general public
                require(msg.sender == owner(), "not owner or whitelisted, wait for general sale");
            }   else {
                //presale
                require(msg.value >= whitelistCost * quantity);
                }  
        }

        _safeMint(to, quantity);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    function burn(uint256 tokenId, bool approvalCheck) public {
        _burn(tokenId, approvalCheck);
    }

    function toString(uint256 x) public pure returns (string memory) {
        return _toString(x);
    }

    function getOwnershipAt(uint256 index) public view returns (TokenOwnership memory) {
        return _ownershipAt(index);
    }

    function getOwnershipOf(uint256 index) public view returns (TokenOwnership memory) {
        return _ownershipOf(index);
    }

    function initializeOwnershipAt(uint256 index) public {
        _initializeOwnershipAt(index);
    }


    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }


}