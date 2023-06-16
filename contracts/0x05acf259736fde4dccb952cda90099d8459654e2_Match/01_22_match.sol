// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract Match is ChainlinkClient, ConfirmedOwner {
    using SafeERC20 for ERC20;
    using Chainlink for Chainlink.Request;

    bool public announced = false;
    uint256 public announcementHours;
    address public immutable CHALLENGER_1;
    address public immutable CHALLENGER_2;

    address public winner;
    mapping(address => bool) public contingencyVote;

    address public constant USDT_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address private constant CHAINLINK_TOKEN = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address private constant CHAINLINK_ORACLE = 0x1db329cDE457D68B872766F4e12F9532BCA9149b;
    bytes32 private constant jobId = "2be3d99009014444a354480991038dac";
    uint256 public fee = (14 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
    string private constant API_URL = "https://api.derektoyzboxing.com/result";
    string private constant API_RES_PATH = "data,winner"; // JSONPath expression with comma(,) delimited string for nested objects
    int256 private constant API_RES_MULTIPLIER = 1; // for removing decimals of the result, mandatory

    event ResultAnnounced(address winner);
    event VoteWinner(uint256 winner, address voter);

    address private  _owner; 

    constructor(address challenger_1, address challenger_2, uint256 _announcementHours) ConfirmedOwner(msg.sender) {
        require(challenger_1 != address(0) && challenger_2 != address(0), "challenger address can't be 0");
        CHALLENGER_1 = challenger_1;
        CHALLENGER_2 = challenger_2;
        announcementHours = _announcementHours;
        setChainlinkToken(CHAINLINK_TOKEN);
        setChainlinkOracle(CHAINLINK_ORACLE);
        _owner = msg.sender;
    } 

    modifier onlyOwnerCheck() {
        require(msg.sender == _owner, "Not a owner");
        _;
    }

    modifier onlyOwnerOrChallenger() {
        require(msg.sender == _owner || msg.sender == CHALLENGER_1 || msg.sender == CHALLENGER_2, "You have no role");
        _;  // continues
    }

    function voteForContingency(bool vote) external onlyOwnerOrChallenger {
        contingencyVote[msg.sender] = vote;
    }

    function contingency() external onlyOwnerCheck {
        // check all agree
        require(contingencyVote[_owner] == true && contingencyVote[CHALLENGER_1] == true && contingencyVote[CHALLENGER_2] == true, "Not all agree");
        uint256 amount = getContractUSDTBalance();
        
        ERC20(USDT_ADDRESS).safeTransfer(msg.sender, amount);
    }

    // Create a Chainlink request to retrieve API response
    function requestWinner() internal returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        req.add("get", API_URL);
        req.add("path", API_RES_PATH);
        req.addInt("times", API_RES_MULTIPLIER);

        // send the request
        return sendChainlinkRequest(req, fee);
    }

    // Receive the response in the form of uint256
    function fulfill(
        bytes32 _requestId,
        uint256 _result
    ) public recordChainlinkFulfillment(_requestId) {
        require(announced == false, "Result has already been announced");
        require(_result == 1 || _result == 2, "Invalid result"); // validating the api response

        if (_result == 1) {
            winner = CHALLENGER_1;
        } else {
            winner = CHALLENGER_2;
        }

        announced = true; //set announced true

        emit ResultAnnounced(winner);
    }

    //Transfer USDT to winner
    function transferToWinner() external onlyOwnerOrChallenger{
        require(announced == true, "Result has not been announced");

        uint256 amount = getContractUSDTBalance();

        ERC20(USDT_ADDRESS).safeTransfer(winner, amount);
    }

    //Allow withdraw of Link tokens from the contract
    function withdrawLink() external onlyOwnerCheck {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
    
    function announceResult() external onlyOwnerOrChallenger returns(bytes32) {
        require(announced == false, "Result has already been announced");
        require(block.timestamp >= announcementHours, "Not time for announcement yet");
        bytes32 reqId = requestWinner();
        return reqId;
    }

    function getContractUSDTBalance() public view returns (uint256) { 
        uint256 amount = ERC20(USDT_ADDRESS).balanceOf(address(this));
        return amount;
    }

    function getContractLINKBalance() external view returns (uint256) {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        uint256 amount = link.balanceOf(address(this));
        return amount;
    }

    function updateLinkFee(uint256 updatedFee) external onlyOwnerCheck {
        fee = (updatedFee * LINK_DIVISIBILITY) / 10; // default 14 (1.4 LINK)
    }
}