// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
 * @title HydraDistributor
 * @notice Hydra is the 7th tribe of NiftyDegen.
 */
contract HydraDistributor is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC721HolderUpgradeable
{
    /// @dev NiftyDegen NFT address
    IERC721Upgradeable public niftyDegen;

    /// @dev Hydra Token Id list
    uint256[] public hydraTokenIds;

    /// @dev NiftyLeague Wallet Address
    address public niftyWallet;

    /// @dev Random Hash Value
    bytes32 internal _prevHash;

    event NiftyDegenSet(address indexed niftyDegen);
    event NiftyWalletSet(address indexed niftyWallet);
    event HydraClaimed(address indexed user, uint256[] tokenIdsBurned, uint256 hydraTokenId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _niftyDegen, address _niftyWallet) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        require(_niftyDegen != address(0), "Zero address");
        require(_niftyWallet != address(0), "Zero address");

        niftyDegen = IERC721Upgradeable(_niftyDegen);
        niftyWallet = _niftyWallet;
    }

    /**
     * @notice Update the NiftyDegen NFT address
     * @param _niftyDegen NiftyDegen NFT address
     */
    function updateNiftyDegen(address _niftyDegen) external onlyOwner {
        require(_niftyDegen != address(0), "Zero address");

        niftyDegen = IERC721Upgradeable(_niftyDegen);

        emit NiftyDegenSet(_niftyDegen);
    }

    /**
     * @notice Update the NiftyLeague wallet address
     * @param _niftyWallet NiftyLeague wallet address
     */
    function updateNiftyWallet(address _niftyWallet) external onlyOwner {
        require(_niftyWallet != address(0), "Zero address");

        niftyWallet = _niftyWallet;

        emit NiftyWalletSet(_niftyWallet);
    }

    /**
     * @notice Deposit the Hydra
     * @param _hydraTokenIdList Token Ids of the Hydra to deposit
     */
    function depositHydra(uint256[] calldata _hydraTokenIdList) external onlyOwner {
        for (uint256 i = 0; i < _hydraTokenIdList.length; ) {
            uint256 tokenId = _hydraTokenIdList[i];

            hydraTokenIds.push(tokenId);

            unchecked {
                ++i;
            }
        }

        for (uint256 i = 0; i < _hydraTokenIdList.length; ) {
            uint256 tokenId = _hydraTokenIdList[i];

            niftyDegen.safeTransferFrom(msg.sender, address(this), tokenId, bytes(""));

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Claim the random Hydra
     * @dev The users must transfer 8 normal degens to claim 1 random Hydra
     * @dev NiftyWallet must transfer 12 normal degens to claim 1 random Hydra
     * @dev All the trasnferred the normal degens are burned
     * @param _degenTokenIdList Token Ids of the normal degens to burn
     */
    function claimRandomHydra(uint256[] calldata _degenTokenIdList) external nonReentrant whenNotPaused {
        uint256 degenCountToBurn = _degenTokenIdList.length;

        if (msg.sender == niftyWallet) {
            require(degenCountToBurn == 12, "Need 12 degens");
        } else {
            require(degenCountToBurn == 8, "Need 8 degens");
        }

        // get the random Hydra tokenId
        uint256 randomValue = 1;
        for (uint256 i = 0; i < degenCountToBurn; ) {
            unchecked {
                randomValue *= _degenTokenIdList[i]; // generate the random value, ignore overflow
                ++i;
            }
        }

        bytes32 randomHash = keccak256(
            abi.encodePacked(_prevHash, randomValue, msg.sender, block.timestamp, block.difficulty)
        );
        uint256 hydraCount = hydraTokenIds.length;
        uint256 hydraIndex = uint256(randomHash) % hydraCount;
        uint256 hydraTokenId = hydraTokenIds[hydraIndex];

        // remove the claimed rare degen Id from the list
        hydraTokenIds[hydraIndex] = hydraTokenIds[hydraCount - 1];
        hydraTokenIds.pop();

        // set the prevHash
        _prevHash = randomHash;

        // burn user's degens
        for (uint256 i = 0; i < degenCountToBurn; ) {
            niftyDegen.safeTransferFrom(msg.sender, address(1), _degenTokenIdList[i], bytes(""));

            unchecked {
                ++i;
            }
        }

        emit HydraClaimed(msg.sender, _degenTokenIdList, hydraTokenId);

        // transfer the random Hydra to the user
        niftyDegen.safeTransferFrom(address(this), msg.sender, hydraTokenId, bytes(""));
    }

    /**
     * @notice Returns the number of the Hydra in the contract
     * @return hydraCount Number of Hydra in the contract
     */
    function getHydraCount() external view returns (uint256 hydraCount) {
        hydraCount = hydraTokenIds.length;
    }

    /**
     * @notice Withdraw all Hydra
     * @param _to Address to receive the Hydra
     */
    function withdrawAllHydra(address _to) external onlyOwner {
        for (uint256 i = 0; i < hydraTokenIds.length; ) {
            uint256 tokenId = hydraTokenIds[i];

            niftyDegen.safeTransferFrom(address(this), _to, tokenId, bytes(""));

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function getHydraTokenIds() external view returns (uint256[] memory) {
        return hydraTokenIds;
    }
}