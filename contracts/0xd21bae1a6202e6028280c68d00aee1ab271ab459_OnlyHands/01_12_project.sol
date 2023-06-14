// SPDX-License-Identifier: MIT

/*

_______/\\\\\_______/\\\\\_____/\\\__/\\\______________/\\\________/\\\_                           
 _____/\\\///\\\____\/\\\\\\___\/\\\_\/\\\_____________\///\\\____/\\\/__                          
  ___/\\\/__\///\\\__\/\\\/\\\__\/\\\_\/\\\_______________\///\\\/\\\/____                         
   __/\\\______\//\\\_\/\\\//\\\_\/\\\_\/\\\_________________\///\\\/______                        
    _\/\\\_______\/\\\_\/\\\\//\\\\/\\\_\/\\\___________________\/\\\_______                       
     _\//\\\______/\\\__\/\\\_\//\\\/\\\_\/\\\___________________\/\\\_______                      
      __\///\\\__/\\\____\/\\\__\//\\\\\\_\/\\\___________________\/\\\_______                     
       ____\///\\\\\/_____\/\\\___\//\\\\\_\/\\\\\\\\\\\\\\\_______\/\\\_______                    
        ______\/////_______\///_____\/////__\///////////////________\///________                   
__/\\\________/\\\_____/\\\\\\\\\_____/\\\\\_____/\\\__/\\\\\\\\\\\\________/\\\\\\\\\\\___        
 _\/\\\_______\/\\\___/\\\\\\\\\\\\\__\/\\\\\\___\/\\\_\/\\\////////\\\____/\\\/////////\\\_       
  _\/\\\_______\/\\\__/\\\/////////\\\_\/\\\/\\\__\/\\\_\/\\\______\//\\\__\//\\\______\///__      
   _\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\//\\\_\/\\\_\/\\\_______\/\\\___\////\\\_________     
    _\/\\\/////////\\\_\/\\\\\\\\\\\\\\\_\/\\\\//\\\\/\\\_\/\\\_______\/\\\______\////\\\______    
     _\/\\\_______\/\\\_\/\\\/////////\\\_\/\\\_\//\\\/\\\_\/\\\_______\/\\\_________\////\\\___   
      _\/\\\_______\/\\\_\/\\\_______\/\\\_\/\\\__\//\\\\\\_\/\\\_______/\\\___/\\\______\//\\\__  
       _\/\\\_______\/\\\_\/\\\_______\/\\\_\/\\\___\//\\\\\_\/\\\\\\\\\\\\/___\///\\\\\\\\\\\/___ 
        _\///________\///__\///________\///__\///_____\/////__\////////////_______\///////////_____

*/

pragma solidity ^0.8.0;

import "ERC721A.sol";
import "DefaultOperatorFilterer.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "MerkleProof.sol";
import "Strings.sol";

contract OnlyHands is
    Ownable,
    ERC721A,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    uint256 public maxSupply = 1111;
    uint256 public maxMintPerTx = 10;
    uint256 public price = 0.111 * 10 ** 18;
    bytes32 public whitelistMerkleRoot =
        0x89f58633140608d78e48e5fadd601ab78e11f07d95272eb2d0ab929d15f58002;
    bool public publicPaused = true;
    bool public revealed = false;
    string public baseURI;
    string public hiddenMetadataUri =
        "ipfs://QmTwjUDFZmTbih5Q9HJ35SgK2NtxCWS3zsPtKTBh7wCb8c";

    constructor() ERC721A("ONLY HANDS", "OH") {}

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

    function whitelistMint(
        uint256 amount,
        bytes32[] calldata _merkleProof
    ) public payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        uint256 ts = totalSupply();
        require(ts + amount <= maxSupply, "Purchase would exceed max tokens");

        require(
            MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf),
            "Invalid proof!"
        );

        {
            _safeMint(msg.sender, amount);
        }
    }

    function setHiddenMetadataUri(
        string memory _hiddenMetadataUri
    ) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
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
                ? string(
                    abi.encodePacked(currentBaseURI, Strings.toString(_tokenId))
                )
                : "";
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function claim(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    // OVERRIDDEN PUBLIC WRITE CONTRACT FUNCTIONS: OpenSea's Royalty Filterer Implementation. //

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }
}