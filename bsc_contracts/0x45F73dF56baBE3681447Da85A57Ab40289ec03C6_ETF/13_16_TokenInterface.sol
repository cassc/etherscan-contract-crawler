// SPDX-License-Identifier: MIT
import "./TokenStorage.sol";
import "./BalanceStorage.sol";
pragma solidity 0.5.16;


contract TokenInterface is TokenStorage, BalanceStorage {

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateBalanceChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Event emitted when tokens are rebased
     */
    event Rebase(uint256 epoch, uint256 prevETFScalingFactor, uint256 newETFScalingFactor);

    /*** Gov Events ***/

    /**
     * @notice Event emitted when pendingGov is changed
     */
    event NewPendingGov(address oldPendingGov, address newPendingGov);

    /**
     * @notice Event emitted when gov is changed
     */
    event NewGov(address oldGov, address newGov);

    /**
     * @notice Sets the rebaser contract
     */
    event NewRebaser(address oldRebaser, address newRebaser);

    /**
    * @notice Event emitted when Guardian is changed
    */
    event NewGuardian(address oldGuardian, address newGuardian);

    /**
    * @notice Event emitted when the pause is triggered.
    */
    event Paused(address account);

    /**
    * @dev Event emitted when the pause is lifted.
    */
    event Unpaused(address account);
    /* - ERC20 Events - */

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /* - Extra Events - */
    /**
     * @notice Tokens minted event
     */
    event Mint(address to, uint256 amount);
    event Burn(address from, uint256 amount);

    // Public functions
    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
    function balanceOf(address who) external view returns(uint256);
    function balanceOfUnderlying(address who) external view returns(uint256);
    function allowance(address owner_, address spender) external view returns(uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function maxScalingFactor() external view returns (uint256);
    function etfToFragment(uint256 etf) external view returns (uint256);
    function fragmentToETF(uint256 value) external view returns (uint256);

//     /* - Governance Functions, modified to track balance - */
    function getPriorBalance(address account, uint blockNumber) external view returns (uint256);
    // function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external;
    // function delegate(address delegatee) external;
    // function delegates(address delegator) external view returns (address);
    function getCurrentBalance(address account) external view returns (uint256);

//     /* - Permissioned/Governance functions - */
    function mint(address to, uint256 amount) external returns (bool);
    function rebase(uint256 epoch, uint256 indexDelta, bool positive) external returns (uint256);
    function _setRebaser(address rebaser_) external;
    function _setPendingGov(address pendingGov_) external;
    function _acceptGov() external;
}