// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IBEP20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IRouter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HoneypotChecker is Ownable {
    constructor() {}

    uint256 MAX_INT = 2**256 - 1;

    struct CheckerResponse {
        uint256 buyGas;
        uint256 sellGas;
        uint256 estimatedBuy;
        uint256 exactBuy;
        uint256 estimatedSell;
        uint256 exactSell;
    }

    function destroy() external payable onlyOwner {
        address owner = owner();
        selfdestruct(payable(owner));
    }

    function _calculateGas(IRouter router, uint256 amountIn, address[] memory path) internal returns (uint256){
        uint256 usedGas = gasleft();

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn, 
            0, 
            path, 
            address(this), 
            block.timestamp + 100
        );

        usedGas = usedGas - gasleft();

        return usedGas;
    }

    function check(address dexRouter, address[] calldata path) external payable returns(CheckerResponse memory) {
        require(path.length == 2);

        IRouter router = IRouter(dexRouter);

        IBEP20 baseToken = IBEP20(path[0]);
        IBEP20 targetToken = IBEP20(path[1]);

        uint tokenBalance;
        address[] memory routePath = new address[](2);
        uint expectedAmountsOut;


        if(path[0] == router.WETH()) {
            IWETH wbnb = IWETH(router.WETH());
            wbnb.deposit{value: msg.value}();

            tokenBalance = baseToken.balanceOf(address(this));
            expectedAmountsOut = router.getAmountsOut(msg.value, path)[1];
        } else {
            routePath[0] = router.WETH();
            routePath[1] = path[0];
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
                0,
                routePath,
                address(this), 
                block.timestamp + 100
            );
            tokenBalance = baseToken.balanceOf(address(this));
            expectedAmountsOut = router.getAmountsOut(tokenBalance, path)[1];
        }

        // approve token
        baseToken.approve(dexRouter, MAX_INT);
        targetToken.approve(dexRouter, MAX_INT);

        uint estimatedBuy = expectedAmountsOut;

        uint buyGas = _calculateGas(router, tokenBalance, path);

        tokenBalance = targetToken.balanceOf(address(this));

        uint exactBuy = tokenBalance;

        //swap Path
        routePath[0] = path[1];
        routePath[1] = path[0];

        expectedAmountsOut = router.getAmountsOut(tokenBalance, routePath)[1];

        uint estimatedSell = expectedAmountsOut;

        uint sellGas = _calculateGas(router, tokenBalance, routePath);

        tokenBalance = baseToken.balanceOf(address(this));

        uint exactSell = tokenBalance;

        CheckerResponse memory response = CheckerResponse(
            buyGas,
            sellGas,
            estimatedBuy,
            exactBuy,
            estimatedSell,
            exactSell
        );

        return response;
    }
}