// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "erc721b/extensions/ERC721BBaseTokenURI.sol";
import "erc721b/extensions/ERC721BBurnable.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IAuthorizeMints } from "./IAuthorizeMints.sol";

/// @title Mintpass
/// @author molecule.to
/// @notice a soulbound (non transferrable) NFT that permits holders to mint IP-NFTs
contract Mintpass is AccessControl, ERC721BBaseTokenURI, ERC721BBurnable, IAuthorizeMints {
    error AlreadyRedeemed();
    error NotRedeemable();
    error NotOwningMintpass(uint256 id);
    error MintPassRevoked(uint256 id);

    bytes32 public constant MODERATOR = keccak256("MODERATOR");
    bytes32 public constant REDEEMER = keccak256("REDEEMER");

    enum Status {
        DEFAULT, //0
        REDEEMED,
        REVOKED
    }

    ///@notice Mapping from tokenId to validity of token.
    mapping(uint256 => Status) private _status;

    constructor(address ipnftContract) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(REDEEMER, ipnftContract);
    }

    /**
     *
     * EVENTS
     *
     */
    event Revoked(uint256 indexed tokenId);
    event Redeemed(uint256 indexed tokenId);
    event Burned(uint256 indexed tokenId);

    /**
     *
     * PUBLIC
     *
     */
    /// @param tokenId Identifier of the mint pass that is checked for validity
    /// @return bool true if the mint pass has been redeemed already
    function isRedeemable(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "Token does not exist");
        return _status[tokenId] == Status.DEFAULT;
    }

    /// @notice mints an arbitrary amount of mintpasses to `to`. Only callable by a `MODERATOR` role.
    function batchMint(address to, uint256 amount) external onlyRole(MODERATOR) {
        _safeMint(to, amount);
    }

    /// @dev see {IAuthorizeMints-authorizeReservation}
    function authorizeReservation(address reserver) external view override returns (bool) {
        return (balanceOf(reserver) > 0);
    }

    /// @dev see {IAuthorizeMints-authorizeMint}
    /// @dev reverts when authorization conditions are not met
    /// @param data must be a single `uint256` value: the mint pass id that's to be authorized
    function authorizeMint(address minter, address to, bytes memory data) external view override onlyRole(REDEEMER) returns (bool) {
        uint256 mintPassId = abi.decode(data, (uint256));

        if (ownerOf(mintPassId) != minter) {
            revert NotOwningMintpass(mintPassId);
        }
        if (!isRedeemable(mintPassId)) {
            revert MintPassRevoked(mintPassId);
        }
        return true;
    }

    /// @dev see {IAuthorizeMints-redeem}
    /// @dev reverts when authorization conditions are not met
    /// @param data must be a single `uint256` value: the mint pass id that's to be redeemed
    function redeem(bytes memory data) external override onlyRole(REDEEMER) {
        uint256 mintPassId = abi.decode(data, (uint256));
        if (!isRedeemable(mintPassId)) {
            revert NotRedeemable();
        }
        _status[mintPassId] = Status.REDEEMED;
        emit Redeemed(mintPassId);
    }

    /// @dev Mark `tokenOd` as revoked by a `MODERATOR` role
    /// @param tokenId Identifier of the token
    function revoke(uint256 tokenId) external onlyRole(MODERATOR) {
        if (!isRedeemable(tokenId)) {
            revert NotRedeemable();
        }
        _status[tokenId] = Status.REVOKED;
        emit Revoked(tokenId);
    }

    /// @param tokenId Identifier of the token
    /// @return string a base64 encoded JSON structure containing the token's redemption status
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string memory statusString = "redeemable";
        if (_status[tokenId] == Status.REVOKED) {
            statusString = "revoked";
        }
        if (_status[tokenId] == Status.REDEEMED) {
            statusString = "redeemed";
        }

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{"name": "IP-NFT Mintpass #',
                        Strings.toString(tokenId),
                        '", "description": "This Mintpass can be used to mint one IP-NFT", "external_url": "https://molecule.to", "image": "',
                        isRedeemable(tokenId)
                            ? "ar://K8ZyU9fWSMgEx0bDRmwd0sXGm1PKb_Dr2B-27yMqy3Y"
                            : "ar://g-ZF9NewUio2B74ChCQN0x0cj3liZPxj0H7wH-v5y98",
                        '", "attributes": [{ "trait_type": "Status", "value": "',
                        statusString,
                        '"}]}'
                    )
                )
            )
        );
    }

    function name() public pure returns (string memory) {
        return "IP-NFT Mintpass";
    }

    function symbol() public pure returns (string memory) {
        return "IPNFTMNTPSS";
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721B, IERC165, AccessControl) returns (bool) {
        return interfaceId == type(IERC721Metadata).interfaceId || super.supportsInterface(interfaceId);
    }

    function totalSupply() public view virtual override (ERC721B, ERC721BBurnable) returns (uint256) {
        return super.totalSupply();
    }

    function _exists(uint256 tokenId) internal view virtual override (ERC721B, ERC721BBurnable) returns (bool) {
        return super._exists(tokenId);
    }

    function ownerOf(uint256 tokenId) public view virtual override (ERC721B, ERC721BBurnable, IERC721) returns (address) {
        return super.ownerOf(tokenId);
    }

    /**
     *
     * INTERNAL
     *
     */

    /// @dev Hook that is called before every token transfer. This includes minting and burning.
    /// It checks if the token is minted or burned. If not the function is reverted.
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 amount) internal virtual override {
        require(from == address(0) || to == address(0), "This a Soulbound token. It can only be burned.");
        super._beforeTokenTransfers(from, to, startTokenId, amount);
    }
}