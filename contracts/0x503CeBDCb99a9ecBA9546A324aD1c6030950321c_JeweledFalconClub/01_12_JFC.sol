// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/**
 *                        ▄▄▄,                                                                     
 *                      ▄██████▓`         ███         ███▀▀▀▀▀⌐        ▄███▀▀▀██▓▄                 
 *               ,▄▄▓▓███████└            ███         ███            ▄██▀       ╙▀                 
 *           ,▓█████████████              ███         ███           ▐██▌                           
 *        ,▄███████████████▀              ███         ███▀▀▀█⌐      ╫██▒                           
 *     ,▄█████████████████¬               ███         ██▌           ╙██▌                           
 *   ╓▓████████████████▀                  ███   ╓▄▄   ██▌       ▄▄   ╙██▓       ,#                 
 *  └▀███████   ╚████`                    ███   ▀██   ██▌      "██▀    └▀███▓▓██▀"                 
 *       └        ╟█▄                    ▓█▀                                                       
 *              ^"╙╙╙╙└─               '▀╙                                                         
 *
 *                      Jeweled Falcon Club by FOREVERCORP | 2022
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./ERC721A.sol";

contract JeweledFalconClub is ERC721A, Ownable {
  using Address for address payable;

  uint256 public constant JFC_MAX = 9990;
  uint256 public constant JFC_PREMINT = 50;
  uint256 public constant JFC_PREORDER = 112;
  uint256 public constant JFC_PRIVATE = 550 - JFC_PREORDER - JFC_PREMINT; // 388
  uint256 public constant JFC_PUBLIC = JFC_MAX - 550;

  uint256 public constant JFC_PER_TX = 100;

  uint256 public constant JFC_PRIVATE_PRICE = 0.05 ether;
  uint256 public constant JFC_PUBLIC_PRICE = 0.08 ether;

  uint256 public preordersFulfilled;
  uint256 public privateMinted;

  string public provenance;

  string private _baseTokenURI;
  string private _contractURI;

  bool public presaleLive;
  bool public saleLive;

  bool public locked;

  constructor(
    string memory newBaseTokenURI,
    string memory newContractURI
  )
    ERC721A("Jeweled Falcon Club", "JFC")
  {
    _baseTokenURI = newBaseTokenURI;
    _contractURI = newContractURI;

    _safeMint(owner(), JFC_PREMINT);
  }

  modifier notLocked {
    require(!locked, "Contract metadata is locked");
    _;
  }

  /**
   * @dev Mints preordered tokens to buyers.
   * @param recipients address[] Array of addresses to receive tokens
   */
  function fulfilPreorders(address[] calldata recipients) external onlyOwner {
    require(totalSupply() + recipients.length <= JFC_MAX, "Cannot mint anymore tokens");
    require(preordersFulfilled + recipients.length <= JFC_PREORDER, "Cannot fulfil anymore preorders");
    
    for (uint256 i = 0; i < recipients.length; i++) {
      preordersFulfilled++;
      _safeMint(recipients[i], 1);
    }
  }

  /**
   * @dev Mints number of tokens specified to wallet during presale.
   * @param quantity uint256 Number of tokens to be minted
   */
  function presaleBuy(uint256 quantity) external payable {
    require(presaleLive && !saleLive, "Presale not currently live");

    require(totalSupply() + quantity <= JFC_MAX &&
      privateMinted + quantity <= JFC_PRIVATE, "Quantity exceeds remaining tokens");
    require(quantity <= JFC_PER_TX, "Max quantity per transaction exceeded");
    require(msg.value >= quantity * JFC_PRIVATE_PRICE, "Insufficient funds");

    privateMinted += quantity;
    _safeMint(msg.sender, quantity);
  }

  /**
   * @dev Mints number of tokens specified to wallet.
   * @param quantity uint256 Number of tokens to be minted
   */
  function buy(uint256 quantity) external payable {
    require(saleLive && !presaleLive, "Sale is not currently live");
    require(totalSupply() + quantity <= JFC_MAX, "Quantity exceeds remaining tokens");
    require(quantity <= JFC_PER_TX, "Max quantity per transaction exceeded");
    require(msg.value >= quantity * JFC_PUBLIC_PRICE, "Insufficient funds");

    _safeMint(msg.sender, quantity);
  }

  /**
   * @dev Set base token URI.
   * @param newBaseURI string New URI to set
   */
  function setBaseURI(string calldata newBaseURI) external onlyOwner notLocked {
    _baseTokenURI = newBaseURI;
  }
  
  /**
   * @dev Set contract URI.
   * @param newContractURI string New URI to set
   */
  function setContractURI(string calldata newContractURI) external onlyOwner notLocked {
    _contractURI = newContractURI;
  }

  /**
   * @dev Set provenance hash.
   * @param hash string Provenance hash
   */
  function setProvenanceHash(string calldata hash) external onlyOwner notLocked {
    provenance = hash;
  }

  /**
   * @dev Toggles status of token presale. Only callable by owner.
   */
  function togglePresale() external onlyOwner {
    presaleLive = !presaleLive;
  }

  /**
   * @dev Toggles status of token sale. Only callable by owner.
   */
  function toggleSale() external onlyOwner {
    saleLive = !saleLive;
  }

  /**
   * @dev Locks contract metadata. Only callable by owner.
   */
  function lockMetadata() external onlyOwner {
    locked = true;
  }

  /**
   * @dev Returns contract URI.
   * @return string Contract URI
   */
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  /**
   * @dev Withdraw funds from contract. Only callable by owner.
   */
  function withdraw() public onlyOwner {
    payable(msg.sender).sendValue(address(this).balance);
  }

  /**
   * @dev Returns base token URI.
   * @return string Base token URI
   */
  function _baseURI() internal view override(ERC721A) returns (string memory) {
    return _baseTokenURI;
  }

  /**
   * @dev Returns starting tokenId.
   * @return uint256 Starting token Id
   */
  function _startTokenId() internal pure override(ERC721A) returns (uint256) {
    return 1;
  }
}