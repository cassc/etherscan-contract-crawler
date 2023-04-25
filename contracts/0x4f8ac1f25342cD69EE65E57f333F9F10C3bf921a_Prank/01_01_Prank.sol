// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract ERC20 {
    error TotalSupplyOverflow();

    error AllowanceOverflow();

    error AllowanceUnderflow();

    error InsufficientBalance();

    error InsufficientAllowance();

    error InvalidPermit();

    error PermitExpired();

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    uint256 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    uint256 private constant _APPROVAL_EVENT_SIGNATURE =
        0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925;

    uint256 private constant _TOTAL_SUPPLY_SLOT = 0x05345cdf77eb68f44c;

    uint256 private constant _BALANCE_SLOT_SEED = 0x87a211a2;

    uint256 private constant _ALLOWANCE_SLOT_SEED = 0x7f5e9f20;

    uint256 private constant _NONCES_SLOT_SEED = 0x38377508;

    function name() public view virtual returns (string memory);

    function symbol() public view virtual returns (string memory);

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual returns (uint256 result) {
        assembly {
            result := sload(_TOTAL_SUPPLY_SLOT)
        }
    }

    function balanceOf(
        address owner
    ) public view virtual returns (uint256 result) {
        assembly {
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, owner)
            result := sload(keccak256(0x0c, 0x20))
        }
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual returns (uint256 result) {
        assembly {
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, owner)
            result := sload(keccak256(0x0c, 0x34))
        }
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual returns (bool) {
        assembly {
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, caller())
            sstore(keccak256(0x0c, 0x34), amount)

            mstore(0x00, amount)
            log3(
                0x00,
                0x20,
                _APPROVAL_EVENT_SIGNATURE,
                caller(),
                shr(96, mload(0x2c))
            )
        }
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 difference
    ) public virtual returns (bool) {
        assembly {
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, caller())
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowanceBefore := sload(allowanceSlot)

            let allowanceAfter := add(allowanceBefore, difference)

            if lt(allowanceAfter, allowanceBefore) {
                mstore(0x00, 0xf9067066)
                revert(0x1c, 0x04)
            }

            sstore(allowanceSlot, allowanceAfter)

            mstore(0x00, allowanceAfter)
            log3(
                0x00,
                0x20,
                _APPROVAL_EVENT_SIGNATURE,
                caller(),
                shr(96, mload(0x2c))
            )
        }
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 difference
    ) public virtual returns (bool) {
        assembly {
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, caller())
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowanceBefore := sload(allowanceSlot)

            if lt(allowanceBefore, difference) {
                mstore(0x00, 0x8301ab38)
                revert(0x1c, 0x04)
            }

            let allowanceAfter := sub(allowanceBefore, difference)
            sstore(allowanceSlot, allowanceAfter)

            mstore(0x00, allowanceAfter)
            log3(
                0x00,
                0x20,
                _APPROVAL_EVENT_SIGNATURE,
                caller(),
                shr(96, mload(0x2c))
            )
        }
        return true;
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        _beforeTokenTransfer(msg.sender, to, amount);

        assembly {
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, caller())
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalance := sload(fromBalanceSlot)

            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8)
                revert(0x1c, 0x04)
            }

            sstore(fromBalanceSlot, sub(fromBalance, amount))

            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)

            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))

            mstore(0x20, amount)
            log3(
                0x20,
                0x20,
                _TRANSFER_EVENT_SIGNATURE,
                caller(),
                shr(96, mload(0x0c))
            )
        }
        _afterTokenTransfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        _beforeTokenTransfer(from, to, amount);

        assembly {
            let from_ := shl(96, from)

            mstore(0x20, caller())
            mstore(0x0c, or(from_, _ALLOWANCE_SLOT_SEED))
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowance_ := sload(allowanceSlot)

            if iszero(eq(allowance_, not(0))) {
                if gt(amount, allowance_) {
                    mstore(0x00, 0x13be252b)
                    revert(0x1c, 0x04)
                }

                sstore(allowanceSlot, sub(allowance_, amount))
            }

            mstore(0x0c, or(from_, _BALANCE_SLOT_SEED))
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalance := sload(fromBalanceSlot)

            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8)
                revert(0x1c, 0x04)
            }

            sstore(fromBalanceSlot, sub(fromBalance, amount))

            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)

            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))

            mstore(0x20, amount)
            log3(
                0x20,
                0x20,
                _TRANSFER_EVENT_SIGNATURE,
                shr(96, from_),
                shr(96, mload(0x0c))
            )
        }
        _afterTokenTransfer(from, to, amount);
        return true;
    }

    function nonces(
        address owner
    ) public view virtual returns (uint256 result) {
        assembly {
            mstore(0x0c, _NONCES_SLOT_SEED)
            mstore(0x00, owner)
            result := sload(keccak256(0x0c, 0x20))
        }
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        bytes32 domainSeparator = DOMAIN_SEPARATOR();

        assembly {
            let m := mload(0x40)

            if gt(timestamp(), deadline) {
                mstore(0x00, 0x1a15a3cc)
                revert(0x1c, 0x04)
            }

            owner := shr(96, shl(96, owner))
            spender := shr(96, shl(96, spender))

            mstore(0x0c, _NONCES_SLOT_SEED)
            mstore(0x00, owner)
            let nonceSlot := keccak256(0x0c, 0x20)
            let nonceValue := sload(nonceSlot)

            sstore(nonceSlot, add(nonceValue, 1))

            mstore(
                m,
                0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9
            )
            mstore(add(m, 0x20), owner)
            mstore(add(m, 0x40), spender)
            mstore(add(m, 0x60), value)
            mstore(add(m, 0x80), nonceValue)
            mstore(add(m, 0xa0), deadline)

            mstore(0, 0x1901)
            mstore(0x20, domainSeparator)
            mstore(0x40, keccak256(m, 0xc0))

            mstore(0, keccak256(0x1e, 0x42))
            mstore(0x20, and(0xff, v))
            mstore(0x40, r)
            mstore(0x60, s)
            pop(staticcall(gas(), 1, 0, 0x80, 0x20, 0x20))

            if iszero(eq(mload(returndatasize()), owner)) {
                mstore(0x00, 0xddafbaef)
                revert(0x1c, 0x04)
            }

            mstore(0x40, or(shl(160, _ALLOWANCE_SLOT_SEED), spender))
            sstore(keccak256(0x2c, 0x34), value)

            log3(add(m, 0x60), 0x20, _APPROVAL_EVENT_SIGNATURE, owner, spender)
            mstore(0x40, m)
            mstore(0x60, 0)
        }
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32 result) {
        assembly {
            result := mload(0x40)
        }

        bytes32 nameHash = keccak256(bytes(name()));

        assembly {
            let m := result

            mstore(
                m,
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f
            )
            mstore(add(m, 0x20), nameHash)

            mstore(
                add(m, 0x40),
                0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6
            )
            mstore(add(m, 0x60), chainid())
            mstore(add(m, 0x80), address())
            result := keccak256(m, 0xa0)
        }
    }

    function _mint(address to, uint256 amount) internal virtual {
        _beforeTokenTransfer(address(0), to, amount);

        assembly {
            let totalSupplyBefore := sload(_TOTAL_SUPPLY_SLOT)
            let totalSupplyAfter := add(totalSupplyBefore, amount)

            if lt(totalSupplyAfter, totalSupplyBefore) {
                mstore(0x00, 0xe5cfe957)
                revert(0x1c, 0x04)
            }

            sstore(_TOTAL_SUPPLY_SLOT, totalSupplyAfter)

            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)

            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))

            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, 0, shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        _beforeTokenTransfer(from, address(0), amount);

        assembly {
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, from)
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalance := sload(fromBalanceSlot)

            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8)
                revert(0x1c, 0x04)
            }

            sstore(fromBalanceSlot, sub(fromBalance, amount))

            sstore(_TOTAL_SUPPLY_SLOT, sub(sload(_TOTAL_SUPPLY_SLOT), amount))

            mstore(0x00, amount)
            log3(
                0x00,
                0x20,
                _TRANSFER_EVENT_SIGNATURE,
                shr(96, shl(96, from)),
                0
            )
        }
        _afterTokenTransfer(from, address(0), amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        _beforeTokenTransfer(from, to, amount);

        assembly {
            let from_ := shl(96, from)

            mstore(0x0c, or(from_, _BALANCE_SLOT_SEED))
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalance := sload(fromBalanceSlot)

            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8)
                revert(0x1c, 0x04)
            }

            sstore(fromBalanceSlot, sub(fromBalance, amount))

            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)

            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))

            mstore(0x20, amount)
            log3(
                0x20,
                0x20,
                _TRANSFER_EVENT_SIGNATURE,
                shr(96, from_),
                shr(96, mload(0x0c))
            )
        }
        _afterTokenTransfer(from, to, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        assembly {
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, owner)
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowance_ := sload(allowanceSlot)

            if iszero(eq(allowance_, not(0))) {
                if gt(amount, allowance_) {
                    mstore(0x00, 0x13be252b)
                    revert(0x1c, 0x04)
                }

                sstore(allowanceSlot, sub(allowance_, amount))
            }
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        assembly {
            let owner_ := shl(96, owner)

            mstore(0x20, spender)
            mstore(0x0c, or(owner_, _ALLOWANCE_SLOT_SEED))
            sstore(keccak256(0x0c, 0x34), amount)

            mstore(0x00, amount)
            log3(
                0x00,
                0x20,
                _APPROVAL_EVENT_SIGNATURE,
                shr(96, owner_),
                shr(96, mload(0x2c))
            )
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

abstract contract Ownable {
    error Unauthorized();

    error NewOwnerIsZeroAddress();

    error NoHandoverRequest();

    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );

    event OwnershipHandoverRequested(address indexed pendingOwner);

    event OwnershipHandoverCanceled(address indexed pendingOwner);

    uint256 private constant _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE =
        0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0;

    uint256 private constant _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE =
        0xdbf36a107da19e49527a7176a1babf963b4b0ff8cde35ee35d6cd8f1f9ac7e1d;

    uint256 private constant _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE =
        0xfa7b8eab7da67f412cc9575ed43464468f9bfbae89d1675917346ca6d8fe3c92;

    uint256 private constant _OWNER_SLOT_NOT = 0x8b78c6d8;

    uint256 private constant _HANDOVER_SLOT_SEED = 0x389a75e1;

    function _initializeOwner(address newOwner) internal virtual {
        assembly {
            newOwner := shr(96, shl(96, newOwner))

            sstore(not(_OWNER_SLOT_NOT), newOwner)

            log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, 0, newOwner)
        }
    }

    function _setOwner(address newOwner) internal virtual {
        assembly {
            let ownerSlot := not(_OWNER_SLOT_NOT)

            newOwner := shr(96, shl(96, newOwner))

            log3(
                0,
                0,
                _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE,
                sload(ownerSlot),
                newOwner
            )

            sstore(ownerSlot, newOwner)
        }
    }

    function _checkOwner() internal view virtual {
        assembly {
            if iszero(eq(caller(), sload(not(_OWNER_SLOT_NOT)))) {
                mstore(0x00, 0x82b42900)
                revert(0x1c, 0x04)
            }
        }
    }

    function transferOwnership(
        address newOwner
    ) public payable virtual onlyOwner {
        assembly {
            if iszero(shl(96, newOwner)) {
                mstore(0x00, 0x7448fbae)
                revert(0x1c, 0x04)
            }
        }
        _setOwner(newOwner);
    }

    function renounceOwnership() public payable virtual onlyOwner {
        _setOwner(address(0));
    }

    function requestOwnershipHandover() public payable virtual {
        unchecked {
            uint256 expires = block.timestamp + ownershipHandoverValidFor();

            assembly {
                mstore(0x0c, _HANDOVER_SLOT_SEED)
                mstore(0x00, caller())
                sstore(keccak256(0x0c, 0x20), expires)

                log2(
                    0,
                    0,
                    _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE,
                    caller()
                )
            }
        }
    }

    function cancelOwnershipHandover() public payable virtual {
        assembly {
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, caller())
            sstore(keccak256(0x0c, 0x20), 0)

            log2(0, 0, _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE, caller())
        }
    }

    function completeOwnershipHandover(
        address pendingOwner
    ) public payable virtual onlyOwner {
        assembly {
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, pendingOwner)
            let handoverSlot := keccak256(0x0c, 0x20)

            if gt(timestamp(), sload(handoverSlot)) {
                mstore(0x00, 0x6f5e8818)
                revert(0x1c, 0x04)
            }

            sstore(handoverSlot, 0)
        }
        _setOwner(pendingOwner);
    }

    function owner() public view virtual returns (address result) {
        assembly {
            result := sload(not(_OWNER_SLOT_NOT))
        }
    }

    function ownershipHandoverExpiresAt(
        address pendingOwner
    ) public view virtual returns (uint256 result) {
        assembly {
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, pendingOwner)

            result := sload(keccak256(0x0c, 0x20))
        }
    }

    function ownershipHandoverValidFor() public view virtual returns (uint64) {
        return 48 * 3600;
    }

    modifier onlyOwner() virtual {
        _checkOwner();
        _;
    }
}

contract Prank is ERC20, Ownable {
    uint private constant _numTokens = 1_000_000_000_000_000;

    constructor() {
        _initializeOwner(msg.sender);
        _mint(msg.sender, _numTokens * (10 ** 18));
    }

    function name() public view virtual override returns (string memory) {
        return "ITS JUST A PRANK BRO";
    }

    function symbol() public view virtual override returns (string memory) {
        return "PRANK";
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}