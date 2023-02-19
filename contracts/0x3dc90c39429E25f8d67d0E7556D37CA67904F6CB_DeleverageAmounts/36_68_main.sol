//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "../common/helpers.sol";

contract ReadModule is Helpers {

    function isRebalancer(address accountAddr_) public view returns (bool) {
        return _isRebalancer[accountAddr_];
    }

    function token() public view returns (address) {
        return address(_token);
    }

    /**
     * @dev function to read decimals of itokens
     */
    function decimals() public view override returns (uint8) {
        return _tokenDecimals;
    }

    function tokenMinLimit() public view returns (uint256) {
        return _tokenMinLimit;
    }

    function atoken() public view returns (address) {
        return address(_atoken);
    }

    function vaultDsa() public view returns (address) {
        return address(_vaultDsa);
    }

    function ratios() public view returns (Ratios memory) {
        return _ratios;
    }

    function lastRevenueExchangePrice() public view returns (uint256) {
        return _lastRevenueExchangePrice;
    }

    function revenueFee() public view returns (uint256) {
        return _revenueFee;
    }

    function revenue() public view returns (uint256) {
        return _revenue;
    }

    function revenueEth() public view returns (uint256) {
        return _revenueEth;
    }

    function withdrawalFee() public view returns (uint256) {
        return _withdrawalFee;
    }

    function idealExcessAmt() public view returns (uint256) {
        return _idealExcessAmt;
    }

    function swapFee() public view returns (uint256) {
        return _swapFee;
    }
    
    function saveSlippage() public view returns (uint256) {
        return _saveSlippage;
    }

    function deleverageFee() public view returns (uint256) {
        return _deleverageFee;
    }
}