// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OOFriends is ERC721A, Ownable {
    uint256 MAX_PUBLIC_PER_TX = 3;
    uint256 public MAX_SUPPLY = 2469;
    uint256 public MINT_PRICE = 0.02469 ether;
    
    bool public mintIsActive = false;
    bool public presale = false;
    bool public pubmint = false;

    mapping(address => uint8) private _freeAllowList;
    mapping(address => uint8) private _mintAllowList;

    string public baseURI = "https://oofriends.xyz/assets/metadata/";

    constructor() ERC721A("OOFriends", "OF") {}

    function mint(uint8 quantity) external payable
    {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(mintIsActive, "Mint must be active to mint");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds max supply");
        require(msg.value >= MINT_PRICE * quantity, "Not enough ETH for transaction");
        
        if (presale) 
        {
            require(quantity <= _mintAllowList[msg.sender], "Exceeds max available to mint");
            _mintAllowList[msg.sender] -= quantity; //tracking minted
            _safeMint(msg.sender, quantity);
        }
        else
        {
            require(pubmint, "Public mint not active");
            require(quantity > 0 && quantity <= MAX_PUBLIC_PER_TX, "Max per transaction reached");
            _safeMint(msg.sender, quantity);
        }
        
    }

    function freeMint(uint8 quantity) external payable
    {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(mintIsActive, "Mint must be active to mint");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds max supply");
        require(quantity <= _freeAllowList[msg.sender], "Exceeds max available to mint");

        _freeAllowList[msg.sender] -= quantity; //tracking minted
        _safeMint(msg.sender, quantity);
    }

    function ownerMint(address[] calldata addresses, uint8 quantity) external onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds max supply");
            _safeMint(addresses[i], quantity, "");
        }
    }

    function setFreeAllowList(address[] calldata addresses, uint8[] calldata numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _freeAllowList[addresses[i]] = numAllowedToMint[i];
        }
    }

    function setMintAllowList(address[] calldata addresses, uint8[] calldata numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _mintAllowList[addresses[i]] = numAllowedToMint[i];
        }
    }

    function freeAvailableToMint(address addr) external view returns (uint8) {
        return _freeAllowList[addr];
    }

    function paidAvailableToMint(address addr) external view returns (uint8) {
        return _mintAllowList[addr];
    }

    function setPrice(uint256 price) external onlyOwner 
    {
        MINT_PRICE = price;
    }

    function flipSaleState() external onlyOwner
    {
        mintIsActive = !mintIsActive;
    }

    function flipPresaleState() external onlyOwner
    {
        presale = !presale;
    }

    function flipPublicState() external onlyOwner
    {
        pubmint = !pubmint;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }
    
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

}