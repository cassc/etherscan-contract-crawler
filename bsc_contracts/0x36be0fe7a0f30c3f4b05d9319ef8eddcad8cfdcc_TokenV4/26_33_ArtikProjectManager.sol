// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/DexRouter.sol";

import "./libraries/ABDKMathQuad.sol";

import "./ArtikTreasury.sol";
import "./ArtikStakeManager.sol";
import "./DistributorV2.sol";

contract ArtikProjectManager is Initializable {
    using SafeMath for uint256;

    // Pancakeswap 0x10ED43C718714eb63d5aA57B78B54704E256024E (testnet: 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3)
    address constant ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    // WBNB 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c (testnet: 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd)
    address constant WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    // BUSD 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56 (testnet: 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7)
    address constant STABLE_COIN = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    uint256 private constant TEAM_FEE = 30;

    DexRouter private dexRouter;

    address private artikToken;
    address payable private admin;

    uint256 public roundNumber;
    mapping(address => mapping(uint256 => uint256)) private voters;
    mapping(address => bool) private isVoter;
    mapping(uint256 => ProjectVotes) private projectVotes;

    Project public bestProject;

    uint256 public projectCount;
    uint256 public votesCount;
    mapping(uint256 => Project) public projects;
    mapping(uint256 => ProjectVotes[]) private projectsLeaderboard;

    DistributorV2 private distributor;
    address payable public distributorAddress;

    uint256 public priceToVote;
    uint256 public minBalanceToVote;

    struct ProjectVotes {
        uint256 id;
        uint256 votes;
    }

    struct Project {
        uint256 id;
        string img;
        string name;
        string description;
        string category;
        string url;
        string twitter;
        address tokenAddress;
        string tokenSymbol;
        uint256 tokenDecimals;
        bool active;
        bool pitchWinner;
    }

    ArtikTreasury private treasury;
    ArtikStakeManager private artikStakeManager;

    modifier onlyAdmin() {
        require(msg.sender == admin || msg.sender == distributorAddress);
        _;
    }

    function initialize(
        address _tokenAddress,
        address _distributorAddress
    ) public initializer {
        dexRouter = DexRouter(ROUTER);
        artikToken = _tokenAddress;
        treasury = ArtikTreasury(payable(_distributorAddress));
        distributorAddress = payable(_distributorAddress);
        admin = payable(msg.sender);
        roundNumber = 1;
        projectCount = 0;
        votesCount = 0;
    }

    function configureStakeManager(
        address _stakeManagerAddr
    ) external onlyAdmin {
        require(_stakeManagerAddr != address(0x0));
        artikStakeManager = ArtikStakeManager(_stakeManagerAddr);
    }

    function configurePriceToVote(uint256 _price) external onlyAdmin {
        require(_price >= 0, "price is less than 0");
        priceToVote = _price;
    }

    function configureMinBalanceToVote(uint256 _balance) external onlyAdmin {
        require(_balance >= 0, "balance is less than 0");
        (uint256 balanceInEth, ) = getAmountOutMin(_balance, STABLE_COIN, WETH);
        (minBalanceToVote, ) = getAmountOutMin(balanceInEth, WETH, artikToken);
    }

    function uploadProject(
        string memory _img,
        string memory _name,
        string memory _description,
        string memory _category,
        string memory _url,
        string memory _twitter,
        bytes20 _tokenAddress,
        string memory _tokenSymbol,
        uint256 _tokenDecimals
    ) external onlyAdmin {
        require(msg.sender != address(0));
        require(bytes(_img).length > 0);
        require(bytes(_name).length > 0);
        require(bytes(_description).length > 0);
        require(bytes(_category).length > 0);
        require(bytes(_url).length > 0);
        require(address(_tokenAddress) != address(0x0));
        require(bytes(_tokenSymbol).length > 0);
        require(_tokenDecimals > 0);

        projectCount = projectCount.add(1);
        projects[projectCount] = Project(
            projectCount,
            _img,
            _name,
            _description,
            _category,
            _url,
            _twitter,
            address(_tokenAddress),
            _tokenSymbol,
            _tokenDecimals,
            true,
            false
        );

        projectVotes[projectCount] = ProjectVotes(projectCount, 0);
    }

    function changeProjectDescription(
        uint256 _projectId,
        string memory _description
    ) external onlyAdmin {
        require(_projectId > 0);
        require(bytes(_description).length > 0);
        projects[_projectId].description = _description;
    }

    function getLeaderBoard() external view returns (ProjectVotes[] memory) {
        return projectsLeaderboard[roundNumber - 1];
    }

    function saveProjectToLeaderboard(uint256 _projectId) external onlyAdmin {
        require(_projectId > 0);
        projectsLeaderboard[roundNumber - 1].push(
            ProjectVotes(_projectId, projectVotes[_projectId].votes)
        );
    }

    function managePitchWinner(
        uint256 _projectId,
        bool _isWinner
    ) external onlyAdmin {
        require(_projectId > 0);
        require(_isWinner == true || _isWinner == false);
        projects[_projectId].pitchWinner = _isWinner;
    }

    function changeProjectState(
        uint256 _projectId,
        bool _active
    ) external onlyAdmin {
        require(_projectId > 0);
        require(_active == true || _active == false);
        projects[_projectId].active = _active;
    }

    function voteProject(uint256 _projectId) external payable {
        require(
            voters[msg.sender][_projectId] != roundNumber,
            "voters can vote the same project only 1 time"
        );

        require(_projectId != 0, "projectId canno be 0");
        require(msg.value > 0, "value less than 0");

        (uint256 priceInBusd, ) = getAmountOutMin(msg.value, WETH, STABLE_COIN);

        if (priceToVote > 0) {
            require(priceInBusd >= priceToVote, "voting has a cost!");
            uint256 amount = msg.value.div(2);

            (bool sentToTeam, ) = admin.call{value: amount}("");
            (bool sentToDistributor, ) = distributorAddress.call{
                value: address(this).balance
            }("");
            require(sentToTeam, "Failed to send to team");
            require(sentToDistributor, "Failed to send to distributor");

            treasury.swapTokens();
        }

        if (minBalanceToVote > 0) {
            require(
                artikStakeManager.getStakedBalance(msg.sender, roundNumber) >=
                    minBalanceToVote,
                "not enough balance to vote"
            );
        }

        projectVotes[_projectId].votes = projectVotes[_projectId].votes.add(1);
        voters[msg.sender][_projectId] = roundNumber;
        isVoter[msg.sender] = true;
        votesCount = votesCount.add(1);
    }

    function setVoter(address _shareholder, bool _isVoter) external onlyAdmin {
        require(_shareholder != address(0x0));
        require(_isVoter == true || _isVoter == false);
        isVoter[_shareholder] = _isVoter;
    }

    function isShareholderVoter(
        address _shareholder
    ) external view returns (bool) {
        require(_shareholder != address(0x0));
        return isVoter[_shareholder];
    }

    function resetProjectVotes(uint256 _projectId) external onlyAdmin {
        require(_projectId > 0);
        projectVotes[_projectId].votes = 0;
    }

    function setBestProject(uint256 _projectId) external onlyAdmin {
        require(_projectId > 0);
        bestProject = projects[_projectId];
    }

    function getProjectVotes(
        uint256 _projectId
    ) external view onlyAdmin returns (ProjectVotes memory) {
        require(_projectId > 0);
        return projectVotes[_projectId];
    }

    function getBestProject() external view returns (Project memory) {
        return bestProject;
    }

    function getAmountOutMin(
        uint256 _amount,
        address _tokenIn,
        address _tokenOut
    ) private view returns (uint256, address[] memory) {
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;

        uint256[] memory amountOutMins = dexRouter.getAmountsOut(_amount, path);
        return (amountOutMins[1], path);
    }

    function setRound(uint256 _round) public onlyAdmin {
        require(_round > 0);
        roundNumber = _round;
    }

    function nextRound() public onlyAdmin {
        roundNumber = roundNumber.add(1);
    }

    function hasVotedProject(uint256 _projectId) external view returns (bool) {
        if (voters[msg.sender][_projectId] == roundNumber) {
            return true;
        } else {
            return false;
        }
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        return
            ABDKMathQuad.toUInt(
                ABDKMathQuad.div(
                    ABDKMathQuad.mul(
                        ABDKMathQuad.fromUInt(x),
                        ABDKMathQuad.fromUInt(y)
                    ),
                    ABDKMathQuad.fromUInt(z)
                )
            );
    }
}