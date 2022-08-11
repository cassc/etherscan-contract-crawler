// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

// import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract ReactorV1 is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    
    // staked token
    IERC20Upgradeable public stakedToken;

    // project structure:
    struct Project {
        string repoType;
        string repoUserName;
        string repo;
        string branch;

        // project owner
        address owner;
        bool verified;
        // maintainers maps who is the maintainer of the project
        mapping(address => bool) maintainers;
    }

    // project maps:
    mapping (uint => Project) public projectMap;

    // project count:
    uint public projectCount;

    // user stake:
    mapping (address => uint256) public userStake;

    // user project count:
    mapping (address => uint) public userProjectCount;

    // staked amount per project:
    uint256 public stakedAmountPerProject;

    // payout amount per account:
    uint256 public payPerAction;

    // total payout amount:
    uint256 public totalPayout;

    // only project owner modifier:
    modifier onlyProjectOwner(uint _projectId) {
        require(projectMap[_projectId].owner == msg.sender, "Only project owner can perform this action");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function initialize(IERC20Upgradeable _stakedToken, uint256 _stakedAmountPerProject) external initializer{
        stakedToken = _stakedToken;
        stakedAmountPerProject = _stakedAmountPerProject;
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    // add projet event:
    event ProjectAdded(uint indexed projectId, address indexed owner, string repoType, string repoUserName, string repo, string branch);

    // add maintainer event:
    event MaintainerAdded(address indexed maintainer, uint indexed projectId);

    // remove maintainer event:
    event MaintainerRemoved(address indexed maintainer, uint indexed projectId);

    // change project owner event:
    event ProjectOwnerChanged(address indexed oldOwner, address indexed newOwner, uint indexed projectId);

    // change project verified event:
    event ProjectVerified(uint indexed projectId, bool verified);

    // change staked token event:
    event StakedTokenChanged(IERC20Upgradeable indexed oldToken, IERC20Upgradeable indexed newToken);

    // change staked amount per project event:
    event StakedAmountPerProjectChanged(uint256 indexed oldAmount, uint256 indexed newAmount);

    // stake event:
    event Stake(address indexed user, uint256 amount);

    // unstake event:
    event Unstake(address indexed user, uint256 amount);

    // change project details event:
    event ProjectDetailsChanged(uint indexed projectId, string repoType, string repoUserName, string repo, string branch);

    // change pay per action event:
    event PayPerActionChanged(uint256 indexed oldAmount, uint256 indexed newAmount);

    // action event:
    event Action(address indexed user, uint indexed projectId, uint indexed actionType, uint256 amount, uint256 timestamp);

    ////////////////////////////////////////////////////////////////////////////////

    function doAction(uint _projectId, uint _action, address _user) private {
        if (payPerAction == 0) {
            return;
        } else {
            stakedToken.safeTransferFrom(msg.sender, address(this), payPerAction);
            totalPayout = totalPayout.add(payPerAction);
            emit Action(_user, _projectId, _action, payPerAction, block.timestamp);
        }
    }

    /**
     * @dev Adds a new project to the contract.
     * @param _repoType The type of the repository.
     * @param _repoUserName The user name of the repository.
     * @param _repo The name of the repository.
     * @param _branch The branch of the repository.
     * @return The id of the project.
     */
    
    function addProject(string memory _repoType, string memory _repoUserName, string memory _repo, string memory _branch) external nonReentrant returns (uint) {
        require(userStake[msg.sender].sub(stakedAmountPerProject.mul(userProjectCount[msg.sender])) >= stakedAmountPerProject, "Not enough staked amount");
        uint projectId = projectCount;
        projectMap[projectId].repoType = _repoType;
        projectMap[projectId].repoUserName = _repoUserName;
        projectMap[projectId].repo = _repo;
        projectMap[projectId].branch = _branch;
        projectMap[projectId].owner = msg.sender;
        projectMap[projectId].verified = false;
        projectMap[projectId].maintainers[msg.sender] = true;
        projectCount++;
        userProjectCount[msg.sender]++;

        doAction(projectId, 1, msg.sender);
        emit ProjectAdded(projectId, msg.sender, _repoType, _repoUserName, _repo, _branch);
        return projectId;
    }

    /**
     * @dev Adds a new maintainer to the project. Only the project owner can add a new maintainer.
     * @param _projectId The id of the project.
     * @param _maintainer The address of the maintainer.
     */

    function addMaintainer(uint _projectId, address _maintainer) external onlyProjectOwner(_projectId) {
        require(!projectMap[_projectId].maintainers[_maintainer], "Maintainer already exists");
        require(userStake[_maintainer].sub(stakedAmountPerProject.mul(userProjectCount[_maintainer])) >= stakedAmountPerProject, "Not enough staked amount");
        projectMap[_projectId].maintainers[_maintainer] = true;
        userProjectCount[_maintainer]++;
        emit MaintainerAdded(_maintainer, _projectId);
    }

    /**
     * @dev Removes a maintainer from the project.
     * @param _projectId The id of the project.
     * @param _maintainer The address of the maintainer.
     */
    
    function removeMaintainer(uint _projectId, address _maintainer) external {
        require(projectMap[_projectId].maintainers[_maintainer], "Maintainer does not exist");
        require(msg.sender == _maintainer || msg.sender == projectMap[_projectId].owner, "Only project owner or maintainer can remove a maintainer");
        projectMap[_projectId].maintainers[_maintainer] = false;
        userProjectCount[_maintainer]--;
        emit MaintainerRemoved(_maintainer, _projectId);
    }

    /**
     * @dev Changes the owner of the project. Only the project owner can change the owner.
     * @param _projectId The id of the project.
     * @param _newOwner The new owner of the project.
     */

    function changeProjectOwner(uint _projectId, address _newOwner) external onlyProjectOwner(_projectId) {
        require(_newOwner != address(0), "New owner cannot be the zero address");
        require(projectMap[_projectId].maintainers[_newOwner], "New owner must be a maintainer");
        projectMap[_projectId].owner = _newOwner;
        emit ProjectOwnerChanged(projectMap[_projectId].owner, _newOwner, _projectId);
    }

    /**
     * @dev isMaintainer returns true if the user is a maintainer of the project.
     * @param _projectId The id of the project.
     * @param _user The user address.
     */

    function isMaintainer(uint _projectId, address _user) external view returns (bool) {
        return projectMap[_projectId].maintainers[_user];
    }

    /**
     * @dev stakes token
     * @param _amount The amount of token to stake.
     */
    
    function stake(uint256 _amount) external nonReentrant {
        stakedToken.safeTransferFrom(msg.sender, address(this), _amount);
        userStake[msg.sender] = userStake[msg.sender].add(_amount);
        emit Stake(msg.sender, _amount);
    }

    /**
     * @dev unstakes token
     * @param _amount The amount of token to unstake.
     */
    
    function unstake(uint256 _amount) external nonReentrant {
        stakedToken.safeTransfer(msg.sender, _amount);
        userStake[msg.sender] = userStake[msg.sender].sub(_amount);
        emit Unstake(msg.sender, _amount);
    }

    /**
     * @dev Verifies the project. Only the owner can verify the project.
     * @param _projectId The id of the project.
     */
    
    function verifyProject(uint _projectId) external onlyOwner {
        projectMap[_projectId].verified = true;
        emit ProjectVerified(_projectId, true);
    }

    /**
     * @dev Unverifies the project. Only the owner can unverify the project.
     * @param _projectId The id of the project.
     */

    function unverifyProject(uint _projectId) external onlyOwner {
        projectMap[_projectId].verified = false;
        emit ProjectVerified(_projectId, false);
    }

    /**
     * @dev Changes staked token. Only the owner can change the staked token.
     * @param _newStakedToken The new staked token.
     */

    function changeStakedToken(IERC20Upgradeable _newStakedToken) external onlyOwner {
        stakedToken = _newStakedToken;
        emit StakedTokenChanged(stakedToken, _newStakedToken);
    }

    /**
     * @dev Changes the staked amount per project. Only the owner can change the staked amount per project.
     * @param _amount The id of the project.
     */

    function changeStakedAmountPerProject(uint256 _amount) external onlyOwner {
        stakedAmountPerProject = _amount;
        emit StakedAmountPerProjectChanged(stakedAmountPerProject, _amount);
    }

    /**
     * @dev Changes payout amount per action. Only the owner can change the payout amount per action.
     * @param _amount The id of the project.
     */

    function changePayPerAction(uint256 _amount) external onlyOwner {
        payPerAction = _amount;
        emit PayPerActionChanged(payPerAction, _amount);
    }

    /**
     * @dev Action to be performed by the project maintainer.
     * @param _projectId The id of the project.
     * @param _action The action to be performed.
     */

    function action(uint _projectId, uint _action) external {
        require(projectMap[_projectId].maintainers[msg.sender], "Only maintainers can perform actions");
        doAction(_projectId, _action, msg.sender);
    }

    /**
     * @dev Changes project details. Only the project owner can change the project details.
     * @param _projectId The id of the project.
     * @param _repoType The repo type.
     * @param _repoUserName The repo user name.
     * @param _repo The repo.
     * @param _branch The branch.
     */

    function changeProjectDetails(uint _projectId, string memory _repoType, string memory _repoUserName, string memory _repo, string memory _branch) external onlyProjectOwner(_projectId) {
        projectMap[_projectId].repoType = _repoType;
        projectMap[_projectId].repoUserName = _repoUserName;
        projectMap[_projectId].repo = _repo;
        projectMap[_projectId].branch = _branch;
        emit ProjectDetailsChanged(_projectId, _repoType, _repoUserName, _repo, _branch);
    }
}