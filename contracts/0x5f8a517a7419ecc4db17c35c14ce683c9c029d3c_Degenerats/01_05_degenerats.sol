// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Degenerats is Ownable, ERC721A {
  string public RATS_PROVENANCE = "0ba9c611a92735801eaa61192964ffbb4bb290ee735f29b808893ce22a9d9ec8";
  string private _baseTokenURI;

  uint256 public MAX_SUPPLY = 7777;
  uint256 public MAX_MINTS = 7;
  uint256 public PRICE = 0.01 ether;
  bool public SALE_STATE = false;
  uint256 public LAST_FREE_RAT = 1000;

  constructor() ERC721A("Degenerats", "DEGENERAT") {}

  /*     
  * Set provenance once it's calculated
  */
  function setProvenanceHash(string memory provenanceHash) public onlyOwner {
      RATS_PROVENANCE = provenanceHash;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function isSaleActive() public view returns (bool) {
    return SALE_STATE;
  }

  function setMaxSupply(uint256 max_supply) external onlyOwner {
    MAX_SUPPLY = max_supply;
  }

  function setMaxMints(uint256 max_mints) external onlyOwner {
    MAX_MINTS = max_mints;
  }

  function setPrice(uint256 price) external onlyOwner {
    PRICE = price;
  }

  function setSaleState(bool sale_state) external onlyOwner {
    SALE_STATE = sale_state;
  }

  function setLastFreeRat(uint256 last_free_rat) external onlyOwner {
    LAST_FREE_RAT = last_free_rat;
  }

  function mint(uint256 num_rats)
    external
    payable
  {
    uint256 totalSupply = totalSupply();
    require(SALE_STATE, "Sale is not active.");
    require(num_rats > 0, "Mint amount should be positive." );
    require(num_rats <= MAX_MINTS, "Mint amount exceeds max per tx." );
    require(totalSupply + num_rats <= MAX_SUPPLY, "No more rats.");
    require(totalSupply <= LAST_FREE_RAT || PRICE * num_rats <= msg.value, "Need to send more ETH.");

    _safeMint(msg.sender, num_rats);
  }

  function isPreapproved(address operator) internal pure returns (bool) {
    return (operator == 0xF849de01B080aDC3A814FaBE1E2087475cF2E354 || operator == 0x1E0049783F008A0085193E00003D00cd54003c71);
  }

  function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
      if (isPreapproved(operator)) {
          return true;
      } else {
          return super.isApprovedForAll(owner, operator);
      }
  }

  function withdrawAll() external onlyOwner {
      require(payable(msg.sender).send(address(this).balance));
  }
}