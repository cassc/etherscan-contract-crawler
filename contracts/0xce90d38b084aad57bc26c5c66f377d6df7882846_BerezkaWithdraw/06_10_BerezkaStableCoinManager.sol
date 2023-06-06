// SPDX-License-Identifier: Unlicense
// Developed by EasyChain Blockchain Development Team (easychain.tech)
//
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract BerezkaStableCoinManager is Ownable {
    
    // Stable token whitelist to use
    //
    mapping(address => bool) public whitelist;

    modifier isWhitelisted(
        address _targetToken
    ) {
        require(whitelist[_targetToken], "INVALID_TOKEN_TO_DEPOSIT");
        _;
    }

    // Computes an amount of _targetToken that user will get in exchange for
    // a given amount for DAO tokens
    // _amount - amount of DAO tokens
    // _price - price in 6 decimals per 10e18 of DAO token
    // _targetToken - target token to receive
    //
    function computeExchange(
        uint256 _amount,
        uint256 _price,
        address _targetToken
    ) public view returns (uint256) {
        IERC20Metadata targetToken = IERC20Metadata(_targetToken);
        uint256 result = _amount * _price / 10 ** (24 - targetToken.decimals());
        require(result > 0, "INVALID_TOKEN_AMOUNT");
        return result;
    }

    // Adds possible tokens (stableconins) to use
    // _whitelisted - list of stableconins to use
    //
    function addWhitelistTokens(address[] memory _whitelisted)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _whitelisted.length; i++) {
            whitelist[_whitelisted[i]] = true;
        }
    }

    // Removes possible tokens (stableconins) to use
    // _whitelisted - list of stableconins to use
    //
    function removeWhitelistTokens(address[] memory _whitelisted)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _whitelisted.length; i++) {
            whitelist[_whitelisted[i]] = false;
        }
    }
}