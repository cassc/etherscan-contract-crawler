// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Booster.sol";
import "../piglet/IPigletz.sol";

contract InvestTokensBooster is Booster {
    uint256 internal _amount;

    constructor(
        IPigletz pigletz,
        uint256 boost,
        uint256 amount,
        uint256 level
    ) Booster(pigletz, boost, level) {
        _pigletz = pigletz;
        _amount = amount;
    }

    function getName() external view virtual override returns (string memory) {
        return "Invest Tokens";
    }

    function getRequirements()
        external
        view
        virtual
        override
        returns (string memory description, uint256[] memory values)
    {
        values = new uint256[](1);
        values[0] = _amount;
        return ("Invest tokens with value of at least $${0} USD", values);
    }

    function isReady(uint256 tokenId) public view virtual override returns (bool) {
        IPigletWallet wallet = IPigletz(_pigletz).getWallet(tokenId);

        require(address(wallet) != address(0), "Token does not exist");

        return wallet.getBalanceInUSD() >= _amount && !isLocked(tokenId);
    }
}