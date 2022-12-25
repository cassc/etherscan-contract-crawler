/*

Welcome to the Milady Christmas Special!
            
*/


pragma solidity ^0.8.14;
import "https://github.com/ProjectOpenSea/operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

contract MILADYCHRISTMAS is ERC721A, DefaultOperatorFilterer, Ownable {           
    using BitMaps for BitMaps.BitMap;

    address public constant MILADY_MAKER = 0x5Af0D9827E0c53E4799BB226655A1de152A425a5;
    address public constant MILADY_CHRISTMAS = 0x57282f0053c25e47710E511bA7Bfa0739444B543;
        
    uint256 public maxSupply = 200;    
    uint256 public maxOwnerMintAmount = 2;    
    uint16 public totalMilady = 0;
    uint16 public totalMiladyChristmas = 0;

    mapping(address => uint8) private _Milady;
    mapping(address => uint8) private _MiladyChristmas;    
    
    string public baseURI = "";    
    


    constructor(
        string memory _name,
        string memory _symbol) ERC721A(_name, _symbol) {               
        }

    modifier miladyMilady() {
        require(
            (ERC721(MILADY_MAKER).balanceOf(msg.sender) >= 1),                      
            "You need at least one Milady"
        );
        _;
    }
    modifier miladyMiladyChristmas() {
        require(
            (ERC721(MILADY_CHRISTMAS).balanceOf(msg.sender) >= 1),            
            "You need at least one Milady Christmas"
        );
        _;
    }

    function miladyMint()
    external 
    payable
    miladyMilady    
    {   
        require(_Milady[msg.sender] <1);      
        require(totalMilady < 99);
        totalMilady = totalMilady + 1;
        _Milady[msg.sender] = 1;
        _safeMint(msg.sender, 1);
    }
    
    function miladyChristmasMint()
    external 
    payable
    miladyMiladyChristmas    
    {   
        require(_MiladyChristmas[msg.sender] <1);      
        require(totalMiladyChristmas < 99);
        totalMiladyChristmas = totalMiladyChristmas + 1;
        _MiladyChristmas[msg.sender] = 1;
        _safeMint(msg.sender, 1);
    }

    function ownerMint(uint16 _mintAmount) external payable onlyOwner {                
        require(_mintAmount + _numberMinted(msg.sender) <= maxOwnerMintAmount, "Greedy");
        require(totalSupply() + _mintAmount <= maxSupply, "Rip");        
        _safeMint(msg.sender, _mintAmount);
    }

    function toBytes32(address addr) pure internal returns (bytes32){
        return bytes32(uint256(uint160(addr)));
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }    

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

     function _startTokenId() internal view override returns (uint256) {
        return 1;
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable 
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function totalMiladySupply() public view virtual returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return totalMilady;
        }
    }

    function totalMiladyChristmasSupply() public view virtual returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return totalMiladyChristmas;
        }
    }
}