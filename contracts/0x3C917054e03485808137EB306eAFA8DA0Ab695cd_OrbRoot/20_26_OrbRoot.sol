// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../utils/Withdrawable.sol";
import "../utils/ERC20Freezable.sol";
import "../utils/NativeMetaTransaction.sol";
import "../utils/IMintableERC20.sol";

contract OrbRoot is
    Ownable,
    AccessControlEnumerable,
    ERC20Burnable,
    ERC20Pausable,
    Withdrawable,
    ERC20Freezable,
    NativeMetaTransaction,
    IMintableERC20
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");

    event Burn(address indexed from, uint256 value);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(WITHDRAWER_ROLE, _msgSender());
        _setupRole(PREDICATE_ROLE, address(0x9923263fA127b3d1484cFD649df8f1831c2A74e4));
    }

    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }

    function _msgSender() internal view override returns (address) {
        return msgSender();
    }

    function mint(address to, uint256 amount) external override {
        require(hasRole(PREDICATE_ROLE, _msgSender()), "mint: must have PREDICATE_ROLE to mint");
        _mint(to, amount);
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable, ERC20Freezable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function freezeAccount(address account, uint256 amount) public {
        require(hasRole(PAUSER_ROLE, _msgSender()), "freeze: must have pauser role to freeze");
        _freezeAccount(account, amount);
    }

    function burn(uint256 amount) public override {
        _transfer(_msgSender(), address(0x000000000000000000000000000000000000dEaD), amount);
        emit Burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public override {
        _spendAllowance(account, _msgSender(), amount);
        _transfer(account, address(0x000000000000000000000000000000000000dEaD), amount);
        emit Burn(account, amount);
    }

    function totalBurned() public view returns (uint256) {
        return balanceOf(address(0x000000000000000000000000000000000000dEaD));
    }
}