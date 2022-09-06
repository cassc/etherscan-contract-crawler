// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../interfaces/periphery/IOracle.sol";
import "../../interfaces/periphery/ITokenOracle.sol";
import "../../interfaces/external/badger/IXToken.sol";

/**
 * @title Oracle for ibBTC token
 */
contract IbBtcTokenOracle is ITokenOracle {
    IXToken public constant IBBTC = IXToken(0xc4E15973E6fF2A35cC804c2CF9D2a1b817a8b40F);
    IXToken public constant WIBBTC = IXToken(0x8751D4196027d4e6DA63716fA7786B5174F04C15);

    /// @notice BTC/USD oracle
    ITokenOracle public immutable btcOracle;

    constructor(ITokenOracle btcOracle_) {
        btcOracle = btcOracle_;
    }

    /// @inheritdoc ITokenOracle
    function getPriceInUsd(address token_) external view override returns (uint256 _priceInUsd) {
        if (token_ == address(IBBTC)) {
            return (btcOracle.getPriceInUsd(address(0)) * IBBTC.pricePerShare()) / 1e18;
        }
        if (token_ == address(WIBBTC)) {
            return (btcOracle.getPriceInUsd(address(0)) * IBBTC.pricePerShare()) / WIBBTC.pricePerShare();
        }

        revert("invalid-ibbtc-related-token");
    }
}