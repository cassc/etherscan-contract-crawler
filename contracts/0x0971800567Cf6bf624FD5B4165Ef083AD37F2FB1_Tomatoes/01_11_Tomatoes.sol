pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Tomatoes is ERC721A, ERC721AQueryable, Ownable, DefaultOperatorFilterer {

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    bool public publicSaleOpen;
    bool public freeSaleOpen;
    string public _baseTokenURI;
    uint256 public constant MAX_FREE_PER_USER = 1;
    uint256 public constant MAX_FREE_SUPPLY = 535;
    
    uint256 public constant MAX_PER_TX = 5;
    uint256 public constant MAX_PER_WALLET = 5;
    uint256 public constant MAX_SUPPLY = 6969;
    uint256 public constant COST_PER_MINT = 0.01 ether;

    mapping(address => uint256) public addressToFreeMints;
    bytes32 public whitelistMerkleRoot;

    constructor() ERC721A("Tomatoez", "TMTS") {
        publicSaleOpen = false;
        freeSaleOpen = false;
    }

    function togglePublicSale() public onlyOwner {
        publicSaleOpen = !(publicSaleOpen);
    }

    function toggleFreeSale() public onlyOwner {
        freeSaleOpen = !(freeSaleOpen);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function publicMint(uint256 numOfTokens) external payable callerIsUser {
        require(publicSaleOpen, "Sale is not active yet");
        require(totalSupply() + numOfTokens < MAX_SUPPLY, "Exceed max supply"); 
        require(numOfTokens <= MAX_PER_TX, "Can't claim more than 4 in a tx");
        require(numberMinted(msg.sender) + numOfTokens <= MAX_PER_WALLET, "Cannot mint this many");
        require(msg.value >= COST_PER_MINT * numOfTokens, "Insufficient ether provided to mint");

        _safeMint(msg.sender, numOfTokens);
    }

    function freeMint(uint256 numOfTokens, bytes32[] calldata merkleProof) external callerIsUser {
        require(freeSaleOpen, "Whitelist is not active yet");
        require(addressToFreeMints[msg.sender] <= MAX_FREE_PER_USER, "User max free limit");
        require(totalSupply() + numOfTokens < MAX_FREE_SUPPLY, "Exceed max free supply, use publicMint to mint");

        // Merkle root check
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, whitelistMerkleRoot, node), "invalid proof");

        addressToFreeMints[msg.sender] = addressToFreeMints[msg.sender] + numOfTokens;
        _safeMint(msg.sender, numOfTokens);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function retrieveFunds() public onlyOwner {
        uint256 balance = accountBalance();
        require(balance > 0, "No funds to retrieve");
        
        _withdraw(payable(msg.sender), balance);
    }

    function _withdraw(address payable account, uint256 amount) internal {
        (bool sent, ) = account.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function accountBalance() internal view returns(uint256) {
        return address(this).balance;
    }

    function ownerMint(address mintTo, uint256 numOfTokens) external onlyOwner {
        _safeMint(mintTo, numOfTokens);
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    function isSaleOpen() public view returns (bool) {
        return publicSaleOpen;
    }

    function isFreeSaleOpen() public view returns (bool) {
        return freeSaleOpen && totalSupply() < MAX_FREE_SUPPLY;
    }

    // Contract overrides
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
    public payable
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}