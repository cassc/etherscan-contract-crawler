// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "@oz/token/ERC721/ERC721.sol";
import {AccessControlEnumerable} from "@oz/access/AccessControlEnumerable.sol";

import {ERC721Enumerable} from "@oz/token/ERC721/extensions/ERC721Enumerable.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {Ownable} from "@oz/access/Ownable.sol";
import {Counters} from "@oz/utils/Counters.sol";
import {Multicall} from "@oz/utils/Multicall.sol";
import "@oz/utils/Strings.sol";
import "./VerifySignature.sol";

/// @title The Pencil Case Project
/// @author Late Checkout <[email protected]>

contract PencilCase is
    ERC721,
    ERC721Enumerable,
    Ownable,
    AccessControlEnumerable,
    VerifySignature,
    Multicall
{
    using Strings for uint256;

    string public baseURI;
    bytes32 public constant minterRole = keccak256("MINTER_ROLE");
    address public vault = 0x9F836913343C0B46771206De4018Fcdd0D76A271;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _baseURI
    ) ERC721(_tokenName, _tokenSymbol) {
        _setupRole(minterRole, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        messageSigner = msg.sender;

        baseURI = _baseURI;
    }

    function claim(
        address _to,
        uint256 _tokenId,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        bytes memory signature
    ) external {
        require(
            verify(_to, _tokenId, _startTimestamp, _endTimestamp, signature),
            "signature is not valid"
        );
        require(
            block.timestamp <= _endTimestamp &&
                block.timestamp >= _startTimestamp,
            "Claiming period ends"
        );

        _mint(_to, _tokenId);
    }

    function setVault(address _newVault) external onlyOwner {
        vault = _newVault;
    }

    function withdraw() external onlyOwner {
        SafeTransferLib.safeTransferETH(vault, address(this).balance);
    }

    function adminMint(address _to, uint256 _tokenId)
        external
        onlyRole(minterRole)
    {
        _mint(_to, _tokenId);
    }

    function setBaseURI(string memory _baseURI) external onlyRole(minterRole) {
        baseURI = _baseURI;
    }

    function setMessageSigner(address _messageSigner) external onlyOwner {
        messageSigner = _messageSigner;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Hook that is called before any batch token transfer. For now this is limited
     * to batch minting by the {ERC721Consecutive} extension.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeConsecutiveTokenTransfer(
        address,
        address,
        uint256,
        uint96
    ) internal virtual override(ERC721, ERC721Enumerable) {
        revert("ERC721Enumerable: consecutive transfers not supported");
    }
}