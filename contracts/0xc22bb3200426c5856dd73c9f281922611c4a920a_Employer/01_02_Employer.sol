// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITimeToken.sol";

/**
 * @title TIME Token Employer contract
 * @dev Smart contract used to model the first Use Case for TIME Token - The Employer. It pays some interest over the native cryptocurrency deposited from investors
 **/
contract Employer {

    bool private _isOperationLocked;

    address public constant DEVELOPER_ADDRESS = 0x731591207791A93fB0Ec481186fb086E16A7d6D0;
    address public immutable TIME_TOKEN_ADDRESS;

    uint256 public constant D = 10**18;
    uint256 public constant FACTOR = 10**18;
    uint256 public immutable FIRST_BLOCK;
    uint256 public immutable ONE_YEAR;
    uint256 public availableNative;
    uint256 public currentDepositedNative;
    uint256 public totalAnticipatedTime;
    uint256 public totalBurnedTime;
    uint256 public totalDepositedNative;
    uint256 public totalDepositedTime;
    uint256 public totalEarnedNative;
    uint256 public totalTimeSaved;
    
    mapping (address => bool) public anticipationEnabled;

    mapping (address => uint256) public deposited;
    mapping (address => uint256) public earned;
    mapping (address => uint256) public lastBlock;
    mapping (address => uint256) public remainingTime;

    constructor(address timeTokenAddress_) {
        FIRST_BLOCK = block.number;
        TIME_TOKEN_ADDRESS = timeTokenAddress_;
        ONE_YEAR = ITimeToken(timeTokenAddress_).TIME_BASE_LIQUIDITY() * 52;
    }

    /**
     * @dev Implement security to avoid reentrancy attacks
     **/
    modifier nonReentrant() {
        require(!_isOperationLocked, "Operation is locked");
        _isOperationLocked = true;
        _;
        _isOperationLocked = false;
	}
    
    /**
     * @dev Update the blocks from caller (msg.sender), contract address, and burn TIME tokens accordingly. It also extracts ETH from TIME contract, compounds and transfer earnings to depositants
     **/
    modifier update(bool mustCompound) {
        if (lastBlock[address(this)] == 0 && block.number != 0)
            lastBlock[address(this)] = block.number;
        if ((lastBlock[msg.sender] == 0 && block.number != 0) || remainingTime[msg.sender] == 0)
            lastBlock[msg.sender] = block.number;
        uint256 timeToBurn = (block.number - lastBlock[address(this)]) * D;
        uint256 timeToBurnDepositant = (block.number - lastBlock[msg.sender]) * D;
        earned[msg.sender] += queryEarnings(msg.sender);
        _;
        if (mustCompound)
            _compoundDepositantEarnings(msg.sender);
        else
            _transferDepositantEarnings(msg.sender);
        ITimeToken timeToken = ITimeToken(TIME_TOKEN_ADDRESS);
        _earnInterestAndAllocate(timeToken);
        if (timeToBurn > remainingTime[address(this)])
            timeToBurn = remainingTime[address(this)];
        if (timeToBurnDepositant > remainingTime[msg.sender])
            timeToBurnDepositant = remainingTime[msg.sender];
        if (timeToBurn > 0)
            _burnTime(timeToken, address(this), timeToBurn);
        if (timeToBurnDepositant > 0)
            _burnTime(timeToken, msg.sender, timeToBurnDepositant);
        lastBlock[address(this)] = block.number;
        lastBlock[msg.sender] = block.number;
    }

    fallback() external payable {
        require(msg.data.length == 0);
    }

    receive() external payable {
        if (msg.sender != TIME_TOKEN_ADDRESS) {
            require(msg.value > 0, "Please deposit some amount");
            availableNative += msg.value;
        }
    }

    /**
     * @dev Common function to anticipate gains earned from investments from deposited amount
     * @param timeAmount TIME token amount used to anticipate the earnings in terms of blocks
     **/
    function _anticipateEarnings(uint256 timeAmount) private {
        earned[msg.sender] += queryAnticipatedEarnings(msg.sender, timeAmount);
        totalAnticipatedTime += timeAmount;
        remainingTime[address(this)] += timeAmount;
    }

    /**
     * @dev Burn TIME according to the amount set from selected depositant
     * @param timeToken The instance of TIME Token contract
     * @param depositant Address of depositant account
     * @param amount Amount to be burned
     **/
    function _burnTime(ITimeToken timeToken, address depositant, uint256 amount) private {
        if (amount > timeToken.balanceOf(address(this)))
            amount = timeToken.balanceOf(address(this));
        try timeToken.burn(amount) {
            totalBurnedTime += amount;
            remainingTime[depositant] -= amount;
        } catch {
            revert("Unable to burn TIME");
        }
    }

    /**
     * @dev Claim the withdrawable amount earned from the TIME Community Pool
     * @param timeToken The instance of TIME Token contract
     * @return earnings The amount earned from TIME Token Community Pool
     **/
    function _claimEarningsFromTime(ITimeToken timeToken) private returns (uint256 earnings) {
        uint256 currentBalance = address(this).balance;
        if (timeToken.withdrawableShareBalance(address(this)) > 0) {
            try timeToken.withdrawShare() {
                earnings = (address(this).balance - currentBalance);
                _payComission(earnings / 2);
                earnings /= 2;
                return earnings;
            } catch {
                return earnings;
            }
        } else {
            return earnings;
        }
    }

    /**
     * @dev Compound earned amount from selected depositant
     * @param depositant Address of depositant account
     **/
    function _compoundDepositantEarnings(address depositant) private {
        if (earned[depositant] > 0) {
            require(availableNative >= earned[depositant], "Not enough amount to transfer");
            availableNative -= earned[depositant];
            deposited[depositant] += earned[depositant];
            currentDepositedNative += earned[depositant];
            earned[depositant] = 0;
        }        
    }

    /**
     * @dev Claim earnings from TIME contract and buy 10% of them in TIME tokens 
     * @param timeToken The instance of TIME Token contract
     **/
    function _earnInterestAndAllocate(ITimeToken timeToken) private {
        uint256 earnedNative = _claimEarningsFromTime(timeToken);
        totalEarnedNative += earnedNative;
        _saveTime(timeToken, earnedNative / 10);
        availableNative += (earnedNative - (earnedNative / 10));
    }

    /**
     * @notice Called when need to pay comission for miner (block.coinbase) and developer
     * @param comissionAmount The total comission amount in ETH which will be paid
    **/
    function _payComission(uint256 comissionAmount) private {
        if (comissionAmount > 0) {
            uint256 share = comissionAmount / 4;
            _saveTime(ITimeToken(TIME_TOKEN_ADDRESS), share);
            payable(DEVELOPER_ADDRESS).transfer(share);
            availableNative += share;
            totalEarnedNative += share;
            if (block.coinbase == address(0))
                payable(DEVELOPER_ADDRESS).transfer(share);
            else
                payable(block.coinbase).transfer(share);
        }
    }

    /**
     * @dev Buy (save) TIME tokens from the TIME Token contract and update the amount to be burned
     * @param timeToken The instance of TIME Token contract
     * @param amountToSave Amount to be bought
     **/
    function _saveTime(ITimeToken timeToken, uint256 amountToSave) private {
        if (amountToSave > 0) {
            require(address(this).balance >= amountToSave, "Not enough amount to save TIME");
            uint256 currentTime = timeToken.balanceOf(address(this));
            try timeToken.saveTime{value: amountToSave}() {
                uint256 timeSaved = (timeToken.balanceOf(address(this)) - currentTime);
                remainingTime[address(this)] += timeSaved;
                totalTimeSaved += timeSaved;
            } catch { 
                revert("Not able to save TIME");
            }
        }
    }

    /**
     * @dev Withdraw all available earnings to the depositant address
     * @param depositant Address of depositant account
     **/
    function _transferDepositantEarnings(address depositant) private {
        if (earned[depositant] > 0) {
            require(availableNative >= earned[depositant], "Not enough amount to transfer");
            availableNative -= earned[depositant];
            payable(depositant).transfer(earned[depositant]);
            earned[depositant] = 0;
        }
    }

    /**
     * @dev Withdraw all deposited amount to the depositant address and transfer the deposited TIME from depositant to the Employer account
     **/
    function _withdraw() private {
        require(deposited[msg.sender] > 0, "Depositant does not have any amount to withdraw");
        require(currentDepositedNative >= deposited[msg.sender], "Not enough in contract to withdraw");
        remainingTime[address(this)] += remainingTime[msg.sender];
        remainingTime[msg.sender] = 0;
        currentDepositedNative -= deposited[msg.sender];
        payable(msg.sender).transfer(deposited[msg.sender]);
        deposited[msg.sender] = 0;       
    }

    /**
     * @dev Deposit only TIME in order to anticipate interest over previous deposited ETH
     * @notice Pre-condition: the depositant must have previous deposited ETH and also should approve (allow to spend) the TIME tokens to deposit. Anticipation is mandatory in this case
     * @param timeAmount The amount in TIME an investor should deposit to anticipate
     **/
    function anticipate(uint256 timeAmount) public payable nonReentrant update(false) {
        require(deposited[msg.sender] > 0, "Depositant does not have any amount to anticipate");
        require(timeAmount > 0, "Please deposit some TIME amount");
        ITimeToken timeToken = ITimeToken(TIME_TOKEN_ADDRESS);
        require(timeToken.allowance(msg.sender, address(this)) >= timeAmount, "Should allow TIME to be spent");
        try timeToken.transferFrom(msg.sender, address(this), timeAmount) {
            totalDepositedTime += timeAmount;
            _anticipateEarnings(timeAmount);
        } catch {
            revert("Problem when transferring TIME");
        }
    }      

    /**
     * @dev Calculate the anticipation fee an investor needs to pay in order to anticipate TIME Tokens in the Employer contract
     * @return fee The fee amount calculated
     **/
    function anticipationFee() public view returns (uint256) {
        return (ITimeToken(TIME_TOKEN_ADDRESS).fee() * 11);
    }

    /**
     * @dev Compound available earnings into the depositant account
     * @notice Pre-condition: the depositant should approve (allow to spend) the TIME tokens to deposit. Also, if they want to anticipate yield, they must enabled anticipation before the function call
     * @param timeAmount (Optional. Can be zero) The amount of TIME Tokens an investor wants to continue receiveing or anticipating earnings 
     * @param mustAnticipateTime Informs whether an investor wants to anticipate earnings to be compounded
     **/
    function compound(uint256 timeAmount, bool mustAnticipateTime) public nonReentrant update(true) {
        require(deposited[msg.sender] > 0, "Depositant does not have any amount to compound");
        if (mustAnticipateTime) 
            require(anticipationEnabled[msg.sender], "Depositant is not enabled to anticipate TIME");
        if (timeAmount > 0) {
            ITimeToken timeToken = ITimeToken(TIME_TOKEN_ADDRESS);
            require(timeToken.allowance(msg.sender, address(this)) >= timeAmount, "Should allow TIME to be spent");
            try timeToken.transferFrom(msg.sender, address(this), timeAmount) {
                totalDepositedTime += timeAmount;
                if (mustAnticipateTime) {
                    _anticipateEarnings(timeAmount);
                } else {
                    remainingTime[msg.sender] += timeAmount;               
                }
            } catch {
                revert("Problem when transferring TIME");
            }
        }
    }

    /**
     * @dev Deposit ETH and TIME in order to earn interest over them
     * @notice Pre-condition: the depositant should approve (allow to spend) the TIME tokens to deposit. Also, if they want to anticipate yield, they must enabled anticipation before the function call
     * @param timeAmount The amount in TIME an investor should deposit
     * @param mustAnticipateTime Informs if the depositant wants to anticipate the yield or not
     **/
    function deposit(uint256 timeAmount, bool mustAnticipateTime) public payable nonReentrant update(false) {
        require(msg.value > 0, "Please deposit some amount");
        require(timeAmount > 0, "Please deposit some TIME amount");
        if (mustAnticipateTime)
            require(anticipationEnabled[msg.sender], "Depositant is not enabled to anticipate TIME");
        ITimeToken timeToken = ITimeToken(TIME_TOKEN_ADDRESS);
        require(timeToken.allowance(msg.sender, address(this)) >= timeAmount, "Should allow TIME to be spent");

        uint256 comission = msg.value / 50;
        uint256 depositAmount = msg.value - comission;
        deposited[msg.sender] += depositAmount;
        currentDepositedNative += depositAmount;
        totalDepositedNative += msg.value;
        try timeToken.transferFrom(msg.sender, address(this), timeAmount) {
            totalDepositedTime += timeAmount;
            if (mustAnticipateTime) {
                _anticipateEarnings(timeAmount);
            } else {
                remainingTime[msg.sender] += timeAmount;               
            }
            _payComission(comission);
        } catch {
            revert("Problem when transferring TIME");
        }
    }

    /**
     * @dev Public call for earning interest for Employer (if it has any to receive)
     **/
    function earn() public nonReentrant {
        _earnInterestAndAllocate(ITimeToken(TIME_TOKEN_ADDRESS));
    }

    /**
     * @dev Enable an investor to anticipate yields using TIME tokens
     **/
    function enableAnticipation() public payable nonReentrant update(false) {
        require(!anticipationEnabled[msg.sender], "Address is already enabled for TIME anticipation");
        uint256 fee = ITimeToken(TIME_TOKEN_ADDRESS).fee() * 10;
        require(msg.value >= fee, "Please provide the enough fee amount to enable TIME anticipation");
        uint256 comission = fee / 5;
        _payComission(comission);
        totalEarnedNative += msg.value;
        availableNative += (msg.value - comission);
        anticipationEnabled[msg.sender] = true;
    }

    /**
     * @dev Inform the current Return Of Investment the Employer contract is giving
     * @return roi The current amount returned to investors
     **/
    function getCurrentROI() public view returns (uint256) {
        if (availableNative == 0)
            return 0;
        if (currentDepositedNative == 0)
            return 10**50;
        return ((availableNative * FACTOR) / currentDepositedNative);
    }

    /**
     * @dev Inform the current Return Of Investment per Block the Employer contract is giving
     * @return roi The current amount per block returned to investors
     **/
    function getCurrentROIPerBlock() public view returns (uint256) {
        return ((getCurrentROI() * FACTOR) / ONE_YEAR);
    }

    /**
     * @dev Inform the historical Return Of Investment the Employer contract is giving
     * @return roi The historical amount returned to investors
     **/
    function getROI() public view returns (uint256) {
        if (totalEarnedNative == 0)
            return 0;
        if (totalDepositedNative == 0)
            return 10**50;
        return ((totalEarnedNative * FACTOR) / totalDepositedNative); 
    }

    /**
     * @dev Inform the historical Return Of Investment per Block the Employer contract is giving
     * @return roi The historical amount per block returned to investors
     **/
    function getROIPerBlock() public view returns (uint256) {
        return ((getROI() * FACTOR) / ONE_YEAR);
    }

    /**
     * @dev Inform the earnings an investor can anticipate (without waiting for a given time) according to the informed TIME amount
     * @param depositant Address of the depositant account
     * @param anticipatedTime Amount of TIME informed by a depositant as anticipation
     * @return earnings Amount a depositant can anticipate
     **/
    function queryAnticipatedEarnings(address depositant, uint256 anticipatedTime) public view returns (uint256) {
        return ((availableNative * anticipatedTime * deposited[depositant]) / ((ONE_YEAR * currentDepositedNative) + 1));
    }

    /**
     * @dev Inform the earnings an investor can currently receive
     * @param depositant Address of the depositant account
     * @return earnings Amount a depositant can receive
     **/
    function queryEarnings(address depositant) public view returns (uint256) {
        uint256 numberOfBlocks = (block.number - lastBlock[depositant]) * D;
        if (numberOfBlocks <= remainingTime[depositant]) {       
            return ((availableNative * numberOfBlocks * deposited[depositant]) / ((ONE_YEAR * currentDepositedNative) + 1));
        } else {
            return ((availableNative * remainingTime[depositant] * deposited[depositant]) / ((ONE_YEAR * currentDepositedNative) + 1));
        }
    }

    /**
     * @dev Withdraw earnings (only) of a depositant (msg.sender)
     * @notice All functions are in modifiers. It only checks if the depositant has earning something
     **/
    function withdrawEarnings() public nonReentrant update(false) {
        require(earned[msg.sender] > 0, "Depositant does not have any earnings to withdraw");
    }

    /**
     * @dev Withdraw all deposited values of a depositant (msg.sender)
     **/
    function withdrawDeposit() public nonReentrant update(false) {
        _withdraw();
    }

    /**
     * @dev Withdraw all deposited values of a depositant (msg.sender) without any check for earnings (emergency)
     **/
    function withdrawDepositEmergency() public nonReentrant {
        _withdraw();
    }
}