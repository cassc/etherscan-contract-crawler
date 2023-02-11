// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Pausable } from "../dependencies/openzeppelin/Pausable.sol";
import { Owned } from "../dependencies/solmate/Owned.sol";

import { IUpgradeable } from "../interfaces/IUpgradeable.sol";
import { ICyberGrand } from "../interfaces/ICyberGrand.sol";

import { Constants } from "../libraries/Constants.sol";
import { DataTypes } from "../libraries/DataTypes.sol";

import { CyberNFTBase } from "../base/CyberNFTBase.sol";
import { CyberGrandNFTStorage } from "../storages/CyberGrandNFTStorage.sol";

/**
 * @title CyberGrand NFT
 * @author CyberConnect
 * @notice This contract is used to create CyberGrand NFT.
 */
contract CyberGrandNFT is
    Pausable,
    CyberNFTBase,
    UUPSUpgradeable,
    Owned,
    CyberGrandNFTStorage,
    IUpgradeable,
    ICyberGrand
{
    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the Box NFT.
     * @param owner The owner to set for the Box NFT.
     * @param name The name to set for the Box NFT.
     * @param symbol The symbol to set for the Box NFT.
     */
    function initialize(
        address owner,
        address signer,
        string calldata name,
        string calldata symbol,
        string calldata uri
    ) external initializer {
        _signer = signer;
        _tokenURI = uri;
        _pause();
        CyberNFTBase._initialize(name, symbol);
        Owned.__Owned_Init(owner);
        emit Initialize(owner, signer, name, symbol, uri);
    }

    /**
     * @notice Changes the pause state of the box nft.
     *
     * @param toPause The pause state.
     */
    function pause(bool toPause) external onlyOwner {
        if (toPause) {
            super._pause();
        } else {
            super._unpause();
        }
    }

    /**
     * @notice Contract version number.
     *
     * @return uint256 The version number.
     * @dev This contract can be upgraded with UUPS upgradeability
     */
    function version() external pure virtual override returns (uint256) {
        return _VERSION;
    }

    /**
     * @notice Claims a CyberGrand nft for an address.
     *
     * @param to The claimer address.
     * @param sig The EIP712 signature.
     * @return uint256 The token id.
     */
    function claimGrand(address to, DataTypes.EIP712Signature calldata sig)
        external
        payable
        returns (uint256)
    {
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._CLAIM_GRAND_TYPEHASH,
                        to,
                        nonces[to]++,
                        sig.deadline
                    )
                )
            ),
            _signer,
            sig
        );

        uint256 tokenId = super._mint(to);
        emit ClaimGrand(to, tokenId);

        return tokenId;
    }

    /**
     * @notice Sets the new signer address.
     *
     * @param signer The signer address.
     * @dev The address can not be zero address.
     */
    function setSigner(address signer) external onlyOwner {
        require(signer != address(0), "zero address signer");
        address preSigner = _signer;
        _signer = signer;

        emit SetSigner(preSigner, signer);
    }

    /**
     * @notice Sets the new tokenURI.
     *
     * @param uri The tokenURI.
     */
    function setTokenURI(string calldata uri) external onlyOwner {
        _tokenURI = uri;
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the signer address.
     *
     * @return address The signer address.
     */
    function getSigner() external view override returns (address) {
        return _signer;
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Transfers the box nft.
     *
     * @param from The initial owner address.
     * @param to The receipient address.
     * @param id The nft id.
     * @dev It requires the state to be unpaused
     */
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override whenNotPaused {
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
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        return _tokenURI;
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    // UUPS upgradeability
    function _authorizeUpgrade(address) internal override onlyOwner {}
}