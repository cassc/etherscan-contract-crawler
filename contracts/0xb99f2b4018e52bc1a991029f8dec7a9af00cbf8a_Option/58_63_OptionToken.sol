// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title A contract for creating and managing Option Tokens within the DeOrderBook system.
 * @author DeOrderBook
 * @custom:license Copyright (c) DeOrderBook, 2023 — All Rights Reserved
 * @notice These tokens represent whole options in the system. Only a designated controller can mint or burn tokens.
 * @dev This contract extends the ERC20 contract with additional functions for minting and burning tokens, and includes checks to ensure that only the designated controller can perform these actions. It also allows for updating the token symbol post deployment.
 */
contract OptionToken is ERC20 {
    /**
     * @notice The ID of the associated option.
     * @dev Publicly accessible variable storing the ID for this specific option.
     */
    uint256 public optionID;

    /**
     * @notice The address of the entity that controls minting and burning.
     * @dev Publicly accessible variable storing the address of the controller.
     */
    address public controller;

    /**
     * @notice A boolean to track if the contract has been initialized.
     * @dev Private variable to prevent multiple initializations.
     */
    bool private initiated = false;

    /**
     * @notice The name of the option token.
     * @dev Private variable to store the name, which can be updated via the `activeInit` function.
     */
    string private _name;

    /**
     * @notice The symbol of the option token.
     * @dev Private variable to store the symbol, which can be updated via the `updateSymbol` function.
     */
    string private _symbol;

    /**
     * @notice Throws if called by any account other than the controller.
     * @dev Modifier that checks if the caller is the controller.
     */
    modifier onlyController() {
        require(msg.sender == controller, "Option Token: caller is not the controller");
        _;
    }

    /**
     * @notice Throws if the contract is not yet initialized.
     * @dev Modifier that checks if the contract is initiated.
     */
    modifier onlyInitiated() {
        require(initiated, "Option Token: contract is not the initiated");
        _;
    }

    /**
     * @notice Contract constructor.
     * @dev Calls ERC20 constructor with initial token name and symbol.
     */
    constructor() ERC20("Option token", "OptionToken") {}

    /**
     * @notice Returns the name of the token.
     * @dev Overrides the ERC20 name function.
     * @return The name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @notice Returns the symbol of the token.
     * @dev Overrides the ERC20 symbol function.
     * @return The symbol of the token.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Initializes the contract, setting the controller address.
     * @dev Can only be called once, when controller is not set.
     * @param _controller The address of the controller.
     */
    function initialize(address _controller) external {
        require(controller == address(0), "Option Token:controller initiated");
        require(_controller != address(0), "Option Token: zero address");
        controller = _controller;
    }

    /**
     * @notice Activates the contract initialization, setting option ID, name and symbol.
     * @dev Can only be called by the controller and when contract is not initiated.
     * @param _optionID The ID of the associated option.
     * @param _new_name The new name of the token.
     * @param _new_symbol The new symbol of the token.
     */
    function activeInit(
        uint256 _optionID,
        string memory _new_name,
        string memory _new_symbol
    ) external onlyController {
        require(!initiated, "Option Token: initiated");
        _name = _new_name;
        _symbol = _new_symbol;
        optionID = _optionID;
        initiated = true;
    }

    /**
     * @notice Updates the symbol of the token.
     * @dev Can only be called by the controller.
     * @param _new_symbol The new symbol of the token.
     */
    function updateSymbol(string memory _new_symbol) external onlyController {
        _symbol = _new_symbol;
    }

    /**
     * @notice Mints a specified amount of tokens for a given account.
     * @dev Can only be called by the controller and when contract is initiated.
     * @param _account The address of the account to mint tokens for.
     * @param _amount The amount of tokens to be minted.
     */
    function mintFor(address _account, uint256 _amount) external onlyController onlyInitiated {
        _mint(_account, _amount);
    }

    /**
     * @notice Burns a specified amount of tokens from the sender's account.
     * @dev Can only be called by the controller and when contract is initiated.
     * @param amount The amount of tokens to be burned.
     */
    function burn(uint256 amount) external onlyController onlyInitiated {
        _burn(_msgSender(), amount);
    }

    /**
     * @notice Burns a specified amount of tokens from a given account.
     * @dev Can only be called by the controller and when contract is initiated.
     * @param account The address of the account to burn tokens from.
     * @param amount The amount of tokens to be burned.
     */
    function burnFrom(address account, uint256 amount) external onlyController onlyInitiated {
        _burn(account, amount);
    }
}