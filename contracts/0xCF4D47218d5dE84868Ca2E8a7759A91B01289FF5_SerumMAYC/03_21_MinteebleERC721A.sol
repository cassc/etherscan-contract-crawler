// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//  =============================================
//   _   _  _  _  _  ___  ___  ___  ___ _    ___
//  | \_/ || || \| ||_ _|| __|| __|| o ) |  | __|
//  | \_/ || || \\ | | | | _| | _| | o \ |_ | _|
//  |_| |_||_||_|\_| |_| |___||___||___/___||___|
//
//  Website: https://minteeble.com
//  Email: [email protected]
//
//  =============================================

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MinteeblePartialERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MinteebleERC721A is MinteeblePartialERC721, ERC721A, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    /**
     *  @notice MinteebleERC721 constructor
     *  @param _tokenName Token name
     *  @param _tokenName Token symbol
     */
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxSupply,
        uint256 _mintPrice
    ) ERC721A(_tokenName, _tokenSymbol) {
        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
    }

    /**
     *  @dev Checks if caller can mint
     */
    modifier canMint(uint256 _mintAmount) {
        require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceed!");
        _;
    }

    /**
     *  @inheritdoc ERC721A
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     *  @inheritdoc ERC721A
     */
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    /**
     *  @inheritdoc ERC721A
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token ID does not exist.");

        // Checks if collection is revealed
        if (revealed) return preRevealUri;

        // Evaluating full URI for the specified ID
        return string.concat(_baseURI(), _tokenId.toString(), uriSuffix);
    }

    /**
     *  @notice Mints one or more items
     */
    function mint(uint256 _mintAmount)
        public
        payable
        virtual
        canMint(_mintAmount)
        enoughFunds(_mintAmount)
        active
    {
        _safeMint(_msgSender(), _mintAmount);
    }

    /**
     * @notice Mints item for another address. (Reserved to contract owner)
     */
    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        canMint(_mintAmount)
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            TokenOwnership memory ownership = _ownershipOf(currentTokenId);

            if (!ownership.burned && ownership.addr != address(0)) {
                latestOwnerAddress = ownership.addr;
            }

            if (latestOwnerAddress == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }
}