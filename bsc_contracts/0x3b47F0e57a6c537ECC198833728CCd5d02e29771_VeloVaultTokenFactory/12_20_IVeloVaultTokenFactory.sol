pragma solidity >=0.5.0;

interface IVeloVaultTokenFactory {
    event VaultTokenCreated(
        address indexed pool,
        address vaultToken,
        uint256 vaultTokenIndex
    );

    function optiSwap() external view returns (address);

    function router() external view returns (address);

    function voter() external view returns (address);

    function pairFactory() external view returns (address);

    function rewardsToken() external view returns (address);

    function reinvestFeeTo() external view returns (address);

    function getVaultToken(address) external view returns (address);

    function allVaultTokens(uint256) external view returns (address);

    function allVaultTokensLength() external view returns (uint256);

    function createVaultToken(address _underlying)
        external
        returns (address vaultToken);
}