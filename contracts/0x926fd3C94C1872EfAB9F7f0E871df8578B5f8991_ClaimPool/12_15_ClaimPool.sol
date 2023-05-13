// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../interfaces/IClaimPool.sol";
import "../interfaces/IProject.sol";
import "../Adminable.sol";
import "../lib/TransferHelper.sol";

contract ClaimPool is IClaimPool, Adminable, ERC165Upgradeable, ReentrancyGuardUpgradeable {
    /**
     *  @notice project is address of project manager
     */
    address public project;

    /**
     *  @notice paymentToken is address of payment token
     */
    address public paymentToken;

    /**
     * @notice Store budget of list collections in project
     * @dev adress of collection => budget of collection claim pool
     */
    mapping(address => uint256) public collectionClaimPool;

    /**
     *  @notice mapping collection to budget in use
     */
    mapping(address => uint256) public budgetInUseOf;

    /**
     *  @notice mapping collection to transfer reward
     */
    mapping(address => uint256) public transferToRewards;

    event Received(address caller, uint amount);
    event AddedBudget(address indexed collectionAddress, uint256 budget);
    event AddedBudgetUse(address indexed collectionAddress, uint256 budget);
    event ReducedBudgetUse(address indexed collectionAddress, uint256 budget);
    event WithdrawnBudgetFrom(address indexed collectionAddress, address indexed to, uint256 amount);
    event TransferToReward(address indexed collectionAddress, address indexed to, uint256 amount);
    event Withdrawn(address indexed caller, uint256 amount);

    /**
     * @notice Throw if caller is not project
     */
    modifier onlyProject() {
        require(project == _msgSender(), "Caller is not project");
        _;
    }

    modifier onlyTaskManager() {
        require(IProject(project).taskManager() == _msgSender(), "Caller is not task manager");
        _;
    }

    /**
     * @notice Function initializer, replace for constructor
     * @param owner_ Address of the contract's owner
     * @param _project Address of the project
     * @param _paymentToken Address of the payment token, address(0) for native token
     */
    function initialize(
        address owner_,
        address _project,
        address _paymentToken
    ) public initializer notZeroAddress(owner_) notZeroAddress(_project) {
        __ERC165_init();
        __Adminable_init();
        __ReentrancyGuard_init();
        transferOwnership(owner_);
        project = _project;
        paymentToken = _paymentToken;
    }

    /**
     * @notice Receive function when contract receive native token from others
     */
    receive() external payable {
        emit Received(_msgSender(), msg.value);
    }

    /**
     * @notice Update budget of collection
     * @dev    Only project can call this function
     * @param _collectionAddress address of collection
     * @param _budget New budget of collection
     *
     * emit {UpdatedBudget} events
     */
    function addBudgetTo(address _collectionAddress, uint256 _budget) external onlyProject {
        collectionClaimPool[_collectionAddress] += _budget;

        emit AddedBudget(_collectionAddress, _budget);
    }

    /**
     * @notice Withdraw budget from collection
     * @dev    Only project can call this function
     * @param _collectionAddress address of collection
     * @param _to areceiver address
     * @param _amount amount of token to withdraw
     */
    function withdrawBudgetFrom(
        address _collectionAddress,
        address _to,
        uint256 _amount
    ) external nonReentrant onlyProject {
        require(
            collectionClaimPool[_collectionAddress] >= _amount + budgetInUseOf[_collectionAddress],
            "Amount exceeds balance"
        );
        collectionClaimPool[_collectionAddress] -= _amount;

        TransferHelper._transferToken(paymentToken, _amount, address(this), _to);

        emit WithdrawnBudgetFrom(_collectionAddress, _to, _amount);
    }

    /**
     * @notice Update budget of collection
     * @dev    Only task manager can call this function
     * @param _collectionAddress address of collection
     * @param _amount New budget of collection
     *
     * emit {UpdatedBudget} events
     */
    function addBudgetUse(address _collectionAddress, uint256 _amount) external onlyTaskManager {
        budgetInUseOf[_collectionAddress] += _amount;

        emit AddedBudgetUse(_collectionAddress, _amount);
    }

    /**
     * @notice Update budget of collection
     * @dev    Only task manager can call this function
     * @param _collectionAddress address of collection
     * @param _amount New budget of collection
     *
     * emit {UpdatedBudget} events
     */
    function reduceBudgetUse(address _collectionAddress, uint256 _amount) external onlyTaskManager {
        require(budgetInUseOf[_collectionAddress] >= _amount, "Invalid _amount");
        budgetInUseOf[_collectionAddress] -= _amount;

        emit ReducedBudgetUse(_collectionAddress, _amount);
    }

    /**
     * @notice transfer reward to Reward contract
     * @dev    Only task manager can call this function
     * @param _collectionAddress address of collection
     * @param _amount amount of token to transfer
     */
    function transferToReward(
        address _collectionAddress,
        uint256 _amount
    ) external nonReentrant onlyTaskManager {
        require(
            budgetInUseOf[_collectionAddress] >= _amount + transferToRewards[_collectionAddress],
            "Amount exceeds balance"
        );
        transferToRewards[_collectionAddress] += _amount;

        TransferHelper._transferToken(paymentToken, _amount, address(this), IProject(project).rewardAddress());

        emit TransferToReward(_collectionAddress, IProject(project).rewardAddress(), _amount);
    }

    /**
     * @notice Withdraw all
     * @dev    Only owner can call this function
     */
    function withdraw() external nonReentrant onlyOwner {
        uint256 totalAmount = paymentToken == address(0)
            ? address(this).balance
            : IERC20Upgradeable(paymentToken).balanceOf(address(this));
        TransferHelper._transferToken(paymentToken, totalAmount, address(this), owner());

        emit Withdrawn(_msgSender(), totalAmount);
    }

    /**
     * @notice Get budget of each collection
     */
    function getFreeBudget(address _collectionAddress) external view returns (uint256) {
        return collectionClaimPool[_collectionAddress] - budgetInUseOf[_collectionAddress];
    }
}