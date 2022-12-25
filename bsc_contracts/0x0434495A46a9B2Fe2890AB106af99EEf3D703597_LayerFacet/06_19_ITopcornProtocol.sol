/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity =0.8.17;

interface ITopcornProtocol {
    struct AddLiquidity {
        uint256 topcornAmount;
        uint256 minTopcornAmount;
        uint256 minBNBAmount;
    }

    function addAndDepositLP(
        uint256 lp,
        uint256 buyTopcornAmount,
        uint256 buyBNBAmount,
        AddLiquidity calldata al
    ) external payable;

    function withdrawLP(uint32[] calldata crates, uint256[] calldata amounts) external;

    function lpDeposit(address account, uint32 id) external view returns (uint256, uint256);

    function claimLP(uint32[] calldata withdrawals) external;

    function withdrawTopcorns(uint32[] calldata crates, uint256[] calldata amounts) external;

    function season() external view returns (uint32);

    function claimTopcorns(uint32[] calldata withdrawals) external;

    function updateSilo(address account) external payable;

    function topcornDeposit(address account, uint32 id) external view returns (uint256);

    function convertDepositedTopcorns(
        uint256 topcorns,
        uint256 minLP,
        uint32[] memory crates,
        uint256[] memory amounts
    ) external;

    function withdrawSeasons() external view returns (uint8);

    function claimBnb() external;

    function balanceOfBNB(address account) external view returns (uint256);

    function siloSunrise(uint256 amount) external;

    function siloSunrises(uint256 number) external;

    function balanceOfFarmableTopcorns(address account) external view returns (uint256 topcorns);

    function lpWithdrawal(address account, uint32 i) external view returns (uint256);
}