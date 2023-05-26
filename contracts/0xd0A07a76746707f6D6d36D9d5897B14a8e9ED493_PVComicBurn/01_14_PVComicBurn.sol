// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ComicMinter is IERC721 {
    function burn(uint256 tokenId) external;
}

contract RestrictedWindow is Ownable {
    uint256 public WINDOW_OPENS = 0; 
    uint256 public WINDOW_CLOSES = 0;

    event UpdatedWindow(uint256 start, uint256 end);
    modifier inWindow() {
        require(
            WINDOW_OPENS > 0 &&
                block.timestamp >= WINDOW_OPENS &&
                block.timestamp <= WINDOW_CLOSES,
            "not in window"
        );
        _;
    }

    function setWindow(
        uint256 start,
        uint256 end
    ) external onlyOwner {
        require(
            WINDOW_OPENS == 0 || block.timestamp < WINDOW_OPENS,
            "window has started"
        );

        if (start == 0) {
            require(end == 0, "clearing needs all to be 0");
        } else {
            require(block.timestamp < start, "start is in past");
            require(end > start, "end not after start");
        }

        WINDOW_OPENS = start;
        WINDOW_CLOSES = end;

        emit UpdatedWindow(WINDOW_OPENS, WINDOW_CLOSES);
    }
}

contract PVComicBurn is
    ERC721("Pixel Vault Founder's DAO", "PVFD"),
    ERC721Enumerable,
    ReentrancyGuard,
    RestrictedWindow
{
    address public COMIC_TOKEN;
    uint256 public constant MAX_COMIC_SUPPLY = 10000;
    string private __baseURI;

    mapping(uint256 => address) private _burners;

    event Burned(address indexed burner, uint256 indexed tokenId);

    constructor(
        address comicAddress,
        string memory baseURI,
        uint256 open,
        uint256 close
    ) {
        COMIC_TOKEN = comicAddress;
        WINDOW_OPENS = open;
        WINDOW_CLOSES = close;
        __baseURI = baseURI;
    }

    function swap(uint256[] calldata tokenIds) external nonReentrant inWindow {
        uint256 count = tokenIds.length;

        require(count <= 40, "Too many tokens to be burned");

        uint256 tokenId;
        for (uint256 i; i < count; i++) {
            tokenId = tokenIds[i];
            uint256 mintIndex = totalSupply();
            ComicMinter(COMIC_TOKEN).burn(tokenId);
            _safeMint(msg.sender, mintIndex);

            _burners[tokenId] = msg.sender;
            emit Burned(msg.sender, tokenId);
        }
    }

    function getBurner(uint256 tokenId) external view returns (address) {
        return _burners[tokenId];
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        __baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return baseURI;
    }

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
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

contract PVComicRedeem is RestrictedWindow, ReentrancyGuard {
    // DOUBLE CHECK THE CONTRACT IS CORRECT
    address public COMIC_TOKEN = 0x5ab21Ec0bfa0B29545230395e3Adaca7d552C948;

    // token id -> redeemer
    mapping(uint256 => address) private _redeemers;

    event Redeemed(address indexed redeemer, uint256 indexed tokenId);

    constructor() {
        // There is a 72 hour grace period before the window ends.
        WINDOW_OPENS = 1629356400; // 2021-08-19 00:00:01 UTC
        WINDOW_CLOSES = 1630566000; // 2021-09-02 00:00:00 UTC
    }

    function redeem(uint256[] calldata tokenIds)
        external
        nonReentrant
        inWindow
    {
        uint256 count = tokenIds.length;
        uint256 tokenId;
        for (uint256 i; i < count; i++) {
            tokenId = tokenIds[i];
            require(
                IERC721(COMIC_TOKEN).ownerOf(tokenId) == msg.sender,
                "not owner"
            );
            require(_redeemers[tokenId] == address(0), "already redeemed");

            _redeemers[tokenId] = msg.sender;
            emit Redeemed(msg.sender, tokenId);
        }
    }

    function getRedeemer(uint256 tokenId) external view returns (address) {
        return _redeemers[tokenId];
    }
}