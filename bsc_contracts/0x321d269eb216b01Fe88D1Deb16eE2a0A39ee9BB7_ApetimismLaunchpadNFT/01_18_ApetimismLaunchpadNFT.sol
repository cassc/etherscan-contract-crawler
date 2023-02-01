//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 
// import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address _to, uint256 _amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract ApetimismLaunchpadNFT is ERC721AQueryable, Ownable, ReentrancyGuard /*, ERC2981*/ {
  event Received(address, uint);
  event RoundChanged(uint8);
  event TotalMintedChanged(uint256);

  //////////////
  // Constants
  //////////////

  string private ERR_INVALID_SIGNATURE = "Invalid sig";
  string private ERR_DUP_NONCE = "Dup nonce";
  string private ERR_UNMATCHED_ETHER = "Unmatched ether";
  string private ERR_HIT_MAXIMUM = "Hit maximum";
  string private ERR_INVALID_AMOUNT = "Invalid amount";
  string private ERR_RUN_OUT = "Run out";

  uint256 public MAX_SUPPLY = 10000;
  uint256 public START_TOKEN_ID = 1;
  string private constant TOKEN_NAME = "Bonk shiba inu ";
  string private constant TOKEN_SYMBOL = "BONK ";

  //////////////
  // Internal
  //////////////

  mapping(address => uint256) private _addressTokenMinted;
  mapping(address => mapping(uint8 => mapping(int16 => uint256))) private _addressTokenMintedInRoundByRole;
  mapping(address => mapping(int16 => uint256)) private _addressTokenMintedInRole;

  mapping(uint256 => uint8) private _nonces;

  uint16 private allowedRolesInRoundSetId = 0;
  uint16 private roundAllocationsSetId = 0;
  uint16 private roleAllocationsSetId = 0;

  /////////////////////
  // Public Variables
  /////////////////////

  address public signerAddress = 0x98feB33d266851CEe0F2C8F88EfA8240580D2e05;

  uint8 public currentRound = 0;
  bool public metadataFrozen = false;
  uint16 public maxMintPerTx = 50;
  uint16 public maxMintPerAddress = 50;

  string public baseURIExtended;
  bool public metdataHasExtension = true;

  mapping(int16 => uint256) mintPriceByRole;

  struct Role {
    uint8 round_id;
    int16 role_id;
    uint256 max_mint;
    uint256 mint_price;
    bool exists;
  }
  mapping(uint16 => mapping(uint8 => mapping(int16 => Role))) public allowedRolesInRound;
  mapping(uint16 => mapping(uint8 => uint16)) public allowedRolesInRoundCount;
  mapping(uint16 => mapping(uint8 => int16[])) public allowedRolesInRoundArr;
  uint8[] public availableAllowedRounds;
  uint8[] public availableRounds;
  mapping(uint16 => mapping(uint8 => uint256)) public roundAllocations;
  mapping(uint16 => mapping(int16 => uint256)) public roleAllocations;
  int16[] public availableRoles;
  mapping(uint8 => uint256) public totalMintedInRound;

  uint256 public totalRevenueShared = 0;

  address public currencyAddress;

  ////////////////
  // Parameters
  ////////////////

  struct RoleInRoundParams {
    uint8 round;
    int16 role;
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

  constructor() ERC721A(TOKEN_NAME, TOKEN_SYMBOL) {
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return START_TOKEN_ID;
  }

  //////////////////////
  // Setters for Owner
  //////////////////////

  function setCurrentRound(uint8 round_) public onlyOwner {
    currentRound = round_;
    emit RoundChanged(round_);
  }

  function setMaxMintPerTx(uint16 count) public onlyOwner {
    maxMintPerTx = count;
  }

  function setMaxMintPerAddress(uint16 count) public onlyOwner {
    maxMintPerAddress = count;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    require(!metadataFrozen, "Metadata frozen");
    baseURIExtended = baseURI;
  }

  function setMetadataHasExtension(bool hasExtension) public onlyOwner {
    metdataHasExtension = hasExtension;
  }

  function setCurrencyAddress(address addr) public onlyOwner {
    currencyAddress = addr;
  }

  function addAllowedRolesInRound(RoleInRoundParams[] memory params, bool replace) public onlyOwner {
    if (replace) {
      allowedRolesInRoundSetId++;
      delete availableAllowedRounds;
    }

    for (uint i = 0; i < params.length; i++) {
      addAllowedRoleInRound(
        params[i].round,
        params[i].role,
        params[i].maxMint,
        params[i].mintPrice,
        false
      );
    }
  }

  function addAllowedRoleInRound(uint8 round, int16 role, uint256 maxMint, uint256 mintPrice, bool replace) public onlyOwner {
    if (replace) {
      allowedRolesInRoundSetId++;
      delete availableAllowedRounds;
    }

    bool role_already_existed = allowedRolesInRound[allowedRolesInRoundSetId][round][role].exists;
    allowedRolesInRound[allowedRolesInRoundSetId][round][role].round_id = round;
    allowedRolesInRound[allowedRolesInRoundSetId][round][role].role_id = role;
    allowedRolesInRound[allowedRolesInRoundSetId][round][role].max_mint = maxMint;
    allowedRolesInRound[allowedRolesInRoundSetId][round][role].mint_price = mintPrice;
    allowedRolesInRound[allowedRolesInRoundSetId][round][role].exists = true;
    if (role_already_existed) // Role already existed
      return;
    allowedRolesInRoundCount[allowedRolesInRoundSetId][round]++;

    allowedRolesInRoundArr[allowedRolesInRoundSetId][round].push(role);

    bool found = false;
    for (uint8 i = 0; i < availableAllowedRounds.length; i++)
      if (availableAllowedRounds[i] == round)
        found = true;

    if (!found)
      availableAllowedRounds.push(round);
  }

  function removeAllowedRoleInRound(uint8 round, int16 role) public onlyOwner {
    require(allowedRolesInRound[allowedRolesInRoundSetId][round][role].exists, "Role not existed");
    allowedRolesInRound[allowedRolesInRoundSetId][round][role].round_id = 0;
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
    if (replace) {
      roleAllocationsSetId++;
      delete availableRoles;
    }

    for (uint i = 0; i < params.length; i++)
      addRoleAllocation(params[i].role, params[i].allocation, false);
  }

  function addRoleAllocation(int16 role, uint256 allocation, bool replace) public onlyOwner {
    if (replace) {
      roleAllocationsSetId++;
      delete availableRoles;
    }

    roleAllocations[roleAllocationsSetId][role] = allocation;

    bool found = false;
    for (uint16 i = 0; i < availableRoles.length; i++)
      if (availableRoles[i] == role)
        found = true;

    if (!found)
      availableRoles.push(role);
  }

  function addRolesRounds(
    RoleInRoundParams[] memory rolesInRound,
    bool replaceRoleInRound,
    RoundAllocationParams[] memory roundAllocations,
    bool replaceRoundAllocations,
    RoleAllocationParams[] memory roleAllocations,
    bool replaceRoleAllocations
  ) public onlyOwner {
    addAllowedRolesInRound(rolesInRound, replaceRoleInRound);
    addRoundsAllocation(roundAllocations, replaceRoundAllocations);
    addRolesAllocation(roleAllocations, replaceRoleAllocations);
  }

  function freezeMetadata() public onlyOwner {
    metadataFrozen = true;
  }

  ////////////
  // Minting
  ////////////

  function mint(uint256 quantity, int16 role, uint16 apetimismFee, address apetimismAddress, uint256 nonce, uint8 v, bytes32 r, bytes32 s) external payable nonReentrant {
    require(currentRound != 0, "Not started");

    uint256 combined_nonce = nonce;
    if (role >= 0)
      combined_nonce = (nonce << 16) + uint16(role);

    require(_nonces[combined_nonce] == 0, ERR_DUP_NONCE);
    require(_recoverAddress(abi.encodePacked(combined_nonce, apetimismFee, apetimismAddress), v, r, s) == signerAddress, ERR_INVALID_SIGNATURE);

    bool is_public_round = allowedRolesInRound[allowedRolesInRoundSetId][currentRound][0].exists;
    int16 selected_role = 0;
    if (role >= 0)
      selected_role = role;

    if (!allowedRolesInRound[allowedRolesInRoundSetId][currentRound][selected_role].exists) {
      if (!is_public_round)
        require(false, "Not eligible");
      selected_role = 0;
    }

    require(quantity > 0, ERR_INVALID_AMOUNT);
    require(mintableLeft() >= quantity, ERR_RUN_OUT);
    if (role >= 0)
      require(maxMintableForTxForRole(msg.sender, role) >= quantity, ERR_HIT_MAXIMUM);
    else
      require(maxMintableForTxForRole(msg.sender, 0) >= quantity, ERR_HIT_MAXIMUM);

    uint256 cost = quantity * allowedRolesInRound[allowedRolesInRoundSetId][currentRound][selected_role].mint_price;
    _nonces[combined_nonce] = 1;

    if (currencyAddress != address(0)) {
      // Pay by Token
      require(msg.value == 0, ERR_UNMATCHED_ETHER);
    } else {
      require(msg.value == cost, ERR_UNMATCHED_ETHER);
    }

    _safeMint(msg.sender, quantity);

    totalMintedInRound[currentRound] = totalMintedInRound[currentRound] + quantity;

    _addressTokenMinted[msg.sender] = _addressTokenMinted[msg.sender] + quantity;
    _addressTokenMintedInRoundByRole[msg.sender][currentRound][selected_role] = _addressTokenMintedInRoundByRole[msg.sender][currentRound][selected_role] + quantity;
    if (selected_role >= 0)
      _addressTokenMintedInRole[msg.sender][selected_role] = _addressTokenMintedInRole[msg.sender][selected_role] + quantity;

    uint256 to_apetimism = cost * apetimismFee / 10000;
    if (currencyAddress != address(0)) {
      IERC20 tokenContract = IERC20(currencyAddress);
      tokenContract.transferFrom(msg.sender, address(this), cost);
      tokenContract.transfer(apetimismAddress, to_apetimism);
    } else {
      payable(apetimismAddress).transfer(to_apetimism);
    }
    totalRevenueShared = totalRevenueShared + to_apetimism;
  }

  function adminMintTo(address to, uint256 quantity) public onlyOwner {
    require(quantity > 0, ERR_INVALID_AMOUNT);
    require(mintableLeft() >= quantity, ERR_RUN_OUT);

    _safeMint(to, quantity);
  }

  //////////////
  // Apetimism
  //////////////

  function setCurrentRoundFromSignature(uint256 nonce, uint8 round, uint8 v, bytes32 r, bytes32 s) public {
    require(_nonces[nonce] == 0, ERR_DUP_NONCE);
    require(_recoverAddress(abi.encodePacked(nonce, round), v, r, s) == signerAddress, ERR_INVALID_SIGNATURE);

    _nonces[nonce] = 1;
    currentRound = round;
    emit RoundChanged(round);
  }

  function setSignerAddressFromSignature(uint256 nonce, address addr, uint8 v, bytes32 r, bytes32 s) public {
    require(_nonces[nonce] == 0, ERR_DUP_NONCE);
    require(_recoverAddress(abi.encodePacked(nonce, addr), v, r, s) == signerAddress, ERR_INVALID_SIGNATURE);

    _nonces[nonce] = 1;
    signerAddress = addr;
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

  /////////////////
  // Public Views
  /////////////////

  // function getAllAvailableRounds() public view returns (uint8[] memory) {
  //   uint256 len = availableRounds.length;
  //   uint8[] memory ret = new uint8[](len);
  //   for (uint i = 0; i < len; i++)
  //     ret[i] = availableRounds[i];
  //   return ret;
  // }

  function getAllowedRolesInRoundArr(uint8 round) public view returns (int16[] memory) {
    uint256 len = allowedRolesInRoundArr[allowedRolesInRoundSetId][round].length;
    int16[] memory ret = new int16[](len);
    for (uint i = 0; i < len; i++)
      ret[i] = allowedRolesInRoundArr[allowedRolesInRoundSetId][round][i];
    return ret;
  }

  // function getAllAvailableRoles() public view returns (int16[] memory) {
  //   uint256 len = availableRoles.length;
  //   int16[] memory ret = new int16[](len);
  //   for (uint i = 0; i < len; i++)
  //     ret[i] = availableRoles[i];
  //   return ret;
  // }

  function getAllAllowedRolesInRounds() public view returns (RoleInRoundParams[] memory) {
    uint256 len = 0;
    for (uint i = 0; i < availableAllowedRounds.length; i++)
      len += allowedRolesInRoundCount[allowedRolesInRoundSetId][ availableAllowedRounds[i] ];

    RoleInRoundParams[] memory ret = new RoleInRoundParams[](len);
    uint256 index = 0;
    for (uint i = 0; i < availableAllowedRounds.length; i++) {
      uint8 round = availableAllowedRounds[i];
      for (uint j = 0; j < allowedRolesInRoundCount[allowedRolesInRoundSetId][ availableAllowedRounds[i] ]; j++) {
        int16 role = allowedRolesInRoundArr[allowedRolesInRoundSetId][round][j];
        ret[index].round = round;
        ret[index].role = role;
        ret[index].maxMint = allowedRolesInRound[allowedRolesInRoundSetId][round][role].max_mint;
        ret[index].mintPrice = allowedRolesInRound[allowedRolesInRoundSetId][round][role].mint_price;
        index++;
      }
    }
    return ret;
  }

  function getAllRoundAllocations() public view returns (RoundAllocationParams[] memory) {
    uint256 len = availableRounds.length;
    RoundAllocationParams[] memory ret = new RoundAllocationParams[](len);
    for (uint i = 0; i < len; i++) {
      ret[i].round = availableRounds[i];
      ret[i].allocation = roundAllocations[roundAllocationsSetId][availableRounds[i]];
    }
    return ret;
  }

  function getAllRoleAllocations() public view returns (RoleAllocationParams[] memory) {
    uint256 len = availableRoles.length;
    RoleAllocationParams[] memory ret = new RoleAllocationParams[](len);
    for (uint i = 0; i < len; i++) {
      ret[i].role = availableRoles[i];
      ret[i].allocation = roleAllocations[roleAllocationsSetId][availableRoles[i]];
    }
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
    require(_exists(tokenId), 'nonexistent token');

    if (bytes(baseURIExtended).length == 0)
      return '';

    string memory extension = "";
    if (metdataHasExtension)
      extension = ".json";

    return string(abi.encodePacked(baseURIExtended, Strings.toString(tokenId), extension));
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

  function _recoverAddress(bytes memory data, uint8 v, bytes32 r, bytes32 s) private pure returns (address) {
    bytes32 msgHash = keccak256(data);
    bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
    return ecrecover(messageDigest, v, r, s);
  }

  ////////////
  // ERC2981
  ////////////

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
    return super.supportsInterface(interfaceId) || ERC721A.supportsInterface(interfaceId);
  }

  // function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
  //   return super.supportsInterface(interfaceId) || ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  // }

  // function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
  //   _setDefaultRoyalty(receiver, feeNumerator);
  // }

  // function deleteDefaultRoyalty() public onlyOwner {
  //   _deleteDefaultRoyalty();
  // }

  // function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public onlyOwner {
  //   _setTokenRoyalty(tokenId, receiver, feeNumerator);
  // }

  // function resetTokenRoyalty(uint256 tokenId) public onlyOwner {
  //   _resetTokenRoyalty(tokenId);
  // }

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