// SPDX-License-Identifier: UNLICENSED
//
//         ,----,
//       ,/   .`|       ,--,                            ____      ,----..                       ,----,
//     ,`   .'  :     ,--.'|    ,---,.                ,'  , `.   /   /   \      ,---,         .'   .`|
//   ;    ;     /  ,--,  | :  ,'  .' |             ,-+-,.' _ |  /   .     :   .'  .' `\    .'   .'   ;
// .'___,/    ,',---.'|  : ',---.'   |          ,-+-. ;   , || .   /   ;.  \,---.'     \ ,---, '    .'
// |    :     | |   | : _' ||   |   .'         ,--.'|'   |  ;|.   ;   /  ` ;|   |  .`\  ||   :     ./
// ;    |.';  ; :   : |.'  |:   :  |-,        |   |  ,', |  ':;   |  ; \ ; |:   : |  '  |;   | .'  /
// `----'  |  | |   ' '  ; ::   |  ;/|        |   | /  | |  |||   :  | ; | '|   ' '  ;  :`---' /  ;
//     '   :  ; '   |  .'. ||   :   .'        '   | :  | :  |,.   |  ' ' ' :'   | ;  .  |  /  ;  /
//     |   |  ' |   | :  | '|   |  |-,        ;   . |  ; |--' '   ;  \; /  ||   | :  |  ' ;  /  /--,
//     '   :  | '   : |  : ;'   :  ;/|        |   : |  | ,     \   \  ',  / '   : | /  ; /  /  / .`|
//     ;   |.'  |   | '  ,/ |   |    \        |   : '  |/       ;   :    /  |   | '` ,/./__;       :
//     '---'    ;   : ;--'  |   :   .'        ;   | |`-'         \   \ .'   ;   :  .'  |   :     .'
//              |   ,/      |   | ,'          |   ;/              `---`     |   ,.'    ;   |  .'
//              '---'       `----'            '---'                         '---'      `---'
//
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./ModzKidsWearables.sol";

contract ModzKidsWearablesFungibleClaim is
    Pausable,
    AccessControl,
    ReentrancyGuard
{
    ModzKidsWearables wearables;

    bytes32 public merkleRoot;

    mapping(address => bool) public alreadyClaimed;

    bool public claimActive = false;
    bool public claimEnded = false;

    constructor(address _wearablesContract, bytes32 _merkleRoot) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        wearables = ModzKidsWearables(_wearablesContract);
        merkleRoot = _merkleRoot;
    }

    function setMerkleRoot(bytes32 _newMerkleRoot)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        merkleRoot = _newMerkleRoot;
    }

    function toggleClaimActive() external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimActive = !claimActive;
    }

    function toggleClaimEnded() external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimEnded = !claimEnded;
        claimActive = false;
    }

    function claim(
        uint256 tier1,
        uint256 tier2,
        uint256 tier3,
        uint256 tier4,
        bytes32[] calldata merkleProof
    ) external nonReentrant {
        require(!claimEnded, "Claim has ended");
        require(claimActive, "Claim is not active");
        require(!alreadyClaimed[msg.sender], "Already claimed");

        bytes32 node = keccak256(
            abi.encodePacked(msg.sender, tier1, tier2, tier3, tier4)
        );

        bool isValidProof = MerkleProof.verifyCalldata(
            merkleProof,
            merkleRoot,
            node
        );

        require(isValidProof, "Invalid proof.");
        alreadyClaimed[msg.sender] = true;
        
        if (tier1 != 0) {
            wearables.mint(msg.sender, tier1, 1);
        }
        if (tier2 != 0) {
            wearables.mint(msg.sender, tier2, 1);
        }
        if (tier3 != 0) {
            wearables.mint(msg.sender, tier3, 1);
        }
        if (tier4 != 0) {
            wearables.mint(msg.sender, tier4, 1);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}