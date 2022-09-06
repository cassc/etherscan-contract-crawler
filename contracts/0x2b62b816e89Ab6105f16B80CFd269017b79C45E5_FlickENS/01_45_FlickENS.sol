// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9 <0.9.0;
/*

  _  _                               __     _       _              _     
 | \| |   __ _    _ __     ___      / _|   | |     (_)     __     | |__  
 | .` |  / _` |  | '  \   / -_)    |  _|   | |     | |    / _|    | / /  
 |_|\_|  \__,_|  |_|_|_|  \___|   _|_|_   _|_|_   _|_|_   \__|_   |_\_\  
_|"""""|_|"""""|_|"""""|_|"""""|_|"""""|_|"""""|_|"""""|_|"""""|_|"""""| 
"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-' 
                       ___    _  _     ___                                                   
                      | __|  | \| |   / __|                                                  
                      | _|   | .` |   \__ \                                                  
                      |___|  |_|\_|   |___/                                                  
                    _|"""""|_|"""""|_|"""""|                                                 
                    "`-0-0-'"`-0-0-'"`-0-0-'                                                 
*/

import "@divergencetech/ethier/contracts/crypto/SignatureChecker.sol";
import "@divergencetech/ethier/contracts/crypto/SignerManager.sol";
import "@divergencetech/ethier/contracts/erc721/BaseTokenURI.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721ACommon.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721Redeemer.sol";
import "@divergencetech/ethier/contracts/sales/FixedPriceSeller.sol";
import "@divergencetech/ethier/contracts/utils/Monotonic.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "erc721a/contracts/extensions/IERC721AQueryable.sol";
import "./ITokenURIGenerator.sol";
import "./IExtendedResolver.sol";

interface IExtendedResolverWithProof {
  function resolve(bytes memory name, bytes memory data)
    external
    view
    returns (bytes memory);

  function resolveWithProof(bytes calldata response, bytes calldata extraData)
    external
    view
    returns (bytes memory);
}

contract FlickENS is
  ERC721ACommon,
  BaseTokenURI,
  SignerManager,
  ERC2981,
  AccessControlEnumerable,
  PaymentSplitter,
  IERC721AQueryable
{
  using EnumerableSet for EnumerableSet.AddressSet;
  using ERC721Redeemer for ERC721Redeemer.Claims;
  using Monotonic for Monotonic.Increaser;
  using SignatureChecker for EnumerableSet.AddressSet;

  // FlickENS provides additional functionality to ENS NFTs. This stores the contractAddres of ENS
  address public ensTokenAddress;
  // Proxy to another resolver, to allow it to be swapped out
  IExtendedResolverWithProof public resolverProxy;
  // Mapping of FlickENS tokens to ENS tokens
  mapping(uint256 => uint256) public flickToEns;

  //sale settings
  uint256 public cost = 0.05 ether;
  uint256 public maxSupply = 2000;
  uint256 public maxMint = 10;
  uint256 public preSaleMaxMintPerAccount = 10;
  bool public presaleActive = false;
  bool public publicSaleActive = false;

  // mint count tracker
  mapping(address => Monotonic.Increaser) private presaleMinted;

  /**
    @notice Role of administrative users allowed to expel a Token from staking.
    @dev See expelFromStaking().
     */
  bytes32 public constant EXPULSION_ROLE = keccak256("EXPULSION_ROLE");

  constructor(
    string memory name,
    string memory symbol,
    string memory baseURI,
    uint256 price,
    address signer,
    address[] memory payments,
    uint256[] memory shares,
    address payable royaltyReceiver
  )
    ERC721ACommon(name, symbol)
    BaseTokenURI(baseURI)
    PaymentSplitter(payments, shares)
  {
    cost = price;
    _setDefaultRoyalty(royaltyReceiver, 500);
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    signers.add(signer);
  }

  /**
   * Resolves a name, as specified by ENSIP 10.
   * @param name The DNS-encoded name to resolve.
   * @param data The ABI encoded data for the underlying resolution function (Eg, addr(bytes32), text(bytes32,string), etc).
   * @return The return data, ABI encoded identically to the underlying function.
   */
  function resolve(bytes calldata name, bytes calldata data)
    external
    view
    returns (bytes memory)
  {
    return resolverProxy.resolve(name, data);
  }

  /**
   * Callback used by CCIP read compatible clients to verify and parse the response.
   */
  function resolveWithProof(bytes calldata response, bytes calldata extraData)
    external
    view
    returns (bytes memory)
  {
    return resolverProxy.resolveWithProof(response, extraData);
  }

  /**
    @dev Record of already-used signatures.
     */
  mapping(bytes32 => bool) public usedMessages;

  /**
    @notice Mint token.
    */
  function presaleMint(
    address to,
    bytes32 nonce,
    uint8 mintAmount,
    bytes calldata sig
  ) external payable {
    signers.requireValidSignature(
      signaturePayload(to, nonce),
      sig,
      usedMessages
    );
    require(presaleActive, "disabled");
    require(mintAmount > 0, "mint <= 0");
    require(mintAmount <= maxMint, "mint >= maxmint");
    require(
      (presaleMinted[to].current() + mintAmount) <= preSaleMaxMintPerAccount,
      "too many mints"
    );
    require(totalSupply() + mintAmount <= maxSupply, "Over supply");
    require(cost * mintAmount == msg.value, "Wrong amount");
    _safeMint(to, mintAmount);
    presaleMinted[to].add(mintAmount);
  }

  /**
    @notice Mint token.
    */
  function mint(address to, uint8 mintAmount) external payable {
    require(publicSaleActive, "disabled");
    require(mintAmount > 0, "mint <= 0");
    require(mintAmount <= maxMint, "mint >= maxmint");
    require(totalSupply() + mintAmount <= maxSupply, "Over supply");
    require(cost * mintAmount == msg.value, "Wrong amount");
    _safeMint(to, mintAmount);
  }

  /**
    @dev Emitted when a FlickENS token wraps an ENS token.
     */
  event Wrapped(uint256 flickTokenId, uint256 ensTokenId);

  /**
   @notice Sets the ENS token that the NFT will resolve to.
   @param flickTokenId The FlickENS token id to set.
   @param ensTokenId The tokenId of the ENS that the resolver will wrap. The ENS must be owned by the owner of this token.
   */
  function wrap(uint256 flickTokenId, uint256 ensTokenId) external {
    IERC721 ensToken = IERC721(ensTokenAddress);
    require(ownerOf(flickTokenId) == msg.sender, "Not owner");
    require(
      ensToken.ownerOf(ensTokenId) == msg.sender,
      "ENS token must be owned by sender"
    );
    flickToEns[flickTokenId] = ensTokenId;
    emit Wrapped(flickTokenId, ensTokenId);
  }

  // admin minting
  function gift(uint256[] calldata _mintAmount, address[] calldata recipient)
    external
    onlyOwner
  {
    require(
      _mintAmount.length == recipient.length,
      "Provide equal mintAmount and recipients"
    );
    for (uint256 i = 0; i < recipient.length; ++i) {
      require(
        totalSupply() + _mintAmount[i] <= maxSupply,
        "Cant go over supply"
      );
      require(_mintAmount[i] > 0, "Cant mint 0");
      _safeMint(recipient[i], _mintAmount[i]);
    }
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setMaxMint(uint256 _newmaxMint) public onlyOwner {
    maxMint = _newmaxMint;
  }

  function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
    maxSupply = _newMaxSupply;
  }

  function setPreSaleMaxMintPerAccount(uint256 _newPreSaleMaxMintPerAccount)
    public
    onlyOwner
  {
    preSaleMaxMintPerAccount = _newPreSaleMaxMintPerAccount;
  }

  function setPresaleActive(bool _newPresaleActive) public onlyOwner {
    presaleActive = _newPresaleActive;
  }

  function setMintActive(bool _newMintActive) public onlyOwner {
    publicSaleActive = _newMintActive;
  }

  /**
   * @notice Returns the number of minted tokens per presale address
   */
  function presaleMintedByAddress(address _address)
    public
    view
    returns (uint256)
  {
    return presaleMinted[_address].current();
  }

  /**
    @notice Returns whether the address has minted with the particular nonce. If
    true, future calls to mint() with the same parameters will fail.
    @dev In production we will never issue more than a single nonce per address,
    but this allows for testing with a single address.
     */
  function alreadyMinted(address to, bytes32 nonce)
    external
    view
    returns (bool)
  {
    return
      usedMessages[
        SignatureChecker.generateMessage(signaturePayload(to, nonce))
      ];
  }

  /**
    @dev Constructs the buffer that is hashed for validation with a minting
    signature.
     */
  function signaturePayload(address to, bytes32 nonce)
    internal
    pure
    returns (bytes memory)
  {
    return abi.encodePacked(to, nonce);
  }

  /**
    @dev tokenId to staking start time (0 = not staking).
     */
  mapping(uint256 => uint256) private stakingStarted;

  /**
    @dev Cumulative per-token staking, excluding the current period.
     */
  mapping(uint256 => uint256) private stakingTotal;

  /**
    @notice Returns the length of time, in seconds, that the Token has
    nested.
    @dev Staking is tied to a specific Token, not to the owner, so it doesn't
    reset upon sale.
    @return staking Whether the Token is currently staking. MAY be true with
    zero current staking if in the same block as staking began.
    @return current Zero if not currently staking, otherwise the length of time
    since the most recent staking began.
    @return total Total period of time for which the Token has nested across
    its life, including the current period.
     */
  function stakingPeriod(uint256 tokenId)
    external
    view
    returns (
      bool staking,
      uint256 current,
      uint256 total
    )
  {
    uint256 start = stakingStarted[tokenId];
    if (start != 0) {
      staking = true;
      current = block.timestamp - start;
    }
    total = current + stakingTotal[tokenId];
  }

  /**
    @dev MUST only be modified by safeTransferWhileStaking(); if set to 2 then
    the _beforeTokenTransfer() block while staking is disabled.
     */
  uint256 private stakingTransfer = 1;

  /**
    @notice Transfer a token between addresses while the Token is minting,
    thus not resetting the staking period.
     */
  function safeTransferWhileStaking(
    address from,
    address to,
    uint256 tokenId
  ) external {
    require(ownerOf(tokenId) == _msgSender(), "Only owner");
    stakingTransfer = 2;
    safeTransferFrom(from, to, tokenId);
    stakingTransfer = 1;
  }

  /**
    @dev Block transfers while staking.
     */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal override {
    uint256 tokenId = startTokenId;
    for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
      require(stakingStarted[tokenId] == 0 || stakingTransfer == 2, "Seeking");
      stakingTotal[tokenId] = 0;
    }
    super._beforeTokenTransfers(from, to, startTokenId, quantity);
  }

  /**
    @dev Emitted when begining staking.
     */
  event Staking(uint256 indexed tokenId);

  /**
    @dev Emitted when stops staking; either through standard means or
    by expulsion.
     */
  event Unstaking(uint256 indexed tokenId);

  /**
    @dev Emitted when expelled from staking.
     */
  event Expelled(uint256 indexed tokenId);

  /**
    @notice Whether staking is currently allowed.
    @dev If false then staking is blocked, but unstaking is always allowed.
     */
  bool public stakingOpen = false;

  /**
    @notice Toggles the `stakingOpen` flag.
     */
  function setStakingOpen(bool open) external onlyOwner {
    stakingOpen = open;
  }

  /**
    @notice Changes the Token's staking status.
    */
  function toggleStaking(uint256 tokenId)
    internal
    onlyApprovedOrOwner(tokenId)
  {
    uint256 start = stakingStarted[tokenId];
    if (start == 0) {
      require(stakingOpen, "SOA: staking closed");
      stakingStarted[tokenId] = block.timestamp;
      emit Staking(tokenId);
    } else {
      stakingTotal[tokenId] += block.timestamp - start;
      stakingStarted[tokenId] = 0;
      emit Unstaking(tokenId);
      (tokenId);
    }
  }

  /**
    @notice Changes the staking statuses
    @dev Changes the staking.
     */
  function toggleStaking(uint256[] calldata tokenIds) external {
    uint256 n = tokenIds.length;
    for (uint256 i = 0; i < n; ++i) {
      toggleStaking(tokenIds[i]);
    }
  }

  /**
    @notice Admin-only ability to expel a Token from the nest.
    @dev As most sales listings use off-chain signatures it's impossible to
    detect someone who has nested and then deliberately undercuts the floor
    price in the knowledge that the sale can't proceed. This function allows for
    monitoring of such practices and expulsion if abuse is detected, allowing
    the undercutting token to be sold on the open market. Since OpenSea uses
    isApprovedForAll() in its pre-listing checks, we can't block by that means
    because staking would then be all-or-nothing for all of a particular owner's
    Tokens.
     */
  function expelFromStaking(uint256 tokenId) external onlyRole(EXPULSION_ROLE) {
    require(stakingStarted[tokenId] != 0, "SOA: not nested");
    stakingTotal[tokenId] += block.timestamp - stakingStarted[tokenId];
    stakingStarted[tokenId] = 0;
    emit Unstaking(tokenId);
    emit Expelled(tokenId);
  }

  /**
    @dev Required override to select the correct baseTokenURI.
     */
  function _baseURI()
    internal
    view
    override(BaseTokenURI, ERC721A)
    returns (string memory)
  {
    return BaseTokenURI._baseURI();
  }

  /**
    @notice If set, contract to which tokenURI() calls are proxied.
     */
  ITokenURIGenerator public renderingContract;

  /**
    @notice Sets the optional tokenURI override contract.
     */
  function setRenderingContract(ITokenURIGenerator _contract)
    external
    onlyOwner
  {
    renderingContract = _contract;
  }

  /**
    @notice If renderingContract is set then returns its tokenURI(tokenId)
    return value, otherwise returns the standard baseTokenURI + tokenId.
     */
  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721A, IERC721Metadata)
    returns (string memory)
  {
    if (address(renderingContract) != address(0)) {
      return renderingContract.tokenURI(tokenId);
    }
    return super.tokenURI(tokenId);
  }

  /**
    @notice Sets the contract-wide royalty info.
     */
  function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
    external
    onlyOwner
  {
    _setDefaultRoyalty(receiver, feeBasisPoints);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721ACommon, ERC2981, AccessControlEnumerable, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IExtendedResolver).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
   *
   * If the `tokenId` is out of bounds:
   *   - `addr` = `address(0)`
   *   - `startTimestamp` = `0`
   *   - `burned` = `false`
   *
   * If the `tokenId` is burned:
   *   - `addr` = `<Address of owner before token was burned>`
   *   - `startTimestamp` = `<Timestamp when token was burned>`
   *   - `burned = `true`
   *
   * Otherwise:
   *   - `addr` = `<Address of owner>`
   *   - `startTimestamp` = `<Timestamp of start of ownership>`
   *   - `burned = `false`
   */
  function explicitOwnershipOf(uint256 tokenId)
    public
    view
    override
    returns (TokenOwnership memory)
  {
    TokenOwnership memory ownership;
    if (tokenId < _startTokenId() || tokenId >= _currentIndex) {
      return ownership;
    }
    ownership = _ownerships[tokenId];
    if (ownership.burned) {
      return ownership;
    }
    return _ownershipOf(tokenId);
  }

  /**
   * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
   * See {ERC721AQueryable-explicitOwnershipOf}
   */
  function explicitOwnershipsOf(uint256[] memory tokenIds)
    external
    view
    override
    returns (TokenOwnership[] memory)
  {
    unchecked {
      uint256 tokenIdsLength = tokenIds.length;
      TokenOwnership[] memory ownerships = new TokenOwnership[](tokenIdsLength);
      for (uint256 i; i != tokenIdsLength; ++i) {
        ownerships[i] = explicitOwnershipOf(tokenIds[i]);
      }
      return ownerships;
    }
  }

  /**
   * @dev Returns an array of token IDs owned by `owner`,
   * in the range [`start`, `stop`)
   * (i.e. `start <= tokenId < stop`).
   *
   * This function allows for tokens to be queried if the collection
   * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
   *
   * Requirements:
   *
   * - `start` < `stop`
   */
  function tokensOfOwnerIn(
    address owner,
    uint256 start,
    uint256 stop
  ) external view override returns (uint256[] memory) {
    unchecked {
      if (start >= stop) revert InvalidQueryRange();
      uint256 tokenIdsIdx;
      uint256 stopLimit = _currentIndex;
      // Set `start = max(start, _startTokenId())`.
      if (start < _startTokenId()) {
        start = _startTokenId();
      }
      // Set `stop = min(stop, _currentIndex)`.
      if (stop > stopLimit) {
        stop = stopLimit;
      }
      uint256 tokenIdsMaxLength = balanceOf(owner);
      // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
      // to cater for cases where `balanceOf(owner)` is too big.
      if (start < stop) {
        uint256 rangeLength = stop - start;
        if (rangeLength < tokenIdsMaxLength) {
          tokenIdsMaxLength = rangeLength;
        }
      } else {
        tokenIdsMaxLength = 0;
      }
      uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
      if (tokenIdsMaxLength == 0) {
        return tokenIds;
      }
      // We need to call `explicitOwnershipOf(start)`,
      // because the slot at `start` may not be initialized.
      TokenOwnership memory ownership = explicitOwnershipOf(start);
      address currOwnershipAddr;
      // If the starting slot exists (i.e. not burned), initialize `currOwnershipAddr`.
      // `ownership.address` will not be zero, as `start` is clamped to the valid token ID range.
      if (!ownership.burned) {
        currOwnershipAddr = ownership.addr;
      }
      for (
        uint256 i = start;
        i != stop && tokenIdsIdx != tokenIdsMaxLength;
        ++i
      ) {
        ownership = _ownerships[i];
        if (ownership.burned) {
          continue;
        }
        if (ownership.addr != address(0)) {
          currOwnershipAddr = ownership.addr;
        }
        if (currOwnershipAddr == owner) {
          tokenIds[tokenIdsIdx++] = i;
        }
      }
      // Downsize the array to fit.
      assembly {
        mstore(tokenIds, tokenIdsIdx)
      }
      return tokenIds;
    }
  }

  /**
   * @dev Returns an array of token IDs owned by `owner`.
   *
   * This function scans the ownership mapping and is O(totalSupply) in complexity.
   * It is meant to be called off-chain.
   *
   * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
   * multiple smaller scans if the collection is large enough to cause
   * an out-of-gas error (10K pfp collections should be fine).
   */
  function tokensOfOwner(address owner)
    external
    view
    override
    returns (uint256[] memory)
  {
    unchecked {
      uint256 tokenIdsIdx;
      address currOwnershipAddr;
      uint256 tokenIdsLength = balanceOf(owner);
      uint256[] memory tokenIds = new uint256[](tokenIdsLength);
      TokenOwnership memory ownership;
      for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
        ownership = _ownerships[i];
        if (ownership.burned) {
          continue;
        }
        if (ownership.addr != address(0)) {
          currOwnershipAddr = ownership.addr;
        }
        if (currOwnershipAddr == owner) {
          tokenIds[tokenIdsIdx++] = i;
        }
      }
      return tokenIds;
    }
  }

  /**
   * @dev withdraws all ETH from the contract
   */
  function withdrawSplit() public onlyOwner {
    uint256 shares = totalShares();
    for (uint256 i = 0; i < shares; i++) {
      address payable wallet = payable(payee(i));
      release(wallet);
    }
  }

  /**
   * @dev sets the ENS resolver that this contract will proxy
   */
  function setEnsContract(address ensContract) public onlyOwner {
    ensTokenAddress = ensContract;
  }

  /**
   * @dev used by the deployment scripts to check if an address is already a signer to avoid setting it again
   */
  function isSigner(address signer) public view returns (bool) {
    return signers.contains(signer);
  }

  function setOffchainResolver(address _resolverProxy) public onlyOwner {
    resolverProxy = IExtendedResolverWithProof(_resolverProxy);
  }
}