// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Booster.sol";
import "../piglet/IPigletz.sol";

import "../oracle/IOracle.sol";
import "@chainlink/contracts/src/v0.8/Denominations.sol";

contract InvestMultiTokensBooster is Booster {
    IOracle private _oracle;
    uint256 private _numTokens;
    address _pifiToken;

    constructor(
        IPigletz pigletz,
        IOracle oracle,
        address pifi,
        uint256 boost,
        uint256 numTokens,
        uint256 level
    ) Booster(pigletz, boost, level) {
        _pigletz = pigletz;
        _oracle = oracle;
        _numTokens = numTokens;
        _pifiToken = pifi;
    }

    function getName() external view virtual override returns (string memory) {
        return "Invest Multiple Tokens";
    }

    function getRequirements()
        external
        view
        virtual
        override
        returns (string memory description, uint256[] memory values)
    {
        values = new uint256[](1);
        values[0] = _numTokens;
        return ("Invest ${0} different tokens", values);
    }

    function _isListed(address token) internal view returns (bool) {
        return _oracle.getTokenUSDPrice(token, 1 ether) > 0;
    }

    function isReady(uint256 tokenId) public view virtual override returns (bool) {
        IPigletWallet wallet = IPigletz(_pigletz).getWallet(tokenId);

        require(address(wallet) != address(0), "Token does not exist");
        IPigletWallet.TokenData[] memory tokens = wallet.listTokens();

        uint256 count = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (_isListed(tokens[i].token) && tokens[i].token != _pifiToken) count++;
        }
        if (address(wallet).balance > 0) count++;
        return count >= _numTokens && !isLocked(tokenId);
    }
}