// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./../interfaces/IExchangeAdapter.sol";

// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase
interface ICurveFraxDola {
    function add_liquidity(
        address _pool,
        uint256[3] memory _amounts,
        uint256 _min_mint_amount
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        address _pool,
        uint256 _burn_amount,
        int128 i,
        uint256 _min_received
    ) external returns (uint256);
}

contract CurveFraxDolaAdapter is IExchangeAdapter {
    address public constant DOLA_FRAX =
        0xE57180685E3348589E9521aa53Af0BCD497E884d;

    function indexByCoin(address coin) public pure returns (int128) {
        if (coin == 0x865377367054516e17014CcdED1e7d814EDC9ce4) return 1; // dola
        if (coin == 0x853d955aCEf822Db058eb8505911ED77F175b99e) return 2; // frax
        if (coin == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) return 3; // usdc
        return 0;
    }

    // 0x6012856e  =>  executeSwap(address,address,address,uint256)
    function executeSwap(
        address pool,
        address fromToken,
        address toToken,
        uint256 amount
    ) external payable returns (uint256) {
        ICurveFraxDola curve = ICurveFraxDola(pool);
        if (toToken == DOLA_FRAX) {
            uint128 i = uint128(indexByCoin(fromToken));
            require(i != 0, "CurveFraxDolaAdapter: Can't Swap");
            uint256[3] memory entryVector;
            entryVector[i - 1] = amount;
            return curve.add_liquidity(DOLA_FRAX, entryVector, 0);
        } else if (fromToken == DOLA_FRAX) {
            int128 i = indexByCoin(toToken);
            require(i != 0, "CurveFraxDolaAdapter: Can't Swap");
            return curve.remove_liquidity_one_coin(DOLA_FRAX, amount, i - 1, 0);
        } else {
            revert("CurveFraxDolaAdapter: Can't Swap");
        }
    }

    // 0xe83bbb76  =>  enterPool(address,address,address,uint256)
    function enterPool(
        address,
        address,
        uint256
    ) external payable returns (uint256) {
        revert("CurveFraxDolaAdapter: Can't Swap");
    }

    // 0x9d756192  =>  exitPool(address,address,address,uint256)
    function exitPool(
        address,
        address,
        uint256
    ) external payable returns (uint256) {
        revert("CurveFraxDolaAdapter: Can't Swap");
    }
}