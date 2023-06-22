// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import {ERC721 as ERC721Rari} from '@rari-capital/solmate/src/tokens/ERC721.sol';

import '../../interfaces/IJBDirectory.sol';
import '../../interfaces/IJBFundingCycleDataSource.sol';
import '../../interfaces/IJBPayDelegate.sol';
import '../../interfaces/IJBRedemptionDelegate.sol';
import '../interfaces/INFTRewardDataSourceDelegate.sol';
import '../interfaces/IPriceResolver.sol';
import '../interfaces/IToken721UriResolver.sol';
import '../interfaces/ITokenSupplyDetails.sol';

import '../../structs/JBDidPayData.sol';
import '../../structs/JBDidRedeemData.sol';
import '../../structs/JBRedeemParamsData.sol';
import '../../structs/JBTokenAmount.sol';

/**
 * @title Juicebox data source delegate that offers project contributors NFTs.
 *
 * @notice This contract allows project creators to reward contributors with NFTs. Intended use is to incentivize initial project support by minting a limited number of NFTs to the first N contributors.
 *
 * @notice One use case is enabling the project to mint an NFT for anyone contributing any amount without a mint limit. Set minContribution.value to 0 and maxSupply to uint256.max to do this. To mint NFTs to the first 100 participants contributing 1000 DAI or more, set minContribution.value to 1000000000000000000000 (3 + 18 zeros), minContribution.token to 0x6B175474E89094C44Da98b954EedeAC495271d0F and maxSupply to 100.
 *
 * @dev Keep in mind that this PayDelegate and RedeemDelegate implementation will simply pass through the weight and reclaimAmount it is called with.
 */
contract NFTRewardDataSourceDelegate is
  ERC721Rari,
  Ownable,
  INFTRewardDataSourceDelegate,
  IJBFundingCycleDataSource,
  IJBPayDelegate,
  IJBRedemptionDelegate
{
  using Strings for uint256;

  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//
  error INVALID_PAYMENT_EVENT();
  error INCORRECT_OWNER();
  error INVALID_ADDRESS();
  error INVALID_TOKEN();
  error SUPPLY_EXHAUSTED();
  error NON_TRANSFERRABLE();
  error INVALID_REQUEST(string);

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /**
   * @notice Project id of the project this configuration is associated with.
   */
  uint256 private _projectId;

  /**
   * @notice Platform directory.
   */
  IJBDirectory private _directory;

  /**
   * @notice Minimum contribution amount to trigger NFT distribution, denominated in some currency defined as part of this object.
   *
   * @dev Only one NFT will be minted for any amount at or above this value.
   */
  JBTokenAmount private _minContribution;

  /**
   * @notice NFT mint cap as part of this configuration.
   */
  uint256 private _maxSupply;

  /**
   * @notice Current supply.
   *
   * @dev Also used to check if rewards supply was exhausted and as nextTokenId
   */
  uint256 private _supply;

  /**
   * @notice Token base uri.
   */
  string private _baseUri;

  /**
   * @notice Custom token uri resolver, superceeds base uri.
   */
  IToken721UriResolver private _tokenUriResolver;

  /**
   * @notice Contract opensea-style metadata uri.
   */
  string private _contractUri;

  IPriceResolver private priceResolver;

  bool private transferrable;

  /**
   * @param projectId JBX project id this reward is associated with.
   * @param directory JBX directory.
   * @param maxSupply Total number of reward tokens to distribute.
   * @param minContribution Minimum contribution amount to be eligible for this reward.
   * @param _name The name of the token.
   * @param _symbol The symbol that the token should be represented by.
   * @param _uri Token base URI.
   * @param _tokenUriResolverAddress Custom uri resolver.
   * @param _contractMetadataUri Contract metadata uri.
   * @param _admin Set an alternate owner.
   * @param _priceResolver Custom uri resolver.
   */
  constructor(
    uint256 projectId,
    IJBDirectory directory,
    uint256 maxSupply,
    JBTokenAmount memory minContribution,
    string memory _name,
    string memory _symbol,
    string memory _uri,
    IToken721UriResolver _tokenUriResolverAddress,
    string memory _contractMetadataUri,
    address _admin,
    IPriceResolver _priceResolver
  ) ERC721Rari(_name, _symbol) {
    // JBX
    _projectId = projectId;
    _directory = directory;
    _maxSupply = maxSupply;
    _minContribution = minContribution;

    // ERC721
    _baseUri = _uri;
    _tokenUriResolver = _tokenUriResolverAddress;
    _contractUri = _contractMetadataUri;

    if (_admin != address(0)) {
      _transferOwnership(_admin);
    }

    priceResolver = _priceResolver;

    transferrable = true;
  }

  //*********************************************************************//
  // ------------------- IJBFundingCycleDataSource --------------------- //
  //*********************************************************************//

  function payParams(JBPayParamsData calldata _data)
    external
    view
    override
    returns (
      uint256 weight,
      string memory memo,
      JBPayDelegateAllocation[] memory delegateAllocations
    )
  {
    weight = _data.weight;
    memo = _data.memo;
    delegateAllocations = new JBPayDelegateAllocation[](1);
    delegateAllocations[0] = JBPayDelegateAllocation({
      delegate: IJBPayDelegate(address(this)),
      amount: _data.amount.value
    });
  }

  function redeemParams(JBRedeemParamsData calldata _data)
    external
    view
    override
    returns (
      uint256 reclaimAmount,
      string memory memo,
      JBRedemptionDelegateAllocation[] memory delegateAllocations
    )
  {
    reclaimAmount = _data.reclaimAmount.value;
    memo = _data.memo;
    // delegateAllocations = new JBRedemptionDelegateAllocation[](0);
  }

  //*********************************************************************//
  // ------------------------ IJBPayDelegate --------------------------- //
  //*********************************************************************//

  /**
   * @notice Part of IJBPayDelegate, this function will mint an NFT to the contributor (_data.beneficiary) if conditions are met.
   *
   * @dev This function will revert if the terminal calling it does not belong to the registered project id.
   *
   * @dev This function will also revert due to ERC721 mint issue, which may interfere with contribution processing. These are unlikely and include beneficiary being the 0 address or the beneficiary already holding the token id being minted. The latter should not happen given that mint is only controlled by this function.
   *
   * @param _data Juicebox project contribution data.
   */
  function didPay(JBDidPayData calldata _data) external payable override {
    if (
      !_directory.isTerminalOf(_projectId, IJBPaymentTerminal(msg.sender)) ||
      _data.projectId != _projectId
    ) {
      revert INVALID_PAYMENT_EVENT();
    }

    if (_supply == _maxSupply) {
      return;
    }

    if (address(priceResolver) != address(0)) {
      uint256 tokenId = priceResolver.validateContribution(_data.beneficiary, _data.amount, this);

      if (tokenId == 0) {
        return;
      }

      _mint(_data.beneficiary, tokenId);

      _supply += 1;
    } else if (
      (_data.amount.value >= _minContribution.value &&
        _data.amount.token == _minContribution.token) || _minContribution.value == 0
    ) {
      uint256 tokenId = _supply;
      _mint(_data.beneficiary, tokenId);

      _supply += 1;
    }
  }

  //*********************************************************************//
  // -------------------- IJBRedemptionDelegate ------------------------ //
  //*********************************************************************//

  /**
   * @notice NFT redemption is not supported.
   */
  // solhint-disable-next-line
  function didRedeem(JBDidRedeemData calldata _data) external payable override {
    // not a supported workflow for NFTs
  }

  //*********************************************************************//
  // ---------------------------- IERC165 ------------------------------ //
  //*********************************************************************//

  function supportsInterface(bytes4 _interfaceId)
    public
    view
    override(ERC721Rari, IERC165)
    returns (bool)
  {
    return
      _interfaceId == type(IJBFundingCycleDataSource).interfaceId ||
      _interfaceId == type(IJBPayDelegate).interfaceId ||
      _interfaceId == type(IJBRedemptionDelegate).interfaceId ||
      super.supportsInterface(_interfaceId); // check with rari-ERC721
  }

  //*********************************************************************//
  // ---------------------- ITokenSupplyDetails ------------------------ //
  //*********************************************************************//

  function totalSupply() public view override returns (uint256) {
    return _supply;
  }

  function tokenSupply(uint256 _tokenId) public view override returns (uint256) {
    return _ownerOf[_tokenId] != address(0) ? 1 : 0;
  }

  function totalOwnerBalance(address _account) public view override returns (uint256) {
    if (_account == address(0)) {
      revert INVALID_ADDRESS();
    }

    return _balanceOf[_account];
  }

  function ownerTokenBalance(address _account, uint256 _tokenId)
    public
    view
    override
    returns (uint256)
  {
    return _ownerOf[_tokenId] == _account ? 1 : 0;
  }

  //*********************************************************************//
  // ----------------------------- ERC721 ------------------------------ //
  //*********************************************************************//

  /**
   * @notice Returns the full URI for the asset.
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    if (_ownerOf[tokenId] == address(0)) {
      revert INVALID_TOKEN();
    }

    if (address(_tokenUriResolver) != address(0)) {
      return _tokenUriResolver.tokenURI(tokenId);
    }

    return bytes(_baseUri).length > 0 ? string(abi.encodePacked(_baseUri, tokenId.toString())) : '';
  }

  /**
   * @notice Returns the contract metadata uri.
   */
  function contractURI() public view override returns (string memory contractUri) {
    contractUri = _contractUri;
  }

  /**
   * @notice Transfer tokens to an account.
   *
   * @param _to The destination address.
   * @param _id NFT id to transfer.
   */
  function transfer(address _to, uint256 _id) public override {
    if (!transferrable) {
      revert NON_TRANSFERRABLE();
    }
    transferFrom(msg.sender, _to, _id);
  }

  /**
   * @notice Transfer tokens between accounts.
   *
   * @param _from The originating address.
   * @param _to The destination address.
   * @param _id The amount of the transfer, as a fixed point number with 18 decimals.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _id
  ) public override {
    if (!transferrable) {
      revert NON_TRANSFERRABLE();
    }
    super.transferFrom(_from, _to, _id);
  }

  /**
   * @notice Confirms that the given address owns the provided token.
   */
  function isOwner(address _account, uint256 _id) public view override returns (bool) {
    return _ownerOf[_id] == _account;
  }

  // TODO: this will cause issues for some price resolvers
  function mint(address _account) external override onlyOwner returns (uint256 tokenId) {
    if (_supply == _maxSupply) {
      revert SUPPLY_EXHAUSTED();
    }

    tokenId = _supply;
    _mint(_account, tokenId);

    _supply += 1;
  }

  /**
   * @notice This function is intended to allow NFT management for non-transferrable NFTs where the holder is unable to perform any action on the token, so we let the admin of the contract burn them.
   */
  function burn(address _account, uint256 _tokenId) external override onlyOwner {
    if (transferrable) {
      revert INVALID_REQUEST('Token is tranferrable');
    }

    if (!isOwner(_account, _tokenId)) {
      revert INCORRECT_OWNER();
    }

    _burn(_tokenId);
  }

  /**
   * @notice Owner-only function to set a contract metadata uri to contain opensea-style metadata.
   *
   * @param _contractMetadataUri New metadata uri.
   */
  function setContractUri(string calldata _contractMetadataUri) external override onlyOwner {
    _contractUri = _contractMetadataUri;
  }

  /**
   * @notice Owner-only function to set a new token base uri.
   *
   * @param _uri New base uri.
   */
  function setTokenUri(string calldata _uri) external override onlyOwner {
    _baseUri = _uri;
  }

  /**
   * @notice Owner-only function to set a token uri resolver. If set to address(0), value of baseUri will be used instead.
   *
   * @param _tokenUriResolverAddress New uri resolver contract.
   */
  function setTokenUriResolver(IToken721UriResolver _tokenUriResolverAddress)
    external
    override
    onlyOwner
  {
    _tokenUriResolver = _tokenUriResolverAddress;
  }

  function setTransferrable(bool _transferrable) external override onlyOwner {
    transferrable = _transferrable;
  }
}