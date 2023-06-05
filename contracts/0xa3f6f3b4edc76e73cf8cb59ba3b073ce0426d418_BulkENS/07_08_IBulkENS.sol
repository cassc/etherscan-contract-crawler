// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/**
 * @title The interface of the BulkENS contract.
 * @notice it allows to register and renew multiple ENS domains at once and save on gas.
 */
interface IBulkENS {
    /**
     * @notice Commit multiple ENS names at once.
     * @param _commitments list of commitments for ETHRegistrarController
     *
     * @dev Commitments can be created with ETHRegistrarController or locally, with a shared secret.
     */
    function commit(bytes32[] calldata _commitments) external;

    /**
     * @notice Register multiple ENS names at once.
     * @param _names list of names to register
     * @param _owners list of owners for each name
     * @param _durations list of durations for each name, in seconds
     * @param _secrets list of secrets for each name
     * @param _prices list of name's total prices (base + premium) for duration provided
     *
     * @dev Prices and value sent can be calculated with `calculateRegisterPrice` to include fee.
     * A contract itself does not check a price for each name. If ENS oracle increases price,
     * the transaction may revert. If ENS oracle decreases price, exceeding value will be returned.
     * This is done to save gas.
     */
    function register(
        string[] calldata _names,
        address[] calldata _owners,
        uint256[] calldata _durations,
        bytes32[] calldata _secrets,
        uint256[] calldata _prices
    ) external payable;

    /**
     * @notice Returns prices to register ENS names.
     * @param _names list of names to register
     * @param _durations list of durations for each name, in seconds
     * @return _totalPrice total eth value to send on register
     * @return _prices list of prices for each name to pass on register
     * @return _fee extra fee user will pay on register, already included in _totalPrice
     *
     * @dev This method should be called on server or client to calculate
     * exact value to send on register. Exceed value will be returned but
     * will cost gas.
     */
    function calculateRegisterPrice(string[] calldata _names, uint256[] calldata _durations)
        external
        view
        returns (uint256 _totalPrice, uint256[] memory _prices, uint256 _fee);

    /**
     * @notice Register multiple ENS names at once with custom resolver and/or TTL.
     * @param _names list of names to register
     * @param _durations list of durations for each name, in seconds
     * @param _prices list of name's prices for duration provided
     *
     * @dev Prices and value sent can be calculated similar to `calculateRegisterPrice` using
     * `getRenewFee`, though must be calculated manually.
     */
    function renew(string[] calldata _names, uint256[] calldata _durations, uint256[] calldata _prices)
        external
        payable;

    /**
     * @notice Returns prices to renew ENS names.
     * @param _names list of names to renew
     * @param _durations list of durations for each name, in seconds
     * @return _totalPrice total eth value to send on register
     * @return _prices list of prices for each name to pass on register
     * @return _fee extra fee user will pay on renew, already included in _totalPrice
     *
     * @dev This method should be called on server or client to calculate
     * exact value to send on renew. Exceed value will be returned but
     * will cost gas.
     */
    function calculateRenewPrice(string[] calldata _names, uint256[] calldata _durations)
        external
        view
        returns (uint256 _totalPrice, uint256[] memory _prices, uint256 _fee);

    /**
     * @notice Set the contract's extra fee to register names.
     * @param _registerFee the fee to set in basis points (1/100th of a percent) between 0 and 10000
     *
     * @dev The fee is applied to the total rent paid for all names.
     */
    function setRegisterFee(uint256 _registerFee) external;

    /**
     * @notice Returns the current register fee.
     * @return the current register fee in basis points (1/100th of a percent)
     */
    function getRegisterFee() external view returns (uint256);

    /**
     * @notice Set the contract's extra fee to renew names.
     * @param _renewFee the fee to set in basis points (1/100th of a percent) between 0 and 10000
     *
     * @dev The fee is applied to the total rent paid for all names.
     */
    function setRenewFee(uint256 _renewFee) external;

    /**
     * @notice Returns the current renew fee.
     * @return the current renew fee in basis points (1/100th of a percent)
     */
    function getRenewFee() external view returns (uint256);

    /**
     * @notice Withdraw all ETH from the contract by owner.
     */
    function withdraw() external;

    /**
     * @notice Withdraw all tokens from the contract by owner.
     * @param _token the token to withdraw
     */
    function withdrawTokens(address _token) external;

    /**
     * @notice Returns the address of the ENS registry.
     * @return _ens address of the ENS registry
     */
    function getENSAddress() external view returns (address _ens);
}