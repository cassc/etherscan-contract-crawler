/// RewardDripper.sol

// Copyright (C) 2021 Reflexer Labs, INC
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.7;

abstract contract TokenLike {
    function balanceOf(address) public view virtual returns (uint256);

    function transfer(address, uint256) external virtual returns (bool);
}

abstract contract FundsHolderLike {
    function emitTokens() external virtual;
}

abstract contract RewardsPoolLike {
    function updatePool() external virtual;
}

contract ExternallyControlledDripper {
    // --- Auth ---
    mapping(address => uint) public authorizedAccounts;

    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external virtual isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }

    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(
        address account
    ) external virtual isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }

    /**
     * @notice Checks whether msg.sender can call an authed function
     **/
    modifier isAuthorized() {
        require(
            authorizedAccounts[msg.sender] == 1,
            "RewardDripper/account-not-authorized"
        );
        _;
    }

    // --- State Variables/Constants ---
    // Last block when a reward was given
    mapping(address => uint256) public lastRewardBlock;
    // Share of rewards that goes to requestors [0]. 100% = 1 WAD
    uint256 public requestorZeroShare;
    // Total reward per block (sum of requestor0 and requestor1 rewardPerBlocks)
    uint256 public totalRewardPerBlock;
    // The address that can request rewards
    address[2] public requestors;
    // The reward token being distributed
    TokenLike public immutable rewardToken;
    // Contract that releases funds on every update (follows dripper interface)
    FundsHolderLike public fundsHolder;
    // Contract that sets the rate and updates rewards per block
    address public rateSetter;
    // Period used to calculate rewards, should match emissions frequency. Default: 30 days
    uint256 public rewardPeriod;
    // End of current reward period
    uint256 public rewardPeriodEnd;    
    // The delay enforced on the controller updates
    uint256 public updateDelay;
    // Last update time
    uint256 public lastUpdateTime;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 indexed parameter, uint256 data);
    event ModifyParameters(bytes32 indexed parameter, address data);
    event DripReward(address requestor, uint256 amountToTransfer);
    event TransferTokenOut(address dst, uint256 amount);
    event UpdateRewards(uint256 amountReceiver0, uint256 totalRewardPerBlock);

    constructor(
        address[2] memory requestors_,
        address rewardToken_,
        address fundsHolder_,
        address rateSetter_,
        uint256 rewardPeriod_,
        uint256 updateDelay_
    ) public {
        require(requestors_[0] != address(0), "RewardDripper/null-requoestor");
        require(requestors_[1] != address(0), "RewardDripper/null-requoestor");
        require(rewardToken_ != address(0), "RewardDripper/null-reward-token");
        require(fundsHolder_ != address(0), "RewardDripper/null-funds-holder");
        require(rateSetter_ != address(0), "RewardDripper/null-rate-setter");
        require(rewardPeriod_ > 0, "RewardDripper/null-reward-period");
        require(updateDelay_ > 0, "RewardDripper/null-update-delay");

        authorizedAccounts[msg.sender] = 1;

        requestors = requestors_;
        rewardToken = TokenLike(rewardToken_);
        fundsHolder = FundsHolderLike(fundsHolder_);
        rateSetter = rateSetter_;
        rewardPeriod = rewardPeriod_;
        updateDelay = updateDelay_;

        lastRewardBlock[requestors_[0]] = block.number;
        lastRewardBlock[requestors_[1]] = block.number;

        emit AddAuthorization(msg.sender);
        emit ModifyParameters("requestors0", requestors_[0]);
        emit ModifyParameters("requestors1", requestors_[1]);
        emit ModifyParameters("fundsHolder", fundsHolder_);
        emit ModifyParameters("rateSetter", rateSetter_);
        emit ModifyParameters("rewardPeriod", rewardPeriod_);
        emit ModifyParameters("updateDelay", updateDelay_);
    }

    // --- Math ---
    uint256 constant WAD = 10 ** 18;

    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "RewardDripper/sub-underflow");
    }

    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "RewardDripper/mul-overflow");
    }

    // --- Administration ---
    /*
     * @notice Modify an uint256 parameter
     * @param parameter The name of the parameter to modify
     * @param data New value for the parameter
     */
    function modifyParameters(
        bytes32 parameter,
        uint256 data
    ) external isAuthorized {
        if (parameter == "updateDelay") {
            require(data > 0, "RewardDripper/invalid-data");
            updateDelay = data;
        } else if (parameter == "rewardPeriod") {
            require(data > 0, "RewardDripper/invalid-data");
            rewardPeriod = data;
        } else if (parameter == "lastUpdateTime") {
            require(data > 0, "RewardDripper/invalid-data");
            lastUpdateTime = data;            
        } else if (parameter == "totalRewardPerBlock") {
            totalRewardPerBlock = data;
        } else if (parameter == "requestorZeroShare") {
            require(data <= WAD, "RewardDripper/invalid-data");
            requestorZeroShare = data;
        } else revert("RewardDripper/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }

    /*
     * @notice Modify an address parameter
     * @param parameter The name of the parameter to modify
     * @param data New value for the parameter
     */
    function modifyParameters(
        bytes32 parameter,
        address data
    ) external isAuthorized {
        require(data != address(0), "RewardDripper/null-data");
        if (parameter == "requestor0") {
            requestors[0] = data;
            lastRewardBlock[data] = block.number;
        } else if (parameter == "requestor1") {
            requestors[1] = data;
            lastRewardBlock[data] = block.number;
        } else if (parameter == "fundsHolder") {
            fundsHolder = FundsHolderLike(data);
        } else if (parameter == "rateSetter") {
            rateSetter = data;
        } else revert("RewardDripper/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }

    // --- Core Logic ---
    /*
     * @notice Transfer tokens to a custom address
     * @param dst The destination address for the tokens
     * @param amount The amount of tokens transferred
     */
    function transferTokenOut(
        address dst,
        uint256 amount
    ) external isAuthorized {
        require(dst != address(0), "RewardDripper/null-dst");
        require(amount > 0, "RewardDripper/null-amount");

        rewardToken.transfer(dst, amount);

        emit TransferTokenOut(dst, amount);
    }

    /*
     * @notice Send rewards to the requestor
     */
    function dripReward() external {
        dripReward(msg.sender);
    }

    /*
     * @notice Send rewards to an address defined by the requestor
     * @param to Receiver of the rewards
     */
    function dripReward(address to) public {
        if (lastRewardBlock[to] >= block.number) return;
        require(
            msg.sender == requestors[0] || msg.sender == requestors[1],
            "RewardDripper/invalid-caller"
        );

        uint256 remainingBalance = rewardToken.balanceOf(address(this));
        uint256 share = to == requestors[0]
            ? requestorZeroShare
            : WAD - requestorZeroShare;
        uint256 amountToTransfer = multiply(
            subtract(block.number, lastRewardBlock[to]),
            multiply(totalRewardPerBlock, share) / WAD
        );
        amountToTransfer = (amountToTransfer > remainingBalance)
            ? remainingBalance
            : amountToTransfer;

        lastRewardBlock[to] = block.number;

        if (amountToTransfer == 0) return;
        require(
            rewardToken.transfer(to, amountToTransfer),
            "RewardDripper/transfer-failed"
        );

        emit DripReward(to, amountToTransfer);
    }
    
    /*
     * @notice Receives a proportion from the controller and sets rewards amounts for a period
     * @dev Can only be called by the controller.
     * @param requestorZeroShare_ The percentage that will go to requestor[0] (1 WAD = 100%)
     */
    function updateRate(uint256 requestorZeroShare_) external {
        require(now >= lastUpdateTime + updateDelay, "RewardDripper/too-soon");
        require(msg.sender == rateSetter, "RewardDripper/only-controller");
        require(requestorZeroShare_ <= WAD, "RewardDripper/invalid-share");

        // force pool updates (pools will call dripReward and drip all available rewards up to now)
        RewardsPoolLike(requestors[0]).updatePool();
        RewardsPoolLike(requestors[1]).updatePool();

        if (rewardPeriodEnd <= now) rewardPeriodEnd = now + rewardPeriod;

        // pull funds
        try fundsHolder.emitTokens() {} catch {}
        uint256 balance = rewardToken.balanceOf(address(this));

        // setting rewards per block
        uint blocksInPeriod = (rewardPeriodEnd - now) / 12;
        totalRewardPerBlock = balance / blocksInPeriod;
        requestorZeroShare = requestorZeroShare_;

        emit UpdateRewards(requestorZeroShare, totalRewardPerBlock);

        lastUpdateTime = now;
    }

    function rewardPerBlock() external view returns (uint256) {
        if (msg.sender == requestors[0])
            return multiply(totalRewardPerBlock, requestorZeroShare) / WAD;
        else if (msg.sender == requestors[1])
            return
                multiply(
                    totalRewardPerBlock,
                    subtract(WAD, requestorZeroShare)
                ) / WAD;
        else revert("RewardDripper/not-a-requestor");
    }
}