//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ERC165, IERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {ITPLRevealedParts} from "../TPLRevealedParts/ITPLRevealedParts.sol";

/// @title TPLMechCrafter
/// @author CyberBrokers
/// @author dev by @dievardump
/// @notice Contract containing the Mech Crafting logic: use 6 parts + one afterglow to get a mech!
contract TPLMechCrafter is Ownable {
    error UserNotPartsOwner();
    error InvalidBodyPart();
    error InvalidPartsAmount();
    error InvalidModelAmount();
    error DelegationInactive();
    error NotAuthorized();
    error InvalidFees();

    error ErrorWithdrawing();
    error NothingToWithdraw();

    error ErrorDisassemblyFeePayment();

    error CraftingDisabled();
    error InvalidLength();

    /// @notice Emitted when a mech is assembled
    /// @param id the mech id
    /// @param partsIds the parts (body parts, afterglow) bitpacked
    /// @param extraData extra data used when crafting
    event MechAssembly(uint256 indexed id, uint256 partsIds, uint256 extraData);

    address public immutable TPL_REVEALED;
    address public immutable TPL_AFTERGLOW;
    address public immutable TPL_MECH;
    address public immutable TPL_PARTS_ESCROW;
    address public immutable DELEGATE_REGISTRY;

    uint256 public disassemblyFee;

    address public disassemblyFeeRecipient;

    bool public delegationActive;

    bool public craftingPublic;

    mapping(address => bool) public allowedCrafters;

    /// @notice Mech IDs linked to Engine ID; Once an engine is used, it will always mint the same Mech ID
    mapping(uint256 => uint256) public engineIds;

    modifier craftingAllowed() {
        if (!craftingPublic) {
            if (!allowedCrafters[msg.sender]) {
                revert CraftingDisabled();
            }
        }
        _;
    }

    constructor(
        address tplRevealed,
        address tplAfterglow,
        address tplMech,
        address tplPartsEscrow,
        address delegateRegistry,
        address disassemblyFeeRecipient_,
        uint256 disassemblyFee_
    ) {
        TPL_REVEALED = tplRevealed;
        TPL_AFTERGLOW = tplAfterglow;
        TPL_MECH = tplMech;
        TPL_PARTS_ESCROW = tplPartsEscrow;

        DELEGATE_REGISTRY = delegateRegistry;

        disassemblyFeeRecipient = disassemblyFeeRecipient_;
        disassemblyFee = disassemblyFee_;
    }

    /// @notice function allowing to parse the ExtraData sent with the mech build
    /// @param extraData the extra data
    /// @return seed the seed used for the name
    /// @return colors the colors used for the parts
    /// @return colorsActive the colors used for the parts
    /// @return emissive whether emissive is topToBottom or bottomToTop
    function parseExtraData(
        uint256 extraData
    ) external pure returns (uint256 seed, uint256[] memory colors, bool[] memory colorsActive, bool emissive) {
        seed = extraData & 0xffffff;
        extraData = extraData >> 24;

        colors = new uint256[](5);
        for (uint256 i; i < 5; i++) {
            colors[i] = extraData & 0xffffff;
            extraData = extraData >> 24;
        }

        colorsActive = new bool[](5);
        for (uint256 i; i < 5; i++) {
            colorsActive[i] = 1 == (extraData & 1);
            extraData = extraData >> 4;
        }

        emissive = (extraData & 1) == 1;
    }

    /////////////////////////////////////////////////////////
    // Actions                                             //
    /////////////////////////////////////////////////////////

    /// @notice Warning: This function should not be used directly from the contract. MechCrafting requires off-chain interactions
    ///         before the crafting.
    ///
    ///         Allows a TPL Revealed Mech Parts owner to craft a new Mech by using their parts
    /// @dev partsIds must be in the order of crafting (ARM_LEFT, ARM_RIGHT, ...) in order to make it less expensive
    /// @param partsIds the token ids to use to craft the mech
    /// @param afterglowId the afterglow id used on the mech
    /// @param extraData the data about seed for name, colors, emissive, ...
    function craft(uint256[] calldata partsIds, uint256 afterglowId, uint256 extraData) external craftingAllowed {
        _craft(partsIds, afterglowId, msg.sender, extraData);
    }

    /// @notice Warning: This function should not be used directly from the contract. MechCrafting requires off-chain interactions
    ///         before the crafting.
    ///
    ///         Allows a TPL Revealed Mech Parts owner to craft a new Mech by using their parts, with support of DelegateCash
    ///
    ///         requirements:
    ///             - All parts MUST be owned by the vault
    ///             - The afterglow MUST be owned by the vault
    ///             - The caller must be delegate for `vault` globally or on the current contract
    ///
    ///         Note that the Mech will be minted to the Vault directly
    ///
    /// @dev partsIds must be in the order of crafting (ARM_LEFT, ARM_RIGHT, ...) in order to make it less expensive
    /// @param partsIds the token ids to use to craft the mech
    /// @param afterglowId the afterglow id used on the mech
    /// @param extraData the data about seed for name, colors, emissive, ...
    /// @param vault the vault the current wallet tries to mint for
    function craftFor(
        uint256[] calldata partsIds,
        uint256 afterglowId,
        uint256 extraData,
        address vault
    ) external craftingAllowed {
        if (!delegationActive) {
            revert DelegationInactive();
        }

        _requireDelegate(vault);

        _craft(partsIds, afterglowId, vault, extraData);
    }

    /// @notice Allows a mech owner to dissasemble `mechId` and get back the parts & afterglow
    /// @param mechId the mech id
    function disassemble(uint256 mechId) external payable {
        _disassemble(mechId, msg.sender);
    }

    /// @notice Allows a mech owner to dissasemble `mechId` and get back the parts & afterglow, with support of DelegateCash
    /// @param mechId the mech id
    function disassembleFor(uint256 mechId, address vault) external payable {
        if (!delegationActive) {
            revert DelegationInactive();
        }

        _requireDelegate(vault);

        _disassemble(mechId, vault);
    }

    /////////////////////////////////////////////////////////
    // Owner                                               //
    /////////////////////////////////////////////////////////

    /// @notice Allows owner to set the disassembly fee & fee recipient
    /// @param newDisassemblyFeeRecipient the new fee recipient
    /// @param newFee the new fee
    function setDisassemblyFee(address newDisassemblyFeeRecipient, uint256 newFee) external onlyOwner {
        disassemblyFeeRecipient = newDisassemblyFeeRecipient;
        disassemblyFee = newFee;
    }

    /// @notice allows owner to activate or not interaction through delegate cash delegates
    /// @param isActive if we activate or not
    function setDelegationActive(bool isActive) external onlyOwner {
        delegationActive = isActive;
    }

    /// @notice allows owner to add or remove addresses allowed to craft even when public crafting is not open
    /// @param crafters the list of addresses to allow/disallow
    /// @param allowed if we are giving or removing the right to craft
    function setAllowedCrafters(address[] calldata crafters, bool allowed) external onlyOwner {
        uint256 length = crafters.length;
        if (length == 0) {
            revert InvalidLength();
        }

        for (uint i; i < length; i++) {
            allowedCrafters[crafters[i]] = allowed;
        }
    }

    /// @notice allows owner to change the "public crafting" status
    /// @param isPublic if the crafting is public or not
    function setCraftingPublic(bool isPublic) external onlyOwner {
        craftingPublic = isPublic;
    }

    /// @notice allows owner to withdraw the possible funds to `to`
    function withdraw(address to) external onlyOwner {
        uint256 balance = address(this).balance;

        if (balance == 0) {
            revert NothingToWithdraw();
        }

        (bool success, ) = to.call{value: balance}("");
        if (!success) {
            revert ErrorWithdrawing();
        }
    }

    /////////////////////////////////////////////////////////
    // Internals                                           //
    /////////////////////////////////////////////////////////

    /// @dev crafts
    function _craft(uint256[] calldata partsIds, uint256 afterglowId, address account, uint256 extraData) internal {
        uint256 length = partsIds.length;
        if (length != 6) {
            revert InvalidPartsAmount();
        }

        // get all ids "TokenData"
        ITPLRevealedParts.TokenData[] memory tokenPartsData = ITPLRevealedParts(TPL_REVEALED).partDataBatch(partsIds);

        uint256 packedIds;
        unchecked {
            uint256 engineModel = tokenPartsData[5].model;
            uint256 sameModelAsEngine;

            // verifies we have all the needed body parts
            // here we simply check that the bodyParts sent have the right types:
            // [ARM, ARM, HEAD, BODY, LEGS, ENGINE] which is [0, 0, 1, 2, 3, 4]
            // this is why they have to be sent in order
            if (
                tokenPartsData[0].bodyPart != 0 ||
                tokenPartsData[1].bodyPart != 0 ||
                tokenPartsData[2].bodyPart != 1 ||
                tokenPartsData[3].bodyPart != 2 ||
                tokenPartsData[4].bodyPart != 3 ||
                tokenPartsData[5].bodyPart != 4
            ) {
                revert InvalidBodyPart();
            }

            do {
                length--;
                if (tokenPartsData[length].model == engineModel) {
                    sameModelAsEngine++;
                }

                // builds the "packedIds" for the Mech to be able to store all the ids used to craft it
                packedIds = packedIds | (partsIds[length] << (length * 32));
            } while (length > 0);

            // engine + at least 2 parts
            if (sameModelAsEngine < 3) {
                revert InvalidModelAmount();
            }
        }

        // we add the afterglow id at the end
        packedIds = packedIds | (afterglowId << (6 * 32));

        // transfer all partsIds to TPL_PARTS_ESCROW
        ITPLRevealedParts(TPL_REVEALED).batchTransferFrom(account, TPL_PARTS_ESCROW, partsIds);

        // transfer the afterGlow to TPL_PARTS_ESCROW
        IERC1155(TPL_AFTERGLOW).safeTransferFrom(account, TPL_PARTS_ESCROW, afterglowId, 1, "");

        // then we mint the next Mech with the needed data
        uint256 engineKnownId = engineIds[partsIds[5]];
        if (engineKnownId != 0) {
            ITPLMech(TPL_MECH).mintToken(engineKnownId, account, packedIds);
        } else {
            engineKnownId = ITPLMech(TPL_MECH).mintNext(account, packedIds);
            engineIds[partsIds[5]] = engineKnownId;
        }

        emit MechAssembly(engineKnownId, packedIds, extraData);
    }

    function _disassemble(uint256 mechId, address account) internal {
        if (msg.value != disassemblyFee) {
            revert InvalidFees();
        }

        // make sure account is the owner of the mech.
        if (account != ITPLMech(TPL_MECH).ownerOf(mechId)) {
            revert NotAuthorized();
        }

        // get all ids used in the Mech assembly
        (uint256[] memory partsIds, uint256 afterglowId) = ITPLMech(TPL_MECH).getMechPartsIds(mechId);

        // burn the mech
        ITPLMech(TPL_MECH).burn(mechId);

        // batch transfer all IDs from ESCROW to account
        ITPLRevealedParts(TPL_REVEALED).batchTransferFrom(TPL_PARTS_ESCROW, account, partsIds);

        // transfer afterglow from ESCROW to account
        IERC1155(TPL_AFTERGLOW).safeTransferFrom(TPL_PARTS_ESCROW, account, afterglowId, 1, "");

        // if there is a fee
        if (msg.value > 0) {
            address disassemblyFeeRecipient_ = disassemblyFeeRecipient;
            // and a fee recipient
            if (disassemblyFeeRecipient_ != address(0)) {
                // send directly
                (bool success, ) = disassemblyFeeRecipient_.call{value: msg.value}("");
                if (!success) {
                    revert ErrorDisassemblyFeePayment();
                }
            }
        }
    }

    function _requireDelegate(address vault) internal view {
        // checks that msg.sender is delegate for vault, either globally or for the current contract or for the RevealedParts contract
        if (!IDelegateRegistry(DELEGATE_REGISTRY).checkDelegateForContract(msg.sender, vault, address(this))) {
            if (!IDelegateRegistry(DELEGATE_REGISTRY).checkDelegateForContract(msg.sender, vault, TPL_REVEALED)) {
                revert NotAuthorized();
            }
        }
    }
}

interface ITPLMech {
    function mintNext(address to, uint256 packedIds) external returns (uint256);

    function mintToken(uint256 tokenId, address to, uint256 packedIds) external;

    function ownerOf(uint256 mechId) external view returns (address);

    function burn(uint256 tokenId) external;

    function getMechPartsIds(uint256 tokenId) external view returns (uint256[] memory, uint256);
}

interface IDelegateRegistry {
    /**
     * @notice Returns true if the address is delegated to act on your behalf for a token contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForContract(address delegate, address vault, address contract_) external view returns (bool);
}