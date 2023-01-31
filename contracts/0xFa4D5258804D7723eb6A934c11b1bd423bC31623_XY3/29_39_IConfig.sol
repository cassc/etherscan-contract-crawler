// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;
import {IAddressProvider} from "./IAddressProvider.sol";

interface IConfig {
    /**
     * @notice This event is emitted when admin fee percent changed.
     * @param  newAdminFee - The new admin fee measured in basis points.
     */
    event AdminFeeUpdated(uint16 newAdminFee);

    /**
     * @notice This event is emitted when the max duration of all borrows.
     * @param  newMaxBorrowDuration - The new max duration in seconds.
     */
    event MaxBorrowDurationUpdated(uint256 newMaxBorrowDuration);

    /**
     * @notice This event is emitted when the min duration of all borrows.
     * @param  newMinBorrowDuration - The new min duration.
     */
    event MinBorrowDurationUpdated(uint256 newMinBorrowDuration);

    /**
     * @notice This event is emitted when the ERC20 permit is set.
     * @param erc20Contract - Address of the ERC20 token.
     * @param isPermitted - ERC20 permit bool value.
     */
    event ERC20Permit(address indexed erc20Contract, bool isPermitted);

    /**
     * @notice This event is emitted when the ERC721 permit is set.
     * @param erc721Contract - Address of the ERC721 collection address.
     * @param isPermitted - ERC721 permit bool value.
     */
    event ERC721Permit(address indexed erc721Contract, bool isPermitted);

    /**
     * @notice This event is emitted when the agent permit is set.
     * @param agent - Address of the agent.
     * @param isPermitted - Agent permit bool value.
     */
    event AgentPermit(address indexed agent, bytes4 selector, bool isPermitted);

    /**
     * @notice This event is emitted when the ERC20 approved to user.
     * @param user - User account.
     * @param erc20Contract - Address of the ERC20 token.
     * @param amount - ERC20 amount.
     */
    event ERC20Approve(address indexed user, address indexed erc20Contract, uint256 amount);

    /**
     * @notice This event is emitted when the ERC721 permit is set.
     * @param user - User account.
     * @param erc721Contract - Address of the ERC721 collection address.
     * @param isPermitted - ERC721 permit bool value.
     */
    event ERC721Approve(address indexed user, address indexed erc721Contract, bool isPermitted);

    /**
     * @notice This event is emitted when the admin fee receiver address is changed.
     */
    event AdminFeeReceiverUpdated(address);

    /**
     * @notice Get the current max allowed borrow duration.
     */
    function maxBorrowDuration() external view returns (uint256);

    /**
     * @notice Get the current min allowed borrow duration.
     */
    function minBorrowDuration() external view returns (uint256);

    /**
     * @notice Get percent of admin fee charged from lender earned.
     */
    function adminShare() external view returns (uint16);

    /**
     * @notice Update max borrow duration
     * @param  _newMaxBorrowDuration - The new max duration.
     */
    function updateMaxBorrowDuration(uint256 _newMaxBorrowDuration)
        external;

    /**
     * @notice Update min borrow duration
     * @param  _newMinBorrowDuration - The new min duration.
     */
    function updateMinBorrowDuration(uint256 _newMinBorrowDuration)
        external;

    /**
     * @notice Update admin fee.
     * @param  _newAdminShare - The new admin fee.
     */
    function updateAdminShare(uint16 _newAdminShare) external;

    /**
     * @notice Update admin fee receiver.
     * @param _newAdminFeeReceiver - The new admin fee receiver address.
     */
    function updateAdminFeeReceiver(address _newAdminFeeReceiver) external;

    /**
     * @notice Get the erc20 token permitted status.
     * @param _erc20 - The address of the ERC20 token.
     * @return The ERC20 permit boolean value
     */
    function getERC20Permit(address _erc20) external view returns (bool);

    /**
     * @notice Get the erc721 token permitted status.
     * @param _erc721 - The address of the ERC721 collection.
     * @return The ERC721 collection permit boolean value
     */
    function getERC721Permit(address _erc721) external view returns (bool);

    /**
     * @dev Get the permit of agent, public reading.
     * @param _agent - The address of the agent.
     * @return The agent permit boolean value
     */
    function getAgentPermit(address _agent, bytes4 _selector) external view returns (bool);

    /**
     * @notice Update a set of the ERC20 tokens permitted status.
     * @param _erc20s - The addresses of the ERC20 currencies.
     * @param _permits - The new statuses of the currencies.
     */
    function setERC20Permits(address[] memory _erc20s, bool[] memory _permits)
        external;

    /**
     * @notice Update a set of the ERC721 collection permitted status.
     * @param _erc721s - The addresses of the ERC721 collection.
     * @param _permits - The new statuses of the collection.
     */
    function setERC721Permits(address[] memory _erc721s, bool[] memory _permits)
        external;

    function setAgentPermits(address[] memory _agents, bytes4[] memory _selectors, bool[] memory _permits)
        external;

    function getAddressProvider() external view returns (IAddressProvider);
}