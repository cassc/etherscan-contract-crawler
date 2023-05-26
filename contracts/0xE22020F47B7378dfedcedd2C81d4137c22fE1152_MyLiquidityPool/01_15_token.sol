// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "ERC20.sol";
import "ERC20Capped.sol";
import "AccessControl.sol";
import "UsingLiquidityProtectionService.sol";

contract MyLiquidityPool is ERC20Capped, AccessControl, UsingLiquidityProtectionService(0xd27b8B3C5444CB4B0C6e9caCD35375c32eca022f) {

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor(
        string memory name,
        string memory symbol,
        uint256 cap,
        address owner
    ) ERC20(name, symbol) ERC20Capped(cap) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, owner);
        _setupRole(MINTER_ROLE, owner);
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    }

    function mint(address to, uint256 amount) external {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _mint(to, amount);
    }

    function token_transfer(address _from, address _to, uint _amount) internal override {
        _transfer(_from, _to, _amount); // Expose low-level token transfer function.
    }
    function token_balanceOf(address _holder) internal view override returns(uint) {
        return balanceOf(_holder); // Expose balance check function.
    }
    function protectionAdminCheck() internal view override onlyRole(ADMIN_ROLE) {} // Must revert to deny access.
    function uniswapVariety() internal pure override returns(bytes32) {
        return UNISWAP; // UNISWAP / PANCAKESWAP / QUICKSWAP / SUSHISWAP.
    }
    function uniswapVersion() internal pure override returns(UniswapVersion) {
        return UniswapVersion.V3; // V2 or V3.
    }
    function uniswapFactory() internal pure override returns(address) {
        return 0x1F98431c8aD98523631AE4a59f267346ea31F984; // UniswapV3Factory
    }
    function _beforeTokenTransfer(address _from, address _to, uint _amount) internal override {
        super._beforeTokenTransfer(_from, _to, _amount);
        LiquidityProtection_beforeTokenTransfer(_from, _to, _amount);
    }
    // All the following overrides are optional, if you want to modify default behavior.

    // How the protection gets disabled.
    function protectionChecker() internal view override returns(bool) {
        return ProtectionSwitch_timestamp(1654559999); // Switch off protection on Monday, June 6, 2022 11:59:59 PM GMT.
        // return ProtectionSwitch_block(13000000); // Switch off protection on block 13000000.
        // return ProtectionSwitch_manual(); // Switch off protection by calling disableProtection(); from owner. Default.
    }

    // This token will be pooled in pair with:
    function counterToken() internal pure override returns(address) {
        return 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC
    }

}