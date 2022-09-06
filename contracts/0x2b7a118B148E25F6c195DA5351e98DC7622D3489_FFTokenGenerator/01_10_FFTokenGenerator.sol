// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;
/*
    Inspired by luchadores.io and @0xBasset's work on the Ascended NFT Aura Contract
*/
/*
    Author: chosta.eth (@chosta_eth)
 */
/*
    The Founders Factory Token Generator is a passive ERC20 token factory for multiple ERC721Like* projects.
    Any wallet that holds an NFT from one of these projects can claim the corresponding amount (time-based 
    since the last claim) of Founder1 tokens. The contract includes an admin interface that controls the projects
    (add / edit), as well as setting properties (placeholder URL, active, etc.) that frontend builders 
    can utilize to create interfaces with proper UX. 
    # TODO -> briefly explain how the yield rate is calculated 
    Each NFT is generating a yield rate based on a formula described in the whitepaper (here). 
    
    *ERC721Like is a 0xInuriashi.eth gas optimized version of the classic ERC721. The benefits are 
    meager mint fees. It comes with a cost, as the function that replaces tokenOfOwnerByIndex 
    (see https://etherscan.io/address/0x496299d8497a02b01f5bc355298b0a831f06c522#code)    

    >>>> Governance Model <<<< 
    (using openzeppelin's AccessControl)

        Default Admin
            - Set Default Admin
            - Set Ratoooor role
            - Renounce Default Admin (1-way)
            - Pause / Unpause claim
            - Add / Update Projects
            - Edit Rates
            - Start / Stop / Restart Yields 

        Ratooooor
            - Edit Rates

    >>>> Interfacing <<<<<

    To draw a front-end interface:
    
        viewAllProjects() - Enumerate all available ERC721Like projects with all their data 

        viewProjects(address[] calldata projects_) - Enumerate specific projects
    
        claimable(address contract_, uint256 id_) - Claimable amount per owned NFT

        totalClaimable(FFProjectIds[] calldata FFProjectIds_) - Claimable amount for all ids given (per project)

        getYieldRate(address project_) - Yield rate of each project at the current moment. Yield rates will be 
        periodically updated as per the whitepaper


    For interaction of users:

        claimSingle(address project_, uint256[] calldata ids_) - Send a project address and ids owned by the msg.sender
        to claim tokens (single project)

        claimMultiple(FFProjectIds[] calldata erc721LikeProjects_) - Send project addresses and ids owned by the msg.sender
        to claim tokens (multiple projects)


    For administration:

        pause() / unpause() - Implements Pausable (OZ). Used for emergency stop claim

        addProject(address project_, FFProject memory FFProject_) - Add a project (the properties responsible for
        starting and ending yield are set to 0, start = 0, end = 0). Need to run startYield to init token generation

        updateProject(address project_, FFProject calldata FFProject_) - Update a project (updating start, end done
        with the help of stopYield, startYield)

        stopYield(address project_) - Sets end claiming to now, effectively stopping any future yield

        restartYield(address project_) - To restart the yield, the daysEnd need to be updated by updateProject first

        updateRates(FFRate[] calldata rates_) - Admins and Ratooors, can change the yield rates of all projects at once
*/

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// import "hardhat/console.sol";

interface IERC20 {
    function mint(address user, uint256 amount) external;
}

/*  
    ERC721 work by default, ERC721I by Inu doesn't have a non-gas intensive read function to get the owned tokens,
    therefore we have to deal with ownerOf to check token ownership, and send the token ids from the frontend. 

    ERC721I implementations at time of deployment
    + Ascended NFT
    + Space Yetis
 */
interface IERC721Like {
    function ownerOf(uint256 id_) external view returns (address);
}

contract FFTokenGenerator is AccessControl, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    struct FFProject {
        address addr;
        string name; // project name
        uint256 start; // timestamp start yield generation
        uint256 end; // timestamp stop yield generation
        uint256 daysInPast; // store a value of when the yield should start from now
        uint256 daysEnd; // store a value of when the yield should end from now
        uint256 yieldRate; // 1 to 10000 rate as per the whitepaper (used to control token generation amounts)
        bool erc721Like; // for frontend
        bool active; // for frontend help only - NOT USED FOR INTERNAL LOGIC
        string projectUrl; // opensea / looksrare (or any other) external url
        string placeholderUrl; // any image describing the project
    }

    /* util structs to help with sending input from frontend */
    struct FFProjectIds {
        address addr;
        uint256[] ids;
    }

    struct FFRate {
        address addr;
        uint256 yieldRate;
    }

    IERC20 public token;
    address[] public projectAddresses; // keep track of all addresses (frontend help)
    mapping(address => FFProject) public projects;
    mapping(address => mapping(uint256 => uint256)) public lastClaims; // store timestamp of last claim

    event Claimed(address indexed user_, uint256 amount_);
    event ProjectAdded(address indexed user_, FFProject FFProject_);
    event ProjectUpdated(address indexed user_, FFProject FFProject_);
    event YieldStarted(
        address indexed user_,
        address indexed project_,
        uint256 start_,
        uint256 end_
    );
    event YieldStopped(
        address indexed user_,
        address indexed project_,
        uint256 end_
    );
    event YieldRestarted(
        address indexed user_,
        address indexed project_,
        uint256 end_
    );
    event RatesUpdated(address indexed user_, FFRate[] rates_);
    event ProjectRemoved(address indexed user_, address indexed project_);

    // role used to enable non-admins to change the rates
    bytes32 public constant RATOOOOR = keccak256("RATOOOOR");
    // avoid misclicks and breaking the economy by setting a limit
    uint16 public constant MAX_YIELD = 10000;

    constructor(address token_) {
        token = IERC20(token_);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(RATOOOOR, msg.sender);
    }

    /** ####################
        Claimoooor functions
    */
    /** 
        Claiming a single ERC721Like project - the ones that Inu built and have a custom method to retrive token owners
        Usually it's walletOfOwner but it is an external and very gas heavy fn, so the solution is to send the ids via frontend,
        and use ownerOf to detect ownership. 
        * must implement ownerOf
    */
    function claimSingle(address project_, uint256[] calldata ids_)
        external
        whenNotPaused
        nonReentrant
    {
        uint256 _totalClaim;
        _totalClaim = claimAndSetLastClaimsERC721Like(project_, ids_);
        require(_totalClaim > 0, "No claimable yield");

        token.mint(msg.sender, _totalClaim);
        emit Claimed(msg.sender, _totalClaim);
    }

    /* 
        Far from optimal but some people just like to watch the ETH burn
     */
    function claimMultiple(FFProjectIds[] calldata erc721LikeProjects_)
        external
        whenNotPaused
        nonReentrant
    {
        uint256 _totalClaim;

        for (uint256 j = 0; j < erc721LikeProjects_.length; j++) {
            FFProjectIds memory _projectIds = erc721LikeProjects_[j];
            address _project = _projectIds.addr;
            uint256[] memory _ids = _projectIds.ids;

            _totalClaim = _totalClaim.add(
                claimAndSetLastClaimsERC721Like(_project, _ids)
            );
        }

        require(_totalClaim > 0, "No claimable yield");

        token.mint(msg.sender, _totalClaim);
        emit Claimed(msg.sender, _totalClaim);
    }

    /** ###########
        Admin stuff
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
       An opinionated choice was made on how to handle `start` and `end` yields. I've decided these times by separate
       functions. Upon creation start=0, end=0. The variables we control at the moment of creation are:
       + daysInPast (start yield retroactively)
       + daysEnd (put a date in the future)
       We set them in days, and ONLY AFTER addProject has been invoked we run startYield to initiate the token generation.
       !IMPORTANT The `addProject` and `updateProject` functions do not deal with `start` and `end` but with `daysInPast`,
       and `daysEnd` instead. One of the main reasons I chose this path was that sending timestamps on updates and adding on a badly
       validated front end could lead to disaster. We can argue that I could have validated the timestamps themselves, but I chose
       human readability.
       startYield, stopYield, restartYield make a lot of sense. All we need to remember is that we first need to updateProject with 
       `daysEnd` or `daysInPast` if we start yield.
     */
    function addProject(address project_, FFProject memory FFProject_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(bytes(FFProject_.name).length > 0, "name missing");
        require(
            address(FFProject_.addr) == project_,
            "contract address mismatch"
        );
        require(uint256(FFProject_.yieldRate) > 0, "yieldRate must be > 0");
        require(
            uint256(FFProject_.yieldRate) <= MAX_YIELD,
            "can't exceed max yield"
        );
        /**
            starting, stopping and restarting is done by separate functions
            daysInPast and daysEnd serve to control the start and end dates prior to calling these functions
         */
        require(FFProject_.daysInPast > 0, "past days must be positive");
        require(FFProject_.daysEnd > 0, "end days must be positive");
        // make sure these are properly initialized
        FFProject_.start = 0;
        FFProject_.end = 0;

        projects[project_] = FFProject_;
        projectAddresses.push(project_);

        emit ProjectAdded(msg.sender, FFProject_);
    }

    function updateProject(address project_, FFProject calldata FFProject_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            bytes(projects[FFProject_.addr].name).length > 0,
            "project doesnt exist"
        );
        require(
            address(FFProject_.addr) == project_,
            "contract address mismatch"
        );
        require(bytes(FFProject_.name).length > 0, "name missing");
        require(uint256(FFProject_.yieldRate) > 0, "yieldRate must be > 0");
        require(
            uint256(FFProject_.yieldRate) <= MAX_YIELD,
            "can't exceed max yield"
        );
        // although we can change days in past, once the function startYield has been invoked, you can't change `start`
        require(FFProject_.daysInPast > 0, "past days must be positive");
        require(FFProject_.daysEnd > 0, "end days must be positive");
        // instead we take whatever we don't want to change from the existing project
        FFProject memory _FFProject;
        _FFProject.name = FFProject_.name;
        _FFProject.addr = FFProject_.addr;
        _FFProject.daysInPast = FFProject_.daysInPast;
        _FFProject.daysEnd = FFProject_.daysEnd;
        _FFProject.yieldRate = FFProject_.yieldRate;
        _FFProject.erc721Like = FFProject_.erc721Like;
        _FFProject.active = FFProject_.active;
        _FFProject.projectUrl = FFProject_.projectUrl;
        _FFProject.placeholderUrl = FFProject_.placeholderUrl;
        // we don't update start and end, do that with a separate function
        _FFProject.start = projects[FFProject_.addr].start;
        _FFProject.end = projects[FFProject_.addr].end;

        projects[FFProject_.addr] = _FFProject;

        emit ProjectUpdated(msg.sender, FFProject_);
    }

    function startYield(address project_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(projects[project_].start == 0, "yield already started");
        require(
            projects[project_].daysInPast > 0,
            "past days must be positive"
        );
        require(projects[project_].daysEnd > 0, "end days must be positive");
        projects[project_].start = block.timestamp.sub(
            projects[project_].daysInPast * 1 days
        );
        projects[project_].end = block.timestamp.add(
            projects[project_].daysEnd * 1 days
        );

        emit YieldStarted(
            msg.sender,
            project_,
            projects[project_].start,
            projects[project_].end
        );
    }

    /** 
        Restarting yield takes the value of daysEnd and sets `end` to now + daysEnd
    */
    function stopYield(address project_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(projects[project_].start > 0, "yield needs to be started");

        projects[project_].end = block.timestamp;

        emit YieldStopped(msg.sender, project_, projects[project_].end);
    }

    /** 
        Used to restart a stopped yield in the following scenarios
        1) yield has been stopped (end < now)
        2) end days need to be adjusted but also triggered (should we decide that the yield should stop earlier/later
           - in that case we send the daysEnd to the update project function and then we restart)
    */
    function restartYield(address project_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(projects[project_].start > 0, "yield needs to be started");
        require(projects[project_].daysEnd > 0, "end days must be positive");

        // if the days end didn't get updated during the stop and restart period,
        // the time passed will be added to the end days
        projects[project_].end = block.timestamp.add(
            projects[project_].daysEnd * 1 days
        );

        emit YieldRestarted(msg.sender, project_, projects[project_].end);
    }

    /** 
        For V1 we let trusted people change the rates. V2 should probably use an oracle 
    */
    function updateRates(FFRate[] calldata rates_) external onlyRole(RATOOOOR) {
        for (uint256 i = 0; i < rates_.length; i++) {
            uint256 rate = rates_[i].yieldRate;
            require(rate > 0, "yieldRate must be > 0");
            require(rate <= MAX_YIELD, "can't exceed max yield");

            projects[rates_[i].addr].yieldRate = rates_[i].yieldRate;
        }
        emit RatesUpdated(msg.sender, rates_);
    }

    /**
        In case we want to update the last claimable date (emergency only)
     */
    function updateLastClaims(
        address project_,
        uint256 id_,
        uint256 timestamp_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        lastClaims[project_][id_] = timestamp_;
    }

    /** #####
        Internal 
     */
    function pendingYield(address project_, uint256 id_)
        internal
        view
        returns (uint256)
    {
        uint256 _timeOffset = lastClaims[project_][id_] > 0
            ? lastClaims[project_][id_]
            : projects[project_].start;

        uint256 _end = projects[project_].end;

        if (block.timestamp > _end) {
            return
                (getYieldRate(project_).mul(_end.sub(_timeOffset))).div(
                    24 hours
                );
        } else {
            return
                (getYieldRate(project_).mul(block.timestamp.sub(_timeOffset)))
                    .div(24 hours);
        }
    }

    function claimAndSetLastClaimsERC721Like(
        address project_,
        uint256[] memory ids_
    ) internal returns (uint256 _totalClaim) {
        IERC721Like _projectERC721Like = IERC721Like(project_);

        for (uint256 i = 0; i < ids_.length; i++) {
            uint256 _id = ids_[i];
            address _owner = _projectERC721Like.ownerOf(_id);
            require(_owner != address(0), "token does not exist");
            require(_owner == msg.sender, "item owner mismatch");

            if (lastClaims[project_][_id] >= projects[project_].end) continue;
            _totalClaim = _totalClaim.add(pendingYield(project_, _id));
            lastClaims[project_][_id] = block.timestamp;
        }
    }

    /** #####
        Views 
    */
    function claimable(address project_, uint256 id_)
        public
        view
        returns (uint256 _claimable)
    {
        _claimable = pendingYield(project_, id_);
    }

    function totalClaimable(FFProjectIds[] calldata FFProjectIds_)
        external
        view
        returns (uint256 _totalClaim)
    {
        for (uint256 i = 0; i < FFProjectIds_.length; i++) {
            FFProjectIds memory _projectIds = FFProjectIds_[i];
            address _project = _projectIds.addr;
            uint256[] memory _ids = _projectIds.ids;

            for (uint256 j = 0; j < _ids.length; j++) {
                _totalClaim = _totalClaim.add(pendingYield(_project, _ids[j]));
            }
        }
    }

    function viewProjects(address[] calldata projects_)
        external
        view
        returns (FFProject[] memory)
    {
        FFProject[] memory _result = new FFProject[](projects_.length);

        for (uint256 i = 0; i < projects_.length; i++) {
            FFProject memory _project = projects[projects_[i]];
            _result[i] = _project;
        }

        return _result;
    }

    function viewAllProjects() external view returns (FFProject[] memory) {
        FFProject[] memory _result = new FFProject[](projectAddresses.length);

        for (uint256 i = 0; i < projectAddresses.length; i++) {
            FFProject memory _project = projects[projectAddresses[i]];
            _result[i] = _project;
        }

        return _result;
    }

    function getYieldRate(address project_) public view returns (uint256) {
        // the rate is in decimals but should represent a floating number with precision of two
        // therefore we multiply the rate by 10^16 instead of 10^18
        return projects[project_].yieldRate.mul(1e16);
        // return projects[project_].yieldRate.mul(1e18);
    }
}