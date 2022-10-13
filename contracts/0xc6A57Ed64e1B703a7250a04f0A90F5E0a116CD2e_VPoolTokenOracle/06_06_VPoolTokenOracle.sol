// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../../interfaces/periphery/IOracle.sol";
import "../../interfaces/periphery/ITokenOracle.sol";
import "../../interfaces/external/vesper/IVesperPool.sol";

/**
 * @title Oracle for vPool token
 */
contract VPoolTokenOracle is ITokenOracle {
    /// @inheritdoc ITokenOracle
    function getPriceInUsd(address token_) external view override returns (uint256 _priceInUsd) {
        IVesperPool _vToken = IVesperPool(token_);
        address _underlyingAddress = _vToken.token();
        _priceInUsd =
            (IOracle(msg.sender).getPriceInUsd(_underlyingAddress) * _vToken.pricePerShare()) /
            10**IERC20Metadata(_underlyingAddress).decimals();
    }
}