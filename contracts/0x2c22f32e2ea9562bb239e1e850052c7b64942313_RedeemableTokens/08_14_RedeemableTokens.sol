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

error RedeemableTokens__OnlyPowerPackContractCanCall();
error RedeemableTokens__MaxSupplyReached();
error RedeemableTokens__PowerPackContractNotSet();
error RedeemableTokens__TokenNotOwned();
error RedeemableTokens__AlreadyRedeemed();
error RedeemableTokens__PackAlreadyOpened();
error RedeemableTokens__RedemptionNotAllowed();
error RedeemableTokens__InvalidAddress();

contract RedeemableTokens is
  ERC721AQueryable,
  Ownable,
  ReentrancyGuard,
  ERC2981,
  UpdatableOperatorFilterer
{
  /////////////////////
  // State Variables //
  /////////////////////

  uint256 public constant MAX_SUPPLY = 100;
  string private s_baseTokenURI;
  string private s_contractURI;

  /**
   * @notice Address that is allowed to mint
   */
  address private s_powerPackContractAddress;

  /**
   * @notice Whether redemptions are currently allowed.
   */
  bool public s_canRedeem;

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
   * @notice track tokens that have been redeemed/burned by tokenId
   * @dev tokenId -> address that redeemed
   */
  mapping(uint256 => address) private s_hasRedeemedByTokenId;

  /**
   * @notice track tokens that have been redeemed/burned by address
   * @dev address -> array of redeemed tokenIds
   */
  mapping(address => uint256[]) private s_hasRedeemedByAddress;

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

  /////////////////////
  // Events          //
  /////////////////////

  /**
   * @dev Emitted when a token is minted
   */
  event Minted(uint256 indexed packId, uint256 tokenId);

  /**
   * @dev Emitted when a token is redeemed
   */
  event Redeemed(uint256 indexed tokenId, address redeemedBy);

  /**
   * @dev Emitted when a token is emergency minted or airdropped to vault
   */
  event EmergencyMinted(address operator, address to, uint256 quantity);

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
    ERC721A("247 Sean Chen OA Redemption", "OAredeem")
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
      revert RedeemableTokens__PowerPackContractNotSet();
    }
    if (msg.sender != s_powerPackContractAddress) {
      revert RedeemableTokens__OnlyPowerPackContractCanCall();
    }
    if (s_packInfo[packId].valid) {
      revert RedeemableTokens__PackAlreadyOpened();
    }
    if (nextTokenId > MAX_SUPPLY) {
      revert RedeemableTokens__MaxSupplyReached();
    }

    _safeMint(to, 1);
    s_packInfo[packId] = PackInfo(nextTokenId, to, true);
    s_tokenInfo[nextTokenId] = TokenInfo(packId, to, true);
    emit Minted(packId, nextTokenId);
  }

  /**
   * @notice Redeems and burns token
   * @dev toggleCanRedeem() must be set to true
   */
  function redeemToken(uint256 tokenId) internal {
    if (!s_canRedeem) {
      revert RedeemableTokens__RedemptionNotAllowed();
    }
    if (msg.sender != ownerOf(tokenId)) {
      revert RedeemableTokens__TokenNotOwned();
    }
    if (s_hasRedeemedByTokenId[tokenId] != address(0)) {
      revert RedeemableTokens__AlreadyRedeemed();
    }
    _burn(tokenId);
    s_hasRedeemedByTokenId[tokenId] = msg.sender;
    s_hasRedeemedByAddress[msg.sender].push(tokenId);
    emit Redeemed(tokenId, msg.sender);
  }

  /**
   * @notice redeems and burns tokens
   */
  function redeemTokens(uint256[] calldata tokenIds) external {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      redeemToken(tokenIds[i]);
    }
  }

  /////////////////////
  // Admin Functions //
  /////////////////////

  /**
   * @notice Emergency backup mint in case of powerpack error
   */
  function emergencyMint(address to, uint256 quantity) external onlyOwner {
    if (to == address(0)) {
      revert RedeemableTokens__InvalidAddress();
    }
    if (_totalMinted() + quantity > MAX_SUPPLY) {
      revert RedeemableTokens__MaxSupplyReached();
    }
    _safeMint(to, quantity);
    emit EmergencyMinted(msg.sender, to, quantity);
  }

  function setBaseURI(string memory newUri) external onlyOwner {
    if (bytes(newUri).length == 0) {
      revert RedeemableTokens__InvalidAddress();
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
      revert RedeemableTokens__InvalidAddress();
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
      revert RedeemableTokens__InvalidAddress();
    }
    s_powerPackContractAddress = addr;
    emit PowerPackContractUpdated(msg.sender, addr);
  }

  function toggleCanRedeem() external onlyOwner {
    s_canRedeem = !s_canRedeem;
  }

  ////////////////////
  // View Functions //
  ////////////////////

  /**
   * @notice gets the address from a tokenId if redeemed
   * @return address the address that redeemed the token
   */
  function getRedeemedByTokenId(
    uint256 tokenId
  ) external view returns (address) {
    return s_hasRedeemedByTokenId[tokenId];
  }

  /**
   * @notice gets the tokenIds that an address has redeemed
   * @return tokenIds array of tokenIds that an address has redeemed
   */
  function getRedeemedByAddress(
    address addr
  ) external view returns (uint256[] memory) {
    return s_hasRedeemedByAddress[addr];
  }

  /**
   * @notice Returns total number of tokens redeemed
   * @return _totalBurned burned tokens = redeemed tokens
   */
  function totalRedeemed() external view returns (uint256) {
    return _totalBurned();
  }

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