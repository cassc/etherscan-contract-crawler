// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./fee/BaseOFTWithFee.sol";
import "./IGravitaDebtToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ProxyOFTV2 is BaseOFTWithFee {
    using SafeERC20 for IGravitaDebtToken;
    IGravitaDebtToken internal immutable innerToken;
    uint internal immutable ld2sdRate;

    constructor(address _token, address _lzEndpoint) BaseOFTWithFee(_lzEndpoint) {
        require(_token != address(0) && _lzEndpoint != address(0), "Invalid address");
        innerToken = IGravitaDebtToken(_token);
        ld2sdRate = 10 ** (18 - sharedDecimals);
    }

    /************************************************************************
     * public functions
     ************************************************************************/
    function circulatingSupply() public view virtual override returns (uint) {
        return innerToken.totalSupply(); // since we are burning the bridged tokens, there's no need to adjust the supply
    }

    function token() public view virtual override returns (address) {
        return address(innerToken);
    }

    /************************************************************************
     * internal functions
     ************************************************************************/
    function _debitFrom(address _from, uint16, bytes32, uint _amount) internal virtual override returns (uint) {
        require(_from == _msgSender(), "ProxyOFT: owner is not send caller");

        _amount = _transferFrom(_from, address(this), _amount);

        innerToken.burnFromWhitelistedContract(_amount);

        return _amount;
    }

    function _creditTo(uint16, address _toAddress, uint _amount) internal virtual override returns (uint) {
        innerToken.mintFromWhitelistedContract(_amount);
        if (_toAddress == address(this)) {
            return _amount;
        }
        return _transferFrom(address(this), _toAddress, _amount);
    }

    function _transferFrom(address _from, address _to, uint _amount) internal virtual override returns (uint) {
        uint before = innerToken.balanceOf(_to);
        if (_from == address(this)) {
            innerToken.safeTransfer(_to, _amount);
        } else {
            innerToken.safeTransferFrom(_from, _to, _amount);
        }
        return innerToken.balanceOf(_to) - before;
    }

    function _ld2sdRate() internal view virtual override returns (uint) {
        return ld2sdRate;
    }
}