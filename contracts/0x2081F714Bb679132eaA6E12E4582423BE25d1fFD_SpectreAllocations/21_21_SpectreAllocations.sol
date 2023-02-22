// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import { ITether } from "./interfaces/Tether.sol";
import { ISpectreAllocations, ProjectConfig } from "./interfaces/ISpectreAllocations.sol";

contract SpectreAllocations is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    ISpectreAllocations
{
    using StringsUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC721Upgradeable spectreContract;
    IERC20 USDC;
    IERC20 USDT;

    mapping(bytes32 => ProjectConfig) private configuredProjects;
    mapping(bytes32 => mapping(address => uint256)) private investmentPerUser;
    mapping(bytes32 => bool) private projectExists;
    mapping(bytes32 => mapping(uint256 => address)) public tokenLock;
    mapping(bytes32 => bool) public refundsActiveForProject;
    mapping(address => bool) public partnerCollections;
    address public tetherContract;

    event EntryUpdate(bytes32 project, address investor);

    function initialize(address _spectre, address _tether)
        external
        initializer
    {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        spectreContract = IERC721Upgradeable(_spectre);
        tetherContract = _tether;
        USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    }

    /**
     * @param projectName : bytes32 representation of the project name
     * @param sig : the signatures generated for the user, including the amount.
     * @param amount : the amount the user want to invest. Need that for accounting
     * and verifying the signature.
     * @param tokenId: the Spectre tokenId. User need to be the owner.
     * will also need it to verify if its a whale token.
     */
    function addInvestmentToProject(
        bytes32 projectName,
        bytes memory sig,
        uint256 amount,
        uint256 tokenId,
        address gatingContract,
        bool useUSDT
    ) external whenNotPaused nonReentrant {
        // checks if the project exist
        require(
            projectExists[projectName],
            "addInvestmentToProject: project not found"
        );
        ProjectConfig storage project = configuredProjects[projectName];

        address holder;
        if (gatingContract == tetherContract) {
            holder = getHolder(tokenId);
        } else if (gatingContract == address(spectreContract)) {
            holder = msg.sender;
            require(
                spectreContract.balanceOf(holder) > 0,
                "addInvestmentToProject: no pass found"
            );
            require(
                project.openForHolders,
                "addInvestmentToProject: whales only"
            );
        } else {
            require(
                partnerCollections[gatingContract],
                "addInvestmentToProject: collection not partnered"
            );
            // TODO: Add in so we check ERC165 interface to verify balance of the tokens
            holder = msg.sender;
        }

        if (tokenLock[projectName][tokenId] == address(0)) {
            tokenLock[projectName][tokenId] = holder;
        } else {
            require(
                tokenLock[projectName][tokenId] == holder,
                "addInvestmentToProject: token already invested"
            );
        }

        require(
            project.endDate >= block.timestamp,
            "addInvestmentToProject: project ended"
        );
        require(!project.paused, "addInvestmentToProject: project paused");
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(
                project.signer,
                keccak256(abi.encodePacked(msg.sender, amount))
                    .toEthSignedMessageHash(),
                sig
            ),
            "Unauthorized"
        );

        require(
            project.totalCollected + amount <= project.maxAllocations,
            "addInvestToProject: allocation filled"
        );

        /*  check that the amount to invest is still within the limit
            of the user.
        */
        uint256 userInvestment = investmentPerUser[projectName][msg.sender];

        if (
            gatingContract == address(spectreContract) ||
            gatingContract == tetherContract
        ) {
            require(
                userInvestment + amount <= project.maxAllocationsPerUser,
                "addInvestmentToProject: overallocated"
            );
        } else {
            require(
                userInvestment + amount <= project.maxAllocationsPerNonHolder,
                "addInvestmentToProject: overallocated"
            );
        }
        if (useUSDT) USDT.transferFrom(msg.sender, address(this), amount);
        else USDC.transferFrom(msg.sender, address(this), amount);

        investmentPerUser[projectName][holder] += amount;
        project.totalCollected += amount;
        emit EntryUpdate(projectName, holder);
    }

    function projectConfig(bytes32 project)
        external
        view
        returns (ProjectConfig memory)
    {
        require(projectExists[project], "projectConfig: not configured");
        return configuredProjects[project];
    }

    function invested(bytes32 project, address investor)
        external
        view
        returns (uint256)
    {
        require(projectExists[project], "invested: project not found");
        return investmentPerUser[project][investor];
    }

    function exists(bytes32 project) external view returns (bool) {
        return projectExists[project];
    }

    function addProject(
        bytes32 projectName,
        uint256 _maxAllocations,
        uint256 _maxAllocationsPerUser,
        uint256 _maxAllocationsPerWhale,
        uint256 _maxAllocationsPerNonHolder,
        uint256 _endDate,
        address _signer,
        bool _openForHolders,
        bool _openForWhales,
        bool _openForPublic
    ) external onlyOwner {
        configuredProjects[projectName] = ProjectConfig({
            maxAllocations: _maxAllocations,
            maxAllocationsPerUser: _maxAllocationsPerUser,
            maxAllocationsPerWhale: _maxAllocationsPerWhale,
            maxAllocationsPerNonHolder: _maxAllocationsPerNonHolder,
            totalCollected: 0,
            endDate: _endDate,
            signer: _signer,
            paused: false,
            openForHolders: _openForHolders,
            openForWhales: _openForWhales,
            openForPublic: _openForPublic
        });

        projectExists[projectName] = true;
    }

    function toggleProjectOpenForHolders(bytes32 projectName)
        external
        onlyOwner
    {
        require(
            projectExists[projectName],
            "toggleProjectOpenForHolders: project not found"
        );
        configuredProjects[projectName].openForHolders = !configuredProjects[
            projectName
        ].openForHolders;
    }

    function toggleProjectOpenForWhales(bytes32 projectName)
        external
        onlyOwner
    {
        require(
            projectExists[projectName],
            "toggleProjectOpenForWhales: project not found"
        );
        configuredProjects[projectName].openForWhales = !configuredProjects[
            projectName
        ].openForWhales;
    }

    function toggleProjectOpenForPublic(bytes32 projectName)
        external
        onlyOwner
    {
        require(
            projectExists[projectName],
            "toggleProjectOpenForPublic: project not found"
        );
        configuredProjects[projectName].openForPublic = !configuredProjects[
            projectName
        ].openForPublic;
    }

    function editProjectMaxAllocations(
        bytes32 projectName,
        uint256 _maxAllocations
    ) external onlyOwner {
        require(
            projectExists[projectName],
            "editProjectMaxAllocations: project not found"
        );
        configuredProjects[projectName].maxAllocations = _maxAllocations;
    }

    function editProjectMaxAllocationPerUser(
        bytes32 projectName,
        uint256 _maxAllocationsPerUser
    ) external onlyOwner {
        require(
            projectExists[projectName],
            "editProjectMaxAllocationPerUser: project not found"
        );
        configuredProjects[projectName]
            .maxAllocationsPerUser = _maxAllocationsPerUser;
    }

    function editMaxAllocationPerWhale(bytes32 projectName, uint256 _amount)
        external
        onlyOwner
    {
        require(
            projectExists[projectName],
            "editProjectMaxAllocationPerWhale: project not found"
        );
        configuredProjects[projectName].maxAllocationsPerWhale = _amount;
    }

    function editMaxAllocationsPerNonHolder(
        bytes32 projectName,
        uint256 _amount
    ) external onlyOwner {
        require(
            projectExists[projectName],
            "editMaxAllocationsPerNonHolder: project not found"
        );
        configuredProjects[projectName].maxAllocationsPerNonHolder = _amount;
    }

    function editProjectEndDate(bytes32 projectName, uint256 _endDate)
        external
        onlyOwner
    {
        require(
            projectExists[projectName],
            "editProjectEndDate: project not found"
        );
        configuredProjects[projectName].endDate = _endDate;
    }

    function editProjectSigner(bytes32 projectName, address _signer)
        external
        onlyOwner
    {
        require(
            projectExists[projectName],
            "editProjectSigner: project not found"
        );
        configuredProjects[projectName].signer = _signer;
    }

    function editProjectPaused(bytes32 projectName, bool _paused)
        external
        onlyOwner
    {
        require(
            projectExists[projectName],
            "editProjectPaused: project not found"
        );
        configuredProjects[projectName].paused = _paused;
    }

    function setSpectreAddress(address _spectre) external onlyOwner {
        spectreContract = IERC721Upgradeable(_spectre);
    }

    function setUSDC(address _USDC) external onlyOwner {
        USDC = IERC20(_USDC);
    }

    function setUSDT(address _USDT) external onlyOwner {
        USDT = IERC20(_USDT);
    }

    function getHolder(uint256 tokenId) internal view returns (address) {
        ITether tether = ITether(tetherContract);
        require(tether.isActive(tokenId), "getHolder: tether not active");
        require(
            tether.ownerOf(tokenId) == msg.sender,
            "getHolder: wallet not valid proxy"
        );
        address holder = tether.links(tokenId).holder;
        require(
            spectreContract.balanceOf(holder) > 0,
            "getHolder: proxied wallet needs to hold a pass"
        );
        return holder;
    }

    function withdrawUSDC(address _receiver) external onlyOwner {
        uint256 balance = USDC.balanceOf(address(this));
        USDC.transfer(_receiver, balance);
    }

    function withdrawUSDT(address _receiver) external onlyOwner {
        uint256 balance = USDT.balanceOf(address(this));
        USDT.transfer(_receiver, balance);
    }

    function userRefund(
        bytes32 projectName,
        uint256 tokenId,
        address verifyContract
    ) external nonReentrant {
        address holder;
        if (verifyContract == tetherContract) {
            holder = getHolder(tokenId);
        } else {
            holder = msg.sender;
        }
        require(refundsActiveForProject[projectName], "userRefund: not active");
        uint256 amountInvested = investmentPerUser[projectName][holder];
        require(amountInvested > 0, "userRefund: no investments");

        investmentPerUser[projectName][holder] = 0;

        configuredProjects[projectName].totalCollected -= amountInvested;

        require(
            USDC.transfer(holder, amountInvested),
            "userRefund: transfer failed"
        );
    }

    function toggleRefundsActive(bytes32 projectName) external onlyOwner {
        require(
            projectExists[projectName],
            "toggleRefundsActive: project not found"
        );
        refundsActiveForProject[projectName] = !refundsActiveForProject[
            projectName
        ];
    }

    function addToInvestmentMapping(
        bytes32 projectName,
        address investor,
        uint256 amount
    ) external onlyOwner {
        require(
            projectExists[projectName],
            "addToInvestmentMapping: project not found"
        );
        _addInvestment(projectName, investor, amount);
    }

    function removeFromInvestmentMapping(
        bytes32 projectName,
        address investor,
        uint256 amount
    ) external onlyOwner {
        require(
            projectExists[projectName],
            "removeFromInvestmentMapping: project not found"
        );
        _deductInvestment(projectName, investor, amount);
    }

    function moveInvestment(
        bytes32 projectName,
        address from,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(
            projectExists[projectName],
            "moveInvestment: project not found"
        );
        _deductInvestment(projectName, from, amount);
        _addInvestment(projectName, to, amount);
    }

    function _addInvestment(
        bytes32 projectName,
        address investor,
        uint256 amount
    ) internal {
        investmentPerUser[projectName][investor] += amount;
        configuredProjects[projectName].totalCollected += amount;
        emit EntryUpdate(projectName, investor);
    }

    function _deductInvestment(
        bytes32 projectName,
        address investor,
        uint256 amount
    ) internal {
        investmentPerUser[projectName][investor] -= amount;
        configuredProjects[projectName].totalCollected -= amount;
        emit EntryUpdate(projectName, investor);
    }
}