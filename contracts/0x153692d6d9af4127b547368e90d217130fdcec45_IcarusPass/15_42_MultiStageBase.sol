//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Base.sol";

contract MultiStageBase is Base
{
    function multiStageMint(uint256 amount_, bytes32[] calldata proof_, uint8 stage_)
        external
        payable
        onlyWhitelisted(stage_, msg.sender, proof_)
    {
        require(stage == stage_, "Current stage is not enabled");
        uint8 _stage = uint8(stage_);
        _increaseBalance(_stage, msg.sender, amount_);
        _callMint(msg.sender, amount_);
        _handlePayment(amount_ * price(_stage));
    }

    function publicMint(uint256 amount_)
        external
        payable
    {
        require(stage == 1, "Current stage is not enabled");
        _increaseBalance(1, msg.sender, amount_);
        _callMint(msg.sender, amount_);
        _handlePayment(amount_ * price(1));
    }
}