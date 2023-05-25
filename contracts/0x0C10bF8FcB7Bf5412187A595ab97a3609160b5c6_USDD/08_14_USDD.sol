// This contract is not supposed to be used in production
// It's strictly for testing purpose

pragma solidity 0.6.6;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IMintableERC20} from "./IMintableERC20.sol";
import {NativeMetaTransaction} from "../../common/NativeMetaTransaction.sol";
import {ContextMixin} from "../../common/ContextMixin.sol";
import {AccessControlMixin} from "../../common/AccessControlMixin.sol";

contract USDD is
    ERC20,
    AccessControlMixin,
    NativeMetaTransaction,
    ContextMixin,
    IMintableERC20
{
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");

    constructor(string memory name_, string memory symbol_, address predicate_)
        public
        ERC20(name_, symbol_)
    {
        _setupContractId("USDD");
        _setupRole(PREDICATE_ROLE, predicate_);

        _initializeEIP712(name_);
    }

    /**
     * @dev See {IMintableERC20-mint}.
     */
    function mint(address user, uint256 amount) external override only(PREDICATE_ROLE) {
        _mint(user, amount);
    }

    function _msgSender()
        internal
        override
        view
        returns (address payable sender)
    {
        return ContextMixin.msgSender();
    }
}