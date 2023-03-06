// SPDX-License-Identifier: MIT

/*
  o__ __o    __o__       o__ __o     o         o/   o__ __o    
 <|     v\     |        /v     v\   <|>       /v   /v     v\   
 / \     <\   / \      />       <\  / >      />   />       <\  
 \o/     o/   \o/    o/             \o__ __o/    _\o____       
  |__  _<|     |    <|               |__ __|          \_\__o__ 
  |       \   < >    \\              |      \               \  
 <o>      /    |       \         /  <o>      \o   \         /  
  |      o     o        o       o    |        v\   o       o   
 / \  __/>   __|>_      <\__ __/>   / \        <\  <\__ __/>   
                                                              
*/

pragma solidity ^0.6.6;

import "ERC721A.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "MerkleProof.sol";

contract BICKS is Ownable, ERC721A, ReentrancyGuard {
    uint256 public maxSupply = 6969;
    uint256 public maxMintPerTx = 20;
    uint256 public price = 0.0025 * 10**18;
    bytes32 public whitelistMerkleRoot =
        0x7916d9e91afcd3513f4d54f056620061a4f26c143f0103a9ca97785b8d04157a;
    bool public publicPaused = true;
    bool public revealed = false;
    string public baseURI;
    string public hiddenMetadataUri =
        "ipfs://QmNtcc6AqEYd2Brgz8MK2xXzqT1RAMF2cgEME1SqKp4oiT";

    constructor() public ERC721A("BICKS", "SMOL", 6969, 6969) {}

    function mint(uint256 amount) external payable {
        uint256 ts = totalSupply();
        require(publicPaused == false, "Mint not open for public");
        require(ts + amount <= maxSupply, "Purchase would exceed max tokens");
        require(
            amount <= maxMintPerTx,
            "Amount should not exceed max mint number"
        );

        require(msg.value >= price * amount, "Please send the exact amount.");

        _safeMint(msg.sender, amount);
    }

    function openPublicMint(bool paused) external onlyOwner {
        publicPaused = paused;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function whitelistStop(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxPerTx(uint256 _maxMintPerTx) external onlyOwner {
        maxMintPerTx = _maxMintPerTx;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
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
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _tokenId.toString()))
                : "";
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}