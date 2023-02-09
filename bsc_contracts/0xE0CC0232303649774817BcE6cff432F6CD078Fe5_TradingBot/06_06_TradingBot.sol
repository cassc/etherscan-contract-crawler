// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRouter01.sol";
import "../interfaces/IUniswapV2Router.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error FailSwap(address from, address to, uint256 amount);

contract TradingBot is Ownable { // Where the actual contract for the trading bot starts. anything above that are just libraries.
    IRouter01 thRouter;
    event Swaped(address from, address to, uint256 amountIn, uint256 amountOut);

    constructor(address _thRouter) {
        thRouter = IRouter01(_thRouter);
    }

    function setRouter(address router) onlyOwner external {
        thRouter = IRouter01(router);
    }
    // call get profit
    // call in node js// frequently
    function arb(address[] memory _paths, uint256 _fromAmount, uint256 gasFee) onlyOwner external {
        // todo _fromAmount should or not. push all invest to this contract to keep
        require(_paths.length > 0, "_paths > 0");
        address _fromToken = _paths[0];
        uint256 allowance = IERC20(_fromToken).allowance(msg.sender, address(this));
        require(allowance >= _fromAmount, "_fromAmount not allowance");
        uint256 balanceOf = IERC20(_fromToken).balanceOf(msg.sender);
        require(balanceOf >= _fromAmount, "_fromAmount not balanceOf");
        IERC20(_fromToken).transferFrom(msg.sender, address(this), _fromAmount);
        // Track original balance
        uint256 _startBalance = IERC20(_fromToken).balanceOf(address(this));

        // Perform the arb trade
        _trade(_paths, _fromAmount);

        // Track result balance
        uint256 _endBalance = IERC20(_fromToken).balanceOf(address(this));

        // Require that arbitrage is profitable
        // todo estimate real fee in token from
        uint256 transactionFee = gasFee;// gasFee
        require(_endBalance > _startBalance + transactionFee, "End balance must exceed start balance.");

        IERC20(_fromToken).transfer(msg.sender, _endBalance);
        // emit event to monitor
    }

    function _trade(address[] memory _paths, uint256 _fromAmount) internal {
        // blance of before - after
        // uint256 _beforeBalance = IERC20(_paths[0]).balanceOf(address(this));
        // loop paths and swap step by step --> a -> b -> c -> a
        // get next amount for next path
        // balance of before
        uint256 amountTransfer = _fromAmount;
        for (uint i = 0; i < _paths.length - 1; i++) {
            // amountTransfer = _pancakeSwap(_paths[i], _paths[i+1], amountTransfer);
            amountTransfer = _thSwap(_paths[i], _paths[i+1], amountTransfer);
        }
    }
    //test on pancake
    // function _pancakeSwap(address _from, address _to, uint256 _amount) internal returns (uint) {
    //     // Setup contracts
    //     uint256 amountOut;
    //     IERC20 _fromIERC20 = IERC20(_from);
    //     IERC20 _toIERC20 = IERC20(_to);
    //     uint256 _beforeTo = _toIERC20.balanceOf(address(this));
        
    //     // Approve tokens
    //     _fromIERC20.approve(address(uniswapRouter), type(uint256).max);
    //     // config router paths
    //     address[] memory paths = new address[](2);
    //     paths[0] = _from;
    //     paths[1] = _to;
        
    //     uniswapRouter.swapExactTokensForTokens(_amount, 0, paths, address(this), block.timestamp);
    //     _fromIERC20.approve(address(uniswapRouter), 0);

    //     uint256 _afterTo = _toIERC20.balanceOf(address(this));
    //     amountOut = _afterTo - _beforeTo;
    //     // Reset approval
    //     return amountOut;
    // }

    // not support stable swap 
    function _thSwap(address _from, address _to, uint256 _amount) internal returns (uint256) {
        // Setup contracts
        IERC20 _fromIERC20 = IERC20(_from);
        IERC20 _toIERC20 = IERC20(_to);
        uint256 _beforeTo = _toIERC20.balanceOf(address(this));

        // Approve tokens
        _fromIERC20.approve(address(thRouter), _amount);
        // config router paths
        IRouter01.route[] memory routes = new IRouter01.route[](1);
        routes[0] = IRouter01.route({
            from: _from, 
            to: _to,
            stable: false
        });
        // Swap tokens: give _from, get _to
        // uint[] memory amounts = thRouter.swapExactTokensForTokens(_amount, 0, routes, address(this), block.timestamp);
        (bool success, bytes memory data) = address(thRouter).call(
            abi.encodeWithSelector(IRouter01.swapExactTokensForTokens.selector, _amount, 0, routes, address(this), block.timestamp + 120)
        );
        
        // uint256[] memory amountsOut = abi.decode(data, (uint256[]));
        if (!success) {
            revert FailSwap({
                from: _from,
                to: _to,
                amount: _amount
            });
        }

        // Reset approval
        _fromIERC20.approve(address(thRouter), 0);
        uint256 _afterTo = _toIERC20.balanceOf(address(this));

        require(_afterTo > _beforeTo, "dont have any token return");

        uint256 amountOut = _afterTo - _beforeTo;
        
        emit Swaped(_from, _to, _amount, amountOut);
        
        return amountOut;
    }

    function emergencyWithdraw(
        address _tokenAddress,
        address _to,
        uint _amount
    ) external onlyOwner {
        IERC20 erc20 = IERC20(_tokenAddress);
        erc20.transfer(_to, _amount);
    }
}