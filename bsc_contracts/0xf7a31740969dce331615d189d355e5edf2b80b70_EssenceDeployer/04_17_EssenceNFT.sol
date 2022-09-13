// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IEssenceNFT } from "../interfaces/IEssenceNFT.sol";
import { IProfileNFT } from "../interfaces/IProfileNFT.sol";
import { IUpgradeable } from "../interfaces/IUpgradeable.sol";
import { IEssenceDeployer } from "../interfaces/IEssenceDeployer.sol";

import { CyberNFTBase } from "../base/CyberNFTBase.sol";
import { EssenceNFTStorage } from "../storages/EssenceNFTStorage.sol";

/**
 * @title Essence NFT
 * @author CyberConnect
 * @notice This contract is used to create an Essence NFT.
 */
contract EssenceNFT is
    CyberNFTBase,
    EssenceNFTStorage,
    IUpgradeable,
    IEssenceNFT
{
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    address public immutable PROFILE; // solhint-disable-line

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        address profileProxy = IEssenceDeployer(msg.sender).essParams();
        require(profileProxy != address(0), "ZERO_ADDRESS");
        PROFILE = profileProxy;
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEssenceNFT
    function initialize(
        uint256 profileId,
        uint256 essenceId,
        string calldata name,
        string calldata symbol,
        bool transferable
    ) external override initializer {
        _profileId = profileId;
        _essenceId = essenceId;
        _transferable = transferable;
        CyberNFTBase._initialize(name, symbol);
        emit Initialize(profileId, essenceId, name, symbol, transferable);
    }

    /// @inheritdoc IEssenceNFT
    function mint(address to) external override returns (uint256) {
        require(msg.sender == PROFILE, "ONLY_PROFILE");
        return super._mint(to);
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IUpgradeable
    function version() external pure override returns (uint256) {
        return _VERSION;
    }

    // @inheritdoc IEssenceNFT
    function isTransferable() external view override returns (bool) {
        return _transferable;
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Disallows the transfer of the essence nft.
     */
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        if (!_transferable) {
            revert("TRANSFER_NOT_ALLOWED");
        }
        super.transferFrom(from, to, id);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Generates the metadata json object.
     *
     * @param tokenId The profile NFT token ID.
     * @return string The metadata json object.
     * @dev It requires the tokenId to be already minted.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        return
            IProfileNFT(PROFILE).getEssenceNFTTokenURI(_profileId, _essenceId);
    }
}