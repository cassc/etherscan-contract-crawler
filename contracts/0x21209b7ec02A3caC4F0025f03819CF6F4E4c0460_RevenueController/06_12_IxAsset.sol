pragma solidity ^0.8.0;

interface IxAsset {
    function withdrawFees() external;

    function transferOwnership(address newOwner) external;

    function getWithdrawableFees() external view returns (address[2] memory, uint256[2] memory);
}

interface ILMTerminal {
    function withdrawFees(address token) external;
}

interface IxINCH is IxAsset {
    function withdrawableOneInchFees() external view returns (uint256);
}

interface IxAAVE is IxAsset {
    function withdrawableAaveFees() external view returns (uint256);
}

interface IxSNX is IxAsset {
    function withdrawableEthFees() external view returns (uint256);
    function withdrawableSusdFees() external view returns (uint256);
}

interface IxU3LP is IxAsset {
    function withdrawableToken0Fees() external view returns (uint256);
    function withdrawableToken1Fees() external view returns (uint256);
}