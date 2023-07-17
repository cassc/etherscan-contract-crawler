//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IMintable.sol";
import "../interfaces/IUniswapV2Factory.sol";

contract Ludus is AccessControl, ERC20("Ludus", "LUDUS"), IMintable {
    using SafeMath for uint256;
    // The identifier of the role which maintains other roles.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    // The identifier of the role which allows accounts to mint tokens.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    // ceiling per address for minting new tokens
    mapping(address => uint256) public ceilings;

    // Minted amount per address to track the ceiling
    mapping(address => uint256) public mintedAmounts;

    // weth/ludus pair address
    address public wethPair;

    constructor(address uniswapV2Factory_, address weth_) public {
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);

        wethPair = IUniswapV2Factory(uniswapV2Factory_).createPair(
            address(this),
            weth_
        );
    }

    // A modifier which checks that the caller has the minter role.
    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "Ludus: only minter");
        _;
    }

    // A modifier which checks that the caller has the admin role.
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Ludus: only admin");
        _;
    }

    // mint amount_ to recipient_.
    function mint(address recipient_, uint256 amount_)
        external
        override
        onlyMinter
    {
        uint256 totalMinted = mintedAmounts[msg.sender].add(amount_);
        require(
            totalMinted <= ceilings[msg.sender],
            "Ludus: Ceiling was breached."
        );
        mintedAmounts[msg.sender] = totalMinted;
        _mint(recipient_, amount_);
    }

    // Max ceiling_ amount that minter_ can mint.
    function setCeiling(address minter_, uint256 ceiling_) external onlyAdmin {
        ceilings[minter_] = ceiling_;
    }

    // Max ceiling_ amount that to_ can mint.
    function getCeiling(address minter_) external view returns (uint256) {
        return ceilings[minter_];
    }
}