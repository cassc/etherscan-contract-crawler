// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./ICubeXCard.sol";
import "./ICubeXGoldCard.sol";
import "./ICubeX.sol";
import "./ICubeXStake.sol";

contract CubeXOfficialTokens is
    ERC721,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    using Strings for uint256;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    address public cubexAddress;
    address public goldCardAddress;
    address public cubexCardAddress;
    address public cubexStakeAddress;

    uint256 public maxMintAmountPerTx;

    bool public paused = true;
    bool public revealed = false;

    uint256 private constant SILVER_OFFSET = 10000;
    uint256 private constant GOLD_OFFSET = 20000;

    ICubeX private cubex;
    ICubeXCard private cubexCard;
    ICubeXGoldCard private goldCard;
    ICubeXStake private cubexStake;

    mapping(uint256 => bool) public usedGameCards;

    address burnAddress = 0x000000000000000000000000000000000000dEaD;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxMintAmountPerTx,
        string memory _hiddenMetadataUri
    ) ERC721(_tokenName, _tokenSymbol) {
        setMaxMintAmountPerTx(_maxMintAmountPerTx);
        setHiddenMetadataUri(_hiddenMetadataUri);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(!paused, "The contract is paused!");
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        _;
    }

    function checkGoldCardBalance(
        address _address
    ) private view returns (uint256) {
        return goldCard.balanceOf(_address, 1);
    }

    function standardMint(
        bool includeStaked,
        uint256[] calldata ids
    ) external mintCompliance(ids.length) {
        address sender = msg.sender;
        uint256[] memory newTokenIds = new uint256[](ids.length);

        for (uint i = 0; i < ids.length; i++) {
            uint256 newTokenId = ids[i];
            require(
                !_exists(newTokenId) &&
                    !_exists(newTokenId + SILVER_OFFSET) &&
                    !_exists(newTokenId + GOLD_OFFSET),
                "A morph of this NFT already exists!"
            );

            if (includeStaked) {
                require(
                    cubex.ownerOf(newTokenId) == sender ||
                        isNftStakedByUser(sender, newTokenId),
                    "Can't morph it if you don't own it or have not staked it"
                );
            } else {
                require(
                    cubex.ownerOf(newTokenId) == sender,
                    "Can't morph it if you don't own it"
                );
            }

            newTokenIds[i] = newTokenId;
        }

        for (uint i = 0; i < newTokenIds.length; i++) {
            _safeMint(sender, newTokenIds[i]);
        }
    }

    function silverMint(
        bool includeStaked,
        uint256[] calldata ids
    ) external mintCompliance(ids.length) {
        address sender = msg.sender;
        uint256[] memory ownerCards = cubexCard.getOwnerTokens(sender);

        require(
            ids.length <= ownerCards.length,
            "Cannot use more Game Cards than owned"
        );

        // Check if the contract is approved by the user to manage their game cards
        require(
            cubexCard.isApprovedForAll(sender, address(this)),
            "Please approve contract to manage your game cards."
        );

        for (uint i = 0; i < ids.length; i++) {
            uint256 newTokenId = ids[i];
            require(
                !_exists(newTokenId) &&
                    !_exists(newTokenId + SILVER_OFFSET) &&
                    !_exists(newTokenId + GOLD_OFFSET),
                "A morph of this NFT already exists!"
            );

            if (includeStaked) {
                require(
                    cubex.ownerOf(newTokenId) == sender ||
                        isNftStakedByUser(sender, newTokenId),
                    "Can't morph it if you don't own it or have not staked it"
                );
            } else {
                require(
                    cubex.ownerOf(newTokenId) == sender,
                    "Can't morph it if you don't own it"
                );
            }

            // Burn used game card by transferring it to burn address
            cubexCard.safeTransferFrom(sender, burnAddress, ownerCards[i]);
            _safeMint(sender, newTokenId + SILVER_OFFSET);
        }
    }

    function goldMint(
        bool includeStaked,
        uint256[] calldata ids
    ) external mintCompliance(ids.length) {
        require(
            ids.length <= checkGoldCardBalance(msg.sender),
            "Cannot use more Gold Cards than owned"
        );

        address sender = msg.sender;
        uint256[] memory newTokenIds = new uint256[](ids.length);

        for (uint i = 0; i < ids.length; i++) {
            uint256 newTokenId = ids[i];
            require(
                !_exists(newTokenId) &&
                    !_exists(newTokenId + SILVER_OFFSET) &&
                    !_exists(newTokenId + GOLD_OFFSET),
                "A morph of this NFT already exists!"
            );

            if (includeStaked) {
                require(
                    cubex.ownerOf(newTokenId) == sender ||
                        isNftStakedByUser(sender, newTokenId),
                    "Can't morph it if you don't own it or have not staked it"
                );
            } else {
                require(
                    cubex.ownerOf(newTokenId) == sender,
                    "Can't morph it if you don't own it"
                );
            }

            newTokenId += GOLD_OFFSET;
            newTokenIds[i] = newTokenId;
        }

        // Check if the contract is approved by the user to manage their tokens
        require(
            goldCard.isApprovedForAll(sender, address(this)),
            "Please approve contract to manage your gold cards."
        );
        goldCard.safeTransferFrom(sender, burnAddress, 1, ids.length, "");

        for (uint i = 0; i < newTokenIds.length; i++) {
            _safeMint(sender, newTokenIds[i]);
        }
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    // Checks if a particular NFT (identified by tokenId) is staked by a user
    function isNftStakedByUser(
        address user,
        uint256 tokenId
    ) public view returns (bool) {
        ICubeXStake.Stake[] memory userStakes = cubexStake.getStakes(user);
        for (uint i = 0; i < userStakes.length; i++) {
            if (
                userStakes[i].tokenId == tokenId && userStakes[i].timestamp != 0
            ) {
                return true;
            }
        }
        return false;
    }

    function setRevealed(bool _state) external onlyOwner {
        revealed = _state;
    }

    function setMaxMintAmountPerTx(
        uint256 _maxMintAmountPerTx
    ) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(
        string memory _hiddenMetadataUri
    ) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) external onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) external onlyOwner {
        paused = _state;
    }

    function setCubexAddress(address _address) external onlyOwner {
        cubexAddress = _address;
        cubex = ICubeX(_address);
    }

    function setGoldCardAddress(address _address) external onlyOwner {
        goldCardAddress = _address;
        goldCard = ICubeXGoldCard(goldCardAddress);
    }

    function setCubexCardAddress(address _address) external onlyOwner {
        cubexCardAddress = _address;
        cubexCard = ICubeXCard(cubexCardAddress);
    }

    function setCubexStakeAddress(address _address) external onlyOwner {
        cubexStakeAddress = _address;
        cubexStake = ICubeXStake(cubexStakeAddress);
    }

    function mintFor(address _to, uint256[] memory _ids) public onlyOwner {
        for (uint i = 0; i < _ids.length; i++) {
            require(
                !_exists(_ids[i]) &&
                    !_exists(_ids[i] + SILVER_OFFSET) &&
                    !_exists(_ids[i] + GOLD_OFFSET),
                "A morph of this NFT already exists!"
            );
            _safeMint(_to, _ids[i]);
        }
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}