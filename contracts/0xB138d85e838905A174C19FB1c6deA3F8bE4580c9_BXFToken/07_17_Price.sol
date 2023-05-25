// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./StandardToken.sol";


abstract contract Price is StandardToken {
    using SafeMath for uint256;

    uint256 constant private INITIAL_TOKEN_PRICE = 0.0000001 ether;
    uint256 constant private INCREMENT_TOKEN_PRICE = 0.00000001 ether;


    function tokenPrice() public view returns(uint256) {
        return tokensToEthereum(1 ether);
    }


    function ethereumToTokens(uint256 _ethereum) internal view returns(uint256) {
        uint256 _tokenPriceInitial = INITIAL_TOKEN_PRICE * 1e18;
        uint256 _tokensReceived =
        (
        (
        // underflow attempts BTFO
        SafeMath.sub(
            (sqrt
        (
            (_tokenPriceInitial**2)
            +
            (2*(INCREMENT_TOKEN_PRICE * 1e18)*(_ethereum * 1e18))
            +
            (((INCREMENT_TOKEN_PRICE)**2)*(totalSupply()**2))
            +
            (2*(INCREMENT_TOKEN_PRICE)*_tokenPriceInitial*totalSupply())
        )
            ), _tokenPriceInitial
        )
        )/(INCREMENT_TOKEN_PRICE)
        )-(totalSupply())
        ;

        return _tokensReceived;
    }


    function tokensToEthereum(uint256 _tokens) internal view returns(uint256) {
        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (totalSupply() + 1e18);
        uint256 _etherReceived =
        (
        // underflow attempts BTFO
        SafeMath.add(
            (
            (
            (
            INITIAL_TOKEN_PRICE + (INCREMENT_TOKEN_PRICE * (_tokenSupply / 1e18))
            ) - INCREMENT_TOKEN_PRICE
            ) * (tokens_ - 1e18)
            ), (INCREMENT_TOKEN_PRICE * ((tokens_ ** 2 - tokens_) / 1e18)) / 2
        )
        /1e18);
        return _etherReceived;
    }


    function sqrt(uint x) internal pure returns(uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}