// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract SavageBaskets is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant MAX_WHITELIST_SUPPLY = 333;
    uint256 public constant MAX_WHITELIST_MINT = 1;
    uint256 public mintPrice = .05 ether;

    string private baseTokenUri;
    string public  placeholderTokenUri;
    
    //deploy smart contract, toggle WL, toggle WL when done, toggle publicSale 
    //2 days later toggle reveal
    bool public isRevealed;
    bool public publicSale;
    bool public whiteListSale;
    bool public pause;
    
    bytes32 private merkleRoot;
    
    mapping(address => uint256) public totalWhitelistMint;
    mapping(address => uint256) public maxWhitelistMint;

    constructor() ERC721A("Savage Baskets", "SBSKT"){}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "SBSKT :: Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        require(publicSale, "SBSKT :: Not Yet Active.");
        require((_totalMinted() + _quantity) <= MAX_SUPPLY, "SBSKT :: Beyond Max Supply");
        require(msg.value >= (mintPrice * _quantity), "SBSKT :: Below Ether Value");

        _mint(msg.sender, _quantity);
    }

    function whitelistMint(bytes32[] memory _merkleProof, uint256 _quantity) external callerIsUser{
        require(whiteListSale, "SBSKT :: Minting is on Pause");
        require((_totalMinted() + _quantity) <= MAX_WHITELIST_SUPPLY, "SBSKT :: Cannot mint beyond whitelist max supply");
        require((totalWhitelistMint[msg.sender] + _quantity)  <= MAX_WHITELIST_MINT, "SBSKT :: Cannot mint beyond whitelist max mint");
        //create leaf node
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, sender), "SBSKT :: You are not whitelisted");

        totalWhitelistMint[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    function teamMint(address to, uint quantity) external onlyOwner{
        _mint(to, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 trueId = tokenId + 1;

        if(!isRevealed){
            return placeholderTokenUri;
        }
        
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
    }

    function setPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setTokenUri(string calldata _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }

    function setPlaceHolderUri(string calldata _placeholderTokenUri) external onlyOwner{
        placeholderTokenUri = _placeholderTokenUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner{
        merkleRoot = _merkleRoot;
    }

    function getMerkleRoot() external view returns (bytes32){
        return merkleRoot;
    }

    function togglePause() external onlyOwner{
        pause = !pause;
    }

    function toggleWhiteListSale() external onlyOwner{
        whiteListSale = !whiteListSale;
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function toggleReveal() external onlyOwner{
        isRevealed = !isRevealed;
    }

    function withdraw() external onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }
}