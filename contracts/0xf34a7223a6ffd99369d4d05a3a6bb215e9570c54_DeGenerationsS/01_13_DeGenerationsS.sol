// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./IDGSMetadataRenderer.sol";

interface INoShitZone {
    function burn(
        address who,
        uint32 amount,
        uint32 id
    ) external;
}

contract DeGenerationsS is ERC721AQueryable, ERC2981, Ownable {
    uint32 public constant LEGENDARY_ID = 0;
    uint32 public constant DOPE_ID = 1;
    uint32 public constant BASIC_ID = 2;

    INoShitZone public immutable _cleaner;
    IERC721A public immutable _shitBeast;
    mapping(uint32 => ShitData) _shitData;

    struct ShitData {
        uint8 shitType;
        uint32 shitNo;
    }

    uint32 public _dopeMinted;
    uint32 public _basicMinted;
    uint32 public _legendaryMinted;

    bool public _started;
    IDGSMetadataRenderer public _renderer;

    constructor(address cleaner, address shitBeast) ERC721A("De-Generations: S", "DGS") {
        _cleaner = INoShitZone(cleaner);
        _shitBeast = IERC721A(shitBeast);
        setFeeNumerator(750);
    }

    function clean(uint8 cleanerType, uint32 amount) external {
        require(_started, "DGS: Not started");
        require(_shitBeast.balanceOf(msg.sender) > 0, "DGS: Are you ShitBeast owner?");

        if (amount == 0) return;

        _cleaner.burn(msg.sender, amount, cleanerType);
        internalMint(msg.sender, amount, cleanerType);
    }

    function shitData(uint256 tokenId) public view returns (uint8 shitType, uint32 shitNo) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        ShitData memory data = _shitData[uint32(tokenId)];
        return (data.shitType, data.shitNo);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return _renderer.render(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || ERC721A.supportsInterface(interfaceId);
    }

    function internalMint(
        address to,
        uint32 amount,
        uint8 cleanerType
    ) internal {
        uint32 shitNoStartId = 0;

        if (cleanerType == BASIC_ID) {
            shitNoStartId = uint32(_basicMinted);
            _basicMinted += amount;
        } else if (cleanerType == DOPE_ID) {
            shitNoStartId = uint32(_dopeMinted);
            _dopeMinted += amount;
        } else if (cleanerType == LEGENDARY_ID) {
            shitNoStartId = uint32(_legendaryMinted);
            _legendaryMinted += amount;
        } else {
            require(false, "?");
        }

        uint32 startId = uint32(_totalMinted());
        _safeMint(to, amount);

        for (uint32 i = 0; i < amount; ) {
            unchecked {
                _shitData[i + startId] = ShitData({shitType: uint8(cleanerType), shitNo: i + shitNoStartId});
                ++i;
            }
        }
    }

    function setFeeNumerator(uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    function setStarted(bool started) external onlyOwner {
        _started = started;
    }

    function setRenderer(address renderer) external onlyOwner {
        _renderer = IDGSMetadataRenderer(renderer);
    }

    uint32 private constant _dopeAirdropLimit = 818;
    uint32 public _dopeAirdropped = 0;
    uint32 private constant _basicAirdropLimit = 637;
    uint32 public _basicAirdropped = 0;

    function airdrop(
        uint8 cleanerType,
        address[] memory tos,
        uint32[] memory amounts
    ) external onlyOwner {
        if (cleanerType == 1) {
            for (uint256 i = 0; i < tos.length; ) {
                internalMint(tos[i], amounts[i], cleanerType);
                _dopeAirdropped += amounts[i];
                unchecked {
                    i++;
                }
            }

            require(_dopeAirdropped <= _dopeAirdropLimit);
        } else if (cleanerType == 2) {
            for (uint256 i = 0; i < tos.length; ) {
                internalMint(tos[i], amounts[i], cleanerType);
                _basicAirdropped += amounts[i];
                unchecked {
                    i++;
                }
            }

            require(_basicAirdropped <= _basicAirdropLimit);
        }
    }
}