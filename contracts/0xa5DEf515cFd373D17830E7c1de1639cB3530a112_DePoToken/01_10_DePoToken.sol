// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './UsingLiquidityProtectionService.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';


contract DePoToken is ERC20, Ownable, UsingLiquidityProtectionService(0x7F6140Bab96793126c0306C08687603F4Cb5b098) {

    constructor() ERC20('DePo Token', 'DEPO') {
        _mint(owner(), 1000000000 * 1e18);
    }

    function token_transfer(address _from, address _to, uint _amount) internal override {
        _transfer(_from, _to, _amount); // Expose low-level token transfer function.
    }
    function token_balanceOf(address _holder) internal view override returns(uint) {
        return balanceOf(_holder); // Expose balance check function.
    }
    function protectionAdminCheck() internal view override onlyOwner {} // Must revert to deny access.
    function uniswapVariety() internal pure override returns(bytes32) {
        return UNISWAP; // UNISWAP / PANCAKESWAP / QUICKSWAP.
    }
    function uniswapVersion() internal pure override returns(UniswapVersion) {
        return UniswapVersion.V2; // V2 or V3.
    }
    function uniswapFactory() internal pure override returns(address) {
        return 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; // Replace with the correct address.
    }
    function _beforeTokenTransfer(address _from, address _to, uint _amount) internal override {
        super._beforeTokenTransfer(_from, _to, _amount);
        LiquidityProtection_beforeTokenTransfer(_from, _to, _amount);
    }
    // All the following overrides are optional, if you want to modify default behavior.

    // How the protection gets disabled.
    function protectionChecker() internal view override returns(bool) {
        return ProtectionSwitch_timestamp(1634133600); // Switch off protection on Wednesday, October 13, 2021 2:00:00 PM GMT.
        // return ProtectionSwitch_block(13000000); // Switch off protection on block 13000000.
        //return ProtectionSwitch_manual(); // Switch off protection by calling disableProtection(); from owner. Default.
    }

    // This token will be pooled in pair with:
    function counterToken() internal pure override returns(address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH
    }
}