// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract LOREMNFT is ERC721AQueryable, ReentrancyGuard, ERC2981, Ownable {
    using ECDSA for bytes32;

    uint public tokenPrice; 
    uint public maxcollectionSize = 10000;
    uint8 public maxPerAddress = 1;
    uint public quantityForMint = 9900;
    uint8 public salesStage = 0;


    mapping(address => uint) public alMinted;
    mapping(address => uint) public publicMinted;
    mapping(uint => mapping(address => uint)) public authorizedMinteds;
  
    string public _baseTokenURI;
    address public _adminSigner;

    constructor() ERC721A("LOREMNFT", "LOREM") {}
         
    // allow list signature
    function alMint(uint quantity, uint allowquantity, bytes calldata signature ) public payable callerIsUser {
        require(salesStage == 1, "Mint not active");
        require(isAllowListAuthorized(msg.sender,  allowquantity, signature), "Auth failed");
        require(totalSupply() + quantity <= quantityForMint, "Minted Out");
        require(alMinted[msg.sender] + quantity <= allowquantity, "Wallet Max Reached");
        require(tokenPrice * quantity <= msg.value, "Insufficient Eth");

        _minttokens(msg.sender, quantity);
        alMinted[msg.sender] += quantity;
    }

    // public mint with signature
    function authorizedMint(uint quantity, uint allowquantity, bytes calldata signature ) public payable callerIsUser{
        require(salesStage > 1 && salesStage < 9, "Mint not active");
        require(isAllowListAuthorized(msg.sender,  allowquantity, signature), "Auth failed");
        require(totalSupply() + quantity <= quantityForMint, "Minted Out");
        require(authorizedMinteds[salesStage][msg.sender] + quantity <= maxPerAddress, "Wallet Max Reached");
        require(tokenPrice * quantity <= msg.value, "Insufficient Eth");

        _minttokens(msg.sender, quantity);
        authorizedMinteds[salesStage][msg.sender] += quantity;
    }

    // public mint without signature
    function publicMint(uint quantity) public payable callerIsUser{
        require(salesStage == 9, "Mint not active");
        require(publicMinted[msg.sender] + quantity <= maxPerAddress, "Wallet Max Reached");
        require(totalSupply() + quantity <= quantityForMint, "Minted Out");
        require(tokenPrice * quantity <= msg.value, "Insufficient Eth");
        
        _minttokens(msg.sender, quantity);
        publicMinted[msg.sender] += quantity;
        
    }
    
    function isAllowListAuthorized(
        address sender, 
        uint allowAmount,
        bytes calldata signature
    ) private view returns (bool) {
        bytes32 messageDigest = keccak256(abi.encodePacked(allowAmount, sender));
        bytes32 ethHashMessage = ECDSA.toEthSignedMessageHash(messageDigest);
        return ECDSA.recover(ethHashMessage, signature) == _adminSigner;

    }
     
    function _minttokens(address _to, uint _quantity ) internal {
          _safeMint(_to, _quantity);
    }


    // override ERC721A
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    //only owner
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function teamMint(address[] calldata to_, uint256 quantity_ ) public onlyOwner {        
      require( totalSupply() + to_.length*quantity_ <= maxcollectionSize, "Minted out");
      for (uint256 i = 0; i < to_.length; i++) {
      _minttokens(to_[i], quantity_);
      }
    }

    function setQuantityForMint(uint256 newquantityForMint) public onlyOwner {
      require( newquantityForMint <= maxcollectionSize, "Exceed");
      quantityForMint = newquantityForMint;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
      tokenPrice = newPrice;
    }

    function setMaxPerAddress(uint8 newmaxPerAddress) public onlyOwner {
      maxPerAddress = newmaxPerAddress;
    }

    function setSigner(address newSigner) external onlyOwner {
       _adminSigner = newSigner;
    }
    
    function setBaseURI(string memory newURI) external onlyOwner {
      _baseTokenURI = newURI;
    }
  
    function setSalesStage(uint8 newSalesStage) public onlyOwner {
        salesStage = newSalesStage;
    }
    
    //@dev Update the royalty percentage (1000 = 10%)
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

   function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981, IERC721A) returns (bool) {
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }


}