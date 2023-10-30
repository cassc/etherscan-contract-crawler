pragma solidity 0.5.16;

interface IController {
    function whiteList(address _target) external view returns (bool);

    function addVaultAndStrategy(address _vault, address _strategy) external;

    function forceUnleashed(address _vault) external;

    function hasVault(address _vault) external returns (bool);

    function salvage(address _token, uint256 amount) external;

    function salvageStrategy(
        address _strategy,
        address _token,
        uint256 amount
    ) external;

    function notifyFee(address _underlying, uint256 fee) external;

    function profitSharingNumerator() external view returns (uint256);

    function profitSharingDenominator() external view returns (uint256);

    function treasury() external view returns (address);
}