// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract getKicks is AccessControl, ERC20Capped, Ownable {
    using SafeMath for uint256;

    address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");
    bytes32 public constant BANNEDLISTED_ROLE = keccak256("BANNEDLISTED_ROLE");

    uint256 public startTime;
    uint256 public blockSellUntil;

    bool public isTimeLockEnabled;
    address public pairAddress;

    event TimeLockEnabled(bool value);

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint256 supplyCap,
        uint256 _startTime,
        uint256 _blockSellUntil
    ) ERC20(name, symbol) ERC20Capped(supplyCap) {
        isTimeLockEnabled = true;
        startTime = _startTime;
        blockSellUntil = _blockSellUntil;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _mint(_msgSender(), initialSupply);
    }

    //Modifier which controls transfer on a set time period
    modifier isTimeLocked(address from, address to) {
        if (isTimeLockEnabled) {
            if (!hasRole(DEFAULT_ADMIN_ROLE, from) && !hasRole(DEFAULT_ADMIN_ROLE, to)) {
                require(block.timestamp >= startTime, "getKicks: Trading not enabled yet");
            }
        }
        _;
    }

    //Modifier which blocks sell until blockSellUntil value
    modifier isSaleBlocked(address from, address to) {
        if (!hasRole(DEFAULT_ADMIN_ROLE, from) && to == pairAddress) {
            require(block.timestamp >= blockSellUntil, "getKicks: Sell disabled!");
        }
        _;
    }

    /**
     *
     * @dev Include/Exclude multiple address in blacklist
     *
     * @param {addr} Address array of users
     * @param {value} Whitelist status of users
     *
     * @return {bool} Status of bulk ban list
     *
     */
    function bulkBannedList(address[] calldata addr) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        uint256 len = addr.length;
        for (uint256 i = 0; i < len; i++) {
            _setupRole(BANNEDLISTED_ROLE, addr[i]);
        }
        return true;
    }

    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required amount for user
     * Make sure minting is done only by this function
     * @param user user address for whom deposit is being done
     * @param depositData abi encoded amount
     */

    function deposit(address user, bytes calldata depositData) external onlyRole(DEPOSITOR_ROLE) {
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
    }

    /**
     *
     * @dev Set pairAddress
     *
     * @param {addr} address of pancakswap liquidity pair
     *
     * @return {bool} Status of operation
     *
     */
    function setPairAddress(address addr) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        pairAddress = addr;
        return true;
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external onlyOwner returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    /**
     * @notice Example function to handle minting tokens on matic chain
     * @dev Minting can be done as per requirement,
     * This implementation allows only admin to mint tokens but it can be changed as per requirement
     * @param user user for whom tokens are being minted
     * @param amount amount of token to mint
     */
    function mint(address user, uint256 amount) public onlyOwner {
        _mint(user, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        // solhint-disable-next-line no-unused-vars
        uint256 amount
    ) internal virtual override isTimeLocked(from, to) isSaleBlocked(from, to) {
        if (hasRole(BANNEDLISTED_ROLE, from)) {
            revert("getKicks: from address banned");
        } else if (hasRole(BANNEDLISTED_ROLE, to)) {
            revert("getKicks: to address banned");
        }
    }
}