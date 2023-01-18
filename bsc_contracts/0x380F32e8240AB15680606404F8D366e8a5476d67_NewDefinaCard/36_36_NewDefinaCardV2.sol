// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./CommonUtils.sol";
import {TokenInfo, MintInfo, MergeInfo} from "./NewDefinaCardStructs.sol";
import {IDefinaCard} from "./NewDefinaCardInterface.sol";
import {NewDefinaCardEventsAndErrors} from "./NewDefinaCardEventsAndErrors.sol";


contract NewDefinaCard is ERC721EnumerableUpgradeable, OwnableUpgradeable, NewDefinaCardEventsAndErrors {

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    address public mergerOperator;

    modifier whenClaimableActive() {
        require(claimableActive, "Claimable state is not active");
        _;
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "DefinaCard: not eoa");
        _;
    }
    modifier onlyOperator() {
        require(mergerOperator == msg.sender, "Only operator can call this method");
        _;
    }
    modifier whenPublicSaleActive() {
        require(publicSaleActive, "Public sale is not active");
        _;
    }
    modifier whenMergerActive() {
        require(mergeActive, "Merge is not active");
        _;
    }


    function setMergerOperator(address newMergerOperator_) external onlyOwner {
        if (newMergerOperator_ == address(0)) {
            revert AddressIsNull();
        }
        mergerOperator = newMergerOperator_;
    }
    // old rarity => new rarity
    mapping(uint => uint) private rarityRarityMap;
    // token => heroId
    mapping(uint => uint) public heroIdMap;
    // token => rarity
    mapping(uint => uint) public rarityMap;
    // rarity => no okex heroIds
    mapping(uint => uint[]) public rarityNoOkexHeroIdsMap;
    //[B,A,S,S+,SS,SS+,SSS,SSS+,X]
    uint private maxRarity;

    //MINT
    uint gasForDestinationLzReceive;
    uint256 public MAX_MINT;
    bool public publicSaleActive;
    address public currTokenAddress;
    uint public nftPrice;
    uint256 public mintIndexPublicSale;
    mapping(uint256 => bool) public forMint;
    mapping(uint256 => MintInfo) public mintMap;
    uint256 public maxFreeMintPerAddress;
    mapping(address => uint256) public freeMintMap;

    uint256[][] mintRarityScale;

    //CLAIM
    bool public claimableActive;
    IDefinaCard public nftA;
    mapping(uint256 => bool) public claimed;
    uint256 private maxClaimedAmount;

    //MERGE
    uint256 public worldCupPrizePool;
    address public worldCupAddress;
    bool public mergeActive;
    mapping(uint256 => bool) public forMerge;
    mapping(uint256 => MergeInfo) public mergeMap;
    //rarity=>scales
    mapping(uint => uint) private rarityScalesMap;
    //rarity=>base merge price
    mapping(uint => uint) public rarityMergePriceMap;
    //rarity=>directional merge price
    mapping(uint => uint) public rarityDirectionalPriceMap;
    address public mergeTokenAddress;
    // mergeIds
    EnumerableSetUpgradeable.UintSet private mintIds;
    EnumerableSetUpgradeable.UintSet private mergeIds;

    //whitelist
    mapping(address => uint256[3]) public whitelistInfos; // user => uint256[3]

    function initialize(IDefinaCard nftA_, uint nftAmount_, uint[][] calldata _rarityHeroIds, uint[] calldata _oldCardRarities) external initializer {
        __ERC721_init_unchained("Defina Card", "DEFINACARD");
        __ERC721Enumerable_init_unchained();
        __Ownable_init();

        mergerOperator = _msgSender();

        gasForDestinationLzReceive = 350000;
        MAX_MINT = 196000;
        maxFreeMintPerAddress = 4;
        mintRarityScale = [[2,60],[3,40]];

        require(nftAmount_ < MAX_MINT);
        nftA = nftA_;
        maxClaimedAmount = nftAmount_;
        mintIndexPublicSale = nftAmount_;
        setOldCardSetting(_oldCardRarities);
        setRarityHeroIds(_rarityHeroIds);
    }

    function setRarityHeroIds(uint[][] calldata _rarityHeroIds) onlyOwner public {
        if (_rarityHeroIds.length == 0) {
            revert ArrayIsNull();
        }
        maxRarity = _rarityHeroIds.length;
        //remove
        for (uint i = 0; i < maxRarity; i++) {
            delete rarityNoOkexHeroIdsMap[i + 1];
            rarityNoOkexHeroIdsMap[i + 1] = _rarityHeroIds[i];
        }
    }

    function setOldCardSetting(uint[] calldata _oldCardRarities) onlyOwner public {
        if (_oldCardRarities.length == 0) {
            revert ArrayIsNull();
        }
        for (uint i = 0; i < _oldCardRarities.length; i++) {
            uint oldRarity = i + 1;
            uint newRarity = _oldCardRarities[i];
            rarityRarityMap[oldRarity] = newRarity;
        }
    }

    // Public Sale Methods
    function startPublicSale(
        address _currTokenAddress,
        uint256 _nftPrice
    ) onlyOwner external {

        if (_nftPrice == 0) {
            revert PriceIsZero();
        }

        currTokenAddress = _currTokenAddress;
        nftPrice = _nftPrice;
        publicSaleActive = true;
    }

    function stopPublicSale() onlyOwner whenPublicSaleActive external {
        publicSaleActive = false;
    }

    function addMint(uint amount_, bool forWhitelist_) external whenPublicSaleActive onlyEOA payable {
        if (amount_ == 0 || amount_ > 10) {
            revert WrongAmount();
        }
        if (mintIndexPublicSale + amount_ > MAX_MINT) {
            revert MintExceedsSupply();
        }

        uint256 price = nftPrice;
        if (forWhitelist_) {
            uint256[3] storage whitelistInfo = whitelistInfos[_msgSender()];
            require(whitelistInfo[1] >= amount_, "Exceeds whitelist mint amount");
            whitelistInfo[1] -= amount_;
            price = whitelistInfo[2];
        }

        if (currTokenAddress == address(0)) {
            require(msg.value >= price * amount_, "Action underpriced");
        } else {
            IERC20Upgradeable currToken = IERC20Upgradeable(currTokenAddress);
            currToken.transferFrom(_msgSender(), address(this), price * amount_);
        }

        uint256 startId = mintIndexPublicSale;
        for (uint i = 0; i < amount_; ++i) {
            uint tokenId = startId++;
            _safeMint(_msgSender(), tokenId);
        }

        forMint[mintIndexPublicSale] = true;
        mintMap[mintIndexPublicSale] = MintInfo({
            tokenId: mintIndexPublicSale,
            amount: amount_,
            user: _msgSender(),
            forWhitelist: forWhitelist_
        });
        mintIds.add(mintIndexPublicSale);
        emit AddMint(mintIndexPublicSale, amount_, forWhitelist_, _msgSender());
        mintIndexPublicSale += amount_;
    }

    function toMint(uint256 mintStartTokenId, uint256 amount_, bool forWhitelist_, bytes32 randomness_, bytes32 transactionHash) external onlyOperator {
        require(forMint[mintStartTokenId] == true, "This tokenId group has been minted");
        MintInfo storage mintInfo = mintMap[mintStartTokenId];
        address user = mintInfo.user;
        uint256 startId = mintStartTokenId;

        for (uint i = 0; i < amount_; ++i) {
            uint rarity;
            if(forWhitelist_){
                rarity = whitelistInfos[mintInfo.user][0];
            }else{
                rarity = CommonUtils.getMintResult(mintRarityScale, mintInfo.user, randomness_, transactionHash[i]);
            }
            uint tokenId = startId++;
            uint heroId = CommonUtils.getHeroBySeed(rarityNoOkexHeroIdsMap[rarity], mintInfo.user, randomness_, transactionHash, i);
            rarityMap[tokenId] = rarity;
            heroIdMap[tokenId] = heroId;
        }

        delete forMint[mintStartTokenId];
        delete mintMap[mintStartTokenId];
        mintIds.remove(mintStartTokenId);
        emit MintSuccess(mintStartTokenId, amount_, forWhitelist_, user, transactionHash);
    }

    function freeMultiMint(uint amount_, uint heroId_, uint rarity_) whenPublicSaleActive onlyEOA external {
        if (amount_ == 0 || amount_ > 10) {
            revert WrongAmount();
        }
        if (mintIndexPublicSale + amount_ > MAX_MINT) {
            revert MintExceedsSupply();
        }
        uint rarity = 1;
        uint heroId;
        if(_msgSender() == mergerOperator){
            rarity = rarity_;
        }else{
            require(freeMintMap[_msgSender()] + amount_ <= maxFreeMintPerAddress, "Reached max free mint amount");
        }
        for (uint i = 0; i < amount_; ++i) {
            uint tokenId = mintIndexPublicSale++;
            if(_msgSender() == mergerOperator){
                heroId = heroId_;
            }else{
                heroId = CommonUtils.getHeroByRand(rarityNoOkexHeroIdsMap[rarity], _msgSender(), i);
            }

            rarityMap[tokenId] = rarity;
            heroIdMap[tokenId] = heroId;
            _safeMint(_msgSender(), tokenId);
        }
        freeMintMap[_msgSender()] += amount_;
        emit MintMulti(_msgSender(), amount_);
    }

    function setNftA(IDefinaCard nftA_) onlyOwner external {
        nftA = nftA_;
    }

    //Claim Methods
    function changeClaimableState() onlyOwner external {
        claimableActive = !claimableActive;
    }

    function nftOwnerClaimCards(uint256[] calldata tokenIds) whenClaimableActive onlyEOA external {
        for (uint256 i; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            if (claimed[tokenId] == true) {
                revert AlreadyClaimed();
            }
            if (nftA.ownerOf(tokenId) != _msgSender()) {
                revert NotTheOwner();
            }
            if (tokenId >= maxClaimedAmount) {
                revert NotAllowedClaim();
            }
            claimLandByTokenId(tokenId);
        }
    }

    function claimLandByTokenId(uint256 tokenId) private {
        claimed[tokenId] = true;
        _safeMint(_msgSender(), tokenId);
        uint cardId_ = nftA.cardIdMap(tokenId);
        (uint cardId, uint camp, uint rarity, string memory name, uint currentAmount, uint maxAmount, string memory cardURI) = nftA.cardInfoes(cardId_);
        rarityMap[tokenId] = rarityRarityMap[rarity];
        uint heroId = CommonUtils.stringToUint(cardURI);
        heroIdMap[tokenId] = heroId;
    }

    function getClaimableCards(uint256[] calldata tokenIds) view external returns (uint256[] memory){
        return CommonUtils.getClaimableCards(tokenIds, claimed);
    }
    // Merge Methods
    function startMerge(address _mergeTokenAddress, address _worldCupAddress, uint[] calldata _mergePrices, uint[] calldata _directionalPrices, uint[] calldata rarityScales
    ) onlyOwner external {
        if (mergeActive) {
            revert MergeHasAlreadyBegun();
        }
        if (_mergePrices.length != (maxRarity - 1) || _directionalPrices.length != (maxRarity - 1) || rarityScales.length != (maxRarity - 1)) {
            revert ArrayLengthError();
        }

        mergeTokenAddress = _mergeTokenAddress;
//        worldCupAddress = _worldCupAddress;
        mergeActive = true;
        //remove previous quota first
        for (uint i = 0; i < _mergePrices.length; ++i) {
            rarityMergePriceMap[i + 1] = _mergePrices[i];
        }
        //remove previous quota first
        for (uint i = 0; i < _directionalPrices.length; ++i) {
            rarityDirectionalPriceMap[i + 1] = _directionalPrices[i];
        }
        //remove previous quota first
        for (uint i = 0; i < rarityScales.length; ++i) {
            rarityScalesMap[i + 1] = rarityScales[i];
        }
    }

    function stopMerge() onlyOwner whenMergerActive external {
        mergeActive = false;
    }


    function addMerge(uint tokenIdA, uint tokenIdB, uint price) payable onlyEOA whenMergerActive external {
        if (!_isApprovedOrOwner(_msgSender(), tokenIdA) || !_isApprovedOrOwner(_msgSender(), tokenIdB)) {
            revert NotApprovedOrOwner();
        }
        if (tokenIdA == tokenIdB || rarityMap[tokenIdA] != rarityMap[tokenIdB] || rarityMap[tokenIdA] >= maxRarity) {
            revert NotMeetMergeRules();
        }
        if (forMerge[tokenIdA] || forMerge[tokenIdB]) {
            revert AlreadyMerging();
        }

        uint basePrice = rarityMergePriceMap[rarityMap[tokenIdA]];
        if (price < basePrice) {
            revert WrongAmount();
        }

        if(mergeTokenAddress == address(0)){
            require(msg.value >= price, 'Action underpriced');
        }else{
            IERC20Upgradeable mergeToken = IERC20Upgradeable(mergeTokenAddress);
            mergeToken.safeTransferFrom(_msgSender(), address(this), price);
        }
//        worldCupPrizePool += price;

        forMerge[tokenIdA] = true;
        forMerge[tokenIdB] = true;
        mergeMap[tokenIdA] = MergeInfo({
            tokenIdA : tokenIdA,
            tokenIdB : tokenIdB,
            user : _msgSender(),
            price : price,
            blockNumber : block.number
        });
        mergeIds.add(tokenIdA);

        if (address(mergerOperator) != _msgSender()) {
            approve(address(mergerOperator), tokenIdA);
            approve(address(mergerOperator), tokenIdB);
        }
        emit AddMerge(tokenIdA, tokenIdB, _msgSender(), block.number);
    }


    function toMerge(uint tokenIdA, bytes32 randomness_, bytes32 transactionHash) external onlyOperator{
        MergeInfo storage mergeInfo = mergeMap[tokenIdA];
        uint256 tokenIdB = mergeInfo.tokenIdB;
        address user = mergeInfo.user;
        if (mergeInfo.tokenIdA != tokenIdA) {
            revert MergeInfoError();
        }
        if (!_isApprovedOrOwner(_msgSender(), tokenIdA) || !_isApprovedOrOwner(_msgSender(), mergeInfo.tokenIdB)) {
            revert NotApprovedOrOwner();
        }
        bool mergeResult = CommonUtils.getMergeResult(rarityScalesMap[rarityMap[tokenIdA]], mergeInfo.user, randomness_, transactionHash);
        if (mergeResult) {
            uint directionalPrice = rarityDirectionalPriceMap[rarityMap[tokenIdA]];

            uint newRarity = rarityMap[tokenIdA] + 1;
            rarityMap[tokenIdA] = newRarity;

            if (mergeInfo.price < directionalPrice) {
                uint heroId = CommonUtils.getHeroBySeed(rarityNoOkexHeroIdsMap[newRarity], mergeInfo.user, randomness_, transactionHash, 0);
                heroIdMap[tokenIdA] = heroId;
            }
            burn(mergeInfo.tokenIdB);
        }
        //delete Merge record
        delete forMerge[tokenIdA];
        delete forMerge[mergeInfo.tokenIdB];
        delete mergeMap[tokenIdA];
        mergeIds.remove(tokenIdA);
        emit MergeSuccess(tokenIdA, tokenIdB, user, rarityMap[tokenIdA], heroIdMap[tokenIdA], mergeResult, transactionHash);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        if (from != to) {
            if (forMerge[tokenId]) {
                uint length = mergeIds.length();
                uint tokenA;
                uint tokenB;
                for (uint i = 0; i < length; i++) {
                    if(tokenId == mergeIds.at(i)){
                        //tokenA
                        tokenA = tokenId;
                        tokenB = mergeMap[tokenId].tokenIdB;
                        break;
                    }
                    if(tokenId == mergeMap[mergeIds.at(i)].tokenIdB){
                        //tokenB
                        tokenB = tokenId;
                        tokenA = mergeIds.at(i);
                        break;
                    }
                }
                delete forMerge[tokenA];
                delete forMerge[tokenB];
                delete mergeMap[tokenA];
                mergeIds.remove(tokenA);
            }
        }
    }

    function burn(uint tokenId_) public returns (bool){
        if (!_isApprovedOrOwner(_msgSender(), tokenId_)) {
            revert NotApprovedOrOwner();
        }
        delete rarityMap[tokenId_];
        delete heroIdMap[tokenId_];
        _burn(tokenId_);
        emit Burn(tokenId_);
        return true;
    }

    function getTokenInfosByAddress(address who) view external returns (TokenInfo[] memory) {
        require(who != address(0));
        uint length = balanceOf(who);

        TokenInfo[] memory tmp = new TokenInfo[](length);
        for (uint i = 0; i < length; i++) {
            uint tokenId = tokenOfOwnerByIndex(who, length - i - 1);
            tmp[i] = TokenInfo({
            tokenId : tokenId,
            heroId : heroIdMap[tokenId],
            rarity : rarityMap[tokenId]
            });
        }
        return tmp;
    }

    function getMintInfos() view external returns (MintInfo[] memory) {
        uint length = mintIds.length();
        MintInfo[] memory tmp = new MintInfo[](length);
        for (uint i = 0; i < length; i++) {
            tmp[i] = mintMap[mintIds.at(i)];
        }
        return tmp;
    }

    function getMergeInfos() view external returns (MergeInfo[] memory) {
        uint length = mergeIds.length();
        MergeInfo[] memory tmp = new MergeInfo[](length);
        for (uint i = 0; i < length; i++) {
            tmp[i] = mergeMap[mergeIds.at(i)];
        }
        return tmp;
    }

    function getHeroIds(uint256[] calldata tokenIds) view external returns (uint256[] memory, uint256[] memory) {
        uint256[] memory heroIds = new uint256[](tokenIds.length);
        uint256[] memory rarities = new uint256[](tokenIds.length);
        for (uint i = 0; i < tokenIds.length; i++) {
            heroIds[i] = heroIdMap[tokenIds[i]];
            rarities[i] = rarityMap[tokenIds[i]];
        }
        return (heroIds, rarities);
    }

    function setWhitelistInfo(
        address[] calldata whitelistAddresses,
        uint256[] calldata rarity,
        uint256[] calldata remainingAmount,
        uint256[] calldata price
    ) external onlyOperator {
        if (
            whitelistAddresses.length != rarity.length ||
            rarity.length != remainingAmount.length ||
            remainingAmount.length != price.length
        ) {
            revert ArrayLengthError();
        }

        for (uint256 i = 0; i < whitelistAddresses.length; i++) {
            uint256[3] storage whitelist = whitelistInfos[
                whitelistAddresses[i]
            ];
            whitelist[0] = rarity[i];
            whitelist[1] = remainingAmount[i];
            whitelist[2] = price[i];
        }
    }

    function pullFunds(address tokenAddress_) external onlyOwner {
        if (tokenAddress_ == address(0)) {
            payable(_msgSender()).transfer(address(this).balance);
        } else {
            IERC20Upgradeable token = IERC20Upgradeable(tokenAddress_);
            token.transfer(_msgSender(), token.balanceOf(address(this)));
        }
    }

    function pullNFTs(address tokenAddress, address receivedAddress, uint amount) onlyOwner public {
        require(receivedAddress != address(0));
        require(tokenAddress != address(0));
        uint balance = IERC721(tokenAddress).balanceOf(address(this));
        if (balance < amount) {
            amount = balance;
        }
        for (uint i = 0; i < amount; i++) {
            uint tokenId = IERC721Enumerable(tokenAddress).tokenOfOwnerByIndex(address(this), 0);
            IERC721(tokenAddress).transferFrom(address(this), receivedAddress, tokenId);
        }
    }

    function setMaxMint(uint amount) onlyOwner public {
        MAX_MINT = amount;
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        require(_exists(tokenId_), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked("https://hero-api.defina.finance/cards/", heroIdMap[tokenId_].toString(), '/', rarityMap[tokenId_].toString()));
    }
}