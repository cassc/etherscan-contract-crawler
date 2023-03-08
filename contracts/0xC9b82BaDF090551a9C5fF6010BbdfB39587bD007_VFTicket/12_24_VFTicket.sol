// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../token/ERC4907VF.sol";
import "./VFTokenBaseExtensions.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

contract VFTicket is ERC4907VF, VFTokenBaseExtensions {
    //Token base URI
    string private _baseUri;

    /**
     * @dev Initializes the contract by setting a `initialBaseUri`, `name`, `symbol`,
     * `controlContractAddress`, `royaltiesContractAddress` and `signer` to the token.
     */
    constructor(
        string memory initialBaseUri,
        string memory name,
        string memory symbol,
        address controlContractAddress,
        address royaltiesContractAddress,
        address signer
    )
        ERC4907VF(name, symbol, signer)
        VFTokenBaseExtensions(controlContractAddress, royaltiesContractAddress)
    {
        string memory contractAddress = Strings.toHexString(
            uint160(address(this)),
            20
        );
        setBaseURI(
            string(
                abi.encodePacked(initialBaseUri, contractAddress, "/tokens/")
            )
        );
    }

    /**
     * @dev Get the base token URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }

    /**
     * @dev Update the base token URI
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function setBaseURI(string memory baseUri) public onlyRole(getAdminRole()) {
        _baseUri = baseUri;
    }

    /**
     * @dev Update the set user signer address with `signer`
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function setSigner(address signer)
        public
        override
        onlyRole(getAdminRole())
    {
        super.setSigner(signer);
    }

    /**
     * @dev Permanently lock minting
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function lockMintingPermanently() external onlyRole(getAdminRole()) {
        _lockMintingPermanently();
    }

    /**
     * @dev Set the active/inactive state of minting
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function toggleMintActive() external onlyRole(getAdminRole()) {
        _toggleMintActive();
    }

    /**
     * @dev Set the active/inactive state of burning
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function toggleBurnActive() external onlyRole(getAdminRole()) {
        _toggleBurnActive();
    }

    /**
     * @dev Airdrop `addresses` for `quantity` starting at `startTokenId`
     *
     * Requirements:
     *
     * - the caller must be a minter role
     * - minting must not be locked and must be active
     * - `addresses` and `quantities` must have the same length
     */
    function airdrop(
        address[] calldata addresses,
        uint256[] calldata quantities,
        uint256 startTokenId
    ) external onlyRoles(getMinterRoles()) notLocked mintActive {
        _airdrop(addresses, quantities, startTokenId);
    }

    /**
     * @dev burn `from` token `tokenId`
     *
     * Requirements:
     *
     * - the caller must be a burner role
     * - burning must be active
     */
    function burn(address from, uint256 tokenId)
        external
        onlyRole(getBurnerRole())
        burnActive
    {
        _burn(from, tokenId, false);
    }

    /**
     * @dev setUser `user` for `tokenId` with `expires`
     *
     * Requirements:
     *
     * - the caller must be a minter role
     * - `tokenId` must be minted
     */
    function setUserAdmin(
        uint256 tokenId,
        address user,
        uint64 expires
    ) public onlyRoles(getMinterRoles()) {
        _setUser(tokenId, user, expires);
    }
}