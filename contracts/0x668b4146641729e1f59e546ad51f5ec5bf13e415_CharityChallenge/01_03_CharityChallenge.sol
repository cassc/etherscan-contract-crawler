pragma solidity ^0.5.2;

import "./IRealityCheck.sol";
import "./SafeMath.sol";

contract CharityChallenge {
    using SafeMath for uint256;
    using SafeMath for uint8;

    event Received(address indexed sender, uint256 value);

    event Donated(address indexed npo, uint256 value);

    event Failed();

    event Fee(address indexed maker, uint256 value);

    event Claimed(address indexed claimer, uint256 value);

    event SafetyHatchClaimed(address indexed claimer, uint256 value);

    string public constant VERSION = "0.4.1";

    address payable public contractOwner;

    // key is npo address, value is ratio
    mapping(address => uint8) public npoRatios;

    uint8 sumRatio;

    address payable[] public npoAddresses;

    uint8 public npoLength;

    address public marketAddress;

    bool public unlockOnNo;

    IRealityCheck realityCheck;

    string public question;

    address public arbitrator;

    uint256 public timeout;

    bytes32 public questionId;

    uint256 public challengeEndTime;

    // For a fee of 10.5%, pass 1050
    uint256 public makerFee;

    uint256 public challengeSafetyHatchTime1;

    uint256 public challengeSafetyHatchTime2;

    // Valid outcomes are 'YES', 'NO' and 'INVALID'
    bool public isEventFinalized;

    // hasChallengeAccomplished will be set to true if we got the expected
    // result that allow to unlock the funds.
    bool public hasChallengeAccomplished;

    bool private safetyHatchClaimSucceeded;

    mapping(address => uint256) public donorBalances;

    uint256 public donorCount;

    uint256 public contributedAmount;

    // We use a divider of 10000 instead of 100 to have more granularity for
    // the maker fee
    uint256 constant feeDivider = 10000;

    bool private mReentrancyLock = false;
    modifier nonReentrant() {
        require(!mReentrancyLock);
        mReentrancyLock = true;
        _;
        mReentrancyLock = false;
    }

    constructor(
        address payable _contractOwner,
        address payable[] memory _npoAddresses,
        uint8[] memory _ratios,
        address _marketAddress,
        string memory _question,
        address _arbitrator,
        uint256 _timeout,
        uint256 _challengeEndTime,
        uint256 _makerFee,
        bool _unlockOnNo
    ) public
    {
        require(_npoAddresses.length == _ratios.length);
        require(makerFee < feeDivider);
        npoLength = uint8(_npoAddresses.length);
        for (uint8 i = 0; i < npoLength; i++) {
            address payable npo = _npoAddresses[i];
            npoAddresses.push(npo);
            require(_ratios[i] > 0, "Ratio must be a positive number");
            npoRatios[npo] = _ratios[i];
            sumRatio += _ratios[i];
        }
        contractOwner = _contractOwner;
        marketAddress = _marketAddress;
        realityCheck = IRealityCheck(_marketAddress);
        question = _question;
        arbitrator = _arbitrator;
        timeout = _timeout;
        challengeEndTime = _challengeEndTime;
        makerFee = _makerFee;
        questionId = realityCheck.askQuestion(0, question, arbitrator, uint32(timeout), uint32(challengeEndTime), 0);
        unlockOnNo = _unlockOnNo;
        challengeSafetyHatchTime1 = challengeEndTime + 26 weeks;
        challengeSafetyHatchTime2 = challengeSafetyHatchTime1 + 52 weeks;
        isEventFinalized = false;
        hasChallengeAccomplished = false;
    }

    function() external payable {
        require(now <= challengeEndTime);
        require(msg.value > 0);
        if (donorBalances[msg.sender] == 0 && msg.value > 0) {
            donorCount++;
        }
        donorBalances[msg.sender] += msg.value;
        contributedAmount += msg.value;
        emit Received(msg.sender, msg.value);
    }

    function balanceOf(address _donorAddress) public view returns (uint256) {
        if (safetyHatchClaimSucceeded) {
            return 0;
        }
        return donorBalances[_donorAddress];
    }

    function finalize() nonReentrant external {
        require(now > challengeEndTime);
        require(now <= challengeSafetyHatchTime1);
        require(!isEventFinalized);
        doFinalize();
    }

    function doFinalize() private {
        bool hasError;
        (hasChallengeAccomplished, hasError) = checkRealitio();
        if (!hasError) {
            isEventFinalized = true;
            if (hasChallengeAccomplished) {
                uint length = npoAddresses.length;
                if (makerFee > 0) {
                    uint256 amount = address(this).balance.mul(makerFee).div(feeDivider);
                    contractOwner.transfer(amount);
                    emit Fee(contractOwner, amount);
                }
                for (uint i = 0; i < length - 1; i++) {
                    address payable npo = npoAddresses[i];
                    uint8 ratio = npoRatios[npo];
                    uint256 amount = address(this).balance.mul(ratio).div(sumRatio);
                    npo.transfer(amount);
                    emit Donated(npo, amount);
                }
                // Don't want to keep any amount in the contract
                uint256 amount = address(this).balance;
                address payable npo = npoAddresses[length - 1];
                npo.transfer(amount);
                emit Donated(npo, amount);
            } else {
                emit Failed();
            }
        }
    }

    function getExpectedDonationAmount(address payable _npo) view external returns (uint256) {
        require(npoRatios[_npo] > 0);
        uint256 amountForNPO = address(this).balance.sub(address(this).balance.mul(makerFee).div(feeDivider));
        uint8 ratio = npoRatios[_npo];
        return amountForNPO.mul(ratio).div(sumRatio);
    }

    function claim() nonReentrant external {
        require(now > challengeEndTime);
        require(isEventFinalized || now > challengeSafetyHatchTime1);
        require(!hasChallengeAccomplished || now > challengeSafetyHatchTime1);
        require(balanceOf(msg.sender) > 0);

        uint256 claimedAmount = balanceOf(msg.sender);
        donorBalances[msg.sender] = 0;
        msg.sender.transfer(claimedAmount);
        emit Claimed(msg.sender, claimedAmount);
    }

    function safetyHatchClaim() external {
        require(now > challengeSafetyHatchTime2);
        require(msg.sender == contractOwner);

        uint totalContractBalance = address(this).balance;
        safetyHatchClaimSucceeded = true;
        contractOwner.transfer(address(this).balance);
        emit SafetyHatchClaimed(contractOwner, totalContractBalance);
    }

    function checkRealitio() public view returns (bool happened, bool errored) {
        if (realityCheck.isFinalized(questionId)) {
            bytes32 answer = realityCheck.getFinalAnswer(questionId);
            if (answer == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
                // Treat 'invalid' outcome as 'no'
                // because 'invalid' is one of the valid outcomes
                return (false, false);
            } else {
                if (unlockOnNo) {
                    return (answer == 0x0000000000000000000000000000000000000000000000000000000000000000, false);
                }
                return (answer == 0x0000000000000000000000000000000000000000000000000000000000000001, false);
            }
        } else {
            return (false, true);
        }
    }
}
