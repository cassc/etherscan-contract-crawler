//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {ERC4907, IERC4907} from "../../utils/tokens/ERC721/extensions/ERC4907/ERC4907.sol";
import {IERC4906, IERC165} from "../../utils/tokens/IERC4906.sol";
import {Base721} from "../../utils/tokens/ERC721/Base721.sol";

import {ITPLRevealedParts} from "../TPLRevealedParts/ITPLRevealedParts.sol";

import {ITPLMechRentalManager} from "./TPLMechRental/ITPLMechRentalManager.sol";
import {ITPLMechOrigin} from "./TPLMechOrigin/ITPLMechOrigin.sol";

/// @title TPLMech
/// @author CyberBrokers
/// @author dev by @dievardump
/// @notice Registry containing the CyberBrokers Genesis Mechs
/// @dev Mechs can only be minted by accounts in the "minters" list.
///
///      To build a Mech, 7 parts are necessary: 2 arms, one head, one body, one pair of legs, one engine and one afterglow.
///
///      We keep a reference of all those 7 ids for each Mech, making sure we can get back all parts information used to build it
contract TPLMech is Base721, ERC4907, IERC4906 {
    error UnknownMech();
    error WrongParameter();
    error NotAuthorized();
    error OperatorNotAuthorized();

    error TransferDeniedByRentalManager();

    uint256 private _minted;
    uint256 private _burned;

    /// @notice Emitted when a Mech changed (either is minted, or its mechData has been updated)
    /// @param mechId the mech id
    event MechChanged(uint256 indexed mechId);

    address public tplOrigin;

    address public rentalManager;

    /// @dev contains extra data allowing to identify the Mechs origin (the parts etc...)
    mapping(uint256 => uint256) public mechOriginData;

    constructor(ERC721CommonConfig memory config, address tplOrigin_) Base721("Genesis Mechs", "GENESISMECHS", config) {
        tplOrigin = tplOrigin_;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(Base721, ERC4907, IERC165) returns (bool) {
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }

    function totalSupply() public view returns (uint256) {
        return _minted - _burned;
    }

    /// @notice returns all TPLRevealedParts IDs & TPLAfterglow ID used in crafting a Mech
    /// @param tokenId the Mech ID
    /// @return an array with the 6 TPLRevealedParts ids used
    /// @return the afterglow id
    function getMechPartsIds(uint256 tokenId) public view returns (uint256[] memory, uint256) {
        uint256 mechData = mechOriginData[tokenId];
        if (mechData == 0) {
            revert UnknownMech();
        }

        return ITPLMechOrigin(tplOrigin).getMechPartsIds(mechData);
    }

    /// @notice returns all TPL Revealed Parts IDs (& their TokenData) used in crafting a Mech
    /// @param tokenId the mech to get parts of
    /// @return an array with 7 MechOrigin containing each parts details
    function getMechOrigin(uint256 tokenId) public view returns (ITPLMechOrigin.MechOrigin memory) {
        uint256 mechData = mechOriginData[tokenId];
        if (mechData == 0) {
            revert UnknownMech();
        }

        return ITPLMechOrigin(tplOrigin).getMechOrigin(mechData);
    }

    /// @notice returns an array of getMechOrigin(tokenId) containing the origin for all ids in tokenIds
    /// @param tokenIds the mech ids we want the origin of
    /// @return an array of MechOrigin
    function getMechOriginBatch(uint256[] memory tokenIds) public view returns (ITPLMechOrigin.MechOrigin[] memory) {
        uint256 length = tokenIds.length;
        if (length == 0) revert WrongParameter();

        ITPLMechOrigin.MechOrigin[] memory origins = new ITPLMechOrigin.MechOrigin[](length);

        do {
            unchecked {
                length--;
            }
            origins[length] = getMechOrigin(tokenIds[length]);
        } while (length > 0);

        return origins;
    }

    function isApprovedForAll(address owner_, address operator) public view virtual override returns (bool) {
        // this allows to automatically approve some contracts like the MechCrafter contract
        // to do actions like disassembly of the mech
        return minters[msg.sender] || super.isApprovedForAll(owner_, operator);
    }

    /////////////////////////////////////////////////////////
    // Interactions                                        //
    /////////////////////////////////////////////////////////

    /// @notice disabled
    function mintTo(address, uint256) public override onlyMinter {
        revert NotAuthorized();
    }

    /// @notice Allows a minter to mint the next Mech to `to` with `mechData`
    /// @param to the token recipient
    /// @param mechData data allowing to find the mech origin
    /// @return the token id
    function mintNext(address to, uint256 mechData) external virtual onlyMinter returns (uint256) {
        uint256 tokenId = _mintTo(to, 1);
        mechOriginData[tokenId] = mechData;

        emit MechChanged(tokenId);

        return tokenId;
    }

    /// @notice Allows a minter to mint the given `tokenId` Mech to `to` with `mechData`
    /// @param tokenId the token id
    /// @param to the token recipient
    /// @param mechData data allowing to find the mech origin
    function mintToken(uint256 tokenId, address to, uint256 mechData) external virtual onlyMinter {
        _mint(to, tokenId);
        mechOriginData[tokenId] = mechData;

        emit MechChanged(tokenId);
    }

    /// @notice Allows to update a mech origin data
    /// @param tokenId the mech id
    /// @param mechData the new Data
    function updateMechData(uint256 tokenId, uint256 mechData) external onlyMinter {
        mechOriginData[tokenId] = mechData;

        emit MechChanged(tokenId);

        // if the mechData are updated, this could mean that the metadata changed
        emit MetadataUpdate(tokenId);
    }

    /////////////////////////////////////////////////////////
    // Gated Owner                                         //
    /////////////////////////////////////////////////////////

    /// @notice allows owner to set the collection base URI value & trigger a metadata update from indexers
    /// @param newBaseURI the new base URI
    /// @param triggerEIP4906 boolean to set to true if we want marketplaces/platforms to refetch metadata
    function setBaseURI(string calldata newBaseURI, bool triggerEIP4906) public onlyOwner {
        _setBaseURI(newBaseURI);

        if (triggerEIP4906) {
            emit BatchMetadataUpdate(1, _lastTokenId);
        }
    }

    /// @notice Allows owner to set the new rental manager, to support EIP-4907
    /// @param newRentalManager the new rental maanager
    function setRentalManager(address newRentalManager) external onlyOwner {
        rentalManager = newRentalManager;
    }

    /// @notice Allows owner to set the new tpl origin
    /// @param newTplMechOrigin the contract reading the origin of a mec
    function setTPLOrigin(address newTplMechOrigin) external onlyOwner {
        tplOrigin = newTplMechOrigin;
    }

    /////////////////////////////////////////////////////////
    // Internals                                           //
    /////////////////////////////////////////////////////////

    function _mint(address to, uint256 id) internal override {
        super._mint(to, id);
        _minted++;
    }

    function _burn(uint256 id) internal override {
        super._burn(id);
        delete mechOriginData[id];

        _burned++;
    }

    /// @dev only rentalManager can allow a rental
    function _checkCanRent(
        address operator,
        uint256 tokenId,
        address /*user*/,
        uint64 /*expires*/
    ) internal view override {
        if (!_exists(tokenId)) {
            revert UnknownMech();
        }

        // if it's not rentalManager calling, deny
        if (operator != rentalManager) {
            revert OperatorNotAuthorized();
        }

        // if we are here, it means the call comes from rentalManager, which must have already validated
        // everything there is before calling the setUser(tokenId, user) function
    }

    /// @dev only rentalManager can trigger the cancelation of a rental
    /// @param operator the current caller
    /// @param tokenId the token id to cancel the rental for
    function _checkCanCancelRental(address operator, uint256 tokenId) internal view virtual override {
        if (operator != rentalManager) {
            revert OperatorNotAuthorized();
        }

        // if we are here, it means the call comes from rentalManager, which must have already validated
        // everything there is before calling the cancelRenntal(tokenId) function
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        // if minting, there is definitely no rental ongoing, saves checks
        if (from != address(0)) {
            address user = userOf(firstTokenId);

            // if the item is currently in rental
            if (user != address(0)) {
                // we need rentalManager to allow or deny the transfer
                if (
                    !ITPLMechRentalManager(rentalManager).checkTransferPolicy(msg.sender, from, to, firstTokenId, user)
                ) {
                    revert TransferDeniedByRentalManager();
                }
            }
        }

        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }
}