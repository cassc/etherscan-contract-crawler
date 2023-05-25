// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721A.sol";

/*

   _     _              _     _   
  (c).-.(c)   LEAVE    (c).-.(c)  
   / ._. \              / ._. \   
 __\( Y )/__   ME     __\( Y )/__ 
(_.-/'-'\-._)        (_.-/'-'\-._)
   ||   ||    ALONE     ||   ||   
 _.' `-' '._          _.' `-' '._ 
(.-./`-'\.-.)        (.-./`-'\.-.)
 `-'     `-'          `-'     `-' 

*/
contract LeaveMeAlone is ERC721A, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    uint256 public constant TOTAL_MAX_SUPPLY = 10000;
    uint256 public constant TOTAL_FREE_MINTS = 1337;
    uint256 public constant MAX_FREE_MINT_PER_WALLET = 1; 
    uint256 public constant MAX_PUBLIC_MINT_PER_WALLET = 5;
    uint256 public constant TOKEN_PRICE = .02 ether;

    address public signatureVerifier;
    bool public publicSaleActive;
    bool public freeMintActive;
    uint256 public freeMintCount;

    mapping(address => uint256) public freeMintClaimed;

    string private _baseTokenURI;

    constructor() ERC721A("Leave Me Alone", "GRRLZ") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier underMaxSupply(uint256 _quantity) {
        require(
            _totalMinted() + _quantity <= TOTAL_MAX_SUPPLY,
            "Purchase would exceed max supply"
        );

        _;
    }

    modifier hasValidSignature(bytes memory _signature, bytes memory message) {
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(keccak256(message));
        require(messageHash.recover(_signature) == signatureVerifier, "Unrecognizable Hash");

        _;
    }

    modifier validateFreeMintStatus() {
        require(freeMintActive, "free claim is not active");
        require(freeMintCount + 1 <= TOTAL_FREE_MINTS, "Purchase would exceed max supply of free mints");
        require(freeMintClaimed[msg.sender] == 0, "wallet has already free minted");
        
        _;
    }

    modifier validatePublicStatus(uint256 _quantity) {
        require(publicSaleActive, "public sale is not active");
        require(msg.value >= TOKEN_PRICE * _quantity, "Need to send more ETH.");
        require(
            _numberMinted(msg.sender) + _quantity - freeMintClaimed[msg.sender] <= MAX_PUBLIC_MINT_PER_WALLET,
            "This purchase would exceed maximum allocation for public mints for this wallet"
        );

        _;
    }

    function freeMint(bytes memory _signature) 
        external 
        callerIsUser 
        validateFreeMintStatus
        hasValidSignature(_signature, abi.encodePacked(msg.sender))
        underMaxSupply(1)
    {
        freeMintClaimed[msg.sender] = 1;
        freeMintCount++;

        _mint(msg.sender, 1, "", false);
    }

    function mint(bytes memory _signature, uint256 _quantity)
        external
        payable
        callerIsUser
        validatePublicStatus(_quantity)
        underMaxSupply(_quantity)
        hasValidSignature(_signature, abi.encodePacked(msg.sender))
    {
        _mint(msg.sender, _quantity, "", false);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '';
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function ownerMint(uint256 _numberToMint)
        external
        onlyOwner
        underMaxSupply(_numberToMint)
    {
        _mint(msg.sender, _numberToMint, "", false);
    }

    function ownerMintToAddress(address _recipient, uint256 _numberToMint)
        external
        onlyOwner
        underMaxSupply(_numberToMint)
    {
        _mint(_recipient, _numberToMint, "", false);
    }

    function setFreeMintCount(uint256 _count) external onlyOwner{
        freeMintCount = _count;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawFundsToAddress(address _address, uint256 amount) external onlyOwner {
        (bool success, ) =_address.call{value: amount}("");
        require(success, "Transfer failed.");
    }
    
    function flipFreeMintActive() external onlyOwner {
        freeMintActive = !freeMintActive;
    }

    function flipPublicSaleActive() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function setSignatureVerifier(address _signatureVerifier)
        external
        onlyOwner
    {
        signatureVerifier = _signatureVerifier;
    }
}