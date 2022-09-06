//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../interfaces/IMerkle.sol";
import "../interfaces/IClaimMerkle.sol";
import "hardhat/console.sol";
import "@divergencetech/ethier/contracts/thirdparty/opensea/OpenSeaGasFreeListing.sol";

interface IRandomGenerator {
    function getRandom(uint256, uint256) external view returns (uint256);
}

contract GGNFT is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;
    Counters.Counter private commonCount;
    Counters.Counter private uncommonCount;
    Counters.Counter private rareCount;
    Counters.Counter private superRareCount;
    Counters.Counter private legendaryCount;
    IRandomGenerator public randomGenerator;
    string public baseUri;
    uint256 public GGNFT_MAX_SUPPLY = 3000;
    string public extension = ".json";
    uint256 private totalCommon = 1512;
    uint256 private totalUncommon = 780;
    uint256 private totalRare = 402;
    uint256 private totalSuperRare = 204;
    uint256 private totalLegendary = 102;
    uint256[1512] public commonId;
    uint256[780] private uncommon;
    uint256[402] private rare;
    uint256[204] private superRare;
    uint256[102] private legendary;
    bool[3000] private minted;

    mapping(address => bool) admins;

    event Minted(address indexed from, uint256 indexed index);

    constructor(
        string memory name,
        string memory symbol,
        address _randomGenerator
    ) ERC721(name, symbol) {
        randomGenerator = IRandomGenerator(_randomGenerator);
    }

    function mint(address to, uint256 rarity)
        public
        adminOrOwner
        returns (uint256)
    {
        require(rarity >= 0 && rarity < 5, "Rarity must be between 0-4");

        uint256 total = supply.current();
        require(total + 1 <= GGNFT_MAX_SUPPLY, "Max supply has been reached");

        if (rarity == 0) {
            return _mintRandom(to, commonCount, totalCommon, 0);
        } else if (rarity == 1) {
            return _mintRandom(to, uncommonCount, totalUncommon, totalCommon);
        } else if (rarity == 2) {
            return
                _mintRandom(
                    to,
                    rareCount,
                    totalRare,
                    totalCommon + totalUncommon
                );
        } else if (rarity == 3) {
            return
                _mintRandom(
                    to,
                    superRareCount,
                    totalSuperRare,
                    totalCommon + totalUncommon + totalRare
                );
        } else if (rarity == 4) {
            return
                _mintRandom(
                    to,
                    legendaryCount,
                    totalLegendary,
                    totalCommon + totalUncommon + totalRare + totalSuperRare
                );
        }
    }

    function _mintRandom(
        address to,
        Counters.Counter storage counter,
        uint256 total,
        uint256 startIndex
    ) private returns (uint256) {
        require(counter.current() < total, "Total number reached for rarity");

        uint256 randomNum = randomGenerator.getRandom(
            counter.current(),
            totalSupply()
        );

        uint256 index = uint256(randomNum % total);

        while (minted[index + startIndex]) {
            index = (index + 1) % total;
        }

        supply.increment();
        counter.increment();

        minted[index + startIndex] = true;

        _safeMint(to, index + startIndex);

        emit Minted(to, index + startIndex);
    }

    function burn(uint256 tokenId) external {
        address prevOwnership = ownerOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership ||
            isApprovedForAll(prevOwnership, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        require(isApprovedOrOwner, "Not approved");
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = baseUri;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        extension
                    )
                )
                : "";
    }

    function setExtension(string memory _extension) external adminOrOwner {
        extension = _extension;
    }

    function setUri(string memory _uri) external adminOrOwner {
        baseUri = _uri;
    }

    function addAdmin(address _admin) external adminOrOwner {
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) external adminOrOwner {
        delete admins[_admin];
    }

    modifier adminOrOwner() {
        require(msg.sender == owner() || admins[msg.sender], "Unauthorized");
        _;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, amount);
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