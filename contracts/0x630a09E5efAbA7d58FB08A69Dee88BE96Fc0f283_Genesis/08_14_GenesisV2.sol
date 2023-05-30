// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import {UpdatableOperatorFilterer} from "operator-filter-registry/src/UpdatableOperatorFilterer.sol";

/*
    ██████╗░░░██╗██╗███████╗░░░░░░░█████╗░░█████╗░███╗░░░███╗██╗░█████╗░░██████╗
    ╚════██╗░██╔╝██║╚════██║░░░░░░██╔══██╗██╔══██╗████╗░████║██║██╔══██╗██╔════╝
    ░░███╔═╝██╔╝░██║░░░░██╔╝█████╗██║░░╚═╝██║░░██║██╔████╔██║██║██║░░╚═╝╚█████╗░
    ██╔══╝░░███████║░░░██╔╝░╚════╝██║░░██╗██║░░██║██║╚██╔╝██║██║██║░░██╗░╚═══██╗
    ███████╗╚════██║░░██╔╝░░░░░░░░╚█████╔╝╚█████╔╝██║░╚═╝░██║██║╚█████╔╝██████╔╝
    ╚══════╝░░░░░╚═╝░░╚═╝░░░░░░░░░░╚════╝░░╚════╝░╚═╝░░░░░╚═╝╚═╝░╚════╝░╚═════╝░
*/

error Genesis__OnlyPowerPackContractCanCall();
error Genesis__MaxSupplyReached();
error Genesis__PowerPackContractNotSet();
error Genesis__PackAlreadyOpened();
error Genesis__NotApprovedOrOwner();
error Genesis__CurrentlyStaking();
error Genesis__StakingDisabled();
error Genesis__NotStaked();
error Genesis__InvalidURI();
error Genesis__InvalidAddress();

contract Genesis is
  ERC721AQueryable,
  Ownable,
  ReentrancyGuard,
  ERC2981,
  UpdatableOperatorFilterer
{
  /////////////////////
  // State Variables //
  /////////////////////

  uint256 public constant MAX_SUPPLY = 6020;
  string private s_baseTokenURI;
  string private s_contractURI;
  bool private s_stakingEnabled = false;

  /**
   * @dev MUST only be modified by safeTransferWhileStaking(); if set
   * to 2 then the _beforeTokenTransfer() block while staking is disabled.
   */
  uint256 private s_stakingTransfer = 1;

  /**
   * @notice Address that is allowed to mint
   */
  address private s_powerPackContractAddress;

  struct PackInfo {
    uint256 tokenId;
    address mintedTo;
    bool valid;
  }

  struct TokenInfo {
    uint256 packId;
    address mintedTo;
    bool valid;
  }

  /**
   * @notice packId mapped to tokenId and address
   * @dev packId -> tokenId and address
   */
  mapping(uint256 => PackInfo) private s_packInfo;

  /**
   * @notice tokenId mapped to packId and address
   * @dev tokenId -> packId and address
   */
  mapping(uint256 => TokenInfo) private s_tokenInfo;

  /**
   * @dev tokenId to staking start time (0 = not staking)
   */
  mapping(uint256 => uint256) private s_stakingStarted;

  /**
   * @dev Cumulative per-token staking, excluding the current period
   */
  mapping(uint256 => uint256) private s_stakingTotal;

  /////////////////////
  // Events          //
  /////////////////////

  /**
   * @dev Emitted when a token is minted
   */
  event Minted(uint256 indexed packId, uint256 tokenId);

  /**
   * @dev Emitted when a token is emergency minted or airdropped to vault
   */
  event EmergencyMinted(address operator, address to, uint256 quantity);

  /**
   * @dev Emitted when a token begins staking.
   */
  event Staked(uint256 indexed tokenId);

  /**
   * @dev Emitted when a token stops staking either through
   * normal means or by being expelled.
   */
  event Unstaked(uint256 indexed tokenId);

  /**
   * @dev Emitted when a token is expelled from staking.
   */
  event Expelled(uint256 indexed tokenId);

  /**
   * @dev emitted when the base URI is updated
   */
  event BaseURIChanged(address operator, string newBaseURI);

  /**
   * @dev emitted when the contract URI is updated
   */
  event ContractURIChanged(address operator, string newContractURI);

  /**
   * @dev emitted when the power pack contract is updated
   */
  event PowerPackContractUpdated(
    address operator,
    address newPowerPackContract
  );

  ////////////////////
  // Overrides      //
  ////////////////////

  /**
   * @notice Start token IDs at 1 instead of 0
   */
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  ////////////////////
  // Main Functions //
  ////////////////////

  constructor(
    string memory baseURI
  )
    ERC721A("247 Genesis", "247Genesis")
    UpdatableOperatorFilterer(
      0x000000000000AAeB6D7670E522A718067333cd4E,
      0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6,
      true
    )
  {
    s_baseTokenURI = baseURI;
  }

  /**
   * @notice mints from powerpack contract
   * @dev setPowerPackContract() must be set
   */
  function mintToOpenedPack(
    address to,
    uint256 packId
  ) external virtual nonReentrant {
    uint256 nextTokenId = _nextTokenId();

    if (s_powerPackContractAddress == address(0)) {
      revert Genesis__PowerPackContractNotSet();
    }
    if (msg.sender != s_powerPackContractAddress) {
      revert Genesis__OnlyPowerPackContractCanCall();
    }
    if (s_packInfo[packId].valid) {
      revert Genesis__PackAlreadyOpened();
    }
    if (nextTokenId > MAX_SUPPLY) {
      revert Genesis__MaxSupplyReached();
    }

    _safeMint(to, 1);
    s_packInfo[packId] = PackInfo(nextTokenId, to, true);
    s_tokenInfo[nextTokenId] = TokenInfo(packId, to, true);
    emit Minted(packId, nextTokenId);
  }

  /**
   * @notice Toggles whether a token is staking or not.
   */
  function toggleStaking(uint256 tokenId) internal {
    if (
      !(ownerOf(tokenId) == msg.sender || getApproved(tokenId) == msg.sender)
    ) {
      revert Genesis__NotApprovedOrOwner();
    }
    uint256 start = s_stakingStarted[tokenId];
    if (start == 0) {
      if (!s_stakingEnabled) {
        revert Genesis__StakingDisabled();
      }
      s_stakingStarted[tokenId] = block.timestamp;
      emit Staked(tokenId);
    } else {
      s_stakingTotal[tokenId] += block.timestamp - start;
      s_stakingStarted[tokenId] = 0;
      emit Unstaked(tokenId);
    }
  }

  /**
   * @notice Toggles staking for one or more tokens.
   */
  function toggleStaking(uint256[] calldata tokenIds) external {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      toggleStaking(tokenIds[i]);
    }
  }

  /**
   * @notice Transfer a token between addresses while it is staking.
   * Does not reset the staking period.
   */
  function safeTransferWhileStaking(
    address from,
    address to,
    uint256 tokenId
  ) external {
    if (
      !(ownerOf(tokenId) == msg.sender || getApproved(tokenId) == msg.sender)
    ) {
      revert Genesis__NotApprovedOrOwner();
    }
    s_stakingTransfer = 2;
    safeTransferFrom(from, to, tokenId);
    s_stakingTransfer = 1;
  }

  /**
   * @dev Block transfers while staking.
   */
  function _beforeTokenTransfers(
    address,
    address,
    uint256 startTokenId,
    uint256 quantity
  ) internal view override {
    uint256 tokenId = startTokenId;
    for (uint256 end = tokenId + quantity; tokenId < end; tokenId++) {
      if (!(s_stakingStarted[tokenId] == 0 || s_stakingTransfer == 2)) {
        revert Genesis__CurrentlyStaking();
      }
    }
  }

  /////////////////////
  // Admin Functions //
  /////////////////////

  /**
   * @notice Emergency backup mint in case of powerpack error. Also
   * used to mint the first 20 vault tokens and 1000 special collection tokens.
   * The remaining 5000 are minted by opening power packs via mintToOpenPack().
   */
  function emergencyMint(address to, uint256 quantity) external onlyOwner {
    if (to == address(0)) {
      revert Genesis__InvalidAddress();
    }
    if (_totalMinted() + quantity > MAX_SUPPLY) {
      revert Genesis__MaxSupplyReached();
    }
    _safeMint(to, quantity);
    emit EmergencyMinted(msg.sender, to, quantity);
  }

  function setBaseURI(string memory newUri) external onlyOwner {
    if (bytes(newUri).length == 0) {
      revert Genesis__InvalidURI();
    }
    s_baseTokenURI = newUri;
    emit BaseURIChanged(msg.sender, newUri);
  }

  /**
   * @notice Sets the contract URI for OpenSea listings
   * @param newContractURI new contract URI
   */
  function setContractURI(string memory newContractURI) external onlyOwner {
    if (bytes(newContractURI).length == 0) {
      revert Genesis__InvalidURI();
    }
    s_contractURI = newContractURI;
    emit ContractURIChanged(msg.sender, newContractURI);
  }

  /**
   * @notice Sets the power pack contract address that can call
   * mintToOpenedPack().
   * @param addr new power pack contract address
   */
  function setPowerPackContract(address addr) external onlyOwner {
    if (addr == address(0)) {
      revert Genesis__InvalidAddress();
    }
    s_powerPackContractAddress = addr;
    emit PowerPackContractUpdated(msg.sender, addr);
  }

  /**
   * @notice sets whether staking is enabled or not
   */
  function setStakingEnabled(bool isEnabled) external onlyOwner {
    s_stakingEnabled = isEnabled;
  }

  /**
   * @notice Admin/owner-only ability to expel a token from staking.
   * @dev As most sales listings use off-chain signatures, it's impossible
   * to detect someone who has staked and then deliberately undercuts
   * the floor price in the knowledge that the sale can't proceed. This
   * function allows for monitoring of such practices and expulsion if
   * abuse is detected, allowing the undercutting token to be
   * sold on the open market. Since OpenSea uses isApprovedForAll() in
   * its pre-listing checks, we can't block by that means because staking
   * would then be all-or-nothing for all of a particular owner's
   * Genesis Avatars.
   */
  function expelFromStaking(uint256 tokenId) external onlyOwner {
    if (s_stakingStarted[tokenId] == 0) {
      revert Genesis__NotStaked();
    }
    s_stakingTotal[tokenId] += block.timestamp - s_stakingStarted[tokenId];
    s_stakingStarted[tokenId] = 0;
    emit Unstaked(tokenId);
    emit Expelled(tokenId);
  }

  ////////////////////
  // View Functions //
  ////////////////////

  /**
   * @notice gets tokenId and address from a given packId
   * @return tokenId the tokenId that was minted from the pack
   * @return mintedTo the address it was minted to
   */
  function getPackInfo(
    uint256 packId
  ) external view returns (uint256 tokenId, address mintedTo, bool valid) {
    tokenId = s_packInfo[packId].tokenId;
    mintedTo = s_packInfo[packId].mintedTo;
    if (tokenId == 0 || mintedTo == address(0)) {
      valid = false;
    } else {
      valid = true;
    }
  }

  /**
   * @notice gets packId and address from a given tokenId
   * @return packId the pack it was minted from
   * @return mintedTo the address it was minted to
   */
  function getTokenInfo(
    uint256 tokenId
  ) external view returns (uint256 packId, address mintedTo, bool valid) {
    packId = s_tokenInfo[tokenId].packId;
    mintedTo = s_tokenInfo[tokenId].mintedTo;
    if (packId == 0 || mintedTo == address(0)) {
      valid = false;
    } else {
      valid = true;
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return s_baseTokenURI;
  }

  function contractURI() external view returns (string memory) {
    return s_contractURI;
  }

  function getStakingEnabled() external view returns (bool) {
    return s_stakingEnabled;
  }

  /**
   * @notice Returns the length of time (in seconds) that the token has been staked.
   * @dev Staking is tied to a specific token, not to the
   * owner, so it doesn't reset upon sale
   * @return staking Whether the token is currently staking.
   * May be true with zero current staking if in the same black as
   * staking began.
   * @return current Zero if not currently staking, otherwise the length
   * of time since the most recent staking began.
   * @return total Total period of time that the token has staked
   * across its life, including the current period.
   */
  function getStakingPeriod(
    uint256 tokenId
  ) external view returns (bool staking, uint256 current, uint256 total) {
    uint256 start = s_stakingStarted[tokenId];
    if (start != 0) {
      staking = true;
      current = block.timestamp - start;
    }
    total = current + s_stakingTotal[tokenId];
  }

  ///////////////////////
  // Royalty Functions //
  ///////////////////////

  function setDefaultRoyalty(
    address receiver,
    uint96 feeNumerator
  ) external onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function deleteDefaultRoyalty() external onlyOwner {
    _deleteDefaultRoyalty();
  }

  function setTokenRoyalty(
    uint256 tokenId,
    address receiver,
    uint96 feeNumerator
  ) external onlyOwner {
    _setTokenRoyalty(tokenId, receiver, feeNumerator);
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC721A, ERC2981, IERC721A) returns (bool) {
    // Supports the following `interfaceId`s:
    // - IERC165: 0x01ffc9a7
    // - IERC721: 0x80ac58cd
    // - IERC721Metadata: 0x5b5e139f
    // - IERC2981: 0x2a55205a
    return
      ERC721A.supportsInterface(interfaceId) ||
      ERC2981.supportsInterface(interfaceId);
  }

  ///////////////////////
  // OpenSea Functions //
  ///////////////////////

  function owner()
    public
    view
    virtual
    override(Ownable, UpdatableOperatorFilterer)
    returns (address)
  {
    return Ownable.owner();
  }

  function setApprovalForAll(
    address operator,
    bool approved
  ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(
    address operator,
    uint256 tokenId
  )
    public
    payable
    override(ERC721A, IERC721A)
    onlyAllowedOperatorApproval(operator)
  {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}