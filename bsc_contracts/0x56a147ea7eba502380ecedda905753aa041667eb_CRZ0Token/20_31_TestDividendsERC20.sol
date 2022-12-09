// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "../modules/tokens/TokenTransfer.sol";
import "../modules/tokens/dividends/DividendsERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";

contract TestDividendsERC20 is TokenTransfer, DividendsERC20 {
    /**
     * @dev Transfer Dividends
     */
    constructor(
        address _owner,
        uint256 _totalTokens,
        string memory _tokenName,
        string memory _tokenSymbol,
        address _dividendsToken
    )
        public
        TokenTransfer(_owner, _totalTokens, _tokenName, _tokenSymbol)
        DividendsERC20(_dividendsToken)
    {}
}