// SPDX-License-Identifier: MIT
// Crepto Pass NFT
// Creator: Xing @nelsonie

/**
   _____ _____  ______ _____ _______ ____    _____         _____ _____ 
  / ____|  __ \|  ____|  __ \__   __/ __ \  |  __ \ /\    / ____/ ____|
 | |    | |__) | |__  | |__) | | | | |  | | | |__) /  \  | (___| (___  
 | |    |  _  /|  __| |  ___/  | | | |  | | |  ___/ /\ \  \___ \\___ \ 
 | |____| | \ \| |____| |      | | | |__| | | |  / ____ \ ____) |___) |
  \_____|_|  \_\______|_|      |_|  \____/  |_| /_/    \_\_____/_____/ 
 
 */

pragma solidity ^0.8.6;

import "./ERC721AA.sol";
import "./EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract CreptoPass is ERC721AA, Ownable {
  using Strings for uint256;

  mapping(address => EnumerableSet.Uint16Set) ownerTokenIds;
  bytes32 public merkelRoot;
  uint256 public constant TOTAL_SUPPLY = 824;
  mapping(address => bool) public minted;

  constructor() ERC721AA("Crepto Pass", "CREPASS") {
  }

  function teamMintFor(address recipient, uint amount) external onlyOwner {
    require(totalSupply() + amount <= TOTAL_SUPPLY, "Exceed max supply");
    _safeMint(recipient, amount);
  }

  function mint(bytes32[] calldata proof, uint amount) external {
    require(!minted[msg.sender], "You have minted");
    require(totalSupply() + amount <= TOTAL_SUPPLY, "Exceed max supply");
    require(merkleVerify(proof, keccak256(abi.encodePacked(msg.sender, amount))), "Invalid proof");

    minted[msg.sender] = true;
    _safeMint(msg.sender, amount);
  }

  function merkleVerify(bytes32[] memory proof, bytes32 leaf) private view returns (bool) {
    return MerkleProof.verify(proof, merkelRoot, leaf);
  }

  function ownerTokenIdList(address owner) public view virtual returns (uint16[] memory) {
    return EnumerableSet.values(ownerTokenIds[owner]);
  }

  function toPaddingString(uint256 value) private pure returns (string memory) {
    bytes memory buffer = new bytes(3);
     buffer[2] = bytes1(uint8(48 + uint256(value % 10)));
     buffer[1] = bytes1(uint8(48 + uint256(value / 10 % 10)));
     buffer[0] = bytes1(uint8(48 + uint256(value / 100 % 10)));
    return string(buffer);
  }

  function svg(uint256 tokenId) private pure returns (string memory) {
    return string(abi.encodePacked(
      "<svg xmlns='http://www.w3.org/2000/svg' width='824' height='480'><style>@keyframes o{100%{opacity:0}}text{fill:gold;}.f{width:100%;height:100%}.a{animation:o 5s ease-out forwards}</style><rect class='f'/><svg overflow='visible'><text x='412' y='240' style='font-size:80px;text-anchor:middle'>CREPTO PASS</text><text x='624' y='400' style='font-size:24px'>NO. ",
      toPaddingString(tokenId),
      "</text></svg><rect class='f a'/></svg>"
      ));
  }

  // OVERRIDE FUNCTION
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "Nonexistent token");
    return string(abi.encodePacked(
      'data:application/json;utf8,{"name":"Crepass #',
      toPaddingString(tokenId),
      '", "description":"Crepto Pass, a Hold2Earn NFT", "created_by":"Xing", "image":"data:image/svg+xml;utf8,',
      svg(tokenId),
      '","attributes":[{"trait_type":"Membership","value":"True"}]}'
    ));
  }

  function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override {
    for (uint16 i = uint16(startTokenId); i < startTokenId + quantity; i++) {
      EnumerableSet.remove(ownerTokenIds[from], i);
      EnumerableSet.add(ownerTokenIds[to], i);
    }
  }

  function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
  }

  // ADMIN FUNCTION
  function setMerkelRoot(bytes32 _merkelRoot) external onlyOwner {
    merkelRoot = _merkelRoot;
  }

  // Hold2Earn
  address public teamAddress = 0xdACFF5227793a31e98845DC5a9910D383e59f85D;
  address public adminAddress;
  uint256 public profitRatio = 2408;

  modifier onlyAdmin() {
    require(msg.sender == adminAddress || msg.sender == owner(), "Caller is not owner or admin");
    _;
  }

  function setAdminAddress(address _adminAddress) external onlyAdmin {
    adminAddress = _adminAddress;
  }

  function setTeamAddress(address _teamAddress) external onlyOwner {
    teamAddress = _teamAddress;
  }

  function setProfitRatio(uint256 _profitRatio) external onlyOwner {
    profitRatio = _profitRatio;
  }

  receive() external payable {}

  mapping(address => uint256) public teamProfit;
  mapping(address => uint256) public ownerProfit;
  mapping(address => uint256) private ownerPendingClaim;

  struct ProfitConfig {
    address tokenAddress;
    uint256 profitPerToken;
    mapping(uint16 => bool) tokenClaimed;
  }
  uint24 public snapshotId;

  // snapshotId => ProfitConfig
  mapping(uint24 => ProfitConfig) snapshotProfitConfig;

  /**
   * For query the pending profit
   */
  function pendingProfit(address _tokenAddress) public view returns (uint256) {
    if (_tokenAddress == address(0)) {
      return address(this).balance - ownerProfit[_tokenAddress] - teamProfit[_tokenAddress];
    } else {
      return IERC20(_tokenAddress).balanceOf(address(this)) - ownerProfit[_tokenAddress] - teamProfit[_tokenAddress];
    }
  }

  /**
   * For calculate profit
   */
  function calcProfit(address _tokenAddress) external {
    uint256 totalProfit = pendingProfit(_tokenAddress);
    require(totalProfit > 10000, "Make more profit");
    uint256 forOwner = totalProfit / 10000 * profitRatio / TOTAL_SUPPLY * TOTAL_SUPPLY;
    uint256 forTeam = totalProfit - forOwner;
    ownerProfit[_tokenAddress] += forOwner;
    teamProfit[_tokenAddress] += forTeam;
  }

  /**
   * For snapshot a profit config
   */
  function snapshotProfit(address _tokenAddress) external onlyAdmin {
    require((ownerProfit[_tokenAddress] - ownerPendingClaim[_tokenAddress]) > 1 ether, "No profit");
    snapshotId += 1;
    ProfitConfig storage p = snapshotProfitConfig[snapshotId];
    p.tokenAddress = _tokenAddress;
    p.profitPerToken = (ownerProfit[_tokenAddress] - ownerPendingClaim[_tokenAddress]) / TOTAL_SUPPLY;

    ownerPendingClaim[_tokenAddress] = ownerProfit[_tokenAddress];
  }

  /**
   * For owner claim profit by owner address
   */
  function claimProfit(uint24 _snapshotId, address _owner) external {
    require(_snapshotId <= snapshotId, "No snapshot profit");

    uint16[] memory ownerTokens = ownerTokenIdList(_owner);
    uint256 profit = 0;
    for (uint16 i = 0; i < ownerTokens.length; i++) {
      if (!snapshotProfitConfig[_snapshotId].tokenClaimed[ownerTokens[i]]) {
        snapshotProfitConfig[_snapshotId].tokenClaimed[ownerTokens[i]] = true;
        profit += snapshotProfitConfig[_snapshotId].profitPerToken;
      }
    }
    require(profit > 0, "Owner has no profit");
    ownerProfit[snapshotProfitConfig[_snapshotId].tokenAddress] -= profit;
    ownerPendingClaim[snapshotProfitConfig[_snapshotId].tokenAddress] -= profit;

    _send(snapshotProfitConfig[_snapshotId].tokenAddress, payable(_owner), profit);
  }

  /**
   * For owner claim profit by tokenId (In case of an owner holds too much tokens)
   */
  function claimProfitByToken(uint24 _snapshotId, uint16[] memory _tokenIdList) external {
    require(_snapshotId <= snapshotId, "No snapshot profit");

    for (uint16 i = 0; i < _tokenIdList.length; i++) {
      if (!snapshotProfitConfig[_snapshotId].tokenClaimed[_tokenIdList[i]]) {
        snapshotProfitConfig[_snapshotId].tokenClaimed[_tokenIdList[i]] = true;
        ownerProfit[snapshotProfitConfig[_snapshotId].tokenAddress] -= snapshotProfitConfig[_snapshotId].profitPerToken;
        ownerPendingClaim[snapshotProfitConfig[_snapshotId].tokenAddress] -= snapshotProfitConfig[_snapshotId].profitPerToken;

        _send(snapshotProfitConfig[_snapshotId].tokenAddress, payable(ownerOf(_tokenIdList[i])), snapshotProfitConfig[_snapshotId].profitPerToken);
      }
    }
  }

  /**
   * For team claim profit
   */
  function teamClaimProfit(address _tokenAddress) external {
    require(teamAddress != address(0), "teamAddress not set");
    uint256 profit = teamProfit[_tokenAddress];
    require(profit > 0, "No team profit");

    teamProfit[_tokenAddress] = 0;

    _send(_tokenAddress, payable(teamAddress), profit);
  }

  function _send(address tokenAddr, address payable to, uint256 amount) private {
    if (tokenAddr == address(0)) {
      require(to.send(amount), "Transfer ETH failed");
    } else {
      require(IERC20(tokenAddr).transfer(to, amount), "Transfer Token failed");
    }
  }
}