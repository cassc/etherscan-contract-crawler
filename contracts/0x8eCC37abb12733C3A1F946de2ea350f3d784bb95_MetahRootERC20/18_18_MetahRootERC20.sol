// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { NativeMetaTransaction } from "./common/NativeMetaTransaction.sol";
import { AccessControlMixin } from "./common/AccessControlMixin.sol";
import { ContextMixin } from "./common/ContextMixin.sol";
import { IMintableERC20 } from "./IMintableERC20.sol";

/// @title ethereum network에 배포될 ERC20 Meta:h 토큰
contract MetahRootERC20 is ERC20, AccessControlMixin, NativeMetaTransaction, IMintableERC20, ContextMixin {
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _setupContractId("MetahRootERC20");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PREDICATE_ROLE, _msgSender());

        uint256 amount = 10000000000 * (10 ** 18); // 백억
        _mint(_msgSender(), amount);
        _initializeEIP712(name_);
    }

    /**
     * @dev See {IMintableERC20-mint}.
     */
    function mint(address user, uint256 amount) external override only(PREDICATE_ROLE) {
        _mint(user, amount);
    }

    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }
}