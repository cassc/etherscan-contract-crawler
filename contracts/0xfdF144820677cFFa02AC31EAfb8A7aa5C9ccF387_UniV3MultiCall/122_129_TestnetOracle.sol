// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Errors} from "../Errors.sol";
import {IOracle} from "../peer-to-peer/interfaces/IOracle.sol";

contract TestnetOracle is Ownable, IOracle {
    mapping(address => uint256) public tokenPricesInUsdc;

    // @dev: set prices in USDC with 1e6
    function setPrices(
        address[] memory tokenAddrs,
        uint256[] memory _tokenPricesInUsdc
    ) external onlyOwner {
        uint256 tokenAddrLen = tokenAddrs.length;
        if (tokenAddrLen == 0 || tokenAddrLen != _tokenPricesInUsdc.length) {
            revert Errors.InvalidArrayLength();
        }
        for (uint i; i < tokenAddrLen; ) {
            if (
                _tokenPricesInUsdc[i] == 0 ||
                _tokenPricesInUsdc[i] == tokenPricesInUsdc[tokenAddrs[i]]
            ) {
                revert Errors.InvalidUpdate();
            }
            tokenPricesInUsdc[tokenAddrs[i]] = _tokenPricesInUsdc[i];
            unchecked {
                ++i;
            }
        }
    }

    function getPrice(
        address collToken,
        address loanToken
    ) external view override returns (uint256 collTokenPriceInLoanToken) {
        (uint256 collTokenPriceRaw, uint256 loanTokenPriceRaw) = getRawPrices(
            collToken,
            loanToken
        );
        uint256 decimals = IERC20Metadata(loanToken).decimals();
        if (decimals == 0) {
            revert Errors.InvalidAddress();
        }
        return
            Math.mulDiv(collTokenPriceRaw, 10 ** decimals, loanTokenPriceRaw);
    }

    function getRawPrices(
        address collToken,
        address loanToken
    )
        public
        view
        override
        returns (uint256 collTokenPriceRaw, uint256 loanTokenPriceRaw)
    {
        if (
            collToken == address(0) ||
            loanToken == address(0) ||
            collToken == loanToken
        ) {
            revert Errors.InvalidAddress();
        }
        collTokenPriceRaw = tokenPricesInUsdc[collToken];
        loanTokenPriceRaw = tokenPricesInUsdc[loanToken];
        if (collTokenPriceRaw == 0 || loanTokenPriceRaw == 0) {
            revert Errors.InvalidOracleAnswer();
        }
    }
}