// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract TeamsManager is Initializable, OwnableUpgradeable {
    uint256 public createPrice;
    uint256 public feeP;
    uint256 public interval;
    uint256 public intervalEarnings;
    uint256 public totalManagers;
    uint256 public totalTeams;
    uint256 private constant d = 10000;

    address public tokenAddress;
    address private w1;
    address private w2;
    address private w3;

    mapping(address => uint256) public managers;
    mapping(uint256 => uint256) public teamsCounter;
    mapping(uint256 => mapping(uint256 => uint256)) public teamsLastClaimDates;

    event Create(address indexed account, uint256 managerId, uint256 amount);
    event CreateManager(address indexed account, uint256 id);

    function initialize(address _tokenAddress) public initializer {
        __Ownable_init();
        createPrice = 10 ether;
        feeP = 1000; // 10%
        interval = 1 days;
        intervalEarnings = 340000000000000000;
        totalManagers = 0;
        totalTeams = 0;

        tokenAddress = _tokenAddress;
        w1 = 0xB2c713F0Cb6C88dF79B9e6ff039D92eD94499f40;
        w2 = 0xb6e76628BeB7872D2ade6AE9641bb390401c18ef;
        w3 = 0x1501982a423d4D06Be4fFfE61d9Da85e79bEC078;
    }

    function setFeeP(uint256 v) external virtual onlyOwner {
        feeP = v;
    }

    function setInterval(uint256 _interval) external virtual onlyOwner {
        interval = _interval;
    }

    function setDailyEarnings(uint256 _intervalEarnings)
        external
        virtual
        onlyOwner
    {
        intervalEarnings = _intervalEarnings;
    }

    function setCreatePrice(uint256 _createPrice) external virtual onlyOwner {
        createPrice = _createPrice;
    }

    function getsUnclaimedRewards(address _account)
        external
        view
        returns (uint256)
    {
        uint256 totalUnclaimed = 0;
        uint256 teamsNumber = teamsCounter[managers[_account]];
        for (uint256 index = 0; index < teamsNumber; index++) {
            totalUnclaimed += ((uint256(
                block.timestamp - teamsLastClaimDates[managers[_account]][index]
            ) * intervalEarnings) / interval);
        }

        return totalUnclaimed;
    }

    function calcPercent(uint256 v, uint256 p) internal pure returns (uint256) {
        return (v * p) / d;
    }

    function createTeam(uint256 _number) external {
        // check if user is manager, if not create manager
        if (managers[msg.sender] == 0) {
            totalManagers++;
            managers[msg.sender] = totalManagers;
            emit CreateManager(msg.sender, totalManagers);
        }

        uint256 requiredTokenAmount = createPrice * _number;
        require(
            IERC20(tokenAddress).balanceOf(msg.sender) >= requiredTokenAmount,
            "Low amount"
        );

        // send to contract
        IERC20(tokenAddress).transferFrom(
            address(msg.sender),
            address(this),
            requiredTokenAmount
        );

        uint256 tokensForTeam = calcPercent(requiredTokenAmount, feeP);
        sendToTeam(tokensForTeam);

        teamsCounter[managers[msg.sender]] += _number;
        totalTeams += _number;

        uint256 teamsNumber = teamsCounter[managers[msg.sender]];
        for (uint256 index = 0; index < teamsNumber; index++) {
            if (teamsLastClaimDates[managers[msg.sender]][index] == 0) {
                teamsLastClaimDates[managers[msg.sender]][index] = block
                    .timestamp;
            }
        }

        emit Create(msg.sender, managers[msg.sender], _number);
    }

    function claimFromAllTeams() external {
        require(managers[msg.sender] > 0, "not is manager");
        uint256 totalUnclaimed = this.getsUnclaimedRewards(msg.sender);

        uint256 teamsNumber = teamsCounter[managers[msg.sender]];
        for (uint256 typeIndex = 0; typeIndex < teamsNumber; typeIndex++) {
            teamsLastClaimDates[managers[msg.sender]][typeIndex] = block
                .timestamp;
        }

        uint256 tokensForTeam = calcPercent(totalUnclaimed, feeP);
        IERC20(tokenAddress).transfer(
            address(msg.sender),
            totalUnclaimed - tokensForTeam
        );
        sendToTeam(tokensForTeam);
    }

    function sendToTeam(uint256 amount) internal {
        uint256 teamAmount = amount / 3;

        IERC20(tokenAddress).transfer(address(w1), teamAmount);
        IERC20(tokenAddress).transfer(address(w2), teamAmount);
        IERC20(tokenAddress).transfer(address(w3), teamAmount);
    }
}