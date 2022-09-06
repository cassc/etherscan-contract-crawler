// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ERC721A.sol";

contract SkyClub is ERC721A, IERC2981,ReentrancyGuard,Ownable {
    //set variables
    uint256 public maxSupply; 
    uint256 public price;
    uint256 public maxQtyPerMember;    
    uint256 public maxQtyPerTransaction; 

    bool public _skyMintActive = false;
    
    //mappings for counters
    mapping(address => uint8) public _skyMintCounter;    
    mapping(address => uint256) public _ownerCounter;     

    //wallet for on cahin royalties
    address public royaltyWallet = 0x6952566b3d3b1bb6e76FD0c3EeE14D39eeaE3846;

    // merkle root
    bytes32 public skyMintRoot;

    // metadata URI
    string private _baseTokenURI;

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter ;
    PaymentSplitter private _splitter;       

    constructor(            
        string memory _name,
        string memory _symbol,
        address[] memory payees,
        uint256[] memory shares,
        uint256 _maxSizeBatch,
        uint256 _maxCollection,
        uint256 _maxSupply,
        uint256 _price,
        uint256 _maxQtyPerMember,
        uint256 _maxQtyPerTransaction
    )
        ERC721A(_name, _symbol, _maxSizeBatch, _maxCollection )        
    {         
        maxSupply = _maxSupply;
        price = _price;
        maxQtyPerMember = _maxQtyPerMember;
        maxQtyPerTransaction = _maxQtyPerTransaction;
        _splitter = new PaymentSplitter(payees, shares);
    }
    

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }    

    function setSkyMintActive(bool isActive) external onlyOwner {
        _skyMintActive = isActive;
    }

    function setMaxSupply(uint256 _newmaxSupply) public onlyOwner {
        maxSupply = _newmaxSupply;
    }

    function setNewPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setMaxQtyPerMember(uint256 _maxQtyPerMember) external onlyOwner {
        maxQtyPerMember = _maxQtyPerMember;
    }

    function setMaxQtyPerTransaction(uint256 _maxQtyPerTransaction) external onlyOwner {
        maxQtyPerTransaction = _maxQtyPerTransaction;
    } 

    function setSkyMintRoot(bytes32 _root) external onlyOwner {
        skyMintRoot = _root;
    }        

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }   

    // Presale
    function skyclubMint(uint8 quantity, bytes32[] calldata _merkleProof)
        external
        payable
        callerIsUser     
        nonReentrant   
    {       
        require(_skyMintActive, "Whitelist mint is not yet active");
        require(_skyMintCounter[msg.sender] + quantity <= maxQtyPerMember, "Exceeds Max Per Wallet Address");
        require(quantity > 0, "Must mint more than 0 tokens");
        require(totalSupply() + quantity <= maxSupply, "Sold out");
        require(quantity <= maxQtyPerTransaction, "Exceeds max per transaction");        
        require(price * quantity >= msg.value, "Incorrect funds");
        // check proof & mint
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, skyMintRoot, leaf), "Invalid MerkleProof"); 

        _safeMint(msg.sender, quantity);
        
        payable(_splitter).transfer(msg.value);        
        _skyMintCounter[msg.sender] = _skyMintCounter[msg.sender] + quantity;        
    }     

    // owner mint
    function ownerMint(uint256 quantity) external payable callerIsUser onlyOwner 
    {       
        require(totalSupply() + quantity <= maxSupply, "Sold out");
        _safeMint(msg.sender, quantity);               
        _ownerCounter[msg.sender] = _ownerCounter[msg.sender] + quantity;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
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

        return (address(royaltyWallet), SafeMath.div(SafeMath.mul(salePrice, 10), 100));
    }    

    function release(address payable account) public virtual nonReentrant onlyOwner {
        _splitter.release(account);
    }
    
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(royaltyWallet).transfer(balance);
    }
}