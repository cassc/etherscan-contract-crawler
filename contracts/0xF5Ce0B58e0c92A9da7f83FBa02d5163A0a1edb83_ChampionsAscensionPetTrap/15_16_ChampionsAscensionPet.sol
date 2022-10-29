// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ChampionsAscensionPet is ERC721, Pausable, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("ChampionsAscensionPet", "PET") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function tokenURI(uint256 _tokenId)
        public
        pure
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "https://champions.io/pets/nfts/",
                    Strings.toString(_tokenId)
                )
            );
    }

    /**
        Returns the total tokens minted so far.
     */
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(address to, uint32 numberToMint)
        public
        whenNotPaused
        onlyRole(MINTER_ROLE)
    {
        for (uint32 i = 0; i < numberToMint; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            _safeMint(to, tokenId);
        }
    }

    function safeMintBatch(address[] calldata to, uint32[] calldata numberToMint)
        external
        whenNotPaused
        onlyRole(MINTER_ROLE)
    {
        require(to.length == numberToMint.length, "to and numberToMint length mismatch");
        require(to.length > 0);
        for (uint32 e = 0; e < to.length; e++) {
            safeMint(to[e], numberToMint[e]);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}