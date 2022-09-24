// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

interface IVaultSponsoring {
    //
    // Events
    //

    /// Emitted when a new sponsor deposit is created
    event Sponsored(
        uint256 indexed id,
        uint256 amount,
        address indexed depositor,
        uint256 lockedUntil
    );

    /// Emitted when an existing sponsor withdraws
    event Unsponsored(
        uint256 indexed id,
        uint256 amount,
        address indexed to,
        bool burned
    );

    /**
     * Total amount currently sponsored
     */
    function totalSponsored() external view returns (uint256);

    /**
     * Creates a sponsored deposit with the amount provided in @param _amount.
     * Sponsored amounts will be invested like deposits, but unlike deposits
     * there are no claimers and the yield generated is donated to the vault.
     * The amount is locked until the timestamp specified in @param _lockedUntil.
     *
     * @param _inputToken The input token to deposit.
     * @param _amount Amount to sponsor.
     * @param _lockedUntil When the sponsor can unsponsor the amount.
     */
    function sponsor(
        address _inputToken,
        uint256 _amount,
        uint256 _lockedUntil,
        uint256 _slippage
    ) external;

    /**
     * Withdraws the sponsored amount for the deposits with the ids provided
     * in @param _ids and sends it to @param _to.
     *
     * It fails if the vault is underperforming and there are not enough funds
     * to withdraw the sponsored amount.
     *
     * @param _to Address that will receive the funds.
     * @param _ids Array with the ids of the deposits.
     */
    function unsponsor(address _to, uint256[] calldata _ids) external;

    /**
     * Withdraws the specified sponsored amounts @param _amounts for the deposits with the ids provided
     * in @param _ids and sends it to @param _to.
     *
     * @notice fails if there are not enough funds to withdraw the specified amounts.
     *
     * @param _to Address that will receive the funds.
     * @param _ids Array with the ids of the deposits.
     * @param _amounts Array with the amounts to withdraw.
     */
    function partialUnsponsor(
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external;
}