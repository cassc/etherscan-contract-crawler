// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../../../oz/token/ERC20/ERC20.sol";
import "./BaseOFTV2.sol";

contract OFTV2 is BaseOFTV2, ERC20 {

    error OFTSharedDecimalsMustBeLessThanOrEqualToDecimals(uint8 sharedDecimals, uint8 decimals);

    uint internal immutable ld2sdRate;

    constructor(string memory _name, string memory _symbol, uint8 _sharedDecimals) ERC20(_name, _symbol) BaseOFTV2(_sharedDecimals) {
        uint8 decimals = decimals();
        if (_sharedDecimals > decimals) {
            revert OFTSharedDecimalsMustBeLessThanOrEqualToDecimals(_sharedDecimals, decimals);
        }
        ld2sdRate = 10 ** (decimals - _sharedDecimals);
    }

    function __OFTV2_init(address _lzEndpoint) internal {
       __BaseOFTV2_init(_lzEndpoint);
    }

    /************************************************************************
    * public functions
    ************************************************************************/
    function circulatingSupply() public view virtual override returns (uint) {
        return totalSupply();
    }

    function token() public view virtual override returns (address) {
        return address(this);
    }

    /************************************************************************
    * internal functions
    ************************************************************************/
    function _debitFrom(address _from, uint16, bytes32, uint _amount) internal virtual override returns (uint) {
        address spender = _msgSender();
        if (_from != spender) _spendAllowance(_from, spender, _amount);
        _burn(_from, _amount);
        return _amount;
    }

    function _creditTo(uint16, address _toAddress, uint _amount) internal virtual override returns (uint) {
        _mint(_toAddress, _amount);
        return _amount;
    }

    function _transferFrom(address _from, address _to, uint _amount) internal virtual override returns (uint) {
        address spender = _msgSender();
        // if transfer from this contract, no need to check allowance
        if (_from != address(this) && _from != spender) _spendAllowance(_from, spender, _amount);
        _transfer(_from, _to, _amount);
        return _amount;
    }

    function _ld2sdRate() internal view virtual override returns (uint) {
        return ld2sdRate;
    }
}