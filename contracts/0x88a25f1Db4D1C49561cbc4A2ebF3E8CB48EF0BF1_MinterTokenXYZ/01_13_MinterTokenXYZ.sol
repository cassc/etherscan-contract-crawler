// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "ERC721.sol";
import "Ownable.sol";
import "Pausable.sol";
import "ECDSA.sol";
import "Strings.sol";

contract MinterTokenXYZ is ERC721, Ownable, Pausable {
    
    using Strings for uint256;

    // Keep track of minted token count
    uint256 private _mintedTokens;

    // Hashing
    using ECDSA for bytes32;
    mapping(bytes32 => bool) private usedHashes;

    // For non-compliant contracts
    mapping(address => bool) internal blacklistedContract;
    mapping(address => string) internal blacklistedURI;

    // Token contract provenance. When a token is minted, the struct is populated with the 
    // contract address and token ID which the SBT represents
    struct tokenMap {
        address minterContract;
        uint256 minterToken;
        string minterURI;
    }

    mapping(uint256 => tokenMap) internal _tokenContractMap;
    
    string internal baseURI_;

    // Emit an event detailing the provenance of the token which the SBT represents
    event MinterTokenEmitted(address tokenMinter, uint256 mintedTokenId, address minterContractAddress, uint256 mintedTokenID);

    // Signature address
    address public signerAddress;

    constructor(address _signerAddress) payable ERC721("MinterTokenXYZ", "MTXYZ") {
        signerAddress = _signerAddress;
    }

    /**
     * @dev Change Signer Address
     */
    function setSignerAddress(address newSignerAddress) onlyOwner external returns(address)
    {
        signerAddress = newSignerAddress; 
        return(signerAddress);
    }

    /**
     * @dev Base URI
     */
    function setBaseURI(string memory newBaseURI) onlyOwner external returns(string memory)
    {
        baseURI_ = newBaseURI;
        return(baseURI_);
    }

    /**
     * @dev Flip contract state and URI for blacklisted contracts
     */
    function flipContractState(address contractAddress, string memory contractURI) onlyOwner external returns(string memory)
    {
        blacklistedContract[contractAddress] = !blacklistedContract[contractAddress];
        blacklistedURI[contractAddress] = contractURI;
        return(contractURI);
    }

    /**
     * @dev Amend individual token URI for metadata updates
     */
    function setTokenURI(uint256 tokenId, string memory newURI) onlyOwner external returns(string memory)
    {
        _tokenContractMap[tokenId].minterURI = newURI;
        return(newURI);
    }

    /**
     * @dev Token URI
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_mintedTokens >= tokenId, "Token does not exist!");

        address tokenAddress = _tokenContractMap[tokenId].minterContract;

        if(blacklistedContract[tokenAddress])
        {
            return blacklistedURI[tokenAddress];
        }
        
        if(bytes(baseURI_).length == 0)
        {
            return _tokenContractMap[tokenId].minterURI;
        }
        else
        {
            return string(abi.encodePacked(baseURI_, tokenId.toString()));
        }
    }

    /**
     * @dev Ensure that tokens can only be minted, but not transferred
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        virtual
        override(ERC721)
    {
        require(from == address(0), "MinterTokenXYZ: this is a Soul-Bond Token!");
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    /**
     * @dev Returns total supply for the collection. Given Minter Tokens are not burnable
     * we can simply return the minted token count
     */
    function totalSupply() external view returns(uint256)
    {
        return _mintedTokens;
    }

    /**
     * @dev Returns for a given token ID the original smart contract and token ID to which it maps
     */
    function viewTokenProvenance(uint256 tokenId) external view returns(address, uint256)
    {
        require(_mintedTokens >= tokenId, "Token does not exist!" );
        return (_tokenContractMap[tokenId].minterContract, _tokenContractMap[tokenId].minterToken);
    }

    /**
     * @dev Pause minting
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause minting
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Mint function transaction hashing; will be verified for recognition versus the signer address
     */
    function hashTransaction(address _sender, address _thisContract, address _tokenContract, 
                            uint256 _contractToken, string memory _uri) private pure returns(bytes32) 
    {
          bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(_sender, _thisContract, _tokenContract, _contractToken, _uri)))
          );    
          return hash;
    }

    /**
     * @dev Cheap transaction hashing which will be the one used for mapping storage. If the 3D-renderer is ever tweaked,
     * the generated end-result models will have different IPFS CIDs which would yield a different signature. This would allow
     * users to mint priorly minted Minter Tokens again. We instead store a signature made of immutable elements
     */
    function hashTransactionCheap(address _sender, address _thisContract, address _tokenContract, 
                            uint256 _contractToken) private pure returns(bytes32) 
    {
          bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(_sender, _thisContract, _tokenContract, _contractToken)))
          );    
          return hash;
    }
    
    /**
     * @dev Mint a Minter Token
     */
    function createMinterToken(bytes memory signature, address contractAddress, 
                                uint256 contractToken, string memory uri, address recipient)
        external
        whenNotPaused
    {   
        bytes32 messageHash = hashTransaction(recipient, address(this), contractAddress, contractToken, uri);
        bytes32 messageHashCheap = hashTransactionCheap(recipient, address(this), contractAddress, contractToken);

        require(messageHash.recover(signature) == signerAddress, "Unrecognizable Hash");
        require(!usedHashes[messageHashCheap], "Reused Hash");
        require(contractAddress != address(this), "Cannot mint SBTs for Minter Tokens");
        require(msg.sender == tx.origin, "No contract minting");
        
        usedHashes[messageHashCheap] = true;
        ++_mintedTokens;

        _safeMint(recipient, _mintedTokens);

        _tokenContractMap[_mintedTokens] = tokenMap(contractAddress, contractToken, uri);

        emit MinterTokenEmitted(recipient, _mintedTokens, contractAddress, contractToken);
    }

}