/**
 *Submitted for verification at BscScan.com on 2023-01-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract TokenData {

    struct Datas {
        bool IsSave;
        address Token0;
        string Name0;
        string Symbol0;
        uint8 Decimals0;
        uint256 TotalSupply0;
        address Token1;
        string Name1;
        string Symbol1;
        uint8 Decimals1;
        uint256 TotalSupply1;
    }

    function tokenData(address pair)
        public
        view
        returns (Datas memory)
    {   
        bool _save = false;
        address token0 = IBEP20(pair).token0();
        address token1 = IBEP20(pair).token1();
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IBEP20(pair).getReserves();

        uint256 balance0 = IBEP20(token0).balanceOf(pair);
        uint256 balance1 = IBEP20(token1).balanceOf(pair);

        if(balance0 == reserve0 && balance1 == reserve1 && blockTimestampLast != 0){
            _save = true;
        }

        Datas memory ds = Datas(
            _save,
            token0,
            IBEP20(token0).name(),
            IBEP20(token0).symbol(),
            IBEP20(token0).decimals(),
            IBEP20(token0).totalSupply(),
            token1,
            IBEP20(token1).name(),
            IBEP20(token1).symbol(),
            IBEP20(token1).decimals(),
            IBEP20(token1).totalSupply()
        );
        return ds;
    }
}