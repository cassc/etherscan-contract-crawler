// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IWithdrawExtension {
    enum WithdrawMode {
        OWNER,
        RECIPIENT,
        ANYONE,
        NOBODY
    }

    error WithdrawWrongRecipient();
    error WithdrawRecipientLocked();
    error WithdrawModeLocked();
    error WithdrawPowerRevoked();

    function setWithdrawRecipient(address _withdrawRecipient) external;

    function lockWithdrawRecipient() external;

    function revokeWithdrawPower() external;

    function setWithdrawMode(WithdrawMode _withdrawMode) external;

    function lockWithdrawMode() external;

    function withdraw(
        address[] calldata claimTokens,
        uint256[] calldata amounts
    ) external;
}

abstract contract WithdrawExtension is
    IWithdrawExtension,
    Initializable,
    Ownable,
    ERC165Storage
{
    // using Address for address;
    using Address for address payable;

    event Withdrawn(address[] claimTokens, uint256[] amounts);

    address public withdrawRecipient;
    bool public withdrawRecipientLocked;
    bool public withdrawPowerRevoked;
    WithdrawMode public withdrawMode;
    bool public withdrawModeLocked;

    /* INTERNAL */

    function __WithdrawExtension_init(
        address _withdrawRecipient,
        WithdrawMode _withdrawMode
    ) internal onlyInitializing {
        __WithdrawExtension_init_unchained(_withdrawRecipient, _withdrawMode);
    }

    function __WithdrawExtension_init_unchained(
        address _withdrawRecipient,
        WithdrawMode _withdrawMode
    ) internal onlyInitializing {
        _registerInterface(type(IWithdrawExtension).interfaceId);

        withdrawRecipient = _withdrawRecipient;
        withdrawMode = _withdrawMode;
    }

    /* ADMIN */

    function setWithdrawRecipient(address _withdrawRecipient)
        external
        onlyOwner
    {
        if (withdrawRecipientLocked) {
            revert WithdrawRecipientLocked();
        }

        withdrawRecipient = _withdrawRecipient;
    }

    function lockWithdrawRecipient() external onlyOwner {
        if (withdrawRecipientLocked) {
            revert WithdrawRecipientLocked();
        }

        withdrawRecipientLocked = true;
    }

    function setWithdrawMode(WithdrawMode _withdrawMode) external onlyOwner {
        if (withdrawModeLocked) {
            revert WithdrawModeLocked();
        }

        withdrawMode = _withdrawMode;
    }

    function lockWithdrawMode() external onlyOwner {
        if (withdrawModeLocked) {
            revert WithdrawModeLocked();
        }

        withdrawModeLocked = true;
    }

    /* PUBLIC */

    function withdraw(
        address[] calldata claimTokens,
        uint256[] calldata amounts
    ) external {
        /**
         * We are using msg.sender for smaller attack surface when evaluating
         * the sender of the function call. If in future we want to handle "withdraw"
         * functionality via meta transactions, we should consider using `_msgSender`
         */
        if (withdrawMode == WithdrawMode.NOBODY) {
            revert WithdrawPowerRevoked();
        } else if (withdrawMode == WithdrawMode.RECIPIENT) {
            if (withdrawRecipient != msg.sender) {
                revert WithdrawWrongRecipient();
            }
        } else if (withdrawMode == WithdrawMode.OWNER) {
            if (owner() != msg.sender) {
                revert WithdrawWrongRecipient();
            }
        }

        if (withdrawPowerRevoked) {
            revert WithdrawPowerRevoked();
        }

        for (uint256 i = 0; i < claimTokens.length; i++) {
            if (claimTokens[i] == address(0)) {
                payable(withdrawRecipient).sendValue(amounts[i]);
            } else {
                IERC20(claimTokens[i]).transfer(withdrawRecipient, amounts[i]);
            }
        }

        emit Withdrawn(claimTokens, amounts);
    }

    function revokeWithdrawPower() external onlyOwner {
        withdrawPowerRevoked = true;
    }
}