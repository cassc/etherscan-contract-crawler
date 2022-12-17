// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./openzeppelin/access/AccessControl.sol";
import "./openzeppelin/token/ERC20/IERC20.sol";
import "./IDUD.sol";

contract Vault is AccessControl {
    IDUD public dud;
    IERC20 public busd;

    uint256 public mintPrice; // percents of BUSD (10% = 0.1 BUSD)
    uint256 public burnPrice; // 8% = 0.08 BUSD

    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    constructor(
        address _dudAddress,
        address _busdAddress
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        dud = IDUD(_dudAddress);
        busd = IERC20(_busdAddress);
        mintPrice = 10;
        burnPrice = 8;
    }

    function setMintingPrice(uint256 _mintPrice) public onlyRole(DEFAULT_ADMIN_ROLE) {
        mintPrice = _mintPrice;
    }

    function setBurningPrice(uint256 _burnPrice) public onlyRole(DEFAULT_ADMIN_ROLE) {
        burnPrice = _burnPrice;
    }

    function mint(uint256 amount) public {
        uint256 busdAmount = amount * mintPrice / 100;
        require(busdAmount > 0, "Amount is too little");
        bool result = busd.transferFrom(_msgSender(), address(this), busdAmount);
        require(result == true, "Can't transfer BUSD");

        dud.mint(_msgSender(), amount);
    }

    function burn(uint256 amount) public {
        uint256 busdAmount = amount * burnPrice / 100;
        require(busdAmount > 0, "Amount is too little");
        bool result = busd.transfer(_msgSender(), busdAmount);
        require(result == true, "Can't transfer BUSD");

        dud.burnFrom(_msgSender(), amount);
    }

    function withdraw(uint256 amount) public onlyRole(WITHDRAWER_ROLE) {
        require(amount <= busd.balanceOf(address(this)), "Unsufficient balance");
        busd.transfer(_msgSender(), amount);
    }
}