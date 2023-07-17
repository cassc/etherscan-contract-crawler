// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin-latest/contracts/access/Ownable.sol";
import "@openzeppelin-latest/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin-latest/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-latest/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

contract Crowdfund is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event Launch(
        uint id,
        address indexed creator,
        address rewardToken,
        uint goal,
        uint createdAt,
        uint startAt,
        uint endAt,
        uint _pledgeRewardRate
    );
    event Cancel(uint id);
    event Pledge(uint indexed id, address indexed caller, uint amount);
    event Unpledge(uint indexed id, address indexed caller, uint amount);
    event ClaimPledgeReward(uint id);
    event ClaimPledges(uint id);
    event Refund(uint id, address indexed caller, uint amount);

    struct Campaign {
        // Campaigne pledge reward token
        ERC20PresetMinterPauser rewardToken;
        // Creator of campaign
        address creator;
        // Amount of tokens to raise
        uint256 goal;
        // Purpose behind campaign
        string purpose;
        // Total amount pledged
        uint256 pledged;
        // Amount of reward tokens per pledge
        uint pledgeRewardRate;
        // Timestamp of creation
        uint createdAt;
        // Timestamp of start of campaign
        uint startAt;
        // Timestamp of end of campaign
        uint endAt;
        // True if goal was reached and creator has claimed the tokens.
        bool claimed;
    }

    struct UserPledge {
        // Total amount pledged
        uint256 amount;
        // True if pledger claimed rewards
        bool claimed;
    }

    // Total count of campaigns created.
    // It is also used to generate id for new campaigns.
    uint public count;
    // IUniswapV2Router02 public uniswapV2Router =
    //     IUniswapV2Router02(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45); // For Mainnet
    IUniswapV2Router02 public uniswapV2Router =
        IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // For BSC Testnet
    // Mapping from id to Campaign
    mapping(uint => Campaign) public campaigns;
    // Mapping from campaign id => pledger => amount pledged
    mapping(uint => mapping(address => UserPledge)) public usersPledge;

    constructor() {}

    receive() external payable {}

    function launch(
        address _rewardToken,
        uint256 _goal,
        string memory _purpose,
        uint _startAt,
        uint _endAt,
        uint _pledgeRewardRate
    ) external onlyOwner {
        require(_startAt >= block.timestamp, "start at < now");
        require(_endAt >= _startAt, "end at < start at");
        require(_endAt <= block.timestamp + 90 days, "end at > max duration");
        require(_goal > 0, "goal required");
        require(bytes(_purpose).length > 0, "purpose required");
        if (_rewardToken != address(0) || _pledgeRewardRate > 0) {
            require(
                _rewardToken != address(0) && _pledgeRewardRate > 0,
                "rewardToken && pledgeRewardRate required"
            );
        } else {
            require(
                _rewardToken == address(0) && _pledgeRewardRate <= 0,
                "rewardToken && pledgeRewardRate required"
            );
        }
        count += 1;
        campaigns[count] = Campaign({
            rewardToken: ERC20PresetMinterPauser(_rewardToken),
            creator: msg.sender,
            goal: _goal,
            purpose: _purpose,
            pledged: 0,
            pledgeRewardRate: _pledgeRewardRate,
            createdAt: block.timestamp,
            startAt: _startAt,
            endAt: _endAt,
            claimed: false
        });
        emit Launch(
            count,
            msg.sender,
            _rewardToken,
            _goal,
            block.timestamp,
            _startAt,
            _endAt,
            _pledgeRewardRate
        );
    }

    function cancel(uint _id) external onlyOwner {
        require(block.timestamp < campaigns[_id].startAt, "started");
        delete campaigns[_id];
        emit Cancel(_id);
    }

    function pledgeETH(uint _id) external payable {
        require(_id > 0 && _id <= count, "Invalid campaign ID");
        require(msg.value > 0, "ETH amount required");
        Campaign storage campaign = campaigns[_id];
        require(campaign.creator != address(0), "campaign not found");
        require(block.timestamp >= campaign.startAt, "not started");
        require(block.timestamp <= campaign.endAt, "ended");

        UserPledge storage userPledge = usersPledge[_id][msg.sender];
        userPledge.amount += msg.value;
        campaign.pledged += msg.value;

        emit Pledge(_id, msg.sender, msg.value);
    }

    function pledgeTokens(uint _id, uint256 _amount, address _token, address[] calldata path) external {
        require(_amount > 0, "Token amount required");
        require(_id > 0 && _id <= count, "Invalid campaign ID");
        Campaign storage campaign = campaigns[_id];
        require(campaign.creator != address(0), "campaign not found");
        require(
            block.timestamp >= campaign.startAt &&
                block.timestamp <= campaign.endAt,
            "Campaign not active"
        );

        IERC20 tokenContract = IERC20(_token);
        tokenContract.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 amountReceived;
        if (_token == uniswapV2Router.WETH()) {
            IWETH(uniswapV2Router.WETH()).withdraw(_amount);
            amountReceived = _amount;
        } else {
            require(path.length > 1, "Invalid path");
            require(path[0] == _token, "Invalid path");
            tokenContract.safeApprove(address(uniswapV2Router), _amount);
            uint[] memory amounts = uniswapV2Router.swapExactTokensForETH(
                _amount,
                0,
                path,
                address(this),
                block.timestamp
            );
            require(amounts[1] > 0, "Uniswap swap failed");
            amountReceived = amounts[1];
        }

        UserPledge storage userPledge = usersPledge[_id][msg.sender];
        userPledge.amount += amountReceived;
        campaign.pledged += amountReceived;
        emit Pledge(_id, msg.sender, amountReceived);
    }

    function unpledge(uint _id, uint256 _amount) external {
        require(_id > 0 && _id <= count, "Invalid campaign ID");
        require(_amount > 0, "Amount must be greater than 0");
        Campaign storage campaign = campaigns[_id];
        require(campaign.creator != address(0), "campaign not found");
        require(block.timestamp <= campaign.endAt, "Campaign has ended");
        UserPledge storage userPledge = usersPledge[_id][msg.sender];
        require(userPledge.amount > 0, "No pledge found");
        require(
            userPledge.amount >= _amount,
            "Unpledge amount exceeds pledged amount"
        );
        campaign.pledged -= _amount;
        userPledge.amount -= _amount;
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed.");
        emit Unpledge(_id, msg.sender, _amount);
    }

    function claimPledgeReward(uint _id) external {
        require(_id > 0 && _id <= count, "Invalid campaign ID");
        Campaign storage campaign = campaigns[_id];
        require(campaign.creator != address(0), "campaign not found");
        UserPledge storage userPledge = usersPledge[_id][msg.sender];
        require(
            block.timestamp >= campaign.endAt + 1 days || campaign.claimed,
            "Campaign has not ended yet or not claimed"
        );
        require(campaign.pledgeRewardRate > 0, "no campaign pledgeRewardRate");
        require(userPledge.amount > 0, "No existing pledge");
        require(!userPledge.claimed, "user pledgeReward claimed");
        userPledge.claimed = true;
        // covert pledge to tokens & mint rewards to user
        campaign.rewardToken.mint(
            msg.sender,
            userPledge.amount * campaign.pledgeRewardRate
        );

        emit ClaimPledgeReward(_id);
    }

    function claimPledges(uint _id) external onlyOwner {
        require(_id > 0 && _id <= count, "Invalid campaign ID");
        require(
            block.timestamp > campaigns[_id].endAt,
            "Campaign has not ended yet"
        );
        require(!campaigns[_id].claimed, "Pledges already claimed");
        campaigns[_id].claimed = true;
        (bool success, ) = msg.sender.call{value: campaigns[_id].pledged}("");
        require(success, "Transfer failed.");
        emit ClaimPledges(_id);
    }

    function refund(uint _id) external {
        require(_id > 0 && _id <= count, "Invalid campaign ID");
        Campaign memory campaign = campaigns[_id];
        UserPledge storage userPledge = usersPledge[_id][msg.sender];
        require(
            block.timestamp >= campaign.endAt + 1,
            "Campaign has not ended yet"
        );
        require(
            campaign.pledged < campaign.goal,
            "Campaign goal has been reached"
        );
        require(userPledge.amount > 0, "No existing pledge");
        require(!userPledge.claimed, "Cannot refund claimed pledge");
        uint pledgedAmount = userPledge.amount;
        userPledge.amount = 0;
        (bool success, ) = msg.sender.call{value: pledgedAmount}("");
        require(success, "Transfer failed.");
        emit Refund(_id, msg.sender, pledgedAmount);
    }

    function updateRouter(address _router) external onlyOwner {
        require(_router != address(0), "Invalid router address");
        IUniswapV2Router02 router = IUniswapV2Router02(_router);
        address factory = router.factory();
        require(factory != address(0), "Invalid factory address");
        address WETH = router.WETH();
        require(WETH != address(0), "Invalid WETH address");
        uniswapV2Router = IUniswapV2Router02(_router);
    }

    function emergencyRecoverTokens(
        address tokenAddress,
        uint256 tokenAmount
    ) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
    }

    function emergencyRecoverETH(uint256 amount) external onlyOwner {
        for (uint i = 1; i <= count; i++) {
            Campaign memory campaign = campaigns[i];
            require(
                block.timestamp > campaign.endAt,
                "Campaign has not ended yet"
            );
        }
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed.");
    }
}