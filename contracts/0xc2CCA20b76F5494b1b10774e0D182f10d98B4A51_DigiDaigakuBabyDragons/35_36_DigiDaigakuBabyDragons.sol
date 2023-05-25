// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@limit-break/presets/BlacklistedTransferWrapperAdventureNFT.sol";
import "./IBurnableToken.sol";

/**
 * @title DigiDaigakuBabyDragons
 * @author Limit Break, Inc.
 */
contract DigiDaigakuBabyDragons is BlacklistedTransferWrapperAdventureNFT {
    error DigiDaigakuBabyDragons__CallerNotOwnerOfDragonEgg();
    error DigiDaigakuBabyDragons__CannotSetDragonEggsToZeroAddress();
    error DigiDaigakuBabyDragons__MustProvideAtLeastOneTokenId();
    error DigiDaigakuBabyDragons__StakeDoesNotAcceptPayment();

    constructor(address dragonEggAddress, address royaltyReceiver_, uint96 royaltyFeeNumerator_) ERC721("", "") {
        if (dragonEggAddress == address(0)) {
            revert DigiDaigakuBabyDragons__CannotSetDragonEggsToZeroAddress();
        }
        initializeERC721("DigiDaigakuBabyDragons", "DIBD");
        initializeURI("https://digidaigaku.com/baby-dragons/metadata/", ".json");
        initializeAdventureERC721(100);
        initializeRoyalties(royaltyReceiver_, royaltyFeeNumerator_);
        initializeOperatorFilterer(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), true);
        initializeWrapperERC721(dragonEggAddress);
    }

    /**
     * @notice Stakes multiple Dragon Eggs to mint Baby Dragons
     *
     * @dev    Throws if you do not provide at least one token ID
     * @dev    Throws if the caller is not the owner of the token ID
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. `quantity` Baby Dragons are minted to the caller where `quantity` is the length of the token ID array
     * @dev    2. `quantity` Staked events are emitted, where `quantity` is the length of the token ID array
     * @dev    3. The Dragon Eggs with the provided token IDs are burnt
     */
    function stakeBatch(uint256[] calldata tokenIds) external payable {
        address dragonEggsAddress = getWrappedCollectionAddress();

        if (tokenIds.length == 0) {
            revert DigiDaigakuBabyDragons__MustProvideAtLeastOneTokenId();
        }

        for (uint256 i = 0; i < tokenIds.length;) {
            _stakeSingle(tokenIds[i], dragonEggsAddress);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Stakes a single Dragon Egg to mint a Baby Dragon
     *
     * @dev    Throws if the caller is not the owner of the token ID
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. A Baby Dragon is minted to the caller
     * @dev    2. A Staked events is emitted
     * @dev    3. The Dragon Eggs with the provided token ID is burnt
     */
    function stake(uint256 tokenId) public payable virtual override {
        _stakeSingle(tokenId, getWrappedCollectionAddress());
    }

    /// @dev Internal function to process staking
    function _stakeSingle(uint256 tokenId, address dragonEggsAddress) internal {
        address tokenOwner = IERC721(dragonEggsAddress).ownerOf(tokenId);

        if (tokenOwner != _msgSender()) {
            revert DigiDaigakuBabyDragons__CallerNotOwnerOfDragonEgg();
        }

        _onStake(tokenId, msg.value);

        emit Staked(tokenId, tokenOwner);

        _mint(tokenOwner, tokenId);
        IBurnableToken(dragonEggsAddress).burn(tokenId);
    }
}