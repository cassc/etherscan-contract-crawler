// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "../base/AdapterBase.sol";
import "./VerifierBasic.sol";
import "../../interfaces/IWETH.sol";
import "../../core/controller/IAccount.sol";

/*
Users deposit some eth/steth as gas fee to support automatic contract calls in the background
*/
contract Verifier is VerifierBasic {
    function getMessageHash(
        address _account,
        uint256 _amount,
        bool _access,
        uint256 _deadline,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_account, _amount, _access, _deadline, _nonce)
            );
    }

    function verify(
        address _signer,
        address _account,
        uint256 _amount,
        bool _access,
        uint256 _deadline,
        bytes memory signature
    ) internal returns (bool) {
        require(_deadline >= block.timestamp, "Signature expired");
        bytes32 messageHash = getMessageHash(
            _account,
            _amount,
            _access,
            _deadline,
            nonces[_account]++
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }
}

contract FeeBoxETH is Verifier, AdapterBase {
    using SafeERC20 for IERC20;

    event FeeBoxETHDeposit(
        address account,
        uint256 amount,
        uint256 consumedAmount
    );
    event FeeBoxETHWithdraw(
        address account,
        uint256 amount,
        uint256 consumedAmount
    );

    address public balanceController;
    address public feeReceiver;
    mapping(address => uint256) public ethBalance;

    constructor(address _adapterManager, address _timelock)
        AdapterBase(_adapterManager, _timelock, "FeeBoxETH")
    {}

    function initialize(address _balanceController, address _feeReceiver)
        external
        onlyTimelock
    {
        balanceController = _balanceController;
        feeReceiver = _feeReceiver;
    }

    modifier onlySigner() {
        require(balanceController == msg.sender, "!Signer");
        _;
    }

    function setAdapterManager(address newAdapterManger) external onlyTimelock {
        ADAPTER_MANAGER = newAdapterManger;
    }

    function setBalance(address[] memory users, uint256[] memory balance)
        external
        onlySigner
    {
        require(users.length == balance.length, "length error!");
        for (uint256 i = 0; i < users.length; i++) {
            ethBalance[users[i]] = balance[i];
        }
    }

    function paymentCheck(address account, uint256 consumedAmount)
        external
        onlySigner
    {
        require(ethBalance[account] >= consumedAmount);
        ethBalance[account] -= consumedAmount;
        safeTransferETH(feeReceiver, consumedAmount);
    }

    function depositWithPermit(address account, bytes calldata encodedData)
        external
        payable
        onlyAdapterManager
    {
        require(tx.origin == IAccount(account).owner(), "!EOA");
        (
            uint256 amount,
            uint256 consumedAmount,
            bool access,
            uint256 deadline,
            bytes memory signature
        ) = abi.decode(encodedData, (uint256, uint256, bool, uint256, bytes));
        require(access, "Not deposit method.");
        require(
            verify(
                balanceController,
                account,
                consumedAmount,
                access,
                deadline,
                signature
            ),
            "Verify failed!"
        );
        if (amount != 0) {
            pullTokensIfNeeded(wethAddr, account, amount);
            IWETH(wethAddr).withdraw(amount);
        }
        require(
            ethBalance[account] + amount + msg.value >= consumedAmount,
            "Insolvent!"
        );

        ethBalance[account] =
            ethBalance[account] +
            amount +
            msg.value -
            consumedAmount;
        if (consumedAmount != 0) {
            safeTransferETH(feeReceiver, consumedAmount);
        }
        emit FeeBoxETHDeposit(account, amount + msg.value, consumedAmount);
    }

    function withdrawWithPermit(address account, bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (
            bool isNative,
            uint256 amount,
            uint256 consumedAmount,
            bool access,
            uint256 deadline,
            bytes memory signature
        ) = abi.decode(
                encodedData,
                (bool, uint256, uint256, bool, uint256, bytes)
            );
        require(!access, "Not withdraw method.");
        require(
            verify(
                balanceController,
                account,
                consumedAmount,
                access,
                deadline,
                signature
            ),
            "Verify failed!"
        );

        require(ethBalance[account] >= consumedAmount + amount, "Insolvent!");
        ethBalance[account] = ethBalance[account] - amount - consumedAmount;
        if (isNative) {
            safeTransferETH(account, amount);
        } else {
            IWETH(wethAddr).deposit{value: amount}();
            IERC20(wethAddr).safeTransfer(account, amount);
        }
        if (consumedAmount != 0) {
            safeTransferETH(feeReceiver, consumedAmount);
        }

        emit FeeBoxETHWithdraw(account, amount, consumedAmount);
    }
}