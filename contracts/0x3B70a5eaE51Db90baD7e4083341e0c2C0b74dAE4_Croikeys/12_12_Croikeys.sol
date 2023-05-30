// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import "openzeppelin-contracts/utils/Strings.sol";
import "ERC721A/ERC721A.sol";
import "operator-filter-registry/DefaultOperatorFilterer.sol";

// ________  ________  ________  ___  ___  __    _______       ___    ___ ________      
// |\   ____\|\   __  \|\   __  \|\  \|\  \|\  \ |\  ___ \     |\  \  /  /|\   ____\     
// \ \  \___|\ \  \|\  \ \  \|\  \ \  \ \  \/  /|\ \   __/|    \ \  \/  / | \  \___|_    
//  \ \  \    \ \   _  _\ \  \\\  \ \  \ \   ___  \ \  \_|/__   \ \    / / \ \_____  \   
//   \ \  \____\ \  \\  \\ \  \\\  \ \  \ \  \\ \  \ \  \_|\ \   \/  /  /   \|____|\  \  
//    \ \_______\ \__\\ _\\ \_______\ \__\ \__\\ \__\ \_______\__/  / /       ____\_\  \ 
//     \|_______|\|__|\|__|\|_______|\|__|\|__| \|__|\|_______|\___/ /       |\_________\
//                                                             \|___|/        \|_________|
/// @author PlaguedLabs ([email protected])

contract Croikeys is ERC721A, Ownable, DefaultOperatorFilterer {

    using Strings for uint256;

    /// ERRORS ///
    error ContractMint();
    error OutOfSupply();
    error ExceedsTxnLimit();
    error ExceedsWalletLimit();
    error InsufficientFunds();
    error MintPaused();
    error MintInactive();
    error InvalidProof();
    error InvalidTokenId();
    error BaseURILocked();

    bytes32 public merkleRoot;

    string public baseURI;
    string public unrevealedTokenURI;
    
    uint256 public PRICE = 0.01 ether;
    uint256 public SUPPLY_MAX = 555;

    bool public whitelistMintActive = false;
    bool public publicMintActive = false;
    bool public revealed = false;
    bool public baseURILocked = false;

    constructor() ERC721A("Croikeys", "Croikeys") payable {
      _mint(msg.sender, 1);
    }

    modifier mintCompliance() {
        if (msg.sender != tx.origin) revert ContractMint();
        if (_numberMinted(msg.sender) > 0) revert ExceedsWalletLimit();
        if ((totalSupply() + 1) > SUPPLY_MAX) revert OutOfSupply();
        _;
    }

    function presaleMint(bytes32[] calldata _merkleProof)
        external
        payable
        mintCompliance 
    {
        if (!whitelistMintActive) revert MintPaused();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf)) revert InvalidProof();
        _mint(msg.sender, 1);
    }

    function publicMint()
        external
        payable
        mintCompliance
    {
        if (!publicMintActive) revert MintPaused();
        if (msg.value != PRICE) revert InsufficientFunds();
        _mint(msg.sender, 1);
    }
    
    function _startTokenId()
        internal
        view
        virtual
        override returns (uint256) 
    {
        return 1;
    }

    function flipWhitelistMintStatus() public onlyOwner {
      whitelistMintActive = !whitelistMintActive;
    }

    function flipPublicMintStatus() public onlyOwner {
      publicMintActive = !publicMintActive;
    }

    function setMerkleRoot(bytes32 merkleRoot_) public onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function setPublicPrice(uint256 _price) public onlyOwner {
        PRICE = _price;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /// METADATA URI ///

    function setUnrevealedURI(string memory _unrevealedURI) public onlyOwner {
        unrevealedTokenURI = _unrevealedURI;
    }

    function _baseURI()
        internal 
        view 
        virtual
        override returns (string memory)
    {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        if (baseURILocked) revert BaseURILocked();
        baseURI = _newBaseURI;
        revealed = true;
    }

    function lockBaseURI() public onlyOwner {
        baseURILocked = true;
    }

    /// @dev Returning concatenated URI with .json as suffix on the tokenID when revealed.
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
      if (!_exists(_tokenId)) revert InvalidTokenId();
      if (revealed) return string(abi.encodePacked(_baseURI(), _tokenId.toString(), ".json")); 
      return string(abi.encodePacked(unrevealedTokenURI));
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override payable onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        payable
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}