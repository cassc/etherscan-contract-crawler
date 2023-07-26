// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "ERC721Enumerable.sol";

import "IXfaiINFT.sol";
import "IERC20.sol";
import "IXfaiFactory.sol";
import "IWETH.sol";

/**
 * @title Xfai's Infinity NFT contract
 * @author Xfai
 * @notice XfaiINFT is responsible for minting, boosting, and harvesting INFTs
 */
contract XfaiINFT is IXfaiINFT, ERC721Enumerable {
  /**
   * @notice The WETH address.
   * @dev In the case of a chain ID other than Ethereum, the wrapped ERC20 token address of the chain's native coin
   */
  address private WETH;

  /**
   * @notice The ERC20 token used as the underlying token for the INFT
   */
  address private underlyingToken;

  /**
   * @notice The Factory address of the DEX
   */
  address private factory;

  string private baseURI;

  uint private counter;

  /**
   * @notice The reserve of underlyingToken within the INFT contract
   */
  uint public override reserve;

  /**
   * @notice Total amount of issued shares
   */
  uint public override totalSharesIssued;

  /**
   * @notice Initial reserve set at during deployment. Does count as part of INFT reserve
   */
  uint public override initialReserve;

  uint private constant NOT_ENTERED = 1;
  uint private constant ENTERED = 2;
  uint private status;
  uint private expectedMints;

  /**
   * @notice Mapping from token address to harvested amounts. harvestedBalance shows how much of a token has been harvested so far from the contract.
   */
  mapping(address => uint) public override harvestedBalance;

  /**
   * @notice Mapping from token ID to share
   */
  mapping(uint => uint) public override INFTShares;

  /**
   * @notice Mapping from token address to token ID to token share
   */
  mapping(address => mapping(uint => uint)) public override sharesHarvestedByPool;

  /**
   * @notice Mapping from token address to total share for a token
   */
  mapping(address => uint) public override totalSharesHarvestedByPool;

  /**
   * @notice Functions with the onlyOwner modifier can be called only by the factory owner
   */
  modifier onlyOwner() {
    require(msg.sender == IXfaiFactory(factory).getOwner(), 'XfaiINFT: NOT_OWNER');
    _;
  }

  /**
   * @notice Functions with the lock modifier can be called only once within a transaction
   */
  modifier lock() {
    require(status != ENTERED, 'XfaiINFT: REENTRANT_CALL');
    status = ENTERED;
    _;
    status = NOT_ENTERED;
  }

  /**
   * @notice Construct Xfai's DEX Factory
   * @param _factory The address of the Xfai factory contract
   * @param _WETH the wrapped ETH address
   * @param _underlyingToken The address of the ERC20 token used as the underlying token for the INFT
   * @param _initialReserve The initial reserve used during deployment
   * @param _expectedMints The number of pre-mints before minting is available
   */
  constructor(
    address _factory,
    address _WETH,
    address _underlyingToken,
    uint _initialReserve,
    uint _expectedMints
  ) ERC721('Infinity-NFT', 'INFT') {
    status = NOT_ENTERED;
    factory = _factory;
    WETH = _WETH;
    underlyingToken = _underlyingToken;
    initialReserve = _initialReserve;
    expectedMints = _expectedMints;
    totalSharesIssued = 1; // permanently lock one share to prevent zero divisions
  }

  receive() external payable {
    assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
  }

  /**
   * @notice preMint is used to mint the legacy NFTs before minting is enabled
   * @dev Can only be called by the owner
   * @param _legacyLNFTHolders the address array of the legacy nft holders
   * @param _initialShares the share array of the legacy nft holders
   */
  function premint(
    address[] memory _legacyLNFTHolders,
    uint[] memory _initialShares
  ) external override onlyOwner {
    require(counter < expectedMints, 'XfaiINFT: PREMINTS_ENDED');
    require(_initialShares.length == _legacyLNFTHolders.length, 'XfaiINFT: INVALID_VALUES');
    for (uint i = 0; i < _initialShares.length; i++) {
      counter += 1;
      _safeMint(_legacyLNFTHolders[i], counter);
      INFTShares[counter] = _initialShares[i];
      totalSharesIssued += _initialShares[i];
    }
  }

  /**
   * @notice Function used to set the baseURI of the NFT
   * @dev setBaseURI can be called only by the contract owner
   * @param _newBaseURI the new baseURI string for the NFT
   */
  function setBaseURI(string memory _newBaseURI) external override onlyOwner {
    baseURI = _newBaseURI;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /**
   * @notice Function used to fetch contract states
   * @return The reserve used during contract initialization, the reserve of the underlying token, and the total number of shares issued
   */
  function getStates() external view override returns (uint, uint, uint) {
    return (initialReserve, reserve, totalSharesIssued);
  }

  /**
   * @notice Computes the amount of _token fees collected for a given _tokenID
   * @param _tokenID The token ID of an INFT
   * @param _token the address of an ERC20 token
   * @return share2amount The total amount of _token that a given _tokenID can harvest
   * @return inftShare The share of an INFT
   * @return harvestedShares The amount of shares harvested for a given pool
   */
  function shareToTokenAmount(
    uint _tokenID,
    address _token
  ) external view override returns (uint share2amount, uint inftShare, uint harvestedShares) {
    inftShare = INFTShares[_tokenID];
    harvestedShares = sharesHarvestedByPool[_token][_tokenID];
    uint tokenBalance = IERC20(_token).balanceOf(address(this));
    uint share = inftShare - harvestedShares;
    uint totalShare = totalSharesIssued - totalSharesHarvestedByPool[_token];
    share2amount = (tokenBalance * share) / totalShare; // zero divisions not possible
  }

  /**
   * @notice Creates a new INFT, the share of which is determined by the amount of the underlying token sent to the Xfai factory
   * @dev This low-level function should be called from a contract which performs important safety checks
   * @param _to The address to which the newly minted INFT should be sent to
   * @return tokenID The id of the newly minted INFT
   * @return share The share value of the INFT
   */
  function mint(address _to) external override lock returns (uint tokenID, uint share) {
    require(counter >= expectedMints, 'XfaiINFT: PREMINTS_ONGOING');
    uint amount = IERC20(underlyingToken).balanceOf(factory) - reserve;
    require(amount != 0, 'XfaiINFT: INSUFICIENT_AMOUNT');
    counter += 1;
    tokenID = counter;
    reserve += amount;
    share = (1e18 * amount) / (reserve + initialReserve);
    INFTShares[tokenID] = share;
    totalSharesIssued += share;
    _safeMint(_to, tokenID);
    emit Mint(msg.sender, _to, share, tokenID);
  }

  /**
   * @notice Boosts the share value of an INFT, the share of which is determined by the amount of the underlying token sent to the DexfaiFactory
   * @dev This low-level function should be called from a contract which performs important safety checks
   * @param _tokenID The token ID of an INFT
   * @return share The share value added to an INFT
   */
  function boost(uint _tokenID) external override lock returns (uint share) {
    require(_tokenID <= counter, 'XfaiINFT: Inexistent_ID');
    uint amount = IERC20(underlyingToken).balanceOf(factory) - reserve;
    require(amount != 0, 'XfaiINFT: INSUFICIENT_AMOUNT');
    reserve += amount;
    share = (1e18 * amount) / (reserve + initialReserve);
    INFTShares[_tokenID] += share;
    totalSharesIssued += share;
    emit Boost(msg.sender, share, _tokenID);
  }

  /**
   * @notice Harvests the fees (in terms of a given ERC20 token) for a given INFT.
   * @param _token An ERC20 token address
   * @param _tokenID The token ID of an INFT
   * @param _amount The amount of _token to harvest
   */
  function _harvest(
    address _token,
    uint _tokenID,
    uint _amount
  ) private returns (uint harvestedTokenShare) {
    require(ownerOf(_tokenID) == msg.sender, 'XfaiINFT: NOT_INFT_OWNER');
    uint tokenBalance = IERC20(_token).balanceOf(address(this));
    uint share = INFTShares[_tokenID] - sharesHarvestedByPool[_token][_tokenID];
    uint totalShare = totalSharesIssued - totalSharesHarvestedByPool[_token];
    uint share2amount = (tokenBalance * share) / totalShare; // zero divisions not possible
    require(_amount <= share2amount, 'XfaiINFT: AMOUNT_EXCEEDS_SHARE');
    harvestedTokenShare = (share * _amount) / share2amount;
    sharesHarvestedByPool[_token][_tokenID] += harvestedTokenShare;
    totalSharesHarvestedByPool[_token] += harvestedTokenShare;
    harvestedBalance[_token] += _amount;
  }

  /**
   * @notice Harvests INFT fees from the INFT contract
   * @param _token The address of an ERC20 token
   * @param _tokenID The ID of the INFT
   * @param _amount The amount to harvest
   */
  function harvestToken(
    address _token,
    uint _tokenID,
    uint _amount
  ) external override lock returns (uint) {
    uint harvestedTokenShare = _harvest(_token, _tokenID, _amount);
    _safeTransfer(_token, ownerOf(_tokenID), _amount);
    emit HarvestToken(_token, _amount, harvestedTokenShare, _tokenID);
    return _amount;
  }

  /**
   * @notice Harvests INFT fees from the INFT contract
   * @param _tokenID The ID of the INFT
   * @param _amount The amount to harvest
   */
  function harvestETH(uint _tokenID, uint _amount) external override lock returns (uint) {
    uint harvestedTokenShare = _harvest(WETH, _tokenID, _amount);
    IWETH(WETH).withdraw(_amount);
    _safeTransferETH(ownerOf(_tokenID), _amount);
    emit HarvestETH(_amount, harvestedTokenShare, _tokenID);
    return _amount;
  }

  function _safeTransfer(address _token, address _to, uint256 _value) internal {
    require(_token.code.length > 0, 'XfaiINFT: TRANSFER_FAILED');
    (bool success, bytes memory data) = _token.call(
      abi.encodeWithSelector(IERC20.transfer.selector, _to, _value)
    );
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'XfaiINFT: TRANSFER_FAILED');
  }

  function _safeTransferETH(address _to, uint _value) internal {
    (bool success, ) = _to.call{value: _value}(new bytes(0));
    require(success, 'XfaiINFT: ETH_TRANSFER_FAILED');
  }
}