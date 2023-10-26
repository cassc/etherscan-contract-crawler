// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
The ResearchToken is a clone contract that is largely an ERC20 and inherits from
ERC20Abstract. The major difference from other ERC20 contracts is that it has an 
important string attribute "researchIdentifier". It also "freeze"s, although 
that is not uncommon.
*/

import "../initializable/Initializable.sol";
import "../abstracts/ERC20Abstract.sol";
import "../interfaces/IERC20Distributor.sol";
import "../token/ResearchTokenInput.sol";

contract ResearchToken is Initializable, ERC20Abstract {
    uint256 public constant erc20_cap = 1000000 * 10 ** 18;
    string public metadata;
    string public researchIdentifier;
    bool public frozen;
    address public minter;

    error AlreadyFrozen();
    error MinterIsZero();
    error SupplyNotEqualToCap();
    error CapExceeded();

    function initialize(
        ResearchTokenInput memory input,
        address minter_
    ) public virtual initializer {
        __ERC20Abstract_unchained(input.name, input.symbol);
        if (minter_ == address(0)) {
            revert MinterIsZero();
        }
        minter = minter_;

        metadata = input.metadata;
        researchIdentifier = input.researchIdentifier;
    }

    function freezeMinting() public {
        // NOTE: This gets called by the Entrypoint right after creation. If
        // that is changed, then this needs another guard.
        if (frozen) {
            revert AlreadyFrozen();
        }
        if (totalSupply() != erc20_cap) {
            revert SupplyNotEqualToCap();
        }
        frozen = true;
    }

    function mint(address account, uint256 amount) public {
        if (frozen) {
            revert AlreadyFrozen();
        }
        if (totalSupply() + amount > erc20_cap) {
            revert CapExceeded();
        }
        _mint(account, amount);
    }
}