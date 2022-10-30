// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


import "../@openzeppelin/contracts/security/Pausable.sol";
import "../@openzeppelin/contracts/access/Ownable.sol";
import "../@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "../@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./ProjectFactory.sol";
import "../milestone/Milestone.sol";
import "../vault/IVault.sol";
import "../project/IProject.sol";
import "./IPlatform.sol";


contract Platform is ProjectFactory, IPlatform, /*Ownable, Pausable,*/ ReentrancyGuard {
    
    using ERC165Checker for address;


    //TODO platform state vars, allow team / vault vetting

    uint constant public MAX_PLATFORM_CUT_PROMILS = 20; //TODO verify max cut value

    IERC20 public platformToken;

    uint public platformCutPromils = 6;

    mapping(address => uint) public numPaymentTokensByTokenAddress;



    //--------

    event PlatformFundTransferToOwner(address owner, uint toExtract);

    event TeamAddressApprovedStatusSet(address indexed teamWallet_, bool indexed approved_);

    event VaultAddressApprovedStatusSet(address indexed vaultAddress_, bool indexed approved_);

    event PlatformTokenChanged(address platformToken, address oldToken);

    event PlatformCutReceived(address indexed senderProject, uint value);

    event PlatformCutChanged(uint oldValPromils, uint platformCutPromils);

    error BadTeamDefinedVault(address projectVault_);

    error InsufficientFundsInContract( uint sumToExtract_, uint contractBalance );

    error InvalidProjectAddress(address projectAddress);
    //---------


    modifier openForAll() {
        _;
    }

    modifier onlyValidProject() {
        require( _validProjectAddress( msg.sender), "not a valid project");
        _;
    }

    constructor( address projectTemplate_, address vaultTemplate_, address platformToken_)
                            ProjectFactory( projectTemplate_, vaultTemplate_) {
         platformToken = IERC20(platformToken_);
     }

/*
 * @title setPlatformToken
 *
 * @dev Allows platform owner to set the platform erc20 token
 *
 * NOTE: As part of the processing _new erc20 project tokens will be minted and transferred to the owner and
 * @event: PlatformTokenChanged
 */
    function setPlatformToken(IERC20 newPlatformToken) external onlyOwner whenPaused { //@PUBFUNC
        // contract should be paused first
        IERC20 oldToken_ = platformToken;
        platformToken = newPlatformToken;
        emit PlatformTokenChanged(address(platformToken), address(oldToken_));
    }

/*
 * @title markVaultAsApproved
 *
 * @dev Set vault approval by platform to be used by future (only!) projects
 *
 * @event: VaultAddressApprovedStatusSet
 */
    function markVaultAsApproved(address vaultAddress_, bool isApproved_) external onlyOwner { //@PUBFUNC
        approvedVaults[vaultAddress_] = isApproved_;
        emit VaultAddressApprovedStatusSet(vaultAddress_, isApproved_);
    }

/*
 * @title transferFundsToPlatformOwner
 *
 * @dev Transfer payment-token funds from platform contract to platform owner
 *
 * @event: PlatformFundTransferToOwner
 */
    function transferFundsToPlatformOwner(uint sumToExtract_, address tokenAddress_) external onlyOwner { //@PUBFUNC
        // @PROTECT: DoS, Re-entry

        _transferPaymntTokensFromPlatformTo( owner(), sumToExtract_, tokenAddress_);
        
        emit PlatformFundTransferToOwner(owner(), sumToExtract_); 
    }

    function _transferPaymntTokensFromPlatformTo( address receiverAddr_, uint numPaymentTokens_, address tokenAddress_) private {
        require( numPaymentTokensByTokenAddress[ tokenAddress_] >= numPaymentTokens_, "not enough tokens in platform");

        numPaymentTokensByTokenAddress[ tokenAddress_] -= numPaymentTokens_;

        bool ok = IERC20( tokenAddress_).transfer( receiverAddr_, numPaymentTokens_);
        require( ok, "Failed to transfer payment tokens");
    }


    /*
     * @title setPlatformCut
     *
     * @dev Set platform cut (promils) after verifying it is <= MAX_PLATFORM_CUT_PROMILS
     *
     * @event: PlatformCutChanged
     */
    function setPlatformCut(uint newPlatformCutPromils) external onlyOwner { //@PUBFUNC
        require( newPlatformCutPromils <= MAX_PLATFORM_CUT_PROMILS, "bad platform cut");
        uint oldVal_ = platformCutPromils;
        platformCutPromils = newPlatformCutPromils;
        emit PlatformCutChanged( oldVal_, platformCutPromils);
    }

    /*
     * @title receive()
     *
     * @dev Allow a valid project (only) to pass payment-token to platform contract
     *
     * @event: PlatformCutReceived
     */
    function onReceivePaymentTokens( address tokenAddress_, uint numTokensToPlatform_) external override onlyValidProject { //@PUBFUNC //@PTokTransfer
        numPaymentTokensByTokenAddress[ tokenAddress_] += numTokensToPlatform_;
        emit PlatformCutReceived( msg.sender, numTokensToPlatform_);
    }

    function getBlockTimestamp() external view returns(uint) {
        return block.timestamp;
    }

    function _getPlatformCutPromils() internal override view returns(uint) {
        return platformCutPromils;
    } 

    function _isAnApprovedVault(address projectVault_) internal override view returns(bool) {
        return approvedVaults[address(projectVault_)];
    }

}