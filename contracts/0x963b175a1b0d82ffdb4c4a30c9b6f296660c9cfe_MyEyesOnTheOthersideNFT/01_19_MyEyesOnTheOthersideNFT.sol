//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "./Apetimism.sol";

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address _to, uint256 _amount) external returns (bool);
}

contract MyEyesOnTheOthersideNFT is ERC721AQueryable, ERC2981, Ownable, Pausable, ReentrancyGuard, Apetimism {
  event Received(address, uint);
  event RoundChanged(uint8);
  event TotalMintedChanged(uint256);

  //////////////
  // Constants
  //////////////

  uint256 public MAX_SUPPLY = 800;
  uint256 public TEAM_NFT_COUNT = 0;
  uint256 public START_TOKEN_ID = 1;
  string private constant TOKEN_NAME = "My Eyes On the otherside ...";
  string private constant TOKEN_SYMBOL = "MEOTS";

  //////////////
  // Internal
  //////////////

  string private _baseURIExtended;
  bool private _isTeamNFTsMinted = false;

  address private _signer;

  mapping(address => uint256) private _addressTokenMinted;
  mapping(address => mapping(uint8 => mapping(int16 => uint256))) private _addressTokenMintedInRoundByRole;
  mapping(address => mapping(int16 => uint256)) private _addressTokenMintedInRole;

  mapping(uint256 => uint8) private _nonces;

  /////////////////////
  // Public Variables
  /////////////////////

  uint8 public currentRound = 0;
  address public teamAddress;
  bool public metadataFrozen = false;
  uint16 public maxMintPerTx = 13;
  uint16 public maxMintPerAddress = 800;

  mapping(int16 => uint256) mintPriceByRole;

  struct Role {
    string name;
    int16 role_id;
    uint256 max_mint;
    uint256 mint_price;
    bool exists;
  }
  mapping(uint16 => mapping(uint8 => mapping(int16 => Role))) public allowedRolesInRound;
  mapping(uint16 => mapping(uint8 => uint16)) public allowedRolesInRoundCount;
  mapping(uint16 => mapping(uint8 => int16[])) public allowedRolesInRoundArr;
  uint8[] public availableRounds;
  mapping(uint16 => mapping(uint8 => uint256)) public roundAllocations;
  mapping(uint16 => mapping(int16 => uint256)) public roleAllocations;
  mapping(uint8 => uint256) public totalMintedInRound;

  uint16 private allowedRolesInRoundSetId = 0;
  uint16 private roundAllocationsSetId = 0;
  uint16 private roleAllocationsSetId = 0;

  ////////////////
  // Parameters
  ////////////////

  struct RoleInRoundParams {
    uint8 round;
    int16 role;
    string roleName;
    uint256 maxMint;
    uint256 mintPrice;
  }
  struct RoundAllocationParams {
    uint8 round;
    uint256 allocation;
  }
  struct RoleAllocationParams {
    int16 role;
    uint256 allocation;
  }

  ////////////////
  // Actual Code
  ////////////////

  constructor(address apetimismAddress_)
    ERC721A(TOKEN_NAME, TOKEN_SYMBOL)
    Apetimism(apetimismAddress_, 500) {
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return START_TOKEN_ID;
  }

  //////////////////////
  // Setters for Owner
  //////////////////////

  function initialize(
    address teamAddress_,
    address signerAddress_,
    string memory baseURI_,
    address receiver_, uint96 feeNumerator_,
    uint16 maxMintPerTx_,
    uint16 maxMintPerAddress_,
    RoleInRoundParams[] memory rolesInRound_,
    RoundAllocationParams[] memory roundAllocations_,
    RoleAllocationParams[] memory roleAllocations_
  ) public onlyOwner {
    setTeamAddress(teamAddress_);
    setSignerAddress(signerAddress_);
    setBaseURI(baseURI_);
    setDefaultRoyalty(receiver_, feeNumerator_);
    setMaxMintPerTx(maxMintPerTx_);
    setMaxMintPerAddress(maxMintPerAddress_);
    addAllowedRolesInRound(rolesInRound_, true);
    addRoundsAllocation(roundAllocations_, true);
    addRolesAllocation(roleAllocations_, true);
  }

  function setCurrentRound(uint8 round_) public onlyOwner {
    currentRound = round_;
    emit RoundChanged(round_);
  }

  function setTeamAddress(address addr) public onlyOwner {
    teamAddress = addr;
  }

  function setSignerAddress(address addr) public onlyOwner {
    _signer = addr;
  }

  function setMaxMintPerTx(uint16 count) public onlyOwner {
    maxMintPerTx = count;
  }

  function setMaxMintPerAddress(uint16 count) public onlyOwner {
    maxMintPerAddress = count;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    require(!metadataFrozen, "Metadata has already been frozen");
    _baseURIExtended = baseURI;
  }

  function addAllowedRolesInRound(RoleInRoundParams[] memory params, bool replace) public onlyOwner {
    if (replace)
      allowedRolesInRoundSetId++;

    for (uint i = 0; i < params.length; i++) {
      addAllowedRoleInRound(
        params[i].round,
        params[i].role,
        params[i].roleName,
        params[i].maxMint,
        params[i].mintPrice,
        false
      );
    }
  }

  function addAllowedRoleInRound(uint8 round, int16 role, string memory roleName, uint256 maxMint, uint256 mintPrice, bool replace) public onlyOwner {
    if (replace)
      allowedRolesInRoundSetId++;

    bool role_already_existed = allowedRolesInRound[allowedRolesInRoundSetId][round][role].exists;
    allowedRolesInRound[allowedRolesInRoundSetId][round][role].name = roleName;
    allowedRolesInRound[allowedRolesInRoundSetId][round][role].role_id = role;
    allowedRolesInRound[allowedRolesInRoundSetId][round][role].max_mint = maxMint;
    allowedRolesInRound[allowedRolesInRoundSetId][round][role].mint_price = mintPrice;
    allowedRolesInRound[allowedRolesInRoundSetId][round][role].exists = true;
    if (role_already_existed) // Role already existed
      return;
    allowedRolesInRoundCount[allowedRolesInRoundSetId][round]++;

    allowedRolesInRoundArr[allowedRolesInRoundSetId][round].push(role);
  }

  function removeAllowedRoleInRound(uint8 round, int16 role) public onlyOwner {
    require(allowedRolesInRound[allowedRolesInRoundSetId][round][role].exists, "Role not existed");
    allowedRolesInRound[allowedRolesInRoundSetId][round][role].name = "";
    allowedRolesInRound[allowedRolesInRoundSetId][round][role].role_id = 0;
    allowedRolesInRound[allowedRolesInRoundSetId][round][role].max_mint = 0;
    allowedRolesInRound[allowedRolesInRoundSetId][round][role].mint_price = 0;
    allowedRolesInRound[allowedRolesInRoundSetId][round][role].exists = false;
    allowedRolesInRoundCount[allowedRolesInRoundSetId][round]--;

    // Remove available role
    for (uint8 i = 0; i < allowedRolesInRoundArr[allowedRolesInRoundSetId][round].length; i++) {
      if (allowedRolesInRoundArr[allowedRolesInRoundSetId][round][i] == role) {
        removeArrayAtInt16Index(allowedRolesInRoundArr[allowedRolesInRoundSetId][round], i);
        break;
      }
    }

    if (allowedRolesInRoundCount[allowedRolesInRoundSetId][round] == 0) {
      // Remove available round
      for (uint8 i = 0; i < availableRounds.length; i++) {
        if (availableRounds[i] == round) {
          removeArrayAtUint8Index(availableRounds, i);
          break;
        }
      }
    }
  }

  function addRoundsAllocation(RoundAllocationParams[] memory params, bool replace) public onlyOwner {
    if (replace) {
      roundAllocationsSetId++;
      delete availableRounds;
    }

    for (uint i = 0; i < params.length; i++)
      addRoundAllocation(params[i].round, params[i].allocation, false);
  }

  function addRoundAllocation(uint8 round, uint256 allocation, bool replace) public onlyOwner {
    if (replace) {
      roundAllocationsSetId++;
      delete availableRounds;
    }
    
    roundAllocations[roundAllocationsSetId][round] = allocation;

    bool found = false;
    for (uint8 i = 0; i < availableRounds.length; i++)
      if (availableRounds[i] == round)
        found = true;

    if (!found)
      availableRounds.push(round);
  }

  function addRolesAllocation(RoleAllocationParams[] memory params, bool replace) public onlyOwner {
    if (replace)
      roleAllocationsSetId++;

    for (uint i = 0; i < params.length; i++)
      addRoleAllocation(params[i].role, params[i].allocation, false);
  }

  function addRoleAllocation(int16 role, uint256 allocation, bool replace) public onlyOwner {
    if (replace)
      roleAllocationsSetId++;

    roleAllocations[roleAllocationsSetId][role] = allocation;
  }

  function freezeMetadata() public onlyOwner {
    metadataFrozen = true;
  }
  
  ////////////
  // Minting
  ////////////

  function mintTeamNFTs() public onlyOwner {
    require(teamAddress != address(0), "Team wallet not set");
    require(!_isTeamNFTsMinted, "Already minted");

    require(bytes(_baseURI()).length != 0, "baseURI not set");

    if (TEAM_NFT_COUNT > 0)
      _safeMint(teamAddress, TEAM_NFT_COUNT);

    _isTeamNFTsMinted = true;
  }

  function mint(uint256 quantity, int16 role, uint256 nonce, uint8 v, bytes32 r, bytes32 s) external payable whenNotPaused nonReentrant {
    require(currentRound != 0, "Not started");

    uint256 combined_nonce = nonce;
    if (role >= 0)
      combined_nonce = (nonce << 16) + uint16(role);

    require(_nonces[combined_nonce] == 0, "Duplicated nonce");
    require(_recoverAddress(combined_nonce, v, r, s) == _signer, "Invalid signature");

    bool is_public_round = allowedRolesInRound[allowedRolesInRoundSetId][currentRound][0].exists;
    int16 selected_role = 0;
    if (role >= 0)
      selected_role = role;

    if (!allowedRolesInRound[allowedRolesInRoundSetId][currentRound][selected_role].exists) {
      if (!is_public_round)
        require(false, "Not eligible");
      selected_role = 0;
    }

    require(_isTeamNFTsMinted, "Not ready for public");
    require(quantity > 0, "Quantity cannot be zero");
    require(totalMinted() + quantity <= MAX_SUPPLY, "Cannot mint more than maximum supply");
    if (role >= 0)
      require(maxMintableForTxForRole(msg.sender, role) >= quantity, "You have reached maximum allowed");
    else
      require(maxMintableForTxForRole(msg.sender, 0) >= quantity, "You have reached maximum allowed");
    require(mintableLeft() >= quantity, "Not enough NFT left to mint.");

    uint256 cost = quantity * allowedRolesInRound[allowedRolesInRoundSetId][currentRound][selected_role].mint_price;
    _nonces[combined_nonce] = 1;

    require(msg.value == cost, "Unmatched ether balance");

    _safeMint(msg.sender, quantity);

    totalMintedInRound[currentRound] = totalMintedInRound[currentRound] + quantity;

    _addressTokenMinted[msg.sender] = _addressTokenMinted[msg.sender] + quantity;
    _addressTokenMintedInRoundByRole[msg.sender][currentRound][selected_role] = _addressTokenMintedInRoundByRole[msg.sender][currentRound][selected_role] + quantity;
    if (selected_role >= 0)
      _addressTokenMintedInRole[msg.sender][selected_role] = _addressTokenMintedInRole[msg.sender][selected_role] + quantity;

    uint256 to_apetimism = msg.value * apetimismFee() / 10000;

    payable(apetimismAddress()).transfer(to_apetimism);
    totalRevenueShared = totalRevenueShared + to_apetimism;
  }

  function _recoverAddress(uint256 nonce, uint8 v, bytes32 r, bytes32 s) private pure returns (address) {
    bytes32 msgHash = keccak256(abi.encodePacked(nonce));
    bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
    return ecrecover(messageDigest, v, r, s);
  }

  ////////////////
  // Transfering
  ////////////////

  function transfersFrom(
    address from,
    address to,
    uint256[] calldata tokenIds
  ) public virtual {
    for (uint i = 0; i < tokenIds.length; i++)
      transferFrom(from, to, tokenIds[i]);
  }

  function safeTransfersFrom(
    address from,
    address to,
    uint256[] calldata tokenIds
  ) public virtual {
    for (uint i = 0; i < tokenIds.length; i++)
      safeTransferFrom(from, to, tokenIds[i]);
  }

  function safeTransfersFrom(
    address from,
    address to,
    uint256[] calldata tokenIds,
    bytes memory _data
  ) public virtual {
    for (uint i = 0; i < tokenIds.length; i++)
      safeTransferFrom(from, to, tokenIds[i], _data);
  }

  //////////////
  // Pausable
  //////////////

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  ///////////////////
  // Internal Views
  ///////////////////

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIExtended;
  }

  /////////////////
  // Public Views
  /////////////////

  function getAllAvailableRounds() public view returns (uint8[] memory) {
    uint256 len = availableRounds.length;
    uint8[] memory ret = new uint8[](len);
    for (uint i = 0; i < len; i++)
      ret[i] = availableRounds[i];
    return ret;
  }

  function getAllowedRolesInRoundArr(uint8 round) public view returns (int16[] memory) {
    uint256 len = allowedRolesInRoundArr[allowedRolesInRoundSetId][round].length;
    int16[] memory ret = new int16[](len);
    for (uint i = 0; i < len; i++)
      ret[i] = allowedRolesInRoundArr[allowedRolesInRoundSetId][round][i];
    return ret;
  }

  function mintPriceForCurrentRoundForRole(int16 role) public view returns (uint256) {
    return allowedRolesInRound[allowedRolesInRoundSetId][currentRound][role].mint_price;
  }

  function maxMintableForRole(address addr, int16 role) public view virtual returns (uint256) {
    uint256 minted = _addressTokenMinted[addr];
    uint256 max_mint = 0;

    // Not yet started
    if (currentRound == 0)
      return 0;
    // Total minted in this round reach the maximum allocated
    if (totalMintedInRound[currentRound] >= roundAllocations[roundAllocationsSetId][currentRound])
      return 0;
    if (_addressTokenMintedInRole[addr][role] >= roleAllocations[roleAllocationsSetId][role])
      return 0;

    if (allowedRolesInRound[allowedRolesInRoundSetId][currentRound][role].exists)
      max_mint = allowedRolesInRound[allowedRolesInRoundSetId][currentRound][role].max_mint;

    // Hit the maximum per wallet
    if (minted >= maxMintPerAddress)
      return 0;
    // Cannot mint more for this round
    if (_addressTokenMintedInRoundByRole[addr][currentRound][role] >= max_mint)
      return 0;
    // Prevent underflow
    if (totalMintedInRound[currentRound] >= roundAllocations[roundAllocationsSetId][currentRound])
      return 0;
    // Cannot mint more than allocated for role
    if (_addressTokenMintedInRole[addr][role] >= roleAllocations[roleAllocationsSetId][role])
      return 0;

    uint256 wallet_quota_left = maxMintPerAddress - minted;
    uint256 round_quota_left = max_mint - _addressTokenMintedInRoundByRole[addr][currentRound][role];
    uint256 round_allocation_quota_left = roundAllocations[roundAllocationsSetId][currentRound] - totalMintedInRound[currentRound];
    uint256 role_quota_left = roleAllocations[roleAllocationsSetId][role] - _addressTokenMintedInRole[addr][role];

    return min(mintableLeft(), min(min(min(wallet_quota_left, round_quota_left), round_allocation_quota_left), role_quota_left));
  }

  function maxMintableForTxForRole(address addr, int16 role) public view virtual returns (uint256) {
    uint256 mintable = maxMintableForRole(addr, role);

    if (mintable > maxMintPerTx)
      return maxMintPerTx;

    return mintable;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

    return bytes(_baseURI()).length != 0 ? string(abi.encodePacked(_baseURI(), Strings.toString(tokenId), ".json")) : '';
  }

  function totalMinted() public view returns (uint256) {
    return _totalMinted();
  }

  function mintableLeft() public view returns (uint256) {
    return MAX_SUPPLY - totalMinted();
  }

  ////////////
  // Helpers
  ////////////

  function removeArrayAtInt16Index(int16[] storage array, uint256 index) private {
    for (uint i = index; i < array.length - 1; i++)
      array[i] = array[i + 1];
    delete array[array.length - 1];
    array.pop();
  }

  function removeArrayAtUint8Index(uint8[] storage array, uint256 index) private {
    for (uint i = index; i < array.length - 1; i++)
      array[i] = array[i + 1];
    delete array[array.length - 1];
    array.pop();
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  ////////////
  // ERC2981
  ////////////

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId) || ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }

  function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function deleteDefaultRoyalty() public onlyOwner {
    _deleteDefaultRoyalty();
  }

  function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public onlyOwner {
    _setTokenRoyalty(tokenId, receiver, feeNumerator);
  }

  function resetTokenRoyalty(uint256 tokenId) public onlyOwner {
    _resetTokenRoyalty(tokenId);
  }

  ///////////////
  // Withdrawal
  ///////////////

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function withdrawToken(address tokenAddress) public onlyOwner {
    IERC20 tokenContract = IERC20(tokenAddress);
    tokenContract.transfer(msg.sender, tokenContract.balanceOf(address(this)));
  }

  /////////////
  // Fallback
  /////////////

  receive() external payable {
    emit Received(msg.sender, msg.value);
  }
}