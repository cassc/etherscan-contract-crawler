// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract UnitedNationsEagles is ERC721A, Ownable {

    using Strings for uint256;

    // Max tokens per transaction
    uint public MAX_PER_TX = 20;
    // Max tokens per wallet 
    uint public MAX_PER_WALLET = 20;
    // Maximum supply
    uint256 public MAX_SUPPLY = 2011;
    // The price
    uint256 public MINT_PRICE = 0.11 ether;
    uint256 public WHITELIST_MINT_PRICE = 0.11 ether;

    string public baseURI;

    // Whether the minting is enabled or not. 
    bool public canPublicMint = false;
    bool public canWhitelistMint = true;
    
    // Number of tokens minted by each address
    mapping(address => uint) public numMinted;
    mapping(address => bool) public whiteList; 

    constructor(string memory _baseUri) ERC721A("UnitedNationsEagles", "UNE") {
        baseURI = _baseUri;
    }

    function airdrop(address[] memory dropTargets, uint8[] memory dropCounts) external onlyOwner {
        require(dropCounts.length == dropTargets.length, "!DC");
        // Make sure total drop count is still less or equal to max supply. 
        uint8 totalDC = 0;
        for(uint8 x = 0; x < dropCounts.length; x++){
            totalDC += dropCounts[x];
        }
        require(totalDC <= MAX_SUPPLY, "DC");
        for(uint l = 0; l < dropTargets.length; l++){
            // Mint the NFT for address. 
            numMinted[dropTargets[l]] += dropCounts[l];
            _safeMint(dropTargets[l], dropCounts[l]);
        }
    }

    function mint(uint8 _quantity) external payable {
        uint256 currentSupply = totalSupply();

        require(tx.origin == msg.sender, "OX!=CX");
        
        if(whiteList[msg.sender]){
            require(canWhitelistMint || canPublicMint, "!WL");
            require(msg.value >= WHITELIST_MINT_PRICE * _quantity, "Invalid value sent. ");
        } else {
            require(canPublicMint, "!Minting");
            require(msg.value >= MINT_PRICE * _quantity, "Invalid value sent. ");
        }

        require(currentSupply + _quantity <= MAX_SUPPLY, "!supply");

        require(_quantity > 0, "!Qty");

        require(_quantity <= MAX_PER_TX, "<!Qty");

        require(numMinted[msg.sender] + _quantity <= MAX_PER_WALLET, "!Wallet");

        numMinted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function ownerMint(address _address, uint256 _quantity) external onlyOwner {
        uint256 currentSupply = totalSupply();

        require(currentSupply + _quantity <= MAX_SUPPLY, ">!Supply");

        require(_quantity <= MAX_PER_TX, "Qty>Tx!");

        _safeMint(_address, _quantity);
    }

    function setMinting(bool _canWhitelistMint, bool _canPublicMint) external onlyOwner {
        canWhitelistMint = _canWhitelistMint;
        canPublicMint = _canPublicMint;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }
    function setMaxPerTx(uint _maxPerTx) external onlyOwner {
        MAX_PER_TX = _maxPerTx;
    }
    function setMaxPerWallet(uint _maxPerWallet) external onlyOwner {
        MAX_PER_WALLET = _maxPerWallet;
    }
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        MAX_SUPPLY = _maxSupply;
    }
    function setPrices(uint256 _price, uint256 _whitelistPrice) external onlyOwner {
        MINT_PRICE = _price;
        WHITELIST_MINT_PRICE = _whitelistPrice;
    }
    function addToWhitelist(address[] memory _whitelist) external onlyOwner {
        for(uint256 i = 0;  i < _whitelist.length; i++){
            whiteList[_whitelist[i]] = true;
        }
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _startTokenId() internal override view virtual returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
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
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }
}