// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract GalaxyAirdrop is ERC1155, Ownable, AccessControl {
  using Strings for uint256;
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
  bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");
  uint256 public constant GALAXY_AIRDROP_ID = 0;
  bool public isAirdropActive = true;
  string public name;

  address mb = 0xDfa857c95608000B46315cdf54Fe1efcF842ab89;

  struct Airdrop {
    address account;
    uint256 amount;
  }

  event AirdropActivation(bool isActive);

  modifier whenAirdropActive() {
    require(isAirdropActive, "GalaxyAirdrop: airdrop is not active");
    _;
  }

  constructor(string memory name_) ERC1155("") {
    name = name_;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(DEFAULT_ADMIN_ROLE, mb);
  }

  function airdrop(Airdrop[] calldata airdrops)
    public
    whenAirdropActive
    onlyRole(AIRDROP_ROLE)
  {
    for (uint256 i; i < airdrops.length; i++) {
      _mint(airdrops[i].account, GALAXY_AIRDROP_ID, airdrops[i].amount, "");
    }
  }

  function setBurner(address burnerAddress) external onlyOwner {
    _setupRole(BURNER_ROLE, burnerAddress);
  }

  function toggleAirdrop() public onlyOwner {
    isAirdropActive = !isAirdropActive;
    emit AirdropActivation(isAirdropActive);
  }

  function uri(uint256 id)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(id == GALAXY_AIRDROP_ID, "GalaxyAirdrop: Invalid id");
    return super.uri(GALAXY_AIRDROP_ID);
  }

  function setURI(string memory uri_) external onlyOwner {
    _setURI(uri_);
  }

  function burn(
    address from,
    uint256 id,
    uint256 amount
  ) external onlyRole(BURNER_ROLE) {
    _burn(from, id, amount);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}