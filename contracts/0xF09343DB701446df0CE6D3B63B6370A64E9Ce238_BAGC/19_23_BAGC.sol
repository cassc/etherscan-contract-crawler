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

    /// @notice Emitted when the token is minted.
    /// @dev If a token is minted, this event should be emitted.
    /// @param to The address that the token is minted to.
    /// @param tokenId The identifier for a token.
    /// @param InvitationTokenId The identifier for a invitation token.
    event Minted(address to, uint256 tokenId, uint256 InvitationTokenId);

    /// @notice Emitted when the token is locked.
    event Locked(uint256 tokenId, uint256 poolId);

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

    /// @notice the function used to mint not user tokens without merch
    /// @dev the function that only owner can mint
    /// @param to The address that the token is minted to.
    /// @param tokenId The token id to mint.
    function ownerMintWithoutMerch(address to, uint256 tokenId) public onlyOwner {
        require(!IBAGC(address(this)).isUserToken(tokenId), "BAGC: it's user tokenId");

        _safeMint(to, tokenId);
    }

    function ownerBatchMintWithoutMerch(address to, uint256[] memory tokenIdArray)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < tokenIdArray.length; i++) {
            require(!IBAGC(address(this)).isUserToken(tokenIdArray[i]), "BAGC: it's user tokenId");
            _safeMint(to, tokenIdArray[i]);
        }
    }

    /// @notice the function used to mint user token
    /// @param invitationTokenId The tokenId of the invitation NFT.
    /// @param relayerSignature The signature of the relayer.
    /// @param salt The random number
    function userMint(
        uint256 invitationTokenId,
        bytes memory relayerSignature,
        uint256 salt
    ) public {
        (bool success, string memory message) = verifySignature(
            invitationTokenId,
            relayerSignature,
            salt
        );

        require(success, message);

        InvitationNft nft = InvitationNft(invitationNFTAddress);
        require(nft.ownerOf(invitationTokenId) == msg.sender, "BAGC: not invitation owner");

        uint256 updatedNumAvailableTokens = _numUserAvailableTokens;
        uint256 tokenId = getRandomAvailableTokenId(msg.sender, salt, updatedNumAvailableTokens);

        _safeMint(msg.sender, tokenId);

        _numUserAvailableTokens = updatedNumAvailableTokens - 1;

        nft.burn(invitationTokenId);

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
     * staking
     * ==================
     */

    /// @param tokenId The identifier for an BAGC nft.
    function getPoolId(uint256 tokenId) public view returns (uint256) {
        return _locked[tokenId];
    }

    function getPoolEndTime(uint256 poolId) public view returns (uint256) {
        return _endTime[poolId];
    }

    /// @param tokenId The identifier for an BAGC nft.
    function stakingPool(uint256 tokenId, uint256 poolId) public {
        require(ownerOf(tokenId) == msg.sender, "BAGC: not owner");
        require(_endTime[_locked[tokenId]] < block.timestamp, "BAGC: already registered in a pool");
        _locked[tokenId] = poolId;
        emit Locked(tokenId, poolId);
    }

    /// @dev If it's locked, the transfer is blocked.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        require(_endTime[_locked[tokenId]] < block.timestamp, "BAGC: locked");
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