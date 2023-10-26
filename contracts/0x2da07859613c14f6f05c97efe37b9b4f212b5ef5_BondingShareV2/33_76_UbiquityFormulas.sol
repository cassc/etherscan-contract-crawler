// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./libs/ABDKMathQuad.sol";

contract UbiquityFormulas {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    /// @dev formula duration multiply
    /// @param _uLP , amount of LP tokens
    /// @param _weeks , mimimun duration of staking period
    /// @param _multiplier , bonding discount multiplier = 0.0001
    /// @return _shares , amount of shares
    /// @notice _shares = (1 + _multiplier * _weeks^3/2) * _uLP
    //          D32 = D^3/2
    //          S = m * D32 * A + A
    function durationMultiply(
        uint256 _uLP,
        uint256 _weeks,
        uint256 _multiplier
    ) public pure returns (uint256 _shares) {
        bytes16 unit = uint256(1 ether).fromUInt();
        bytes16 d = _weeks.fromUInt();
        bytes16 d32 = (d.mul(d).mul(d)).sqrt();
        bytes16 m = _multiplier.fromUInt().div(unit); // 0.0001
        bytes16 a = _uLP.fromUInt();

        _shares = m.mul(d32).mul(a).add(a).toUInt();
    }

    /// @dev formula bonding
    /// @param _shares , amount of shares
    /// @param _currentShareValue , current share value
    /// @param _targetPrice , target uAD price
    /// @return _uBOND , amount of bonding shares
    /// @notice UBOND = _shares / _currentShareValue * _targetPrice
    // newShares = A / V * T
    function bonding(
        uint256 _shares,
        uint256 _currentShareValue,
        uint256 _targetPrice
    ) public pure returns (uint256 _uBOND) {
        bytes16 a = _shares.fromUInt();
        bytes16 v = _currentShareValue.fromUInt();
        bytes16 t = _targetPrice.fromUInt();

        _uBOND = a.div(v).mul(t).toUInt();
    }

    /// @dev formula redeem bonds
    /// @param _uBOND , amount of bonding shares
    /// @param _currentShareValue , current share value
    /// @param _targetPrice , target uAD price
    /// @return _uLP , amount of LP tokens
    /// @notice _uLP = _uBOND * _currentShareValue / _targetPrice
    // _uLP = A * V / T
    function redeemBonds(
        uint256 _uBOND,
        uint256 _currentShareValue,
        uint256 _targetPrice
    ) public pure returns (uint256 _uLP) {
        bytes16 a = _uBOND.fromUInt();
        bytes16 v = _currentShareValue.fromUInt();
        bytes16 t = _targetPrice.fromUInt();

        _uLP = a.mul(v).div(t).toUInt();
    }

    /// @dev formula bond price
    /// @param _totalULP , total LP tokens
    /// @param _totalUBOND , total bond shares
    /// @param _targetPrice ,  target uAD price
    /// @return _priceUBOND , bond share price
    /// @notice
    // IF _totalUBOND = 0  priceBOND = TARGET_PRICE
    // ELSE                priceBOND = totalLP / totalShares * TARGET_PRICE
    // R = T == 0 ? 1 : LP / S
    // P = R * T
    function bondPrice(
        uint256 _totalULP,
        uint256 _totalUBOND,
        uint256 _targetPrice
    ) public pure returns (uint256 _priceUBOND) {
        bytes16 lp = _totalULP.fromUInt();
        bytes16 s = _totalUBOND.fromUInt();
        bytes16 r = _totalUBOND == 0 ? uint256(1).fromUInt() : lp.div(s);
        bytes16 t = _targetPrice.fromUInt();

        _priceUBOND = r.mul(t).toUInt();
    }

    /// @dev formula ugov multiply
    /// @param _multiplier , initial ugov min multiplier
    /// @param _price , current share price
    /// @return _newMultiplier , new ugov min multiplier
    /// @notice new_multiplier = multiplier * ( 1.05 / (1 + abs( 1 - price ) ) )
    // nM = M * C / A
    // A = ( 1 + abs( 1 - P)))
    // 5 >= multiplier >= 0.2
    function ugovMultiply(uint256 _multiplier, uint256 _price)
        public
        pure
        returns (uint256 _newMultiplier)
    {
        bytes16 m = _multiplier.fromUInt();
        bytes16 p = _price.fromUInt();
        bytes16 c = uint256(105 * 1e16).fromUInt(); // 1.05
        bytes16 u = uint256(1e18).fromUInt(); // 1
        bytes16 a = u.add(u.sub(p).abs()); // 1 + abs( 1 - P )

        _newMultiplier = m.mul(c).div(a).toUInt(); // nM = M * C / A

        // 5 >= multiplier >= 0.2
        if (_newMultiplier > 5e18 || _newMultiplier < 2e17)
            _newMultiplier = _multiplier;
    }
}