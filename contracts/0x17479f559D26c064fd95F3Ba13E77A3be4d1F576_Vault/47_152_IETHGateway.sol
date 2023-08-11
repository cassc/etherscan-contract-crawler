// SPDX-License-Identifier:MIT
pragma solidity >=0.6.0 <=0.9.0;
pragma experimental ABIEncoderV2;

/**
 * @title Interface of ETH gateway for opty-fi  adapter
 * @author Opty.fi
 * @dev Inspired from Aave WETH gateway
 */
interface IETHGateway {
    /**
     * @dev deposits ETH into the reserve, using native ETH. A corresponding amount of the overlying asset
     *      is minted.
     * @param _vault address of the user who will receive the lpTokens representing the deposit
     * @param _liquidityPool address of the targeted lending pool
     * @param _liquidityPoolToken address of the targeted lpToken
     * @param _amounts list of amounts of coins.
     * @param _tokenIndex index of the coin to redeem
     **/
    function depositETH(
        address _vault,
        address _liquidityPool,
        address _liquidityPoolToken,
        uint256[2] memory _amounts,
        int128 _tokenIndex
    ) external;

    /**
     * @dev withdraws the ETH _reserves of vault.
     * @param _vault address that will receive WETH
     * @param _liquidityPool address of the targeted cToken pool
     * @param _liquidityPoolToken address of the targeted lpToken
     * @param _amount amount of lpToken to redeem
     * @param _tokenIndex index of the coin to redeem
     */
    function withdrawETH(
        address _vault,
        address _liquidityPool,
        address _liquidityPoolToken,
        uint256 _amount,
        int128 _tokenIndex
    ) external;

    /**
     * @dev transfer ERC20 from the utility contract, for ERC20 recovery in case of stuck tokens due
     * direct transfers to the contract address.
     * @param _token token to transfer
     * @param _to recipient of the transfer
     * @param _amount amount to send
     */
    function emergencyTokenTransfer(
        address _token,
        address _to,
        uint256 _amount
    ) external;

    /**
     * @dev transfer native Ether from the utility contract, for native Ether recovery in case of stuck Ether
     * due selfdestructs or transfer ether to pre-computated contract address before deployment.
     * @param _to recipient of the transfer
     * @param _amount amount to send
     */
    function emergencyEtherTransfer(address _to, uint256 _amount) external;

    /**
     * @dev Get WETH address used by WETHGateway
     */
    function getWETHAddress() external view returns (address);
}