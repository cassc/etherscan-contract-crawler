//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;
import "../lib/ConsiderationEnums.sol";

/**
 * @title Ori Protocol NFT Token Factory
 * @author ysqi
 * @notice management License and Derivative NFT token.
 */
interface IOriFactory {
    event TokenEnabled(address token);
    event TokenDisabled(address token);
    event LicenseTokenDeployed(address originToken, address license);
    event DerivativeTokenDeployed(address originToken, address derivative);

    function requireRegistration(address token) external view returns (bool isLicense);

    function licenseToken(address originToken) external view returns (address);

    function derivativeToken(address originToken) external view returns (address);

    /**
     * @notice enable the given nft token.
     *
     * Emits an {TokenEnabled} event.
     *
     * Requirements:
     *
     * - The nft token `token` must been created by OriFactory.
     * - The `token` must be unenabled.
     * - Only the administrator can call it.
     *
     * @param token  is License or Derivative contract address.
     *
     */
    function enableToken(address token) external;

    /**
     * @notice disable the given nft token.
     *
     * Emits an {TokenDisabled} event.
     *
     * Requirements:
     *
     * - The `token` must be enabled.
     * - Only the administrator can call it.
     *
     * @param token  is License or Derivative contract address.
     *
     */
    function disableToken(address token) external;

    /**
     * @notice Create default license and derivative token contracts for the given NFT.
     * @dev Ori can deploy licenses and derivative contracts for every NFT contract.
     * Then each NFT's licens and derivatives will be stand-alone.
     * helping to analyz this NFT and makes the NFT managment structure clear and concise.
     *
     * Every one can call it to deploy license and derivative contracts for the given NFT.
     * but this created contracts is disabled, need the administrator to enable them.
     * them will be enabled immediately if the caller is an administrator.
     *
     * Emits a `LicenseTokenDeployed` and a `Derivative1155TokenDeployed` event.
     * And there are tow `TokenEnabled` events if the caller is an administrator.
     *
     *
     * Requirements:
     *
     * - The `originToken` must be NFT contract.
     * - Each NFT Token can only set one default license and derivative contract.
     *
     * @param originToken is the NFT contract.
     *
     */
    function createOrignPair(address originToken) external;

    /**
     * @notice Create a empty derivative NFT contract
     * @dev Allow every one to call it to create derivative NFT contract.
     * Only then can Ori whitelist it. and this new contract will be enabled immediately.
     *
     * Emits a `Derivative1155TokenDeployed` event. the event parameter `originToken` is zero.
     * And there are a `TokenEnabled` event if the caller is an administrator.
     */
    function deployDerivative721(string memory dName, string memory dSymbol) external returns (address token);

    function deployDerivative1155() external returns (address token);
}