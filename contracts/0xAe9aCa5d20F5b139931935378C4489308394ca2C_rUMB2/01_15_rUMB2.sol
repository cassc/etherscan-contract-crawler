//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./interfaces/rUMBV2.sol";
import "./interfaces/Blacklisted.sol";
import "./interfaces/OnDemandTokenBridgable.sol";

contract rUMB2 is Blacklisted, rUMBV2, OnDemandTokenBridgable {
     constructor (
        address _owner,
        uint256 _maxAllowedTotalSupply,
        uint32 _swapStartsOn,
        uint32 _dailyCup,
        string memory _name,
        string memory _symbol,
        address _umb
    ) rUMBV2(_owner, _maxAllowedTotalSupply, _swapStartsOn, _dailyCup, _name, _symbol, _umb) {}

    function mint(address _holder, uint256 _amount)
        external
        override(MintableToken, OnDemandToken)
        onlyOwnerOrMinter()
        assertMaxSupply(_amount)
    {
        require(_amount != 0, "zero amount");

        _mint(_holder, _amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(Blacklisted, OnDemandTokenBridgable, ERC20)
    {
        Blacklisted._beforeTokenTransfer(from, to, amount);
        OnDemandTokenBridgable._beforeTokenTransfer(from, to, amount);
    }
}