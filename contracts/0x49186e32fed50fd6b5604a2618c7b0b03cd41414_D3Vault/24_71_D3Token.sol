// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../lib/InitializableOwnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title D3Token
/// @notice When LP deposit token into D3MM pool, they receive certain amount of corresponding D3Token.
/// @notice D3Token acts as an interest bearing LP token.
contract D3Token is InitializableOwnable, ERC20("DODOV3 Token", "D3Token") {
    address public originToken;
    string private _symbol;
    string private _name;

    // ============ Events ============

    event Mint(address indexed user, uint256 value);

    event Burn(address indexed user, uint256 value);

    // ============ Functions ============

    function init(address token, address pool) external {
        initOwner(pool);
        originToken = token;
        _symbol = string.concat("d3", IERC20Metadata(token).symbol());
        _name = string.concat(_symbol, "_", addressToShortString(pool));
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function decimals() public view override returns (uint8) {
        return IERC20Metadata(originToken).decimals();
    }

    /// @dev Transfer token for a specified address
    /// @param to The address to transfer to.
    /// @param amount The amount to be transferred.
    function transfer(address to, uint256 amount) public override returns (bool) {
        address owner = _msgSender();
        require(amount <= balanceOf(owner), "BALANCE_NOT_ENOUGH");
        _transfer(owner, to, amount);
        return true;
    }

    /// @dev Transfer tokens from one address to another
    /// @param from address The address which you want to send tokens from
    /// @param to address The address which you want to transfer to
    /// @param amount uint256 the amount of tokens to be transferred
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(amount <= balanceOf(from), "BALANCE_NOT_ENOUGH");
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /// @notice Mint certain amount of token for user
    function mint(address user, uint256 value) external onlyOwner {
        _mint(user, value);
        emit Mint(user, value);
    }

    /// @notice Burn certain amount of token on user account
    function burn(address user, uint256 value) external onlyOwner {
        _burn(user, value);
        emit Burn(user, value);
    }

    /// @notice Convert the address to a shorter string
    function addressToShortString(address _addr) public pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(8);
        for (uint256 i = 0; i < 4; i++) {
            str[i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[1 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
}