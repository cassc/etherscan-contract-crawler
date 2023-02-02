// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;


import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@rari-capital/solmate/src/utils/FixedPointMathLib.sol';
import '@rari-capital/solmate/src/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/ethereum/ozIMiddleware.sol';
import '../interfaces/ethereum/DelayedInbox.sol';
import '../interfaces/common/IWETH.sol';
import '../arbitrum/facets/OZLFacet.sol';
import '../libraries/LibCommon.sol';
import './StorageBeacon.sol';
import '../Errors.sol';


contract ozMiddleware is ozIMiddleware, Ownable, ReentrancyGuard {

    using FixedPointMathLib for uint;

    address private beacon;

    address private immutable inbox;
    address private immutable OZL;
    uint private immutable maxGas;

    constructor(address inbox_, address ozDiamond_, uint maxGas_) {
        inbox = inbox_;
        OZL = ozDiamond_;
        maxGas = maxGas_;
    }


    /*///////////////////////////////////////////////////////////////
                              Main functions
    //////////////////////////////////////////////////////////////*/

    //@inheritdoc ozIMiddleware
    function forwardCall(
        uint gasPriceBid_,
        bytes memory dataForL2_,
        uint amountToSend_,
        address account_
    ) external payable returns(bool, bool, address) {
        (address user,,uint16 slippage) = LibCommon.extract(dataForL2_);
        bool isEmergency;

        StorageBeacon storageBeacon = StorageBeacon(_getStorageBeacon(0));

        if (!storageBeacon.isUser(user)) revert UserNotInDatabase(user);
        if (amountToSend_ <= 0) revert CantBeZero('amountToSend');
        if (!(msg.value > 0)) revert CantBeZero('contract balance');

        bytes32 acc_user = bytes32(bytes.concat(bytes20(msg.sender), bytes12(bytes20(user))));
        if (!storageBeacon.verify(user, acc_user)) revert NotAccount();

        bytes memory swapData = abi.encodeWithSelector(
            OZLFacet(payable(OZL)).exchangeToAccountToken.selector, 
            dataForL2_, amountToSend_, account_
        );

        bytes memory ticketData = _createTicketData(gasPriceBid_, swapData, false);

        (bool success, ) = inbox.call{value: msg.value}(ticketData); 
        if (!success) {
            /// @dev If it fails the 1st bridge attempt, it decreases the L2 gas calculations
            ticketData = _createTicketData(gasPriceBid_, swapData, true);
            (success, ) = inbox.call{value: msg.value}(ticketData);

            if (!success) {
                _runEmergencyMode(user, slippage);
                isEmergency = true;
            }
        }
        bool emitterStatus = storageBeacon.getEmitterStatus();
        return (isEmergency, emitterStatus, user);
    }

    /**
     * @dev Runs the L1 emergency swap in Uniswap. 
     *      If it fails, it doubles the slippage and tries again.
     *      If it fails again, it sends WETH back to the user.
     */
    function _runEmergencyMode(address user_, uint16 slippage_) private nonReentrant { 
        address sBeacon = _getStorageBeacon(0);
        StorageBeacon.EmergencyMode memory eMode = StorageBeacon(sBeacon).getEmergencyMode();
        
        IWETH(eMode.tokenIn).deposit{value: msg.value}();
        uint balanceWETH = IWETH(eMode.tokenIn).balanceOf(address(this));

        IERC20(eMode.tokenIn).approve(address(eMode.swapRouter), balanceWETH);

        for (uint i=1; i <= 2;) {
            ISwapRouter.ExactInputSingleParams memory params =
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: eMode.tokenIn,
                    tokenOut: eMode.tokenOut, 
                    fee: eMode.poolFee,
                    recipient: user_,
                    deadline: block.timestamp,
                    amountIn: balanceWETH,
                    amountOutMinimum: _calculateMinOut(eMode, i, balanceWETH, slippage_), 
                    sqrtPriceLimitX96: 0
                });

            try eMode.swapRouter.exactInputSingle(params) { 
                break; 
            } catch {
                if (i == 1) {
                    unchecked { ++i; }
                    continue; 
                } else {
                    IERC20(eMode.tokenIn).transfer(user_, balanceWETH);
                    break;
                }
            }
        } 
    }


    /*///////////////////////////////////////////////////////////////
                        Retryable helper methods
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Creates the ticket's calldata based on L1 gas values
     */
    function _createTicketData( 
        uint gasPriceBid_, 
        bytes memory swapData_,
        bool decrease_
    ) private view returns(bytes memory) {
        (uint maxSubmissionCost, uint autoRedeem) = _calculateGasDetails(swapData_.length, gasPriceBid_, decrease_);

        return abi.encodeWithSelector(
            DelayedInbox(inbox).createRetryableTicket.selector, 
            OZL, 
            msg.value - autoRedeem,
            maxSubmissionCost, 
            OZL, 
            OZL, 
            maxGas,  
            gasPriceBid_, 
            swapData_
        );
    }

    /**
     * @dev Calculates the L1 gas values for the retryableticket's auto redeemption
     */
    function _calculateGasDetails(
        uint dataLength_, 
        uint gasPriceBid_, 
        bool decrease_
    ) private view returns(uint maxSubmissionCost, uint autoRedeem) {
        maxSubmissionCost = DelayedInbox(inbox).calculateRetryableSubmissionFee(
            dataLength_,
            0
        );

        maxSubmissionCost = decrease_ ? maxSubmissionCost : maxSubmissionCost * 2;
        autoRedeem = maxSubmissionCost + (gasPriceBid_ * maxGas);
        if (autoRedeem > msg.value) autoRedeem = msg.value;
    }

    /**
     * @dev Using the account slippage, calculates the minimum amount of tokens out.
     *      Uses the "i" variable from the parent loop to double the slippage, if necessary.
     */
    function _calculateMinOut(
        StorageBeacon.EmergencyMode memory eMode_, 
        uint i_,
        uint balanceWETH_,
        uint slippage_
    ) private view returns(uint minOut) {
        (,int price,,,) = eMode_.priceFeed.latestRoundData();
        uint expectedOut = balanceWETH_.mulDivDown(uint(price) * 10 ** 10, 1 ether);
        uint minOutUnprocessed = 
            expectedOut - expectedOut.mulDivDown(slippage_ * i_ * 100, 1000000); 
        minOut = minOutUnprocessed.mulWadDown(10 ** 6);
    }

    /*///////////////////////////////////////////////////////////////
                                Helpers
    //////////////////////////////////////////////////////////////*/

    /// @dev Gets a version of the Storage Beacon
    function _getStorageBeacon(uint version_) private view returns(address) {
        return ozUpgradeableBeacon(beacon).storageBeacon(version_);
    }

    /// @dev Stores the Beacon
    function storeBeacon(address beacon_) external onlyOwner {
        beacon = beacon_;
    }
}