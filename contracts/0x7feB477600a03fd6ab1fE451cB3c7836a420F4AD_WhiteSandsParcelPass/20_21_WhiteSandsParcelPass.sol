// SPDX-License-Identifier: UNLICENSED

//  dP   dP   dP dP       oo   dP            .d88888b                          dP
//  88   88   88 88            88            88.    "'                         88
//  88  .8P  .8P 88d888b. dP d8888P .d8888b. `Y88888b. .d8888b. 88d888b. .d888b88 .d8888b.
//  88  d8'  d8' 88'  `88 88   88   88ooood8       `8b 88'  `88 88'  `88 88'  `88 Y8ooooo.
//  88.d8P8.d8P  88    88 88   88   88.  ... d8'   .8P 88.  .88 88    88 88.  .88       88
//  8888' Y88'   dP    dP dP   dP   `88888P'  Y88888P  `88888P8 dP    dP `88888P8 `88888P'
//  ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
//
//  888888ba                                      dP  888888ba
//  88    `8b                                     88  88    `8b
//  a88aaaa8P' .d8888b. 88d888b. .d8888b. .d8888b. 88 a88aaaa8P' .d8888b. .d8888b. .d8888b.
//  88        88'  `88 88'  `88 88'  `"" 88ooood8 88  88        88'  `88 Y8ooooo. Y8ooooo.
//  88        88.  .88 88       88.  ... 88.  ... 88  88        88.  .88       88       88
//  dP        `88888P8 dP       `88888P' `88888P' dP  dP        `88888P8 `88888P' `88888P'


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "../common/DeveloperAccessControl.sol";
import "../common/IPresaleAccessControlHandler.sol";
import "../common/PresaleAccessControlHandler.sol";
import "../common/Sales.sol";

import "hardhat/console.sol";

/**
 * @title White Sands - Parcel Pass Contract
 *
 * @notice The White Sands Parcel Pass contract allows minting a time-limited presale controlled by
 * an access list, and then a public sale. The presale is limited by the number of tokens that can
 * be minted per wallet. The presale mint allocation also counts towards the public sale limit.
 */
contract WhiteSandsParcelPass is ERC721, DeveloperAccessControl, Pausable, ReentrancyGuard {
  using Sales for Sales.PreSale;
  using Counters for Counters.Counter;
  using Strings for uint256;
  using ERC165Checker for address;

  address constant PAYOUT_ADDRESS = address(0xe3dB823ce2eA1B9A545F4ea93886aEBeEC26fd75);
  bytes4 constant ACL_IID = type(IPresaleAccessControlHandler).interfaceId;

  uint8 constant DEFAULT_TX_LIMIT = 2;
  uint8 constant DEFAULT_WALLET_LIMIT = 2;
  uint32 constant DEFAULT_LIMIT = 3000;
  uint128 constant DEFAULT_PRICE = 0.5 ether;

  struct AppStorage {
    address payoutAddress;
    uint8 maxTokensPerTx;
    uint8 maxTokensPerWallet;
    uint32 supplyLimit;
    uint32 totalSupply;
    uint128 price;
    uint64 presaleStart;
    uint64 presaleEnd;
    bool revealed;
    IPresaleAccessControlHandler acl;
    string metadataIpfsCid;
    string placeholderCid;
  }

  AppStorage public state;

  event TokenMinted(address to, uint32 token);

  constructor(
    address owner,
    address acl,
    uint64 preSaleStart,
    string memory metadataIpfsCid
  ) DeveloperAccessControl(owner) ERC721("White Sands Parcel Pass", "WSPP") {
    state.payoutAddress = owner;
    state.maxTokensPerTx = DEFAULT_TX_LIMIT;
    state.maxTokensPerWallet = DEFAULT_WALLET_LIMIT;
    state.supplyLimit = DEFAULT_LIMIT;
    state.price = DEFAULT_PRICE;
    state.presaleStart = preSaleStart;
    state.presaleEnd = preSaleStart + 24 hours;
    require(acl.supportsInterface(ACL_IID), "ACL: wrong interface type for checker");
    state.acl = IPresaleAccessControlHandler(acl);
    state.placeholderCid = metadataIpfsCid;
    state.revealed = false;
  }

  modifier onlyPresale() {
    require(block.timestamp >= state.presaleStart, "Presale not open yet");
    require(block.timestamp < state.presaleEnd, "Presale has closed");
    _;
  }

  modifier onlyPublicSale() {
    require(block.timestamp >= state.presaleEnd, "Sale not open yet");
    _;
  }

  function pause() external onlyUnlocked {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }

  /// Minting method for people on the access list that can mint before the public sale.
  ///
  /// The combination of the nonce and senders address is signed by the trusted signer wallet.
  function mintPresale(
    uint16 count,
    uint256 nonce,
    bytes calldata signature
  ) external payable onlyPresale nonReentrant {
    (bool canMint, bytes memory error) = state.acl.verifyCanMintPresaleTokens(
      _msgSender(),
      uint32(balanceOf(_msgSender())),
      state.presaleStart,
      state.presaleEnd,
      count,
      nonce,
      signature
    );
    require(canMint, string(abi.encodePacked("ERROR: ", error)));
    _safeMintTokens(count);
  }

  /// Perform a regular mint with a limit per wallet on passes as well as a limit per transaction.
  function mint(uint16 count) external payable onlyPublicSale {
    _safeMintTokens(count);
  }

  function _safeMintTokens(uint16 count) internal {
    require(count <= state.maxTokensPerTx, "exceeded max per transaction");
    require(balanceOf(_msgSender()) + count <= state.maxTokensPerWallet, "exceeded max per wallet");
    require(state.totalSupply + count <= state.supplyLimit, "mint: not enough supply");

    uint256 cost = count * state.price;
    require(msg.value >= cost, "Insufficient funds");

    for (uint16 i = 0; i < count; i++) {
      uint32 token = nextTokenId();
      _safeMint(_msgSender(), token);
      emit TokenMinted(_msgSender(), token);
    }

    if (msg.value > cost) {
      uint256 refund = msg.value - cost;
      (bool success,) = payable(_msgSender()).call{value : refund}("");
      require(success, "Failed to refund additional value");
    }
  }

  function setPresaleAccessController(address acl) external onlyUnlocked {
    require(acl.supportsInterface(ACL_IID), "ACL: wrong interface type for checker");
    state.acl = IPresaleAccessControlHandler(acl);
  }

  function setPresaleDetails(uint64 startTime, uint64 durationInHours) external onlyUnlocked {
    state.presaleStart = startTime;
    state.presaleEnd = startTime + (durationInHours * 1 hours);
  }

  function getPresaleStart() public view returns (uint64) {
    return state.presaleStart;
  }

  function getSaleStart() public view returns (uint64) {
    return state.presaleEnd;
  }

  function setTokensPerTx(uint8 limit) external onlyUnlocked {
    state.maxTokensPerTx = limit;
  }

  function getTokensPerTx() external view returns (uint8) {
    return state.maxTokensPerTx;
  }

  function setTokensPerWallet(uint8 limit) external onlyUnlocked {
    state.maxTokensPerWallet = limit;
  }

  function getTokensPerWallet() external view returns (uint8) {
    return state.maxTokensPerWallet;
  }

  function setTokenSupplyLimit(uint32 limit) external onlyUnlocked {
    state.supplyLimit = limit;
  }

  function getTokenSupplyLimit() external view returns (uint32) {
    return state.supplyLimit;
  }

  function setMintPrice(uint128 _price) external onlyUnlocked {
    state.price = _price;
  }

  function price() external view returns (uint128) {
    return state.price;
  }

  function setMetadataIpfsCid(string calldata cid) external onlyUnlocked {
    state.metadataIpfsCid = cid;
  }

  function setPlaceholderIpfsCid(string calldata cid) external onlyUnlocked {
    state.placeholderCid = cid;
  }

  function reveal() external onlyUnlocked {
    state.revealed = true;
  }

  /**
   * @dev Returns the total amount of tokens stored by the contract.
     */
  function totalSupply() external view returns (uint256) {
    return state.totalSupply;
  }

  /**
   * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
  function tokenByIndex(uint256 index) external pure returns (uint256) {
    return index;
  }

  function nextTokenId() internal returns (uint32) {
    state.totalSupply++;
    return state.totalSupply;
  }


  /**
   * @dev See {IERC721Metadata-tokenURI}.
     */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (state.revealed) {
      return string(abi.encodePacked("ipfs://", state.metadataIpfsCid, "/", tokenId.toString(), ".json"));
    } else {
      return string(abi.encodePacked("ipfs://", state.placeholderCid));
    }
  }

  function recoverSignerAddress(
    uint256 nonce,
    address sender,
    bytes calldata signature
  ) internal pure returns (address) {
    bytes32 message = keccak256(abi.encode(nonce, sender));
    bytes32 digest = ECDSA.toEthSignedMessageHash(message);
    return ECDSA.recover(digest, signature);
  }

  function _afterTokenTransfer(
    address /*from*/,
    address /*to*/,
    uint256 /*tokenId*/
  ) internal virtual override {
    maybeLock();
  }

  /** Fallback to be able to receive ETH payments (just in case!) */
  receive() external payable {}

  function getPayoutAddress() external view returns (address) {
    return state.payoutAddress;
  }

  function setPayoutAddress(address payout) external onlyOwner {
    state.payoutAddress = payout;
  }

  function withdraw() external onlyOwner {
    require(payable(state.payoutAddress).send(address(this).balance), "withdraw: sending funds failed");
  }

  function destroy() external onlyUnlocked {
    require(state.totalSupply == 0, "cannot destroy once minting has started");
    selfdestruct(payable(PAYOUT_ADDRESS));
  }
}