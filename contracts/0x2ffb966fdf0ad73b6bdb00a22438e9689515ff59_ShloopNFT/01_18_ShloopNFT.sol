// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";



contract ShloopNFT is ERC721A, ERC721ABurnable, Ownable {
    
    uint256 public MAX_SUPPLY = 4444;

    uint256 public PRICE = 0.0044 ether;

    uint256 public MAX_TX = 10;

    uint public MAX_WALLET = 10;

    bool public whitelistSaleActive = false;

    bool public publicSaleActive = false;

    bool public burnActive = false;

    bool public teamClaimed = false;

    bytes32 merkleRoot;

    string public baseURI;


  //Data structure to track mints per wallet
    mapping(address => uint256 ) private mintedPerWallet;

    constructor(string memory name_, string memory symbol_) ERC721A(name_, symbol_) {}

    function mint(uint256 quantity)
        public
        payable
        publicSaleOpen
        validatePublicSale(quantity) 
    {
        _safeMint(msg.sender, quantity);
    }

    function whitelistMint(uint256 quantity, bytes32[] calldata proof)
        public
        payable
        allowlistSaleOpen
        validateAllowlistSale(quantity)
        isValidProof(proof)
    {
        _safeMint(msg.sender, quantity);
        mintedPerWallet[msg.sender] += quantity; 
    }

    function teamMint()
        public
        onlyOwner
    {
        _safeMint(msg.sender, 1);
    }


    function burnTokens(uint256[] calldata tokenIds) 
        public 
        tokenBurnActive 
    {
        for(uint256 i = 0; i < tokenIds.length; i++) {
            burn(tokenIds[i]);
        }
    }



    function checkProof(bytes32[] memory _proof) internal view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_proof, merkleRoot, leaf);
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function togglePublic() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function toggleWhitelist() external onlyOwner {
        whitelistSaleActive = !whitelistSaleActive;
    }

    function toggleBurn() external onlyOwner {
        burnActive = !burnActive;
    }

    function setMaxTx(uint256 _maxTx) public onlyOwner {
        MAX_TX = _maxTx;
    }

    function setPrice(uint256 _price) public onlyOwner {
        PRICE = _price;
    }

    function setBaseURI(string memory _URI) public onlyOwner {
        baseURI = _URI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
}

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    modifier publicSaleOpen() {
        require(publicSaleActive, "Shloop! Public sale is closed.");
        _;
    }

    modifier allowlistSaleOpen() {
        require(whitelistSaleActive, "Shloop! Private sale is closed.");
        _;
    }

    modifier tokenBurnActive() {
        require(burnActive, "Shloop! Token burning is not yet active.");
        _;
    }

    modifier validatePublicSale(uint256 quantity) {
        require(quantity <= MAX_TX, "Shloop! Too many tokens per mint.");
        require(PRICE * quantity == msg.value, "Shloop! Incorrect transaction value.");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Shloop! Transaction exceeds max supply.");
        _;
    }

    modifier validateAllowlistSale(uint256 quantity) {
         require(mintedPerWallet[msg.sender] + quantity <= MAX_WALLET, "you can only mint 10 per wallet");
        require(quantity <= MAX_TX, "Shloop! Too many tokens per mint.");
          require(PRICE * quantity == msg.value, "Shloop! Incorrect transaction value.");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Shloop! Transaction exceeds max supply.");
        _;
    }

    modifier isValidProof(bytes32[] memory proof) {
        require(checkProof(proof), "Shloop! Invalid proof.");
        _;
    }
}