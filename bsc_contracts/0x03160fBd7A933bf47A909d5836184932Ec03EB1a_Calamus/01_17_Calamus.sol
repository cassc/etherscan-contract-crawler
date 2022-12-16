// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./IPlatformFee.sol";
import "./ICalamus.sol";
import "./Types.sol";
import "./CarefulMath.sol";

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";

contract Calamus is Initializable, OwnableUpgradeable, ICalamus, IPlatformFee, ReentrancyGuardUpgradeable, CarefulMath, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;
    uint256 public nextStreamId;
    uint32 constant private DENOMINATOR = 10000;

    mapping (address => uint256) public ownerToStreams;
    mapping (address => uint256) public recipientToStreams;
    mapping (uint256 => Types.Stream) public streams;
    mapping (address => uint256) private contractFees;
    mapping (address => uint32) private withdrawFeeAddresses;
    address[] private withdrawAddresses;

    EnumerableMapUpgradeable.AddressToUintMap addressFees;
    uint32 public rateFee;

    function initialize(uint32 initialFee) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        rateFee = initialFee;
        nextStreamId = 1;
    }

    modifier isAllowAddress(address allowAddress) {
        require(allowAddress != address(0x00), "Address can't be zero");
        require(allowAddress != address(this), "Address can't be this contract address");
        _;
    }

    modifier streamExists(uint256 streamId) {
        require(streams[streamId].streamId >= 0, "stream does not exist");
        _;
    }

    function setRateFee(uint32 newRateFee) public override onlyOwner {
        rateFee = newRateFee;
        emit SetRateFee(newRateFee);
    }

    function deltaOf(uint256 streamId) public view streamExists(streamId) returns (uint256 delta) {
        Types.Stream memory stream = streams[streamId];
        if (block.timestamp <= stream.startTime) return 0;
        if (block.timestamp < stream.stopTime) return block.timestamp - stream.startTime;
        return stream.stopTime - stream.startTime;
    }

    struct FeeVars {
        bool exists;
        uint256 value;
    }

    function feeOf(address userAddress, address tokenAddress) external view returns (uint256 fee) {
        return _feeOf(userAddress, tokenAddress);
    }

    function _feeOf(address userAddress, address tokenAddress) private view returns (uint256 fee) {
        FeeVars memory vars;
        (vars.exists, vars.value) = addressFees.tryGet(userAddress);
        if (vars.exists) {
            return vars.value;
        }
        (vars.exists, vars.value) = addressFees.tryGet(tokenAddress);
        if (vars.exists) {
            return vars.value;
        }
        return uint256(rateFee);
    }

    struct BalanceOfLocalVars {
        MathError mathErr;
        uint256 recipientBalance;
        uint256 releaseTimes;
        uint256 withdrawalAmount;
        uint256 senderBalance;
    }

    function balanceOf(uint256 streamId, address who) public override view streamExists(streamId) returns (uint256 balance) {
        Types.Stream memory stream = streams[streamId];
        BalanceOfLocalVars memory vars;

        uint256 delta = deltaOf(streamId);
        (vars.mathErr, vars.releaseTimes) = divUInt(delta, stream.releaseFrequency);
        uint256 duration = stream.stopTime - stream.startTime;

        if (delta == duration) {
            vars.recipientBalance = stream.releaseAmount;
        } else if (vars.releaseTimes > 0 && vars.mathErr == MathError.NO_ERROR) {
            (vars.mathErr, vars.recipientBalance) = mulUInt(stream.releaseFrequency * vars.releaseTimes, stream.releaseAmount);
            if (vars.mathErr == MathError.NO_ERROR) {
                vars.recipientBalance /= duration;
            } else {
                (vars.mathErr, vars.recipientBalance) = mulUInt(stream.releaseFrequency * vars.releaseTimes, stream.releaseAmount / duration);
            }
        }

        if (stream.vestingAmount > 0 && delta > 0) {
            vars.recipientBalance += stream.vestingAmount;
        }

        require(vars.mathErr == MathError.NO_ERROR, "recipient balance calculation error");

        /*
         * If the stream `balance` does not equal `deposit`, it means there have been withdrawals.
         * We have to subtract the total amount withdrawn from the amount of money that has been
         * streamed until now.
         */
        uint256 totalRelease = stream.releaseAmount + stream.vestingAmount;
        if (totalRelease > stream.remainingBalance) {
            (vars.mathErr, vars.withdrawalAmount) = subUInt(totalRelease, stream.remainingBalance);
            assert(vars.mathErr == MathError.NO_ERROR);
            (vars.mathErr, vars.recipientBalance) = subUInt(vars.recipientBalance, vars.withdrawalAmount);
            /* `withdrawalAmount` cannot and should not be bigger than `recipientBalance`. */
            assert(vars.mathErr == MathError.NO_ERROR);
        }

        if (who == stream.recipient) return vars.recipientBalance;
        if (who == stream.sender) {
            (vars.mathErr, vars.senderBalance) = subUInt(stream.remainingBalance, vars.recipientBalance);
            /* `recipientBalance` cannot and should not be bigger than `remainingBalance`. */
            assert(vars.mathErr == MathError.NO_ERROR);
            return vars.senderBalance;
        }
        return 0;
    }

    struct CreateStreamLocalVars {
        MathError mathErr;
        uint256 duration;
        uint256 vestingAmount;
    }

    function _createStream(
        uint256 releaseAmount,
        address recipient,
        uint256 startTime,
        uint256 stopTime,
        uint32 vestingRelease,
        uint256 releaseFrequency,
        uint8 transferPrivilege,
        uint8 cancelPrivilege,
        address tokenAddress
    )
    internal
    {
        require(startTime >= block.timestamp, "start time before block.timestamp");
        require(stopTime > startTime, "stop time before the start time");
        require(recipient != address(0x00), "stream to the zero address");
        require(recipient != address(this), "stream to the contract itself");
        require(recipient != msg.sender, "stream to the caller");
        require(releaseAmount > 0, "deposit is zero");
        require(vestingRelease <= DENOMINATOR, "vesting release is too much");
        require(releaseFrequency > 0, "release frequency is zero");

        CreateStreamLocalVars memory vars;
        (vars.mathErr, vars.duration) = subUInt(stopTime, startTime);
        /* `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know `stopTime` is higher than `startTime`. */
        assert(vars.mathErr == MathError.NO_ERROR);
        require(vars.duration >= releaseFrequency, "Duration is smaller than frequency");

        uint256 releaseAmountAfterFee = _getReleaseAmountAfterFee(tokenAddress, releaseAmount, msg.value);
        (vars.mathErr, vars.vestingAmount) = mulUInt(releaseAmountAfterFee, vestingRelease);

        assert(vars.mathErr == MathError.NO_ERROR);

        vars.vestingAmount /= DENOMINATOR;

        contractFees[(tokenAddress == address(this)) ? address(0) : tokenAddress] += releaseAmount - releaseAmountAfterFee;
        Types.Stream memory stream = Types.Stream(
            nextStreamId,
            msg.sender,
            releaseAmountAfterFee - vars.vestingAmount,
            releaseAmountAfterFee,
            startTime,
            stopTime,
            vars.vestingAmount,
            releaseFrequency,
            transferPrivilege,
            cancelPrivilege,
            recipient,
            (tokenAddress == address(this)) ? address(0) : tokenAddress,
            1
        );

        /* Create and store the stream object. */
        streams[nextStreamId] = stream;
        ownerToStreams[msg.sender] += 1;
        recipientToStreams[recipient] +=1;
        /* Increment the next stream id. */
        nextStreamId += 1;
        emit CreateStream(
            stream.streamId,
            stream.sender,
            stream.recipient,
            stream.releaseAmount,
            stream.startTime,
            stream.stopTime,
            vestingRelease,
            stream.releaseFrequency,
            stream.transferPrivilege,
            stream.cancelPrivilege,
            stream.tokenAddress
        );
    }

    function _getReleaseAmountAfterFee(address tokenAddress, uint256 releaseAmount, uint256 msgValue) internal view returns (uint256) {
        bool isUsingNativeToken = (tokenAddress == address(this));
        uint256 fee = _feeOf(msg.sender, tokenAddress);
        uint256 releaseAmountAfterFee = (releaseAmount * DENOMINATOR / (DENOMINATOR + fee)) ;
        if (isUsingNativeToken) {
            releaseAmountAfterFee = (msgValue * DENOMINATOR / (DENOMINATOR + fee));
        }
        return releaseAmountAfterFee;
    }

    function createStream(
        uint256 releaseAmount,
        address recipient,
        uint256 startTime,
        uint256 stopTime,
        uint32 vestingRelease,
        uint256 releaseFrequency,
        uint8 transferPrivilege,
        uint8 cancelPrivilege,
        address tokenAddress
    ) public payable override whenNotPaused nonReentrant  {
        _createStream(
            releaseAmount,
            recipient,
            startTime,
            stopTime,
            vestingRelease,
            releaseFrequency,
            transferPrivilege,
            cancelPrivilege,
            tokenAddress
        );

        if (tokenAddress != address(this)) {
            _transferFrom(tokenAddress, releaseAmount);
        }

    }

    function _transferFrom(address tokenAddress, uint256 releaseAmount) internal {
        IERC20Upgradeable(tokenAddress).transferFrom(msg.sender, address(this), releaseAmount);
    }

    function _transfer(address tokenAddress, address to, uint256 amount) internal {
        IERC20Upgradeable(tokenAddress).transfer(to, amount);
    }

    function getOwnerToStreams(address owner) public view returns (Types.Stream[] memory) {
        uint256 streamCount = 0;
        Types.Stream[] memory filterStreams = new Types.Stream[](ownerToStreams[owner]);

        for (uint i=1; i < nextStreamId; i++) {
            if (streams[i].sender == owner) {
                filterStreams[streamCount] = streams[i];
                streamCount++;
            }
        }
        return filterStreams;
    }

    function getRecipientToStreams(address recipient) public view returns (Types.Stream[] memory) {
        uint256 streamCount = 0;
        Types.Stream[] memory filterStreams = new Types.Stream[](recipientToStreams[recipient]);

        for (uint i=1; i < nextStreamId; i++) {
            if (streams[i].recipient == recipient) {
                filterStreams[streamCount] = streams[i];
                streamCount++;
            }
        }
        return filterStreams;
    }

    function withdrawFromStream(uint256 streamId, uint256 amount)
    public
    override
    whenNotPaused
    nonReentrant
    streamExists(streamId)
    {
        Types.Stream memory stream = streams[streamId];
        require(amount > 0, "amount is zero");
        require(stream.status == 1, "Stream is not active");
        require(stream.recipient == msg.sender, "Only Recipient can withdraw");
        uint256 balance = balanceOf(streamId, stream.recipient);
        require(balance >= amount, "amount exceeds the available balance");

        MathError mathErr;
        (mathErr, streams[streamId].remainingBalance) = subUInt(stream.remainingBalance, amount);
        /**
         * `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know that `remainingBalance` is at least
         * as big as `amount`.
         */
        assert(mathErr == MathError.NO_ERROR);

        // Should not delete stream.
        if (streams[streamId].remainingBalance == 0) {
            streams[streamId].status = 3;
        }
        if (stream.tokenAddress != address(0x00)) {
            _transfer(stream.tokenAddress, stream.recipient, amount );
        } else {
            payable(stream.recipient).transfer(amount);
        }

        emit WithdrawFromStream(streamId, stream.recipient, amount);
    }

    function _checkCancelPermission(Types.Stream memory stream) internal view returns (bool) {
        address sender = msg.sender;
        address streamSender = stream.sender;
        address recipient = stream.recipient;
        if (stream.cancelPrivilege == 0) {
            return (sender == recipient);
        } else if (stream.cancelPrivilege == 1) {
            return (sender == streamSender);
        } else if (stream.cancelPrivilege == 2) {
            return true;
        } else if (stream.cancelPrivilege == 3) {
            return false;
        } else {
            return false;
        }
    }

    function _checkTransferPermission(Types.Stream memory stream) internal view returns (bool) {
        address sender = msg.sender;
        address streamSender = stream.sender;
        address recipient = stream.recipient;
        if (stream.transferPrivilege == 0) {
            return (sender == recipient);
        } else if (stream.transferPrivilege == 1) {
            return (sender == streamSender);
        } else if (stream.transferPrivilege == 2) {
            return true;
        } else if (stream.transferPrivilege == 3) {
            return false;
        } else {
            return false;
        }
    }

    // Who cancel Stream feature is not check at here
    function cancelStream(uint256 streamId)
    public
    override
    whenNotPaused
    nonReentrant
    streamExists(streamId)
    {
        Types.Stream memory stream = streams[streamId];
        require(stream.status == 1, "Stream is not active");
        require(_checkCancelPermission(stream), "Don't have permission to cancel stream");
        uint256 senderBalance = balanceOf(streamId, stream.sender);
        uint256 recipientBalance = balanceOf(streamId, stream.recipient);

        streams[streamId].status = 2;

        IERC20Upgradeable token = IERC20Upgradeable(stream.tokenAddress);
        if (recipientBalance > 0) {
            MathError mathErr;
            (mathErr, streams[streamId].remainingBalance) = subUInt(stream.remainingBalance, recipientBalance);
            assert(mathErr == MathError.NO_ERROR);
            if (stream.tokenAddress != address(0x00)) {

                token.transfer(stream.recipient, recipientBalance);

            } else {

                payable(stream.recipient).transfer(recipientBalance);

            }
        }


        if (senderBalance > 0) {
            if (stream.tokenAddress != address(0x00)) {

                _transfer(stream.tokenAddress, stream.sender, senderBalance );

            } else {
                payable(stream.sender).transfer(senderBalance);
            }
        }

        emit CancelStream(streamId, stream.sender, stream.recipient, senderBalance, recipientBalance);
    }

    function _changeStreamOwner(uint256 streamId, address newRecipient) internal {
        Types.Stream memory stream = streams[streamId];
        (MathError mathErr, uint256 oldRecipientCount) = divUInt(recipientToStreams[stream.recipient], 1);
        assert(mathErr == MathError.NO_ERROR);
        recipientToStreams[stream.recipient] = oldRecipientCount;
        recipientToStreams[newRecipient] += 1;
        streams[streamId].recipient = newRecipient;
    }

    function transferStream(uint256 streamId, address newRecipient)
    public
    override
    whenNotPaused
    nonReentrant
    streamExists(streamId) {
        Types.Stream memory stream = streams[streamId];
        require(stream.status == 1, "Stream is not active");
        require(_checkTransferPermission(stream), "Don't have permission to transfer stream");
        require(newRecipient != stream.recipient, "New recipient is the same with old recipient");
        require(newRecipient != address(0x00), "stream to the zero address");
        require(newRecipient != address(this), "stream to the contract itself");
        require(newRecipient != msg.sender, "stream to the caller");
        uint256 recipientBalance = balanceOf(streamId, stream.recipient);

        _changeStreamOwner(streamId, newRecipient);

        if (recipientBalance > 0) {
            MathError mathErr;
            (mathErr, streams[streamId].remainingBalance) = subUInt(stream.remainingBalance, recipientBalance);
            assert(mathErr == MathError.NO_ERROR);

            if (stream.tokenAddress != address(0x00)) {

                _transfer(stream.tokenAddress, stream.recipient, recipientBalance );

            } else {

                payable(stream.recipient).transfer(recipientBalance);

            }

        }

        emit TransferStream(streamId, stream.sender, newRecipient, recipientBalance);
    }
    
    function topupStream(uint256 streamId, uint256 amount)
        public
        payable
        override
        whenNotPaused
        nonReentrant
        streamExists(streamId)
    {
        Types.Stream memory stream = streams[streamId];
        require(stream.status == 1, "Stream is not active");
        require(
            stream.sender == msg.sender,
            "Don't have permission to topup stream"
        );
        require(amount > 0, "Topup amount must be greator than zero");
        require(block.timestamp < stream.stopTime, "Stream has ended");

        if (stream.tokenAddress != address(0)) {
            _transferFrom(stream.tokenAddress, amount);
        }
        uint256 amountAfterFee = _getReleaseAmountAfterFee(
            stream.tokenAddress,
            amount,
            msg.value
        );
        contractFees[(stream.tokenAddress == address(this)) ? address(0) : stream.tokenAddress] += amount - amountAfterFee;
        streams[streamId].releaseAmount += amountAfterFee;
        streams[streamId].remainingBalance += amountAfterFee;
        streams[streamId].stopTime =
            stream.stopTime +
            (amountAfterFee * (stream.stopTime - stream.startTime)) /
            stream.releaseAmount;
        emit TopupStream(streamId, amountAfterFee, streams[streamId].stopTime);
    }

    function addWithdrawFeeAddress(address allowAddress, uint32 percentage) public override onlyOwner isAllowAddress(allowAddress) {
        require(percentage > 0, "Percentage muse be greater than zero");
        withdrawFeeAddresses[allowAddress] = percentage;
        withdrawAddresses.push(allowAddress);
        emit AddWithdrawFeeAddress(allowAddress, percentage);
    }

    function removeWithdrawFeeAddress(address allowAddress) public override onlyOwner returns(bool) {
        uint32 percentage = withdrawFeeAddresses[allowAddress];
        if (percentage > 0) {
            delete withdrawFeeAddresses[allowAddress];
            for (uint32 i = 0; i < withdrawAddresses.length; i++) {
                if (withdrawAddresses[i] == allowAddress) {
                    delete withdrawAddresses[i];
                    break;
                }
            }
            emit RemoveWithdrawFeeAddress(allowAddress);
            return true;
        }
        return false;
    }

    function getWithdrawFeeAddresses() public override view onlyOwner returns(Types.WithdrawFeeAddress[] memory) {

        Types.WithdrawFeeAddress[] memory addresses = new Types.WithdrawFeeAddress[](withdrawAddresses.length);

        for (uint32 i=0; i< withdrawAddresses.length; i++ ) {
            addresses[i] = Types.WithdrawFeeAddress(
                withdrawAddresses[i],
                withdrawFeeAddresses[withdrawAddresses[i]]
            );
        }
        return addresses;
    }

    function isAllowWithdrawingFee(address allowAddress) public override view onlyOwner returns (bool) {
        uint32 percentage = withdrawFeeAddresses[allowAddress];
        if (percentage > 0) {
            return true;
        }
        return false;
    }

    function getContractFee(address tokenAddress) public override view returns(uint256) {
        if (tokenAddress == address(this)) {
            return contractFees[address(0)];
        }
        return contractFees[tokenAddress];
    }

    function withdrawFee(address to, address tokenAddress, uint256 amount) public override whenNotPaused nonReentrant onlyOwner  returns(bool) {
        uint256 feeBalance = contractFees[(tokenAddress == address(this))? address(0x00) : tokenAddress];

        require(isAllowWithdrawingFee(to), "The address is not allowed withdrawing fee");
        require(to != address(this), "Could not withdraw to the contract itself");
        require(feeBalance >= amount, "Could not withdraw amount greater than fee balance");

        uint256 allowAmount = (feeBalance * withdrawFeeAddresses[to] / 100);
        require(amount <= allowAmount, "Exceed allowed amount to withdraw");
        if (tokenAddress != address(this)) {

            _transfer(tokenAddress, to, amount );

        } else {
            payable(to).transfer(amount);
        }
        emit WithdrawFee(tokenAddress, to, amount);
        return true;
    }

    function pause() public onlyOwner {
        _pause();
    }
    function unpause() public onlyOwner {
        _unpause();
    }

    function addWhitelistAddress(address whitelistAddress, uint256 fee) public onlyOwner {
        addressFees.set(whitelistAddress, fee);
    }

    function removeWhitelistAddress(address whitelistAddress) public onlyOwner {
        addressFees.remove(whitelistAddress);
    }
}