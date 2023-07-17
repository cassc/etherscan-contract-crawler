// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/utils/Counters.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "erc6551/ERC6551Registry.sol";

// Soulbound ERC721 token for AquaNet profiles
contract AquaNet is ERC721, Ownable {
    using Counters for Counters.Counter;

    address public tokenBoundRegistry;
    address public erc6551ImplementationAddress;
    Counters.Counter private _tokenIdCounter;

    event AquaCreated(
        address indexed tokenAddress,
        uint256 tokenId,
        uint256 aquaId
    );

    constructor(
        address tokenBoundRegistry_,
        address erc6551ImplementationAddress_
    ) ERC721("AquaNet", "AQUA") {
        tokenBoundRegistry = tokenBoundRegistry_;
        erc6551ImplementationAddress = erc6551ImplementationAddress_;
    }

    modifier onlyApprovedOrOwner(address tokenAddress, uint256 tokenId) {
        require(
            msg.sender == IERC721(tokenAddress).ownerOf(tokenId) ||
                IERC721(tokenAddress).getApproved(tokenId) == msg.sender ||
                IERC721(tokenAddress).isApprovedForAll(
                    IERC721(tokenAddress).ownerOf(tokenId),
                    msg.sender
                ),
            "You must be the owner or approved to perform this action."
        );
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https:/token.aquanet.app/";
    }

    function safeMint(
        address tokenAddress,
        uint tokenId
    ) public onlyApprovedOrOwner(tokenAddress, tokenId) {
        address tokenBoundAddress = ERC6551Registry(tokenBoundRegistry).account(
            erc6551ImplementationAddress,
            block.chainid,
            tokenAddress,
            tokenId,
            0
        );
        require(
            balanceOf(tokenBoundAddress) == 0,
            "This address already has a token."
        );
        require(
            ERC721(tokenAddress).supportsInterface(type(IERC721).interfaceId),
            "The token adddress must be an ERC721."
        );
        _tokenIdCounter.increment();
        uint256 puddleTokenId = _tokenIdCounter.current();
        _safeMint(tokenBoundAddress, puddleTokenId);
        emit AquaCreated(tokenAddress, tokenId, puddleTokenId);
    }

    // If you are an owner or approved address, you can burn the token
    function burnAsEOA(
        address tokenAddress,
        uint tokenId
    ) external onlyApprovedOrOwner(tokenAddress, tokenId) {
        _burn(tokenId);
    }

    // The owner (TBA) can burn its own AquaNet token
    function burn(uint tokenId) external {
        require(
            msg.sender == ownerOf(tokenId),
            "You must be the owner of the token to burn it."
        );
        _burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal pure {
        require(
            from == address(0) || to == address(0),
            "This token can only be transfered or burned by the token owner or an approved address."
        );
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }
}