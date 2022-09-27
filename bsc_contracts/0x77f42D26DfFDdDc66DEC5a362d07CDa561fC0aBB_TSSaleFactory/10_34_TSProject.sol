// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract TSProject is Ownable{
    event RegisterUser(uint256 indexed userId, address indexed user, uint indexed role);
    event ProjectCreate(uint256 indexed id, bytes32 indexed name, address indexed owner, bytes32 pId);
    event ProjectApproved(uint256 indexed id);
    event AddCheckPoint(uint256 indexed projectId, uint64 timestamp, uint256 value);

    struct CheckPoint{
        uint64 timestamp;
        uint256 value;
    }
    struct Project{
        uint256 id;
        bytes32 name;
        address owner;
        uint256 status;
        uint256 totalPercentRequest;         
    }
    struct User{
        uint256 userId;
        address userAdd;
        uint256 userType;
        uint256 levelVC;
        uint256 levelStarter;
    }

    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;

    uint256 public BPS  = 10000;
    Project[] public projects;
    User[] public users;
    Counters.Counter private projectCounter;
    Counters.Counter private userCounter;
    mapping(address => EnumerableSet.UintSet) private projectsOfUsers;
    mapping(address => uint256) public userIdOfAdd;
    mapping(uint256 => CheckPoint[]) public checkPointOfProject;

    constructor(){
        projectCounter.increment();
        userCounter.increment();
    }

    function registerVc() external {
        uint256 id = userIdOfAdd[msg.sender];
        require(id == 0,"TS: user already registered");
        uint256 userId = userCounter.current();
        users.push(User(userId,msg.sender,0,1,0));
        userIdOfAdd[msg.sender] = userId;
        emit RegisterUser(userId, msg.sender, 1);
        userCounter.increment();
    }
    function registerStartup() external {
        uint256 id = userIdOfAdd[msg.sender];
        require(id == 0,"TS: user already registered");
        uint256 userId = userCounter.current();
        users.push(User(userId,msg.sender,0,0,1));
        userIdOfAdd[msg.sender] = userId;
        emit RegisterUser(userId, msg.sender, 0);
        userCounter.increment();
    }
    
    function createProject(bytes32 projectId, bytes32 name) external{
       require(userIdOfAdd[msg.sender]>0,"TS: user not exist");
        User storage user = users[userIdOfAdd[msg.sender] -1];
        require(user.levelStarter>0,"TS: only startup call");
        uint256 smProjectId = projectCounter.current();
        projects.push(Project(smProjectId,name,msg.sender,0,0));
        projectsOfUsers[msg.sender].add(smProjectId);
        emit ProjectCreate(smProjectId, name, msg.sender, projectId);
        projectCounter.increment();
    }
    function approveProject(uint256 projectId) external onlyOwner{
        require(projectId>0 && projectId-1 < projects.length,"TS: id invalid");
        Project storage project = projects[projectId - 1];
        project.status = 1;
        emit ProjectApproved(projectId);
    }
    function addCheckPoint(uint256 projectId, uint64 timestamp, uint256 value) external{
        require(projectId>0 && projectId-1 < projects.length,"TS: id invalid");
        Project storage project = projects[projectId - 1];
        require(project.owner == msg.sender,"TS: not owner project");
        uint64 lastestTimestamp = checkPointOfProject[projectId].length == 0?uint64(block.timestamp):checkPointOfProject[projectId][checkPointOfProject[projectId].length -1].timestamp;
        require(timestamp > lastestTimestamp,"TS: timestamp invalid");
        require(project.totalPercentRequest + value <= BPS,"TS: value invalid");
        project.totalPercentRequest += value;
        checkPointOfProject[projectId].push(CheckPoint(timestamp,value));
        emit AddCheckPoint(projectId, timestamp, value);
    }
    function getProjectOfUser(address user, uint256 index) external view returns (Project memory project){
        project =projects[projectsOfUsers[user].at(index)-1];
    }
    function getCheckPointsOfProject(uint256 projectId) public view  returns(CheckPoint[] memory checkPoints){
       checkPoints = checkPointOfProject[projectId]; 
    }
    function getProjectById(uint256 smProjectId) public view returns(Project memory project){
        require(smProjectId>0&&smProjectId<=projects.length,"TS: project not exist");
        project = projects[smProjectId -1 ];
    }
    function getOwnerOfProject(uint256 smProjectId)public view returns(address owner){
        require(smProjectId>0&&smProjectId-1<projects.length, "TS: project not exist");
        owner = projects[smProjectId -1 ].owner;
    }
    function userIsVc(address user) public view returns(bool _value){
        _value = userIdOfAdd[user]>0&&users[userIdOfAdd[user]-1].levelVC >0? true: false;
    }
    function userIsStartup(address user) public view returns(bool _value){
        _value = userIdOfAdd[user]>0&&users[userIdOfAdd[user]-1].levelStarter >0? true: false;
    }

}