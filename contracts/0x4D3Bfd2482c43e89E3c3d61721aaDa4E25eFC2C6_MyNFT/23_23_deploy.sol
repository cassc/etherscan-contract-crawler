// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract MyNFT is ERC721, ERC721Enumerable, IERC2981,ReentrancyGuard , Ownable, ERC721Burnable{
    uint256 public maxSupply = 10000; 
    uint256 public price = 0.01 ether;
    uint256 public maxQtyPerWalletAddressPreSale = 100;
    uint256 public maxQtyPerWalletAddressPublicSale = 100; //max total for public mint
    uint256 public maxQtyPerTransaction = 100; //max per tx public mint   

    bool public _isActive = false;
    bool public _presaleActive = false;

    mapping(address => bool) public allowList;
    mapping(address => uint8) public _preSaleListCounter;
    mapping(address => uint256) public _publicCounter;   
    mapping(address => uint256) public _ownerCounter;     

    //address public royaltyWallet = 0x6AD71401bcCc644fCdF93eAc9b8b4bb919e92414;

    // merkle root
    bytes32 public preSaleRoot;

    // metadata URI
    string private _baseTokenURI;

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter ;
    

    PaymentSplitter private _splitter;

    

    

    constructor(              
        //string memory _contractURI,
        string memory _name,
        string memory _symbol,
        address[] memory payees,
        uint256[] memory shares
    )
        ERC721(_name, _symbol)        
    {
        //contractURI = _contractURI;
        _splitter = new PaymentSplitter(payees, shares);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }    

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    //set variables
    function setPublicActive(bool isActive) external onlyOwner {
        _isActive = isActive;
    }

    function setPresaleActive(bool isActive) external onlyOwner {
        _presaleActive = isActive;
    }

    function setMaxSupply(uint256 _newmaxSupply) public onlyOwner {
        maxSupply = _newmaxSupply;
    }

    function setNewPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setMaxQtyPerWalletAddressPreSale(uint256 _maxQtyPerWalletAddressPreSale) external onlyOwner {
        maxQtyPerWalletAddressPreSale = _maxQtyPerWalletAddressPreSale;
    }

    function setMaxQtyPerTransaction(uint256 _maxQtyPerTransaction) external onlyOwner {
        maxQtyPerTransaction = _maxQtyPerTransaction;
    }
    
    function setMaxQtyPerWalletAddressPublicSale(uint256 maxMints_) public onlyOwner {
        maxQtyPerWalletAddressPublicSale = maxMints_;
    }

    function setPreSaleRoot(bytes32 _root) external onlyOwner {
        preSaleRoot = _root;
    }        

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }    

    //withdraw to owner wallet
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // Presale
    function mintPreSaleTokens(uint8 quantity, bytes32[] calldata _merkleProof)
        external
        payable
        callerIsUser     
        nonReentrant   
    {
        //uint256 supply = totalSupply();
        require(_presaleActive, "Whitelist mint is not active yet");
        require(_preSaleListCounter[msg.sender] + quantity <= maxQtyPerWalletAddressPreSale, "Exceeded max available to purchase at a time");
        require(quantity > 0, "Must mint more than 0 tokens");
        //require(totalSupply() + quantity <= maxSupply, "No more NFTs left");
        require(quantity <= maxQtyPerTransaction, "Exceeds max per transaction");        
        require(price * quantity >= msg.value, "Incorrect funds");
        // check proof & mint
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, preSaleRoot, leaf) || allowList[msg.sender], "Invalid MerkleProof");

         for (uint256 i = 1; i <= quantity; i++) {
            _mint(_msgSender());
        }

        payable(_splitter).transfer(msg.value);        
        _preSaleListCounter[msg.sender] = _preSaleListCounter[msg.sender] + quantity;
        
    }        

    // public mint
    function publicSaleMint(uint256 quantity)
        external
        payable        
        callerIsUser
        nonReentrant
    {
        //uint256 supply = totalSupply();
        //uint256 tokenId = _tokenIdCounter.current();

        require(quantity > 0, "Must mint more than 0 tokens at a time");
        require(_isActive, "Public mint has not begun yet");
        require(price * quantity >= msg.value, "Incorrect funds");
        require(quantity <= maxQtyPerTransaction, "Exceeds max per transaction");
        require(_publicCounter[msg.sender] + quantity <= maxQtyPerWalletAddressPublicSale, "Exceeds max per address");
        //require(totalSupply() + quantity <= maxSupply, "No more NFTs left");



        for (uint256 i = 1; i <= quantity; i++) {
            //supply + i;
            _mint(_msgSender());
        }

        payable(_splitter).transfer(msg.value);        
        _publicCounter[msg.sender] = _publicCounter[msg.sender] + quantity;       
       
    }
     

    // owner mint
    function ownerMint(uint256 quantity) external payable callerIsUser onlyOwner 
    {        
        //uint256 supply = totalSupply();
        //require(totalSupply() + quantity <= maxSupply, "No more NFTs left");

        for (uint256 i = 1; i <= quantity; i++) {
          _mint(_msgSender());
        }
        
        _ownerCounter[msg.sender] = _ownerCounter[msg.sender] + quantity;
    }

    function _mint(address to) internal returns (uint256) {
        if (maxSupply > 0) require(_tokenIdCounter.current() < maxSupply, "No more NFTs left");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        return tokenId;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable,ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");

        return (address(this), SafeMath.div(SafeMath.mul(salePrice, 3), 100));
    }    

    function release(address payable account) public virtual nonReentrant onlyOwner {
        _splitter.release(account);
    }
}


/*
["0x5D5e43516840c94622D7A894f94Eb634bEe51AD0","0x9e7761249995c34feB31FF4dACFDaAF1e756BC1e","0xA47A2cA3c27b11ace79f3BB62416EFbac63c798C"]
[20,40,40]
*/