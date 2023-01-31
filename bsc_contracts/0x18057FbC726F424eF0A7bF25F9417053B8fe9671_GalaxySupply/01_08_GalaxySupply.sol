// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./interfaces/IERC4626.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IVenusProtocol.sol";
import "./interfaces/IGalaxyHolding.sol";
import "./utils/Ownable.sol";

contract GalaxySupply is Ownable {
    mapping(address => bool) public allowedManagers;

    modifier onlyManagers {
        require(allowedManagers[msg.sender] == true, "Only Managers");
        _;
    }

    function addManagers(address[] memory newManagers) public onlyOwner {
        for (uint i=0;i<newManagers.length;i++) {
            allowedManagers[newManagers[i]] = true;
        }
    }

    function removeManagers(address[] memory oldManagers) public onlyOwner {
        for (uint i=0;i<oldManagers.length;i++) {
            delete allowedManagers[oldManagers[i]];
        }
    }

    function supply(address token, address vault, uint256 amount) public onlyManagers {
        IERC20(token).approve(vault, amount);
        IVenusToken(vault).mint(amount);
    }

    function redeem(address vault, uint256 amount) public onlyManagers {
        IVenusToken(vault).redeem(amount);
    }

    function claim(address unitroller) public onlyManagers {
       IVenusUnitroller(unitroller).claimVenus(address(this));
    }

    function vaultDeposit(address token, address vaultToken, uint256 amount) public onlyManagers {
        IERC20(token).approve(vaultToken, amount);
        IERC4626(vaultToken).deposit(amount, address(this));
    }

    function redeemUnderlying(address vaultToken, uint256 amount) public onlyManagers {
        IERC4626(vaultToken).redeem(amount, address(this), address(this));
    }

    function takeLoan(address holdingContract, address vaultToken, uint256 amount) public onlyManagers {
        IGalaxyHolding(holdingContract).takeLoan(vaultToken, amount);
    }

    function loanPayment(address holdingContract, address vaultToken, address loanContract, uint256 amount) public onlyManagers {
        IERC20(vaultToken).approve(holdingContract, amount);
        IGalaxyHolding(holdingContract).loanPayment(vaultToken, loanContract, amount);
    }

    function withdrawToken(address token, uint256 amount) public onlyOwner {
        address to = this.owner();
        IERC20(token).transfer(to, amount);
    }

    function migrateTokens(address[] memory tokens, address newContract) public onlyOwner {
        for (uint256 i=0;i<tokens.length;i++) {
            uint256 balance = IERC20(tokens[i]).balanceOf(address(this));
            IERC20(tokens[i]).transfer(newContract, balance);
        }
    }
}