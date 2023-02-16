pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";

contract BLUR is ERC721A, Ownable {
  string private baseURI;

  bool public started = true;
  bool public claimed = false;
  uint256 public constant MAX_SUPPLY = 1081;
  uint256 public constant MAX_MINT = 1;
  uint256 public constant TEAM_CLAIM_AMOUNT = 81;

  mapping(address => uint) public addressClaimed;

  constructor() ERC721A("B.L.U.R.", "BLUR") {}

  function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
  }

  function mint() external {
    require(addressClaimed[_msgSender()] < MAX_MINT, "You have already received your B.L.U.R.");
    require(totalSupply() < MAX_SUPPLY, "All B.L.U.R. have been accounted for");
    addressClaimed[_msgSender()] += 1;
    _safeMint(msg.sender, 1);
  }

  function teamClaim() external onlyOwner {
    require(!claimed, "Team already claimed");
    _safeMint(msg.sender, TEAM_CLAIM_AMOUNT);
    claimed = true;
  }

  function setBaseURI(string memory baseURI_) external onlyOwner {
      baseURI = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
  }
}