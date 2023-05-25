// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface L1StandardBridge {
    /**
     * @dev Performs the logic for deposits by storing the ETH and informing the L2 ETH Gateway of
     * the deposit.
     * @param _to Account to give the deposit to on L2.
     * @param _l2Gas Gas limit required to complete the deposit on L2.
     * @param _data Optional data to forward to L2. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function depositETHTo(
        address _to,
        uint32 _l2Gas,
        bytes calldata _data
    ) external payable;

    /**
     * @dev deposit an amount of ERC20 to a recipient's balance on L2.
     * @param _l1Token Address of the L1 ERC20 we are depositing
     * @param _l2Token Address of the L1 respective L2 ERC20
     * @param _to L2 address to credit the withdrawal to.
     * @param _amount Amount of the ERC20 to deposit.
     * @param _l2Gas Gas limit required to complete the deposit on L2.
     * @param _data Optional data to forward to L2. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function depositERC20To(
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount,
        uint32 _l2Gas,
        bytes calldata _data
    ) external;
}

interface OldL1TokenGateway {
    /**
     * @dev Transfer SNX to L2 First, moves the SNX into the deposit escrow
     *
     * @param _to Account to give the deposit to on L2
     * @param _amount Amount of the ERC20 to deposit.
     */
    function depositTo(address _to, uint256 _amount) external;

    /**
     * @dev Transfer SNX to L2 First, moves the SNX into the deposit escrow
     *
     * @param currencyKey currencyKey for the SynthToken
     * @param destination Account to give the deposit to on L2
     * @param amount Amount of the ERC20 to deposit.
     */
    function initiateSynthTransfer(
        bytes32 currencyKey,
        address destination,
        uint256 amount
    ) external;
}