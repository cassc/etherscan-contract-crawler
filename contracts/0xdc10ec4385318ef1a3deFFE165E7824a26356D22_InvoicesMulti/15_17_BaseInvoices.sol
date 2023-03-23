// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./BaseProxy.sol";

abstract contract BaseInvoices is BaseProxy {
    using SafeMath for uint256;
    uint256 public feeConst;

    /**
     * @notice Emitted when fee was send to treasure
     * @param invoice_id Identifier of invoice. Indexed
     * @param _amount Address of payer
     * @param created Date of created
     */
    event deductions(
        uint256 indexed invoice_id,
        uint256 _amount,
        uint256 created
    );

    function getweiAmount(uint256 _amount, uint16 _fee)
        internal
        view
        virtual
        returns (uint256, uint256)
    {
        if (_fee > 0) {
            uint256 main = 10000;
            uint256 weiAmount = _amount.mul(main.sub(_fee)).div(main);
            return (weiAmount, _amount.sub(weiAmount));
        } else {
            return (_amount.sub(feeConst), feeConst);
        }
    }

    /**
     * @notice Set fee by USDT const
     * @dev Only for owner
     * @param _feeConst wei USDT
     */
    function set_feeConst(uint256 _feeConst) external virtual onlyOwner {
        feeConst = _feeConst;
    }
}