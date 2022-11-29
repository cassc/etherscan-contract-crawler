// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./abstract/PoolMetadata.sol";
import "./abstract/PoolRewards.sol";
import "./abstract/PoolConfiguration.sol";

/// @notice This is perimary protocol contract, describing borrowing Pool
contract PoolMaster is PoolRewards, PoolConfiguration, PoolMetadata {
    // CONSTRUCTOR

    /// @notice Upgradeable contract constructor
    /// @param manager_ Address of the Pool's manager
    /// @param currency_ Address of the currency token
    function initialize(address manager_, IERC20Upgradeable currency_)
        public
        initializer
    {
        __PoolBaseInfo_init(manager_, currency_);
    }

    // VERSION

    function version() external pure virtual returns (string memory) {
        return "1.1.0";
    }

    // OVERRIDES

    /// @notice Override of the mint function, see {IERC20-_mint}
    function _mint(address account, uint256 amount)
        internal
        override(ERC20Upgradeable, PoolRewards)
    {
        super._mint(account, amount);
    }

    /// @notice Override of the mint function, see {IERC20-_burn}
    function _burn(address account, uint256 amount)
        internal
        override(ERC20Upgradeable, PoolRewards)
    {
        super._burn(account, amount);
    }

    /// @notice Override of the transfer function, see {IERC20-_transfer}
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, PoolRewards) {
        super._transfer(from, to, amount);
    }

    /// @notice Override of the decimals function, see {IERC20Metadata-decimals}
    /// @return r-token decimals
    function decimals()
        public
        view
        override(ERC20Upgradeable, PoolMetadata)
        returns (uint8)
    {
        return super.decimals();
    }

    /// @notice Override of the decimals function, see {IERC20Metadata-symbol}
    /// @return Pool's symbol
    function symbol()
        public
        view
        override(ERC20Upgradeable, PoolMetadata)
        returns (string memory)
    {
        return super.symbol();
    }
}