//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝


pragma solidity 0.8.16;
//SPDX-License-Identifier: MIT

interface IDullahanPodManager {

    function mintFeeRatio() external view returns(uint256);

    function podOwedFees(address pod) external view returns(uint256);

    function updatePodState(address pod) external returns(bool);

    function getStkAave(uint256 amountToMint) external returns(bool);
    function freeStkAave(address pod) external returns(bool);

    function notifyStkAaveClaim(uint256 claimedAmount) external;
    function notifyPayFee(uint256 feeAmount) external;
    function notifyMintingFee(uint256 feeAmount) external;

}