// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import './ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/finance/PaymentSplitter.sol';

contract FridayBeers is ERC721A, ERC2981, Ownable, ReentrancyGuard, PaymentSplitter {    
    // Fund recipients.
    address[] private payees;

    // Merkle root for the merkle tree that contains presale participants.
    bytes32 public merkleRoot;

    // Reference to the storage of the images and metadata.
    string public baseURI;

    // The SHA-256 hash of the SHA-256 hashes of all images. 
    string public provenance;

    // Amount of ether required to mint a single token.
    uint256 public price;

    // Indicates whether the collection is in a non-minting or minting period.
    uint256 public status;

    // Max supply of tokens that can ever exist in the collection.
    uint256 public constant MAX_SUPPLY = 5555;

    constructor(address[] memory _payees, uint256[] memory _shares) ERC721A('FridayBeers', 'FB') PaymentSplitter(_payees, _shares) {
        payees = _payees;
    }

    /**
        @dev Sets reference to the `baseURI` variable which will reference the storage of the images and metadata and be used in the `_baseURI()` and `tokenURI()` functions.
    */
    function setBaseURI(string calldata baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    /**
        @dev Sets the `merkleRoot` variable to be used in `presale()` function.
    */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
      @dev Sets the `price` variable to be used in `presale()` and `mint()` functions.
    */
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    /**
      @dev Sets the `provenance` value to SHA-256 hash to add fairness to the distribution of tokens.
    */
    function setProvenance(string calldata _provenance) external onlyOwner {
        provenance = _provenance;
    }

    /**
      @dev Sets the royalty fee and recipient for the collection.
    */
    function setRoyalty(address receiver, uint96 feeBasisPoints) external onlyOwner {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    /**
      @dev Sets the `status` variable to change between non-minting and different minting periods.
    */
    function setStatus(uint256 _status) external onlyOwner {
        status = _status;
    }

    /**
      @dev Returns the amount of tokens minted by a given address.
    */
    function numberMinted(address _owner) external view returns (uint256) {
        return _numberMinted(_owner);
    }

    /**
      @dev Gift minting function with restrictions on `status` and value of `_amount`. 
    */
    function gift(address _recipient, uint256 _amount) external nonReentrant onlyOwner {
        require(status == 1, 'FB: gift period is not open');
        require(_totalMinted() + _amount <= MAX_SUPPLY, 'FB: all tokens have been minted');

        _mint(_recipient, _amount);
    }

    /**
      @dev Presale minting period that is limited to the participants included within the merkle tree with restrictions on `status`, value of the msg, sender of the msg, and value of `_amount`.
    */
    function presale(bytes32[] calldata _merkleProof, uint256 _amount) external nonReentrant payable {
        require(status == 2, 'FB: presale period is not open');
        require(msg.value == price * _amount, 'FB: insufficent ether provided');
        require(tx.origin == msg.sender, 'FB: contract interactions are not permitted');
        require(_totalMinted() + _amount <= MAX_SUPPLY, 'FB: all tokens have been minted');
        require(_numberMinted(msg.sender) + _amount < 3, 'FB: provided amount is more than the allowed mint quantity');
        require(MerkleProof.verifyCalldata(_merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), 'FB: leaf is not a member of the merkle tree');

        _mint(msg.sender, _amount);
    }

    /**
      @dev Public minting function with restrictions on `status`, value of the msg, sender of the msg, and value of `_amount`. 
    */
    function mint(uint256 _amount) external nonReentrant payable {
        require(status == 3, 'FB: public sale period is not open');
        require(msg.value == price * _amount, 'FB: insufficent ether provided');
        require(tx.origin == msg.sender, 'FB: contract interactions are not permitted');
        require(_numberMinted(msg.sender) + _amount < 4, 'FB: provided amount is more than the allowed mint quantity');
        require(_totalMinted() + _amount <= MAX_SUPPLY, 'FB: all tokens have been minted');

        _mint(msg.sender, _amount);
    }

    /**
      @dev Releases ether from contract.
    */
    function releaseTotal() external nonReentrant {
        for(uint256 i; i < payees.length; ++i){
            release(payable(payees[i]));
        }
    }

    /**
      @dev Override to return the local version of `baseURI`. 
    */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
      @dev Override to set the starting token Id. 
    */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}