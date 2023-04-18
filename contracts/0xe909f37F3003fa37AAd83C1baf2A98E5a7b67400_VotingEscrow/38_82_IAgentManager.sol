// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

interface IAgentManager {
    /**
     * @dev Emitted when grant agent data
     */
    event AgentGranted(
        address indexed account,
        uint256 credit,
        uint256 effectiveBlock,
        uint256 expirationBlock,
        bool minable,
        bool burnable,
        address sender
    );
    /**
     * @dev Emitted when revoked agent role
     */
    event AgentRevoked(address indexed account, address sender);

    /**
     * @dev Emitted when increase agent credit
     */
    event AgentIncreaseCredit(address indexed account, uint256 credit, address sender);

    /**
     * @dev Emitted when decrease agent credit
     */
    event AgentDecreaseCredit(address indexed account, uint256 credit, address sender);

    /**
     * @dev Emitted when change agent effective block number
     */
    event AgentChangeEffectiveBlock(address indexed account, uint256 effectiveBlock, address sender);

    /**
     * @dev Emitted when change agent expiration block number
     */
    event AgentChangeExpirationBlock(address indexed account, uint256 expirationBlock, address sender);

    /**
     * @dev Emitted when switch agent minable
     */
    event AgentSwitchMinable(address indexed account, bool minable, address sender);

    /**
     * @dev Emitted when switch agent burnable
     */
    event AgentSwitchBurnable(address indexed account, bool burnable, address sender);

    /**
     * @dev Return agent max credit
     */
    function getMaxCredit(address account) external view returns (uint256);

    /**
     * @dev Return agent remaining credit
     */
    function getRemainingCredit(address account) external view returns (uint256);

    /**
     * @dev Return agent minable status
     */
    function isMinable(address account) external view returns (bool);

    /**
     * @dev Return agent burnable status
     */
    function isBurnable(address account) external view returns (bool);

    /**
     * @dev Return agent effective block number
     */
    function getEffectiveBlock(address account) external view returns (uint256);

    /**
     * @dev Return agent expiration block number
     */
    function getExpirationBlock(address account) external view returns (uint256);

    /**
     * @dev Return whether the address is an agent
     */
    function hasAgent(address account) external view returns (bool);

    /**
     * @dev Grant the address as agent
     */
    function grantAgent(
        address account,
        uint256 credit,
        uint256 effectiveBlock,
        uint256 expirationBlock,
        bool minable,
        bool burnable
    ) external;

    /**
     * @dev Revoke the agent at the address
     */
    function revokeAgent(address account) external;

    /**
     * @dev Change the effective block number of the address agent
     */
    function changeEffectiveBlock(address account, uint256 effectiveBlock) external;

    /**
     * @dev Change the expiration block number of the address agent
     */
    function changeExpirationBlock(address account, uint256 expirationBlock) external;

    /**
     * @dev Change the minable status of the address agent
     */
    function switchMinable(address account, bool minable) external;

    /**
     * @dev Change the burnable status of the address agent
     */
    function switchBurnable(address account, bool burnable) external;

    /**
     * @dev Increase credit of the address agent
     */
    function increaseCredit(address account, uint256 credit) external;

    /**
     * @dev Decrease credit of the address agent
     */
    function decreaseCredit(address account, uint256 credit) external;
}