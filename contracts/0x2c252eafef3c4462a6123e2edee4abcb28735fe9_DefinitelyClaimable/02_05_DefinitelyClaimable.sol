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
import {MerkleProof} from "openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IDefinitelyMemberships} from "./interfaces/IDefinitelyMemberships.sol";
import {IDelegationRegistry} from "./interfaces/IDelegationRegistry.sol";

/**
 * @title
 * Definitely Claimable
 *
 * @author
 * DEF DAO
 *
 * @notice
 * A membership issuing contract that uses EIP-712 signatures to allow membership claiming
 */
contract DefinitelyClaimable is Auth {
    /* ------------------------------------------------------------------------
       S T O R A G E    
    ------------------------------------------------------------------------ */

    /// @notice The main membership contract
    address public memberships;

    /// @notice The address of the delegate.cash delegation registry
    address public delegationRegistry = 0x00000000000076A84feF008CDAbe6409d2FE638B;

    /// @notice The merkle root used for claiming memberships
    bytes32 public claimableRoot;

    /* ------------------------------------------------------------------------
       E V E N T S    
    ------------------------------------------------------------------------ */

    /// @dev Whenever a membership is claimed for an existing DEF member
    event MembershipClaimed(address indexed member);

    /// @dev Whenever the claimable merkle root is updated
    event ClaimableRootUpdated(bytes32 indexed root);

    /// @dev Whenever the delegation registry address is updated
    event DelegationRegistryUpdated(address indexed registry);

    /* ------------------------------------------------------------------------
       E R R O R S    
    ------------------------------------------------------------------------ */

    error InvalidProof();
    error NotDelegatedToClaim();

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    /**
     * @param owner_ Contract owner address
     * @param memberships_ The main membership contract
     * @param initialRoot_ An initial merkle root for claiming memberships
     */
    constructor(
        address owner_,
        address memberships_,
        bytes32 initialRoot_
    ) Auth(owner_) {
        memberships = memberships_;
        claimableRoot = initialRoot_;
        emit ClaimableRootUpdated(initialRoot_);
    }

    /* ------------------------------------------------------------------------
       C L A I M I N G
    ------------------------------------------------------------------------ */

    /**
     * @notice
     * Allows someone to claim a DEF membership with a valid merkle proof
     *
     * @param proof A merkle proof for claiming
     */
    function claimMembership(bytes32[] calldata proof) external {
        if (!_verifyProof(msg.sender, proof)) revert InvalidProof();

        IDefinitelyMemberships(memberships).issueMembership(msg.sender);
        emit MembershipClaimed(msg.sender);
    }

    /**
     * @notice
     * Allows someone to claim a DEF membership with a valid merkle proof to a vault address
     * from delegate.cash.
     *
     * @dev
     * The caller must be a delegate of `vault` for the main membership contract. The vault
     * address should be in the proof, not the caller address.
     *
     * @param vault Cold wallet that delegated `msg.sender` on https://delegate.cash
     * @param proof A merkle proof for claiming
     */
    function claimMembership(address vault, bytes32[] calldata proof) external {
        if (
            !IDelegationRegistry(delegationRegistry).checkDelegateForContract(
                msg.sender,
                vault,
                memberships
            )
        ) revert NotDelegatedToClaim();
        if (!_verifyProof(vault, proof)) revert InvalidProof();

        IDefinitelyMemberships(memberships).issueMembership(vault);
        emit MembershipClaimed(vault);
    }

    /**
     * @notice
     * Checks if an account can claim a membership with a given proof
     *
     * @param account The account to check
     * @param proof The merkle proof to validate
     */
    function canClaimMembership(address account, bytes32[] calldata proof)
        external
        view
        returns (bool)
    {
        return _verifyProof(account, proof);
    }

    /**
     * @notice
     * Internal function to verify a merkle proof for claiming
     *
     * @param account The account to verify the proof for
     * @param proof The merkle proof to verify
     */
    function _verifyProof(address account, bytes32[] calldata proof) internal view returns (bool) {
        return MerkleProof.verify(proof, claimableRoot, keccak256(abi.encodePacked(account)));
    }

    /* ------------------------------------------------------------------------
       A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @notice
     * Admin function to set the claimable merkle root
     *
     * @dev
     * Emits the ClaimableRootUpdated event
     *
     * @param root The new claimable merkle root
     */
    function setClaimableRoot(bytes32 root) external onlyOwnerOrAdmin {
        claimableRoot = root;
        emit ClaimableRootUpdated(root);
    }

    /**
     * @notice
     * Admin function to set the delegate.cash registry address
     *
     * @dev
     * Emits the ClaimableRootUpdated event
     *
     * @param registry The new registry address
     */
    function setDelegationRegistry(address registry) external onlyOwnerOrAdmin {
        delegationRegistry = registry;
        emit DelegationRegistryUpdated(registry);
    }
}