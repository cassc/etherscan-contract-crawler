/// SPDX-License-Identifier CC0-1.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import {IERC4906} from "./IERC4906.sol";
import {IReapersGambit} from "./IReapersGambit.sol";
import {IWrappedReaperRenderer} from "./IWrappedReaperRenderer.sol";

import "./WrappedReaperUtils.sol";

// &&&&&&&&&&&&&&&&&&&&%#%#%%%%%##///*****,,****////((((((#####%%%%%%%%%&&&&&&&&&&&
// &&&&&&&&&&&&&&%%%%##(((((##((*,,..........(,,,,,,**//((((((###%%%%#%%%%%%%%%%&&&
// &&&&&&%&&&%%##((//*,...,,,,,.. [email protected]&*      &&@&......,**////((((####((####%%%%%&&&
// &&&&&&%%%%%%###*,,,[email protected]&&@&,(&#/     #@@@@@     ..,,**//////((((((((###%%%%%&
// &&&&&&&&&%%%%#(/*,,[email protected]@ ..   .   &    &@@@@@@@&     ....,,,*****///((((###%%%%%%
// &&&&&&&&&&%%%#((//#&....,,....   &  *&&@@@@@@@@@&   ......,,,,***///(((###%%%%%%
// &&&&&&&&%%%%##((/(,,,,...,,...   & ,@&@@@@@@@@@@@(   .....,,,,***///(((###%%%%%%
// &&&&&&&&%%%%%##((/******,,,,.... &#@@@@@@@@@@@@@@@   ....,,,,***//(((####%%%%%%%
// &&&&&&&&&%%%%%##(((////**,,,,[email protected]@&@@@@@@@@@@@@@@@ ...,,,,**///(((#####%%%%%%%%
// &&&&&&&&&&%%%%%##w((((//***,,,.. @@@&&&@@@@@@@@&@@@@...,,**///(((######%%%%%%%%%
// &&&&&&&&&&&%%%%%####(((//***,,,..&...&&@@@@@@@@&.&@&.,,,**///((((#####%%%%%%%%%&
// &&&&&&&&&&&%%%%%%###((((//***,,,.#...&&@@@@@@@@@#@@&,,,,**///(((((#####%%%%%%%%%
// &&&&&&&&&%%%%%%%####(((///***,,,,,...&@@@@@@@@@@&(@f,,,,****////(((((#####%%%%%%
// &&&&%%%%%%%%####(((((////****,,,, *.,@&@@@@@@@@@&..,,,,,,******/////(((((######%
// %%%%%%#####(((((/////*****,,,,,,..%.&@@@%@@@@@@@@.,,,,,,,,,,,******/////((((((##
// #######(((((////******,,,,,,,,....&&@@@@@@@@@@@@@,,,.,,,,,,,,,,,*****////((((((#
// #####(((((////*****,,,,,,,,,[email protected]&@@@@@@@@@@@@@&..,...,,,,,,,,,,****/////(((((#
// ######(((((//*****,,,,,,,,....r%#@@@@@&&@&&&&&&%%......,,,,,,,,,*****////(((((##
// #######((((////*****,,,,,....*#,#@@@@&@@&&&&%#%##.......,,,,,,*****///(((((#####
// #######((((((/////****,,,,,,[email protected]@@@&/@&&&&&%%####,,,,.,,,,,***////((((((#####%%%%
// %%%%###########(((((((///*e#%%%%%%%&&&&%%%%%%%#(*****/*/(/((##((((#%%%%%%%%&&&&&
// &&&&&&&&&&&@@@@@&&&&&%%%%%(#####&&&&&@&@@@@@e&&&&&&&&%#&%%#%#%%&&&&&&&&&&&&&@@@@

/// @title WrappedReaper.sol
/// @author unknown
/// @notice Behold, O seeker of arcane wisdom!
///         The enigmatic WrappedReaper grants the mages of minting a sanctuary to safeguard their precious
///         $RG from the clutches of the reaper herself. It bestows upon them the ability to engage in secure exchanges.
///         Yet, lo and behold, in return for these mystical boons, minters must offer up a sacrificial offering,
///         meticulously calculated using the enchanted scythe's bonding curve.
/// @custom:warning This smart contract has **not** been audited. Use at your own risk.
contract WrappedReaper is IERC4906, ERC721, ERC721Enumerable, ReentrancyGuard {

  /// @notice The Bar struct maintains the properties specific to a minted token.
  /// @param minter The address who originally minted the token.
  /// @param mintBlock The block number when the mint occurred.
  /// @param deathBlock The block the number when the minter's fate would be sealed.
  /// @param stake The number of tokens staked inside the bar.
  /// @param blockTimestamp The UNIX timestamp of when the bar was minted.
  struct Bar {
    address minter;
    uint256 mintBlock;
    uint256 deathBlock;
    uint256 stake;
    uint256 blockTimestamp;
  }

  /// @notice The Burn struct captures properties of a burn.
  /// @param burnBlock The block at which the token was burned.
  /// @param stake The amount of $RG which was originally staked.
  struct Burn {
    uint256 burnBlock;
    uint256 stake;
  }

  uint256 private constant _BP = 10000;
  uint256 private constant _GRACE_PERIOD = 64800;
  uint256 private constant _MIN_STAKE =   666_666 * 10 ** WrappedReaperUtils.DECIMALS;   //     666,666 $RG
  uint256 private constant _MAX_STAKE = 100_000_000 * 10 ** WrappedReaperUtils.DECIMALS; // 100,000,000 $RG

  IReapersGambit private immutable _reapersGambit;
  IWrappedReaperRenderer private immutable _wrappedReaperRenderer;

  uint256 private immutable _maxSupply;
  uint256 private immutable _minTaxBasisPoints;
  uint256 private immutable _maxTaxBasisPoints;
  uint256 private immutable _bladeWidth;
  uint256 private immutable _bladeDiscountBasisPoints;

  mapping(uint256 => Bar) private _bars;
  mapping(uint256 => Burn) private _burns;
  uint256 private _nextTokenId;

  /// @notice WrappedReaper constructor.
  /// @param reapersGambit The address of the deployment of ReapersGambit.
  /// @param maxSupply_ The maximum possible circulating supply of the token. Invariant.
  /// @param minTaxBasisPoints__ The absolute minimum tribute which must be paid for a mint.
  /// @param maxTaxBasisPoints__ The absolute maximum tribute which must be paid for a mint.
  /// @param bladeWidth__ The size of the blade of the scythe (#tokens up to maxSupply which receive a discount).
  /// @param bladeDiscountBasisPoints__ The maximum discount that can be applied to minters within the bladeWidth__.
  constructor(
    address reapersGambit,
    address wrappedReaperRenderer,
    uint256 maxSupply_,
    uint256 minTaxBasisPoints__,
    uint256 maxTaxBasisPoints__,
    uint256 bladeWidth__,
    uint256 bladeDiscountBasisPoints__
) ERC721("WRAPPED REAPER", "WRG") {
    require(minTaxBasisPoints__ <= maxTaxBasisPoints__);
    require(bladeWidth__ <= maxSupply_);
    require(bladeDiscountBasisPoints__ <= (maxTaxBasisPoints__ - minTaxBasisPoints__));
    require(_MIN_STAKE >= _BP);
    require(_MIN_STAKE <= _MAX_STAKE);

    _reapersGambit = IReapersGambit(reapersGambit);
    _wrappedReaperRenderer = IWrappedReaperRenderer(wrappedReaperRenderer);
    _maxSupply = maxSupply_;
    _minTaxBasisPoints = minTaxBasisPoints__;
    _maxTaxBasisPoints = maxTaxBasisPoints__;
    _bladeWidth = bladeWidth__;
    _bladeDiscountBasisPoints = bladeDiscountBasisPoints__;

    require(_reapersGambit.approve(address(this), 2**256 - 1));
  }

  /// @notice Use the babylonian method to find the square root of an unsigned integer.
  /// @custom:url https://github.com/Uniswap/v2-core/blob/4dd59067c76dea4a0e8e4bfdda41877a6b16dedc/contracts/libraries/Math.sol#L11
  function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
      z = y;
      uint x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }

  /// @notice Scales an input value as per the specified basis points.
  function costBasis(uint256 value, uint256 basisPoints) public pure returns (uint256) {
    /// @dev Ensure that we don't underflow representation.
    require(value >= _BP);
    // A basis point is a hundredth of a percent. 1% = 100 basis points.
    return (value * basisPoints) / _BP;
  }

  /// @notice Calculates the size of the tribute measured in $RG which must be paid for new mints.
  /// @param currentSupply The current circulating supply of WrappedReaper.
  /// @param stake_ The amount the caller intends to stake.
  /// @return The total price of the mint; this is the base price plus the tribute.
  function scythe(uint256 currentSupply, uint256 stake_) public view returns (uint256) {
    require(currentSupply < _maxSupply, "WRG: supply cap reached");

    /// @dev Defines the token values which lie within the period of linear taxation.
    uint256 handleWidth = _maxSupply - _bladeWidth;

    uint256 maxTax = costBasis(stake_, _maxTaxBasisPoints);
    uint256 minTax = costBasis(stake_, _minTaxBasisPoints);
    uint256 bladeDiscount = costBasis(stake_, _bladeDiscountBasisPoints);

    /// @dev Calculates the linear tax allocation assuming it would go on forever without entering
    ///      the blade of the curve. This makes it capable of expressing values of tax that are larger
    ///      than the specified maximum.
    ///
    ///      Within the handle interval, An a increment of tax is accumulated for each new token identifier,
    ///      making them increasingly more costly to create.
    ///
    ///      This is effectively (currentNumberOfTokens * amountOfLinearTaxToAddPerToken) + minimumTaxPerToken.
    ///
    ///      If there is no handle width, then we assume a cutoff at the maxTax (since this is where the blade
    ///      begins).
    uint256 linearTax = handleWidth > 0
      ? (((maxTax - minTax) * currentSupply) / handleWidth) + minTax
      : maxTax;

    /// @dev Enforces that tax will never exceed the specified maxTax. The only point along the scythe where
    ///      tax values would be computed greater than the maxTax is when the currentSupply exceeds the handle
    ///      width. At this point, we initialize the blade calculation.
    uint256 linearPrice = stake_ + (linearTax < maxTax ? linearTax : maxTax);

    /// @dev If the currentSupply exceeds the handleWidth, we are inside the vicinity of the scythe curve, and can
    ///      start applying price discounts for the length of the blade.
    if (currentSupply > handleWidth)
      /// @dev Assuming a quadratic curve with the formula y = x ** 2, we can interpret the maximum_discount y to
      ///      resolve to an x position of sqrt(y). Taking x to represent a unitless axis, we can transpose increments
      ///      in currentSupply to represent equivalent increments along the x axis. We can therefore calculate the
      ///      equivalent y on the quadratic curve by using this position, which yields the shape of the blade.
      return linearPrice - ((((currentSupply - handleWidth) * sqrt(bladeDiscount)) / _bladeWidth) ** 2);

    /// @dev Returns the linear taxation price.
    return linearPrice;
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
  internal
  override(ERC721, ERC721Enumerable)
  {
    super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }

  function supportsInterface(bytes4 interfaceId)
  public
  view
  override(IERC165, ERC721, ERC721Enumerable)
  returns (bool)
  {
    /// @custom:url https://eips.ethereum.org/EIPS/eip-4906#reference-implementation
    /// @dev See {IERC165-supportsInterface}.
    return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
  }

  /// @notice Mints a WrappedReaper NFT in exchange for the base price and tribute as calculated by
  ///         the scythe curve. The tribute is immediately burned. The price of the NFT is bound
  ///         inside of the token and can be retrieved upon burning the token.
  ///         The scythe curve is a function of the currentSupply; different values of the currentSupply
  ///         will result in different values of tribute required.
  ///         The contract also imposes a maximum limit to the circulating supply of the collection.
  /// @notice Callers must ReapersGambit.approve() the WrappedReaper before attempting to mint.
  /// @param amountToStake The amount of $RG the caller wishes to lock in.
  /// @param maximumPrice Enable frontrun protection for the caller. Here, the caller can specify the maximum
  ///        price to ensure the price of a token remains within a tolerable bound and has not been manipulated
  ///        by searchers in an effort to pay an unexpectedly higher tribute.
  function mint(uint256 amountToStake, uint256 maximumPrice) external nonReentrant returns (bool) {
    uint256 currentSupply = totalSupply();

    require(amountToStake >= _MIN_STAKE && amountToStake <= _MAX_STAKE && amountToStake <= maximumPrice, "WRG: invalid stake");
    require(currentSupply < _maxSupply, "WRG: supply cap reached");

    uint256 total = scythe(currentSupply, amountToStake);
    require(total <= maximumPrice && total >= amountToStake, "WRG: frontrun protection");

    Bar memory bar = Bar(msg.sender, block.number, _reapersGambit.KnowDeath(msg.sender), amountToStake, block.timestamp);

    /// @notice It is possible to attain $RG and mint $WRG within the same block; however, it is not
    ///         possible to transfer $RG from an account that has reached its deathBlock.
    /// @dev We are making a conscious decision here to disable immortal accounts from minting.
    ///      Immortal accounts have a deathBlock of zero.
    require(bar.deathBlock > bar.mintBlock && proximity(bar.deathBlock, bar.mintBlock) <= _GRACE_PERIOD, "cannot escape death");

    _bars[_nextTokenId] = bar;

    /// @dev Ensure the caller has configured a sufficient allowance for this action.
    require(_reapersGambit.allowance(msg.sender, address(this)) >= total, "ERC20: insufficient allowance");

    /// @dev Ensure the caller has sufficient balance for these transactions.
    require(_reapersGambit.balanceOf(msg.sender) >= total, "ERC20: transfer amount exceeds balance");

    /// @notice Transfer the total cost from the caller to this contract.
    /// @dev The caller must have approved a sufficient allowance for this to succeed.
    require(_reapersGambit.transferFrom(msg.sender, address(this), amountToStake), "WRG: failed to transfer");

    /// @notice If the total amount transferred is greater than the price of the token, the caller has
    ///         provided a tribute which must be burned.
    if (total > amountToStake)
      /// @dev Transfers the tribute to the vanity burn address.
      require(_reapersGambit.transferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), total - amountToStake), "WRG: failed to burn");

    _safeMint(msg.sender, _nextTokenId++);

    return true;
  }

  /// @notice Allows the owner of a token to burn and redeem funds to a specified address.
  ///         Be careful! It is possible to burn tokens to an address which may already
  ///         have died...
  /// @dev We don't use ERC721Burnable because we require the specification of a custom to address.
  ///      Without this, it's highly likely that anyone who attempted to redeem the token would get
  ///      rekt, since it is likely that sufficient time would have passed that the address would
  ///      have been lost to the reaper by that point.
  /// @param to The address to unlock staked $RG to.
  function burn(uint256 tokenId, address to) external nonReentrant {
    /// @custom:url https://github.com/OpenZeppelin/openzeppelin-contracts/blob/dfef6a68ee18dbd2e1f5a099061a3b8a0e404485/contracts/token/ERC721/extensions/ERC721Burnable.sol#L23
    require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");

    Bar memory bar = _bars[tokenId];

    require(bar.deathBlock > 0 && bar.stake > 0, "WRG: invalid token");

    delete _bars[tokenId];

    _burn(tokenId);

    Burn memory burned = Burn(block.number, bar.stake);

    _burns[tokenId] = burned;

    require(_reapersGambit.transferFrom(address(this), to, bar.stake), "WRG: failed to transfer");

    /// @notice Ensure OpenSea updates the metadata for burned tokens to avoid confusion on the frontend.
    /// @custom:url https://eips.ethereum.org/EIPS/eip-4906
    emit MetadataUpdate(tokenId);
  }

  // @notice Returns a string representing a json-encoded OpenSea metadata trait.
  // @param traitType The trait type.
  // @param value The value of the trait.
  function _tokenURIJsonTrait(
    string memory traitType,
    string memory value
  ) private pure returns (bytes memory) {
    return abi.encodePacked(
      '{',
        '"trait_type":"', traitType, '",',
        '"value":', value,
      '}'
    );
  }

  /// @notice Calculates the corresponding saturation for a given stake.
  /// @dev The amount staked.
  /// @return The saturation value (0 -> 3).
  function saturation(uint256 stake) public pure returns (uint256) {
    // slither-disable-next-line incorrect-equality
    if (stake <= _MIN_STAKE) return 0;
    // slither-disable-next-line incorrect-equality
    if (stake >= _MAX_STAKE) return 3;

    // slither-disable-next-line incorrect-equality
    if (stake >= 7_000_000 * 10 ** WrappedReaperUtils.DECIMALS) return 3;
    // slither-disable-next-line incorrect-equality
    if (stake >= 3_000_000 * 10 ** WrappedReaperUtils.DECIMALS) return 2;
    // slither-disable-next-line incorrect-equality
    if (stake >= 1_000_000 * 10 ** WrappedReaperUtils.DECIMALS) return 1;

    return 0;
  }

  /// @notice Calculates the phase for a given deathBlock.
  /// @param deathBlock The block depth of death at the time of mint.
  /// @param mintBlock The block depth at time of mint.
  /// @return The phase of the death.
  function phase(uint256 deathBlock, uint256 mintBlock) public pure returns (uint256) {
    uint256 delta = deathBlock - mintBlock;
    // slither-disable-next-line incorrect-equality
    return (delta <= 1800) ? 3 : (delta <= 22800) ? 2 : (delta <= 43800) ? 1 : 0;
  }


  /// @notice Computes how close a mint was to death. The closer to death, the higher the value.
  /// @dev Relies on the fact that deathBlock must be >= mintBlock, and the difference between
  ///      these must be <= to the Reaper's nine day grace period. Also depends on 0.8.x's builtin
  ///      underflow protection.
  /// @return The proximity of the token to death.
  function proximity(uint256 deathBlock, uint256 mintBlock) public pure returns (uint256) {
    return _GRACE_PERIOD - (deathBlock - mintBlock);
  }

  /// @notice Returns the title for the phase attribute.
  /// @param phase_ The phase parameter.
  /// @return The equivalent title for the value of phase.
  function _phaseTitle(uint256 phase_) private pure returns (string memory) {
    string[4] memory phases__ = ["Spirited", "Intrepid", "Daring", "Indomitable"];
    return phases__[phase_];
  }

  /// @notice Returns the title for the saturation attribute based on the level of saturation.
  /// @param saturation_ The saturation parameter.
  /// @return The equivalent title for the value of saturation.
  function _saturationTitle(uint256 saturation_) private pure returns (string memory) {
    string[4] memory saturations__ = ["Daylight", "Twilight", "Dusk", "Moonlight"];
    return saturations__[saturation_];
  }

  /// @notice Computes the name for an item of the collection.
  /// @param tokenId The token identifier.
  /// @param suffix Characters to render immediately after the collection title.
  /// @return The name for the tokenId.
  function _tokenURIName(uint256 tokenId, string memory suffix) private pure returns (bytes memory) {
    return abi.encodePacked("WRAPPED REAPER #", Strings.toString(tokenId), suffix);
  }

  /// @notice Defines the core skeleton of generated on-chain metadata.
  /// @param name Readable name of the token.
  /// @param imageData Plaintext image data string.
  /// @param attributes Plaintext OpenSea metadata JSON attributes, without enclosing brackets.
  /// @return a Base64 encoded JSON string.
  function tokenURISkeleton(
    bytes memory name,
    bytes memory imageData,
    bytes memory attributes
  ) private pure returns (string memory) {
    return string(
      abi.encodePacked(
        "data:application/json;base64,",
        Base64.encode(
          bytes(
            abi.encodePacked(
              '{',
              '"name":"', name, '",',
              '"description":', '"', unicode"💀 ⚔️ CHEAT DEATH ⚔️ 💀\\n\\nWrapped Reaper is a community extension to the Reaper's Gambit ecosystem that enables holders to safeguard their hoard from the clutches of the reaper.\\n\\n$RG can be staked inside of Wrapped Reaper in exchange for a tribute to the burn address.\\n\\nLearn more at https://reapersgambit.com", '",',
              '"image":"data:image/svg+xml;base64,', Base64.encode(imageData), '",',
              '"attributes":[', attributes, ']',
              '}'
            )
          )
        )
      )
    );
  }

  /// @notice Computes the Base64 encoded JSON metadata compatible with the OpenSea metadata standard.
  ///         Alongside image attributes, the on-chain SVG is delivered via the `image` attribute opposed
  ///         to image_data; this is because the image data is itself a Base64 encoded XML URI, which this
  ///         compliant with the rendering specification.
  /// @param tokenId The identifier of the token.
  /// @param stake The amount of $RG locked inside the token.
  /// @param deathBlock The block depth at which the minter of the block were to perish.
  /// @param mintBlock The block depth when the token was originally minted.
  /// @param minter The address responsible for minting the block.
  /// @param blockTimestamp The block timestamp when the token was minted.
  /// @return a Base64 encoded JSON string.
  function barTokenURIData(
    uint256 tokenId,
    uint256 stake,
    uint256 deathBlock,
    uint256 mintBlock,
    address minter,
    uint256 blockTimestamp
  ) public view returns (string memory) {

    uint256 saturation_ = saturation(stake);
    uint256 phase_ = phase(deathBlock, mintBlock);

    bytes memory attributes = abi.encodePacked(
      _tokenURIJsonTrait("Burned", '"No"'), ',',
      _tokenURIJsonTrait("Staked", Strings.toString(stake / 10 ** WrappedReaperUtils.DECIMALS)), ',',
      _tokenURIJsonTrait("Phase", string(abi.encodePacked('"', _phaseTitle(phase_), '"'))), ',',
      _tokenURIJsonTrait("Saturation", string(abi.encodePacked('"', _saturationTitle(saturation_), '"'))), ',',
      string(abi.encodePacked('{"display_type": "number", "trait_type": "Proximity", "value": ', Strings.toString(proximity(deathBlock, mintBlock)), '}')), ',',
      _tokenURIJsonTrait("Minter", string(abi.encodePacked('"', WrappedReaperUtils.short(minter), '"'))), ',',
      string(abi.encodePacked('{"display_type": "date", "trait_type": "Minted", "value": ', Strings.toString(blockTimestamp), '}'))
    );

    return tokenURISkeleton(
      _tokenURIName(tokenId, ""),
      _wrappedReaperRenderer.barTokenURIDataImage(tokenId, stake, mintBlock, minter, saturation_, phase_),
      attributes
    );
  }

  /// @notice Computes a base64-encoded OpenSea-compatible metadata json for an active stake.
  /// @param tokenId Identifier of the token.
  /// @param bar The Bar object which corresponds to the provided tokenId.
  /// @return The base64-encoded tokenURI.
  function _barTokenURI(uint256 tokenId, Bar memory bar) private view returns (string memory) {
    // Redirect call to underlying implementation.
    return barTokenURIData(tokenId, bar.stake, bar.deathBlock, bar.mintBlock, bar.minter, bar.blockTimestamp);
  }

  /// @notice Computes a base64-encoded OpenSea-compatible metadata json for a burned stake.
  /// @param tokenId Identifier of the token.
  /// @param stake The amount which was originall staked in the burned token.
  /// @return The base64-encoded tokenURI.
  function burnTokenURIData(
    uint256 tokenId,
    uint256 stake
  ) public view returns (string memory) {
    uint256 saturation_ = saturation(stake);

    return tokenURISkeleton(
      _tokenURIName(tokenId, " [BURNED]"),
      _wrappedReaperRenderer.burnTokenURIDataImage(saturation_),
      _tokenURIJsonTrait("Burned", '"Yes"')
    );
  }

  /// @notice Computes a base64-encoded OpenSea-compatible metadata json for a burned stake.
  /// @param tokenId Identifier of the token.
  /// @param burned The Burn object which corresponds to the provided tokenId.
  /// @return The base64-encoded tokenURI.
  function _burnTokenURI(uint256 tokenId, Burn memory burned) private view returns (string memory) {
    return burnTokenURIData(tokenId, burned.stake);
    // Redirect call to underlying implementation.
    uint256 saturation_ = saturation(burned.stake);
  }

  /// @notice Attempts to return the base64 encoded tokenURI for existing tokens.
  /// @dev Will fail for tokens which have not been created - these are tokens which
  ///      possess EITHER a corresponding Bar instance OR a Burn instance.
  /// @dev It is not be possible to mint bars with a zero deathBlock.
  /// @return The tokenURI.
  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    Burn memory burned = _burns[tokenId];

    if (burned.burnBlock > 0) return _burnTokenURI(tokenId, burned);

    Bar memory bar = _bars[tokenId];

    require(bar.deathBlock > 0, "ERC721: invalid token ID");

    return _barTokenURI(tokenId, bar);
  }

  /// @return The minimum possible amount of $RG that can be staked.
  function minStake() external pure returns (uint256){
    return _MIN_STAKE;
  }

  /// @return The maximum possible amount of $RG that can be staked.
  function maxStake() external pure returns (uint256){
    return _MAX_STAKE;
  }

  /// @return The decimal units of $RG.
  function decimals() external pure returns (uint256){
    return WrappedReaperUtils.DECIMALS;
  }

  /// @return The maximum possible supply of tokens at any one time. Invariant.
  ///         If the limit is reached, burning new tokens will permit new tokens
  ///         to be created.
  function maxSupply() external view returns (uint256){
    return _maxSupply;
  }

  /// @return The minimum possible fee to pay for a mint.
  function minTaxBasisPoints() external view returns (uint256){
    return _minTaxBasisPoints;
  }

  /// @return The maximum possible additional fee to pay for a mint.
  function maxTaxBasisPoints() external view returns (uint256){
    return _maxTaxBasisPoints;
  }

  /// @return The width of the blade. This is the number of tokens
  ///         leading up to the maximum supply which are subject to
  ///         a discount on the scythe curve.
  function bladeWidth() external view returns (uint256){
    return _bladeWidth;
  }

  /// @return The maximum possible discount from the maxTax, in $RG.
  /// @dev For a nonzero bladeWidth, the maximum discount is applied
  ///      to the maximum supply token.
  function bladeDiscountBasisPoints() external view returns (uint256){
    return _bladeDiscountBasisPoints;
  }

  /// @notice Computes the total cost for the intention of staking the
  ///         caller-defined stake.
  /// @param stake__ The amount of $RG intended to be staked.
  /// @return The current position of the scythe for the specified staking amount.
  // slither-disable-next-line naming-convention
  function currentScythe(uint256 stake__) public view returns (uint256) {
    return scythe(totalSupply(), stake__);
  }

}