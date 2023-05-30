//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface ISaleV3 {
    function getMinStakedAmount() external view returns (uint256 amount);

    function getMarkupFee() external view returns (uint96 fee);

    function getParticipantDetails(address participant)
        external
        view
        returns (
            uint256 vipSpendAmount,
            uint256 privateSpendAmount,
            uint256 publicSpendAmount,
            uint256 vipBuyAmount,
            uint256 privateBuyAmount,
            uint256 publicBuyAmount,
            bool participantMarkup
        );
}