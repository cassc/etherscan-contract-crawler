// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ICollectionHolderMint} from "../interfaces/ICollectionHolderMint.sol";
import {ICre8ors} from "../interfaces/ICre8ors.sol";
import {IERC721A} from "lib/ERC721A/contracts/interfaces/IERC721A.sol";
import {IERC721Drop} from "../interfaces/IERC721Drop.sol";
import {IFriendsAndFamilyMinter} from "../interfaces/IFriendsAndFamilyMinter.sol";
import {IMinterUtilities} from "../interfaces/IMinterUtilities.sol";
import {IERC721ACH} from "ERC721H/interfaces/IERC721ACH.sol";

contract CollectionHolderMint is ICollectionHolderMint {
    ///@notice Mapping to track whether a specific uint256 value (token ID) has been claimed or not.
    mapping(uint256 => bool) public freeMintClaimed;

    ///@notice The address of the collection contract that mints and manages the tokens.
    address public cre8orsNFTContractAddress;

    ///@notice The address of the passport contract.
    address public passportContractAddress;

    ///@notice The address of the minter utility contract that contains shared utility info.
    address public minterUtilityContractAddress;

    ///@notice The address of the friends and family minter contract.
    address public friendsAndFamilyMinterContractAddress;

    ///@notice mapping of address to quantity of free mints claimed.
    mapping(address => uint256) public totalClaimed;

    /**
     * @notice Constructs a new CollectionHolderMint contract.
     * @param _cre8orsNFTContractAddress The address of the collection contract that mints and manages the tokens.
     * @param _passportContractAddress The address of the passport contract.
     * @param _minterUtility The address of the minter utility contract that contains shared utility info.
     * @param _friendsAndFamilyMinterContractAddress The address of the friends and family minter contract.
     */
    constructor(
        address _cre8orsNFTContractAddress,
        address _passportContractAddress,
        address _minterUtility,
        address _friendsAndFamilyMinterContractAddress
    ) {
        cre8orsNFTContractAddress = _cre8orsNFTContractAddress;
        passportContractAddress = _passportContractAddress;
        minterUtilityContractAddress = _minterUtility;
        friendsAndFamilyMinterContractAddress = _friendsAndFamilyMinterContractAddress;
    }

    /**
     * @dev Mint function to create a new token, assign it to the specified recipient, and trigger additional actions.
     *
     * This function creates a new token with the given `tokenId` and assigns it to the `recipient` address.
     * It requires the `tokenId` to be eligible for a free mint, and the caller must be the owner of the specified `tokenId`
     * to successfully execute the minting process.
     *
     * @param passportTokenIDs The IDs of passports.
     * @param recipient The address to whom the newly minted token will be assigned.
     * @return pfpTokenId The ID of the corresponding PFP token that was minted for the `recipient`.
     *
     */
    function mint(
        uint256[] calldata passportTokenIDs,
        address recipient
    )
        external
        tokensPresentInList(passportTokenIDs)
        noDuplicates(passportTokenIDs)
        onlyTokenOwner(passportTokenIDs, recipient)
        hasFreeMint(passportTokenIDs)
        returns (uint256)
    {
        _friendsAndFamilyMint(recipient);

        return _passportMint(passportTokenIDs, recipient);
    }

    /**
     * @notice Toggle the free mint claim status of a token.
     * @param tokenId Passport token ID to toggle free mint claim status.
     */
    function toggleHasClaimedFreeMint(uint256 tokenId) external onlyAdmin {
        freeMintClaimed[tokenId] = !freeMintClaimed[tokenId];
    }

    ////////////////////////////////////////
    ////////////// MODIFIERS //////////////
    ///////////////////////////////////////

    /**
     * @dev Modifier to ensure the caller owns the specified tokens or has appropriate approval.
     * @param passportTokenIDs An array of token IDs.
     * @param recipient The recipient address.
     */
    modifier onlyTokenOwner(
        uint256[] calldata passportTokenIDs,
        address recipient
    ) {
        for (uint256 i = 0; i < passportTokenIDs.length; i++) {
            if (
                IERC721A(passportContractAddress).ownerOf(
                    passportTokenIDs[i]
                ) != recipient
            ) {
                revert IERC721A.ApprovalCallerNotOwnerNorApproved();
            }
        }
        _;
    }

    /**
     * @dev Modifier to ensure the caller is an admin.
     */
    modifier onlyAdmin() {
        if (!ICre8ors(cre8orsNFTContractAddress).isAdmin(msg.sender)) {
            revert IERC721Drop.Access_OnlyAdmin();
        }

        _;
    }

    /**
     * @dev Modifier to ensure the specified token IDs are not duplicates.
     */
    modifier noDuplicates(uint[] calldata _passportpassportTokenIDs) {
        if (_hasDuplicates(_passportpassportTokenIDs)) {
            revert DuplicatesFound();
        }
        _;
    }
    /**
     * @dev Modifier to ensure the specified token IDs are eligible for a free mint.
     * @param passportTokenIDs An array of token IDs.
     */
    modifier hasFreeMint(uint256[] calldata passportTokenIDs) {
        for (uint256 i = 0; i < passportTokenIDs.length; i++) {
            if (freeMintClaimed[passportTokenIDs[i]]) {
                revert AlreadyClaimedFreeMint();
            }
        }
        _;
    }

    /**
     * @dev Modifier to ensure the specified token ID list is not empty.
     * @param passportTokenIDs An array of token IDs.
     */
    modifier tokensPresentInList(uint256[] calldata passportTokenIDs) {
        if (passportTokenIDs.length == 0) {
            revert NoTokensProvided();
        }
        _;
    }

    ///////////////////////////////////////
    ////////// SETTER FUNCTIONS //////////
    /////////////////////////////////////
    /**
     * @notice Set New Minter Utility Contract Address
     * @notice Allows the admin to set a new address for the Minter Utility Contract.
     * @param _newMinterUtilityContractAddress The address of the new Minter Utility Contract.
     * @dev Only the admin can call this function.
     */
    function setNewMinterUtilityContractAddress(
        address _newMinterUtilityContractAddress
    ) external onlyAdmin {
        minterUtilityContractAddress = _newMinterUtilityContractAddress;
    }

    /**
     * @notice Set the address of the friends and family minter contract.
     * @param _newfriendsAndFamilyMinterContractAddressAddress The address of the new friends and family minter contract.
     */
    function setFriendsAndFamilyMinterContractAddress(
        address _newfriendsAndFamilyMinterContractAddressAddress
    ) external onlyAdmin {
        friendsAndFamilyMinterContractAddress = _newfriendsAndFamilyMinterContractAddressAddress;
    }

    /**
     * @notice Updates the passport contract address.
     * @dev This function can only be called by the admin.
     * @param _newPassportContractAddress The new passport contract address.
     */
    function setNewPassportContractAddress(
        address _newPassportContractAddress
    ) external onlyAdmin {
        passportContractAddress = _newPassportContractAddress;
    }

    /**
     * @notice Updates the Cre8ors NFT contract address.
     * @dev This function can only be called by the admin.
     * @param _newCre8orsNFTContractAddress The new Cre8ors NFT contract address.
     */
    function setNewCre8orsNFTContractAddress(
        address _newCre8orsNFTContractAddress
    ) external onlyAdmin {
        cre8orsNFTContractAddress = _newCre8orsNFTContractAddress;
    }

    ////////////////////////////////////////
    ////////// INTERNALFUNCTIONS //////////
    ///////////////////////////////////////

    function _setpassportTokenIDsToClaimed(
        uint256[] calldata passportTokenIDs
    ) internal {
        for (uint256 i = 0; i < passportTokenIDs.length; i++) {
            freeMintClaimed[passportTokenIDs[i]] = true;
        }
    }

    function _lockAndStakeTokens(uint256[] memory _mintedPFPTokenIDs) internal {
        IMinterUtilities minterUtility = IMinterUtilities(
            minterUtilityContractAddress
        );
        uint256 lockupDate = block.timestamp + 8 weeks;
        uint256 unlockPrice = minterUtility.getTierInfo(3).price;
        bytes memory data = abi.encode(lockupDate, unlockPrice);
        ICre8ors(
            IERC721ACH(cre8orsNFTContractAddress).getHook(
                IERC721ACH.HookType.BeforeTokenTransfers
            )
        ).cre8ing().inializeStakingAndLockup(
                cre8orsNFTContractAddress,
                _mintedPFPTokenIDs,
                data
            );
    }

    function _passportMint(
        uint256[] calldata _passportTokenIDs,
        address recipient
    ) internal returns (uint256) {
        uint256 pfpTokenId = ICre8ors(cre8orsNFTContractAddress).adminMint(
            recipient,
            _passportTokenIDs.length
        );
        uint256[] memory _pfpTokenIds = new uint256[](_passportTokenIDs.length);
        uint256 startingTokenId = pfpTokenId - _passportTokenIDs.length + 1;
        for (uint256 i = 0; i < _passportTokenIDs.length; ) {
            _pfpTokenIds[i] = startingTokenId + i;
            unchecked {
                i++;
            }
        }
        totalClaimed[recipient] += _passportTokenIDs.length;
        _lockAndStakeTokens(_pfpTokenIds);
        _setpassportTokenIDsToClaimed(_passportTokenIDs);
        return pfpTokenId;
    }

    function _friendsAndFamilyMint(address buyer) internal {
        IFriendsAndFamilyMinter ffMinter = IFriendsAndFamilyMinter(
            friendsAndFamilyMinterContractAddress
        );

        if (ffMinter.hasDiscount(buyer)) {
            ffMinter.mint(buyer);
        }
    }

    function _hasDuplicates(
        uint[] calldata values
    ) internal pure returns (bool) {
        for (uint i = 0; i < values.length; i++) {
            for (uint j = i + 1; j < values.length; j++) {
                if (values[i] == values[j]) {
                    return true;
                }
            }
        }
        return false;
    }
}