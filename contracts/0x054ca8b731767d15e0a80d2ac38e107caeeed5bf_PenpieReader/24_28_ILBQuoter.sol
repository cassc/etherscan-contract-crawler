pragma solidity =0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ILBRouter } from "./ILBRouter.sol";

interface ILBQuoter {

   struct Quote {
        address[] route;
        address[] pairs;
        uint256[] binSteps;
        uint256[] amounts;
        uint256[] virtualAmountsWithoutSlippage;
        uint256[] fees;
    }

    function findBestPathFromAmountIn(address[] calldata route, uint256 amountIn)
        external
        view
    returns (Quote memory quote);
}