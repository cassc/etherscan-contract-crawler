// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// FOR ACADEMIC PURPOSE
// Contract by Sui Lip Xin TP051226 from Asia Pacific University. FOR FYP PURPOSE. 

contract APUCertificate is ERC721, Ownable, ERC721Enumerable{
    using Counters for Counters.Counter;
    using Strings for uint256;  
    string public baseURI;
    bool private _transferLock = false;
    Counters.Counter private _tokenIdCounter;
    mapping(address => uint256) public amountMinted;
    
    constructor(string memory _baseURI) ERC721("APU BlockChain Certificate", "APUCertificate") {
        _tokenIdCounter.increment();
        baseURI = _baseURI;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /** 
    * @notice Mint the Certificate NFT 
    * @param amount Number of Certificate NFT
    **/
    function ownerMint(uint256 amount) external onlyOwner {
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    /** 
    * @notice Burn the certificate (remove ownership of cert)
    * @param tokenId ID of token to be burned
    **/

    function burnCertificate(uint256 tokenId) external onlyOwner {
        require(_exists(tokenId), 'Token does not exist');
        _burn(tokenId);
    }

    /** 
    * @notice link metadata
    * @param tokenId ID of token
    **/
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId));
        string memory uri = string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
        return uri;
    }

    /** 
    * @notice Lock the transfer process 
    * @param lock true / false
    **/
    function setTransferLock(bool lock) external onlyOwner {
        _transferLock = lock;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) onlyOwner
        internal
        override(ERC721, ERC721Enumerable)
    {
        require(!_transferLock);
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}