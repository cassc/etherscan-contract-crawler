// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IRewardDistributor} from "./interfaces/IRewardDistributor.sol";
import {IRewardHarvester} from "./interfaces/IRewardHarvester.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Errors} from "./libraries/Errors.sol";
import {Common} from "./libraries/Common.sol";

contract RewardSwapper is Ownable2Step {
    using SafeERC20 for IERC20;

    IRewardDistributor public rewardDistributor;
    IRewardHarvester public rewardHarvester;

    // Operator address
    address public operator;

    //-----------------------//
    //        Events         //
    //-----------------------//
    event SetOperator(address indexed operator);
    event SetRewardHarvester(address indexed rewardHarvester);
    event SetRewardDistributor(address indexed rewardDistributor);
    event BribeTransferred(address indexed token, uint256 totalAmount);

    /**
     * @notice Modifier to check caller is operator
     */
    modifier onlyOperator() {
        if (msg.sender != operator) revert Errors.NotAuthorized();
        _;
    }

    //-----------------------//
    //       Constructor     //
    //-----------------------//
    constructor(
        address _rewardDistributor,
        address _rewardHarvester,
        address _operator
    ) {
        _setRewardDistributor(_rewardDistributor);
        _setRewardHarvester(_rewardHarvester);
        _setOperator(_operator);
    }

    //-----------------------//
    //   External Functions  //
    //-----------------------//

    /**
     * @notice Executes swaps via DEX
     * @param  _claimSwapData  Common.ClaimAndSwapData[]  The data for the claims+swaps
     */
    function claimSwapAndDepositReward(
        Common.ClaimAndSwapData[] calldata _claimSwapData
    ) external onlyOperator {
        uint256 cLen = _claimSwapData.length;

        if (cLen == 0) revert Errors.InvalidArray();

        IERC20 defaultToken = IERC20(rewardHarvester.defaultToken());

        uint256 initalAmount = defaultToken.balanceOf(address(this));

        Common.Claim[] memory claimData = new Common.Claim[](
            _claimSwapData.length
        );

        // Claim rewards
        for (uint256 i; i < cLen; ) {
            claimData[i].identifier = _claimSwapData[i].rwIdentifier;
            claimData[i].account = address(this);
            claimData[i].amount = _claimSwapData[i].fromAmount;
            claimData[i].merkleProof = _claimSwapData[i].rwMerkleProof;

            unchecked {
                ++i;
            }
        }

        rewardDistributor.claim(claimData);

        // Swap reward tokens to default token
        for (uint256 i; i < cLen; ) {
            _swap(_claimSwapData[i]);

            unchecked {
                ++i;
            }
        }

        uint256 amountClaimed = defaultToken.balanceOf(address(this)) -
            initalAmount;

        // Approve reward harvester if needed
        if (
            defaultToken.allowance(address(this), address(rewardHarvester)) <
            amountClaimed
        ) {
            defaultToken.safeApprove(
                address(rewardHarvester),
                type(uint256).max
            );
        }

        // Deposit reward
        rewardHarvester.depositReward(amountClaimed);

        emit BribeTransferred(address(defaultToken), amountClaimed);
    }

    /**
        @notice Change the operator
        @param  _operator  address  New operator address
     */
    function changeOperator(address _operator) external onlyOwner {
        _setOperator(_operator);
    }

    /**
        @notice Change the reward harvester address
        @param  _harvester  address  New harvester address
     */
    function changeRewardHarvester(address _harvester) external onlyOwner {
        _setRewardHarvester(_harvester);
    }

    /**
        @notice Change the reward distributor address
        @param  _distributor  address  New distributor address
     */
    function changeRewardDistributor(address _distributor) external onlyOwner {
        _setRewardDistributor(_distributor);
    }

    //-----------------------//
    //   Internal Functions  //
    //-----------------------//

    /**
        @dev    Internal to set the operator
        @param  _operator  address  Operator address
     */
    function _setOperator(address _operator) internal {
        if (_operator == address(0)) revert Errors.InvalidAddress();

        operator = _operator;

        emit SetOperator(_operator);
    }

    /**
        @dev    Internal to set the reward harvester
        @param  _harvester  address  Reward Harvester address
     */
    function _setRewardHarvester(address _harvester) internal {
        if (_harvester == address(0)) revert Errors.InvalidAddress();

        rewardHarvester = IRewardHarvester(_harvester);

        emit SetRewardHarvester(_harvester);
    }

    /**
        @dev    Internal to set the reward distributor
        @param  _distributor  address  Distributor address
     */
    function _setRewardDistributor(address _distributor) internal {
        if (_distributor == address(0)) revert Errors.InvalidAddress();

        rewardDistributor = IRewardDistributor(_distributor);

        emit SetRewardDistributor(_distributor);
    }

    /**
     * @notice Executes a sequence of swaps via DEX
     * @param  _swapData       Common.SwapData  The data for the swaps
     * @return receivedAmount  uint256          The final amount of the toToken received
     */
    function _swap(
        Common.ClaimAndSwapData memory _swapData
    ) internal returns (uint256 receivedAmount) {
        if (
            !(_swapData.callees.length == _swapData.callLengths.length &&
                _swapData.callees.length == _swapData.values.length)
        ) {
            revert Errors.ExchangeDataArrayMismatch();
        }

        if (_swapData.deadline < block.timestamp) {
            revert Errors.DeadlineBreach();
        }

        if (_swapData.toAmount == 0) {
            revert Errors.ZeroExpectedReturns();
        }

        bytes memory exchangeData = _swapData.exchangeData;
        uint256 calleesLength = _swapData.callees.length;

        if (calleesLength == 0) revert Errors.InvalidArray();

        bytes4 transferFromSelector = IERC20.transferFrom.selector;
        uint256 initialAmount = IERC20(_swapData.toToken).balanceOf(
            address(this)
        );

        uint256 currentDataStartIndex = 0;
        for (uint256 i; i < calleesLength; ) {
            // Check if the call is a transferFrom call
            // protect caller from transferring more than `fromAmount`
            {
                bytes32 selector;
                assembly {
                    selector := mload(add(exchangeData, add(currentDataStartIndex, 32)))
                }
                if (bytes4(selector) == transferFromSelector) {
                    revert Errors.TransferFromCall();
                }
            }
            bool result = _externalCall(
                _swapData.callees[i], //destination
                _swapData.values[i], //value to send
                currentDataStartIndex, // start index of call data
                _swapData.callLengths[i], // length of calldata
                exchangeData // total calldata
            );
            if (!result) {
                revert Errors.ExternalCallFailure();
            }
            currentDataStartIndex += _swapData.callLengths[i];
            unchecked {
                ++i;
            }
        }

        receivedAmount = IERC20(_swapData.toToken).balanceOf(address(this));

        if ((receivedAmount - initialAmount) < _swapData.toAmount) {
            revert Errors.InsufficientReturn();
        }
    }

    /**
     * @dev Source take from GNOSIS MultiSigWallet
     * @dev https://github.com/gnosis/MultiSigWallet/blob/master/contracts/MultiSigWallet.sol
     */
    function _externalCall(
        address _destination,
        uint256 _value,
        uint256 _dataOffset,
        uint256 _dataLength,
        bytes memory _data
    ) internal returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40) // "Allocate" memory for output
            // (0x40 is where "free memory" pointer is stored by convention)

            let d := add(_data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                gas(),
                _destination,
                _value,
                add(d, _dataOffset),
                _dataLength, // Size of the input (in bytes) - this is what fixes the padding problem
                x,
                0 // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }
}