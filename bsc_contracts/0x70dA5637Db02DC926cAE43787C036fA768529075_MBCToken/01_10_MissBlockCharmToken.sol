// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MBCToken is ERC20, AccessControl {

    bool public isTransferable;
    
    mapping(address => bool) public addressesTransferable;

    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    bytes32 public constant MINTING_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor() ERC20("MBC Token", "MBC") {
       _setupRole(
            DEFAULT_ADMIN_ROLE,
            msg.sender
        );
    }

    function setIsTransferable(bool isTransferable_) external onlyRole(CONTROLLER_ROLE) {
        isTransferable = isTransferable_;
    }

    function setAddressTransferable(address address_, bool isTransferable_) external onlyRole(CONTROLLER_ROLE) {
        require(address_ != address(0));
        addressesTransferable[address_] = isTransferable_;
    }

    function burnFrom(address account, uint256 amount) public virtual onlyRole(BURNER_ROLE) {
        _burn(account, amount);
    }

    function mint(address account, uint256 amount) external onlyRole(MINTING_ROLE) {
        _mint(account, amount);
    }

    /************************************************************************************
     * Internal methods =>
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override view {

        bool isMintingProcess = from == address(0);
        bool isBurningProcess = to == address(0);
        if(!isMintingProcess && !isBurningProcess) {
            require(isTransferable || addressesTransferable[from], "cannot transfer");
        }
    }
}