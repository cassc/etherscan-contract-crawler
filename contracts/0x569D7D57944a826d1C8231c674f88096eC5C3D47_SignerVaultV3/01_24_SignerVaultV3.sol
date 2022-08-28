// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "./interfaces/lightweight/IUniswapV2Factory.sol";
import "./interfaces/lightweight/IUniswapV2Pair.sol";
import "./interfaces/lightweight/IUniswapV2Router02.sol";
import "./interfaces/IContractDeployerV1.sol";
import "./interfaces/IFeeCollectorV2.sol";
import "./interfaces/ISignerVaultFactoryV1.sol";
import "./interfaces/ISignerVaultV3.sol";
import "./library/AddressArrayHelper.sol";
import "./library/CurrencyLockMapHelper.sol";
import "./structs/SwapLiquidityLocalVariables.sol";
import "./structs/Vote.sol";

contract SignerVaultV3 is ISignerVaultV3 {
  using AddressArrayHelper for address[];
  using CurrencyLockMapHelper for LockMap;

  uint constant private UINT_MAX_VALUE = 2 ** 256 - 1;
  string constant private IDENTIFIER = "SignerVault";
  uint constant private VERSION = 3;

  address immutable private _deployer;
  Dependency[] _dependencies;

  bool _implementationInitialized;

  address private _signerVaultFactory;

  address[] private _signersArray;
  mapping (address => bool) _signers;
  address[] private _lockMapIdsArray;
  mapping (address => LockMap) private _lockMaps;
  Vote private _vote;
  address private _voteInitiator;

  bool private _locked;

  constructor() {
    _deployer = msg.sender;
  }

  receive() external payable {}
  fallback() external payable {}

  modifier lock() {
    require(!_locked, "SignerVault: reentrancy");
    _locked = true;
    _;
    _locked = false;
  }

  modifier onlyDeployer() {
    require(msg.sender == _deployer, "SignerVault: caller must be the deployer");
    _;
  }

  function onlyThis() private view {
    require(msg.sender == address(this), "SignerVault: caller must be this");
  }

  function onlyVault() private view {
    require(msg.sender == ISignerVaultFactoryV1(_signerVaultFactory).vault(), "SignerVault: caller must be the vault");
  }

  function onlySigners() private view {
    require(_signers[msg.sender], "SignerVault: caller must be a signer");
  }

  function onlyVaultOrSigners() private view {
    require(msg.sender == ISignerVaultFactoryV1(_signerVaultFactory).vault() || _signers[msg.sender], "SignerVault: caller must be the vault or a signer");
  }

  function ensureVoter(address voter) private view {
    require(_signers[voter], "SignerVault: voter must be a signer");
  }

  function ensureRecipient(address recipient) private view {
    require(_signers[recipient], "SignerVault: recipient must be a signer");
  }

  function ensureId(CurrencyType currencyType, address id) private pure {
    require((currencyType == CurrencyType.ETH) != (id != address(0)), "SignerVault: id can't be the null address");
  }

  function ensureArrays(CurrencyType[] calldata currencyTypes, address[] calldata ids, uint[] calldata values) private pure {
    require(currencyTypes.length == ids.length && currencyTypes.length == values.length, "SignerVault: array size mismatch");
  }

  function identifier() external pure returns (string memory) {
    return IDENTIFIER;
  }

  function version() external pure returns (uint) {
    return VERSION;
  }

  function dependencies() external view returns (Dependency[] memory) {
    return _dependencies;
  }

  function updateDependencies(Dependency[] calldata dependencies_) external onlyDeployer {
    delete _dependencies;
    for (uint index = 0; index < dependencies_.length; index++)
      _dependencies.push(dependencies_[index]);
  }

  function deployer() external view returns (address) {
    return _deployer;
  }

  function initialize(bytes calldata data) external onlyDeployer {}

  function initializeImplementation(address signerVaultFactory_, address signer_) external {
    require(!_implementationInitialized);
    _implementationInitialized = true;
    _signerVaultFactory = signerVaultFactory_;
    _signersArray.push(signer_);
    _signers[signer_] = true;
  }

  function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }

  function signerVaultFactory() external view returns (address) {
    return _signerVaultFactory;
  }

  function signers() external view returns (address[] memory) {
    return _signersArray;
  }

  function signersLength() external view returns (uint) {
    return _signersArray.length;
  }

  function signer(uint index) external view returns (address) {
    require(index < _signersArray.length, "SignerVault: index out of range");
    return _signersArray[index];
  }

  function signer(address candidate) external view returns (bool) {
    return _signers[candidate];
  }

  function lockMapIds() external view returns (address[] memory) {
    return _lockMapIdsArray;
  }

  function lockMapIdsLength() external view returns (uint) {
    return _lockMapIdsArray.length;
  }

  function lockMapId(uint index) external view returns (address) {
    require(index < _lockMapIdsArray.length, "SignerVault: index out of range");
    return _lockMapIdsArray[index];
  }

  function addSignerViaVote(address nominee) external {
    onlyThis();
    _addSigner(nominee);
  }

  function removeSignerViaVote(address nominee) external {
    onlyThis();
    _removeSigner(nominee);
  }

  function unlockViaVote(CurrencyType currencyType, address id, uint value, address recipient) external {
    onlyThis();
    _unlock(currencyType, id, value, recipient);
  }

  function unlockMultipleViaVote(CurrencyType[] calldata currencyTypes, address[] calldata ids, uint[] calldata values, address recipient) external {
    onlyThis();
    _unlockMultiple(currencyTypes, ids, values, recipient);
  }

  function vote(address voter) external view returns (bytes memory data, uint quorom, uint accepts, uint rejects, bool voted) {
    data = _vote.data;
    quorom = _vote.quorom;
    accepts = _vote.accepts;
    rejects = _vote.rejects;
    voted = _vote.voted[voter];
  }

  function voteInitiator() external view returns (address) {
    return _voteInitiator;
  }

  function castVote(bool accept) external {
    onlySigners();
    _castVote(accept, msg.sender);
  }

  function castVote(bool accept, address voter) external {
    onlyVault();
    _castVote(accept, voter);
  }

  function addSigner(address nominee) external {
    onlySigners();
    _addSignerWithVote(nominee, msg.sender);
  }

  function addSigner(address nominee, address voter) external {
    onlyVault();
    _addSignerWithVote(nominee, voter);
  }

  function removeSigner(address nominee) external {
    onlySigners();
    _removeSignerWithVote(nominee, msg.sender);
  }

  function removeSigner(address nominee, address voter) external {
    onlyVault();
    _removeSignerWithVote(nominee, voter);
  }

  function lockCurrency(CurrencyType currencyType, address id, uint value, uint until) external payable {
    onlyVault();
    _lock(currencyType, id, value, until);
  }

  function lockMapMultiple(address[] calldata ids) external view returns (LockMap[] memory) {
    LockMap[] memory lockMaps_ = new LockMap[](ids.length);
    for (uint index = 0; index < ids.length; index++)
      lockMaps_[index] = _getLockMapUnsafe(ids[index]);

    return lockMaps_;
  }

  function claimMultiple(CurrencyType[] calldata currencyTypes, address[] calldata ids, uint[] calldata values, address recipient) external {
    onlyVaultOrSigners();
    ensureArrays(currencyTypes, ids, values);
    for (uint index = 0; index < currencyTypes.length; index++)
      _claim(currencyTypes[index], ids[index], values[index], recipient);
  }

  function unlockMultiple(CurrencyType[] calldata currencyTypes, address[] calldata ids, uint[] calldata values, address recipient) external {
    onlySigners();
    _unlockMultipleWithVote(currencyTypes, ids, values, recipient, msg.sender);
  }

  function unlockMultiple(CurrencyType[] calldata currencyTypes, address[] calldata ids, uint[] calldata values, address recipient, address voter) external {
    onlyVault();
    _unlockMultipleWithVote(currencyTypes, ids, values, recipient, voter);
  }

  function lockMultiple(CurrencyType[] calldata, address[] calldata, uint[] calldata, uint[] calldata) external payable {
    revert("SignerVault: call lockMultiple from the IVaultV2 - we are out of contract code space! Thanks @ Vitalik Buterin (This message costs also...)");
  }

  function lockMapETH() external view returns (LockMap memory) {
    return _getLockMapUnsafe(address(0));
  }

  function claimETH() external {
    onlySigners();
    _claim(CurrencyType.ETH, address(0), msg.sender);
  }

  function claimETH(address recipient) external {
    onlyVaultOrSigners();
    _claim(CurrencyType.ETH, address(0), recipient);
  }

  function unlockETH(uint amount) external {
    onlySigners();
    _unlockWithVote(CurrencyType.ETH, address(0), amount, msg.sender, msg.sender);
  }

  function unlockETH(uint amount, address recipient) external {
    onlySigners();
    _unlockWithVote(CurrencyType.ETH, address(0), amount, recipient, msg.sender);
  }

  function unlockETH(uint amount, address recipient, address voter) external {
    onlyVault();
    _unlockWithVote(CurrencyType.ETH, address(0), amount, recipient, voter);
  }

  function lockETH(uint amount, uint until) external payable {
    _lock(CurrencyType.ETH, address(0), amount, until);
  }

  function lockETHPermanently(uint amount) external payable {
    _lock(CurrencyType.ETH, address(0), amount, UINT_MAX_VALUE);
  }

  function lockMapToken(address token) external view returns (LockMap memory) {
    return _getLockMapUnsafe(token);
  }

  function claimToken(address token) external {
    onlySigners();
    _claim(CurrencyType.Token, token, msg.sender);
  }

  function claimToken(address token, address recipient) external {
    onlyVaultOrSigners();
    _claim(CurrencyType.Token, token, recipient);
  }

  function unlockToken(address token, uint amount) external {
    onlySigners();
    _unlockWithVote(CurrencyType.Token, token, amount, msg.sender, msg.sender);
  }

  function unlockToken(address token, uint amount, address recipient) external {
    onlySigners();
    _unlockWithVote(CurrencyType.Token, token, amount, recipient, msg.sender);
  }

  function unlockToken(address token, uint amount, address recipient, address voter) external {
    onlyVault();
    _unlockWithVote(CurrencyType.Token, token, amount, recipient, voter);
  }

  function lockToken(address token, uint amount, uint until) external payable {
    _lock(CurrencyType.Token, token, amount, until);
  }

  function lockTokenPermanently(address token, uint amount) external payable {
    _lock(CurrencyType.Token, token, amount, UINT_MAX_VALUE);
  }

  function lockMapERC721(address erc721) external view returns (LockMap memory) {
    return _getLockMapUnsafe(erc721);
  }

  function claimERC721(address erc721, uint tokenId) external {
    onlySigners();
    _claim(CurrencyType.ERC721, erc721, tokenId, msg.sender);
  }

  function claimERC721(address erc721, uint tokenId, address recipient) external {
    onlyVaultOrSigners();
    _claim(CurrencyType.ERC721, erc721, tokenId, recipient);
  }

  function unlockERC721(address erc721, uint tokenId) external {
    onlySigners();
    _unlockWithVote(CurrencyType.ERC721, erc721, tokenId, msg.sender, msg.sender);
  }

  function unlockERC721(address erc721, uint tokenId, address recipient) external {
    onlySigners();
    _unlockWithVote(CurrencyType.ERC721, erc721, tokenId, recipient, msg.sender);
  }

  function unlockERC721(address erc721, uint tokenId, address recipient, address voter) external {
    onlyVault();
    _unlockWithVote(CurrencyType.ERC721, erc721, tokenId, recipient, voter);
  }

  function lockERC721(address erc721, uint tokenId, uint until) external payable {
    _lock(CurrencyType.ERC721, erc721, tokenId, until);
  }

  function lockERC721Permanently(address erc721, uint tokenId) external payable {
    _lock(CurrencyType.ERC721, erc721, tokenId, UINT_MAX_VALUE);
  }

  function swapLiquidity(address token, uint removeLiquidity, address[] calldata swapPath, uint deadline) external payable {
    _swapLiquidity(token, removeLiquidity, 0, 0, 0, swapPath, 0, 0, deadline);
  }

  function swapLiquidity(address token, uint removeLiquidity, uint swapAmountOutMin, address[] calldata swapPath, uint deadline) external payable {
    _swapLiquidity(token, removeLiquidity, 0, 0, swapAmountOutMin, swapPath, 0, 0, deadline);
  }

  function swapLiquidity(address token, uint removeLiquidity, uint removeAmountAMin, uint removeAmountBMin, uint swapAmountOutMin, address[] calldata swapPath, uint addAmountAMin, uint addAmountBMin, uint deadline) external payable {
    _swapLiquidity(token, removeLiquidity, removeAmountAMin, removeAmountBMin, swapAmountOutMin, swapPath, addAmountAMin, addAmountBMin, deadline);
  }

  function _getLockMapUnsafe(address id) private view returns (LockMap memory) {
    return _lockMaps[id];
  }

  function _getLockMap(address id) private returns (LockMap storage lockMap_) {
    lockMap_ = _lockMaps[id];
    if (!lockMap_.initialized) {
        lockMap_.id = id;
        lockMap_.initialized = true;
        _lockMapIdsArray.push(id);
    }
  }

  function _initVote(address voter, bytes memory data) private {
    ensureVoter(voter);
    require(_vote.data.length == 0, "SignerVault: a vote can't be pending");
    _vote.data = data;
    _vote.quorom = (_signersArray.length + 1) / 2;
    _vote.accepts = 1;
    _vote.voted[voter] = true;
    _voteInitiator = voter;
  }

  function _castVote(bool accept, address voter) private lock {
    ensureVoter(voter);
    require(!_vote.voted[voter], "SignerVault: voter can't have voted");
    require(_vote.data.length > 0, "SignerVault: a vote must be pending");

    accept ? _vote.accepts++ : _vote.rejects++;
    _vote.voted[voter] = true;

    if (_vote.accepts >= _vote.quorom || _vote.rejects >= _vote.quorom) {
      for (uint index = 0; index < _signersArray.length; index++)
        _vote.voted[_signersArray[index]] = false;

      string memory revertReason;
      if (_vote.accepts >= _vote.quorom) {
        (bool success, bytes memory data) = address(this).call(_vote.data);
        if (!success) {
            uint length = data.length;
            if (length >= 68) {
              uint l;
              assembly {
                data := add(data, 4)
                l := mload(data)
                mstore(data, sub(length, 4))
              }

              revertReason = abi.decode(data, (string));
              assembly {
                mstore(data, l)
              }
            }
        }

        emit VoteOperationExecuted(_vote.data, success, revertReason);
      }

      delete _vote;
      delete _voteInitiator;
    }
  }

  function _addSignerWithVote(address nominee, address voter) private lock {
    require(!_signers[nominee], "SignerVault: nominee can't be a signer");
    if (_signersArray.length > 2) {
      ensureVoter(voter);
      _initVote(voter, abi.encodeWithSelector(this.addSignerViaVote.selector, nominee));
      return;
    }

    _addSigner(nominee);
  }

  function _addSigner(address nominee) private {
    _signersArray.push(nominee);
    _signers[nominee] = true;
    ISignerVaultFactoryV1(_signerVaultFactory).addLinking(nominee);
  }

  function _removeSignerWithVote(address nominee, address voter) private lock {
    require(_signers[nominee], "SignerVault: nominee must be a signer");
    if (_signersArray.length > 2) {
      ensureVoter(voter);
      _initVote(voter, abi.encodeWithSelector(this.removeSignerViaVote.selector, nominee));
      return;
    }

    revert("SignerVault: removing a signer is only allowed for 3 or more signers");
  }

  function _removeSigner(address nominee) private {
    _signersArray.remove(nominee);
    _signers[nominee] = false;
    ISignerVaultFactoryV1(_signerVaultFactory).removeLinking(nominee);
  }

  function _claim(CurrencyType currencyType, address id, address recipient) private {
    _claim(currencyType, id, TransferHelperV2.safeBalanceOf(id, address(this)) - _getLockMap(id).balance(currencyType), recipient);
  }

  function _claim(CurrencyType currencyType, address id, uint value, address recipient) private lock {
    ensureId(currencyType, id);
    ensureRecipient(recipient);
    _transferCurrencyFromThis(currencyType, id, value, recipient, false);
  }

  function _unlockWithVote(CurrencyType currencyType, address id, uint value, address recipient, address voter) private lock {
    ensureId(currencyType, id);
    ensureRecipient(recipient);
    if (_signersArray.length > 2) {
      ensureVoter(voter);
      _initVote(voter, abi.encodeWithSelector(this.unlockViaVote.selector, currencyType, id, value, recipient));
      return;
    }

    _unlock(currencyType, id, value, recipient);
  }

  function _unlockMultipleWithVote(CurrencyType[] calldata currencyTypes, address[] calldata ids, uint[] calldata values, address recipient, address voter) private lock {
    ensureArrays(currencyTypes, ids, values);
    for (uint index = 0; index < currencyTypes.length; index++)
      ensureId(currencyTypes[index], ids[index]);
    ensureRecipient(recipient);
    if (_signersArray.length > 2) {
      ensureVoter(voter);
      _initVote(voter, abi.encodeWithSelector(this.unlockMultipleViaVote.selector, currencyTypes, ids, values, recipient));
      return;
    }

    _unlockMultiple(currencyTypes, ids, values, recipient);
  }

  function _unlock(CurrencyType currencyType, address id, uint value, address recipient) private {
    _transferCurrencyFromThis(currencyType, id, value, recipient, true);
  }

  function _unlockMultiple(CurrencyType[] calldata currencyTypes, address[] calldata ids, uint[] calldata values, address recipient) private {
    for (uint index = 0; index < currencyTypes.length; index++)
      _transferCurrencyFromThis(currencyTypes[index], ids[index], values[index], recipient, true);
  }

  function _lock(CurrencyType currencyType, address id, uint value, uint until) private lock {
    address vault = ISignerVaultFactoryV1(_signerVaultFactory).vault();
    uint paidFee = msg.sender != vault ? IFeeCollectorV2(ISignerVaultFactoryV1(_signerVaultFactory).feeCollector()).payLockFee{value:currencyType == CurrencyType.ETH ? msg.value - value : msg.value}(currencyType, address(this), msg.sender) : 0;
    require(currencyType != CurrencyType.ETH || msg.value >= value + paidFee, "SignerVault: insufficient value provided");
    ensureId(currencyType, id);
    require(until > block.timestamp, "SignerVault: until must be greater than the current block timestamp");
    if (currencyType != CurrencyType.ETH && msg.sender != vault)
      value = TransferHelperV2.safeTransferCurrency(currencyType, id, msg.sender, address(this), value);
    _getLockMap(id).add(currencyType, value, until);
  }

  function _transferCurrencyFromThis(CurrencyType currencyType, address id, uint value, address recipient, bool remove) private {
    value = TransferHelperV2.safeTransferCurrency(currencyType, id, address(this), recipient, value);
    remove ? _getLockMap(id).remove(currencyType, value) : _getLockMap(id).validate(currencyType);
  }

  function _swapLiquidity(address token, uint removeLiquidity, uint removeAmountAMin, uint removeAmountBMin, uint swapAmountOutMin, address[] calldata swapPath, uint addAmountAMin, uint addAmountBMin, uint deadline) private lock {
    onlyVaultOrSigners();
    if (msg.sender != ISignerVaultFactoryV1(_signerVaultFactory).vault())
      IFeeCollectorV2(ISignerVaultFactoryV1(_signerVaultFactory).feeCollector()).paySwapLiquidityFee{value:msg.value}(address(this), msg.sender);

    require(token != address(0), "SignerVault: token can't be the null address");
    require(removeLiquidity > 0, "SignerVault: removeLiquidity must be greater than 0");
    require(swapPath.length > 1, "SignerVault: swapPath must contain atleast 2 entries");
    require(deadline >= block.timestamp, "SignerVault: deadline must be greater or equal than the current block timestamp");

    SwapLiquidityLocalVariables memory localVariables;

    IUniswapV2Router02 uniswapV2Router02 = IUniswapV2Router02(IContractDeployerV1(ISignerVaultFactoryV1(_signerVaultFactory).contractDeployer()).router());
    (localVariables.amountA, localVariables.amountB, localVariables.until) = _removeLiquidity(uniswapV2Router02, IUniswapV2Pair(token).token0(), IUniswapV2Pair(token).token1(), removeLiquidity, removeAmountAMin, removeAmountBMin, deadline);
    localVariables.addAmountBDesired = _swapExactTokensForTokensSupportingFeeOnTransferTokens(uniswapV2Router02, swapPath[0] == IUniswapV2Pair(token).token0() ? localVariables.amountA : localVariables.amountB, swapAmountOutMin, swapPath, deadline, localVariables.until);
    _addLiquidity(uniswapV2Router02, swapPath[0] == IUniswapV2Pair(token).token0() ? IUniswapV2Pair(token).token1() : IUniswapV2Pair(token).token0(), swapPath[swapPath.length - 1], swapPath[0] == IUniswapV2Pair(token).token0() ? localVariables.amountB : localVariables.amountA, localVariables.addAmountBDesired, addAmountAMin, addAmountBMin, deadline, localVariables.until);
  }

  function _removeLiquidity(IUniswapV2Router02 uniswapV2Router02, address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, uint deadline) private returns (uint amountA, uint amountB, uint until) {
    address tokenPair = IUniswapV2Factory(uniswapV2Router02.factory()).getPair(tokenA, tokenB);
    TransferHelperV2.safeApprove(tokenPair, address(uniswapV2Router02), liquidity);
    uint balancePairBefore = IUniswapV2Pair(tokenPair).balanceOf(address(this));
    uint balanceABefore = TransferHelperV2.safeBalanceOf(tokenA, address(this));
    uint balanceBBefore = TransferHelperV2.safeBalanceOf(tokenB, address(this));
    uniswapV2Router02.removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, address(this), deadline);
    amountA = TransferHelperV2.safeBalanceOf(tokenA, address(this)) - balanceABefore;
    amountB = TransferHelperV2.safeBalanceOf(tokenB, address(this)) - balanceBBefore;
    until = CurrencyLockMapHelper.remove(_getLockMap(tokenPair), CurrencyType.Token, balancePairBefore - IUniswapV2Pair(tokenPair).balanceOf(address(this)), true);
    CurrencyLockMapHelper.add(_getLockMap(tokenA), CurrencyType.Token, amountA, until);
    CurrencyLockMapHelper.add(_getLockMap(tokenB), CurrencyType.Token, amountB, until);
  }

  function _swapExactTokensForTokensSupportingFeeOnTransferTokens(IUniswapV2Router02 uniswapV2Router02, uint amountIn, uint amountOutMin, address[] calldata path, uint deadline, uint until) private returns (uint amount) {
    TransferHelperV2.safeApprove(path[0], address(uniswapV2Router02), amountIn);
    uint[] memory balancesBefore = new uint[](path.length);
    for (uint i = 0; i < path.length; i++)
      balancesBefore[i] = TransferHelperV2.safeBalanceOf(path[i], address(this));
    uniswapV2Router02.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, address(this), deadline);
    amount = TransferHelperV2.safeBalanceOf(path[path.length - 1], address(this)) - balancesBefore[path.length - 1];
    CurrencyLockMapHelper.remove(_getLockMap(path[0]), CurrencyType.Token, balancesBefore[0] - TransferHelperV2.safeBalanceOf(path[0], address(this)), true);
    for (uint i = 1; i < path.length - 1; i++)
      CurrencyLockMapHelper.add(_getLockMap(path[i]), CurrencyType.Token, TransferHelperV2.safeBalanceOf(path[i], address(this)) - balancesBefore[i], until);
    CurrencyLockMapHelper.add(_getLockMap(path[path.length - 1]), CurrencyType.Token, amount, until);
  }

  function _addLiquidity(IUniswapV2Router02 uniswapV2Router02, address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, uint deadline, uint until) private {
    address tokenPair = IUniswapV2Factory(uniswapV2Router02.factory()).getPair(tokenA, tokenB);
    TransferHelperV2.safeApprove(tokenA, address(uniswapV2Router02), amountADesired);
    TransferHelperV2.safeApprove(tokenB, address(uniswapV2Router02), amountBDesired);
    uint balanceABefore = TransferHelperV2.safeBalanceOf(tokenA, address(this));
    uint balanceBBefore = TransferHelperV2.safeBalanceOf(tokenB, address(this));
    uint balancePairBefore = TransferHelperV2.safeBalanceOf(tokenPair, address(this));
    uniswapV2Router02.addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, address(this), deadline);
    CurrencyLockMapHelper.remove(_getLockMap(tokenA), CurrencyType.Token, balanceABefore - TransferHelperV2.safeBalanceOf(tokenA, address(this)), true);
    CurrencyLockMapHelper.remove(_getLockMap(tokenB), CurrencyType.Token, balanceBBefore - TransferHelperV2.safeBalanceOf(tokenB, address(this)), true);
    CurrencyLockMapHelper.add(_getLockMap(tokenPair), CurrencyType.Token, TransferHelperV2.safeBalanceOf(tokenPair, address(this)) - balancePairBefore, until);
  }
}