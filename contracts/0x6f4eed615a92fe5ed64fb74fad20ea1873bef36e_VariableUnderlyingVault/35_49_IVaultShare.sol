// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IVaultShare {
    /**
     * @dev mint option token to an address. Can only be called by corresponding vault
     * @param _recipient    where to mint token to
     * @param _amount       amount to mint
     *
     */
    function mint(address _recipient, uint256 _amount) external;

    /**
     * @dev burn option token from an address. Can only be called by corresponding vault
     * @param _from         account to burn from
     * @param _amount       amount to burn
     *
     */
    function burn(address _from, uint256 _amount) external;

    /**
     * @dev burn option token from addresses. Can only be called by corresponding vault
     * @param _froms        accounts to burn from
     * @param _amounts      amounts to burn
     *
     */
    function batchBurn(address[] memory _froms, uint256[] memory _amounts) external;

    /**
     * @dev returns total supply of a vault
     * @param _vault      address of the vault
     *
     */
    function totalSupply(address _vault) external view returns (uint256 amount);

    /**
     * @dev returns vault share balance for a given holder
     * @param _owner      address of token holder
     * @param _vault      address of the vault
     *
     */
    function getBalanceOf(address _owner, address _vault) external view returns (uint256 amount);

    /**
     * @dev exposing transfer method to vault
     *
     */
    function transferVaultOnly(address _from, address _to, uint256 _amount, bytes calldata _data) external;

    /**
     * @dev helper metod to pass in vault address instead of tokenId
     *
     */
    function transferFromWithVault(address _from, address _to, address _vault, uint256 _amount, bytes calldata _data) external;
}