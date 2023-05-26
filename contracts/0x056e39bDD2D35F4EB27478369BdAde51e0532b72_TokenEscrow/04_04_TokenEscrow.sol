//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import "./BoringBatchable.sol";

error IS_ACTIVE();
error NOT_ACTIVE();
error INVALID_TIME();

contract TokenEscrow is BoringBatchable {
    using SafeTransferLib for ERC20;

    event Create(
        address token,
        address payer,
        address payee,
        uint256 amount,
        uint256 release,
        bytes32 id
    );

    event Redeem(
        address token,
        address payer,
        address payee,
        uint256 amount,
        uint256 release,
        bytes32 id
    );

    event Revoke(
        address token,
        address payer,
        address payee,
        uint256 amount,
        uint256 release,
        bytes32 id
    );

    mapping(bytes32 => uint256) public active;

    function calculateEscrowHash(
        address _token,
        address _payer,
        address _payee,
        uint256 _amount,
        uint256 _release
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_token, _payer, _payee, _amount, _release)
            );
    }

    function create(
        address _token,
        address _payee,
        uint256 _amount,
        uint256 _release
    ) external {
        bytes32 id = calculateEscrowHash(
            _token,
            msg.sender,
            _payee,
            _amount,
            _release
        );
        if (active[id] == 1) revert IS_ACTIVE();

        active[id] = 1;
        ERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        emit Create(_token, msg.sender, _payee, _amount, _release, id);
    }

    function redeem(
        address _token,
        address _payer,
        address _payee,
        uint256 _amount,
        uint256 _release
    ) external {
        bytes32 id = calculateEscrowHash(
            _token,
            _payer,
            _payee,
            _amount,
            _release
        );
        if (active[id] == 0) revert NOT_ACTIVE();
        if (_release > block.timestamp) revert INVALID_TIME();
        active[id] = 0;
        ERC20(_token).safeTransfer(_payee, _amount);

        emit Redeem(_token, _payer, _payee, _amount, _release, id);
    }

    function revoke(
        address _token,
        address _payee,
        uint256 _amount,
        uint256 _release
    ) external {
        bytes32 id = calculateEscrowHash(
            _token,
            msg.sender,
            _payee,
            _amount,
            _release
        );
        if (active[id] == 0) revert NOT_ACTIVE();
        active[id] = 0;
        ERC20(_token).safeTransfer(msg.sender, _amount);

        emit Revoke(_token, msg.sender, _payee, _amount, _release, id);
    }
}