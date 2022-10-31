// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import "../controller/IAccount.sol";
import "../verifier/IERC2612Verifier.sol";
import "../verifier/ITokenApprovalVerifier.sol";

contract Automation {
    address public immutable verifier;
    address public immutable tokenApprovalVerifier;
    address public immutable loanProvider;
    mapping(address => address) public customizedLoanProviders;

    event SetLoanProvider(address account, address loanProvider);

    constructor(
        address _verifier,
        address _tokenApprovalVerifier,
        address _loanProvider
    ) {
        verifier = _verifier;
        tokenApprovalVerifier = _tokenApprovalVerifier;
        loanProvider = _loanProvider;
    }

    function setLoanProvider(address account, address customizedLoanProvider)
        external
    {
        require(IAccount(account).owner() == msg.sender, "Owner check failed.");
        customizedLoanProviders[account] = customizedLoanProvider;
        emit SetLoanProvider(account, customizedLoanProvider);
    }

    function getLoanProvider(address account) public view returns (address) {
        return
            customizedLoanProviders[account] == address(0)
                ? loanProvider
                : customizedLoanProviders[account];
    }

    function _executeVerifyBasic(address account, uint256 operation)
        internal
        view
    {
        require(
            IERC2612Verifier(verifier).isTxPermitted(
                account,
                msg.sender,
                operation
            ),
            "denied"
        );
    }

    function _executeVerifyAdapter(address account, bytes memory callBytes)
        internal
        view
    {
        address adapter;
        assembly {
            adapter := mload(add(callBytes, 32))
        }
        require(
            IERC2612Verifier(verifier).isTxPermitted(
                account,
                msg.sender,
                adapter
            ),
            "denied"
        );
    }

    function _executeVerifyApproval(address account, address spender)
        internal
        view
    {
        require(
            ITokenApprovalVerifier(tokenApprovalVerifier).isWhitelisted(
                account,
                spender
            ),
            "denied"
        );
    }

    function _autoExecute(
        address account,
        bytes calldata callBytes,
        bool callType
    ) internal returns (bytes memory returnData) {
        _executeVerifyAdapter(account, callBytes);
        returnData = IAccount(account).executeOnAdapter(callBytes, callType);
    }

    function autoExecute(
        address account,
        bytes calldata callBytes,
        bool callType
    ) external returns (bytes memory) {
        return _autoExecute(account, callBytes, callType);
    }

    function autoExecuteWithPermit(
        address account,
        bytes calldata callBytes,
        bool callType,
        bytes32 approvalType,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bytes memory) {
        IERC2612Verifier(verifier).permit(
            account,
            msg.sender,
            approvalType,
            deadline,
            v,
            r,
            s
        );
        return _autoExecute(account, callBytes, callType);
    }

    function autoExecuteMultiCall(
        address account,
        bool[] memory callType,
        bytes[] memory callBytes,
        bool[] memory isNeedCallback
    ) external {
        require(
            callType.length == callBytes.length &&
                callBytes.length == isNeedCallback.length
        );
        for (uint256 i = 0; i < callType.length; i++) {
            _executeVerifyAdapter(account, callBytes[i]);
        }
        IAccount(payable(account)).multiCall(
            callType,
            callBytes,
            isNeedCallback
        );
    }

    function autoApprove(
        address account,
        address token,
        address spender,
        uint256 amount
    ) external {
        _executeVerifyBasic(account, 0);
        _executeVerifyApproval(account, spender);
        IAccount(payable(account)).approve(token, spender, amount);
    }

    function autoApproveWithPermit(
        address account,
        address[] memory tokens,
        address[] memory spenders,
        uint256[] memory amounts,
        address[] memory permitSpenders,
        bool enable,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(
            tokens.length == spenders.length &&
                spenders.length == amounts.length,
            "approve length error."
        );
        _executeVerifyBasic(account, 0);
        ITokenApprovalVerifier(tokenApprovalVerifier).permit(
            account,
            permitSpenders,
            enable,
            deadline,
            v,
            r,
            s
        );
        for (uint256 i = 0; i < spenders.length; i++) {
            _executeVerifyApproval(account, spenders[i]);
        }
        IAccount(payable(account)).approveTokens(tokens, spenders, amounts);
    }

    function doFlashLoan(
        address account,
        address token,
        uint256 amount,
        bytes calldata payload
    ) external {
        _executeVerifyBasic(account, 1);
        (
            bool[] memory _callType,
            bytes[] memory _callBytes,
            bool[] memory _isNeedCallback
        ) = abi.decode(payload, (bool[], bytes[], bool[]));
        require(
            _callType.length == _callBytes.length &&
                _callBytes.length == _isNeedCallback.length
        );
        for (uint256 i = 0; i < _callBytes.length; i++) {
            _executeVerifyAdapter(account, _callBytes[i]);
        }
        IERC3156FlashLender(getLoanProvider(account)).flashLoan(
            IERC3156FlashBorrower(account),
            token,
            amount,
            payload
        );
    }

    function autoExecuteOnSubAccount(
        address account,
        address subAccount,
        bytes calldata callArgs,
        uint256 amountETH
    ) external {
        _executeVerifyBasic(account, 2);
        require(Ownable(subAccount).owner() == account, "invalid account!");
        IAccount(payable(account)).callOnSubAccount(
            subAccount,
            callArgs,
            amountETH
        );
    }

    function doFlashLoanOnSubAccount(
        address account,
        address subAccount,
        address token,
        uint256 amount,
        bytes calldata payload
    ) external {
        _executeVerifyBasic(account, 3);
        require(Ownable(subAccount).owner() == account, "invalid account!");
        IERC3156FlashLender(getLoanProvider(account)).flashLoan(
            IERC3156FlashBorrower(subAccount),
            token,
            amount,
            payload
        );
    }
}