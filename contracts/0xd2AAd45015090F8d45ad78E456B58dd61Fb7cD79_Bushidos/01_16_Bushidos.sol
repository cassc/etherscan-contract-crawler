// SPDX-License-Identifier: MIT
//
// Bushidos Main Sales Contract
// Twitter: https://twitter.com/bushidosnft
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./SashimonoInterface.sol";


contract Bushidos is ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint public constant MAX_BUSHIDOS = 8888;
    uint public constant BUSHIDO_PRICE = 88000000000000000;

    uint public constant MAX_BUSHIDOS_PER_TXN = 8;

    bool public mintIsActive = false;
    bool public whitelistIsActive = false;
    bool public sashimonoIsActive = false;
    string public baseTokenURI;


    //Whitelist Minting Constants
    mapping(address => bool) public whiteList;

    //Sashimono Minting Constants
    mapping (uint256 => uint256) private _sashimonoUsed;

    address public SASHIMONO_ADDRESS = 0x8E81d22d0Dc7ef48A81aB25b773D449f08059C33;
    SashimonoInterface sashimonoContract = SashimonoInterface(SASHIMONO_ADDRESS);

    constructor(string memory baseURI) ERC721("Bushidos", "BUSHIDO") {
        setBaseURI(baseURI);
    }

    //Sashimono mininting logic
    // Mint single sashimono
    function mintWithSingleSashimono(uint sashimonoId, uint numberOfBushidos) public payable {
        require(sashimonoIsActive, "Must be active to mint Bushidos");
        require(numberOfBushidos > 0 && numberOfBushidos <= 2, "Can only mint between 0 and 2 bushidos per sashimono");
        require(totalSupply().add(numberOfBushidos) <= MAX_BUSHIDOS, "Mint would exceed max supply of Bushidos");
        require(BUSHIDO_PRICE.mul(numberOfBushidos) <= msg.value, "Ether value sent is not correct");
        require(canMintWithSashimono(sashimonoId) && sashimonoContract.ownerOf(sashimonoId) == msg.sender, "Bad owner!");

        _sashimonoUsed[sashimonoId] = 1;
        for(uint i = 0; i < numberOfBushidos; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    // Mint multiple sashimono
    function mintMultipleSashimono(uint256[] memory sashimonoIds) public payable {

        uint numberOfBushidos = (sashimonoIds.length).mul(2);
        require(sashimonoIsActive, "Must be active to mint Bushidos");
        require(totalSupply().add(numberOfBushidos) <= MAX_BUSHIDOS, "Mint would exceed max supply of Bushidos");
        require(BUSHIDO_PRICE.mul(numberOfBushidos) <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < sashimonoIds.length; i++) {
            uint256 sashimonoId = sashimonoIds[i];
            require(canMintWithSashimono(sashimonoId) && sashimonoContract.ownerOf(sashimonoId) == msg.sender, "Bad owner!");
            _sashimonoUsed[sashimonoId] = 1;
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
            _safeMint(msg.sender, mintIndex+1);
        }
    }

    function canMintWithSashimono(uint256 sashimonoId) public view returns(bool) {
        return _sashimonoUsed[sashimonoId] == 0;
    }

    //Whitelist Logic
    function mintFromWhitelist() public payable {
        require(whitelistIsActive, "Must be active to mint Bushidos");
        require(totalSupply().add(1) <= MAX_BUSHIDOS, "Mint would exceed max supply of Bushidos");
        require(BUSHIDO_PRICE.mul(1) <= msg.value, "Ether value sent is not correct");
        require(isWhiteList(msg.sender), "Not on whitelist or whitelist used");

        whiteList[msg.sender] = false;
        uint256 mintIndex = totalSupply();
        _safeMint(msg.sender, mintIndex);
    }

    function isWhiteList(address addr) public view returns (bool) {
        return whiteList[addr];
    }

    function addToWhiteList(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            require(!whiteList[entry], "DUPLICATE_ENTRY");

            whiteList[entry] = true;
        }   
    }

    //Function for the main sale. Can mint 8 at most in one txn 
    //Can mint when sale is active and totalSupply < 8888
    function mintBushidos(uint numberOfBushidos) public payable {
        require(mintIsActive, "Must be active to mint Bushidos");
        require(numberOfBushidos > 0 && numberOfBushidos <= MAX_BUSHIDOS_PER_TXN, "Can only mint between 0 and 8 bushidos at a time");
        require(totalSupply().add(numberOfBushidos) <= MAX_BUSHIDOS, "Mint would exceed max supply of Bushidos");
        require(BUSHIDO_PRICE.mul(numberOfBushidos) <= msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < numberOfBushidos; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }
    //Only owner actions
    //Reserve for team and partnerships
    function reserveBushidos(address addr, uint numberOfBushidos) public onlyOwner {
        require(totalSupply().add(numberOfBushidos) <= MAX_BUSHIDOS, "Mint would exceed max supply of Bushidos");
        require(!mintIsActive, 'Too late to reserve');
        for (uint i = 0; i < numberOfBushidos; i++) {
            uint mintIndex = totalSupply();
            _safeMint(addr, mintIndex);
        }
    }

    function reserveMultipleBushidos(address[] calldata entries) public onlyOwner {
        require(totalSupply().add(entries.length) <= MAX_BUSHIDOS, "Mint would exceed max supply of Bushidos");
        require(!mintIsActive, 'Too late to reserve');
        for (uint i = 0; i < entries.length; i++) {
            address addr = entries[i];
            uint mintIndex = totalSupply();
            _safeMint(addr, mintIndex);
        }
    }

    //Turn sale active
    function flipMintState() public onlyOwner {
        mintIsActive = !mintIsActive;
    }

    //Turn sale active
    function flipwhitelistState() public onlyOwner {
        whitelistIsActive = !whitelistIsActive;
    }

    //Turn sale active
    function flipSashimonoState() public onlyOwner {
        sashimonoIsActive = !sashimonoIsActive;
    }

    // internal function override
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // set baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    //Witdraw funds
    function withdrawAll() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

}