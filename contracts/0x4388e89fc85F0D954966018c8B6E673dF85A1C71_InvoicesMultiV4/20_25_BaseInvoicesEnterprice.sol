// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./BaseProxy.sol";

abstract contract BaseInvoicesEnterprice is BaseProxy {
    using SafeMath for uint256;

    uint16 public feeEnterprice;

    mapping(address => bool) public whitelist;
    mapping(uint256 => address) public invoiceCreator;

    function verifyWL(address _seller) external view virtual returns (bool) {
        return whitelist[_seller];
    }

    function getweiAmount(
        uint256 _amount,
        uint16 _fee,
        address _payer,
        uint256 _feeConst
    ) internal view virtual returns (uint256, uint256) {
        if (this.verifyWL(_payer) && feeEnterprice > 0) {
            uint256 _main = 10000;
            uint256 _feeWL = _amount.mul(feeEnterprice).div(_main);
            return (_amount.sub(_feeWL), _feeWL);
        }

        if (_fee > 0) {
            uint256 main = 10000;
            uint256 weiAmount = _amount.mul(main.sub(_fee)).div(main);
            return (weiAmount, _amount.sub(weiAmount));
        } else {
            return (_amount.sub(_feeConst), _feeConst);
        }
    }

    /**
     * @notice Add addresses to WhiteList
     * @dev Only for owner
     * @param _users Array of addresses
     */
    function addToWhitelist(address[] calldata _users) external onlyOwner {
        for (uint i = 0; i < _users.length; i++) {
            if (!whitelist[_users[i]]) whitelist[_users[i]] = true;
        }
    }

    /**
     * @notice Remove addresses from WhiteList
     * @dev Only for owner
     * @param _users Array of addresses
     */
    function removeFromWhitelist(address[] calldata _users) external onlyOwner {
        for (uint i = 0; i < _users.length; i++) {
            if (whitelist[_users[i]]) whitelist[_users[i]] = false;
        }
    }

    /**
     * @notice Set fee by Enterprise payer
     * @dev Only for owner
     * @param _feeEnterprice Number 0 .. 10000. Mean 1 - to Treasury 0.01%
     */
    function set_feeEnterprice(uint16 _feeEnterprice) external onlyOwner {
        feeEnterprice = _feeEnterprice;
    }
}