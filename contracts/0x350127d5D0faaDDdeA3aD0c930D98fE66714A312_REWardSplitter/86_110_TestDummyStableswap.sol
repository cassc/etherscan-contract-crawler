// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Curve/ICurveStableSwap.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract TestDummyStableswap is ERC20("test", "TST"), ERC20Permit("test"), ICurveStableSwap
{
    IERC20Full immutable coin0;
    IERC20Full immutable coin1;
    uint256 public get_virtual_price = 1 ether;

    uint256 public removeLiquidityAmount;
    uint256 public removeLiquidityMinAmounts0;
    uint256 public removeLiquidityMinAmounts1;
    uint256 public removeLiquidityMinAmounts2;
    uint256 public removeLiquidityMinAmounts3;
    uint256 nextAddLiquidityMintAmount;
    uint256 public addLiquidityAmounts0;
    uint256 public addLiquidityAmounts1;
    uint256 public addLiquidityMinAmount;
    bool public addLiquidityCalled;
    uint256 nextRemoveLiquidityOneCoinReceived;
    uint256 public removeLiquidityOneCoinAmount;
    uint256 public removeLiquidityOneCoinMinReceived;
    bool addLiquidityTransfer;
    bool skipRemoveLiquidityBurn;

    mapping (uint256 => uint256) _balances;

    constructor(IERC20Full _coin0, IERC20Full _coin1)
    {
        coin0 = _coin0;
        coin1 = _coin1;
    }

    function mint(address to, uint256 amount) public { _mint(to, amount); }

    function coins(uint256 index) public view returns (IERC20Full)
    {
        if (index == 0) { return coin0; }
        if (index == 1) { return coin1; }
        revert();
    }
    function balances(uint256 index) public view returns (uint256) { return _balances[index]; }

    function setBalance(uint256 index, uint256 balance) public { _balances[index] = balance; }
    function setVirtualPrice(uint256 newPrice) public { get_virtual_price = newPrice; }
    function setNextAddLiquidityMintAmount(uint256 amount) public { nextAddLiquidityMintAmount = amount; }
    function setNextRemoveLiquidityOneCoinReceived(uint256 amount) public { nextRemoveLiquidityOneCoinReceived = amount; }

    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256) {}

    function version() external view returns (string memory) {}

    function remove_liquidity(uint256 amount, uint256[2] memory minAmounts) external returns (uint256[2] memory receivedAmounts)
    {
        removeLiquidityAmount = amount;
        removeLiquidityMinAmounts0 = minAmounts[0];
        removeLiquidityMinAmounts1 = minAmounts[1];
        receivedAmounts[0] = 123;
        receivedAmounts[1] = 234;
    }
    function remove_liquidity(uint256 amount, uint256[3] memory minAmounts) external returns (uint256[3] memory receivedAmounts)
    {
        removeLiquidityAmount = amount;
        removeLiquidityMinAmounts0 = minAmounts[0];
        removeLiquidityMinAmounts1 = minAmounts[1];
        removeLiquidityMinAmounts2 = minAmounts[2];
        receivedAmounts[0] = 123;
        receivedAmounts[1] = 234;
        receivedAmounts[2] = 345;
    }
    function remove_liquidity(uint256 amount, uint256[4] memory minAmounts) external returns (uint256[4] memory receivedAmounts)
    {
        removeLiquidityAmount = amount;
        removeLiquidityMinAmounts0 = minAmounts[0];
        removeLiquidityMinAmounts1 = minAmounts[1];
        removeLiquidityMinAmounts2 = minAmounts[2];
        removeLiquidityMinAmounts3 = minAmounts[3];
        receivedAmounts[0] = 123;
        receivedAmounts[1] = 234;
        receivedAmounts[2] = 345;
        receivedAmounts[3] = 456;
    }
    function setAddLiquidityTransfer(bool transfer) public { addLiquidityTransfer = transfer; }
    function add_liquidity(uint256[2] memory amounts, uint256 minMintAmount) external
    {
        _mint(msg.sender, nextAddLiquidityMintAmount);
        if (addLiquidityTransfer)
        {
            coin0.transferFrom(msg.sender, address(this), amounts[0]);
            coin1.transferFrom(msg.sender, address(this), amounts[1]);
        }
        addLiquidityAmounts0 = amounts[0];
        addLiquidityAmounts1 = amounts[1];
        addLiquidityMinAmount = minMintAmount;
        addLiquidityCalled = true;
    }
    function setSkipLiquidityBurn(bool skip) public { skipRemoveLiquidityBurn = skip; }
    function remove_liquidity_one_coin(uint256 amount, int128 tokenIndex, uint256 minReceived) external
    {
        if (!skipRemoveLiquidityBurn)
        {
            _burn(msg.sender, amount);
        }
        coins(uint128(tokenIndex)).transfer(msg.sender, nextRemoveLiquidityOneCoinReceived);
        removeLiquidityOneCoinAmount = amount;
        removeLiquidityOneCoinMinReceived = minReceived;
    }
}