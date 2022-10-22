//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IDuetOracle.sol";
import "./interfaces/IERC20.sol";
import "./lib/Adminable.sol";
import "./interfaces/IDodoOracle.sol";

contract DodoOracle is Adminable, Initializable, IDodoOracle {
    // token address => duet oracle
    mapping(address => IDuetOracle) public duetOracleMapping;
    /**
     * fallback oracle for tokens which no oracle in duetOracleMapping
     */
    IDuetOracle public fallbackDuetOracle;

    function initialize(address admin_) external initializer {
        _setAdmin(admin_);
    }

    function setFallbackDuetOracle(IDuetOracle fallbackDuetOracle_) external onlyAdmin {
        fallbackDuetOracle = fallbackDuetOracle_;
    }

    function setDuetOracle(address token_, IDuetOracle duetOracle_) external onlyAdmin {
        duetOracleMapping[token_] = duetOracle_;
    }

    function prices(address base_) external view returns (uint256 price) {
        if (address(duetOracleMapping[base_]) == address(0)) {
            price = fallbackDuetOracle.getPrice(base_);
        } else {
            price = duetOracleMapping[base_].getPrice(base_);
        }
        require(price > 0, "Invalid price from oracle");

        uint256 baseTokenDecimals = IERC20(base_).decimals();
        require(baseTokenDecimals < 36, "decimals of base token is too high");
        // decimals for Dodo is `18 - base + quote`
        // quote token is always BUSD, it is 1e18
        // duet oracle returns 1e8 value
        uint256 targetDecimals = uint256(18 - int256(baseTokenDecimals) + 18);
        if (targetDecimals == 8) {
            return price;
        }
        if (targetDecimals > 8) {
            return price * 10**(targetDecimals - 8);
        }
        return price / (10**(8 - targetDecimals));
    }
}