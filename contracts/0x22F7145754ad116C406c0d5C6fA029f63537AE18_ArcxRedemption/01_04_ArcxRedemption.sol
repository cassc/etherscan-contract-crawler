// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import {Ownable} from "../lib/Ownable.sol";
import {IERC20} from "../token/IERC20.sol";
import {SafeERC20} from "../lib/SafeERC20.sol";


contract ArcxRedemption is Ownable {

    using SafeERC20 for IERC20;

    IERC20 public usdcToken;

    IERC20 public arcxToken;

    uint256 public exchangeRate;

    uint256 public cutoffDate;

    event Redemption(
        address indexed _redeemer,
        uint256 _arcxGiven, 
        uint256 _usdcReturned
    );

    event Withdraw(
        address _token, 
        uint256 _amount, 
        address _destination
    );

    constructor(
        address _usdcAddress,
        address _arcxAddress,
        uint256 _exchangeRate,
        uint256 _cutoffDate
    ) 
    {
        usdcToken = IERC20(_usdcAddress);
        arcxToken = IERC20(_arcxAddress);

        exchangeRate = _exchangeRate;
        cutoffDate = _cutoffDate;
    }

    /**
     * @dev Callable by anyone who supplies ARCx up until the cut off date
     * 
     * @param _amount - How many ARCx tokens you'd like to redeem for USDC
     */
    function redeem(
        uint256 _amount
    ) 
        public 
    {
        // Check cut off date has not passed
        require(
            currentTimestamp() <= cutoffDate,
            "The cut off date to redeem has already passed"
        );

        // Transfer ARCx from user to contract
        arcxToken.safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        // Calculate how much USDC to give using exchange rate
        uint256 usdcToReturn = (_amount * exchangeRate) / (10 ** 18) / (10 ** 12);

        // Send USDC to user
        usdcToken.safeTransfer(
            msg.sender,
            usdcToReturn
        );

        emit Redemption(
            msg.sender,
            _amount,
            usdcToReturn
        );
    }

    /**
     * @dev Should only be callable by the owner to withdraw funds (USDC or ARCx)
     * 
     * @param _token - Specify to remove USDC or ARCx
     * @param _amount - How much of the amount of tokens to remove
     * @param _destination - Where the tokens should be sent to
     */
    function withdraw(
        address _token,
        uint256 _amount,
        address _destination
    ) 
        public 
        onlyOwner
    {
        // Send the specified token to the destination
        IERC20(_token).safeTransfer(
            _destination,
            _amount
        );
    }

    function currentTimestamp()
        public
        virtual
        view
        returns (uint256)
    {
        return block.timestamp;
    }

}