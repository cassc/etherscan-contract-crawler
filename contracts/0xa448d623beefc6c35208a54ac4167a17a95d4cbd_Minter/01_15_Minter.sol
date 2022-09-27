// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "./base/Utils.sol";
import "./interfaces/IExplicitTokenIdNFT.sol";
import "../contracts-generated/Versioned.sol";

/**
 * @dev The minter contract is currently responsible for airdropping NFTs to players
 */
contract Minter is PausableUpgradeable, 
                   AccessControlUpgradeable, 
                   ReentrancyGuardUpgradeable,
                   Versioned 
{
    uint256[1000] private _gap_;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    uint256 public constant AIRDROP_ID_MULTIPLIER = 10000000000;

    /**
     * @dev Emitted when `info` is added to the stages array at `index`
     */
    event NFTAirDropped(uint256 indexed airDropId, uint256 mintedTokenId, 
                        uint256 indexed genesisTokenId, address indexed recipient,
                        IExplicitTokenIdNFT nftContract, string details);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}
    
    /**
     * @dev Initialize the minter contract
     * `admin` receives {DEFAULT_ADMIN_ROLE} and {PAUSER_ROLE}, assumes msg.sender if not specified.
     */
    function initialize(address admin) 
        virtual
        initializer 
        public 
    {
        require(Utils.isKnownNetwork(), "unknown network");
        __Pausable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();

        if (admin == address(0)) {
            admin = _msgSender();
        }

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
    }

    /**
     * @dev Pause the contract, requires `PAUSER_ROLE`
     */
    function pause() 
        public 
        onlyRole(PAUSER_ROLE) 
    {
        _pause();
    }

    /**
     * @dev Unpause the contract, requires `PAUSER_ROLE`
     */
    function unpause() 
        public 
        onlyRole(PAUSER_ROLE) 
    {
        _unpause();
    }

    /**
     * @dev Encode the AirDrop Id and genesis token Id into the same unique Id
     */
    function encodeTokenId(uint256 airDropId, uint256 genesisTokenId)
        public
        pure
        returns (uint256) 
    {
        // require(genesisTokenId < AIRDROP_ID_MULTIPLIER);
        return airDropId * AIRDROP_ID_MULTIPLIER + genesisTokenId;
    }

    /**
     * @dev AirDrop/Mint tokens from 'nftContract' to 'accounts' based on the 'genesisTokenIDs'
     * Note that we do NOT (by design) verify that 'accounts' own 'genesisTokenIDs' in 'nftContract' as the drop 
     * may be using a snapshot from before that's no longer verifiable on-chain.
     * We only require 'accounts' to be non-zero and can receive ERC721 tokens (when 'useSafeMint' is set).
     *
     * The same genesis token cannot be used to drop again with the same AirDrop Id, this is gauranteed by the uniqueness of the encoded dropped token Id.
     * User cares about the details of the drop should list to the 'NFTAirDropped' event since it has more info than the standard NFT mint event.
     *
     * This function requires 'DEFAULT_ADMIN_ROLE' from the caller, it also requires this contract to have the 'MINTER_ROLE' in the NFT contract.
     *
     * When 'useSafeMint' is unset, the mint skips the ERC721Receiver check, which makes it slighly cheaper to run.
     * In this case the user is responsible for running the check off-chain.
     */
    function adminAirDropNFT(uint256 airDropId, IExplicitTokenIdNFT nftContract, 
                             uint256[] calldata genesisTokenIDs, address[] calldata accounts, 
                             bool useSafeMint, string calldata details)
        external
        onlyRole(DEFAULT_ADMIN_ROLE) 
        whenNotPaused 
    {
        require(address(nftContract) != address(0), "bad NFT contract");
        require(genesisTokenIDs.length == accounts.length, "mismatched length");
        require(airDropId > 0, "expect positive airDropId");        
        for (uint256 index = 0; index < genesisTokenIDs.length; index++) {
            uint256 encodedTokenId = encodeTokenId(airDropId, genesisTokenIDs[index]);
            nftContract.mintWithTokenId(accounts[index], encodedTokenId, useSafeMint);
            emit NFTAirDropped(airDropId, encodedTokenId, genesisTokenIDs[index], accounts[index], nftContract, details);
        }
    }
}