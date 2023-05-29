// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "./interfaces/IOneExFee.sol";

abstract contract OneExFee is IOneExFee {
    /// @inheritdoc IOneExFee
    address public override oneExFeeCollector;
    /// @inheritdoc IOneExFee
    uint8 public override oneExFeePercent;

    constructor(address _oneExFeeCollector, uint8 _oneExFeePercent) {
        require(_oneExFeePercent <= 100, "InvalidPercent");

        oneExFeeCollector = _oneExFeeCollector;
        oneExFeePercent = _oneExFeePercent;
    }

    /// @inheritdoc IOneExFee
    function setOneExFeePercent(uint8 _oneExFeePercent) external override {
        require(msg.sender == oneExFeeCollector, "NotAllowed");
        require(_oneExFeePercent <= 100, "InvalidPercent");

        oneExFeePercent = _oneExFeePercent;

        emit NewOneExFeePercent(oneExFeePercent);
    }

    /// @inheritdoc IOneExFee
    function setOneExFeeCollector(address _oneExFeeCollector) external override {
        require(msg.sender == oneExFeeCollector, "NotAllowed");

        oneExFeeCollector = _oneExFeeCollector;

        emit NewOneExFeeCollector(oneExFeeCollector);
    }
}