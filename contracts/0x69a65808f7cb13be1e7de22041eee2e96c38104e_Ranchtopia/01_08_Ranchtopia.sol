// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import '@openzeppelin/contracts/access/Ownable.sol'; 
import 'erc721a/contracts/ERC721A.sol'; 
import '@openzeppelin/contracts/security/ReentrancyGuard.sol'; 
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol'; 
import '@openzeppelin/contracts/utils/Strings.sol'; 

contract Ranchtopia is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256; 

    string public uriPrefix = ""; 
    string public uriSuffix = ".json"; 
    string public hiddenMetadataURI; 

    uint256 public maxSupply; 
    uint256 public maxFreeMintAmountPerAddrWL;
    uint256 public maxFreeMintAmountPerAddrPUB;  


    bytes32 public merkleRoot; 
    mapping(address => uint256) public whitelistedAmt; 
    mapping(address => uint256) public publicAmt; 

    bool public paused = false; 
    bool public revealed = false;
    bool public whiteListSale = true; 
    bool public publicSale = false;  


    constructor(
        uint256 _maxSupply,
        uint256 _maxFreeMintAmountPerAddrWL,
        uint256 _maxFreeMintAmountPerAddrPUB,
        string memory _hiddenMetadataUri
    ) ERC721A("Ranchtopia", "RANCH") {
        maxSupply = _maxSupply;
        setMaxFreeMintAmountPerAddrWL(_maxFreeMintAmountPerAddrWL); 
        setMaxFreeMintAmountPerAddrPUB(_maxFreeMintAmountPerAddrPUB); 
        setHiddenMetadataURI(_hiddenMetadataUri); 
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(totalSupply() + _mintAmount <= maxSupply, "Sold out"); 
        _; 
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public mintCompliance(_mintAmount) {
            require(whiteListSale, "Whitelist sale is not current"); 
            bytes32 leaf = keccak256(abi.encodePacked(_msgSender())); 
            require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid Proof"); 
            uint256 mintedCount = whitelistedAmt[msg.sender]; 
            require(mintedCount + _mintAmount <= maxFreeMintAmountPerAddrWL, "Max Ranchtopians minted"); 
            
            whitelistedAmt[msg.sender]++; 

            _safeMint(_msgSender(), _mintAmount); 

    }

    function freeMint(uint256 _mintAmount) public mintCompliance(_mintAmount) {
        require(publicSale, "Mint is not live yet"); 
        require(_numberMinted(msg.sender) + _mintAmount <= maxFreeMintAmountPerAddrPUB, "Exceeds your allocation."); 
        uint256 mintCountPublic = publicAmt[msg.sender];
        require(mintCountPublic + _mintAmount <= maxFreeMintAmountPerAddrPUB, "Max Ranchtopians minted"); 

        publicAmt[msg.sender]++; 

        _safeMint(_msgSender(), _mintAmount); 
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1; 
    }
    
    function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataURI;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function publicFreeMint() public onlyOwner {
        publicSale = !publicSale;
    }

    function whitelistFreeMint() public onlyOwner {
        whiteListSale = !whiteListSale; 
    }

    function setMaxFreeMintAmountPerAddrWL(uint256 _maxFreeMintAmountPerAddrWL) public onlyOwner {
        maxFreeMintAmountPerAddrWL = _maxFreeMintAmountPerAddrWL; 
    }

    function setMaxFreeMintAmountPerAddrPUB(uint256 _maxFreeMintAmountPerAddrPUB) public onlyOwner {
        maxFreeMintAmountPerAddrPUB = _maxFreeMintAmountPerAddrPUB;
    }

    function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
        
        _safeMint(_receiver, _mintAmount); 
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state; 
    }

    function setHiddenMetadataURI(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataURI = _hiddenMetadataUri; 
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix; 
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix; 
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os, "Withdraw failed!");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}