pragma solidity 0.8.6;

import "./utils/TimeLockedERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract sePSP is ERC20Votes, TimeLockedERC20 {
    string constant NAME = "Social Escrowed PSP";
    string constant SYMBOL = "sePSP1";

    constructor(
        IERC20 _asset,
        uint256 _timeLockBlocks,
        uint256 _minTimeLockBlocks,
        uint256 _maxTimeLockBlocks
    ) TimeLockedERC20(NAME, SYMBOL, _asset, _timeLockBlocks, _minTimeLockBlocks, _maxTimeLockBlocks) {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
}