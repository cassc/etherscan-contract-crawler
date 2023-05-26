// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/**
 * @dev Implementation of CakeApp (https://www.trycake.xyz/) ERC721A Non-Fungible Token, including
 * the ERC721A Queryable extension and OpenZeppin PaymentSplitter, AccessControl and RoyaltyStandard
 */
contract CAKE721A is ERC721A, ERC721AQueryable, PaymentSplitter, AccessControl, ERC2981 {
  
  uint256 public MAX_TOKEN_SUPPLY;
  uint256 public MAX_TOTAL_MINTS_BY_ADDRESS;
  uint256 public MAX_TXN_MINT_LIMIT;
  uint256 public PRIVATE_SALE_TIMESTAMP;
  uint256 public PUBLIC_SALE_TIMESTAMP;  
  uint256 public PRICE;

  bytes32 public MERKLEROOT;  
  
  string public PROVENANCE_HASH = '';
  string public BASE_URI = '';

  bytes32 public constant PROVISIONED_ACCESS = keccak256("PROVISIONED_ACCESS");

  /**
  * @dev Initializes the contract using array objects to avoid Solidityparameter limits
  */
  constructor(
    string[] memory description, // [name, symbol]
    uint256[] memory limits, // [supply, price, maxTotalMints, maxTxnMints]
    uint256[] memory timestamps, // [privateSaleTimestamp, publicSaleTimestamp]     
    address superAdmin,
    address[] memory primaryDistRecipients,
    uint256[] memory primaryDistShares,
    address secondaryDistRecipient,
    uint96 secondaryDistShare
    ) ERC721A(description[0], description[1]) 
      PaymentSplitter(primaryDistRecipients, primaryDistShares)
    {
      require(primaryDistRecipients.length > 0, "Invalid payment address"); 
      require(superAdmin != address(0), "Admin zero_addr");
      require( primaryDistRecipients.length == primaryDistShares.length, "Invalid payment params");      

      MAX_TOKEN_SUPPLY = limits[0];
      PRICE = limits[1];
      MAX_TOTAL_MINTS_BY_ADDRESS = limits[2];
      MAX_TXN_MINT_LIMIT = limits[3];

      PRIVATE_SALE_TIMESTAMP = timestamps[0];
      PUBLIC_SALE_TIMESTAMP = timestamps[1];      

      _grantRole(DEFAULT_ADMIN_ROLE, superAdmin);
      _grantRole(PROVISIONED_ACCESS, superAdmin);
      _setDefaultRoyalty(secondaryDistRecipient, secondaryDistShare);    

  }

  /**
  * @dev See {IERC165-supportsInterface}.
  */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721A, IERC721A, AccessControl, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /**
  * @dev Multi-purpose mint function able to execute public mints, presale mints and 
  * Paper.xyz-enabled dApp (https://docs.paper.xyz/reference/mintmethod) mints
  */
  function mint(address to, uint256 quantity, bytes32[] calldata proof) external payable {
    string memory eligibilityCheck = checkMintEligibilityMethod(to, quantity, proof, msg.value); 
    require(bytes(eligibilityCheck).length==0, eligibilityCheck);
    _mint(to, quantity);
  }

  /**
  * @dev onlyAdmin function that enables non-payable mint
  */
  function reserveTokens(address to, uint256 quantity) external onlyRole(PROVISIONED_ACCESS) {  
    require(totalSupply() + quantity <= MAX_TOKEN_SUPPLY, 'Invalid');    
    _mint(to, quantity);
  }
  
  /**
  * @dev Ensure valid conditions prior to mint. Meets requirements for Paper.xyz
  * eligibilityMethod (https://docs.paper.xyz/reference/eligibilitymethod)
  */
  function checkMintEligibilityMethod(address to, uint256 quantity, bytes32[] calldata proof, uint256 value) public view returns(string memory) {
    
    require(to!= address(0), "Invalid addr");
    require(block.timestamp >= PRIVATE_SALE_TIMESTAMP || block.timestamp >= PUBLIC_SALE_TIMESTAMP, 'Inactive');
    
    if(block.timestamp < PUBLIC_SALE_TIMESTAMP){
      require(verifyWhitelistMembership(proof, to), "Unauthroized");
    }

    require(totalSupply() + quantity <= MAX_TOKEN_SUPPLY, 'Exceeds supply');  
    
    if(MAX_TXN_MINT_LIMIT > 0){
     require(quantity <= MAX_TXN_MINT_LIMIT, 'Exceeds limit'); 
    }

    if(MAX_TOTAL_MINTS_BY_ADDRESS > 0){
     require(balanceOf(to) + quantity <= MAX_TOTAL_MINTS_BY_ADDRESS, 'Exceeds total'); 
    }

    if(PRICE > 0){
      require(value >= PRICE * quantity , 'Invalid value');
    }
          
    return '';
  }

  /**
  * @dev Merkleproof implementation for presale mints.  
  */
  function verifyWhitelistMembership(bytes32[] calldata proof, address _address) internal view returns (bool){        
    bytes32 leaf = keccak256(abi.encodePacked(_address));        
    return MerkleProof.verify(proof, MERKLEROOT, leaf);
  }  

  /**
  * @dev onlyAdmin merkleproof setter.
  */
  function setMerkleroot(bytes32 merkleroot) external onlyRole(PROVISIONED_ACCESS) {
    MERKLEROOT = merkleroot;
  }

  /**
  * @dev onlyAdmin setter for mutable state variables. Combined to conserve byte-space.
  */
  function setContractParams(uint256 supply, uint256 maxTotal, uint256 maxTxn, uint256 price) external onlyRole(PROVISIONED_ACCESS) {
    require(supply >= totalSupply(), 'Invalid supply');
    MAX_TOKEN_SUPPLY = supply;
    MAX_TOTAL_MINTS_BY_ADDRESS = maxTotal;
    MAX_TXN_MINT_LIMIT = maxTxn;
    PRICE = price;
  }

  /**
  * @dev onlyAdmin setter for mutable timestamp variables. Combined to conserve byte-space.
  */
  function setTimestamps(uint256 preSale, uint256 publicSale) external onlyRole(PROVISIONED_ACCESS) {
    require(preSale >= 0 && publicSale >= 0, 'Invalid timestamp');
    PRIVATE_SALE_TIMESTAMP = preSale;
    PUBLIC_SALE_TIMESTAMP = publicSale;
  }

  /**
  * @dev onlyAdmin provenance hash setter.
  */
  function setProvenanceHash(string calldata provenanceHash) external onlyRole(PROVISIONED_ACCESS) {
    require(bytes(PROVENANCE_HASH).length==0, 'Invalid');
    PROVENANCE_HASH = provenanceHash;
  }

  /**
  * @dev onlyAdmin baseURI setter
  */
  function setBaseURI(string calldata baseURI) external onlyRole(PROVISIONED_ACCESS) {
    BASE_URI = baseURI;
  }

  /**
  * @dev Override ERC721A baseURI to be BASE_URI
  */
  function _baseURI() internal view override returns (string memory) {
    return BASE_URI;
  }

}