pragma solidity ^0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

library BoringERC20 {
    function safeSymbol(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

contract Vesting {
    using SafeMath for uint256;
    using BoringERC20 for IERC20;

    address public gamma;
    address public recipient;
    address public funder;

    modifier onlyFunder() {
        require(msg.sender == funder, "Ownable: caller is not the funder");
        _;
    }

    uint256 public vestingAmount;
    uint256 public vestingBegin;
    uint256 public vestingCliff;
    uint256 public vestingEnd;

    uint256 public lastUpdate;

    constructor(
        address gamma_,
        address recipient_,
        address funder_,
        uint256 vestingAmount_,
        uint256 vestingBegin_,
        uint256 vestingCliff_,
        uint256 vestingEnd_
    ) public {
        require(vestingCliff_ >= vestingBegin_, "TreasuryVester.constructor: cliff is too early");
        require(vestingEnd_ > vestingCliff_, "TreasuryVester.constructor: end is too early");

        gamma = gamma_;
        recipient = recipient_;
        funder = funder_;
        vestingAmount = vestingAmount_;
        vestingBegin = vestingBegin_;
        vestingCliff = vestingCliff_;
        vestingEnd = vestingEnd_;

        lastUpdate = vestingBegin;
    }

    function setRecipient(address recipient_) public {
        require(msg.sender == recipient, "TreasuryVester.setRecipient: unauthorized");
        recipient = recipient_;
    }

    function claim() public {
        require(block.timestamp >= vestingCliff, "TreasuryVester.claim: not time yet");
        require(msg.sender == recipient, "TreasuryVester.claim: unauthorized");
        uint256 amount;
        if (block.timestamp >= vestingEnd) {
            amount = IERC20(gamma).balanceOf(address(this));
        } else {
            amount = vestingAmount.mul(block.timestamp.sub(lastUpdate)).div(vestingEnd.sub(vestingBegin));
            lastUpdate = block.timestamp;
        }
        IERC20(gamma).transfer(recipient, amount);
    }

    function recoverToken(address token_) public {
        require(token_ != gamma, "TreasuryVester.recoverToken: only recover tokens accidentally sent to the contract");
        uint256 amount = IERC20(token_).balanceOf(address(this));
        IERC20(token_).transfer(recipient, amount);
    }

    function reclaimTokens(uint256 amount, address payable to) public onlyFunder {
		IERC20(gamma).safeTransfer(to, amount);
    }
    function transferFunder(address newFunder) public onlyFunder {
        funder = newFunder;
    }
}