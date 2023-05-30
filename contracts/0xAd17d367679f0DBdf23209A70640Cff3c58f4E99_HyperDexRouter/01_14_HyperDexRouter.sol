// SPDX-License-Identifier: BUSL
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@plasma-fi/contracts/utils/GasStationRecipient.sol";
import "@plasma-fi/contracts/interfaces/ITokensApprover.sol";
import "./interfaces/IHyperDex.sol";
import "./packages/LibBytesV06.sol";
import "./packages/LibProxyRichErrors.sol";
import "./packages/Ownable.sol";

/// @title Plasma Finance proxy contract for 0x proxy
/// @dev A generic proxy contract which extracts a fee before delegation
contract HyperDexRouter is GasStationRecipient, Ownable {
    using LibBytesV06 for bytes;
    using SafeERC20 for IERC20;

    // Native currency address (ETH - 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, MATIC - 0x0000000000000000000000000000000000001010)
    address private nativeAddress;

    address payable public beneficiary;
    address payable public allowanceTarget;
    IHyperDex public hyperDex;
    ITokensApprover public approver;

    uint256 public feeBeneficiary = 5; // 0.05%
    uint256[4] public feeReferrals = [4, 3, 2, 1];  // 0.05%, 0.03%, 0.02%, 0.01%

    event BeneficiaryChanged(address indexed beneficiary);
    event AllowanceTargetChanged(address indexed allowanceTarget);
    event HyperDexChanged(address indexed hyperDex);
    event TokensApproverChanged(address indexed approver);
    event FeePayment(address indexed recipient, address token, uint256 amount);

    /// @dev Construct this contract and specify a fee beneficiary, 0x proxy contract address, and allowance target
    constructor(address _nativeAddress, IHyperDex _hyperDex, address payable _allowanceTarget, address payable _beneficiary, address _gasStation, ITokensApprover _approver) {
        nativeAddress = _nativeAddress;
        hyperDex = _hyperDex;
        allowanceTarget = _allowanceTarget;
        beneficiary = _beneficiary;
        approver = _approver;

        _setGasStation(_gasStation);
    }

    /// @dev Fallback for just receiving ether.
    receive() external payable {}

    /// @dev Set a new MultiSwap proxy contract address
    /// @param _hyperDex New Exchange proxy address
    function setHyperDex(IHyperDex _hyperDex) public onlyOwner {
        require(address(_hyperDex) != address(0), "Invalid HyperDex address");
        hyperDex = _hyperDex;
        emit HyperDexChanged(address(hyperDex));
    }

    /// @dev Set a new new allowance target address
    /// @param _allowanceTarget New allowance target address
    function setAllowanceTarget(address payable _allowanceTarget) public onlyOwner {
        require(_allowanceTarget != address(0), "Invalid allowance target");
        allowanceTarget = _allowanceTarget;
        emit AllowanceTargetChanged(allowanceTarget);
    }

    /// @dev Set a new beneficiary address
    /// @param _beneficiary New beneficiary target address
    function setBeneficiary(address payable _beneficiary) public onlyOwner {
        require(_beneficiary != address(0), "Invalid beneficiary");
        beneficiary = _beneficiary;
        emit BeneficiaryChanged(beneficiary);
    }

    /// @dev Set a new trusted gas station address
    /// @param _gasStation New gas station address
    function setGasStation(address _gasStation) external onlyOwner {
        _setGasStation(_gasStation);
    }

    /// @dev Set a new tokens approver contract address
    /// @param _approver New approver address
    function setApprover(ITokensApprover _approver) external onlyOwner {
        require(address(_approver) != address(0), "Invalid beneficiary");
        approver = _approver;
        emit TokensApproverChanged(address(approver));
    }

    /// @dev Set a referrals fees
    /// @param _feeReferrals New referrals fees values
    function setFeeReferrals(uint256[4] memory _feeReferrals) public onlyOwner {
        feeReferrals = _feeReferrals;
    }

    /// @dev Set a beneficiary fees
    /// @param _feeBeneficiary New beneficiary fees value
    function setFeeBeneficiary(uint256 _feeBeneficiary) public onlyOwner {
        feeBeneficiary = _feeBeneficiary;
    }

    /// @dev Forwards calls to the HyperDex contract and extracts a fee based on provided arguments
    /// @param msgData The byte data representing a swap using the original HyperDex contract. This is either recieved from the Multiswap API directly or we construct it in order to perform a single swap trade
    /// @param inputToken The ERC20 the user is selling. If this is ETH it should be the standard 0xeee ETH address
    /// @param inputAmount The amount of inputToken being sold, without fees
    /// @param outputToken The ERC20 the user is buying. If this is ETH it should be the standard 0xeee ETH address
    /// @param referrals Referral addresses for which interest will be accrued from each exchange.
    function multiRoute(
        bytes calldata msgData,
        address inputToken,
        uint256 inputAmount,
        address outputToken,
        address[4] memory referrals
    ) external payable returns (bytes memory) {
    return _multiRoute(msgData, inputToken, inputAmount, outputToken, referrals);
    }

    function multiRouteWithPermit(
        bytes calldata msgData,
        address inputToken,
        uint256 inputAmount,
        address outputToken,
        address[4] memory referrals,
        bytes calldata approvalData
    ) external payable returns (bytes memory) {
        _permit(inputToken, approvalData);
        return _multiRoute(msgData, inputToken, inputAmount, outputToken, referrals);
    }

    function _multiRoute(
        bytes calldata msgData,
        address inputToken,
        uint256 inputAmount,
        address outputToken,
        address[4] memory referrals
    ) internal returns (bytes memory) {
        // Calculate total fees and send to beneficiary.
        uint256 inputAmountPercent = inputAmount / 10000;
        uint256 fee = inputAmountPercent * feeBeneficiary;
        _payFees(inputToken, fee, beneficiary);
        for (uint256 i = 0; i < referrals.length; i++) {
            if (referrals[i] != address(0) && feeReferrals[i] != 0) {
                uint256 feeReferral = inputAmountPercent * feeReferrals[i];
                fee = fee + feeReferral;
                _payFees(inputToken, feeReferral, payable(referrals[i]));
            }
        }

        // Checking the ETH balance and approve for token transfer
        uint256 value = 0;
        if (inputToken == nativeAddress) {
            require(msg.value == inputAmount + fee, "Insufficient value with fee");
            value = inputAmount;
        } else {
            _sendERC20(IERC20(inputToken), _msgSender(), address(this), inputAmount);
            uint256 allowedAmount = IERC20(inputToken).allowance(address(this), allowanceTarget);
            if (allowedAmount < inputAmount) {
                IERC20(inputToken).safeIncreaseAllowance(allowanceTarget, inputAmount - allowedAmount);
            }
        }

        // Call HyperDex multi swap
        (bool success, bytes memory resultData) = address(hyperDex).call{value : value}(msgData);

        if (!success) {
            _revertWithData(resultData);
        }

        // We send the received tokens back to the sender
        if (outputToken == nativeAddress) {
            if (address(this).balance > 0) {
                _sendETH(payable(_msgSender()), address(this).balance);
            } else {
                _revertWithData(resultData);
            }
        } else {
            uint256 tokenBalance = IERC20(outputToken).balanceOf(address(this));
            if (tokenBalance > 0) {
                IERC20(outputToken).safeTransfer(_msgSender(), tokenBalance);
            } else {
                _revertWithData(resultData);
            }
        }
        _returnWithData(resultData);
    }

    function _permit(address token, bytes calldata approvalData) internal {
        if (approvalData.length > 0 && approver.hasConfigured(token)) {
            (bool success,) = approver.callPermit(token, approvalData);
            require(success, "Permit Method Call Error");
        }
    }

    /// @dev Pay fee to beneficiary
    /// @param token token address to pay fee in, can be ETH
    /// @param amount fee amount to pay
    function _payFees(address token, uint256 amount, address payable recipient) private {
        if (token == nativeAddress) {
            _sendETH(recipient, amount);
        } else {
            _sendERC20(IERC20(token), _msgSender(), recipient, amount);
        }
        emit FeePayment(recipient, token, amount);
    }

    function _sendETH(address payable toAddress, uint256 amount) private {
        if (amount > 0) {
            (bool success,) = toAddress.call{value : amount}("");
            require(success, "Unable to send ETH");
        }
    }

    function _sendERC20(IERC20 token, address fromAddress, address toAddress, uint256 amount) private {
        if (amount > 0) {
            token.safeTransferFrom(fromAddress, toAddress, amount);
        }
    }

    /// @dev Revert with arbitrary bytes.
    /// @param data Revert data.
    function _revertWithData(bytes memory data) private pure {
        assembly {revert(add(data, 32), mload(data))}
    }

    /// @dev Return with arbitrary bytes.
    /// @param data Return data.
    function _returnWithData(bytes memory data) private pure {
        assembly {
            return (add(data, 32), mload(data))
        }
    }
}