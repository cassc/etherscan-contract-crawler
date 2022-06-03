// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

abstract contract BPContract {
    function protect(address sender, address receiver, uint256 amount) external virtual;
}
/// @notice LunaFI's Token contract
contract LFIToken is
    ERC20,
    Pausable,
    ERC20Permit,
    AccessControl
{
    string constant TOKEN_NAME = "LunaFi";
    string constant TOKEN_SYMBOL = "LFI";

    
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    uint256 public maxSupply;

    uint8 internal constant DECIMAL_PLACES = 18;

    BPContract public BP;
    bool public bpEnabled;
    bool public BPDisabledForever = false;

    constructor(uint256 supply) ERC20(TOKEN_NAME, TOKEN_SYMBOL) ERC20Permit(TOKEN_NAME) {
        maxSupply = supply * 10**DECIMAL_PLACES; // 1 Billion Tokens ^ 10 decimals

        super._mint(msg.sender, maxSupply);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
    }
    /// @notice Function to set the Bot Protection addresss
    /// @param _bp bot protection contract address
    function setBPAddress(address _bp) external onlyRole(MANAGER_ROLE){
        require(address(BP) == address(0),"can only be initialized once");
        BP = BPContract(_bp);
    }
    /// @notice Function to enable or disable bot protection
    /// @param _enabled - trur or false to enable or disable the bot protection
    function setBpEnabled(bool _enabled) external onlyRole(MANAGER_ROLE) {
        bpEnabled = _enabled;
    }
    /// @notice Function to disable bot protection for ever
    function setBotProtectionDisableForever() external onlyRole(MANAGER_ROLE) {
        require(BPDisabledForever == false);
        BPDisabledForever = true;
    }
    /// @notice Function to pause contract operations
    function pause() external onlyRole(PAUSER_ROLE) returns (bool) {
        _pause();
        return true;
    }
    /// @notice Function to unpause contract operations
    function unpause() external onlyRole(PAUSER_ROLE) returns (bool) {
        _unpause();
        return true;
    }
    // Function to retunr decimals
    function decimals() public pure override returns (uint8) {
        return DECIMAL_PLACES;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return super.totalSupply();
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account);
    }
    /// @notice Internal _beforeTokenTransfer function
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) whenNotPaused {
        if(bpEnabled && !BPDisabledForever) {
            BP.protect(from,to,amount);
        }
        super._beforeTokenTransfer(from, to, amount);
    }
    /// @notice Internal _afterTokenTransfer function
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) {
        super._afterTokenTransfer(from, to, amount);
    }
    
}