/*

  /$$$$$$   /$$$$$$  /$$$$$$  /$$$$$$ 
 /$$__  $$ /$$__  $$|_  $$_/ /$$__  $$
| $$  \ $$| $$  \__/  | $$  | $$  \__/
| $$$$$$$$|  $$$$$$   | $$  | $$      
| $$__  $$ \____  $$  | $$  | $$      
| $$  | $$ /$$  \ $$  | $$  | $$    $$
| $$  | $$|  $$$$$$/ /$$$$$$|  $$$$$$/
|__/  |__/ \______/ |______/ \______/ 

*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/PulseDogecoin.sol";

/// @title ASIC (Application Specific Internet Currency) smart contract
/// @author 01101000 01100101 01111000 01101001 01101110 01100110 01101111 00100000 00100110 00100000 01101011 01101111 01100100 01100101
/// @dev ASIC is used to mine PulseBitcoin. ASIC can be created by transforming PulseDogecoin.
contract ASIC is ERC20, ReentrancyGuard {
    IPulseDogecoin private _plsd;

    // constants
    uint256 private immutable LAUNCH_TIME;
    address private immutable OWNER;
    uint256 private constant SCALE_FACTOR = 5;
    uint256 private constant TRANSFORM_EVENT_LENGTH = 60;
    address private constant PLSD_ADDRESS = address(0x34F0915a5f15a66Eba86F6a58bE1A471FB7836A7);
    address private constant DEAD_ADDRESS = address(0x000000000000000000000000000000000000dEaD);

    // variables
    uint256 public totalPlsdTransformed;

    // events
    event Transform(uint256 data0, address indexed account);

    // errors
    error NotOwner();
    error TransformFailed();
    error TransformEventIsOver(uint256 eventLength, uint256 currentDay);
    error InsufficientBalance(uint256 available, uint256 required);
    error InvalidAmount(uint256 sent, uint256 required);

    // modifiers
    modifier onlyOwner() {
        if (msg.sender != OWNER) {
            revert NotOwner();
        }
        _;
    }

    // functions
    constructor() ERC20("Application Specific Internet Coin", "ASIC") {
        LAUNCH_TIME = block.timestamp;
        OWNER = msg.sender;
        _plsd = IPulseDogecoin(PLSD_ADDRESS);
    }

    /// @dev Private function to determine the current day
    function _currentDay() internal view returns (uint256) {
        return ((block.timestamp - LAUNCH_TIME) / 1 days);
    }

    /// @dev Returns the PulseBitcoin contract address
    function owner() external view returns (address) {
        return OWNER;
    }

    /// @dev Overrides the ERC-20 decimals function
    function decimals() public view virtual override returns (uint8) {
        return 12;
    }

    /// @dev Mints new tokens. Only the owner of contract can run this function
    /// @param account Address of the account to receive the minted tokens
    /// @param amount Amount of tokens to be minted
    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    /// @dev Burns existing tokens. Only the owner of contract can run this function
    /// @param account Address of the account to have the tokens burned
    /// @param amount Amount of tokens to be burned
    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }

    /// @dev Transforms PulseDogecoin tokens into ASIC tokens
    /// @param amount Amount of tokens to be transformed
    /// @return bitoshiAmount Amount of bitoshis
    function transform(uint256 amount) external nonReentrant returns (uint256) {
        // Validations
        if (_currentDay() > TRANSFORM_EVENT_LENGTH) {
            revert TransformEventIsOver({eventLength: TRANSFORM_EVENT_LENGTH, currentDay: _currentDay()});
        }

        if (amount == 0) {
            revert InvalidAmount({sent: amount, required: 1});
        }
        if (amount > _plsd.balanceOf(msg.sender)) {
            revert InsufficientBalance({available: _plsd.balanceOf(msg.sender), required: amount});
        }

        uint256 points;

        // Burn PLSD and Mint ASIC
        if (_plsd.transferFrom(msg.sender, DEAD_ADDRESS, amount)) {
            totalPlsdTransformed += amount;
            points = amount * SCALE_FACTOR;

            _mint(msg.sender, points);

            emit Transform(
                uint256(uint40(block.timestamp)) | (uint256(uint104(amount)) << 40) | (uint256(uint104(points)) << 144),
                msg.sender
            );
        } else {
            revert TransformFailed();
        }
        return points;
    }
}