// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IProxyBotSpecialEditionInspector.sol";
import "./IProxyBotRenderer.sol";
import "./IProxyBot.sol";
import "./ProxyBotConfig.sol";

/**
 * @title
 * Proxy Bot
 * https://proxybot.turf.dev/
 *
 * @author
 * Turf NFT
 *
 * @notice
 * Proxy Bot is an access delegation helper that allows you to delegate your NFTs
 * from a vault wallet to a hot wallet, primarily for the purpose of accessing and
 * utilizing those NFTs in wallet-connected environments without ever compromising your vault.
 * This isn't a "security tool" in that we do not block or protect your vault explicitly.
 *
 * We believe that the best security practice is to never connect your vault to any sites, including ours.
 *
 * Proxy Bot is entirely NFT native. A Proxy Token is an NFT you own. It does not
 * require any external contracts or services to function.
 * 
 * This also lets us have fun with the Proxy Token NFT art, offering special editions
 * that are only available to holders of certain projects or tokens.
 * 
 * Here's how it works:
 * 
 * 1. You mint a token to a vault wallet from the Proxy Bot site, probably from a hot wallet.
 * 2. You then transfer that back to a hot wallet. Most cold wallet/vault software
 *    allows transferring NFTs directly, without connecting to something like OpenSea.
 * 3. That token is now "connected" to the vault. Hooray!
 *
 * An integrating website or app should now be able to call the getVaultAddressForDelegate
 * method with a hot wallet address to a the vault address, and redirect its logic to
 * load NFTs for display, token gating, or whatever from that vault. All without
 * ever having to have connected that vault to anything.
 */

contract ProxyBot is IProxyBot, ERC721AQueryable, AccessControl {

  /* ------------------------------------------------------------------------
      S T O R A G E
  ------------------------------------------------------------------------ */

  IProxyBotRenderer public renderer;
  IProxyBotSpecialEditionInspector public specialEditionInspector;

  /// @dev Lets us turn off metadata updates event emits, if they turn out to be too gassy or problematic.
  bool public suppressMetadataUpdates;

  /// @dev Lets us turn off minting. Only to be used in case of emergency. Does not affect other functionality.
  bool public stopMinting;

  /**
   * @dev
   * Why does a "security tool" have an admin role?
   * It's not to core functionality. It's primarily to maintain the renderer and
   * special edition inspector contracts, for display purposes only.
   */
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");  

  /// @dev Counts the times a given token ID has been transferred.
  mapping(uint256 => uint256) public transferCounts;

  /** @dev
   * Track the vault wallet addresses to arrays of tokenIds minted to them that,
   * in turn, have been boomeranged.
   */
  mapping(address => uint256[]) private boomerangedTokenIdsPerVaultWallet;

  /**
   * @dev 
   * A record of each token ID and when it was first minted. This is used to 
   * determine the "age" of a token for display purposes.
   */
  mapping(uint256 => uint256) public mintedBlockNumbers;

  /// @dev Record special editions per token ID.
  mapping(uint256 => string) public appliedSpecialEditions;

  /**
   * @dev
   * Track the first address each token was minted to.
   * Those are the vault wallets we're doing the delagating from.
   */
  mapping(uint256 => address) public vaultWallets;

  /* ------------------------------------------------------------------------
      E V E N T S
  ------------------------------------------------------------------------ */

  /// @dev Triggered after the constructor has executed.
  event Deployed();
  
  /// @dev Alert us to a newly connected vault.
  event NewVaultConnected(uint256 _tokenId);
  
  /// @dev https://eips.ethereum.org/EIPS/eip-4906
  event MetadataUpdate(uint256 _tokenId);
  event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

/* ------------------------------------------------------------------------
      E R R O R S
  ------------------------------------------------------------------------ */

  error NotAnAdminError();
  error InvalidTokenId();
  error WithdrawalFailed();
  error MintStoppedError();

  /* ------------------------------------------------------------------------
      M O D I F I E R S
  ------------------------------------------------------------------------ */

  /// @dev Check if msg.sender has either admin roles.
  modifier onlyAdmin() {
    if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender) && !hasRole(ADMIN_ROLE, msg.sender)){
      revert NotAnAdminError();
    }
    _;
  }

  /* ------------------------------------------------------------------------
      I N I T
  ------------------------------------------------------------------------ */

  constructor() ERC721A("ProxyBotV1", "PBV1") {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    emit Deployed();
  }  

  /**
  * @notice
  * Returns the token URI for the given token ID.
  * @dev
  * Proxy this through to our upgradable renderer.
  * 
  * @param tokenId The token to return metadata for.
  */
  function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
    if(!_exists(tokenId)){
      revert InvalidTokenId();
    }
    return renderer.tokenURI(tokenId);
  }

  /**
  * @notice
  * Returns the ProxyBotConfig.Status of the token with the given ID.
  * 
  * @dev
  * A token's status depends on its transfer history (boomeranging) and the
  * transfer activity of its vault siblings.
  * 
  * We talk about "boomeranging" a lot: That's the short way of saying
  * "minted the token to the vault and then the vault sent it to a hot wallet".
  * 
  * The statuses are as follows:
  *
  * - Pending
  * It's never been boomeranged. It's just sitting in the mint
  * wallet, which presumably is a vault and hasn't been delagated to anyone.
  *    
  * - Connected
  * It's been boomeranged at least once AND is the most recently
  * boomeranged token for its vault wallet.
  * 
  * Note! Subsequent boomeranging of tokens for the same vault wallet will render
  * previously boomeranged tokens invalid.
  *  
  * - Void
  * If it's been boomeranged at least once (so it was valid at some point)
  * AND is NOT the most recently boomeranged token for its vault wallet.
  * 
  * @param tokenId The token to get the status of.
  */
  function getStatus(uint256 tokenId) public view returns (ProxyBotConfig.Status) {
    // You can also deactivate (void) a token by sending it to the dead address.
    // Would check for zero address here too but you can't send it to the zero address, ERC721A prevents that.
    if(ownerOf(tokenId) == 0x000000000000000000000000000000000000dEaD){
      return ProxyBotConfig.Status.Void;
    }

    if(!isBoomeranged(tokenId)){
      return ProxyBotConfig.Status.Pending;
    } else if(isMostRecentBoomerangedTokenForWallet(tokenId)){
      return ProxyBotConfig.Status.Connected;
    } else {
      return ProxyBotConfig.Status.Void;
    }
  }

  /**
  * @notice
  * Mint a new token to the given address.
  * Accepts a wallet address (presumably a vault) and mints to it.
  * Also, if you are claiming to be minting a special edition, pass in that info
  * and we'll verify it on-chain.
  
  * @param to The address to mint to.
  * @param expectedSpecialEditionContract The address of a contract that should warrant a special edition. Pass in a zero address if you don't want to check.
  * @param checkSpecificTokenId If true, we'll check ownership of a specific tokenId as part of the special edition verification.
  * @param editionTokenId The token ID to check ownership of, if checkSpecificTokenId is true.
  * @param checkVaultForSpecialEdition If true, we'll check the vault wallet for ownership of the special edition token, otherwise msg.sender.
  */
  function mint(
    address to,
    address expectedSpecialEditionContract,
    bool checkSpecificTokenId,
    uint256 editionTokenId,
    bool checkVaultForSpecialEdition
  ) public payable {

    if(stopMinting){
      revert MintStoppedError();
    }

    uint256 totalMinted = _totalMinted();

    // Record when this mint occurred.
    mintedBlockNumbers[totalMinted] = block.number;

    // Record the first address this token was minted to, which is the vault wallet address.
    vaultWallets[totalMinted] = to;

    if(expectedSpecialEditionContract != address(0)){
      // Check if any special edition exists
      // The first value in the tuple, if true, will allow us to use the second value, which is the name of the edition.
      (bool specialEditionExists, string memory specialEditionName) = validateSpecialEdition(
        (checkVaultForSpecialEdition ? to : msg.sender),
        expectedSpecialEditionContract,
        checkSpecificTokenId,
        editionTokenId
      );

      // If it is, log the special edition:
      if(specialEditionExists) appliedSpecialEditions[totalMinted] = specialEditionName;
    }

    _mint(to, 1);
  }

  /** 
  * @notice
  * Return if the given wallet address holds a token by the given contract.
  * The return is a tuple, with the first bool whether the holding is legit,
  * the second value is a string with the name of the special edition.
  * 
  * @param ownerAddress The wallet to which this special edition granting NFT belongs.
  * @param contractAddress The address of the contract that should warrant a special edition.
  * @param checkSpecificTokenId If true, we'll check ownership of the specific tokenId as part of the special edition verification.
  * @param editionTokenId The tokenId to check ownership of, if checkSpecificTokenId is true.
  * 
  */
  function validateSpecialEdition(
    address ownerAddress,
    address contractAddress,
    bool checkSpecificTokenId,
    uint256 editionTokenId
  ) public view returns (bool, string memory) {
    return IProxyBotSpecialEditionInspector(specialEditionInspector)
      .validateSpecialEdition(
        ownerAddress,
        contractAddress,
        checkSpecificTokenId,
        editionTokenId
      );
  }

  /* ------------------------------------------------------------------------
      A C C E S S O R S
  ------------------------------------------------------------------------ */

  /**
  * @notice
  * Given a hot wallet's address, returns the address of the vault it proxies to,
  * if any active connections exist.
  * 
  * This is the method to call off-chain for proxy access purposes.
  * 
  * @param delegateAddress The address to check.
  * @return The address of the vault that the given address proxies to, or a zero address if none exists.
  */
  function getVaultAddressForDelegate(address delegateAddress) public view returns (address) {
    uint256[] memory tokenIds = tokensOfOwner(delegateAddress);
    for(uint256 i; i < tokenIds.length; i++){
      if(getStatus(tokenIds[i]) == ProxyBotConfig.Status.Connected){
        return getVaultWallet(tokenIds[i]);
      }
    }
    return address(0x0); 
  }

  /// @notice Get the minted block number for the given token ID.
  /// @param tokenId The token to get the minted block number for.
  /// @return The minted block number.
  function getMintedBlock(uint256 tokenId) public view returns (uint256) {
    return mintedBlockNumbers[tokenId];
  }

  /**
  * @dev
  * Returns whether the given token ID is the most recently boomeranged token for its vault wallet.
  * This is used to determine the status of a token.
  * 
  * @param tokenId The token to check.
  */
  function isMostRecentBoomerangedTokenForWallet(uint256 tokenId) public view returns (bool) {
    uint256[] memory boomerangedTokenIds = boomerangedTokenIdsPerVaultWallet[vaultWallets[tokenId]];
    if(boomerangedTokenIds.length == 0){
      return false;
    }
    return boomerangedTokenIds[boomerangedTokenIds.length - 1] == tokenId;
  }

  /** 
  * @dev
  * Determine if the given tokenId has been boomeranged at least once.
  * E.g, it's been minted to its (presumably) vault wallet, and then transferred
  * to its (presumably) hot wallet.
  * 
  * @param tokenId The token to check.
  */
  function isBoomeranged(uint256 tokenId) public view returns (bool) {
    return transferCounts[tokenId] > 0;
  }

  /**
   * @notice
   * How many connected tokens does the given wallet hold? Call this off-chainprobably, for web UI purposes.
   * Note that this can be called on a hot wallet, to see if it's holding any Connected tokens.
   * 
   * @param a The wallet address to check.
   */
  function heldConnectedTokensCount(address a) public view returns (uint256) {
    uint256[] memory tokenIds = tokensOfOwner(a);
    uint256 activeTokenCount = 0;
    uint256 l = tokenIds.length;
    for(uint256 i; i < l; i++){
      if(getStatus(tokenIds[i]) == ProxyBotConfig.Status.Connected){
        unchecked {
          activeTokenCount++;
        }
      }
    }
    return activeTokenCount;
  }

  /// @notice Return the number of active tokens boomeranged out by a given vault address.
  /// @param a The vault address to check.
  function connectedTokensCountForVault(address a) public view returns (uint256) {
    uint256[] memory boomerangedTokenIds = boomerangedTokenIdsPerVaultWallet[a];
    uint256 activeTokenCount = 0;
    uint256 l = boomerangedTokenIds.length;
    for(uint256 i; i < l; i++){
      if(getStatus(boomerangedTokenIds[i]) == ProxyBotConfig.Status.Connected){
        unchecked {
          activeTokenCount++;
        }
      }
    }
    return activeTokenCount;
  }

  // @notice Get the special edition for the given token ID.
  // @param tokenId The token to get the special edition for.
  // @return A tuple, with the first value being a bool indicating whether a
  //         special edition exists, and the second value being the name of the special edition.
  function getAppliedSpecialEdition(uint256 tokenId) public view returns (bool, string memory) {
    string memory e = appliedSpecialEditions[tokenId];
    return (!ProxyBotConfig.stringsEqual(e, ""), e);
  }

  /// @notice Return the vault wallet address for the given token ID.
  /// @param tokenId The token to get the vault wallet address for.
  /// @return The vault wallet address.
  function getVaultWallet(uint256 tokenId) public view returns (address) {
    return vaultWallets[tokenId];
  }

  /* ------------------------------------------------------------------------
      A D M I N  &  M A I N T E N A N C E
  ------------------------------------------------------------------------ */
  // We don't really "administer" individual NFTs: we can't.
  // But we do need to update art and features, like the special editions.

  /** 
   * @dev Toggle suppressMetadataUpdates.
   * If true, we won't trigger the MetadataUpdate events during transfer events.
   * Can't really see using this but who knows, maybe we grow to hate it.
  */
  function toggleSuppressMetadataUpdates() external onlyAdmin {
    suppressMetadataUpdates = !suppressMetadataUpdates;
  }

  /// @dev Toggle stopMinting.
  /// If true, we won't allow any more tokens to be minted.
  /// Intended to be used in case of emergency, or if we want to force new users
  /// over to an upgraded contract.
  function toggleStopMinting() external onlyAdmin {
    stopMinting = !stopMinting;
  }

  /// @dev Set the address of the renderer contract.
  function setRendererAddress(IProxyBotRenderer _renderer) external onlyAdmin {
    renderer = _renderer;
    emit BatchMetadataUpdate(_startTokenId(), _totalMinted());
  }

  /// @dev Set the address of the special edition inspector contract. We'll update it as we add possible special edition art.
  function setSpecialEditionInspectorAddress(IProxyBotSpecialEditionInspector _specialEditionInspector) external onlyAdmin {
    specialEditionInspector = _specialEditionInspector;
  }  

  /* ------------------------------------------------------------------------
      B O O K K E E P I N G
  ------------------------------------------------------------------------ */

  /** 
  * @notice
  * The _afterTokenTransfers hook does a lot of the heavy lifting for Proxy Bot.
  * The address a token gets transferred to, and from whom, drives the core
  * functionality of tracking token connectivity. And since we're updating state,
  * we emit MetadataUpdate as appropriate to keep our views on OpenSea looking fresh.
  */
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal override {

    // Don't bother if from is zero, since that's an initial mint which is to a vault wallet.
    // That's automatically in the default state of Pending, which is the default metadata.
    if(from != address(0)){
      // Have to operate on each consecutive token, from startTokenId to startTokenId + quantity
      for(uint256 i; i < quantity; i++){
        uint256 tokenId = startTokenId + i;
        // Increment the transfer count for this token
        transferCounts[tokenId] += 1;

        // If this is the first time this token has been transferred, add it to the boomerangedTokenIdsPerVautlWallet mapping.
        // This is used to determine if a given vault wallet address has any boomeranged tokens,
        // and also we can later tell if the vault wallet has done other boomeranging, rendering previous tokens invalid.
        // A caveat here is that if your vault ends up with a huge amount of tokens, this could become expensive. But, don't do that?
        if(transferCounts[tokenId] == 1){
          boomerangedTokenIdsPerVaultWallet[from].push(tokenId);
          emit NewVaultConnected(tokenId);

          // Emit the MetaDataUpdated event for tokens that have been boomeranged, which includes this new one.
          // This keeps us fresh in OpenSea and friends, so our data looks kind of live there.
          // If this becomes too burdensome we can turn it off with the suppressMetadataUpdates flag.
          if(!suppressMetadataUpdates){
            uint256[] memory boomerangedTokenIds = boomerangedTokenIdsPerVaultWallet[from];
            uint256 length = boomerangedTokenIds.length;
            for(uint256 j; j < length; ++j){
              // We can skip any but the most recently added and the one before that,
              // since that first one has already been deactivated previously. No need to sync those.
              if(length > 2 && j < length - 2){
                continue;
              }
              emit MetadataUpdate(boomerangedTokenIds[j]);
            }
          }
        }
      }
    }
  }

  function supportsInterface(bytes4 _interfaceId)
  public
  view
  virtual
  override(ERC721A, IERC721A, AccessControl)
  returns (bool)
  {
    return
    super.supportsInterface(_interfaceId) ||
    ERC721A.supportsInterface(_interfaceId) ||
    _interfaceId == bytes4(0x49064906); // Support for MetadataUpdate
  }

  // Override ERC721AQueryable so we can access this method internally.
  // They say that "it is meant to be called off-chain", and we are, but we access it
  // from another method here, so the original `external` modifier is not appropriate.
  function tokensOfOwner(address owner) public view virtual override returns (uint256[] memory) {
    uint256 tokenIdsIdx;
    address currOwnershipAddr;
    uint256 tokenIdsLength = balanceOf(owner);
    uint256[] memory tokenIds = new uint256[](tokenIdsLength);
    TokenOwnership memory ownership;
    for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
        ownership = _ownershipAt(i);
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

  function transferERC20(address tokenAddress, address to, uint tokens) public onlyAdmin returns (bool success) {
    return IERC20(tokenAddress).transfer(to, tokens);
  }
  
  function transferERC721(IERC721 token, uint256 tokenId, address to) external onlyAdmin {
    token.safeTransferFrom(address(this), to, tokenId);
  }  

  function withdrawAll() external onlyAdmin {
    (bool success, ) = payable(msg.sender).call{
      value: address(this).balance
    }("");

    if (!success) {
      revert WithdrawalFailed();
    }
  }

  receive() external payable {}

}