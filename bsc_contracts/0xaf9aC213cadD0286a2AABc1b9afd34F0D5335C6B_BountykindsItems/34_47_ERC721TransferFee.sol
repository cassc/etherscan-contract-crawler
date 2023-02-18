// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { BusinessAddresses } from "./BusinessAddresses.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { CurrencyTransferLib } from "../libraries/CurrencyTransferLib.sol";

abstract contract ERC721TransferFee is BusinessAddresses, ERC721Upgradeable {
    event SetFeeTransfer(address token, address beneficiary, uint256 amount);

    uint256 internal _feeAmount;
    address internal _feeToken;
    address internal _feeBeneficiary;

    function getTransferFee() external view returns (address, address, uint256) {
        return (_feeToken, _feeBeneficiary, _feeAmount);
    }

    function _setTransferFee(address token_, address beneficiary_, uint256 amount_) internal {
        _feeToken = token_;
        _feeBeneficiary = beneficiary_;
        _feeAmount = amount_;

        emit SetFeeTransfer(token_, beneficiary_, amount_);
    }

    function _beforeTokenTransfer(address from_, address to_, uint256 tokenId_, uint256 batchSize_) internal virtual override {
        if ((from_ != address(0) && to_ != address(0)) && !_inBusinessList(msg.sender) && _feeAmount > 0) {
            CurrencyTransferLib.safeTransferERC20(_feeToken, from_, _feeBeneficiary, _feeAmount);
        }
        super._beforeTokenTransfer(from_, to_, tokenId_, batchSize_);
    }

    uint256[47] private __gap;
}