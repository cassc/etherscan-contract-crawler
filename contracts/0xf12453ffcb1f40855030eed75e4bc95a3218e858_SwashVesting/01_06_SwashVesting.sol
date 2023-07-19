//"SPDX-License-Identifier: MIT"
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SwashVesting is Ownable {
    using SafeERC20 for IERC20;
    uint256 public startDate;
    uint256 internal constant periodLength = 1 days;
    uint256 public initialValue;
    uint256 public totalVest;
    uint256 public vestingDays;
    uint256 public totalShares;

    IERC20 internal immutable token;

    struct Recipient {
        uint256 withdrawnAmount;
        uint256 recipientTotalShare;
        uint256 recipientInitialShare;
        uint256 recipientDailyShare;
    }

    string public name;
    uint256 public totalRecipients;
    address[] public recipientList;
    mapping(address => Recipient) public recipients;

    event LogStartDateSet(address setter, uint256 startDate);
    event LogRecipientAdded(address recipient, uint256 recipientTotalShare, uint256 recipientInitialShare, uint256 recipientDailyShare);
    event LogTokensClaimed(address recipient, uint256 amount);

    modifier onlyValidShareAmount(uint256 _recipientTotalShare) {
        require(
            _recipientTotalShare <= totalVest,
            "Provided _recipientTotalShare should be less than or equals to totalVest"
        );
        _;
    }

    constructor(
        string memory _name,
        address _tokenAddress,
        uint256 _totalVest,
        uint256 _vestingDays,
        uint256 _initialValue
    ) {
        require(
            _initialValue <= 100,
            "_initialValue should be between 0 and 100"
        );
        require(
            _tokenAddress != address(0),
            "Token Address can't be zero address"
        );
        name = _name;
        token = IERC20(_tokenAddress);
        totalVest = _totalVest;
        vestingDays = _vestingDays;
        initialValue = _initialValue;
    }

	
    function percDiv(uint256 period, Recipient memory recipient)
        public
        pure
        returns (uint256)
    {
        return (period * recipient.recipientDailyShare) + recipient.recipientInitialShare;
    }


    function setStartDate(uint256 _startDate) external onlyOwner {
        require(startDate == 0, "Start Date already set");
        require(_startDate >= block.timestamp, "Start Date can't be in the past");

        startDate = _startDate;
        emit LogStartDateSet(address(msg.sender), _startDate);
    }


    function addRecipient(
        address _recipientAddress,
        uint256 _recipientTotalShare
    ) public onlyOwner onlyValidShareAmount(_recipientTotalShare) {
        require(
            _recipientAddress != address(0),
            "Recipient Address can't be zero address"
        );
        require(
            recipients[_recipientAddress].recipientTotalShare == 0,
            "Recipient already has values saved"
        );
        totalShares = totalShares + _recipientTotalShare;
        require(totalShares <= totalVest, "Total shares exceeds totalVest");
        totalRecipients++;
        recipientList.push(_recipientAddress);
        uint256 _recipientInitialShare = (initialValue * _recipientTotalShare)/100;
        uint256 _recipientDailyShare = (_recipientTotalShare - _recipientInitialShare)/ vestingDays;
        recipients[_recipientAddress] = Recipient(0, _recipientTotalShare, _recipientInitialShare, _recipientDailyShare);
        emit LogRecipientAdded(_recipientAddress, _recipientTotalShare, _recipientDailyShare, _recipientInitialShare);
    }

 
    function addMultipleRecipients(
        address[] memory _recipients,
        uint256[] memory _recipientTotalShares
    ) external onlyOwner {
        require(
            _recipients.length < 200,
            "The recipients array size must be smaller than 200"
        );
        require(
            _recipients.length == _recipientTotalShares.length,
            "The two arrays are with different length"
        );
        for (uint256 i = 0; i < _recipients.length; i++) {
            addRecipient(_recipients[i], _recipientTotalShares[i]);
        }
    }


    function claim() external {
        require(startDate != 0, "The vesting hasn't started");
        require(block.timestamp >= startDate, "The vesting hasn't started");

        (uint256 owedAmount, uint256 calculatedAmount) = calculateAmounts();
        recipients[msg.sender].withdrawnAmount = calculatedAmount;
        emit LogTokensClaimed(msg.sender, owedAmount);
        token.safeTransfer(msg.sender, owedAmount);
    }

  
    function hasClaim() public view returns (uint256) {
        if (block.timestamp < startDate) {
            return 0;
        }

        (uint256 owedAmount,) = calculateAmounts();
        return owedAmount;
    }

    function calculateAmounts()
        internal
        view
        returns (uint256 _owedAmount, uint256 _calculatedAmount)
    {
        uint256 period = (block.timestamp - startDate) / (periodLength);
        Recipient memory recipient = recipients[msg.sender];

        //cuz on day 0 one share will release and day n, n+1 share will be released
        period = period +1;

        if (period >= vestingDays) {
            //Time is completed and all recipient share should be payed
            _calculatedAmount = recipient.recipientTotalShare;
        }
        else{
            _calculatedAmount = percDiv(
                period,
                recipient
            );
            if(_calculatedAmount > recipient.recipientTotalShare){
                _calculatedAmount = recipient.recipientTotalShare;
            }
        }

        _owedAmount =
            _calculatedAmount -
            recipients[msg.sender].withdrawnAmount;

        return (_owedAmount, _calculatedAmount);
    }
}