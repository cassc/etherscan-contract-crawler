// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IControlledToken.sol";

/**
 * @title  Asymetrix Protocol V1 Controlled ERC20 Token
 * @author Asymetrix Protocol Inc Team
 * @notice  ERC20 Tokens with a controller for minting & burning
 */
contract ControlledToken is
    Initializable,
    ERC20PermitUpgradeable,
    IControlledToken
{
    /* ============ Global Variables ============ */

    /// @notice Interface to the contract responsible for controlling mint/burn
    address public override controller;

    /// @notice ERC20 controlled token decimals.
    uint8 private _decimals;

    /* ============ Events ============ */

    /// @dev Emitted when contract is deployed
    event Deployed(
        string name,
        string symbol,
        uint8 decimals,
        address indexed controller
    );

    /* ============ Modifiers ============ */

    /// @dev Function modifier to ensure that the caller is the controller
    ///      contract
    modifier onlyController() {
        require(
            msg.sender == address(controller),
            "ControlledToken/only-controller"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /* ============ Initialize ============ */

    /// @notice Deploy the Controlled Token with Token Details and the
    ///         Controller
    /// @param _name The name of the Token
    /// @param _symbol The symbol for the Token
    /// @param decimals_ The number of decimals for the Token
    /// @param _controller Address of the Controller contract for minting &
    ///                    burning
    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 decimals_,
        address _controller
    ) external virtual initializer {
        __ControlledToken_init_unchained(
            _name,
            _symbol,
            decimals_,
            _controller
        );
    }

    function __ControlledToken_init_unchained(
        string memory _name,
        string memory _symbol,
        uint8 decimals_,
        address _controller
    ) internal onlyInitializing {
        __ERC20Permit_init("Asymetrix Protocol ControlledToken");
        __ERC20_init_unchained(_name, _symbol);

        require(
            address(_controller) != address(0),
            "ControlledToken/controller-not-zero-address"
        );
        controller = _controller;

        require(decimals_ > 0, "ControlledToken/decimals-gt-zero");

        _decimals = decimals_;

        emit Deployed(_name, _symbol, decimals_, _controller);
    }

    /* ============ External Functions ============ */

    /// @notice Allows the controller to mint tokens for a user account
    /// @dev May be overridden to provide more granular control over minting
    /// @param _user Address of the receiver of the minted tokens
    /// @param _amount Amount of tokens to mint
    function controllerMint(
        address _user,
        uint256 _amount
    ) external virtual override onlyController {
        _mint(_user, _amount);
    }

    /// @notice Allows the controller to burn tokens from a user account
    /// @dev May be overridden to provide more granular control over burning
    /// @param _user Address of the holder account to burn tokens from
    /// @param _amount Amount of tokens to burn
    function controllerBurn(
        address _user,
        uint256 _amount
    ) external virtual override onlyController {
        _burn(_user, _amount);
    }

    /// @notice Allows an operator via the controller to burn tokens on behalf
    ///         of a user account
    /// @dev May be overridden to provide more granular control over
    ///      operator-burning
    /// @param _operator Address of the operator performing the burn action via
    ///                  the controller contract
    /// @param _user Address of the holder account to burn tokens from
    /// @param _amount Amount of tokens to burn
    function controllerBurnFrom(
        address _operator,
        address _user,
        uint256 _amount
    ) external virtual override onlyController {
        if (_operator != _user) {
            _approve(_user, _operator, allowance(_user, _operator) - _amount);
        }

        _burn(_user, _amount);
    }

    /// @notice Returns the ERC20 controlled token decimals.
    /// @dev This value should be equal to the decimals of the token used to
    ///      deposit into the pool.
    /// @return uint8 decimals.
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}