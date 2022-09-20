// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/AccessControlEnumerable.sol";

import "./IOverlayV1Token.sol";

contract OverlayV1Token is IOverlayV1Token, AccessControlEnumerable, ERC20("Overlay", "OVL") {
    constructor() {
        address DAO_multisig = 0xB635D8EcC59330dDf611B4aA02e9d78820Cd3985;
        _grantRole(DEFAULT_ADMIN_ROLE, DAO_multisig);
        _grantRole(GUARDIAN_ROLE, DAO_multisig);
        _grantRole(GOVERNOR_ROLE, DAO_multisig);
        _mint(msg.sender, 8000000000000000000000000);
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "ERC20: !minter");
        _;
    }

    modifier onlyBurner() {
        require(hasRole(BURNER_ROLE, msg.sender), "ERC20: !burner");
        _;
    }

    function mint(address _recipient, uint256 _amount) external onlyMinter {
        _mint(_recipient, _amount);
    }

    function burn(uint256 _amount) external onlyBurner {
        _burn(msg.sender, _amount);
    }
}