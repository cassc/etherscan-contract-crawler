// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


import "../@openzeppelin/contracts/security/Pausable.sol";
import "../@openzeppelin/contracts/access/Ownable.sol";
import "../@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "../@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../@openzeppelin/contracts/proxy/Clones.sol";

import "../project/ProjectParams.sol";
import "../project/ProjectInitParams.sol";
import "../milestone/Milestone.sol";
import "../milestone/MilestoneResult.sol";
import "../token/CommonGoodProjectToken.sol";
import "../token/IMintableOwnedERC20.sol";
import "../vault/IVault.sol";
import "../project/IProject.sol";
import "../libs/Sanitizer.sol";
import "./BetaTestable.sol";


abstract contract ProjectFactory is BetaTestable, /*Ownable*/ Pausable {

    using Clones for address;

    address immutable public projectTemplate;

    address immutable public vaultTemplate;


    uint public onChangeExitGracePeriod = 7 days; 
    
    uint public pledgerGraceExitWaitTime = 14 days;

    mapping(address => IProject) public addressToProject;

    mapping(address => bool) public isApprovedPaymentToken;


    address[] public projectAddresses; // all created projects - either in-progress or completed

    //--------

    mapping(address => bool) public approvedVaults;

    uint public minNumMilestones;
    uint public maxNumMilestones;



    //----

    modifier onlyIfCallingProjectSucceeded() {
        IProject callingProject_ = addressToProject[ msg.sender];
        require( callingProject_.getProjectState() == ProjectState.SUCCEEDED, "project not succeeded");
        _;
    }

    modifier legalNumberOfMilestones( Milestone[] memory milestones_) {
        require( milestones_.length >= minNumMilestones, "not enough milestones");
        require( milestones_.length <= maxNumMilestones, "too many milestones");
        _;
    }

    //----

    constructor(address projectTemplate_, address vaultTemplate_) {
        projectTemplate = projectTemplate_;
        vaultTemplate = vaultTemplate_;
        minNumMilestones = 1;
        maxNumMilestones = 400;

    }

    event ApprovedPaymentTokenChanged( address indexed paymentToken, bool isLegal);

    event ProjectWasDeployed(uint indexed projectIndex, address indexed projectAddress, address indexed projectVault,
                            uint numMilestones, address projectToken, string tokenName, string tokenSymbol, uint tokenSupply,
                            uint onChangeExitGracePeriod, uint pledgerGraceExitWaitTime);

    event OnChangeExitGracePeriodChanged( uint newGracePeriod, uint oldGracePeriod);

    event PledgerGraceExitWaitTimeChanged( uint newValue, uint oldValue);

    event MliestoneLimitsChanged( uint new_minNumMilestones, uint indexed old_minNumMilestones,
                                  uint new_maxNumMilestones, uint indexed old_maxNumMilestones );
    //---

    error ExternallyProvidedProjectVaultMustBeOwnedByPlatform( address vault_, address vaultOwner_);

    error ExternallyProvidedProjectTokenMustBeOwnedByPlatform( address projectToken, address actualOwner_);

    error ProjectTokenMustBeIMintableERC20( address projectToken_);

    error NotAnApprovedVault(address projectVault_, address teamAddr);              

    error MilestoneInitialResultMustBeUnresolved(uint milestoneIndex, MilestoneResult milestoneResult);

    error InvalidVault(address vault);
    //----

    function _approvedPaymentToken(address paymentTokenAddr_) private view returns(bool) {
        return paymentTokenAddr_ != address(0) && isApprovedPaymentToken[ paymentTokenAddr_];
    }


/*
 * @title createProject()
 *
 * @dev create a _new project, must be called by an approved team wallet address with a complete
 * list fo milestones and parameters
 * Internally: will create project vault and a dedicated project token, unless externally provided
 * and will instantiate and deploy a project contract
 *
 * @precondition: externally provided vault and project-token, if any, must be platform owned
 * @postcondition: vault and project-token will be owned by project when exiting this function
 *
 * @event: ProjectWasDeployed
 */
    //@DOC1
    function createProject( ProjectParams memory params_, Milestone[] memory milestones_) external
                                onlyValidBetaTester
                                legalNumberOfMilestones( milestones_)
                                whenNotPaused { //@PUBFUNC

        uint projectIndex_ = projectAddresses.length;

        address projectTeamWallet_ = msg.sender;

        require( _approvedPaymentToken( params_.paymentToken), "payment token not approved");

        Sanitizer._sanitizeMilestones(milestones_, block.timestamp, minNumMilestones, maxNumMilestones);


        //@gilad externl vault initially owned by platform address => after owned by project
        if (params_.projectVault == address(0)) {
            // deploy a dedicated DefaultVault contract
            params_.projectVault = vaultTemplate.clone();

        } else {
            _validateExternalVault( IVault(params_.projectVault));
        }

        if (params_.projectToken == address(0)) {
            // deploy a dedicated CommonGoodProjectToken contract
            CommonGoodProjectToken newDeployedToken_ = new CommonGoodProjectToken(params_.tokenName, params_.tokenSymbol);
            params_.projectToken = address( newDeployedToken_);

        } else {
            _validateExternalToken( IMintableOwnedERC20(params_.projectToken));
        }

        IMintableOwnedERC20 projToken_ = IMintableOwnedERC20(params_.projectToken);
        require( projToken_.getOwner() == address(this), "Project token must initially be owned by Platform");

        //-------------
        IProject project_ = IProject( projectTemplate.clone());


        IVault(params_.projectVault).initialize( address(project_));


        require( IVault(params_.projectVault).getOwner() == address(project_), "Vault must be owned by project");


        ProjectInitParams memory initParams_ = ProjectInitParams( {
            projectTeamWallet: projectTeamWallet_,
            vault: IVault(params_.projectVault),
            milestones: milestones_,
            projectToken: projToken_,
            platformCutPromils: _getPlatformCutPromils(),
            minPledgedSum: params_.minPledgedSum,
            onChangeExitGracePeriod: onChangeExitGracePeriod,
            pledgerGraceExitWaitTime: pledgerGraceExitWaitTime,
            paymentToken: params_.paymentToken,
            cid: params_.cid
        });

        project_.initialize( initParams_);

        require( project_.getOwner() == projectTeamWallet_, "Project must be owned by team");
        //-------------


        addressToProject[ address(project_)] = project_;

        projectAddresses.push( address(project_));

        projToken_.setConnectedProject( project_);

        projToken_.performInitialMint( params_.initialTokenSupply);

        projToken_.changeOwnership( address(project_));

        require( projToken_.getOwner() == address(project_), "Project token must be owned by Platform");

        emit ProjectWasDeployed( projectIndex_, address(project_), params_.projectVault, milestones_.length,
                                 params_.projectToken, params_.tokenName, params_.tokenSymbol,
                                 params_.initialTokenSupply, onChangeExitGracePeriod, pledgerGraceExitWaitTime);
    }


    function _validateExternalToken( IMintableOwnedERC20 projectToken_) private view {
        if ( !ERC165Checker.supportsInterface( address(projectToken_), type(IMintableOwnedERC20).interfaceId)) {
            revert ProjectTokenMustBeIMintableERC20( address(projectToken_));
        }

        address tokenOwner_ = projectToken_.getOwner();
        if ( tokenOwner_ != address(this) && tokenOwner_ != address(0)) {
            revert ExternallyProvidedProjectTokenMustBeOwnedByPlatform( address( projectToken_), tokenOwner_);
        }
    }


    function _validateExternalVault( IVault vault_) private view {
        if ( !_isAnApprovedVault(address(vault_))) {
            revert NotAnApprovedVault( address(vault_), msg.sender);
        }

        if ( !_supportIVaultInterface(address(vault_))) {
            revert InvalidVault( address(vault_));
        }

        address vaultOwner_ = IVault(vault_).getOwner();
        if ( vaultOwner_ != address(this) && vaultOwner_ != address(0)) {
            revert ExternallyProvidedProjectVaultMustBeOwnedByPlatform( address(vault_), vaultOwner_);
        }
    }

    function _supportIVaultInterface(address projectVault_) private view returns(bool) {
        return ERC165Checker.supportsInterface( projectVault_, type(IVault).interfaceId);
    }

    function _validProjectAddress( address projectAddr_) internal view returns(bool) {
        return addressToProject[ projectAddr_].getProjectStartTime() > 0;
    }

    function setMilestoneMinMaxCounts( uint new_minNumMilestones, uint new_maxNumMilestones) external onlyOwner { //@PUBFUNC
        uint old_minNumMilestones = minNumMilestones;
        uint old_maxNumMilestones = maxNumMilestones;

        minNumMilestones = new_minNumMilestones;
        maxNumMilestones = new_maxNumMilestones;

        emit MliestoneLimitsChanged( minNumMilestones, old_minNumMilestones, maxNumMilestones, old_maxNumMilestones);
    }


    function approvePTok(address paymentTokenAddr_, bool isApproved_) external onlyOwner { //@PUBFUNC
        require( paymentTokenAddr_ != address(0), "bad payment token address");
        isApprovedPaymentToken[ paymentTokenAddr_] = isApproved_;
        emit ApprovedPaymentTokenChanged( paymentTokenAddr_, isApproved_);
    }


/*
 * @title setProjectChangeGracePeriod()
 *
 * @dev Sets the project grace period where pledgers are allowed to exit after project details change
 * Note that this change will only affect _new projects
 *
 * @event: OnChangeExitGracePeriodChanged
 */
    function setProjectChangeGracePeriod(uint newGracePeriod) external onlyOwner { //@PUBFUNC
        // set grace period allowing pledgers to gracefully exit after project change
        uint oldGracePeriod_ = onChangeExitGracePeriod;
        onChangeExitGracePeriod = newGracePeriod;
        emit OnChangeExitGracePeriodChanged( onChangeExitGracePeriod, oldGracePeriod_);
    }


/*
 * @title setPledgerWaitTimeBeforeGraceExit()
 *
 * @dev Sets the project pledger wait time between entering and being allowed to leave due to grace period
 * Note that this change will only affect _new projects
 *
 * @event: PledgerGraceExitWaitTimeChanged
 */
    function setPledgerWaitTimeBeforeGraceExit(uint newWaitTime) external onlyOwner { //@PUBFUNC
        // will pnly take effect on future projects
        uint oldWaitTime_ = pledgerGraceExitWaitTime;
        pledgerGraceExitWaitTime = newWaitTime;
        emit PledgerGraceExitWaitTimeChanged( pledgerGraceExitWaitTime, oldWaitTime_);
    }

     function numProjects() external view returns(uint) {
         return projectAddresses.length;
     }

    //------------


    function _getPlatformCutPromils() internal virtual view returns(uint);
    function _isAnApprovedVault(address vault) internal virtual view returns(bool);
}