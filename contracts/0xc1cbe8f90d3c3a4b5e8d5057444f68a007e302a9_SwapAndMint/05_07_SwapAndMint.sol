// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./utils/ownable.sol";
import "./interfaces/IFactory.sol";
import "v3-periphery/interfaces/ISwapRouter.sol";
import "v3-periphery/libraries/TransferHelper.sol";

contract SwapAndMint {
  ISwapRouter public immutable router;
  FactoryInterface public immutable factory;
  IERC20 public immutable weth;
  IERC20 public immutable usdc;
  IERC20 public immutable amkt;
  string public constant depositAddress = "forge";

  address public swapper;
  address public admin;
  address public proposedAdmin;

  uint24 public constant poolFee = 3000;

  modifier only(address who) {
    require(msg.sender == who, "invalid permissions");
    _;
  }

  constructor(
    address _router,
    address _factory,
    address _usdc,
    address _weth,
    address _amkt,
    address _swapper,
    address _admin
  ) {
    router = ISwapRouter(_router);
    factory = FactoryInterface(_factory);
    weth = IERC20(_weth);
    usdc = IERC20(_usdc);
    amkt = IERC20(_amkt);
    swapper = _swapper;
    admin = _admin;
  }

  function swapAndMint(
    uint256 amountIn,
    uint256 amountOutMin,
    string calldata txid
  ) external only(swapper) {
    swapExactInput(amountIn, amountOutMin);
    addRequest(amountIn, txid);
  }

  function swapAndBurn(
    uint256 amountInMax,
    uint256 amountOut,
    string calldata txid
  ) external only(swapper) {
    swapExactOutput(amountInMax, amountOut);
    burnRequest(amountOut, txid);
  }

  ///////////////////////////// INTERNAL ///////////////////////////////////

  function swapExactInput(uint256 amountIn, uint256 amountOutMin)
    internal
    returns (uint256 amountOut)
  {
    ISwapRouter.ExactInputParams memory params;
    amkt.approve(address(router), amountIn);

    params = ISwapRouter.ExactInputParams({
      path: abi.encodePacked(
        address(amkt),
        poolFee,
        address(weth),
        poolFee,
        address(usdc)
      ),
      recipient: address(this),
      deadline: block.timestamp,
      amountIn: amountIn,
      amountOutMinimum: amountOutMin
    });

    // Executes the swap.
    amountOut = router.exactInput(params);
  }

  function swapExactOutput(uint256 amountInMax, uint256 amountOut)
    internal
    returns (uint256 amountIn)
  {
    ISwapRouter.ExactOutputParams memory params;
    usdc.approve(address(router), amountInMax);

    // exact output path is encoded backwards!
    // read the docs nerd
    params = ISwapRouter.ExactOutputParams({
      path: abi.encodePacked(
        address(amkt),
        poolFee,
        address(weth),
        poolFee,
        address(usdc)
      ),
      recipient: address(this),
      deadline: block.timestamp,
      amountOut: amountOut,
      amountInMaximum: amountInMax
    });

    // Executes the swap.
    amountIn = router.exactOutput(params);
  }

  function addRequest(uint256 amount, string memory txid) internal {
    factory.addMintRequest(amount, txid, depositAddress);
  }

  function burnRequest(uint256 amount, string memory txid) internal {
    amkt.approve(address(factory), amount);
    factory.burn(amount, txid);
  }

  ///////////////////////////// ADMIN ///////////////////////////////////

  function removeTokens(
    uint256 amount,
    address dst,
    bool _amkt
  ) external only(admin) {
    if (_amkt) {
      amkt.transfer(dst, amount);
    } else {
      usdc.transfer(dst, amount);
    }
  }

  function arbitraryCall(
    address to,
    bytes calldata data,
    uint256 _value
  ) external only(admin) returns (bytes memory) {
    (bool success, bytes memory data) = to.call{value: _value}(data);
    require(success, "call failed");
    return data;
  }

  ///////////////////////////// SETTERS ///////////////////////////////////

  function setSwapper(address _swapper) external only(admin) {
    swapper = _swapper;
  }

  function proposeAdmin(address _proposedAdmin) external only(admin) {
    proposedAdmin = _proposedAdmin;
  }

  function takeAdmin() external only(proposedAdmin) {
    admin = proposedAdmin;
  }

  function setMerchantDepositAddress() external {
    factory.setMerchantDepositAddress("forge");
  }
}