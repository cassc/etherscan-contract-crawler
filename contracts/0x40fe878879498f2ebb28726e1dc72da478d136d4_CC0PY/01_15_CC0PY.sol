// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CC0PY is ERC721, ERC721Burnable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    bytes32[] public merkleRoots;
    uint256[] public allowances;

    mapping(address => uint256) public numberOfMints;
    mapping(address => uint256) public numberOfAllowance;


    string private baseMetadataUri;
    string private hiddenMetadataUri;

    uint256 public maxSupply = 666;
    uint256 public totalSupply;
    uint256 public mintPrice = 0.0099 ether;

    bool public isWhitelistMintOpen = true;
    bool public isPublicMintOpen = true;
    bool public isRevealed = true;

    // >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< ><  >< >< >< >< >< >< >< >< >< >< >< >< >< >< ><

    constructor(string memory _baseMetadataUri, string memory _hiddenMetadataUri) 
        ERC721("CC0PY", "CC0PY") 
    {
        baseMetadataUri = _baseMetadataUri;
        hiddenMetadataUri = _hiddenMetadataUri;            
        _tokenIdCounter.increment();    // The collection index starts from 1
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0, "Invalid mint amount!");
        require(totalSupply + _mintAmount <= maxSupply, "Max supply exceeded!");
        _;
    }   

    // >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< ><  >< >< >< >< >< >< >< >< >< >< >< >< >< >< ><

    function _baseURI() internal view override returns (string memory) {
        return baseMetadataUri;
    }

    function baseURI() public view returns (string memory) {
        if (isRevealed)
            return baseMetadataUri;
        else 
            return hiddenMetadataUri;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){        
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        if (!isRevealed)
            return hiddenMetadataUri;
        
        return super.tokenURI(_tokenId);
    }

    function publicMint(uint256 _mintAmount) public payable mintCompliance(1) nonReentrant {
        require(_mintAmount == 1, "Mint amount can not exceed 1");
        require(isPublicMintOpen, "The public mint is not open yet!");
        require(numberOfMints[_msgSender()] == 0, "You have already minted at least 1 NFT!");

        if (totalSupply >= 200){
            require(msg.value >= mintPrice, "Invalid price input!");
        }

        numberOfMints[_msgSender()] = 1;

        _safeMint(_msgSender());
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) 
    public mintCompliance(_mintAmount) nonReentrant returns (uint256){
        require(isWhitelistMintOpen, "The whitelist sale is not enabled!");

        merkleCheck(_merkleProof);
        require(numberOfAllowance[_msgSender()] > 0, "This address is not whitelisted!");
        require(numberOfAllowance[_msgSender()] >= numberOfMints[_msgSender()] + _mintAmount, "Number of allowance exceeded!");

        numberOfMints[_msgSender()] += _mintAmount;
        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(_msgSender());
        }
        return numberOfAllowance[_msgSender()] - numberOfMints[_msgSender()];
    }

    /*
        @dev increase tokenID and total supply before mint
    */
    function _safeMint(address to) internal virtual {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        totalSupply++;

        super._safeMint(to, tokenId);
    }

    function remainingAllowance(bytes32[] calldata _merkleProof) public returns (uint256) { 
        merkleCheck(_merkleProof);       
        require(numberOfAllowance[_msgSender()] > 0, "The address is not whitelisted!");

        return numberOfAllowance[_msgSender()] - numberOfMints[_msgSender()];
    }

    function merkleCheck (bytes32[] calldata _merkleProof) internal {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        
        for (uint256 i = 0; i < merkleRoots.length; i++){
            // If the proof valid for this index, get the allowance of this index
            if (MerkleProof.verify(_merkleProof, merkleRoots[i], leaf)){
                numberOfAllowance[_msgSender()] = allowances[i];
                break;
            }
        }
    }
        

    /*  ->->->->->->->->->->        ADMIN FUNCTIONS         ->->->->->->->->->->
                                                           .------.------.    
            +-------------+                                |      |      |    
            |             |                                |      |      |    
            |             |        _           ____        |      |      |    
            |             |     ___))         [  | \___    |      |      |    
            |             |     ) //o          | |     \   |      |      |    
            |             |  _ (_    >         | |      ]  |      |      |    
            |          __ | (O)  \__<          | | ____/   '------'------'    
            |         /  o| [/] /   \)        [__|/_                          
            |             | [\]|  ( \         __/___\_____                    
            |             | [/]|   \ \__  ___|            |                   
            |             | [\]|    \___E/%%/|____________|_____              
            |             | [/]|=====__   (_____________________)             
            |             | [\] \_____ \    |                  |              
            |             | [/========\ |   |                  |              
            |             | [\]     []| |   |                  |              
            |             | [/]     []| |_  |                  |              
            |             | [\]     []|___) |                  |    MEPH          
            ====================================================================
    */    
    function setWhitelistMintOpen(bool _state) public onlyOwner {
        isWhitelistMintOpen = _state;
    }

    function setPublicMintOpen(bool _state) public onlyOwner {
        isPublicMintOpen = _state;
    }

    function setRevealed(bool _state) public onlyOwner {
        isRevealed = _state;
    }

    function setBaseMetadataUri(string memory _baseMetadataUri) public onlyOwner {
        baseMetadataUri = _baseMetadataUri;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setPublicPrice(uint256 _newPrice) public onlyOwner {
        mintPrice = _newPrice;
    }

    function pushMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoots.push(_merkleRoot);
    }

    function pushAllowance(uint256 _allowance) public onlyOwner {
        allowances.push(_allowance);
    }

    function withdraw() public payable onlyOwner {
        (bool txSuccess, ) = payable(owner()).call{value: address(this).balance}("");
        require(txSuccess);
    }
}