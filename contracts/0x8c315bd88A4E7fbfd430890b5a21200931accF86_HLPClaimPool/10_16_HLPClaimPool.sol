// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IHLPClaimPool.sol";
import "./interfaces/IProject.sol";
import "./Validatable.sol";
import "./lib/TransferHelper.sol";

contract HLPClaimPool is IHLPClaimPool, Validatable, ReentrancyGuardUpgradeable {
    /**
     *  @notice project is address of Project
     */
    address public project;

    event RegisterProject(address indexed project);
    event DepositedToProject(uint256 indexed projectId, address indexed paymentToken, address indexed to, uint256 amount);
    event SetProjectAddress(address indexed oldValue, address indexed newValue);
    event Withdrawn(address indexed paymentToken, address indexed request, address indexed to, uint256 amount);

    function initialize(IAdmin _admin) public initializer notZeroAddress(address(_admin)) {
        __Validatable_init(_admin);
    }

    receive() external payable {}

    /**
     *  @notice Register Project to allow it order methods of this contract
     *
     *  @dev    Register can only be called once
     */
    function registerProject() external {
        require(project == address(0), "Already register");
        project = _msgSender();
        emit RegisterProject(project);
    }

    /**
     * @notice
     * Set the new Project contract address
     * Caution need to discuss with the dev before updating the new state
     *
     * @param _project New Project contract address
     */
    function setProjectAddress(address _project) external onlyAdmin notZeroAddress(_project) {
        address oldValue = project;
        project = _project;
        emit SetProjectAddress(oldValue, _project);
    }

    /**
     * @notice
     * Deposit reward token into claimPool of project
     * Caution need to discuss with the dev before updating the new state
     *
     * @param _projectId id of project
     * @param _amount reward amount
     */
    function depositToProject(uint256 _projectId, uint256 _amount) external nonReentrant onlyAdmin notZero(_amount) {
        ProjectInfo memory projectInfo = IProject(project).getProjectById(_projectId);
        require(projectInfo.projectId > 0, "Invalid project");
        IProject(project).splitBudget(_projectId, _amount);
        TransferHelper._transferToken(projectInfo.paymentToken, _amount, address(this), projectInfo.claimPool);

        emit DepositedToProject(_projectId, projectInfo.paymentToken, projectInfo.claimPool, _amount);
    }

    /**
     * @notice
     * Withdraw token from contract
     * Caution need to discuss with the dev before updating the new state
     *
     * @param _paymentToken payment address
     * @param _amount reward amount
     * @param _to address receive reward
     */
    function withdraw(
        address _paymentToken,
        uint256 _amount,
        address _to
    ) external onlyAdmin nonReentrant notZeroAddress(_to) notZero(_amount) {
        TransferHelper._transferToken(_paymentToken, _amount, address(this), _to);

        emit Withdrawn(_paymentToken, _msgSender(), _to, _amount);
    }
}