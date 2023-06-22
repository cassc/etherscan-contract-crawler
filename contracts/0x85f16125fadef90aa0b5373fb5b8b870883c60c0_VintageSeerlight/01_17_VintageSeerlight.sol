// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract VintageSeerlight is ERC721, ERC721URIStorage, Ownable, VRFConsumerBase {
    using Strings for uint256;
    using ECDSA for bytes32;

    mapping (uint256 => string) private _tokenURIs;

    uint256 public totalReservedSupply = 0;
    
    bytes32 internal keyHash;
    uint256 internal fee;
    
    uint256 public randomSeed;

    struct chainlinkParams {
        address vrfCoordinator;
        address linkAddress;
        bytes32 keyHash;
    }
    
    string private _tokenBaseURI = '';
    string private _tokenRevealedBaseURI = '';
    
    event RandomSeedDrawn(bytes32 indexed requestId, uint256 indexed result);

    constructor(chainlinkParams memory _chainlinkParams) 
        ERC721("Vintage Seerlight", "VINTAGESEERLIGHT") 
        VRFConsumerBase(
            _chainlinkParams.vrfCoordinator, // VRF Coordinator
            _chainlinkParams.linkAddress  // LINK Token
        ) {
        
        keyHash = _chainlinkParams.keyHash;
        fee = 2 * 10 ** 18;
    }
    
    /** 
     * Requests randomness 
     */
    function getRandomNumber() public onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomSeed = randomness;
        emit RandomSeedDrawn(requestId, randomness);
    }
    
    function totalSupply() public view returns (uint) {
        return totalReservedSupply;
    }

    function mintReserved(uint256[] calldata tokenIds) external onlyOwner {
        for(uint256 i = 0; i < tokenIds.length; i++) {
            totalReservedSupply += 1;
            _safeMint(msg.sender, tokenIds[i]);
        }
    }

    receive() external payable {
        revert();
    }
    
    fallback() external payable {
        revert();
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    function  _setTokenURI(uint256 tokenId, string memory _tokenURI) 
        internal
        virtual
        override
    {       
        _tokenURIs[tokenId] = _tokenURI;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) 
        public
        onlyOwner
    {       
        _setTokenURI(tokenId, _tokenURI);
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function setRevealedBaseURI(string calldata revealedBaseURI) external onlyOwner {
        _tokenRevealedBaseURI = revealedBaseURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), 'Token does not exist');

        string memory directTokenURI = _tokenURIs[tokenId];

        if (bytes(directTokenURI).length > 0) {
            return directTokenURI;
        }

        string memory revealedBaseURI = _tokenRevealedBaseURI;
        
        return bytes(revealedBaseURI).length > 0 ?
            string(abi.encodePacked(revealedBaseURI, tokenId.toString())) :
            string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }
}