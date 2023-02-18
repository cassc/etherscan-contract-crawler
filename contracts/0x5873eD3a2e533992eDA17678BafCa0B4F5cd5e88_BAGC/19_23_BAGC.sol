// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./core/BAGCCore.sol";

import "./interface/IBAGC.sol";
import "./interface/IMerchNFT.sol";
import "./interface/IInvitation.sol";

contract BAGC is ERC721URIStorageUpgradeable, ERC721EnumerableUpgradeable, BAGCCore {
    using ECDSA for bytes32;

    /// @notice Emitted when the locking status is changed to locked.
    /// @dev If a token is minted and the status is locked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Locked(uint256 tokenId, uint256 startTime, uint256 endTime);

    /// @notice Emitted when the locking status is changed to unlocked.
    /// @dev If a token is minted and the status is unlocked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Unlocked(uint256 tokenId);

    /// @notice Emitted when the token is minted.
    /// @dev If a token is minted, this event should be emitted.
    /// @param to The address that the token is minted to.
    /// @param tokenId The identifier for a token.
    /// @param InvitationTokenId The identifier for a invitation token.
    event Minted(address to, uint256 tokenId, uint256 InvitationTokenId);

    function initialize(
        string memory name,
        string memory symbol,
        string memory baseURI_,
        address invitationNFTAddress_,
        address relayerAddress_,
        uint256 numUserAvailableTokens,
        uint256 userTokenBoundaries
    ) public initializer {
        __ERC721_init(name, symbol);
        __ERC721URIStorage_init();
        __ERC721Enumerable_init();
        __Ownable_init();
        baseURI = baseURI_;
        invitationNFTAddress = invitationNFTAddress_;
        relayerAddress = relayerAddress_;
        _numUserAvailableTokens = numUserAvailableTokens;
        _userTokenBoundaries = userTokenBoundaries;
    }

    /**
     * ==================
     * mint
     * ==================
     */

    /// @notice the function used to mint not user tokens with merch
    /// @dev the function that only owner can mint
    /// @param to The address that the token is minted to.
    /// @param tokenId The token id to mint.
    function ownerMint(address to, uint256 tokenId) public onlyOwner {
        require(!IBAGC(address(this)).isUserToken(tokenId), "BAGC: it's user tokenId");

        _safeMint(to, tokenId);

        IMerchNFT(merchNFTAddress).mint(to, tokenId);
    }

    /// @notice the function used to mint tokens nft not user tokens without merch
    /// @dev the function that only owner can mint
    /// @param to The address that the token is minted to.
    /// @param tokenId The token id to mint.
    function ownerMintWithoutMerch(address to, uint256 tokenId) public onlyOwner {
        require(!IBAGC(address(this)).isUserToken(tokenId), "BAGC: it's user tokenId");

        _safeMint(to, tokenId);
    }

    /// @notice the function used to mint user token
    /// @param invitationTokenId The tokenId of the invitation NFT.
    /// @param relayerSignature The signature of the relayer.
    /// @param expiredAt The timestamp of the signature expired.
    function userMint(
        uint256 invitationTokenId,
        bytes memory relayerSignature,
        uint256 expiredAt
    ) public {
        if (expiredAt < block.timestamp) {
            revert("BAGC: expired");
        }
        (bool success, string memory message) = verifySignature(
            invitationTokenId,
            relayerSignature,
            expiredAt
        );

        require(success, message);

        InvitationNft nft = InvitationNft(invitationNFTAddress);
        require(nft.ownerOf(invitationTokenId) == msg.sender, "BAGC: not invitation owner");

        nft.burn(invitationTokenId);

        uint256 tokenId = getRandomAvailableTokenId(msg.sender, expiredAt);

        _safeMint(msg.sender, tokenId);

        --_numUserAvailableTokens;

        IMerchNFT(merchNFTAddress).mint(msg.sender, tokenId);

        emit Minted(msg.sender, tokenId, invitationTokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorageUpgradeable, ERC721Upgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    /**
     * ==================
     * lock
     * ==================
     */

    /// @dev the function to check if the NFT is locked
    /// @param tokenId The identifier for an BAGC nft.
    function locked(uint256 tokenId) public view returns (bool) {
        return (_locked[tokenId] > 0);
    }

    /// @dev the function to check if the NFT is locked
    /// @param tokenId The identifier for an BAGC nft.
    function getLockTime(uint256 tokenId) public view returns (uint256) {
        return _locked[tokenId];
    }

    /// @dev unlock NFTs can be called by only owner, and it should not be locked
    /// @param tokenId The identifier for an BAGC nft.
    function lock(uint256 tokenId, uint256 period) public {
        require(ownerOf(tokenId) == msg.sender, "BAGC: not owner");
        require(_locked[tokenId] == 0, "BAGC: already locked");
        require(period > 0, "BAGC: period should be greater than 0");
        uint256 end = block.timestamp + period;
        _locked[tokenId] = end;
        emit Locked(tokenId, block.timestamp, end);
    }

    /// @dev unlock NFTs can be called by only owner, and it should be already locked
    /// @param tokenId The identifier for an BAGC nft.
    function unlock(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "BAGC: not owner");
        require(_locked[tokenId] < block.timestamp, "BAGC: not expired");
        _locked[tokenId] = 0;
        emit Unlocked(tokenId);
    }

    /// @dev If it's locked, the transfer is blocked.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        require(_locked[tokenId] == 0);
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721URIStorageUpgradeable, ERC721Upgradeable)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    uint256[50] private __gap;
}