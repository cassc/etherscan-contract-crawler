// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IERC20Decimals {
    function decimals() external view returns (uint8);
}

/**
 * @dev a standard ERC20 contract that is extended with a few methods
 * described in detail below
 */
contract AelinERC20 is ERC20 {
    bool setInfo;
    /**
     * @dev Due to the constructor being empty for the MinimalProxy architecture we need
     * to set the name and symbol in the initializer which requires these custom variables
     */
    string private _custom_name;
    string private _custom_symbol;
    uint8 private _custom_decimals;
    bool private locked;
    uint8 constant DEAL_TOKEN_DECIMALS = 18;

    constructor() ERC20("", "") {}

    modifier initInfoOnce() {
        require(!setInfo, "can only initialize once");
        _;
    }

    /**
     * @dev Due to the constructor being empty for the MinimalProxy architecture we need
     * to set the name, symbol, and decimals in the initializer which requires this
     * custom logic for name(), symbol(), decimals(), and _setNameSymbolAndDecimals()
     */
    function name() public view virtual override returns (string memory) {
        return _custom_name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _custom_symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _custom_decimals;
    }

    function _setNameSymbolAndDecimals(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) internal initInfoOnce returns (bool) {
        _custom_name = _name;
        _custom_symbol = _symbol;
        _custom_decimals = _decimals;
        setInfo = true;
        emit AelinToken(_name, _symbol, _decimals);
        return true;
    }

    /**
     * @dev Add this to prevent reentrancy attacks on purchasePoolTokens and depositUnderlying
     * source: https://quantstamp.com/blog/how-the-dforce-hacker-used-reentrancy-to-steal-25-million
     * uniswap implementation: https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol#L31-L36
     */
    modifier lock() {
        require(!locked, "AelinV1: LOCKED");
        locked = true;
        _;
        locked = false;
    }

    event AelinToken(string name, string symbol, uint8 decimals);
}