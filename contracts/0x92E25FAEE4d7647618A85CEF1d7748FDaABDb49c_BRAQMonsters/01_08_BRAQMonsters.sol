// SPDX-License-Identifier: MIT

/******************************************
 *  Amended by KingPin Development Agency *
 *         Author: devCarl.eth            *
 ******************************************/

 /******************************************************************************************
  ____   ____    ____   ___       ___ ___   ___   ____   _____ ______    ___  ____   _____
|    \ |    \  /    | /   \     |   |   | /   \ |    \ / ___/|      |  /  _]|    \  / ___/
|  o  )|  D  )|  o  ||     |    | _   _ ||     ||  _  (   \_ |      | /  [_ |  D  )(    \_ 
|     ||    / |     ||  Q  |    |  \_/  ||  O  ||  |  |\__  ||_|  |_||    _]|    /  \__  |
|  O  ||    \ |  _  ||     |    |   |   ||     ||  |  |/  \ |  |  |  |   [_ |    \  /  \ |
|     ||  .  \|  |  ||     |    |   |   ||     ||  |  |\    |  |  |  |     ||  .  \ \    |
|_____||__|\_||__|__| \__,_|    |___|___| \___/ |__|__| \___|  |__|  |_____||__|\_|  \___|
*******************************************************************************************/

pragma solidity ^0.8.15;

import '@openzeppelin/contracts/access/Ownable.sol'; 
import 'erc721a/contracts/ERC721A.sol'; 
import '@openzeppelin/contracts/security/ReentrancyGuard.sol'; 
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol'; 
import '@openzeppelin/contracts/utils/Strings.sol'; 

contract BRAQMonsters is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256; 

    string public uriPrefix = ""; 
    string public uriSuffix = ".json"; 
    string public hiddenMetadataURI; 

    uint256 public maxSupply = 4444; 
    uint256 public reservedMonsters = 100;
    uint256 public maxPublic; 

    mapping(address => uint256) public countsByAddress;
    bytes32 private merkleRoot;   

    bool public paused = false; 
    bool public revealed = false;
    bool public whiteListSale = true;  
    bool public publicSale = false; 


    constructor(
        string memory _hiddenMetadataUri
    ) ERC721A("BRAQ Monsters", "MONSTER") { 
        setHiddenMetadataURI(_hiddenMetadataUri); 
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(totalSupply() + _mintAmount <= maxSupply, "Sold out"); 
        _; 
    }

    function whitelistMint(uint256 _mintAmount, uint8 _maxAllowed, bytes32[] calldata _merkleProof) public mintCompliance(_mintAmount) {
            require(whiteListSale && !publicSale && !paused, "Whitelist not active."); 
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender,_maxAllowed));
            require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid Proof"); 
            require(countsByAddress[_msgSender()] + _mintAmount <= _maxAllowed, "Purchase exceeds max whitelisted count.");  
            countsByAddress[_msgSender()] += _mintAmount; 
            _safeMint(_msgSender(), _mintAmount); 

    }

    function publicMint(uint256 _mintAmount) public mintCompliance(_mintAmount) {
        require(!whiteListSale && publicSale && !paused, "Public not Active currently");  
        require(countsByAddress[_msgSender()] + _mintAmount <= maxPublic, "You have minted the max you are allowed in public sale");  
        countsByAddress[_msgSender()]+= _mintAmount; 
        _safeMint(_msgSender(), _mintAmount); 
    }

    function mintReserved(address _to, uint256 _mintAmount) external mintCompliance(_mintAmount) onlyOwner {
        require(!paused, "Sale is Paused"); 
        require(countsByAddress[_msgSender()] + _mintAmount <= reservedMonsters, "All reserved Monsters have not been minted"); 
        countsByAddress[_msgSender()]+= _mintAmount; 
        _safeMint(_to, _mintAmount);

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

    function publicSaleState(bool _state) public onlyOwner {
        publicSale = _state; 
    }

    function publicMaxAllowed(uint256 _publicAllowed) public onlyOwner {
        maxPublic = _publicAllowed; 
    }

    function setPresaleMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function whitelistFreeMint() public onlyOwner {
        whiteListSale = !whiteListSale; 
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