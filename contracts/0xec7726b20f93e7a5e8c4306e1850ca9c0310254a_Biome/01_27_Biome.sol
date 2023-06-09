// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./ITreasure.sol";
import "../lib/Roles.sol";
import "../lib/Revealable.sol";

contract Biome is
    Ownable,
    ERC721,
    ERC721Enumerable,
    ReentrancyGuard,
    Roles,
    Revealable
{
    ITreasure public immutable treasure;
    uint256 public maxSupply;
    bool public claimEnabled;

    constructor(
        address treasureAddress,
        string memory _tokenName,
        string memory _symbol,
        uint256 _maxSupply,
        address _coordinator,
        address _linkToken,
        bytes32 _keyHash,
        string memory _defaultURI
    )
        ERC721(_tokenName, _symbol)
        Revealable(_defaultURI, _coordinator, _linkToken, _keyHash)
    {
        treasure = ITreasure(treasureAddress);
        keyHash = _keyHash;
        maxSupply = _maxSupply;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(tokenId <= totalSupply(), "Token not exist.");

        return
            isRevealed()
                ? string(
                    abi.encodePacked(
                        revealedBaseURI,
                        getShuffledId(totalSupply(), maxSupply, tokenId, 1),
                        ".json"
                    )
                )
                : defaultURI;
    }

    function ownedBalance() external view returns (uint256) {
        return treasure.balanceOf(msg.sender, 1);
    }

    function setClaimable(bool _claimEnabled) external onlyOwner {
        claimEnabled = _claimEnabled;
    }

    function airdrop(address to) external onlyOperator {
        uint256 tokenIndex = totalSupply();
        require(totalSupply() + 1 <= maxSupply, "Max supply reached.");
        _safeMint(to, tokenIndex + 1);
    }

    function burnBag(uint256 amount) external nonReentrant returns (uint256) {
        require(claimEnabled, "Claiming is disabled.");
        require(totalSupply() + amount <= maxSupply, "Exceeding max supply.");
        require(amount > 0 && amount <= 5, "Invalid burn amount");
        require(
            treasure.balanceOf(msg.sender, 1) >= amount,
            "Insufficient Bag."
        );
        uint256 tokenIndex = totalSupply();
        treasure.burnForAddress(1, msg.sender, amount);
        _mintToken(msg.sender, amount);
        return tokenIndex;
    }

    function _mintToken(address addr, uint256 amount) internal returns (bool) {
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenIndex = totalSupply();
            if (tokenIndex < maxSupply) {
                _safeMint(addr, tokenIndex + 1);
            }
        }
        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}