pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title ComboToken Contract
/// For more information about this token please visit https://combo.io

contract ComboToken is ERC20, Pausable, Ownable {
    /// Constant token specific fields
    uint256 public constant MAX_SUPPLY = 100000000 * (10 ** 18);

    // minters
    mapping(address => bool) public _minters;

    // white list
    mapping(address => bool) public whiteAccountMap;

    // black list
    mapping(address => bool) public blackAccountMap;

    event AddWhiteAccount(
        address indexed operator,
        address indexed whiteAccount
    );
    event AddBlackAccount(
        address indexed operator,
        address indexed blackAccount
    );

    event DelWhiteAccount(
        address indexed operator,
        address indexed whiteAccount
    );
    event DelBlackAccount(
        address indexed operator,
        address indexed blackAccount
    );

    event Mint(address indexed from, address indexed to, uint256 value);
    event AddMinter(address minter);
    event DelMinter(address minter);

    modifier validAddress(address addr) {
        require(addr != address(0x0), "address is not 0x0");
        require(addr != address(this), "address is not contract");
        _;
    }

    /**
     * CONSTRUCTOR
     *
     * @dev Initialize the Combo Token
     */
    constructor() ERC20("ComboToken", "COMBO") {
        // Pause at start
        super._pause();
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal override {
        if (paused()) {
            // only white list pass
            require(whiteAccountMap[from], "'from' is not in white list");
        } else {
            // check black list
            require(!blackAccountMap[from], "'from' is in black list");
        }
        super._transfer(from, to, value);
    }

    // people will transfer COMBO to contract, fix it
    function withdrawFromContract(
        address _to
    ) public onlyOwner validAddress(_to) returns (bool) {
        uint256 contractBalance = balanceOf(address(this));
        require(contractBalance > 0, "not enough balance");

        _transfer(address(this), _to, contractBalance);
        return true;
    }

    function pause() external onlyOwner {
        super._pause();
    }

    function unpause() external onlyOwner {
        super._unpause();
    }

    /**
     * @dev for mint function
     */
    function mint(
        address account,
        uint256 amount
    ) external validAddress(account) {
        require(_minters[msg.sender], "!minter");

        uint256 newMintSupply = totalSupply() + amount;
        require(newMintSupply <= MAX_SUPPLY, "supply is max!");

        _mint(account, amount);
        emit Mint(address(0), account, amount);
    }

    function addMinter(address _minter) external onlyOwner {
        require(!_minters[_minter], "is minter");
        _minters[_minter] = true;
        emit AddMinter(_minter);
    }

    function removeMinter(address _minter) external onlyOwner {
        require(_minters[_minter], "not is minter");
        _minters[_minter] = false;
        emit DelMinter(_minter);
    }

    function addWhiteAccount(
        address _whiteAccount
    ) public onlyOwner validAddress(_whiteAccount) {
        require(!whiteAccountMap[_whiteAccount], "has in white list");
        whiteAccountMap[_whiteAccount] = true;
        emit AddWhiteAccount(msg.sender, _whiteAccount);
    }

    function delWhiteAccount(
        address _whiteAccount
    ) public onlyOwner validAddress(_whiteAccount) {
        require(whiteAccountMap[_whiteAccount], "not in white list");
        whiteAccountMap[_whiteAccount] = false;
        emit DelWhiteAccount(msg.sender, _whiteAccount);
    }

    function addBlackAccount(
        address _blackAccount
    ) public onlyOwner validAddress(_blackAccount) {
        require(!blackAccountMap[_blackAccount], "has in black list");
        blackAccountMap[_blackAccount] = true;
        emit AddBlackAccount(msg.sender, _blackAccount);
    }

    function delBlackAccount(
        address _blackAccount
    ) public onlyOwner validAddress(_blackAccount) {
        require(blackAccountMap[_blackAccount], "not in black list");
        blackAccountMap[_blackAccount] = false;
        emit DelBlackAccount(msg.sender, _blackAccount);
    }
}