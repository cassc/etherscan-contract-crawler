// SPDX-License-Identifier: MIT

// Made with love by pr0xy

pragma solidity ^0.8.7;

import './ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/finance/PaymentSplitter.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract PowPow is ERC721A, ERC2981, Ownable, ReentrancyGuard, PaymentSplitter {
    // Recipients of funds from token sales.
    address[] private payees;

    // Root for merkle tree containing presale participants.
    bytes32 public merkleRoot;

    // Reference to metadata.
    string public baseURI;

    // Amount of ether required for a single token.
    uint public price;

    // Sale controller.
    uint public status;

    // Tokens per wallet limit for public sale.
    uint public walletLimit;

    // Max supply of tokens.
    uint public constant MAX_SUPPLY = 2222;

    constructor(address[] memory _payees, uint[] memory _shares) ERC721A('PowPow', 'POWPOW') PaymentSplitter(_payees, _shares) {
        payees = _payees;
    }

    /**
      @dev Override for the reference to metadata.
    */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
      @dev Override to begin token id at 1.
    */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
      @dev Sets reference to the metadata.
    */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /**
      @dev Sets the merkle root to be used in presale.
    */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
      @dev Sets the price to be used in presale and public mint functions.
    */
    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }

    /**
      @dev Sets the royalty fee and recieving address for the collection.
    */
    function setRoyalty(address receiver, uint96 feeBasisPoints) external onlyOwner {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    /**
      @dev Sets the status to change between minting periods.
    */
    function setStatus(uint _status) external onlyOwner {
        status = _status;
    }

    /**
      @dev Sets the token limit per wallet for public sale. 
    */
    function setWalletLimit(uint _walletLimit) external onlyOwner {
        walletLimit = _walletLimit;
    }

    /**
      @dev Returns tokens minted by an address.
    */
    function numberMinted(address owner) external view returns (uint) {
        return _numberMinted(owner);
    }

    /**
      @dev Presale minting function that is limited to the participants included within the merkle tree.
    */
    function presale(bytes32[] calldata _merkleProof, uint _amount, uint _max) external nonReentrant payable {
        require(status == 1, 'POW: presale period is not open');
        require(msg.value == price * _amount, 'POW: insufficent ether provided');
        require(tx.origin == msg.sender, 'POW: contract interactions are not permitted');
        require(_totalMinted() + _amount <= MAX_SUPPLY, 'POW: all tokens have been minted');
        require(_numberMinted(msg.sender) + _amount <= _max, 'POW: provided amount exceeds allocated mints');
        require(MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender, _max))), 'POW: leaf is not a member of the merkle tree');

        _safeMint(msg.sender, _amount);
    }

    /**
      @dev Public minting function that is limited to a mint amount of 2 tokens per wallet.
    */
    function mint(uint _amount) external nonReentrant payable {
        require(status == 2, 'POW: public sale period is not open');
        require(msg.value == price * _amount, 'POW: insufficent ether provided');
        require(tx.origin == msg.sender, 'POW: contract interactions are not permitted');
        require(_amount + _numberMinted(msg.sender) <= walletLimit, 'POW: provided amount exceeds allocated mints');
        require(_totalMinted() + _amount <= MAX_SUPPLY, 'POW: all tokens have been minted');

        _safeMint(msg.sender, _amount);
    }

   /**
      @dev Releases ether from contract. 
    */
    function releaseTotal() external nonReentrant {
        for(uint256 i; i < payees.length; i++){
            release(payable(payees[i]));
        }
    }
   
   /**
      @dev Releases provided token from contract. 
    */
    function releaseTotal(IERC20 token) external nonReentrant {
        for(uint256 i; i < payees.length; i++){
            release(token, payable(payees[i]));
        }
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}