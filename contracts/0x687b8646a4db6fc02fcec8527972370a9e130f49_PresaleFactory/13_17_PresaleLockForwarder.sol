// SPDX-License-Identifier: UNLICENSED
// @Credits Unicrypt Network 2021

/**
    This contract creates the lock on behalf of each presale. This contract will be whitelisted to bypass the flat rate 
    ETH fee. Please do not use the below locking code in your own contracts as the lock will fail without the ETH fee
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PresaleManage.sol";
import "../../interfaces/IWETH.sol";
import "../../interfaces/IUniswapV2Factory.sol";
import "../../interfaces/IUniswapV2Router02.sol";
import "../../interfaces/IUniswapV2Pair.sol";
import "../../LiquidityLock/LPLock.sol";
import "../TransferHelper.sol";

contract PresaleLockForwarder {
    LPLocker public lplocker;
    IUniswapV2Factory public uniswapfactory;
    IUniswapV2Router02 public uniswaprouter;

    PresaleManage manage;
    IWETH public WETH;

    mapping(address => address) public locked_lp_tokens;
    mapping(address => address) public locked_lp_owner;

    constructor(
        address _manage,
        address lplock_addrress,
        address unifactaddr,
        address unirouter,
        address wethaddr
    ) public {
        lplocker = LPLocker(lplock_addrress);
        uniswapfactory = IUniswapV2Factory(unifactaddr);
        uniswaprouter = IUniswapV2Router02(unirouter);
        WETH = IWETH(wethaddr);
        manage = PresaleManage(_manage);
    }

    /**
        Send in _token0 as the PRESALE token, _token1 as the BASE token (usually WETH) for the check to work. As anyone can create a pair,
        and send WETH to it while a presale is running, but no one should have access to the presale token. If they do and they send it to 
        the pair, scewing the initial liquidity, this function will return true
    */
    function uniswapPairIsInitialised(address _token0, address _token1)
        public
        view
        returns (bool)
    {
        address pairAddress = uniswapfactory.getPair(_token0, _token1);
        if (pairAddress == address(0)) {
            return false;
        }
        uint256 balance = IERC20(_token0).balanceOf(pairAddress);
        if (balance > 0) {
            return true;
        }
        return false;
    }

    // function lockLiquidity (IERC20 _saleToken, uint256 _unlock_date, address payable _withdrawer) payable external {

    //     require(msg.value >= lplocker.price(), 'Balance is insufficient');

    //     address pair = uniswapfactory.getPair(address(WETH), address(_saleToken));

    //     uint256 totalLPTokensMinted = IUniswapV2Pair(pair).balanceOf(address(this));
    //     require(totalLPTokensMinted != 0 , "LP creation failed");

    //     TransferHelper.safeApprove(pair, address(lplocker), totalLPTokensMinted);
    //     uint256 unlock_date = _unlock_date > 9999999999 ? 9999999999 : _unlock_date;

    //     lplocker.lpLock{value:lplocker.price()}(pair, totalLPTokensMinted, unlock_date, _withdrawer );

    //     lptokens[msg.sender] = pair;
    // }

    function lockLiquidity(
        address _saleToken,
        uint256 _baseAmount,
        uint256 _saleAmount,
        uint256 _unlock_date,
        address payable _withdrawer
    ) external payable {
        require(manage.IsRegistered(msg.sender), "PRESALE NOT REGISTERED");
        require(
            msg.value >= lplocker.price() + _baseAmount,
            "Balance is insufficient"
        );

        // if (pair == address(0)) {
        //     uniswapfactory.createPair(address(WETH), address(_saleToken));
        //     pair = uniswapfactory.getPair(address(WETH), address(_saleToken));
        // }

        // require(WETH.transferFrom(msg.sender, address(this), _baseAmount), 'WETH transfer failed.');
        // TransferHelper.safeTransferFrom(address(_baseToken), msg.sender, address(pair), _baseAmount);
        TransferHelper.safeTransferFrom(
            address(_saleToken),
            msg.sender,
            address(this),
            _saleAmount
        );
        // IUniswapV2Pair(pair).mint(address(this));
        // return;
        // require(WETH.approve(address(uniswaprouter), _baseAmount), 'router approve failed.');
        // _saleToken.approve(address(uniswaprouter), _saleAmount);
        TransferHelper.safeApprove(
            address(_saleToken),
            address(uniswaprouter),
            _saleAmount
        );
        // construct token path
        // address[] memory path = new address[](2);
        // path[0] = address(WETH);
        // path[1] = address(_saleToken);

        // IUniswapV2Router02(uniswaprouter).swapExactTokensForTokens(
        //     WETH.balanceOf(address(this)).div(2),
        //     0,
        //     path,
        //     address(this),
        //     block.timestamp + 5 minutes
        // );

        // // calculate balances and add liquidity
        // uint256 wethBalance = WETH.balanceOf(address(this));
        // uint256 balance = _saleToken.balanceOf(address(this));

        // IUniswapV2Router02(uniswaprouter).addLiquidity(
        //     address(_saleToken),
        //     address(WETH),
        //     balance,
        //     wethBalance,
        //     0,
        //     0,
        //     address(this),
        //     block.timestamp + 5 minutes
        // );

        IUniswapV2Router02(address(uniswaprouter)).addLiquidityETH{
            value: _baseAmount
        }(
            address(_saleToken),
            _saleAmount,
            0,
            0,
            payable(address(this)),
            block.timestamp + 5 minutes
        );

        address pair = uniswapfactory.getPair(
            address(WETH),
            address(_saleToken)
        );

        uint256 totalLPTokensMinted = IUniswapV2Pair(pair).balanceOf(
            address(this)
        );
        require(totalLPTokensMinted != 0, "LP creation failed");

        TransferHelper.safeApprove(
            pair,
            address(lplocker),
            totalLPTokensMinted
        );
        uint256 unlock_date = _unlock_date > 9999999999
            ? 9999999999
            : _unlock_date;

        lplocker.lpLock{value: lplocker.price()}(
            pair,
            totalLPTokensMinted,
            unlock_date,
            _withdrawer
        );

        locked_lp_tokens[address(_saleToken)] = pair;
        locked_lp_owner[address(_saleToken)] = _withdrawer;

        payable(_withdrawer).transfer(address(this).balance);
    }
}