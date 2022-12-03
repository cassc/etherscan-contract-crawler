// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./IAnySwapV5ERC20.sol";

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IAnySwapV5ERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function callOptionalReturn(IAnySwapV5ERC20 token, bytes memory data)
        private
    {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

struct feeSystem {
    uint256 val;
    uint256 valDenomination;
}

contract WithdrawWrap is Ownable {
    using SafeERC20 for IAnySwapV5ERC20;
    mapping(address => bool) private authorizes;

    address public AnyswapV5ERC20Address;
    uint256 public threshold;
    feeSystem public fee;

    event Warning(bytes _requestId, uint256 _remain);
    event WithdrawWrapper(bytes _requestId, address[] _to, uint256[] _amounts);

    constructor(
        address _AnyswapV5ERC20Address,
        uint256 _threshold,
        feeSystem memory _fee
    ) {
        AnyswapV5ERC20Address = _AnyswapV5ERC20Address;
        authorizes[msg.sender] = true;
        threshold = _threshold;
        fee = _fee;
    }

    function withdrawWrapper(
        bytes memory _requestId,
        address[] calldata _to,
        uint256[] calldata _amounts,
        uint256 _totalAmount
    ) external {
        require(authorizes[msg.sender], "Invalid Authorizer");
        require(_to.length == _amounts.length, "Invalid Parameter");

        uint256 balance = IAnySwapV5ERC20(AnyswapV5ERC20Address).balanceOf(
            address(this)
        );

        require(balance >= _totalAmount, "Invalid Total Amount");

        uint256 totalAmount;
        for (uint256 i = 0; i < _to.length; ) {
            uint256 remainAmount;
            remainAmount =
                _amounts[i] -
                (_amounts[i] * fee.val) /
                10**fee.valDenomination;
            totalAmount += remainAmount;
            IAnySwapV5ERC20(AnyswapV5ERC20Address).safeTransfer(
                _to[i],
                remainAmount
            );
            unchecked {
                ++i;
            }
        }

        if (balance - totalAmount <= threshold)
            emit Warning(_requestId, balance - totalAmount);
        emit WithdrawWrapper(_requestId, _to, _amounts);
    }

    function updateThreshold(uint256 _threshold) public onlyOwner {
        threshold = _threshold;
    }

    function updateAuthorize(address _owner, bool _allowance) public onlyOwner {
        authorizes[_owner] = _allowance;
    }

    function updateFee(feeSystem calldata _fee) public onlyOwner {
        fee = _fee;
    }
}