// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../utils/AccessControlMixin.sol";
import "../utils/NativeMetaTransaction.sol";
import "../utils/ContextMixin.sol";
import "./IMintableERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract RootWINR is
    ERC20,
    AccessControlMixin,
    NativeMetaTransaction,
    ContextMixin,
    IMintableERC20,
    Pausable
{
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");
    uint256 private immutable _cap = 10000000000 ether;

    constructor() ERC20("JustBet", "WINR") {
        _setupContractId("JustBetRootWINR");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PREDICATE_ROLE, _msgSender());
        _mint(_msgSender(), 1722919230 ether);
        _initializeEIP712("JustBet");
    }

    /**
     * @dev See {IMintableERC20-mint}.
     */
    function mint(address user, uint256 amount)
        external
        override
        only(PREDICATE_ROLE)
    {
        require(totalSupply() + amount <= cap(), "Max supply of WINR reached.");
        _mint(user, amount);
    }

    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }
}