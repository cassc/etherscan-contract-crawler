// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";

contract PI is
    Ownable,
    UpdatableOperatorFilterer,
    ERC2981,
    ERC721A,
    ReentrancyGuard
{
    struct Season {
        uint256 sellType; //0 public, 1 whitelist , 2 team
        uint256 price;
        uint256 quantity;
        uint256 startTime;
        uint256 endTime;
    }

    struct Whitelist {
        uint256 season;
        bytes32 merkleRoot;
    }

    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 10000;
    bool public allowBuy = true;
    bool public allowFixURI = true;
    uint256 public buyLimit = 2;
    uint256[] public seasonList;

    string private _hiddenMetadataURI;

    mapping(uint256 => string) public seasonUriMap; //seasonNum => uri
    mapping(uint256 => Whitelist) public seasonWhitelist; // seasonNum => Whitelist

    mapping(address => uint256) private _walletMints; //record wallet mint number
    mapping(uint256 => uint256) private _tokenSeasonMap; // tokenId => seasonNum
    mapping(uint256 => Season) private _ogxSeasons; // seasonNum =>  Season
    mapping(uint256 => bool) private _lockTokens; //token => isLocked

    event TokenBorn(
        address indexed owner,
        uint256 startTokenId,
        uint256 quantity,
        uint256 season
    );
    event SeasonAdded(
        uint256 indexed season,
        uint256 indexed sellType,
        uint256 quantity,
        uint256 startTime,
        uint256 endTime
    );
    event SeasonUpdated(uint256 indexed season, uint256 endTime);
    event WhitelistDeleted(uint256 indexed season);
    event WhitelistAdded(uint256 indexed season, bytes32 merkleRoot);
    event SeasonsDeleted(uint256 indexed season);
    event TokenLocked(uint256 indexed tokenId);
    event TokenUnlocked(uint256 indexed tokenId);
    event SeasonOpened(uint256 indexed season, string baseURI);
    event HiddenMetadataURISet(string baseURI);
    event AllowBuySet(bool allowBuy);
    event BuyLimitSet(uint256 buyLimit);
    event RoyaltyInfoSet(address receiver, uint96 feeBasisPoints);
    event FixURIDisabled();

    error IsNoOwner();
    error CallFailed();
    error TokenIsLocked(uint256 tokenId);
    error TokenIsUnlocked(uint256 tokenId);
    error LockQueryForNonexistentToken();

    constructor(
        string memory hiddenMetadataURI,
        string memory name,
        string memory symbol,
        address filterRegistry,
        address subscribeRegistry
    )
        ERC721A(name, symbol)
        UpdatableOperatorFilterer(address(0), address(0), false)
    {
        _hiddenMetadataURI = hiddenMetadataURI;
        _setDefaultRoyalty(msg.sender, 500);
        operatorFilterRegistry = IOperatorFilterRegistry(filterRegistry);
        if (address(0) != filterRegistry) {
            operatorFilterRegistry.register(address(this));
            if (address(0) != subscribeRegistry) {
                operatorFilterRegistry.subscribe(
                    address(this),
                    subscribeRegistry
                );
            }
        }
    }

    function addSeason(
        uint256 season,
        uint256 sellType,
        uint256 price,
        uint256 quantity,
        uint256 startTime,
        uint256 endTime
    ) external onlyOwner {
        require(season > 0, "season invalid");
        require(sellType < 3, "sellType invalid");
        require(startTime > block.timestamp, "startTime invalid");
        require((endTime > startTime), "endTime invalid");
        require(quantity > 0, "quantity invalid");
        Season storage ogxSeason = _ogxSeasons[season];
        require(ogxSeason.startTime == 0, "season already exists");
        ogxSeason.price = price;
        ogxSeason.quantity = quantity;
        ogxSeason.startTime = startTime;
        ogxSeason.endTime = endTime;
        ogxSeason.sellType = sellType;

        seasonList.push(season);

        emit SeasonAdded(season, sellType, quantity, startTime, endTime);
    }

    function updateSeason(uint256 season, uint256 endTime) external onlyOwner {
        Season storage ogxSeason = _ogxSeasons[season];
        require(ogxSeason.startTime > 0, "season not exist");
        require(
            (endTime > ogxSeason.startTime) && (endTime > block.timestamp),
            "endTime must be later than startTime and current time"
        );
        ogxSeason.endTime = endTime;
        emit SeasonUpdated(season, endTime);
    }

    function deleteSeason(uint256 season) external onlyOwner {
        Season storage ogxSeason = _ogxSeasons[season];
        require(ogxSeason.startTime > 0, "season not exist");
        delete (_ogxSeasons[season]);
        delete (seasonWhitelist[season]);
        for (uint i = 0; i < seasonList.length; i++) {
            if (season == seasonList[i]) {
                uint256 last = seasonList[seasonList.length - 1];
                seasonList.pop();
                if (season != last) {
                    seasonList[i] = last;
                }
                break;
            }
        }
        emit SeasonsDeleted(season);
    }

    // Function to set the merkle root
    function addWhitelist(
        uint256 season,
        bytes32 newMerkleRoot
    ) external onlyOwner {
        seasonWhitelist[season].season = season;
        seasonWhitelist[season].merkleRoot = newMerkleRoot;
        emit WhitelistAdded(season, newMerkleRoot);
    }

    function deleteWhitelist(uint256 season) external onlyOwner {
        delete (seasonWhitelist[season]);
        emit WhitelistDeleted(season);
    }

    function buyBox(
        uint256 season,
        uint256 quantity,
        bytes32[] calldata merkleProof
    ) external payable {
        require(allowBuy, "buy disabled");
        require(quantity > 0, "quantity invalid");
        require(totalSupply() + quantity <= MAX_SUPPLY, "over max supply");
        Season storage ogxSeason = _ogxSeasons[season];
        require(ogxSeason.startTime > 0, "season not exist");
        require(
            ogxSeason.sellType < 2,
            "the season is not allowed to mint by this function"
        );
        require(
            (ogxSeason.startTime <= block.timestamp) &&
                (ogxSeason.endTime >= block.timestamp),
            "not in the sale period"
        );
        require(ogxSeason.quantity > 0, "sold out");
        require(ogxSeason.quantity >= quantity, "not enough stock");
        require(ogxSeason.price * quantity == msg.value, "eth value invalid");
        address sender = _msgSender();
        if (ogxSeason.sellType == 1) {
            Whitelist storage _whitelistSeason = seasonWhitelist[season];
            require(
                _whitelistSeason.season == season,
                "whitelist season not exist"
            );
            bytes32 leaf = keccak256(abi.encodePacked(sender));
            require(
                MerkleProof.verify(
                    merkleProof,
                    _whitelistSeason.merkleRoot,
                    leaf
                ),
                "not in the whitelist."
            );
        }
        // Check max box per user
        uint256 totalBoxes = _walletMints[sender] + quantity;
        require(buyLimit >= totalBoxes, "reach the limit");
        _walletMints[sender] = totalBoxes;

        uint256 startTokenId = _nextTokenId();
        _mint(sender, quantity);
        ogxSeason.quantity = ogxSeason.quantity - quantity;
        _bornOGX(startTokenId, season);
        emit TokenBorn(sender, startTokenId, quantity, season);
    }

    function treasuryWithdraw(
        address payable address_,
        uint256 value_
    ) external onlyOwner nonReentrant {
        require(address(this).balance >= value_, "withdraw too much");
        (bool success, ) = address_.call{value: value_}("");
        if (!success) {
            revert CallFailed();
        }
    }

    function mintNFTToTeamMember(
        uint256 season,
        uint256 quantity,
        address to
    ) external onlyOwner {
        require(allowBuy, "buy disabled");
        require(quantity > 0, "quantity invalid");
        require(totalSupply() + quantity <= MAX_SUPPLY, "over max supply");
        Season storage ogxSeason = _ogxSeasons[season];
        require(ogxSeason.startTime > 0, "season not exist");
        require(
            ogxSeason.sellType == 2,
            "the season is not allowed to mint by this function"
        );
        require(
            (ogxSeason.startTime <= block.timestamp) &&
                (ogxSeason.endTime >= block.timestamp),
            "not in the sale period"
        );
        require(ogxSeason.quantity > 0, "sold out");
        require(ogxSeason.quantity >= quantity, "not enough stock");
        uint256 startTokenId = _nextTokenId();
        _mint(to, quantity);
        ogxSeason.quantity = ogxSeason.quantity - quantity;
        _bornOGX(startTokenId, season);
        emit TokenBorn(to, startTokenId, quantity, season);
    }

    function lock(uint256[] calldata tokenIds) external {
        for (uint256 index = 0; index < tokenIds.length; index++) {
            uint256 tokenId = tokenIds[index];
            _checkTokenOwner(tokenId);
            if (_lockTokens[tokenId]) {
                revert TokenIsLocked(tokenId);
            }
            _lockTokens[tokenId] = true;
            emit TokenLocked(tokenId);
        }
    }

    function unlock(uint256[] calldata tokenIds) external {
        for (uint256 index = 0; index < tokenIds.length; index++) {
            uint256 tokenId = tokenIds[index];
            _checkTokenOwner(tokenId);
            if (!_lockTokens[tokenId]) {
                revert TokenIsUnlocked(tokenId);
            }
            delete _lockTokens[tokenId];
            emit TokenUnlocked(tokenId);
        }
    }

    function getLocked(uint256 tokenId) public view virtual returns (bool) {
        if (!_exists(tokenId)) {
            revert LockQueryForNonexistentToken();
        }
        return _lockTokens[tokenId];
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (tokenId < _startTokenId() || tokenId >= _nextTokenId()) {
            return string(abi.encodePacked(_hiddenMetadataURI, "0.json"));
        } else {
            string memory uri = _findBaseURI(tokenId);
            if (bytes(uri).length == 0) {
                return string(abi.encodePacked(_hiddenMetadataURI, "0.json"));
            } else {
                return
                    string(abi.encodePacked(uri, tokenId.toString(), ".json"));
            }
        }
    }

    function openSeason(
        uint256 seasonNum,
        string calldata baseUri
    ) external onlyOwner {
        require(bytes(baseUri).length > 0, "baseUri is empty");
        require(
            bytes(seasonUriMap[seasonNum]).length == 0 || allowFixURI,
            "not allow to fix URI"
        );
        seasonUriMap[seasonNum] = baseUri;
        emit SeasonOpened(seasonNum, baseUri);
    }

    function setBaseURI(string calldata baseUri) external onlyOwner {
        require(bytes(baseUri).length > 0, "baseUri is empty");
        require(allowFixURI, "not allow to fix URI");
        for (uint i = 0; i < seasonList.length; i++) {
            uint256 seasonNum = seasonList[i];
            seasonUriMap[seasonNum] = baseUri;
            emit SeasonOpened(seasonNum, baseUri);
        }
    }

    function setHiddenMetadataURI(
        string memory hiddenMetadataURI
    ) external onlyOwner {
        _hiddenMetadataURI = hiddenMetadataURI;
        emit HiddenMetadataURISet(hiddenMetadataURI);
    }

    function setAllowBuy(bool allowBuy_) external onlyOwner {
        allowBuy = allowBuy_;
        emit AllowBuySet(allowBuy_);
    }

    function setBuyLimit(uint256 buyLimit_) external onlyOwner {
        buyLimit = buyLimit_;
        emit BuyLimitSet(buyLimit_);
    }

    function disableFixURI() external onlyOwner {
        allowFixURI = false;
        emit FixURIDisabled();
    }

    function getSeason(
        uint256 season
    ) external view returns (uint256, uint256, uint256, uint256, bool) {
        Season storage ogxSeason = _ogxSeasons[season];
        bool soldOut = (ogxSeason.quantity == 0);
        return (
            ogxSeason.sellType,
            ogxSeason.price,
            ogxSeason.startTime,
            ogxSeason.endTime,
            soldOut
        );
    }

    function setRoyaltyInfo(
        address receiver,
        uint96 feeBasisPoints
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeBasisPoints);
        emit RoyaltyInfoSet(receiver, feeBasisPoints);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    // ========= OPERATOR FILTERER OVERRIDES =========

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokens
    ) public payable onlyAllowedOperator(from) {
        for (uint256 index = 0; index < tokens.length; index++) {
            super.safeTransferFrom(from, to, tokens[index]);
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _bornOGX(uint256 startTokenId, uint256 season) private {
        _tokenSeasonMap[startTokenId] = season;
    }

    function _findBaseURI(
        uint256 tokenId
    ) internal view returns (string memory) {
        string memory foundUri;
        if (tokenId < _nextTokenId()) {
            uint256 startTokenId = _startTokenId();
            for (; tokenId >= startTokenId; tokenId--) {
                uint256 seasonNum = _tokenSeasonMap[tokenId];
                if (seasonNum > 0) {
                    foundUri = seasonUriMap[seasonNum];
                    return foundUri;
                }
            }
        }
        return foundUri;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        // if it is a Transfer or Burn, we always deal with one token, that is startTokenId
        if (from != address(0)) {
            if (_lockTokens[startTokenId]) {
                revert TokenIsLocked(startTokenId);
            }
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function _checkTokenOwner(uint256 tokenId) internal view {
        address tokenOwner = ownerOf(tokenId);
        if (msg.sender != tokenOwner) {
            revert IsNoOwner();
        }
    }
}