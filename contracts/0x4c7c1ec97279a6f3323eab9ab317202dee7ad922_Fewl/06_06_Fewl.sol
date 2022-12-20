// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Fewl is ERC20, Ownable {
    constructor() ERC20("FEWL", "FEWL") {}

    /** PUBLIC VARS */
    uint256 public MAX_TOKENS = 1_000_000_000 ether;
    uint256 public tokensMinted;
    uint256 public tokensBurned;

    /** PRIVATE VARS */
    // Store admins to allow them to call certain functions
    mapping(address => bool) private _admins;

    /** MODIFIERS */
    modifier onlyAdmin() {
        require(_admins[_msgSender()], "FEWL: Only admins can call this");
        _;
    }

    /** ONLY ADMIN FUNCTIONS */
    function mint(address to, uint256 amount) external onlyAdmin {
        require(tokensMinted + amount <= MAX_TOKENS, "FEWL: All tokens minted");
        tokensMinted += amount;
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyAdmin {
        tokensBurned += amount;
        _burn(from, amount);
    }

    /** ONLY OWNER FUNCTIONS */
    function addAdmin(address addr) external onlyOwner {
        _admins[addr] = true;
    }

    function isAdmin(address addr) external view returns (bool) {
        return _admins[addr];
    }

    function removeAdmin(address addr) external onlyOwner {
        delete _admins[addr];
    }
}