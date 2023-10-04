// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Errors} from "../Errors.sol";
import {TestnetToken} from "./TestnetToken.sol";

contract TestnetTokenWithTransferFee is TestnetToken {
    uint256 public feeRate;
    uint256 public constant FEE_PARTS = 1000000;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 __decimals,
        uint256 initialMint,
        uint256 _mintCoolDownPeriod,
        uint256 _mintAmountPerCoolDownPeriod
    )
        TestnetToken(
            _name,
            _symbol,
            __decimals,
            initialMint,
            _mintCoolDownPeriod,
            _mintAmountPerCoolDownPeriod
        )
    {
        // set initially to 2bps
        feeRate = 200;
    }

    function setFeeRate(uint256 newFeeRate) external onlyOwner {
        if (newFeeRate == feeRate) {
            revert("Already set!");
        }
        if (newFeeRate >= FEE_PARTS) {
            revert("Fee rate exceeds fee parts!");
        }
        feeRate = newFeeRate;
    }

    function getFeeFor(uint256 value) public view returns (uint256) {
        uint256 currFeeRate = feeRate;
        if (currFeeRate == 0) {
            return 0;
        }
        return (value * currFeeRate) / FEE_PARTS;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal override {
        uint256 _fee = getFeeFor(_value);
        uint256 _principle = _value - _fee;
        super._transfer(_from, owner(), _fee);
        super._transfer(_from, _to, _principle);
    }
}