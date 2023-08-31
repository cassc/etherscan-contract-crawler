// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IFlatCoin is IERC20 {
    /**
     * @dev Emitted when issuer role been set to 'newIssuer' address
     */
    event IssuerUpdated(address newIssuer);

    /**
     * @dev Emitted when operator role been set to 'newOperator' address
     */
    event OperatorUpdated(address newOperator);

    /**
     * @dev Emitted when emergency role been set to 'newEmergency' address
     */
    event EmergencyUpdated(address newEmergency);

    /**
     * @dev Emitted when min distribution interval updated to 'newInterval'
     */
    event MinDistributionIntervalUpdated(uint64 newInterval);

    /**
     * @dev Emitted when max distribution ratio updated to 'newRatio'
     */
    event MaxDistributionRatioUpdated(uint64 newRatio);

    /**
     * @dev Emitted when 'account' added to black list
     */
    event BlackListAdded(address account);

    /**
     * @dev Emitted when 'account' removed to black list
     */
    event BlackListRemoved(address account);

    /**
     * @dev Emitted when distribute interest
     *
     * Note that `interest` may be minus value.
     */
    event InterestsDistributed(
        int256 interest,
        uint256 newTotalSupply,
        uint256 interestFromTime,
        uint256 interestToTime
    );

    /**
     * @return the amount of shares that corresponds to `amount` of token.
     */
    function getSharesByAmount(uint256 amount) external view returns (uint256);

    /**
     * @return the amount of token that corresponds to `sharesAmount` token shares.
     */
    function getAmountByShares(
        uint256 sharesAmount
    ) external view returns (uint256);

    /**
     * @return the amount of shares belongs to _account.
     */
    function sharesOf(address _account) external view returns (uint256);

    /**
     * @dev Distribute interest for the token owner. only operator role can call this function
     */
    function distributeInterests(
        int256 _distributedInterest,
        uint interestFromTime,
        uint interestToTime
    ) external;

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply. Only issuer role can call this function.
     */
    function mint(address account, uint256 amount) external;
}