pragma solidity =0.5.16;

import "./BStorage.sol";
import "./PoolToken.sol";

contract BAllowance is PoolToken, BStorage {
    event BorrowApproval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function _borrowApprove(
        address owner,
        address spender,
        uint256 value
    ) private {
        borrowAllowance[owner][spender] = value;
        emit BorrowApproval(owner, spender, value);
    }

    function borrowApprove(address spender, uint256 value)
        external
        returns (bool)
    {
        _borrowApprove(msg.sender, spender, value);
        return true;
    }

    function _checkBorrowAllowance(
        address owner,
        address spender,
        uint256 value
    ) internal {
        uint256 _borrowAllowance = borrowAllowance[owner][spender];
        if (spender != owner && _borrowAllowance != uint256(-1)) {
            require(_borrowAllowance >= value, "Tarot: BORROW_NOT_ALLOWED");
            borrowAllowance[owner][spender] = _borrowAllowance - value;
        }
    }

    // keccak256("BorrowPermit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant BORROW_PERMIT_TYPEHASH =
        0xf6d86ed606f871fa1a557ac0ba607adce07767acf53f492fb215a1a4db4aea6f;

    function borrowPermit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        _checkSignature(
            owner,
            spender,
            value,
            deadline,
            v,
            r,
            s,
            BORROW_PERMIT_TYPEHASH
        );
        _borrowApprove(owner, spender, value);
    }
}