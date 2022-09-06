// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 *  ██████████▄,            ▄▓███████▓▄           ▓████                   ▐████
 *  █████████████µ       ,▓██████████████         ╟████▌                 ▐██████
 *           ╙████      ▄████▀─     └▀████▌        ▀██████▄              ████████
 *            ████─    ]████           ████µ        └▀▀██████µ          ████⌐╟███▌
 *  █████████████▀     ╟███▌           ▐███▌             ╙████▌        ████▌  ████▄
 *  ███████████▀`      ▐████           ▓███▌               ████       ▐████    ████
 *        └████▌        █████,       ,█████      ,▄▓      ,████      ╓████     ╙████
 *          ▀████        ╙██████▓▓▓██████▀      ╙██████▓▓█████⌐      ████       ╙████
 *           ╙████▄        ╙▀█████████▀╙          ▀█████████▀       ████⌐        ╟███▌
 *
 *                                ROSA by AITX | 2022
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./ERC721A.sol";

contract ROSA is ERC721A, Ownable {
  using Address for address payable;

  uint256 public constant AITX_PREMINT = 123;
  uint256 public constant AITX_MAX = 3333;

  uint256 public constant AITX_PRICE = 0.07 ether;

  string private _baseTokenURI;
  string private _contractURI;

  bool public saleLive;

  bool public locked;

  constructor(
    string memory newBaseTokenURI,
    string memory newContractURI
  )
    ERC721A("ROSA NFT", "AITX")
  {
    _baseTokenURI = newBaseTokenURI;
    _contractURI = newContractURI;

    _safeMint(owner(), AITX_PREMINT);
  }

  modifier notLocked {
    require(!locked, "Contract metadata is locked");
    _;
  }

  /**
   * @dev Mints number of tokens specified to wallet.
   * @param _to address Receipient of tokens
   * @param quantity uint256 Number of tokens to be minted
   */
  function buy(address _to, uint256 quantity) external payable {
    require(saleLive, "Sale is not currently live");
    require(totalSupply() + quantity <= AITX_MAX, "Quantity exceeds remaining tokens");
    require(msg.value >= quantity * AITX_PRICE, "Insufficient funds");

    _safeMint(_to, quantity);
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