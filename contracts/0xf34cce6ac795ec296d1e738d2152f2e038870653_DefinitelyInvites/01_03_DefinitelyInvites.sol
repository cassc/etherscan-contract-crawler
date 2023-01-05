//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/**
                                                      ...:--==***#@%%-
                                             ..:  -*@@@@@@@@@@@@@#*:  
                               -:::-=+*#%@@@@@@*[email protected]@@@@@@@@@@#+=:     
           .::---:.         +#@@@@@@@@@@@@@%*+-. [email protected]@@@@@+..           
    .-+*%@@@@@@@@@@@#-     [email protected]@@@@@@@@@%#*=:.    :@@@@@@@#%@@@@@%:     
 =#@@@@@@@@@@@@@@@@@@@%.   %@@@@@@-..           *@@@@@@@@@@@@%*.      
[email protected]@@@@@@@@#*+=--=#@@@@@%  [email protected]@@@@@%*#%@@@%*=-.. [email protected]@@@@@@%%*+=:         
 :*@@@@@@*       [email protected]@@@@@.*@@@@@@@@@@@@*+-      =%@@@@%                
  [email protected]@@@@@.       *@@@@@%:@@@@@@*==-:.          [email protected]@@@@:                
 [email protected]@@@@@=      [email protected]@@@@@%.*@@@@@=   ..::--=+*=+*[email protected]@@@=                 
 #@@@@@*    [email protected]@@@@@@* [email protected]@@@@#%%@@@@@@@@#+:.  =#@@=                  
 @@@@@%   :*@@@@@@@*:  .#@@@@@@@@@@@@@%#:       ---                   
:@@@@%. -%@@@@@@@+.     [email protected]@@@@%#*+=:.                                 
[email protected]@@%=*@@@@@@@*:        =*:                                           
:*#+%@@@@%*=.                                                         
 :+##*=:.

*/

import {Auth} from "./lib/Auth.sol";
import {IDefinitelyMemberships} from "./interfaces/IDefinitelyMemberships.sol";

/**
 * @title
 * Definitely Invites
 *
 * @author
 * DEF DAO
 *
 * @notice
 * A membership issuing contract that uses an invites mechanism so that existing
 * DEF members can invite new people to DEF. It uses a cooldown system so invites can't be
 * spammed over and over.
 */
contract DefinitelyInvites is Auth {
    /* ------------------------------------------------------------------------
       S T O R A G E    
    ------------------------------------------------------------------------ */

    /// @notice The main membership contract
    address public memberships;

    /// @notice The invite cooldown period in seconds
    uint256 public inviteCooldown;

    /// @notice The time a member last invited someone
    mapping(address => uint256) public memberLastSentInvite;

    /// @notice If a non member has an invite they can claim
    mapping(address => bool) public inviteAvailable;

    /* ------------------------------------------------------------------------
       E V E N T S    
    ------------------------------------------------------------------------ */

    /// @dev Emitted when the invite cooldown is updated
    event InviteCooldownUpdated(uint256 indexed cooldown);

    /// @dev Emitted when an invite is sent immediately, or when a claimable invite is created
    event MemberInvited(address indexed invited, address indexed invitedBy);

    /// @dev Emitted when a claimable invite is claimed
    event InviteClaimed(address indexed invited);

    /* ------------------------------------------------------------------------
       E R R O R S    
    ------------------------------------------------------------------------ */

    error InviteOnCooldown();
    error NoInviteToClaim();
    error NotDefMember();
    error AlreadyDefMember();

    /* ------------------------------------------------------------------------
       M O D I F I E R S    
    ------------------------------------------------------------------------ */

    /// @dev Reverts if an invite is currently on cooldown
    modifier whenInviteNotOnCooldown() {
        if (memberLastSentInvite[msg.sender] + inviteCooldown > block.timestamp) {
            revert InviteOnCooldown();
        }
        _;
    }

    /// @dev Reverts if there is no invite to claim for the sender
    modifier whileInviteAvailable() {
        if (!inviteAvailable[msg.sender]) revert NoInviteToClaim();
        _;
    }

    /// @dev Reverts if `account` is not a member
    modifier whileDefMember(address account) {
        if (!IDefinitelyMemberships(memberships).isDefMember(account)) revert NotDefMember();
        _;
    }

    /// @dev Reverts if `account` is already a member
    modifier whileNotDefMember(address account) {
        if (IDefinitelyMemberships(memberships).isDefMember(account)) revert AlreadyDefMember();
        _;
    }

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    /**
     * @param owner_ Contract owner address
     * @param memberships_ The main membership contract
     * @param inviteCooldown_ Invite cooldown in seconds
     */
    constructor(
        address owner_,
        address memberships_,
        uint256 inviteCooldown_
    ) Auth(owner_) {
        memberships = memberships_;
        inviteCooldown = inviteCooldown_;
        emit InviteCooldownUpdated(inviteCooldown_);
    }

    /* ------------------------------------------------------------------------
       S E N D I N G   I N V I T E S    
    ------------------------------------------------------------------------ */

    /**
     * @notice
     * Create an invite to an address that can be claimed at a later time
     *
     * @dev
     * Reverts if:
     *   - `msg.sender` is not a DEF member
     *   - `to` is already a DEF member
     *   - `msg.sender` is not on cooldown for invites
     *
     * @param to The address to create an invite for
     */
    function sendClaimableInvite(address to)
        external
        whileDefMember(msg.sender)
        whileNotDefMember(to)
        whenInviteNotOnCooldown
    {
        inviteAvailable[to] = true;
        _startInviteCooldown(msg.sender);

        emit MemberInvited(to, msg.sender);
    }

    /**
     * @notice
     * Send an membership token directly to an address, skipping the claim step
     *
     * @dev
     * Reverts if:
     *   - `msg.sender` is not a DEF member
     *   - `to` is already a DEF member
     *   - `msg.sender` is not on cooldown for invites
     *
     * @param to The address to send the membership NFT to
     */
    function sendImmediateInvite(address to)
        external
        whileDefMember(msg.sender)
        whileNotDefMember(to)
        whenInviteNotOnCooldown
    {
        _startInviteCooldown(msg.sender);

        IDefinitelyMemberships(memberships).issueMembership(to);
        emit MemberInvited(to, msg.sender);
    }

    /**
     * @dev
     * Starts the invite cooldown for an address
     *
     * @param inviter The account to put on invite cooldown
     */
    function _startInviteCooldown(address inviter) internal {
        memberLastSentInvite[inviter] = block.timestamp;
    }

    /* ------------------------------------------------------------------------
       C L A I M I N G   I N V I T E S
    ------------------------------------------------------------------------ */

    /**
     * @notice
     * Allows someone to claim their invite if they have one available
     *
     * @dev
     * Reverts if:
     *   - `msg.sender` doesn't have an invite available
     *   - `msg.sender` is already a DEF member
     */
    function claimInvite() external whileInviteAvailable {
        // We don't really need to remove the available invite, but it's nice to clean up
        inviteAvailable[msg.sender] = false;

        IDefinitelyMemberships(memberships).issueMembership(msg.sender);
        emit InviteClaimed(msg.sender);
    }

    /* ------------------------------------------------------------------------
       A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @notice
     * Admin function to update the invite cooldown timer
     *
     * @param cooldown The cooldown time in seconds
     */
    function setInviteCooldown(uint256 cooldown) external onlyOwnerOrAdmin {
        inviteCooldown = cooldown;
        emit InviteCooldownUpdated(cooldown);
    }
}