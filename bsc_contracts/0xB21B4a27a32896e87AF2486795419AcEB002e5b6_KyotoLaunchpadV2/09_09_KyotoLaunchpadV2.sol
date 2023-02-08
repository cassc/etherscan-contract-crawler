// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

contract KyotoLaunchpadV2 is ReentrancyGuardUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;
    uint256 private constant PERCENT_DENOMINATOR = 10000;

    struct Project {
        address projectOwner; // Address of the Project owner
        address paymentToken; // Address of the payment token
        uint256 targetAmount; // Funds targeted to be raised for the project
        uint256 minInvestmentAmount; // Minimum amount of payment token that can be invested
        address projectToken; // Address of the Project token
        uint256 tokensForDistribution; // Number of tokens to be distributed
        uint256 tokenPrice; // Token price in payment token (Decimals same as payment token)
        uint256 winnersOutTime; // Timestamp at which winners are announced
        uint256 projectOpenTime; // Timestamp at which the Project is open for investment
        uint256 projectCloseTime; // Timestamp at which the Project is closed
        bool cancelled; // Boolean indicating if Project is cancelled
    }

    struct ProjectInvestment {
        uint256 totalInvestment; // Total investment in payment token
        uint256 totalProjectTokensClaimed; // Total number of Project tokens claimed
        uint256 totalInvestors; // Total number of investors
        bool collected; // Boolean indicating if the investment raised in Project collected
    }

    struct Investor {
        uint256 investment; // Amount of payment tokens invested by the investor
        bool claimed; // Boolean indicating if user has claimed Project tokens
        bool refunded; // Boolean indicating if user is refunded
    }

    address public owner; // Owner of the Smart Contract
    address public potentialOwner; // Potential owner's address
    uint256 public feePercentage; // Percentage of Funds raised to be paid as fee
    uint256 public BNBFromFailedTransfers; // BNB left in the contract from failed transfers

    mapping(string => Project) private _projects; // Project ID => Project{}

    mapping(string => ProjectInvestment) private _projectInvestments; // Project ID => ProjectInvestment{}

    mapping(string => bytes32) private _projectMerkleRoots; // IDO ID => Its Merkle Root

    mapping(string => mapping(address => Investor)) private _projectInvestors; // Project ID => userAddress => Investor{}

    mapping(address => bool) private _paymentSupported; // tokenAddress => Is token supported as payment

    mapping(bytes32 => mapping(address => bool)) private _roles; // role => walletAddress => status

    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));

    /* Events */
    event OwnerChange(address newOwner);
    event NominateOwner(address potentialOwner);
    event SetFeePercentage(uint256 feePercentage);
    event AddAdmin(address adminAddress);
    event RevokeAdmin(address adminAddress);
    event SetMerkleRoot(string projectID, bytes32 merkleRoot);
    event AddPaymentToken(address indexed paymentToken);
    event RemovePaymentToken(address indexed paymentToken);
    event ProjectAdd(
        string projectID,
        address projectOwner,
        address projectToken
    );
    event ProjectEdit(string projectID);
    event ProjectCancel(string projectID);
    event ProjectInvestmentCollect(string projectID);
    event ProjectInvest(
        string projectID,
        address indexed investor,
        uint256 investment
    );
    event ProjectInvestmentClaim(
        string projectID,
        address indexed investor,
        uint256 tokenAmount
    );
    event ProjectInvestmentRefund(
        string projectID,
        address indexed investor,
        uint256 refundAmount
    );
    event TransferOfBNBFail(address indexed receiver, uint256 indexed amount);

    /* Modifiers */
    modifier onlyOwner() {
        require(owner == msg.sender, "KyotoLaunchpad: Only owner allowed");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner || _roles[ADMIN][msg.sender],
        "KyotoLaunchpad: not authorized");
        _;
    }

    modifier onlyValidProject(string calldata projectID) {
        require(projectExist(projectID), "KyotoLaunchpad: invalid Project");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        owner = msg.sender;
    }

    /* Owner Functions */

    /** @notice This internal function is used to add an address as an admin
        @dev Only the platform owner can call this function
        @param role Role to be granted
        @param newAdmin Address of the new admin
     */
    function _addAdmin(bytes32 role, address newAdmin) internal {
        require(
            newAdmin != address(0),
            "KyotoLaunchpad: admin address zero"
        );
        _roles[role][newAdmin] = true;
        emit AddAdmin(newAdmin);
    }

    /** @notice This internal function is used to remove an admin
        @dev Only the platform owner can call this function
        @param role Role to be revoked
        @param adminAddress Address of the admin
     */
    function _removeAdmin(bytes32 role, address adminAddress) internal {
        require(
            adminAddress != address(0),
            "KyotoLaunchpad: admin address zero"
        );
        _roles[role][adminAddress] = false;
        emit RevokeAdmin(adminAddress);
    }

    /** @notice This function is used to add an address as an admin
        @dev Only the platform owner can call this function
        @param newAdmin Address of the new admin
     */
    function grantRole(address newAdmin) external onlyOwner {
        _addAdmin(ADMIN, newAdmin);
    }

    /** @notice This function is used to remove an admin
        @dev Only the platform owner can call this function
        @param adminAddress Address of the admin
     */
    function revokeRole(address adminAddress) external onlyOwner {
        _removeAdmin(ADMIN, adminAddress);
    }

    /**
     * @notice This function is used to add a potential owner of the contract
     * @dev Only the owner can call this function
     * @param _potentialOwner Address of the potential owner
     */
    function addPotentialOwner(address _potentialOwner) external onlyOwner {
        require(
            _potentialOwner != address(0),
            "KyotoLaunchpad: potential owner zero"
        );
        require(
            _potentialOwner != owner,
            "KyotoLaunchpad: potential owner same as owner"
        );
        potentialOwner = _potentialOwner;
        emit NominateOwner(_potentialOwner);
    }

    /**
     * @notice This function is used to accept ownership of the contract
     */
    function acceptOwnership() external {
        require(
            msg.sender == potentialOwner,
            "KyotoLaunchpad: only potential owner"
        );
        owner = potentialOwner;
        delete potentialOwner;
        emit OwnerChange(owner);
    }

    /**
     * @notice This method is used to set Merkle Root of an IDO
     * @dev This method can only be called by the contract owner
     * @param projectID ID of the IDO
     * @param merkleRoot Merkle Root of the IDO
     */
    function addMerkleRoot(string calldata projectID, bytes32 merkleRoot) 
        external 
        onlyValidProject(projectID)
        onlyAdmin(){
        
        require(
            _projects[projectID].winnersOutTime <= block.timestamp,
            "KyotoLaunchPad: cannot update before whitelisting closes"
        );
        require(
            _projectMerkleRoots[projectID] == bytes32(0),
            "KyotoLaunchPad: merkle root already added"
        );
        _projectMerkleRoots[projectID] = merkleRoot;
        emit SetMerkleRoot(projectID, merkleRoot);
    }

    /**
     * @notice This method is used to set commission percentage for the launchpad
     * @param _feePercentage Percentage from raised funds to be set as fee
     */
    function setFee(uint256 _feePercentage) external onlyAdmin(){

        require(
            _feePercentage <= 10000,
            "KyotoLaunchpad: fee Percentage should be less than 10000"
        );
        feePercentage = _feePercentage;
        emit SetFeePercentage(_feePercentage);
    }

    /* Payment Token */
    /**
     * @notice This method is used to add Payment token
     * @param _paymentToken Address of payment token to be added
     */
    function addPaymentToken(address _paymentToken) external onlyAdmin(){
        require(
            !_paymentSupported[_paymentToken],
            "KyotoLaunchpad: token already added"
        );
        _paymentSupported[_paymentToken] = true;
        emit AddPaymentToken(_paymentToken);
    }

    /**
     * @notice This method is used to remove Payment token
     * @param _paymentToken Address of payment token to be removed
     */
    function removePaymentToken(address _paymentToken) external onlyAdmin(){
        require(
            _paymentSupported[_paymentToken],
            "KyotoLaunchpad: token not added"
        );
        _paymentSupported[_paymentToken] = false;
        emit RemovePaymentToken(_paymentToken);
    }

    /**
     * @notice This method is used to check if a payment token is supported
     * @param _paymentToken Address of the token
     */
    function isPaymentTokenSupported(address _paymentToken)
        external
        view
        returns (bool)
    {
        return _paymentSupported[_paymentToken];
    }

    /* Helper Functions */
    /**
     * @dev This helper method is used to validate whether the address is whitelisted or not
     * @param merkleRoot Merkle Root of the IDO
     * @param merkleProof Merkle Proof of the user for that IDO
     */
    function _isWhitelisted(bytes32 merkleRoot, bytes32[] calldata merkleProof)
        private
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProofUpgradeable.verify(merkleProof, merkleRoot, leaf);
    }

    /**
     * @notice Helper function to transfer tokens based on type
     * @param receiver Address of the receiver
     * @param paymentToken Address of the token to be transferred
     * @param amount Number of tokens to transfer
     */
    function transferTokens(
        address receiver,
        address paymentToken,
        uint256 amount
    ) internal {
        if (amount != 0) {
            if (paymentToken != address(0)) {
                IERC20Upgradeable(paymentToken).safeTransfer(receiver, amount);
            } else {
                (bool success, ) = payable(receiver).call{value: amount}("");
                if (!success) {
                    BNBFromFailedTransfers += amount;
                    emit TransferOfBNBFail(receiver, amount);
                }
            }
        }
    }

    /**
     * @notice Helper function to estimate Project token amount for payment
     * @param amount Amount of payment tokens
     * @param projectToken Address of the Project token
     * @param tokenPrice Price for Project token
     */
    function estimateProjectTokens(
        address projectToken,
        uint256 tokenPrice,
        uint256 amount
    ) public view returns (uint256 projectTokenCount) {
        uint256 projectTokenDecimals = uint256(
            IERC20MetadataUpgradeable(projectToken).decimals()
        );
        projectTokenCount = (amount * 10**projectTokenDecimals) / tokenPrice;
    }

    /**
     * @notice Helper function to estimate Project token amount for payment
     * @param projectID ID of the Project
     * @param amount Amount of payment tokens
     */
    function estimateProjectTokensById(
        string calldata projectID,
        uint256 amount
    )
        external
        view
        onlyValidProject(projectID)
        returns (uint256 projectTokenCount)
    {
        uint256 projectTokenDecimals = uint256(
            IERC20MetadataUpgradeable(_projects[projectID].projectToken)
                .decimals()
        );
        projectTokenCount =
            (amount * 10**projectTokenDecimals) /
            _projects[projectID].tokenPrice;
    }

    /* Project */
    /**
     * @notice This method is used to check if an Project exist
     * @param projectID ID of the Project
     */
    function projectExist(string calldata projectID)
        public
        view
        returns (bool)
    {
        return _projects[projectID].projectOwner != address(0) ? true : false;
    }

    /**
     * @notice This method is used to get Project details
     * @param projectID ID of the Project
     */
    function getProject(string calldata projectID)
        external
        view
        onlyValidProject(projectID)
        returns (Project memory)
    {
        return _projects[projectID];
    }

    /**
     * @notice This method is used to get Project Investment details
     * @param projectID ID of the Project
     */
    function getProjectInvestment(string calldata projectID)
        external
        view
        onlyValidProject(projectID)
        returns (ProjectInvestment memory)
    {
        return _projectInvestments[projectID];
    }

    /**
     * @notice This method is used to get Project Investment details of an investor
     * @param projectID ID of the Project
     * @param investor Address of the investor
     */
    function getInvestor(string calldata projectID, address investor)
        external
        view
        onlyValidProject(projectID)
        returns (Investor memory)
    {
        return _projectInvestors[projectID][investor];
    }

    /**
     * @notice This method is used to add a new Private project
     * @dev This method can only be called by the contract owner
     * @param projectID ID of the Project to be added
     * @param projectOwner Address of the Project owner
     * @param paymentToken Payment token to be used for the Project
     * @param targetAmount Targeted amount to be raised in Project
     * @param minInvestmentAmount Minimum amount of payment token that can be invested in Project
     * @param projectToken Address of Project token
     * @param tokenPrice Project token price in terms of payment token
     * @param winnersOutTime Announcement of whitelisted addresses
     * @param projectOpenTime Project open timestamp
     * @param projectCloseTime Project close timestamp
     */
    function addPrivateLaunch(
        string calldata projectID,
        address projectOwner,
        address paymentToken,
        uint256 targetAmount,
        uint256 minInvestmentAmount,
        address projectToken,
        uint256 tokenPrice,
        uint256 winnersOutTime,
        uint256 projectOpenTime,
        uint256 projectCloseTime
    ) external 
      nonReentrant
      onlyAdmin(){
        require(
            !projectExist(projectID),
            "KyotoLaunchpad: Project id already exist"
        );
        require(
            projectOwner != address(0),
            "KyotoLaunchpad: Project owner zero"
        );
        require(
            _paymentSupported[paymentToken],
            "KyotoLaunchpad: payment token not supported"
        );
        require(targetAmount != 0, "KyotoLaunchpad: target amount zero");
        require(tokenPrice != 0, "KyotoLaunchpad: token price zero");
        require(
            block.timestamp < winnersOutTime &&
                winnersOutTime <= projectOpenTime &&
                projectOpenTime < projectCloseTime,
            "KyotoLaunchpad: Project invalid timestamps"
        );

        if(projectToken != address(0)){  
            uint256 tokensForDistribution = estimateProjectTokens(
                projectToken,
                tokenPrice,
                targetAmount);

            _projects[projectID] = Project(
            projectOwner,
            paymentToken,
            targetAmount,
            minInvestmentAmount,
            projectToken,
            tokensForDistribution,
            tokenPrice,
            winnersOutTime,
            projectOpenTime,
            projectCloseTime,
            false
        );

            IERC20Upgradeable(projectToken).safeTransferFrom(
                projectOwner,
                address(this),
                tokensForDistribution
            );
        } else {
            _projects[projectID] = Project(
            projectOwner,
            paymentToken,
            targetAmount,
            minInvestmentAmount,
            projectToken,
            0,
            tokenPrice,
            winnersOutTime,
            projectOpenTime,
            projectCloseTime,
            false
            );
        }    
        emit ProjectAdd(projectID, projectOwner, projectToken);
    }

    /**
     * @notice This method is used to add a new Public project
     * @dev This method can only be called by the contract owner
     * @param projectID ID of the Project to be added
     * @param projectOwner Address of the Project owner
     * @param paymentToken Payment token to be used for the Project
     * @param targetAmount Targeted amount to be raised in Project
     * @param minInvestmentAmount Minimum amount of payment token that can be invested in Project
     * @param projectToken Address of Project token
     * @param tokenPrice Project token price in terms of payment token
     * @param presaleStartTime Beginning of pre-sale round. 0 for public launch
     * @param projectOpenTime Project open timestamp
     * @param projectCloseTime Project close timestamp
     */
    function addPublicLaunch(
        string calldata projectID,
        address projectOwner,
        address paymentToken,
        uint256 targetAmount,
        uint256 minInvestmentAmount,
        address projectToken,
        uint256 tokenPrice,
        uint256 presaleStartTime,
        uint256 projectOpenTime,
        uint256 projectCloseTime
    ) external 
      onlyAdmin()
      nonReentrant{
        require(
            !projectExist(projectID),
            "KyotoLaunchpad: Project id already exist"
        );
        require(
            projectOwner != address(0),
            "KyotoLaunchpad: Project owner zero"
        );
        require(
            _paymentSupported[paymentToken],
            "KyotoLaunchpad: payment token not supported"
        );
        require(targetAmount != 0, "KyotoLaunchpad: target amount zero");
        require(tokenPrice != 0, "KyotoLaunchpad: token price zero");
        require(presaleStartTime == 0, "KyotoLaunchpad: presale time not zero");
        require(block.timestamp < projectOpenTime 
                && projectOpenTime < projectCloseTime,
            "KyotoLaunchpad: Project invalid timestamps"
        );

        if(projectToken != address(0)){  
            uint256 tokensForDistribution = estimateProjectTokens(
                projectToken,
                tokenPrice,
                targetAmount);

            _projects[projectID] = Project(
            projectOwner,
            paymentToken,
            targetAmount,
            minInvestmentAmount,
            projectToken,
            tokensForDistribution,
            tokenPrice,
            presaleStartTime,
            projectOpenTime,
            projectCloseTime,
            false
        );

            IERC20Upgradeable(projectToken).safeTransferFrom(
                projectOwner,
                address(this),
                tokensForDistribution
            );
        } else {
            _projects[projectID] = Project(
            projectOwner,
            paymentToken,
            targetAmount,
            minInvestmentAmount,
            projectToken,
            0,
            tokenPrice,
            presaleStartTime,
            projectOpenTime,
            projectCloseTime,
            false
            );
        }   
        emit ProjectAdd(projectID, projectOwner, projectToken);
    }

    /**
     * @notice This method is used to add a new project with presale round
     * @dev This method can only be called by the contract owner
     * @param projectID ID of the Project to be added
     * @param projectOwner Address of the Project owner
     * @param paymentToken Payment token to be used for the Project
     * @param targetAmount Targeted amount to be raised in Project
     * @param minInvestmentAmount Minimum amount of payment token that can be invested in Project
     * @param projectToken Address of Project token
     * @param tokenPrice Project token price in terms of payment token
     * @param presaleStartTime Beginning of pre-sale round. 0 for public launch
     * @param projectOpenTime Project open timestamp
     * @param projectCloseTime Project close timestamp
     */
    function addPresaleLaunch(
        string calldata projectID,
        address projectOwner,
        address paymentToken,
        uint256 targetAmount,
        uint256 minInvestmentAmount,
        address projectToken,
        uint256 tokenPrice,
        uint256 presaleStartTime,
        uint256 projectOpenTime,
        uint256 projectCloseTime
    ) external 
      onlyAdmin()
      nonReentrant{
        require(
            !projectExist(projectID),
            "KyotoLaunchpad: Project id already exist"
        );
        require(
            projectOwner != address(0),
            "KyotoLaunchpad: Project owner zero"
        );
        require(
            _paymentSupported[paymentToken],
            "KyotoLaunchpad: payment token not supported"
        );
        require(targetAmount != 0, "KyotoLaunchpad: target amount zero");
        require(tokenPrice != 0, "KyotoLaunchpad: token price zero");
        require(
            block.timestamp < presaleStartTime &&
                presaleStartTime <= projectOpenTime &&
                projectOpenTime < projectCloseTime,
            "KyotoLaunchpad: Project invalid timestamps"
        );

        if(projectToken != address(0)){  
            uint256 tokensForDistribution = estimateProjectTokens(
                projectToken,
                tokenPrice,
                targetAmount);

            _projects[projectID] = Project(
            projectOwner,
            paymentToken,
            targetAmount,
            minInvestmentAmount,
            projectToken,
            tokensForDistribution,
            tokenPrice,
            presaleStartTime,
            projectOpenTime,
            projectCloseTime,
            false
        );

            IERC20Upgradeable(projectToken).safeTransferFrom(
                projectOwner,
                address(this),
                tokensForDistribution
            );
        } else {
            _projects[projectID] = Project(
            projectOwner,
            paymentToken,
            targetAmount,
            minInvestmentAmount,
            projectToken,
            0,
            tokenPrice,
            presaleStartTime,
            projectOpenTime,
            projectCloseTime,
            false
            );
        }    
        emit ProjectAdd(projectID, projectOwner, projectToken);
    }

    /**
     * @notice This method is used to edit a Private project
     * @dev This method can only be called by the contract owner
     * @param projectID ID of the Project to be added
     * @param projectOwner Address of the Project owner
     * @param paymentToken Payment token to be used for the Project
     * @param targetAmount Targeted amount to be raised in Project
     * @param minInvestmentAmount Minimum amount of payment token that can be invested in Project
     * @param projectToken Address of Project token
     * @param tokenPrice Project token price in terms of payment token
     * @param winnersOutTime Announcement of whitelisted addresses
     * @param projectOpenTime Project open timestamp
     * @param projectCloseTime Project close timestamp
     */
    function editPrivateProject(
        string calldata projectID,
        address projectOwner,
        address paymentToken,
        uint256 targetAmount,
        uint256 minInvestmentAmount,
        address projectToken,
        uint256 tokenPrice,
        uint256 winnersOutTime,
        uint256 projectOpenTime,
        uint256 projectCloseTime
    ) external 
      onlyAdmin()
      nonReentrant{
        require(
            projectExist(projectID),
            "KyotoLaunchpad: Project does not exist"
        );
        require(
            projectOwner != address(0),
            "KyotoLaunchpad: Project owner zero"
        );
        require(
            _paymentSupported[paymentToken],
            "KyotoLaunchpad: payment token not supported"
        );
        require(targetAmount != 0, "KyotoLaunchpad: target amount zero");
        require(tokenPrice != 0, "KyotoLaunchpad: token price zero");

        if(projectToken != address(0)){  
            uint256 tokensForDistribution = estimateProjectTokens(
                projectToken,
                tokenPrice,
                targetAmount);

            _projects[projectID] = Project(
            projectOwner,
            paymentToken,
            targetAmount,
            minInvestmentAmount,
            projectToken,
            tokensForDistribution,
            tokenPrice,
            winnersOutTime,
            projectOpenTime,
            projectCloseTime,
            false
        );

            IERC20Upgradeable(projectToken).safeTransferFrom(
                projectOwner,
                address(this),
                tokensForDistribution
            );
        } else {
            _projects[projectID] = Project(
            projectOwner,
            paymentToken,
            targetAmount,
            minInvestmentAmount,
            projectToken,
            0,
            tokenPrice,
            winnersOutTime,
            projectOpenTime,
            projectCloseTime,
            false
            );
        }   
        emit ProjectEdit(projectID);
    }

    /**
     * @notice This method is used to edit a Public project
     * @dev This method can only be called by the contract owner
     * @param projectID ID of the Project to be added
     * @param projectOwner Address of the Project owner
     * @param paymentToken Payment token to be used for the Project
     * @param targetAmount Targeted amount to be raised in Project
     * @param minInvestmentAmount Minimum amount of payment token that can be invested in Project
     * @param projectToken Address of Project token
     * @param tokenPrice Project token price in terms of payment token
     * @param presaleStartTime Beginning of pre-sale round. 0 for public launch
     * @param projectOpenTime Project open timestamp
     * @param projectCloseTime Project close timestamp
     */
    function editPublicProject(
        string calldata projectID,
        address projectOwner,
        address paymentToken,
        uint256 targetAmount,
        uint256 minInvestmentAmount,
        address projectToken,
        uint256 tokenPrice,
        uint256 presaleStartTime,
        uint256 projectOpenTime,
        uint256 projectCloseTime
    ) external
      onlyAdmin()
      nonReentrant{
        require(
            projectExist(projectID),
            "KyotoLaunchpad: Project does not exist"
        );
        require(
            projectOwner != address(0),
            "KyotoLaunchpad: Project owner zero"
        );
        require(
            _paymentSupported[paymentToken],
            "KyotoLaunchpad: payment token not supported"
        );
        require(targetAmount != 0, "KyotoLaunchpad: target amount zero");
        require(tokenPrice != 0, "KyotoLaunchpad: token price zero");

        if(projectToken != address(0)){  
            uint256 tokensForDistribution = estimateProjectTokens(
                projectToken,
                tokenPrice,
                targetAmount);

            _projects[projectID] = Project(
            projectOwner,
            paymentToken,
            targetAmount,
            minInvestmentAmount,
            projectToken,
            tokensForDistribution,
            tokenPrice,
            presaleStartTime,
            projectOpenTime,
            projectCloseTime,
            false
        );

            IERC20Upgradeable(projectToken).safeTransferFrom(
                projectOwner,
                address(this),
                tokensForDistribution
            );
        } else {
            _projects[projectID] = Project(
            projectOwner,
            paymentToken,
            targetAmount,
            minInvestmentAmount,
            projectToken,
            0,
            tokenPrice,
            presaleStartTime,
            projectOpenTime,
            projectCloseTime,
            false
            );
        }   
        emit ProjectEdit(projectID);
      }

    /**
     * @notice This method is used to edit a project with pre sale round
     * @dev This method can only be called by the contract owner
     * @param projectID ID of the Project to be added
     * @param projectOwner Address of the Project owner
     * @param paymentToken Payment token to be used for the Project
     * @param targetAmount Targeted amount to be raised in Project
     * @param minInvestmentAmount Minimum amount of payment token that can be invested in Project
     * @param projectToken Address of Project token
     * @param tokenPrice Project token price in terms of payment token
     * @param presaleStartTime Beginning of pre-sale round. 0 for public launch
     * @param projectOpenTime Project open timestamp
     * @param projectCloseTime Project close timestamp
     */
    function editPresaleProject(
        string calldata projectID,
        address projectOwner,
        address paymentToken,
        uint256 targetAmount,
        uint256 minInvestmentAmount,
        address projectToken,
        uint256 tokenPrice,
        uint256 presaleStartTime,
        uint256 projectOpenTime,
        uint256 projectCloseTime
    ) external
      onlyAdmin()
      nonReentrant{
        require(
            projectExist(projectID),
            "KyotoLaunchpad: Project does not exist"
        );
        require(
            projectOwner != address(0),
            "KyotoLaunchpad: Project owner zero"
        );
        require(
            _paymentSupported[paymentToken],
            "KyotoLaunchpad: payment token not supported"
        );
        require(targetAmount != 0, "KyotoLaunchpad: target amount zero");
        require(tokenPrice != 0, "KyotoLaunchpad: token price zero");

        if(projectToken != address(0)){  
            uint256 tokensForDistribution = estimateProjectTokens(
                projectToken,
                tokenPrice,
                targetAmount);

            _projects[projectID] = Project(
            projectOwner,
            paymentToken,
            targetAmount,
            minInvestmentAmount,
            projectToken,
            tokensForDistribution,
            tokenPrice,
            presaleStartTime,
            projectOpenTime,
            projectCloseTime,
            false
        );

            IERC20Upgradeable(projectToken).safeTransferFrom(
                projectOwner,
                address(this),
                tokensForDistribution
            );
        } else {
            _projects[projectID] = Project(
            projectOwner,
            paymentToken,
            targetAmount,
            minInvestmentAmount,
            projectToken,
            0,
            tokenPrice,
            presaleStartTime,
            projectOpenTime,
            projectCloseTime,
            false
            );
        }    
        emit ProjectEdit(projectID);
      }

    /**
     * @notice This method is used to cancel an Project
     * @dev This method can only be called by the contract owner
     * @param projectID ID of the Project
     */
    function cancelIDO(string calldata projectID)
        external
        onlyValidProject(projectID)
        onlyAdmin()
    {
        Project memory project = _projects[projectID];
        require(
            !project.cancelled,
            "KyotoLaunchpad: Project already cancelled"
        );
        require(
            block.timestamp < project.projectCloseTime,
            "KyotoLaunchpad: Project is closed"
        );

        _projects[projectID].cancelled = true;
        if(project.projectToken != address(0)){
            IERC20Upgradeable(project.projectToken).safeTransfer(
                project.projectOwner,
                project.tokensForDistribution
            );
        }
        emit ProjectCancel(projectID);
    }

    /**
     * @notice This method is used to distribute investment raised in Project
     * @dev This method can only be called by the contract owner
     * @param projectID ID of the Project
     */
    function collectIDOInvestment(string calldata projectID)
        external
        onlyValidProject(projectID)
        onlyAdmin()
    {
        Project memory project = _projects[projectID];
        require(project.projectToken != address(0),
                "KyotoLaunchpad: Project token not added yet");
        require(!project.cancelled, "KyotoLaunchpad: Project is cancelled");
        require(
            block.timestamp > project.projectCloseTime,
            "KyotoLaunchpad: Project is open"
        );

        ProjectInvestment memory projectInvestment = _projectInvestments[
            projectID
        ];

        require(
            !projectInvestment.collected,
            "KyotoLaunchpad: Project investment already collected"
        );

        _projectInvestments[projectID].collected = true;

        if(projectInvestment.totalInvestment == 0){
            IERC20Upgradeable(project.projectToken).safeTransfer(
            project.projectOwner,
            project.tokensForDistribution
        );
        }
        else{
            uint256 platformShare = feePercentage == 0
                ? 0
                : (feePercentage * projectInvestment.totalInvestment) /
                    PERCENT_DENOMINATOR;

            _projectInvestments[projectID].collected = true;

            transferTokens(owner, project.paymentToken, platformShare);
            transferTokens(
                project.projectOwner,
                project.paymentToken,
                projectInvestment.totalInvestment - platformShare
            );

            uint256 projectTokensLeftover = project.tokensForDistribution -
                estimateProjectTokens(
                    project.projectToken,
                    project.tokenPrice,
                    projectInvestment.totalInvestment
                );
            transferTokens(
                project.projectOwner,
                project.projectToken,
                projectTokensLeftover
            );
        } 

        emit ProjectInvestmentCollect(projectID);
    }

    /**
     * @notice This method is used to invest in a privately listed Project
     * @dev User must send _amount in order to invest in BNB
     * @dev User must be whitelisted to invest
     * @param projectID ID of the Project
     */
    function investPrivateLaunch(string calldata projectID, bytes32[] calldata merkleProof, uint256 _amount)
        external
        payable
    {
        require(
            projectExist(projectID),
            "KyotoLaunchpad: Project does not exist"
        );
        require(_amount != 0, "KyotoLaunchpad: investment zero");

        Project memory project = _projects[projectID];
        require(
            block.timestamp >= project.projectOpenTime,
            "KyotoLaunchpad: Project is not open"
        );
        require(
            block.timestamp < project.projectCloseTime,
            "KyotoLaunchpad: Project has closed"
        );
        require(!project.cancelled, "KyotoLaunchpad: Project cancelled");
        require(
            _amount >= project.minInvestmentAmount,
            "KyotoLaunchpad: amount less than minimum investment"
        );
        ProjectInvestment storage projectInvestment = _projectInvestments[
            projectID
        ];

        require(
            project.targetAmount >= projectInvestment.totalInvestment + _amount,
            "KyotoLaunchpad: amount exceeds target"
        );
        require(
            _projectMerkleRoots[projectID] != bytes32(0),
            "KyotoLaunchPad: whitelist not approved by admin yet"
        );
        require(
            _isWhitelisted(_projectMerkleRoots[projectID], merkleProof),
            "KyotoLaunchPad: user is not whitelisted"
        );

        projectInvestment.totalInvestment += _amount;
        if (_projectInvestors[projectID][msg.sender].investment == 0)
            ++projectInvestment.totalInvestors;
        _projectInvestors[projectID][msg.sender].investment += _amount;

        if (project.paymentToken == address(0)) {
            require(
                msg.value == _amount,
                "KyotoLaunchpad: msg.value not equal to amount"
            );
        } else {
            require(msg.value == 0, "KyotoLaunchpad: msg.value not zero");
            IERC20Upgradeable(project.paymentToken).safeTransferFrom(
                msg.sender,
                address(this),
                _amount
            );
        }

        emit ProjectInvest(projectID, msg.sender, _amount);
    }

    /**
     * @notice This method is used to invest in a publicly listed Project
     * @dev User must send _amount in order to invest in BNB
     * @param projectID ID of the Project
     */
    function investFairLaunch(string calldata projectID, uint256 _amount)
        external
        payable
    {
        require(
            projectExist(projectID),
            "KyotoLaunchpad: Project does not exist"
        );
        require(_amount != 0, "KyotoLaunchpad: investment zero");

        Project memory project = _projects[projectID];
        require(
            block.timestamp >= project.projectOpenTime,
            "KyotoLaunchpad: Project is not open"
        );
        require(
            block.timestamp < project.projectCloseTime,
            "KyotoLaunchpad: Project has closed"
        );
        require(!project.cancelled, "KyotoLaunchpad: Project cancelled");
        require(
            _amount >= project.minInvestmentAmount,
            "KyotoLaunchpad: amount less than minimum investment"
        );
        ProjectInvestment storage projectInvestment = _projectInvestments[
            projectID
        ];

        require(
            project.targetAmount >= projectInvestment.totalInvestment + _amount,
            "KyotoLaunchpad: amount exceeds target"
        );

        projectInvestment.totalInvestment += _amount;
        if (_projectInvestors[projectID][msg.sender].investment == 0)
            ++projectInvestment.totalInvestors;
        _projectInvestors[projectID][msg.sender].investment += _amount;

        if (project.paymentToken == address(0)) {
            require(
                msg.value == _amount,
                "KyotoLaunchpad: msg.value not equal to amount"
            );
        } else {
            require(msg.value == 0, "KyotoLaunchpad: msg.value not zero");
            IERC20Upgradeable(project.paymentToken).safeTransferFrom(
                msg.sender,
                address(this),
                _amount
            );
        }

        emit ProjectInvest(projectID, msg.sender, _amount);
    }

    /**
     * @notice This method is used to invest in a project with a presale round
     * @dev User must send _amount in order to invest in BNB
     * @dev User must be whitelisted to invest in presale round
     * @param projectID ID of the Project
     */
    function investPresale(string calldata projectID, bytes32[] calldata merkleProof, uint256 _amount)
        external
        payable
    {
        require(
            projectExist(projectID),
            "KyotoLaunchpad: Project does not exist"
        );
        require(_amount != 0, "KyotoLaunchpad: investment zero");
        Project memory project = _projects[projectID];
        require(
            block.timestamp >= project.winnersOutTime,
            "KyotoLaunchpad: Project is not open"
        );
        if(block.timestamp >= project.winnersOutTime && block.timestamp < project.projectOpenTime){
            require(
                _projectMerkleRoots[projectID] != bytes32(0),
                "KyotoLaunchPad: whitelist not approved by admin yet"
            );
            require(
                _isWhitelisted(_projectMerkleRoots[projectID], merkleProof),
                "KyotoLaunchPad: user is not whitelisted"
            );
        }
        require(
            block.timestamp < project.projectCloseTime,
            "KyotoLaunchpad: Project closed"
        );
        require(!project.cancelled, "KyotoLaunchpad: Project cancelled");
        require(
            _amount >= project.minInvestmentAmount,
            "KyotoLaunchpad: amount less than minimum investment"
        );
        ProjectInvestment storage projectInvestment = _projectInvestments[
            projectID
        ];

        require(
            project.targetAmount >= projectInvestment.totalInvestment + _amount,
            "KyotoLaunchpad: amount exceeds target"
        );

        projectInvestment.totalInvestment += _amount;
        if (_projectInvestors[projectID][msg.sender].investment == 0)
            ++projectInvestment.totalInvestors;
        _projectInvestors[projectID][msg.sender].investment += _amount;

        if (project.paymentToken == address(0)) {
            require(
                msg.value == _amount,
                "KyotoLaunchpad: msg.value not equal to amount"
            );
        } else {
            require(msg.value == 0, "KyotoLaunchpad: msg.value not zero");
            IERC20Upgradeable(project.paymentToken).safeTransferFrom(
                msg.sender,
                address(this),
                _amount
            );
        }

        emit ProjectInvest(projectID, msg.sender, _amount);
    }

    /**
     * @notice This method is used to refund investment if Project is cancelled
     * @param projectID ID of the Project
     */
    function refundInvestment(string calldata projectID)
        external
        onlyValidProject(projectID)
    {

        Project memory project = _projects[projectID];
        require(
            project.cancelled,
            "KyotoLaunchpad: Project is not cancelled"
        );

        Investor memory user = _projectInvestors[projectID][msg.sender];
        require(!user.refunded, "KyotoLaunchpad: already refunded");
        require(user.investment != 0, "KyotoLaunchpad: no investment found");

        _projectInvestors[projectID][msg.sender].refunded = true;
        transferTokens(msg.sender, project.paymentToken, user.investment);

        emit ProjectInvestmentRefund(projectID, msg.sender, user.investment);
    }

    /**
     * @notice This method is used to claim investment if Project is closed
     * @param projectID ID of the Project
     */
    function claimIDOTokens(string calldata projectID)
        external
        onlyValidProject(projectID)
    {
        Project memory project = _projects[projectID];

        require(!project.cancelled, "KyotoLaunchpad: Project is cancelled");
        require(
            block.timestamp > project.projectCloseTime,
            "KyotoLaunchpad: Project not closed yet"
        );

        Investor memory user = _projectInvestors[projectID][msg.sender];
        require(!user.claimed, "KyotoLaunchpad: already claimed");
        require(user.investment != 0, "KyotoLaunchpad: no investment found");

        uint256 projectTokens = estimateProjectTokens(
            project.projectToken,
            project.tokenPrice,
            user.investment
        );
        _projectInvestors[projectID][msg.sender].claimed = true;
        _projectInvestments[projectID]
            .totalProjectTokensClaimed += projectTokens;

        IERC20Upgradeable(project.projectToken).safeTransfer(
            msg.sender,
            projectTokens
        );

        emit ProjectInvestmentClaim(projectID, msg.sender, projectTokens);
    }

    /**
     * @notice This method is to collect any BNB left from failed transfers.
     * @dev This method can only be called by the contract owner
     */
    function collectBNBFromFailedTransfers() external onlyAdmin(){
        uint256 bnbToSend = BNBFromFailedTransfers;
        BNBFromFailedTransfers = 0;
        (bool success, ) = payable(owner).call{value: bnbToSend}("");
        require(success, "KyotoLaunchpad: BNB transfer failed");
    }
}