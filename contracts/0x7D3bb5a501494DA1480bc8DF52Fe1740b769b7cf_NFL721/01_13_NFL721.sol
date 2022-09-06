pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFL721 is ERC721A, Pausable, Ownable {
  uint public constant NUM_NFL_TEAMS = 32;
  uint public PRICE;
  uint public TEAM_MAX;
  uint public SALE_MAX;
  uint public SELLING_AMOUNT;
  string public BASE_URI;
  string public CONTRACT_URI = "https://presalemetadata.mythical.market/rarityleague/contractmetadata";

  // array of teams currently on sale
  uint8[] private _teamsOnSale;
  // from teamId to index of teamsOnSale array
  mapping(uint8 => uint8) private _teamIdIndex;

  struct TeamData {
    // if team has been sold previously
    bool sold;
    // if team is currently for sale
    bool isSelling;
    // team current supply
    uint supply;
  }
  mapping(uint8 => TeamData) private _teamData;

  event MintSupplyRemaining(uint8 teamId, uint remainingSupply);
  event CreateSale(uint8[] teams, uint withHoldAmount);
  event SaleEnd(uint8 teamId);

  constructor(uint teamMax, uint _price, string memory __baseURI) ERC721A("Rarity League", "RL") {
    TEAM_MAX = teamMax;
    PRICE = _price;
    BASE_URI = __baseURI;
  }

  function renounceOwnership() public view override onlyOwner {
    revert('can only transfer ownership');
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function getTeamsOnSale() external view returns (uint8[] memory) {
    return _teamsOnSale;
  }

  function getRemainingSupply(uint8 teamId) external view returns (uint) {
    require(_teamData[teamId].isSelling == true, "team not on sale");
    return SELLING_AMOUNT - _teamData[teamId].supply;
  }

  function teamOf(uint256 tokenId) external view returns (uint8) {
    return _ownershipOf(tokenId).teamId;
  }

  function setBaseURI(string memory baseURI) external onlyOwner {
    BASE_URI = baseURI;
  }

  function setPrice(uint _price) public onlyOwner {
    PRICE = _price;
  }

  function _baseURI() internal view override returns (string memory) {
    return BASE_URI;
  }

  function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
  }

  function setContractURI(string memory _contractURI) external onlyOwner {
    CONTRACT_URI = _contractURI;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success);
  }

  function createSale(uint8[] memory teams, uint withHoldAmount) external onlyOwner {
    require(_teamsOnSale.length == 0, "must end sale first");
    require(withHoldAmount < TEAM_MAX, "can't withhold more than selling");
    SELLING_AMOUNT = TEAM_MAX - withHoldAmount;
    SALE_MAX = _totalMinted() + SELLING_AMOUNT * teams.length;

    for (uint8 i = 0; i < teams.length; i++) {
      require(_teamData[teams[i]].sold == false, "team in sale");
      require(_teamData[teams[i]].isSelling == false, "no duplicates allowed");
      require(teams[i] > 0 && teams[i] <= NUM_NFL_TEAMS, "only 32 NFL teams");
      _teamData[teams[i]].isSelling = true;
      _teamIdIndex[teams[i]] = i;
    }
    _teamsOnSale = teams;
    emit CreateSale(teams, withHoldAmount);
  }


  function endSale() external onlyOwner {
    require(_teamsOnSale.length > 0, "can only end active sales");
    for (uint8 i = 0; i < _teamsOnSale.length; i++) {
      _teamData[_teamsOnSale[i]].sold = true;
      _teamData[_teamsOnSale[i]].isSelling = false;
      delete _teamIdIndex[i];
      emit SaleEnd(_teamsOnSale[i]);
    }
    delete _teamsOnSale;
  }

  function adminMint(uint quantity, uint8 teamId) external onlyOwner whenNotPaused {
    require(_teamsOnSale.length < 1, "cannot admin mint during sale");
    require(_teamData[teamId].sold == true, "sale must have ended");
    require(_teamData[teamId].isSelling == false, "sale must have ended");
    require(_teamData[teamId].supply + quantity <= TEAM_MAX, "exceeds team supply");
    _teamData[teamId].supply += quantity;
    _safeMint(msg.sender, quantity, teamId);
  }

  function specificMint(uint quantity, uint8 teamId) external payable whenNotPaused {
    require(quantity < 51, "limit of 50 per transaction");
    require(_teamData[teamId].isSelling == true, "team not on sale");
    require(_teamData[teamId].supply + quantity <= SELLING_AMOUNT, "purchase exceeds allotted team supply");
    require(msg.value >= PRICE * quantity, "incorrect eth sent");
    // update team supply
    _teamData[teamId].supply += quantity;
    emit MintSupplyRemaining(teamId,  SELLING_AMOUNT - _teamData[teamId].supply);
    if (_teamData[teamId].supply == SELLING_AMOUNT) {
      _removeTeamFromSale(teamId);
    }
    _safeMint(msg.sender, quantity, teamId);
  }


  function mint(uint quantity, uint8 teamId, address recipient) external payable whenNotPaused {
    require(quantity < 51, "limit of 50 per transaction");
    require(_teamData[teamId].isSelling == true, "team not on sale");
    require(_teamData[teamId].supply + quantity <= SELLING_AMOUNT, "purchase exceeds allotted team supply");
    require(msg.value >= PRICE * quantity, "incorrect eth sent");
    // update team supply
    _teamData[teamId].supply += quantity;
    emit MintSupplyRemaining(teamId,  SELLING_AMOUNT - _teamData[teamId].supply);
    if (_teamData[teamId].supply == SELLING_AMOUNT) {
      _removeTeamFromSale(teamId);
    }
    _safeMint(recipient, quantity, teamId);
  }


  function _removeTeamFromSale(uint8 teamId) internal {
    require(_teamData[teamId].isSelling == true, "team not on sale");
    uint lastTeamIndex = _teamsOnSale.length - 1;
    uint8 index = _teamIdIndex[teamId];
    // if last element in array, no need to swap before pop
    if (index != lastTeamIndex) {
      uint8 lastTeamId = _teamsOnSale[lastTeamIndex];
      _teamsOnSale[index] = lastTeamId;
      _teamIdIndex[lastTeamId] = index;
    }
    _teamsOnSale.pop();
    delete _teamIdIndex[teamId];
    _teamData[teamId].sold = true;
    _teamData[teamId].isSelling = false;

    emit SaleEnd(teamId);
  }


}