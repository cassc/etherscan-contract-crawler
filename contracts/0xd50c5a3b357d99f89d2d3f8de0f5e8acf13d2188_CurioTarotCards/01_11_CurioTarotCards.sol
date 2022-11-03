// SPDX-License-Identifier: MIT

// 1010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
// 1010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
// 10101010101010101010101010101010101010                           10101010101010101010101010101010101
// 1010101010101010101010101010101010101.    01010101010101010       1010101010101010101010101010101010
// 101010101010101010101010101010101 '    .0101010101010101010        .10101010101010101010101010101010
// 10101010101010101010101010101010     ,01010101010101010101010      101010101010101010101010101010101
// 101010101010101010101010101010,     '01010101010101010101010101     10101010101010101010101010101010
// 10101010101010101010101010101      ;0101010101010101010101010101   101010101010101010101010101010101
// 1010101010101010101010101010      ,010101010101010101010101010101  101010101010101010101010101010101
// 101010101010101010101010101       .101010101010101010101011010101010101010 1010101010101010101010101
// 10101010101010101010101010        101010101010101010101010101010101010101   101010101010101010101010
// 10101010101010101010101010      101010101010101010101010101010101010101      01010101010101010101010
// 1010101010101010101010101       10101010101010101010101010101010101010        1010101010101010101010
// 1010101010101010101010101       101010101010101010101010101010101010101      10010101010101010101010
// 1010101010101010101010101       1010101010101010101010101010101010101010    101010101010101010101010
// 1010101010101010101010101       :1010101010101010101010101010101010101010  0101010101010101010101010
// 1010101010101010101010101       '1010101010101010101010101010101010101010101010101010010101010101010
// 0101010101010101010101010        .101010101010101010101010101001010101010101010101010101001010101010
// 1010101010101010101010101        ;010101010101010101010101010010101010101010101010101010010101010101
// 10101010101010101010101010         10101001010101010101010101010101110010101010101010101010101010101
// 10101010101010101010101010,        .0101010101010101010101010101010   101010010101010101010101010101
// 101010101010101010101010101,        .01010101010101010101010101010   0101010101010101010101010101010
// 1010101010101010101010101010.        ,010101010101010101010101010    0101010101101010101010101010101
// 10101010101010101010101010101,         ,01010101010101010101010     01010101011010101010101010101010
// 101010101010101010101010101010;.        .,01010101010101010101      01010101011010101010101010101010
// 10101010101010101010101010101010,.                                 101010101011010101010101010101010
// 01010101010101011010101010101010101,.,.,                         10101010101010110101010101010101010
// 1010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
// 1010101010101010101010101010101010101011010101010101010101010101010101010101011010101010101010101010
// 1010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
// 1010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
// P O W E R E D  B Y  E X H A L E  S T U D I O S  //  P O W E R E D  B Y  E X H A L E  S T U D I O S//

pragma solidity ^0.8.16;

import "./IERC721ABurnable.sol";
import "./ERC721AQueryable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract CurioTarotCards is ERC721AQueryable, IERC721ABurnable, Ownable, Pausable, ReentrancyGuard {

    event PermanentURI(string _value, uint256 indexed _id);
    event Mint(address account, uint8 id);
    string private _baseTokenURI;
    bool public _baseURILocked;

    address private _authorizedContract;
    address private _admin;

    uint256 public _maxMintPerPublicWallet = 78;
    uint256 public _maxMintPerWhiteListWallet = 5;
    uint256 public _maxSupply = 78;
    uint256 public PRICE = 0.33 ether;
    uint256 public SPICYPRICE = 0.25 ether;
    bool private _maxSupplyLocked;

    // merkle root
    bytes32 public curioMintRoot;

    bool public _curioPublicMintActive = false;
    bool public _curioWhiteListMintActive = false;

    //mappings for counters
    mapping(address => uint8) public _curioMintCounter;   



    constructor(
        string memory baseTokenURI,
        address admin)
    ERC721A("CurioTarot", "CurioTarot") {
        _admin = admin;
        _baseTokenURI = baseTokenURI;
        _safeMint(msg.sender, 1);
        _pause();
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller is another contract");
        _;
    }

    
    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner() || msg.sender == _admin, "Not owner or admin");
        _;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwnerOrAdmin {
        require(!_baseURILocked, "Base URI is locked");
        _baseTokenURI = newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setCurioMintRoot(bytes32 _root) external onlyOwner {
        curioMintRoot = _root;
    }  

    function setCurioPublicMintActive(bool isActive) external onlyOwner {
        _curioPublicMintActive = isActive;
    }  

    function setCurioWhitelistMintActive(bool isActive) external onlyOwner {
        _curioWhiteListMintActive = isActive;
    }  
    
    function setNewPrice(uint256 _newPrice) public onlyOwner {
        PRICE = _newPrice;
    }

    function setNewSpicyPrice(uint256 _newPrice) public onlyOwner {
        SPICYPRICE = _newPrice;
    }
    
    function mint(address toAddress,uint256 quantity)
        external
        payable
        nonReentrant
        whenNotPaused
        returns (uint8 id)
    {
        uint256 price = PRICE * quantity;
        require(_curioPublicMintActive, "Public mint is not yet active");
        require(msg.value >= price, "Not enough ETH");
        require(_numberMinted(msg.sender) + quantity <= _maxMintPerPublicWallet, "Quantity exceeds wallet limit");
        require(totalSupply() + quantity <= _maxSupply, "Quantity exceeds supply");

        _safeMint(toAddress, quantity);
        emit Mint(toAddress, id);

               // refund excess ETH
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    // Presale
    function allowListMint(uint8 quantity, bytes32[] calldata _merkleProof)
        external
        payable
        callerIsUser     
        nonReentrant   
    {       
        uint256 price = SPICYPRICE * quantity;
        require(_curioWhiteListMintActive, "Whitelist mint is not yet active");
        require(_numberMinted(msg.sender) + quantity <= _maxMintPerWhiteListWallet, "Quantity exceeds wallet limit");
        require(quantity > 0, "Must mint more than 0 tokens");
        require(totalSupply() + quantity <= _maxSupply, "Quantity exceeds supply");                
        require(msg.value >= price, "Not enough ETH");
        // check proof & mint
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, curioMintRoot, leaf), "Invalid MerkleProof"); 

        _safeMint(msg.sender, quantity);

         if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
               
        _curioMintCounter[msg.sender] = _curioMintCounter[msg.sender] + quantity;        
    }    
 

    function ownerMint(address to, uint256 quantity) external onlyOwnerOrAdmin {
        require(totalSupply() + quantity <= _maxSupply, "Quantity exceeds supply");
        _safeMint(to, quantity);
    }

    // Pauses the mint process
    function pause() external onlyOwnerOrAdmin {
        _pause();
    }

    // Unpauses the mint process
    function unpause() external onlyOwnerOrAdmin {
        _unpause();
    }

    function setMaxMintPerPublicWallet(uint256 quantity) external onlyOwnerOrAdmin {
        _maxMintPerPublicWallet = quantity;
    }

    function setMaxMintPerWhiteListWallet(uint256 quantity) external onlyOwnerOrAdmin {
        _maxMintPerWhiteListWallet = quantity;
    }

    function setMaxSupply(uint256 supply) external onlyOwnerOrAdmin {
        require(!_maxSupplyLocked, "Max supply is locked");
        _maxSupply = supply;
    }

    // Locks maximum supply forever
    function lockMaxSupply() external onlyOwnerOrAdmin {
        _maxSupplyLocked = true;
    }

    // Locks base token URI forever and emits PermanentURI for marketplaces (e.g. OpenSea)
    function lockBaseURI() external onlyOwnerOrAdmin {
        _baseURILocked = true;
        for (uint256 i = 0; i < totalSupply(); i++) {
            emit PermanentURI(tokenURI(i), i);
        }
    }

    // Only the owner of the token and its approved operators, and the authorized contract
    // can call this function.
    function burn(uint256 tokenId) public virtual override {
        // Avoid unnecessary approvals for the authorized contract
        bool approvalCheck = msg.sender != _authorizedContract;
        _burn(tokenId, approvalCheck);
    }

    function setAdmin(address admin) external onlyOwner {
        _admin = admin;
    }
    
    function setAuthorizedContract(address authorizedContract) external onlyOwnerOrAdmin {
        _authorizedContract = authorizedContract;
    }

    function withdrawMoney(address to) external onlyOwnerOrAdmin {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // OpenSea metadata initialization
    function contractURI() public pure returns (string memory) {
        return "https://exhale.mypinata.cloud/ipfs/Qmduw1eZnKjoybGtLzfzYHxfKCGE28fP2xYaRQF387xJJ1";
    }
}