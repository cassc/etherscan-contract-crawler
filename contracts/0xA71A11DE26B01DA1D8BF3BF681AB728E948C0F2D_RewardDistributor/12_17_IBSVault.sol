// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IERC3156FlashLender.sol";

interface IBSVault is IERC3156FlashLender {
    // ************** //
    // *** EVENTS *** //
    // ************** //

    /// @notice Emitted on deposit
    /// @param token being deposited
    /// @param from address making the depsoit
    /// @param to address to credit the tokens being deposited
    /// @param amount being deposited
    /// @param shares the represent the amount deposited in the vault
    event Deposit(
        IERC20 indexed token,
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 shares
    );

    /// @notice Emitted on withdraw
    /// @param token being deposited
    /// @param from address making the depsoit
    /// @param to address to credit the tokens being withdrawn
    /// @param amount Amount of underlying being withdrawn
    /// @param shares the represent the amount withdraw from the vault
    event Withdraw(
        IERC20 indexed token,
        address indexed from,
        address indexed to,
        uint256 shares,
        uint256 amount
    );

    event Transfer(IERC20 indexed token, address indexed from, address indexed to, uint256 amount);

    event FlashLoan(
        address indexed borrower,
        IERC20 indexed token,
        uint256 amount,
        uint256 feeAmount,
        address indexed receiver
    );

    event TransferControl(address _newTeam, uint256 timestamp);

    event UpdateFlashLoanRate(uint256 newRate);

    event Approval(address indexed user, address indexed allowed, bool status);

    event OwnershipAccepted(address prevOwner, address newOwner, uint256 timestamp);

    event RegisterProtocol(address sender);

    event AllowContract(address whitelist, bool status);

    event RescueFunds(IERC20 token, uint256 amount);

    // ************** //
    // *** FUNCTIONS *** //
    // ************** //

    function initialize(uint256 _flashLoanRate, address _owner) external;

    function approveContract(
        address _user,
        address _contract,
        bool _status,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function deposit(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) external returns (uint256, uint256);

    function withdraw(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) external returns (uint256);

    function balanceOf(IERC20, address) external view returns (uint256);

    function transfer(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _shares
    ) external;

    function toShare(
        IERC20 token,
        uint256 amount,
        bool ceil
    ) external view returns (uint256);

    function toUnderlying(IERC20 token, uint256 share) external view returns (uint256);
}