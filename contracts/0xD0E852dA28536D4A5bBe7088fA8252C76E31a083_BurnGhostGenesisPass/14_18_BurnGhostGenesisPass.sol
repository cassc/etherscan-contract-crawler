// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Burn Ghost Genesis Pass
/// @notice This is Burn Ghost's Genesis Pass ERC721 NFT contract 
/// @dev This contract uses OpenZeppelin's library and includes OpenSea's on-chain enforcement tool for royalties   
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

//          *((((,            ,((((/           *((((*            ,((((*          
//          *((((((/        ,((((((((/       *((((((((*        ,((((((*          
//          *((((((((*    ./(((((((((((*   ,((((((((((((.    *((((((((*          
//          *(((((((((((,/(((((((((((((((*((((((((((((((((,(((((((((((*          
//          *(((((((((((((((((((((((((((((((((((((((((((((((((((((((((*          
//          *(((((((((((((((((((((((((((((((((((((((((((((((((((((((((*          
//          *((((((((((((((((/,.                  .,//((((((((((((((((*          
//          *((((((((((((/.          *(#%%%((*          ,(((((((((((((*          
//          *(((((((((*       *#@@@@@@@@@@@@@@@@@@@&*       ,(((((((((*          
//          *(((((((.      &@@@@@@@@@@@@@@@@@@@@@@@@@@@%      ./((((((*          
//          *((((/,    ,&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%.     /((((*          
//          *(((,     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%     ,(((*          
//          *((.    #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(    ./(*          
//          *(,    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&    .(*          
//          *,   .&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    .*          
//          ,    (@@@@@@&    ,@@@,    %@@@@@@,   .%@@#    (@@@@@@/    *          
//          .    @@@@@@@@/           *@@@@@@@#           ,@@@@@@@@    .          
//          .    @@@@@@@@@@#       %@@@@@@@@@@@&.      /@@@@@@@@@@.   .          
//               @@@@@@@@%           #@@@@@@@@,          /@@@@@@@@.              
//              ,@@@@@@@&     %@%.    %@@@@@@.    (@&.    *@@@@@@@.              
//              ,@@@@@@@@@&&@@@@@@@@&@@@@@@@@@@&@@@@@@@@&@@@@@@@@@.              
//              ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.              
//              ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.              
//              ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.              
//              ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.              
//              ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.              
//              ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.              
//              ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.              
//              ,@@@@@@   (@@@@@@@@@@@@&   %@@@@@@@@@@@@&   %@@@@@.              
//              ,@@@%       /@@@@@@@@&,      %@@@@@@@@%       (@@@.              
//              ,@/           #@@@@@,          &@@@@%.          /@.              
//                              %@*             ,@&.                     

contract BurnGhostGenesisPass is DefaultOperatorFilterer, ERC721, Ownable {

    /// @notice The base uri of the project
    string public baseURI; 

    /// @notice The collection's max supply 
    uint256 public maxSupply = 777;

    /// @notice Total reserved by the Burn Ghost team
    uint256 public reserved = 177;

    /// @notice Flag to pause allow list mint, paused by default
    bool public salePaused = true;

    /// @notice Flag to pause public mint, paused by default
    bool public publicMintPaused = true;

    /// @dev Merkle tree root hash
    bytes32 private root;

    /// @dev Mapping to check if an address has already minted to avoid double mints on allow list mints
    mapping(address => bool) minted; 

    /// @dev Counters library to track token id and counts
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _allowListMintedCounter;

    constructor(string memory uri) ERC721("Burn Ghost Genesis Pass", "BGGP") {
        baseURI = uri;
    }

    /// Base uri functions
    ///@notice Returns the base uri 
    ///@return Base uri
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    ///@notice Sets a new base uri
    ///@dev Only callable by owner
    ///@param newBaseURI The new base uri 
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    /// Minting functions
    ///@notice Mints token to allow list addresses 
    ///@dev Uses Merkle tree proof
    ///@param proof The Merkle tree proof of the allow list address 
    function safeMint(bytes32[] calldata proof) external {
        /// Check if the sale is paused
        require(salePaused == false, "BGGP: Sale paused");

        /// If public mint is paused, check allow list
        if (publicMintPaused == true) {
            /// Check if user is on the allow list
            bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_msgSender()))));
            require(MerkleProof.verify(proof, root, leaf), "BGGP: Invalid proof");
        } 

        /// Check if user has minted
        require(minted[_msgSender()] == false, "BGGP: User already minted");

        /// Check balance of supply
        require(_allowListMintedCounter.current() < maxSupply - reserved, "BGGP: Max allow list supply minted"); 

        /// Get current token id then increase it
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        /// Increase the allow list minted count
        _allowListMintedCounter.increment();

        /// Mint the token
        _safeMint(_msgSender(), tokenId);

        /// Set that address has minted
        minted[_msgSender()] = true;
    }

    ///@notice Airdrops a token to users 
    ///@dev Only callable by owner
    ///@param to Array of addresses to receive airdrop 
    function airdrop(address[] calldata to) external onlyOwner {
        /// Check balance of supply
        require(_tokenIdCounter.current() + to.length - 1 < maxSupply, "BGGP: Airdrop amount exceeds maximum supply"); 
        
        for(uint i; i < to.length;) {
            /// Get current token id then increase it
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();

            /// Mint the token
            _safeMint(to[i], tokenId);

            /// Unchecked i to save gas
            unchecked {
                i++;
            }
        }
    }

    /// Other view and admin functions
    ///@notice Pause or unpause the allow list mint
    ///@dev Only callable by owner
    ///@param isPaused Flag if sale is paused or not
    function setSalePaused(bool isPaused) external onlyOwner {
        salePaused = isPaused; 
    }

    ///@notice Pause or unpause the public mint
    ///@dev Only callable by owner
    ///@param isPaused Flag if sale is paused or not
    function setPublicMintPaused(bool isPaused) external onlyOwner {
        publicMintPaused = isPaused;
    }

    /// Verification functions
    ///@notice Returns the current Merkle tree root hash
    ///@dev Only callable by owner
    function getRootHash() external view onlyOwner returns(bytes32) {
        return root;
    }

    ///@notice Sets a new Merkle tree root hash
    ///@dev Only callable by owner
    ///@param _root The new merkle tree root hash 
    function setRootHash(bytes32 _root) external onlyOwner {
        root = _root;
    }

    ///@notice Returns the total number of passes minted
    function totalMinted() external view returns(uint256) {
        /// Token id starts from index 0 and counter is always incremented after mint, representing the total minted count
       return _tokenIdCounter.current(); 
    }

    ///@notice Returns the current number of allow list passes minted
    function totalAllowListMinted() external view returns(uint256) {
        /// Token id starts from index 0 and counter is always incremented after mint, representing the total minted count
       return _allowListMintedCounter.current(); 
    }

    ///@dev Overrides for DefaultOperatorRegistry
    function setApprovalForAll(address operator, bool approved) public override(ERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}