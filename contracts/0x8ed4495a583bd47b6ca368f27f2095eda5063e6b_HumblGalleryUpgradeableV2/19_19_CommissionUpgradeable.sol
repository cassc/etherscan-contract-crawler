// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract CommissionUpgradeable {

    address private _commissionReceiver;
    mapping(address=>uint256) private _commissionBalance;
    uint96 private defaultCommission;

    function _setCommissionReceiver (address commissionReceiver ) internal virtual {
        _commissionReceiver = commissionReceiver;
    }
    function _getCommissionReceiver() internal view virtual returns(address) {
        return _commissionReceiver;
    }
    function _getCommission(uint256 _commissionPercentage, uint256 _salePrice) internal view virtual returns(address receiver,uint256 _commisionamount){
        receiver = _commissionReceiver;
        _commisionamount = (_salePrice * _commissionPercentage )/10000;
    }
    function _setCommissionBalance (address receiver,uint256 commissionAmount) internal virtual {
        _commissionBalance[receiver]+=commissionAmount;
    }
    function _getCommissionBalance (address receiver) internal view virtual returns(uint256){
        return _commissionBalance[receiver];
    }
    function _setDefaultCommission (uint96 _commission) internal virtual {
        defaultCommission= _commission;
    }
    function _getDefaultCommission () internal view virtual returns(uint96) {
        return defaultCommission;
    }
   
  
    
    

}