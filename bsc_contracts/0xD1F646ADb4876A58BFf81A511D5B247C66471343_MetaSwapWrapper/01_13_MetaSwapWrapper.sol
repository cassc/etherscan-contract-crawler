// SPDX-License-Identifier: UNLICENSED

/**
 * Meta Swap Router Wrapper Contract.
 * Designed by Wallchain in Metaverse.
 */

pragma solidity >=0.8.6;

import "./interfaces/IWChainMaster.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IAllowanceTransfer.sol";
import "./interfaces/ISignatureTransfer.sol";

contract MetaSwapWrapper is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    address private constant ETH_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    event MasterUpgrade(address indexed old, address indexed newMaster);
    event MasterError(string message);
    event MasterError(bytes message);
    event WithdrawAll();
    event WithdrawEth();
    event TargetAdded(address indexed target);
    event TargetRemoved(address indexed target);
    event NonProfitTransaction();
    event MasterUpgradeFailed(address indexed attemptMaster);

    struct WallchainExecutionParams {
        address callTarget; // Target to call. Should create MEV opportunity.
        address approveTarget; // Target to handle token transfers. Usually the same as callTarget.
        bool isPermit; // Is approval handled through Permit.
        bytes targetData; // Target transaction data.
        bytes masterInput; // Generated strategies.
        address[] originator; // Transaction beneficiaries.
        uint256 amount; // Input token amount. Used in targetData for swap.
        IERC20 srcToken; // Input token. Used in targetData for swap.
        IERC20 dstToken; // Output token. Used in targetData for swap.
        uint256 originShare; // Percentage share with the originator of the transaction.
        ISignatureTransfer.PermitTransferFrom permit;
        bytes signature;
    }

    IWChainMaster public wchainMaster;
    EnumerableSet.AddressSet private whitelistedTargets;
    ISignatureTransfer public immutable permit2;

    constructor(
        IWChainMaster _wchainMaster,
        address[] memory _whitelistedTargets,
        ISignatureTransfer _permit2
    ) {
        wchainMaster = _wchainMaster;
        for (uint256 i = 0; i < _whitelistedTargets.length; i++) {
            whitelistedTargets.add(_whitelistedTargets[i]);
        }
        permit2 = _permit2;
    }

    receive() external payable {}

    function whitelistedTargetsLength() external view returns (uint256) {
        return whitelistedTargets.length();
    }

    function whitelistedTargetsAt(uint256 index)
        external
        view
        returns (address)
    {
        return whitelistedTargets.at(index);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function addTarget(address _target) external onlyOwner {
        require(
            !whitelistedTargets.contains(_target),
            "Target is already added"
        );
        require(Address.isContract(_target), "Target must be a contract");

        whitelistedTargets.add(_target);
        emit TargetAdded(_target);
    }

    function removeTarget(address _target) external onlyOwner {
        require(whitelistedTargets.contains(_target), "Target is not present");
        whitelistedTargets.remove(_target);
        emit TargetRemoved(_target);
    }

    function _isETH(IERC20 token) internal pure returns (bool) {
        return (address(token) == ETH_ADDRESS);
    }

    function withdrawEth() external onlyOwner {
        (bool result, ) = msg.sender.call{value: address(this).balance}("");
        require(result, "Failed to withdraw Ether");
        emit WithdrawEth();
    }

    function withdrawAll(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).safeTransfer(
                msg.sender,
                _tokenBalance(tokens[i], address(this))
            );
        }
        emit WithdrawAll();
    }

    function upgradeMaster() external onlyOwner {
        address nextAddress = wchainMaster.nextAddress();
        require(
            Address.isContract(nextAddress),
            "nextAddress must be a contract"
        );
        if (address(wchainMaster) != nextAddress) {
            emit MasterUpgrade(address(wchainMaster), nextAddress);
            wchainMaster = IWChainMaster(nextAddress);
            return;
        }

        emit MasterUpgradeFailed(nextAddress);
    }

    function _tokenBalance(address token, address account)
        internal
        view
        returns (uint256)
    {
        if (_isETH(IERC20(token))) {
            return account.balance;
        } else {
            return IERC20(token).balanceOf(account);
        }
    }

    function maybeApproveERC20(
        IERC20 token,
        uint256 amount,
        address target,
        address callTarget,
        bool isPermit
    ) private {
        // approve router to fetch the funds for swapping
        if (isPermit) {
            if (token.allowance(address(this), target) < amount) {
                token.forceApprove(target, type(uint256).max);
            }

            IAllowanceTransfer(target).approve(
                address(token),
                callTarget,
                uint160(amount),
                uint48(block.timestamp)
            );
        } else {
            if (token.allowance(address(this), target) < amount) {
                token.forceApprove(target, amount);
            }
        }
    }

    function transferTokens(
        address token,
        address payable destination,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (_isETH(IERC20(token))) {
                (bool result, ) = destination.call{value: amount}("");
                require(result, "Native Token Transfer Failed");
            } else {
                IERC20(token).safeTransfer(destination, amount);
            }
        }
    }

    function _processPermits(WallchainExecutionParams memory execution)
        private
    {
        if (!_isETH(execution.srcToken)) {
            maybeApproveERC20(
                execution.srcToken,
                execution.amount,
                execution.approveTarget,
                execution.callTarget,
                execution.isPermit
            );

            permit2.permitTransferFrom(
                execution.permit,
                ISignatureTransfer.SignatureTransferDetails(
                    address(this),
                    execution.amount
                ),
                msg.sender,
                execution.signature
            );
        }
    }

    modifier coverUp(
        bytes calldata masterInput,
        address[] calldata originator,
        uint256 originShare
    ) {
        _;
        // masterInput should be empty if txn is not profitable
        if (masterInput.length > 8) {
            try
                wchainMaster.execute(
                    masterInput,
                    msg.sender,
                    originator,
                    originShare
                )
            {} catch Error(string memory _err) {
                emit MasterError(_err);
            } catch (bytes memory _err) {
                emit MasterError(_err);
            }
        } else {
            emit NonProfitTransaction();
        }
    }

    function _validateInput(WallchainExecutionParams memory execution) private {
        require(
            whitelistedTargets.contains(execution.approveTarget) &&
                whitelistedTargets.contains(execution.callTarget),
            "Target must be whitelisted"
        );
        require(
            execution.callTarget != address(permit2),
            "Call target must not be Permit2"
        );

        if (_isETH(execution.srcToken)) {
            require(
                msg.value != 0,
                "Value must be above 0 when input token is Native Token"
            );
        } else {
            require(
                msg.value == 0,
                "Value must be 0 when input token is not Native Token"
            );
        }
        {
            bytes memory exchangeData = execution.targetData;
            require(
                exchangeData.length != 0,
                "Transaction data must not be empty"
            );
            bytes32 selector;
            assembly {
                selector := mload(add(exchangeData, 32))
            }
            require(
                bytes4(selector) != IERC20.transferFrom.selector,
                "transferFrom not allowed for externalCall"
            );
        }
    }

    /// @return returnAmount The destination token sent to msg.sender
    function swapWithWallchain(WallchainExecutionParams calldata execution)
        external
        payable
        nonReentrant
        whenNotPaused
        coverUp(
            execution.masterInput,
            execution.originator,
            execution.originShare
        )
        returns (uint256 returnAmount)
    {
        _validateInput(execution);

        uint256 balanceBefore = _tokenBalance(
            address(execution.dstToken),
            address(this)
        ) - (_isETH(execution.dstToken) ? msg.value : 0);

        uint256 srcBalanceBefore = _tokenBalance(
            address(execution.srcToken),
            address(this)
        ) - msg.value;

        _processPermits(execution);

        {
            (bool success, ) = execution.callTarget.call{value: msg.value}(
                execution.targetData
            );
            require(success, "Call Target failed");
        }

        uint256 balance = _tokenBalance(
            address(execution.dstToken),
            address(this)
        );

        uint256 srcBalance = _tokenBalance(
            address(execution.srcToken),
            address(this)
        );

        returnAmount = srcBalance - srcBalanceBefore;
        if (srcBalance > srcBalanceBefore) {
            transferTokens(
                address(execution.srcToken),
                payable(msg.sender),
                returnAmount
            );
        }

        returnAmount = balance - balanceBefore;
        if (balance > balanceBefore) {
            transferTokens(
                address(execution.dstToken),
                payable(msg.sender),
                returnAmount
            );
        }
    }
}