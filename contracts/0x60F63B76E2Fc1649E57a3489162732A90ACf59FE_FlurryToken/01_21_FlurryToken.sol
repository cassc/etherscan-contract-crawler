//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./VestedToken.sol";

contract FlurryToken is VestedToken, ERC20PresetMinterPauser, ERC20Capped {
    // Token
    uint256 public constant MAX_SUPPLY = 1e28;

    // Role
    bytes32 public constant SWEEPER_ROLE = keccak256("SWEEPER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    // Initilizer
    constructor(
        string memory name,
        string memory symbol,
        uint256 _restrictionGas,
        uint256 _restrictionAmount,
        uint256 _unlockMultiple,
        uint256 _maxLock
    ) ERC20PresetMinterPauser(name, symbol) ERC20Capped(MAX_SUPPLY){
        VestedToken.__intitialize(_restrictionGas, _restrictionAmount, _unlockMultiple, _maxLock);
    }

    // TODO - Governance

    /// @notice A record of states for signing / validating signatures
    // mapping(address => uint256) public nonces;

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public override {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal override(ERC20, ERC20Capped) {
        require(totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }

    function burn(address to, uint256 amount) external {
        require(hasRole(BURNER_ROLE, _msgSender()), "ERC20PresetminterPauser: must have burner role to burn");
        _burn(to, amount);
    }

    /**
     * @dev Multiple inheritance for _beforeTokenTransfer.
     * Need to override all functions with the same signature in the parents
     * All the parent implementations however, does nothing substantial.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20PresetMinterPauser) launchRestrict(from, to, amount) {
        ERC20PresetMinterPauser._beforeTokenTransfer(from, to, amount);
    }

    function sweepERC20Token(address token, address to) external onlyRole(SWEEPER_ROLE) {
        require(token != address(this), "!safe");
        IERC20 tokenToSweep = IERC20(token);
        tokenToSweep.transfer(to, tokenToSweep.balanceOf(address(this)));
    }

    function getOwner() external view returns (address) {
        if (getRoleMemberCount(DEFAULT_ADMIN_ROLE) == 0) {
            return address(0);
        }
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

}