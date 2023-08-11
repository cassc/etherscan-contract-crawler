// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract DERC20 is ERC20Pausable, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    address private owner;
    string private _name;

    mapping(address => bool) public isBlockListed;

    event AddedBlockList(address user);
    event RemovedBlockList(address user);

    constructor(string memory symbol) ERC20("", symbol) {
        owner = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(BURNER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(PAUSER_ROLE, ADMIN_ROLE);
    }

    /**
     * @dev Returns the owner of the token.
     * Binance Smart Chain BEP20 compatibility
     */
    function getOwner() external view returns (address) {
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Mint token
     *
     * Requirements
     *
     * - `to` recipient address.
     * - `amount` amount of tokens.
     */
    function mint(address to, uint256 amount) external {
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "You should have a minter role"
        );
        _mint(to, amount);
    }

    /**
     * @dev Burn token
     *
     * Requirements
     *
     * - `from` address of user.
     * - `amount` amount of tokens.
     */
    function burn(address from, uint256 amount) external {
        require(
            hasRole(BURNER_ROLE, msg.sender),
            "You should have a burner role"
        );
        _burn(from, amount);
    }

    /**
     * @dev Pause token
     */
    function pause() external {
        require(
            hasRole(PAUSER_ROLE, msg.sender),
            "You should have a pauser role"
        );
        super._pause();
    }

    /**
     * @dev Pause token
     */
    function unpause() external {
        require(
            hasRole(PAUSER_ROLE, msg.sender),
            "You should have a pauser role"
        );
        super._unpause();
    }

    /**
     * @dev Add user address to blocklist
     *
     * Requirements
     *
     * - `user` address of user.
     */
    function addBlockList(address user) external {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "You should have an admin role"
        );
        isBlockListed[user] = true;
        emit AddedBlockList(user);
    }

    /**
     * @dev Remove user address from blocklist
     *
     * Requirements
     *
     * - `user` address of user.
     */
    function removeBlockList(address user) external {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "You should have an admin role"
        );
        isBlockListed[user] = false;

        emit RemovedBlockList(user);
    }

    /**
     * @dev Update name of token
     *
     * Requirements
     *
     * - `name_` name of token
     */
    function updateName(string memory name_) external {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "You should have an admin role"
        );
        _name = name_;
    }

    /**
     * @dev check blocklist when token minted, burned or transfered
     *
     * Requirements
     *
     * - `from` source address
     * - `to` destination address
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        ERC20Pausable._beforeTokenTransfer(from, to, amount);
        require(isBlockListed[from] == false, "Address from is blocklisted");
        require(isBlockListed[to] == false, "Address to is blocklisted");
    }
}