// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@balancer-labs/v2-solidity-utils/contracts/math/Math.sol";
import "@balancer-labs/v2-solidity-utils/contracts/math/FixedPoint.sol";
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/misc/IERC4626.sol";
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";
import "./interfaces/IERC20Extended.sol";
import "./interfaces/IRateProvider.sol";

/**
 * @title Generic ERC4626 Rate Provider
 * @dev ensure `getRate` returns scaled to 1e18
 */
contract ERC4626RateProvider is IRateProvider {
    using FixedPoint for uint256;
    
    uint256 private immutable _rateScaleFactor;
    IERC20 public immutable mainToken;
    IERC4626 public immutable wrappedToken;

    constructor(IERC4626 _wrappedToken, IERC20Extended _mainToken) {
        // We do NOT enforce mainToken == wrappedToken.asset() even
        // though this is the expected behavior in most cases. Instead,
        // we assume a 1:1 relationship between mainToken and
        // wrappedToken.asset(), but they do not have to be the same
        // token. It is vitally important that this 1:1 relationship is
        // respected, or the pool will not function as intended.
        //
        // This allows for use cases where the wrappedToken is
        // double-wrapped into an ERC-4626 token. For example, consider
        // a linear pool whose goal is to pair DAI with aDAI. Because
        // aDAI is a rebasing token, it needs to be wrapped, and let's
        // say an ERC-4626 wrapper is chosen for compatibility with this
        // linear pool. Then wrappedToken.asset() will return aDAI,
        // whereas mainToken is DAI. But the 1:1 relationship holds, and
        // the pool is still valid.
        
        uint256 wrappedTokenDecimals = IERC20Extended(address(_wrappedToken)).decimals();
        uint256 mainTokenDecimals = _mainToken.decimals();

        require(mainTokenDecimals <= 18 && wrappedTokenDecimals <= 18, "Only tokens with 18 or fewer decimals are supported");
        uint256 digitsDifference = Math.add(18, wrappedTokenDecimals).sub(mainTokenDecimals);
        _rateScaleFactor = 10**digitsDifference;
        mainToken = _mainToken;
        wrappedToken = _wrappedToken;
    }

    /**
     * @return returns exchangeRate scaled to 1e18
     * @dev scaling to 1e18 must be ensured
     */
    function getRate() external view override returns (uint256) {
        uint256 assetsPerShare = wrappedToken.convertToAssets(FixedPoint.ONE);

        // This function returns a 18 decimal fixed point number
        // assetsPerShare decimals:   18 + main - wrapped
        // _rateScaleFactor decimals: 18 - main + wrapped
        uint256 rate = assetsPerShare.mulDown(_rateScaleFactor);
        return rate;
    }
}