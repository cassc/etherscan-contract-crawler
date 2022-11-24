// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "../base/AdapterBase.sol";
import "./VerifierBasic.sol";
import "../../interfaces/lido/ILido.sol";
import "../../core/controller/IAccount.sol";

/*
Users deposit some steth as gas fee to support automatic contract calls in the background
*/
contract Verifier is VerifierBasic {
    function getMessageHash(
        address _account,
        address _token,
        uint256 _amount,
        bool _access,
        uint256 _deadline,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _account,
                    _token,
                    _amount,
                    _access,
                    _deadline,
                    _nonce
                )
            );
    }

    function verify(
        address _signer,
        address _account,
        address _token,
        uint256 _amount,
        bool _access,
        uint256 _deadline,
        bytes memory signature
    ) internal returns (bool) {
        require(_deadline >= block.timestamp, "Signature expired");
        bytes32 messageHash = getMessageHash(
            _account,
            _token,
            _amount,
            _access,
            _deadline,
            nonces[_account]++
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }
}

contract FeeBoxStETH is Verifier, AdapterBase {
    using SafeERC20 for IERC20;

    event FeeBoxStETHDeposit(
        address account,
        uint256 amount,
        uint256 consumedAmount
    );
    event FeeBoxStETHWithdraw(
        address account,
        uint256 amount,
        uint256 consumedAmount
    );

    address public balanceController;
    address public feeReceiver;
    address public stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    mapping(address => uint256) public tokenBalance;

    constructor(address _adapterManager, address _timelock)
        AdapterBase(_adapterManager, _timelock, "feeBoxSTETH")
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
            tokenBalance[users[i]] = balance[i];
        }
    }

    function _paymentCheck(address account, uint256 consumedAmount) internal {
        if (consumedAmount != 0) {
            require(tokenBalance[account] >= consumedAmount, "Insolvent!");
            tokenBalance[account] -= consumedAmount;
            IERC20(stETH).safeTransfer(feeReceiver, consumedAmount);
        }
    }

    function paymentCheck(address account, uint256 consumedAmount)
        external
        onlySigner
    {
        _paymentCheck(account, consumedAmount);
    }

    function depositWithPermit(address account, bytes calldata encodedData)
        external
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
                stETH,
                consumedAmount,
                access,
                deadline,
                signature
            ),
            "Verify failed!"
        );

        pullTokensIfNeeded(stETH, account, amount);
        tokenBalance[account] += amount;
        _paymentCheck(account, consumedAmount);
        emit FeeBoxStETHDeposit(account, amount, consumedAmount);
    }

    function withdrawWithPermit(address account, bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (
            uint256 amount,
            uint256 consumedAmount,
            bool access,
            uint256 deadline,
            bytes memory signature
        ) = abi.decode(encodedData, (uint256, uint256, bool, uint256, bytes));
        require(!access, "Not withdraw method.");
        require(
            verify(
                balanceController,
                account,
                stETH,
                consumedAmount,
                access,
                deadline,
                signature
            ),
            "Verify failed!"
        );

        require(tokenBalance[account] >= amount, "Insolvent!");
        tokenBalance[account] -= amount;
        _paymentCheck(account, consumedAmount);
        IERC20(stETH).safeTransfer(account, amount);
        emit FeeBoxStETHWithdraw(account, amount, consumedAmount);
    }
}