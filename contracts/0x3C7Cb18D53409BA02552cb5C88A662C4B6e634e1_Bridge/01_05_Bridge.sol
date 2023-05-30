// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

// OpenZeppelin
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IBridgeMigrationSource {
    function tokenAddress() external view returns (address);
    function settlingAgent() external view returns (address payable);
}

contract Bridge is Ownable {

    using SafeMath for uint256;

    struct BridgeRequest {
        address account;
        uint256 amount;
        uint256 blockNumber;
        uint256 timestamp;
    }

    event RequestSent (uint256 indexed _id, address indexed _account, uint256 _amount, uint256 _blocknumber);
    event RequestReceived (uint256 indexed _id, address indexed _account, uint256 _amount, uint256 _amountPaid, uint256 _blocknumber);

    event RequiredConfirmationsChanged (uint256 _value);
    event PayoutRatioChanged (uint256 _nominator, uint256 _denominator);

    constructor(address _tokenAddress) {
        settlingAgent = payable(msg.sender);
        tokenAddress = _tokenAddress;
    }

    address payable public settlingAgent;
    function setSettlingAgent(address _address) public onlyOwner {
        settlingAgent = payable(_address);
    }

    address public tokenAddress;
    function setTokenAddress(address _address) public onlyOwner {
        tokenAddress = _address;
    }

    uint256 public payoutRatioNominator = 1;
    uint256 public payoutRatioDenominator = 1;
    function setPayoutRatio(uint256 _nominator, uint256 _denominator) public onlyOwner {
        require(_nominator > 0, "Nominator must be greater than zero");
        require(_denominator > 0, "Denominator must be greater than zero");

        payoutRatioNominator = _nominator;
        payoutRatioDenominator = _denominator;

        emit PayoutRatioChanged(_nominator, _denominator);
    }

    uint256 public outgoingTransferFee = 0.1 * 10**18;
    function setOutgoingTransferFee(uint256 _amount) public onlyOwner {
        outgoingTransferFee = _amount;
    }

    uint256 public maximumTransferAmount = 0;
    function setMaximumTransferAmount(uint256 _amount) public onlyOwner {
        maximumTransferAmount = _amount;
    }

    uint256 public requiredConfirmations = 20;
    function setRequiredConfirmations(uint256 _amount) public onlyOwner {
        requiredConfirmations = _amount;
        emit RequiredConfirmationsChanged(_amount);
    }

    modifier onlyAgent() {
        require(msg.sender == settlingAgent, "This action can only be executed by the settling agent");
        _;
    }

    uint256 public sentRequestCount;
    mapping (uint256 => BridgeRequest) public sentRequests;

    uint256 public receivedRequestCount;
    mapping (uint256 => bool) public receivedRequests;

    function withdrawETH() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    function withdrawToken(address _tokenAddress) public onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        require(token.transfer(owner(), token.balanceOf(address(this))), "Failed to transfer tokens");
    }

    function bridgeToken(uint256 _amount) public payable  {
        require(msg.value >= outgoingTransferFee, "Underpaid transaction: please provide the outgoing transfer fee." );
        require(_amount <= maximumTransferAmount || maximumTransferAmount == 0, "Requested amount exceeds maximum amount to transfer.");

        IERC20 erc20 = IERC20(tokenAddress);

        uint256 balanceBefore = erc20.balanceOf(address(this));
        require(erc20.transferFrom (msg.sender, address(this) , _amount), "Transferring tokens was cancelled by the token contract. Please check with the token developer.");

        uint256 balanceExpected = balanceBefore + _amount;
        require(erc20.balanceOf(address(this)) >= balanceExpected, "Did not receive enough tokens from sender. Is the bridge exempted from taxes?");

        sentRequestCount++;
        settlingAgent.transfer(msg.value);

        sentRequests[sentRequestCount].account =  msg.sender;
        sentRequests[sentRequestCount].amount = _amount;
        sentRequests[sentRequestCount].blockNumber = block.number;
        sentRequests[sentRequestCount].timestamp = block.timestamp;

        emit RequestSent(sentRequestCount, msg.sender, _amount, block.number);
    }
    function settleRequest(uint256 _id, address _account, uint256 _amount) public onlyAgent {

        IERC20 erc20 = IERC20(tokenAddress);
        uint256 _amountRespectingPayoutRatio = _amount.mul(payoutRatioNominator).div(payoutRatioDenominator);

        require (!receivedRequests[_id], "This request was already settled");
        require (erc20.balanceOf(address(this)) >= _amountRespectingPayoutRatio, "Token deposit insufficient for settlement");

        receivedRequestCount++;
        receivedRequests[receivedRequestCount] = true;

        require(erc20.transfer(_account, _amountRespectingPayoutRatio), "Failed to send tokens to the receiving account.");

        emit RequestReceived(receivedRequestCount, _account, _amount, _amountRespectingPayoutRatio, block.number);
    }

    receive() external payable {}
    fallback() external payable {}

    function migrateFrom(address _oldAddress) public onlyOwner {
        IBridgeMigrationSource oldBridge = IBridgeMigrationSource(_oldAddress);

        tokenAddress = oldBridge.tokenAddress();
        settlingAgent = oldBridge.settlingAgent();

        payoutRatioNominator = tryGetValue(_oldAddress, "payoutRatioNominator()", payoutRatioNominator);
        payoutRatioDenominator = tryGetValue(_oldAddress, "payoutRatioDenominator()", payoutRatioDenominator);
        outgoingTransferFee = tryGetValue(_oldAddress, "outgoingTransferFee()", outgoingTransferFee);
        maximumTransferAmount = tryGetValue(_oldAddress, "maximumTransferAmount()", maximumTransferAmount);
        requiredConfirmations = tryGetValue(_oldAddress, "requiredConfirmations()", requiredConfirmations);
    }
    function tryGetValue(address _address, string memory _signature, uint256 _fallback) private view returns (uint256) {
        (bool result, bytes memory retval) = _address.staticcall(abi.encodeWithSignature(_signature));
        if (result) {
            return abi.decode(retval, (uint256));
        }
        else {
            return _fallback;
        }
    }
}