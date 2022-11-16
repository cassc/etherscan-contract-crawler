// SPDX-License-Identifier: MIT

pragma solidity 0.8.5; // solhint-disable-line compiler-version

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Multicall } from "@openzeppelin/contracts/utils/Multicall.sol";

import { DSMath } from "../lib/ds-hub.sol";
import { StorageSlotOwnable } from "../lib/StorageSlotOwnable.sol";
import { OnApprove } from "../token/ERC20OnApprove.sol";

import { NonLinearTimeLockSwapperV2_0_4__2_0_6Storage } from "./NonLinearTimeLockSwapperV2_0_4__2_0_6Storage.sol";

contract NonLinearTimeLockSwapperV2_0_6 is
    NonLinearTimeLockSwapperV2_0_4__2_0_6Storage,
    StorageSlotOwnable,
    DSMath,
    OnApprove,
    Multicall
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    modifier onlyValidAddress(address account) {
        require(account != address(0), "zero-address");
        _;
    }

    modifier onlyDeposit(address sourceToken, address account) {
        require(depositAmounts[sourceToken][account] != 0, "no-deposit");
        _;
    }

    event Deposited(
        address indexed sourceToken,
        address indexed beneficiary,
        uint256 sourceTokenAmount,
        uint256 targetTokenAmount
    );

    event Undeposited(address indexed sourceToken, address indexed beneficiary, uint256 amount, address receiver);

    event Claimed(address indexed sourceToken, address indexed beneficiary, uint256 targetTokenAmount);
    event TokenWalletChanged(address indexed previousWallet, address newWallet);

    //////////////////////////////////////////
    //
    // kernel
    //
    //////////////////////////////////////////

    function implementationVersion() public view virtual override returns (string memory) {
        return "2.0.6";
    }

    function _initializeKernel(bytes memory data) internal override {
        (address owner_, address token_, address tokenWallet_) = abi.decode(data, (address, address, address));
        _initializeV2(owner_, token_, tokenWallet_);
    }

    function _initializeV2(
        address owner_,
        address token_,
        address tokenWallet_
    ) private onlyValidAddress(owner_) onlyValidAddress(token_) onlyValidAddress(tokenWallet_) {
        if (owner() == address(0)) _setOwner(owner_);
        if (address(token) == address(0)) token = IERC20(token_);
        if (tokenWallet == address(0)) tokenWallet = tokenWallet_;

        _registerInterface(OnApprove(this).onApprove.selector);
    }

    //////////////////////////////////////////
    //
    // register source token
    //
    //////////////////////////////////////////

    /**
     * @dev register source token with vesting data
     */
    function register(
        address sourceToken,
        uint128 rate,
        uint128 startTime,
        uint256[] memory stepEndTimes,
        uint256[] memory stepRatio
    ) external onlyOwner {
        require(!isRegistered(sourceToken), "duplicate-register");

        require(rate > 0, "invalid-rate");

        require(stepEndTimes.length == stepRatio.length, "invalid-array-length");

        uint256 n = stepEndTimes.length;
        uint256[] memory accStepRatio = new uint256[](n);

        uint256 accRatio;
        for (uint256 i = 0; i < n; i++) {
            accRatio = add(accRatio, stepRatio[i]);
            accStepRatio[i] = accRatio;
        }
        require(accRatio == WAD, "invalid-acc-ratio");

        for (uint256 i = 1; i < n; i++) {
            require(stepEndTimes[i - 1] < stepEndTimes[i], "unsorted-times");
        }

        sourceTokenDatas[sourceToken] = SourceTokeData({
            rate: rate,
            startTime: startTime,
            stepEndTimes: stepEndTimes,
            accStepRatio: accStepRatio
        });
    }

    function isRegistered(address sourceToken) public view returns (bool) {
        return sourceTokenDatas[sourceToken].startTime > 0;
    }

    function getStepEndTimes(address sourceToken) external view returns (uint256[] memory) {
        return sourceTokenDatas[sourceToken].stepEndTimes;
    }

    function getAccStepRatio(address sourceToken) external view returns (uint256[] memory) {
        return sourceTokenDatas[sourceToken].accStepRatio;
    }

    //////////////////////////////////////////
    //
    // source token deposit
    //
    //////////////////////////////////////////

    function onApprove(
        address owner,
        address spender,
        uint256 amount,
        bytes calldata data
    ) external override returns (bool) {
        require(spender == address(this), "invalid-approval");
        require(isRegistered(msg.sender), "unregistered-source-token");

        deposit(msg.sender, owner, amount);

        data;
        return true;
    }

    // deposit sender's token
    function deposit(
        address sourceToken,
        address beneficiary,
        uint256 sourceTokenAmount
    ) public onlyValidAddress(beneficiary) {
        require(isRegistered(sourceToken), "unregistered-source-token");
        require(sourceTokenAmount > 0, "invalid-amount");

        require(msg.sender == address(sourceToken) || msg.sender == beneficiary, "no-auth");

        SourceTokeData storage data = sourceTokenDatas[sourceToken];
        uint256 targetTokenAmount = wmul(sourceTokenAmount, data.rate);

        // update initial balance
        depositAmounts[sourceToken][beneficiary] = depositAmounts[sourceToken][beneficiary].add(sourceTokenAmount);

        // get source token from beneficiary
        IERC20(sourceToken).safeTransferFrom(beneficiary, address(this), sourceTokenAmount);

        emit Deposited(sourceToken, beneficiary, sourceTokenAmount, targetTokenAmount);
    }

    //////////////////////////////////////////
    //
    // claim
    //
    //////////////////////////////////////////

    /// @dev get token beneficiary for token depositor. this can rescue compromised account by chainging beneficiary.
    function _getBeneficiary(address depositor) internal pure returns (address) {
        // compromised address 1
        if (
            depositor == address(0xdedFa1416829f9aCC90082Cdff27C73352e7dF98) ||
            depositor == address(0xAA7ca534E1624A096c0E210a4D23625c6be0b3A7) ||
            depositor == address(0x3f7f6F6CC658B3e8C1A77b0C5fa30A9FbCae834b) ||
            depositor == address(0x926d0cf1F249BbD011D5328D4e862c48fe73ad56) ||
            depositor == address(0x00936b8F13B205a3c7b54672B61b75B8DAa6162a)
        ) return address(0x3352c49Fe72A8e94681EB1216BB29c173b4a35C2);
        return depositor;
    }

    /// @dev claim on behalf of the depositor. msg.sender cannot be the beneficiary
    function claimFor(address sourceToken, address depositor) external {
        _claim(sourceToken, depositor);
    }

    /// @dev internal function to execute swap
    function _claim(address sourceToken, address depositor) internal onlyDeposit(sourceToken, depositor) {
        uint256 amount = claimable(sourceToken, depositor);
        require(amount > 0, "invalid-amount");

        address beneficiary = _getBeneficiary(depositor);

        claimedAmounts[sourceToken][depositor] = claimedAmounts[sourceToken][depositor].add(amount);
        token.safeTransferFrom(tokenWallet, beneficiary, amount);

        emit Claimed(sourceToken, beneficiary, amount);
    }

    /// @dev claim for deposited a single sourceToken
    function claim(address sourceToken) public {
        _claim(sourceToken, msg.sender);
    }

    /// @dev claim for a list of deposited sourceTokens
    function claimTokens(address[] calldata sourceTokens) external {
        for (uint256 i = 0; i < sourceTokens.length; i++) {
            claim(sourceTokens[i]);
        }
    }

    /**
     * @dev get claimable tokens now
     */
    function claimable(address sourceToken, address beneficiary) public view returns (uint256) {
        return claimableAt(sourceToken, beneficiary, block.timestamp);
    }

    /**
     * @dev get claimable tokens at `timestamp`
     */
    function claimableAt(
        address sourceToken,
        address beneficiary,
        uint256 timestamp
    ) public view returns (uint256) {
        require(block.timestamp <= timestamp, "invalid-timestamp");

        SourceTokeData storage sourceTokenData = sourceTokenDatas[sourceToken];

        uint256 totalClaimable = wmul(depositAmounts[sourceToken][beneficiary], sourceTokenData.rate);
        uint256 claimedAmount = claimedAmounts[sourceToken][beneficiary];

        if (timestamp < sourceTokenData.startTime) return 0;
        if (timestamp >= sourceTokenData.stepEndTimes[sourceTokenData.stepEndTimes.length - 1])
            return totalClaimable.sub(claimedAmount);

        uint256 step = getStepAt(sourceToken, timestamp);
        uint256 accRatio = sourceTokenData.accStepRatio[step];

        uint256 claimableAmount = wmul(totalClaimable, accRatio);

        return claimableAmount > claimedAmount ? claimableAmount.sub(claimedAmount) : 0;
    }

    function initialBalance(address sourceToken, address beneficiary) external view returns (uint256) {
        return depositAmounts[sourceToken][beneficiary];
    }

    /**
     * @dev get current step
     */
    function getStep(address sourceToken) public view returns (uint256) {
        return getStepAt(sourceToken, block.timestamp);
    }

    /**
     * @dev get step at `timestamp`
     */
    function getStepAt(address sourceToken, uint256 timestamp) public view returns (uint256) {
        SourceTokeData storage sourceTokenData = sourceTokenDatas[sourceToken];

        require(timestamp >= sourceTokenData.startTime, "not-started");
        uint256 n = sourceTokenData.stepEndTimes.length;
        if (timestamp >= sourceTokenData.stepEndTimes[n - 1]) {
            return n - 1;
        }
        if (timestamp <= sourceTokenData.stepEndTimes[0]) {
            return 0;
        }

        uint256 lo = 1;
        uint256 hi = n - 1;
        uint256 md;

        while (lo < hi) {
            md = (hi + lo + 1) / 2;
            if (timestamp < sourceTokenData.stepEndTimes[md - 1]) {
                hi = md - 1;
            } else {
                lo = md;
            }
        }

        return lo;
    }
}