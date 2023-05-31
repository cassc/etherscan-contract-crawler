// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

error NotOwnerOfToken();
error TokenNotWin();
error TokenAlrealyClaimed();
error TokenAlrealyBurned();
error PassHasClaimed();
error BurnTimeOver();
error MintNotStartedOrOver();

contract BaliRafflePass is ERC721URIStorage, Pausable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    IERC721 sssContract;

    string constant TOKENURI_UNBURNED =
        "ipfs://QmVMmv2hC6MJYstZ4fsbF5bf4BTeEkC4paHfChtpbzPw9v";
    string constant TOKENURI_BURNED =
        "ipfs://QmWVCKMjFNj32QadYFjcYD6PPL55VgyaQ3Td15qnmN1dSf";

    struct WinnerToken {
        bool isWin;
        bool hasClaimed;
    }

    mapping(uint256 => WinnerToken) public winnerTokens;
    mapping(uint256 => bool) private burnedTokens;

    uint256 public s_mintTimeStart;
    uint256 public s_mintTimeEnd;
    uint256 public s_burnTimeEnd;

    event WinnerTokenIdAdded(uint256 indexed tokenId);
    event WinnerTokenIdRemoved(uint256 indexed tokenId);
    event PassBurned(uint256 indexed tokenId, address indexed burner);

    constructor(
        address sssAddress,
        uint256 _mintStart,
        uint256 _mintEnd,
        uint256 _burnEnd
    ) ERC721("BaliRafflePass", "BALIRAFFLEPASS") {
        sssContract = IERC721(sssAddress);

        _tokenIdCounter.increment(); // so it'll start from token id 1

        s_mintTimeStart = _mintStart;
        s_mintTimeEnd = _mintEnd;
        s_burnTimeEnd = _burnEnd;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function addWinnerTokenId(uint256 sssTokenId) external onlyOwner {
        winnerTokens[sssTokenId].isWin = true;

        emit WinnerTokenIdAdded(sssTokenId);
    }

    function removeWinnerTokenId(
        uint256[] calldata sssTokenIds
    ) external onlyOwner {
        for (uint256 i; i < sssTokenIds.length; ) {
            uint256 sssTokenId = sssTokenIds[i];

            if (winnerTokens[sssTokenId].hasClaimed) {
                revert PassHasClaimed();
            }

            winnerTokens[sssTokenId].isWin = false;

            emit WinnerTokenIdRemoved(sssTokenId);

            unchecked {
                ++i;
            }
        }
    }

    function setMintTimeStart(uint256 _time) external onlyOwner {
        s_mintTimeStart = _time;
    }

    function setMintTimeEnd(uint256 _time) external onlyOwner {
        s_mintTimeEnd = _time;
    }

    function setBurnTimeEnd(uint256 _time) external onlyOwner {
        s_burnTimeEnd = _time;
    }

    function mint(uint256 sssTokenId) external {
        if (!winnerTokens[sssTokenId].isWin) {
            revert TokenNotWin();
        }

        if (winnerTokens[sssTokenId].hasClaimed) {
            revert TokenAlrealyClaimed();
        }

        if (sssContract.ownerOf(sssTokenId) != msg.sender) {
            revert NotOwnerOfToken();
        }

        if (
            s_mintTimeStart > block.timestamp || block.timestamp > s_mintTimeEnd
        ) {
            revert MintNotStartedOrOver();
        }

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        winnerTokens[sssTokenId].hasClaimed = true;

        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, TOKENURI_UNBURNED);
    }

    function airdrop(uint256 sssTokenId) external onlyOwner {
        if (!winnerTokens[sssTokenId].isWin) {
            revert TokenNotWin();
        }

        if (winnerTokens[sssTokenId].hasClaimed) {
            revert TokenAlrealyClaimed();
        }

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        winnerTokens[sssTokenId].hasClaimed = true;

        _mint(sssContract.ownerOf(sssTokenId), tokenId);
        _setTokenURI(tokenId, TOKENURI_UNBURNED);
    }

    function burn(uint256 tokenId) external {
        if (ownerOf(tokenId) != msg.sender) {
            revert NotOwnerOfToken();
        }
        if (burnedTokens[tokenId]) {
            revert TokenAlrealyBurned();
        }
        if (block.timestamp > s_burnTimeEnd) {
            revert BurnTimeOver();
        }

        burnedTokens[tokenId] = true;
        _setTokenURI(tokenId, TOKENURI_BURNED);

        if (paused()) {
            _unpause();
            transferFrom(msg.sender, address(this), tokenId);
            _pause();
        } else {
            transferFrom(msg.sender, address(this), tokenId);
        }

        emit PassBurned(tokenId, msg.sender);
    }

    function getBurnedTokenStatus(uint256 _tokenId) public view returns (bool) {
        return burnedTokens[_tokenId];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
}