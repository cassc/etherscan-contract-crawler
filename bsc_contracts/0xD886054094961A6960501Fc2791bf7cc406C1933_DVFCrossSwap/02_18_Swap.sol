// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./EIP712Upgradeable.sol";
import "./libs/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./Storage.sol";
import "./UserWallet.sol";

abstract contract Swap is Storage, UserWallet {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  bytes32 public constant DEVERSIFI_GATEWAY = "DeversifiGateway";

  bytes32 public constant _SWAP_TYPEHASH =
   keccak256("Swap(address user,bytes32 swapGateway,address tokenFrom,address tokenTo,uint256 amountFrom,uint256 minAmountTo,uint256 nonce,uint256 deadline,uint256 chainId)");

  struct SwapConstraints {
    address user;
    bytes32 swapGateway;
    address tokenFrom;
    address tokenTo;
    uint256 amountFrom;
    uint256 minAmountTo;
    uint256 nonce;
    uint256 deadline;
    uint256 chainId;
    // maxFeeTo set as extra argument in calls but not part of the EIP712 signature
    uint256 maxFeeTo;
  }

  event SwapPerformed(bytes32 swapId, bytes32 swapGateway, address indexed user,
   address indexed tokenFrom, uint256 amountFrom, address indexed tokenTo,
   uint256 amountTo, uint256 amountToFee, bool fundsBridged);

  // solhint-disable-next-line func-name-mixedcase
  function __Swap_init(
    address _paraswap,
    address _paraswapTransferProxy
  ) internal onlyInitializing {
    paraswap = _paraswap;
    paraswapTransferProxy = _paraswapTransferProxy;
    __EIP712_init("RhinoFi Cross Chain Swap", "1");
  }

  function setParaswapAddresses(
    address _paraswap,
    address _paraswapTransferProxy
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    paraswap = _paraswap;
    paraswapTransferProxy = _paraswapTransferProxy;
  }

  function executeSwapWithSignature(
    SwapConstraints calldata swapConstraints,
    bytes32 swapId,
    bytes memory signature,
    bytes memory data
  ) external onlyRole(OPERATOR_ROLE) withUniqueId(swapId) {
    ensureDeadline(swapConstraints.deadline);

    verifySwapSignature(swapConstraints, signature);

    (,uint256 amountToUser, uint256 amountToFee) = performSwap(swapConstraints.user, swapConstraints.tokenFrom, swapConstraints.tokenTo, swapConstraints.amountFrom, swapConstraints.minAmountTo, swapConstraints.maxFeeTo, data);

    // based on swapGateway decide to tunnel the funds back into
    // Our pool or not, this can be done inside performSwap as well
    // to save ~3 extra addition/subtraction
    bool fundsBridged = postSwap(swapConstraints.swapGateway, amountToUser, swapConstraints.tokenTo, swapConstraints.user);

    emit SwapPerformed(swapId, swapConstraints.swapGateway, swapConstraints.user, swapConstraints.tokenFrom,
     swapConstraints.amountFrom, swapConstraints.tokenTo, amountToUser, amountToFee, fundsBridged);
  }

  function executeSwapWithSelfLiquidity(
    SwapConstraints calldata swapConstraints,
    bytes32 swapId,
    bytes memory data
  ) external onlyRole(LIQUIDITY_SPENDER_ROLE) withUniqueId(swapId) {
    ensureDeadline(swapConstraints.deadline);
    // Currently transfers from this contract's vault
    // We can also place them in operator's vault and use msg.sender
    transfer(address(this), swapConstraints.tokenFrom, swapConstraints.user, swapConstraints.amountFrom);
    (,uint256 amountToUser, uint256 amountToFee) = performSwap(swapConstraints.user, swapConstraints.tokenFrom, swapConstraints.tokenTo,
     swapConstraints.amountFrom, swapConstraints.minAmountTo, swapConstraints.maxFeeTo, data);

    emit SwapPerformed(swapId, bytes32(0), swapConstraints.user, swapConstraints.tokenFrom, swapConstraints.amountFrom,
     swapConstraints.tokenTo, amountToUser, amountToFee, false);
  }

  function postSwap(
    bytes32 swapGateway,
    uint256 receivedtokenAmount,
    address receivedToken,
    address user
  ) internal returns (bool fundsBridged) {
    if (swapGateway == DEVERSIFI_GATEWAY) {
      transfer(user, receivedToken, address(this), receivedtokenAmount);
      return true;
    }

    return false;
  }

  function performSwap(
    address user,
    address tokenFrom,
    address tokenTo,
    uint256 amountFrom,
    uint256 minAmountTo,
    uint256 maxFeeTo,
    bytes memory data
  ) private returns(uint256 tokenFromAmount, uint256 amountToUser, uint256 amountToFee) {
    tokenFromAmount = IERC20Upgradeable(tokenFrom).balanceOf(address(this));
    // Using amountToUser name all the way in order to use a single variable
    amountToUser = IERC20Upgradeable(tokenTo).balanceOf(address(this));

    // Only approve one token for the max amount
    IERC20Upgradeable(tokenFrom).safeApprove(paraswapTransferProxy, amountFrom);
    // Do swap
    // Arbitary call, must vailidate the state after
    safeExecuteOnParaswap(data);

    // After swap, reuse variables to save stack space
    tokenFromAmount = tokenFromAmount - IERC20Upgradeable(tokenFrom).balanceOf(address(this));
    amountToUser = IERC20Upgradeable(tokenTo).balanceOf(address(this)) - amountToUser;

    require(tokenFromAmount <= amountFrom, "HIGHER_THAN_AMOUNT_FROM");
    require(amountToUser >= minAmountTo, "LOWER_THAN_MIN_AMOUNT_TO");

    amountToFee = amountToUser - minAmountTo;
    // Fee is expresses as a max amount. The rest (ex: positive slippage) goes to the user in the MVP.
    // This logic should allow an higer success rate while the amounts quoted to users remain attractive.
    amountToFee = amountToFee > maxFeeTo ? maxFeeTo : amountToFee;
    // Final actual value of this variable
    amountToUser = amountToUser - amountToFee;

    _decreaseBalance(tokenFrom, user, tokenFromAmount);
    _increaseBalance(tokenTo, user, amountToUser);
    _increaseBalance(tokenTo, address(this), amountToFee);

    // Ensure any amount not spent is disallowed
    IERC20Upgradeable(tokenFrom).safeApprove(paraswapTransferProxy, 0);
  }

  function safeExecuteOnParaswap(
    bytes memory _data
  ) private {
    AddressUpgradeable.functionCall(paraswap, _data, "PARASWAP_CALL_FAILED");
  }

  function verifySwapSignature(
    SwapConstraints calldata swapConstraints,
    bytes memory signature
  ) private {
    require(swapConstraints.nonce > userNonces[swapConstraints.user], "NONCE_ALREADY_USED");
    require(swapConstraints.chainId == block.chainid, "INVALID_CHAIN");

    bytes32 structHash = _hashTypedDataV4(keccak256(
      abi.encode(
        _SWAP_TYPEHASH,
        swapConstraints.user,
        swapConstraints.swapGateway,
        swapConstraints.tokenFrom,
        swapConstraints.tokenTo,
        swapConstraints.amountFrom,
        swapConstraints.minAmountTo,
        swapConstraints.nonce,
        swapConstraints.deadline,
        swapConstraints.chainId
      )
    ));

    address signer = ECDSAUpgradeable.recover(structHash, signature);
    require(signer == swapConstraints.user, "INVALID_SIGNATURE");

    userNonces[swapConstraints.user] = swapConstraints.nonce;
  }
}