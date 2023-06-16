// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract GalaxyWarriorsSE is ERC721Enumerable, Ownable, AccessControl {
  using Strings for uint256;

  bytes32 public constant WHITE_LIST_ROLE = keccak256("WHITE_LIST_ROLE");

  uint256 public totalMaxSupply;
  string private _baseTokenURI = "";

  address mb = 0xDfa857c95608000B46315cdf54Fe1efcF842ab89;
  address cg = 0xD46F1A123892D48a7C9D0E4Bf3b537d1f1976AaB;

  struct Giveaway {
    address account;
    uint256 amount;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _totalMaxSupply
  ) ERC721(_name, _symbol) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(DEFAULT_ADMIN_ROLE, mb);

    _setupRole(WHITE_LIST_ROLE, msg.sender);
    _setupRole(WHITE_LIST_ROLE, mb);
    _setupRole(WHITE_LIST_ROLE, cg);

    totalMaxSupply = _totalMaxSupply;
  }

  fallback() external payable {}

  receive() external payable {}

  function giveAway(Giveaway[] calldata giveaways)
    external
    onlyRole(WHITE_LIST_ROLE)
  {
    for (uint256 i; i < giveaways.length; i++) {
      uint256 supply = totalSupply();
      require(
        supply + giveaways[i].amount <= totalMaxSupply,
        "GalaxyWarriorsSE: No items left to give away"
      );
      for (uint256 j; j < giveaways[i].amount; j++) {
        _safeMint(giveaways[i].account, supply + j);
      }
    }
  }

  function setBaseURI(string memory baseURI) public onlyRole(WHITE_LIST_ROLE) {
    _baseTokenURI = baseURI;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "GalaxyWarriorsSE: URI query for nonexistent token"
    );

    string memory baseURI = getBaseURI();
    string memory json = ".json";
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), json))
        : "";
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(_owner);

    uint256[] memory tokensId = new uint256[](tokenCount);
    for (uint256 i; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensId;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Enumerable, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function getBaseURI() public view returns (string memory) {
    return _baseTokenURI;
  }
}