// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./libraries/SimpleAccessUpgradable.sol";

import "./interfaces/IHoney.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract HoneyCoinRaffle is SimpleAccessUpgradable {
    IHoney public HoneyToken;

    struct RaffleProject {
        uint128 price;
        uint128 supply;
        uint128 deadline;
        address winner;
        address nftProject;
        uint128 nftTokenId;
        bool isRewardClaimed;
        bool isRewardTransferred;
    }

    mapping(uint256 => address[]) projectToUsers;
    mapping(uint256 => RaffleProject) public raffleProjects;
    mapping(uint256 => mapping(address => uint256)) public projectToUserSpots;

    uint128 public max128;

    event RaffleAddProject(
        uint256 indexed projectId,
        uint256 price,
        uint256 deadline,
        uint256 supply,
        uint256 nftId,
        address projectAddress
    );
    event RaffleModifyProject(
        uint256 indexed projectId,
        uint256 price,
        uint256 deadline,
        uint256 supply,
        uint256 nftId
    );
    event RaffleBought(address indexed buyer, uint256 indexed projectId);
    event RaffleWinnerAnnounced(uint256 indexed projectId);

    constructor(address _honeyToken) {}

    function initialize(address _honeyToken) public initializer {
        __Ownable_init();

        HoneyToken = IHoney(_honeyToken);

        max128 = 2**128 - 1;
        require(max128 != 0, "Max128 overflow");
    }

    function reserveRaffleProjectSpot(
        uint256 projectId,
        uint128 amount,
        uint256[] memory flowersWithBees
    ) external {
        RaffleProject storage project = raffleProjects[projectId];

        require(
            project.deadline != 0 && project.price != 0,
            "Project does not exist"
        );
        require(project.supply >= amount, "Not enough spots left");
        require(project.deadline > block.timestamp, "Project offering expired");

        HoneyToken.spendEcoSystemBalance(
            msg.sender,
            project.price * amount,
            flowersWithBees,
            ""
        );

        project.supply -= amount;

        for (uint256 i = 0; i < amount; i++) {
            projectToUsers[projectId].push(msg.sender);
        }

        projectToUserSpots[projectId][msg.sender] += amount;

        emit RaffleBought(msg.sender, projectId);
    }

    function shuffleProjectUsers(uint256 projectId)
        private
        view
        returns (address[] memory)
    {
        address[] memory projectUsers = projectToUsers[projectId];

        uint256 count = projectUsers.length;

        for (uint256 i = 0; i < count; i++) {
            uint256 n = i +
                (uint256(keccak256(abi.encodePacked(block.timestamp))) %
                    (count - i));
            address temp = projectUsers[n];
            projectUsers[n] = projectUsers[i];
            projectUsers[i] = temp;
        }

        return projectUsers;
    }

    function getRandomValue(uint256 projectId) private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        projectToUsers[projectId]
                    )
                )
            );
    }

    function findProjectWinner(uint256 projectId)
        external
        view
        onlyAuthorized
        returns (address)
    {
        RaffleProject memory project = raffleProjects[projectId];

        require(
            projectToUsers[projectId].length > 0,
            "No users participated for project"
        );

        require(
            project.winner == address(0),
            "Winner already choosen for project"
        );

        uint256 winnerIndex = getRandomValue(projectId) %
            projectToUsers[projectId].length;

        return shuffleProjectUsers(projectId)[winnerIndex];
    }

    function setProjectWinner(uint256 projectId, address winner)
        external
        onlyAuthorized
    {
        RaffleProject storage project = raffleProjects[projectId];

        require(
            projectToUsers[projectId].length > 0,
            "No users participated for project"
        );

        require(
            project.winner == address(0),
            "Winner already choosen for project"
        );

        project.winner = winner;

        emit RaffleWinnerAnnounced(projectId);
    }

    function getProjectUsers(uint256 projectId)
        external
        view
        onlyOwner
        returns (address[] memory)
    {
        return projectToUsers[projectId];
    }

    function claimProjectReward(uint256 projectId) external {
        RaffleProject storage project = raffleProjects[projectId];

        require(project.winner != address(0), "Winner not choosen for project");
        require(
            !project.isRewardClaimed,
            "Reward is already claimed for project"
        );

        require(
            project.winner == msg.sender,
            "You are not winner for this project"
        );

        project.isRewardClaimed = true;
        transferNftToWinner(projectId);
    }

    function transferNftToWinner(uint256 projectId) internal {
        RaffleProject memory project = raffleProjects[projectId];

        require(project.nftTokenId != 0, "No nft token found for project");
        require(
            project.nftProject != address(0),
            "No project address found for project"
        );
        require(project.winner != address(0), "Winner not choosen for project");
        require(project.isRewardClaimed, "Reward not claimed for project");
        require(
            !project.isRewardTransferred,
            "Reward is already transferred for project"
        );

        project.isRewardTransferred = true;
        IERC721(project.nftProject).transferFrom(
            address(this),
            project.winner,
            project.nftTokenId
        );
    }

    function addOrModifyRaffleProject(
        bool isModify,
        uint256 projectId,
        uint256 price,
        uint256 deadline,
        uint256 supply,
        uint256 nftId,
        address nftProject
    ) external payable onlyAuthorized {
        RaffleProject storage project = raffleProjects[projectId];

        require(price < max128, "price overflow");
        require(deadline < max128, "deadline overflow");
        require(supply < max128, "supply overflow");
        require(nftId < max128, "nft id overflow");

        if (isModify) {
            project.price = uint128(price);
            project.supply = uint128(supply);
            project.deadline = uint128(deadline);

            if (nftId != project.nftTokenId) {
                IERC721(nftProject).transferFrom(
                    msg.sender,
                    address(this),
                    nftId
                );

                IERC721(nftProject).transferFrom(
                    address(this),
                    msg.sender,
                    project.nftTokenId
                );

                project.nftTokenId = uint128(nftId);
            }

            emit RaffleModifyProject(projectId, price, deadline, supply, nftId);
        } else {
            require(project.deadline == 0, "Cannot overwrite existing project");

            IERC721(nftProject).transferFrom(msg.sender, address(this), nftId);

            project.price = uint128(price);
            project.supply = uint128(supply);
            project.deadline = uint128(deadline);
            project.nftTokenId = uint128(nftId);
            project.nftProject = nftProject;

            emit RaffleAddProject(
                projectId,
                price,
                deadline,
                supply,
                nftId,
                nftProject
            );
        }
    }
}