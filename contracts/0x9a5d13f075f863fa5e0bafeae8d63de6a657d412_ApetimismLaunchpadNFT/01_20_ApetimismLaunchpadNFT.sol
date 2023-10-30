// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract ApetimismLaunchpadNFT is ERC721AQueryable, Ownable, ReentrancyGuard {
  event RoundChanged(uint256 indexed);
  event TotalMintedChanged(uint256 indexed);

  ///////////
  // Errors
  ///////////

  error InvalidSignature();
  error DuplicatedNonce();
  error HitMaximum();
  error InvalidAmount();
  error RunOut();
  error NotEligible();
  error NotStarted();
  error RoleNotExisted();
  error MetadataFrozen();
  error NonExistentToken();
  error UnmatchedEther();
  error EtherNotSent();

  //////////////
  // Constants
  //////////////

  uint256 public constant MAX_SUPPLY = 299999905;
  uint256 private constant START_TOKEN_ID = 0;
  string private constant TOKEN_NAME = "Raven Insurrectionist Forces";
  string private constant TOKEN_SYMBOL = "RVNIF";

  //////////////
  // Internal
  //////////////

  mapping(address => uint256) private _addressTokenMinted;
  mapping(address => mapping(uint256 => mapping(int256 => uint256))) private _addressTokenMintedInRoundByRole;
  mapping(address => mapping(int256 => uint256)) private _addressTokenMintedInRole;

  mapping(uint256 => uint256) private _nonces;

  mapping(uint256 => mapping(uint256 => mapping(int256 => Role))) private allowedRolesInRound;
  mapping(uint256 => mapping(uint256 => uint256)) private allowedRolesInRoundCount;
  mapping(uint256 => mapping(uint256 => int256[])) private allowedRolesInRoundArr;
  uint256[] private availableAllowedRounds;
  uint256[] private availableRounds;
  mapping(uint256 => mapping(uint256 => uint256)) private roundAllocations;
  mapping(uint256 => mapping(int256 => uint256)) private roleAllocations;
  int256[] private availableRoles;

  mapping(uint256 => uint256) private totalMintedInRound;

  uint256 private allowedRolesInRoundSetId;
  uint256 private roundAllocationsSetId;
  uint256 private roleAllocationsSetId;

  bool private metadataFrozen;
  uint256 private maxMintPerTx = 100000000;
  uint256 private maxMintPerAddress = 100000000;
  string private baseURIExtended;
  bool private isSingleMetadata = false;
  bool private metadataHasExtension = true;

  /////////////////////
  // Public Variables
  /////////////////////

  address public signerAddress = 0x6cEb04aFE583f03F599188F5C475fE74069AB34d;

  uint256 public currentRound;

  struct Role {
    uint256 round_id;
    int256 role_id;
    uint256 max_mint;
    uint256 mint_price;
    bool exists;
  }

  address public currencyAddress;

  ////////////////
  // Parameters
  ////////////////

  struct RoleInRoundParams {
    uint256 round;
    int256 role;
    uint256 maxMint;
    uint256 mintPrice;
  }
  struct RoundAllocationParams {
    uint256 round;
    uint256 allocation;
  }
  struct RoleAllocationParams {
    int256 role;
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

  function setCurrentRound(uint256 round_) public onlyOwner {
    currentRound = round_;
    emit RoundChanged(round_);
  }

  function setMaxMintPerTx(uint256 count) external onlyOwner {
    maxMintPerTx = count;
  }

  function setMaxMintPerAddress(uint256 count) external onlyOwner {
    maxMintPerAddress = count;
  }

  function setBaseURI(string memory baseURI) external onlyOwner {
    if (metadataFrozen)
      revert MetadataFrozen();
    baseURIExtended = baseURI;
  }

  function setMetadataHasExtension(bool hasExtension) external onlyOwner {
    metadataHasExtension = hasExtension;
  }

  function setIsSingleMetadata(bool _isSingleMetadata) external onlyOwner {
    isSingleMetadata = _isSingleMetadata;
  }

  function setCurrencyAddress(address addr) external onlyOwner {
    currencyAddress = addr;
  }

  function addAllowedRolesInRound(RoleInRoundParams[] memory params, bool replace) public onlyOwner {
    if (replace) {
      allowedRolesInRoundSetId++;
      delete availableAllowedRounds;
    }

    mapping(uint256 => mapping(int256 => Role)) storage _currentAllowedRolesInRound = allowedRolesInRound[allowedRolesInRoundSetId];
    mapping(uint256 => uint256) storage _currentAllowedRolesInRoundCount = allowedRolesInRoundCount[allowedRolesInRoundSetId];
    mapping(uint256 => int256[]) storage _currentAllowedRolesInRoundArr = allowedRolesInRoundArr[allowedRolesInRoundSetId];

    unchecked {
      for (uint i; i < params.length; ++i) {
        RoleInRoundParams memory param = params[i];
        uint256 round = param.round;

        Role storage allowedRole = _currentAllowedRolesInRound[round][param.role];

        allowedRole.round_id = round;
        allowedRole.role_id = param.role;
        allowedRole.max_mint = param.maxMint;
        allowedRole.mint_price = param.mintPrice;
        if (allowedRole.exists) // Role already existed
          continue;
        allowedRole.exists = true;

        _currentAllowedRolesInRoundCount[round]++;

        _currentAllowedRolesInRoundArr[round].push(param.role);

        if (!_existedInUint256Array(availableAllowedRounds, round))
          availableAllowedRounds.push(round);
      }
    }
  }

  function removeAllowedRoleInRound(uint256 round, int256 role) public onlyOwner {
    Role storage allowedRole = allowedRolesInRound[allowedRolesInRoundSetId][round][role];
    mapping(uint256 => uint256) storage _allowedRolesInRoundCount =
      allowedRolesInRoundCount[allowedRolesInRoundSetId];

    if (!allowedRole.exists)
      revert RoleNotExisted();
    allowedRole.round_id = 0;
    allowedRole.role_id = 0;
    allowedRole.max_mint = 0;
    allowedRole.mint_price = 0;
    allowedRole.exists = false;
    _allowedRolesInRoundCount[round]--;

    // Remove available role
    int256[] storage _allowedRolesInRound = allowedRolesInRoundArr[allowedRolesInRoundSetId][round];
    uint256 len = _allowedRolesInRound.length;
    for (uint i = 0; i < len; i++) {
      if (_allowedRolesInRound[i] == role) {
        removeArrayAtInt256Index(_allowedRolesInRound, i);
        break;
      }
    }

    if (_allowedRolesInRoundCount[round] == 0) {
      // Remove available round
      len = availableRounds.length;
      for (uint i = 0; i < len; i++) {
        if (availableRounds[i] == round) {
          removeArrayAtUint256Index(availableRounds, i);
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

    mapping(uint256 => uint256) storage _currentRoundAllocations = roundAllocations[roundAllocationsSetId];

    unchecked {
      for (uint i = 0; i < params.length; i++) {
        RoundAllocationParams memory param = params[i];
        uint256 round = param.round;

        _currentRoundAllocations[round] = param.allocation;

        if (!_existedInUint256Array(availableRounds, round))
          availableRounds.push(round);
      }
    }
  }

  function addRolesAllocation(RoleAllocationParams[] memory params, bool replace) public onlyOwner {
    if (replace) {
      roleAllocationsSetId++;
      delete availableRoles;
    }

    mapping(int256 => uint256) storage _currentRoleAllocations = roleAllocations[roleAllocationsSetId];

    unchecked {
      for (uint i = 0; i < params.length; i++) {
        RoleAllocationParams memory param = params[i];

        _currentRoleAllocations[param.role] = param.allocation;

        bool existed = false;
        uint256 len = availableRoles.length;
        for (uint j = 0; j < len; j++)
          if (availableRoles[j] == param.role)
            existed = true;

        if (!existed)
          availableRoles.push(param.role);
      }
    }
  }

  function addRolesRounds(
    RoleInRoundParams[] memory _rolesInRound,
    bool _replaceRoleInRound,
    RoundAllocationParams[] memory _roundAllocations,
    bool _replaceRoundAllocations,
    RoleAllocationParams[] memory _roleAllocations,
    bool _replaceRoleAllocations
  ) external onlyOwner {
    addAllowedRolesInRound(_rolesInRound, _replaceRoleInRound);
    addRoundsAllocation(_roundAllocations, _replaceRoundAllocations);
    addRolesAllocation(_roleAllocations, _replaceRoleAllocations);
  }

  function freezeMetadata() external onlyOwner {
    metadataFrozen = true;
  }

  ////////////
  // Minting
  ////////////

  function mint(uint256 quantity, int256 role, uint256 apetimismFee, address apetimismAddress, uint256 nonce, uint8 v, bytes32 r, bytes32 s) external payable nonReentrant {
    if (currentRound == 0)
      revert NotStarted();

    uint256 combined_nonce = nonce;
    if (role >= 0)
      combined_nonce = (nonce << 16) + uint256(role);

    _validateNonceAndSignature(combined_nonce, abi.encodePacked(combined_nonce, apetimismFee, apetimismAddress), v, r, s);

    mapping(int256 => Role) storage allowedRolesInCurrentRound =
      allowedRolesInRound[allowedRolesInRoundSetId][currentRound];

    int256 selected_role = 0;
    if (role >= 0)
      selected_role = role;

    if (!allowedRolesInCurrentRound[selected_role].exists) {
      if (!allowedRolesInCurrentRound[0].exists) // Revert if Public Role is NOT allowed in this round
        revert NotEligible();
      selected_role = 0;
    }

    _validateQuantity(quantity);

    // Check for Role Quota
    {
      int256 _roleToCheck = 0;
      if (role >= 0)
        _roleToCheck = role;
      if (maxMintableForTxForRole(msg.sender, _roleToCheck) < quantity)
        revert HitMaximum();
    }

    uint256 cost = quantity * allowedRolesInCurrentRound[selected_role].mint_price;
    _nonces[combined_nonce] = 1;

    // Check the Ether value
    {
      uint256 _expectedValue = cost;
      // Pay by Token
      if (currencyAddress != address(0))
        _expectedValue = 0;
      if (msg.value != _expectedValue)
        revert UnmatchedEther();
    }

    _safeMint(msg.sender, quantity);

    totalMintedInRound[currentRound] += quantity;

    _addressTokenMinted[msg.sender] += quantity;
    _addressTokenMintedInRoundByRole[msg.sender][currentRound][selected_role] += quantity;
    _addressTokenMintedInRole[msg.sender][selected_role] += quantity;

    uint256 to_apetimism = cost * apetimismFee / 10000;
    if (currencyAddress != address(0)) {
      // Pay by Token
      IERC20 tokenContract = IERC20(currencyAddress);
      tokenContract.transferFrom(msg.sender, address(this), cost);
      tokenContract.transfer(apetimismAddress, to_apetimism);
    } else {
      // Pay by Native Coin
      _transferEth(payable(apetimismAddress), to_apetimism);
    }
  }

  function adminMintTo(address to, uint256 quantity) external onlyOwner {
    _validateQuantity(quantity);

    _safeMint(to, quantity);
  }

  //////////////
  // Apetimism
  //////////////

  function setCurrentRoundFromSignature(uint256 nonce, uint256 round, uint8 v, bytes32 r, bytes32 s) public {
    _validateNonceAndSignature(nonce, abi.encodePacked(nonce, round), v, r, s);

    _nonces[nonce] = 1;
    setCurrentRound(round);
  }

  function setSignerAddressFromSignature(uint256 nonce, address addr, uint8 v, bytes32 r, bytes32 s) public {
    _validateNonceAndSignature(nonce, abi.encodePacked(nonce, addr), v, r, s);

    _nonces[nonce] = 1;
    signerAddress = addr;
  }

  ///////////////
  // Validators
  ///////////////

  function _validateQuantity(uint256 quantity) private view {
    if (quantity <= 0)
      revert InvalidAmount();
    if (mintableLeft() < quantity)
      revert RunOut();
  }

  function _validateNonceAndSignature(uint256 nonce, bytes memory data, uint8 v, bytes32 r, bytes32 s) private view {
    if (_nonces[nonce] != 0)
      revert DuplicatedNonce();
    if (_recoverAddress(data, v, r, s) != signerAddress)
      revert InvalidSignature();
  }

  ////////////////
  // Transfering
  ////////////////

  function transfersFrom(
    address from,
    address to,
    uint256[] memory tokenIds
  ) public virtual {
    for (uint i = 0; i < tokenIds.length; i++)
      transferFrom(from, to, tokenIds[i]);
  }

  function safeTransfersFrom(
    address from,
    address to,
    uint256[] memory tokenIds,
    bytes memory _data
  ) public virtual {
    for (uint i = 0; i < tokenIds.length; i++)
      safeTransferFrom(from, to, tokenIds[i], _data);
  }

  /////////////////
  // Public Views
  /////////////////

  function getConfigs() public view returns (bool, uint256, uint256, string memory, bool, bool) {
    return (metadataFrozen, maxMintPerTx, maxMintPerAddress, baseURIExtended, metadataHasExtension, isSingleMetadata);
  }

  function getAllowedRolesInRoundArr(uint256 round) public view returns (int256[] memory) {
    int256[] storage _allowedRolesInRound = allowedRolesInRoundArr[allowedRolesInRoundSetId][round];
    uint256 len = _allowedRolesInRound.length;
    int256[] memory ret = new int256[](len);
    for (uint i = 0; i < len; i++)
      ret[i] = _allowedRolesInRound[i];
    return ret;
  }

  function getAllAllowedRolesInRounds() public view returns (RoleInRoundParams[] memory) {
    mapping(uint256 => uint256) storage _currentAllowedRolesInRoundCount =
      allowedRolesInRoundCount[allowedRolesInRoundSetId];

    uint256 len = 0;
    for (uint i = 0; i < availableAllowedRounds.length; i++)
      len += _currentAllowedRolesInRoundCount[ availableAllowedRounds[i] ];

    RoleInRoundParams[] memory ret = new RoleInRoundParams[](len);
    uint256 index = 0;
    for (uint i = 0; i < availableAllowedRounds.length; i++) {
      uint256 round = availableAllowedRounds[i];
      uint256 count = _currentAllowedRolesInRoundCount[round];
      for (uint j = 0; j < count; j++) {
        int256 role = allowedRolesInRoundArr[allowedRolesInRoundSetId][round][j];
        Role storage allowedRole = allowedRolesInRound[allowedRolesInRoundSetId][round][role];
        RoleInRoundParams memory retAtCurrentIndex = ret[index];
        retAtCurrentIndex.round = round;
        retAtCurrentIndex.role = role;
        retAtCurrentIndex.maxMint = allowedRole.max_mint;
        retAtCurrentIndex.mintPrice = allowedRole.mint_price;
        index++;
      }
    }
    return ret;
  }

  function getAllRoundAllocations() public view returns (RoundAllocationParams[] memory) {
    uint256 len = availableRounds.length;
    RoundAllocationParams[] memory ret = new RoundAllocationParams[](len);
    mapping(uint256 => uint256) storage _currentRoundAllocations = roundAllocations[roundAllocationsSetId];
    for (uint i = 0; i < len; i++) {
      RoundAllocationParams memory retAtCurrentIndex = ret[i];
      retAtCurrentIndex.round = availableRounds[i];
      retAtCurrentIndex.allocation = _currentRoundAllocations[retAtCurrentIndex.round];
    }
    return ret;
  }

  function getAllRoleAllocations() public view returns (RoleAllocationParams[] memory) {
    uint256 len = availableRoles.length;
    RoleAllocationParams[] memory ret = new RoleAllocationParams[](len);
    mapping(int256 => uint256) storage _currentRoleAllocations = roleAllocations[roleAllocationsSetId];
    for (uint i = 0; i < len; i++) {
      RoleAllocationParams memory retAtCurrentIndex = ret[i];
      retAtCurrentIndex.role = availableRoles[i];
      retAtCurrentIndex.allocation = _currentRoleAllocations[retAtCurrentIndex.role];
    }
    return ret;
  }

  function mintPriceForCurrentRoundForRole(int256 role) public view returns (uint256) {
    return allowedRolesInRound[allowedRolesInRoundSetId][currentRound][role].mint_price;
  }

  function maxMintableForRole(address addr, int256 role) public view virtual returns (uint256) {
    uint256 minted = _addressTokenMinted[addr];
    uint256 max_mint = 0;

    uint256 _currentRoundAllocation = roundAllocations[roundAllocationsSetId][currentRound];
    uint256 _currentRoleAllocation = roleAllocations[roleAllocationsSetId][role];
    uint256 _addressMintedInRoundByRole = _addressTokenMintedInRoundByRole[addr][currentRound][role];
    uint256 _addressMintedInRole = _addressTokenMintedInRole[addr][role];
    uint256 _currentTotalMintedInRound = totalMintedInRound[currentRound];

    if (
      // Not yet started
      currentRound == 0
      // Total minted in this round reach the maximum allocated
      || _currentTotalMintedInRound >= _currentRoundAllocation
      // Cannot mint more than allocated for role
      || _addressMintedInRole >= _currentRoleAllocation
      // Hit the maximum per wallet
      || minted >= maxMintPerAddress
      // Prevent underflow
      || _currentTotalMintedInRound >= _currentRoundAllocation
      )
      return 0;

    Role storage _allowedRoleInRound = allowedRolesInRound[allowedRolesInRoundSetId][currentRound][role];
    if (_allowedRoleInRound.exists)
      max_mint = _allowedRoleInRound.max_mint;

    // Cannot mint more for this round
    if (_addressMintedInRoundByRole >= max_mint)
      return 0;

    uint256 wallet_quota_left = maxMintPerAddress - minted;
    uint256 round_quota_left = max_mint - _addressMintedInRoundByRole;
    uint256 round_allocation_quota_left = _currentRoundAllocation - _currentTotalMintedInRound;
    uint256 role_quota_left = _currentRoleAllocation - _addressMintedInRole;

    return Math.min(
      Math.min(
        Math.min(
          Math.min(
            wallet_quota_left,
            round_quota_left
          ),
          round_allocation_quota_left
        ),
        role_quota_left
      ),
      mintableLeft());
  }

  function maxMintableForTxForRole(address addr, int256 role) public view virtual returns (uint256) {
    return Math.min(maxMintableForRole(addr, role), maxMintPerTx);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (!_exists(tokenId))
      revert NonExistentToken();

    if (bytes(baseURIExtended).length == 0)
      return '';

    if (isSingleMetadata)
      return baseURIExtended;

    string memory extension = "";
    if (metadataHasExtension)
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

  function removeArrayAtUint256Index(uint256[] storage array, uint256 index) private {
    array[index] = array[array.length - 1];
    array.pop();
  }

  function removeArrayAtInt256Index(int256[] storage array, uint256 index) private {
    array[index] = array[array.length - 1];
    array.pop();
  }

  function _existedInUint256Array(uint256[] storage array, uint256 value) private view returns (bool) {
    uint256 len = array.length;
    for (uint i = 0; i < len; i++)
      if (array[i] == value)
        return true;
    return false;
  }

  function _recoverAddress(bytes memory data, uint8 v, bytes32 r, bytes32 s) private pure returns (address) {
    return ecrecover(keccak256(
      abi.encodePacked(
        "\x19Ethereum Signed Message:\n32",
        keccak256(data)
      )
    ), v, r, s);
  }

  function _transferEth(address payable to, uint256 amount) private {
    if (amount == 0)
      return;
    (bool sent,) = to.call{ value: amount }("");
    if (!sent)
      revert EtherNotSent();
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
    return super.supportsInterface(interfaceId) || ERC721A.supportsInterface(interfaceId);
  }

  ///////////////
  // Withdrawal
  ///////////////

  function withdraw() public onlyOwner {
    _transferEth(payable(msg.sender), address(this).balance);
  }

  function withdrawToken(address tokenAddress) public onlyOwner {
    IERC20 tokenContract = IERC20(tokenAddress);
    tokenContract.transfer(msg.sender, tokenContract.balanceOf(address(this)));
  }

  /////////////
  // Fallback
  /////////////

  receive() external payable {
  }
}