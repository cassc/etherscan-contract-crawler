// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./BaseProxy.sol";

abstract contract BaseInvoicesToken is BaseProxy {
    using SafeMath for uint256;
    using SafeMath for uint8;

    mapping(address => bool) public tokenList;
    mapping(uint256 => address) public invoiceToken;

    /**
     * @notice Emitted when invoice was created
     * @param invoice_id Identifier of invoice. Indexed
     * @param amount Amount of USDT for pay
     * @param seller Address of seller. Indexed
     * @param timestamp time of ctreation
     * @param creator address of creator
     * @param token address of token
     */
    event created(
        uint256 indexed invoice_id,
        uint256 amount,
        address indexed seller,
        uint256 timestamp,
        address creator,
        address token
    );

        /**
     * @notice Add addresses to WhiteList
     * @dev Only for owner
     * @param _tokens Array of addresses
     */
    function addToTokenList(address[] calldata _tokens) external onlyOwner {
        for (uint i = 0; i < _tokens.length; i++) {
            if (!tokenList[_tokens[i]]) tokenList[_tokens[i]] = true;
        }
    }

    /**
     * @notice Remove addresses from tokenList
     * @dev Only for owner
     * @param _tokens Array of addresses
     */
    function removeFromTokenList(
        address[] calldata _tokens
    ) external onlyOwner {
        for (uint i = 0; i < _tokens.length; i++) {
            if (tokenList[_tokens[i]]) tokenList[_tokens[i]] = false;
        }
    }

    function verifyToken(address _token) external view virtual returns (bool) {
        return tokenList[_token];
    }

    function feeCalculation (uint256 _feeConst, uint8 _decimal) internal view virtual returns (uint256) {
        if (_decimal == 18) {
            return _feeConst;
        }

        if (_decimal > 18) {
            uint256 newDeciaml = 10 **(_decimal - 18);
            return _feeConst.mul(newDeciaml);
        }

        if (_decimal < 18) {
            uint256 newDeciaml = 10 ** (18 - _decimal);
            return _feeConst.div(newDeciaml);
        }

        return _feeConst;
    }
}