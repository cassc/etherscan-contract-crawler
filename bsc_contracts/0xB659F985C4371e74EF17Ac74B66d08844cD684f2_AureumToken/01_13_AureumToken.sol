// contracts/MyToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "hardhat/console.sol";

contract AureumToken is ERC20, AccessControl {
    // Create a new role identifier for the minter role
    using Address for address;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant EWITHDRAW_ROLE = keccak256("EWITHDRAW_ROLE");
    address public EToken = address(0x1597F069D3ec65d5A4625527054e40F69533f27E);

    constructor(address minter) ERC20("Aureum Token", "AUT") {
        // Grant the minter role to a specified account
        _setupRole(DEFAULT_ADMIN_ROLE, minter);
        _setupRole(MINTER_ROLE, minter);
    }

    function mint(address to, uint256 amount) public {
        // Check that the calling account has the minter role
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");

        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function modifiyEToken(address newToken) public {
        // Check that the calling account has the minter role
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not a withdrawer"
        );
        EToken = newToken;
    }

    function getEtokenBalance() public view returns (uint256) {
        // Check that the calling account has the minter role
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not a withdrawer"
        );
        IERC20 eToken = IERC20(EToken);
        return eToken.balanceOf(address(this));
    }

    function withDrawEtoken() public {
        // Check that the calling account has the minter role
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not a withdrawer"
        );
        IERC20 eToken = IERC20(EToken);
        eToken.transfer(msg.sender, eToken.balanceOf(address(this)));
    }
}