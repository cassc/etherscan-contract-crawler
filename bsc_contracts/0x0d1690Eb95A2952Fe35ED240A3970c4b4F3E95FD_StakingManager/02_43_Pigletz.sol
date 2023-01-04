// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IPigletz.sol";
import "./PigletWallet.sol";
import "../token/PiFiToken.sol";
import "../boosters/IBooster.sol";
import "../boosters/InvestTokensBooster.sol";
import "../boosters/InvestMultiTokensBooster.sol";
import "../boosters/CollectSameSignsBooster.sol";
import "../boosters/CollectSignsBooster.sol";
import "../boosters/CollectNumberBooster.sol";
import "../boosters/InvestMultiTokensBooster.sol";
import "../boosters/StakingBooster.sol";
import "../boosters/SpecialBooster.sol";
import "../oracle/IOracle.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract Pigletz is IPigletz, ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for bytes32;
    using Clones for address;

    uint256 constant PIPS = 10000;

    uint256 public constant SEED = 1638504306;

    uint256 constant LEVEL_2_REQUIREMENTS = 10000 ether;
    uint256 constant LEVEL_3_REQUIREMENTS = 55000 ether;

    uint256 constant MAX_MINT_PER_PIG = 2000000 ether;

    string[] IPFS_FOLDERS = [
        "QmUoYfWQCAkjw2oNvbXikEZC24Kg5oLkw4Fef49thyexmq",
        "Qmb3bJAtH9x8N5D5MkDaXGSTKooyDNpoihuZzR7sEsgRp3",
        "QmPAoRPzkkXwXJ34EaFGQmRUY3F8W4p3gnyhn9ga56QFc6",
        "QmaErGy2B71Jsn7aaCnbrChoSiWDR32KezrNEwHgZASmnz"
    ];
    string CELEBRITY_FOLDER = "QmPLLwf4miKgFnxwgrp8uq4z9FnaNV6rTvR5MmrRHR2GFi";

    uint256 _regularTokens;
    uint256 _celebrityTokens;

    // @todo Add a better documentation for this
    uint256[] _mintingRatePerDay = [167 ether, 250 ether, 417 ether, 500 ether];

    uint256 constant MAX_TOKENS = 12345;
    uint256 internal nonce = 0;
    uint256[MAX_TOKENS] internal _indexes;
    mapping(uint256 => uint8) private _levels;
    mapping(uint256 => IPigletWallet) private _wallets;
    mapping(uint256 => uint256) private _mintedAmount;
    mapping(uint256 => uint256) private _lastMintTime;

    IBooster[] private _boosters;
    IOracle _oracle;
    PiFiToken _token;
    address _staker;
    address _portal;
    uint256 _numRegularMinted;
    uint256 _numCelebrityMinted;
    mapping(uint256 => bool) _special;
    SpecialBooster _specialBooster;
    mapping(address => bool) _minters;

    PigletWallet _walletLibrary;

    constructor(
        IOracle oracle,
        PiFiToken token,
        uint256 regularTokens,
        uint256 celebrityTokens
    ) ERC721("Pigletz", "PIGZ") {
        _boosters = [
            IBooster(new InvestTokensBooster(this, 1000, 100 ether, 1)), // Invest 100
            new InvestTokensBooster(this, 3000, 500 ether, 2), // Invest 500
            new InvestTokensBooster(this, 10000, 2000 ether, 3), // Invest 2000
            new CollectNumberBooster(this, 2000, 3, 1), // Collect 3
            new CollectNumberBooster(this, 3000, 7, 2), // Collect 7
            new InvestMultiTokensBooster(this, oracle, address(token), 1000, 3, 1), // Invest 3
            new InvestMultiTokensBooster(this, oracle, address(token), 2000, 7, 3), // Invest 7
            new CollectSameSignsBooster(this, 3000, 3, 1), // Collect 3 same
            new CollectSignsBooster(this, 8000, 12, 3), // Collect 12 different
            new StakingBooster(this, 5000), // Stake Booster
            new SpecialBooster(this, 5000) // Special Booster
        ];
        _oracle = oracle;
        _token = token;
        _regularTokens = regularTokens;

        _celebrityTokens = celebrityTokens;
        _walletLibrary = new PigletWallet();
    }

    function addMinter(address minter) public onlyOwner {
        _minters[minter] = true;
    }

    function removeMinter(address minter) public onlyOwner {
        delete _minters[minter];
    }

    modifier onlyMinter() {
        require(_minters[msg.sender], "Only minters can mint");
        _;
    }
    modifier validToken(uint256 tokenId) {
        require(_exists(tokenId), "Token does not exist");
        _;
    }

    modifier onlyPortal() {
        require(msg.sender == _portal, "Only portal can do this");
        require(_portal != address(0), "Portal is not set");
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(msg.sender == ownerOf(tokenId), "Only token owner can do this");
        _;
    }

    function maxSupply() public view override returns (uint256) {
        return _regularTokens + _celebrityTokens;
    }

    function _checkSaleEnded() internal {
        if (tokenCount() >= maxSupply()) {
            emit SaleEnded(maxSupply(), address(this).balance);
        }
    }

    function tokenCount() public view override returns (uint256) {
        return _numRegularMinted + _numCelebrityMinted;
    }

    function _randomIndex() internal returns (uint256) {
        uint256 totalSize = _regularTokens - _numRegularMinted;

        uint256 index = uint256(
            keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, blockhash(block.number)))
        ) % totalSize;
        uint256 value = 0;
        if (_indexes[index] != 0) {
            value = _indexes[index];
        } else {
            value = index;
        }

        if (_indexes[totalSize - 1] == 0) {
            _indexes[index] = totalSize - 1;
        } else {
            _indexes[index] = _indexes[totalSize - 1];
        }
        nonce++;
        return value.add(1);
    }

    function getSign(uint256 tokenId) public pure override returns (ZodiacSign) {
        bytes32 signHash = keccak256(abi.encode(SEED, tokenId));
        return ZodiacSign(uint256(signHash) % 12);
    }

    function _isSpecial(uint256 probability) internal view returns (bool) {
        uint256 random = uint256(
            keccak256(abi.encodePacked(_numRegularMinted, msg.sender, block.difficulty, blockhash(block.number)))
        ) % PIPS;
        return random < probability;
    }

    function mint(
        address to,
        uint256 amount,
        uint256 probability
    ) external override onlyMinter {
        require(amount + _numRegularMinted <= _regularTokens, "Not enough tokens left");

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = _randomIndex();

            _numRegularMinted++;

            _createPiglet(to, tokenId, 1, _isSpecial(probability));
        }
        _checkSaleEnded();
    }

    function isCelebrity(uint256 tokenId) public view override returns (bool) {
        return tokenId > _regularTokens;
    }

    function _createWallet(uint256 tokenId) internal returns (IPigletWallet) {
        address clone = Clones.cloneDeterministic(address(_walletLibrary), bytes32(tokenId));
        IPigletWallet(clone).init(_oracle);
        return IPigletWallet(clone);
    }

    function _createPiglet(
        address to,
        uint256 tokenId,
        uint8 level,
        bool special
    ) internal {
        _mint(to, tokenId);
        IPigletWallet wallet = _createWallet(tokenId);
        _wallets[tokenId] = wallet;
        _levels[tokenId] = level;
        _lastMintTime[tokenId] = block.timestamp;
        _special[tokenId] = special;
    }

    function mintCelebrities(address to) external override onlyMinter {
        for (uint256 i = 0; i < _celebrityTokens; i++) {
            uint256 tokenId = _regularTokens + i + 1;

            _createPiglet(to, tokenId, 3, true);
            _numCelebrityMinted++;
        }

        _checkSaleEnded();
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    function tokenURI(uint256 tokenId) public view override validToken(tokenId) returns (string memory uri) {
        if (isCelebrity(tokenId)) {
            return string(abi.encodePacked(_baseURI(), CELEBRITY_FOLDER, "/", Strings.toString(tokenId)));
        }

        bytes32 jsonHash = keccak256(abi.encode(SEED, tokenId, getLevel(tokenId), getSign(tokenId)));

        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    IPFS_FOLDERS[getLevel(tokenId) - 1],
                    "/",
                    Strings.toHexString(uint256(jsonHash), 32)
                )
            );
    }

    function _getTokenBalance(uint256 tokenId) internal view validToken(tokenId) returns (uint256) {
        uint256 balance = _token.balanceOf(address(getWallet(tokenId)));
        balance += _getUnmintedTokens(tokenId);
        return balance;
    }

    function getTotalBoost(uint256 tokenId) public view validToken(tokenId) returns (uint256) {
        uint256 percentage = 0;
        for (uint256 i = 0; i < _boosters.length; i++) {
            if (_boosters[i].isBoosted(tokenId)) {
                percentage += _boosters[i].getBoost();
            }
        }
        return percentage;
    }

    function getDailyMintingAmount(uint256 tokenId) public view validToken(tokenId) returns (uint256) {
        uint8 level = getLevel(tokenId);
        uint256 mintingRatePerDay = _mintingRatePerDay[level - 1];
        uint256 mintingAmount = mintingRatePerDay;
        mintingAmount += ((mintingAmount * getTotalBoost(tokenId)) / PIPS);
        return mintingAmount;
    }

    function _getUnmintedTokens(uint256 tokenId) private view returns (uint256) {
        uint256 lastMintTime = _lastMintTime[tokenId];
        uint256 daysMinting = (block.timestamp - lastMintTime) / 24 hours;
        uint256 balance = getDailyMintingAmount(tokenId) * daysMinting;

        return Math.min(balance, MAX_MINT_PER_PIG - _mintedAmount[tokenId]);
    }

    function getEligibleLevel(uint256 tokenId) public view returns (uint8) {
        uint256 balance = _getTokenBalance(tokenId);

        if (balance >= LEVEL_3_REQUIREMENTS) {
            return 3;
        }

        if (balance >= LEVEL_2_REQUIREMENTS) {
            return 2;
        }
        return 1;
    }

    function updatePiFiBalance(uint256 tokenId) external override {
        _mintPiFi(tokenId);
    }

    function _mintPiFi(uint256 tokenId) internal {
        uint256 tokensToMint = _getUnmintedTokens(tokenId);
        if (tokensToMint > 0) {
            IPigletWallet wallet = getWallet(tokenId);
            _token.mint(address(wallet), tokensToMint);
            _mintedAmount[tokenId] += tokensToMint;

            wallet.registerDeposit(address(_token));

            _lastMintTime[tokenId] = block.timestamp;
        }
    }

    function levelUp(uint256 tokenId) external validToken(tokenId) onlyTokenOwner(tokenId) {
        uint8 level = getLevel(tokenId);
        uint8 eligibleLevel = getEligibleLevel(tokenId);

        if (level >= eligibleLevel) {
            return;
        }

        _mintPiFi(tokenId);

        _levels[tokenId] = eligibleLevel;

        emit LevelUp(tokenId, eligibleLevel, msg.sender);
    }

    function getLevel(uint256 tokenId) public view override validToken(tokenId) returns (uint8) {
        return _levels[tokenId];
    }

    function getWallet(uint256 tokenId) public view override validToken(tokenId) returns (IPigletWallet) {
        return _wallets[tokenId];
    }

    // TODO: Improve this one so it can return a specified booster
    function getBoosters() external view returns (IBooster[] memory) {
        return _boosters;
    }

    function getBoosterStatuses(uint256 tokenId) external view returns (IBooster.Status[] memory) {
        IBooster.Status[] memory statuses = new IBooster.Status[](_boosters.length);
        for (uint256 i = 0; i < _boosters.length; i++) {
            statuses[i] = _boosters[i].getStatus(tokenId);
        }
        return statuses;
    }

    function burn(uint256 tokenId) external override validToken(tokenId) onlyTokenOwner(tokenId) {
        require(getLevel(tokenId) > 1, "Cannot burn level 1 piglets");

        _mintPiFi(tokenId);

        getWallet(tokenId).destroy(msg.sender);

        _burn(tokenId);
    }

    //todo: set staker and portal as approved for all tokens?
    function setStaker(address staker) external override onlyOwner {
        require(_staker == address(0), "Staker already set");
        _staker = staker;
    }

    function setMetaversePortal(address portal) external override onlyOwner {
        require(_portal == address(0), "Portal already set");
        _portal = portal;
    }

    function getMetaversePortal() public view override returns (address) {
        return _portal;
    }

    function materialize(uint256 tokenId) external override validToken(tokenId) onlyTokenOwner(tokenId) onlyPortal {
        require(getLevel(tokenId) == 3, "Can materialize only level 3 piglets");

        _mintPiFi(tokenId);

        _levels[tokenId] = 4;

        emit Materialized(tokenId);
    }

    function digitalize(uint256 tokenId) external override validToken(tokenId) onlyTokenOwner(tokenId) onlyPortal {
        require(getLevel(tokenId) == 4, "Can digitalize only level 4 piglets");

        _mintPiFi(tokenId);

        _levels[tokenId] = 3;

        emit Digitalized(tokenId);
    }

    function getStaker() external view override returns (address) {
        return _staker;
    }

    function isSpecial(uint256 tokenId) external view override validToken(tokenId) returns (bool) {
        return _special[tokenId] || isCelebrity(tokenId);
    }

    function getPiFiBalance(uint256 tokenId) public view validToken(tokenId) returns (uint256, uint256) {
        uint256 pifiBalance = _getTokenBalance(tokenId);
        uint256 pifiBalanceInUSD = _oracle.getTokenUSDPrice(address(_token), pifiBalance);
        return (pifiBalance, pifiBalanceInUSD);
    }

    function _createTokenData(address token, uint256 balance) private view returns (TokenData memory) {
        return TokenData(token, balance, _oracle.getTokenUSDPrice(token, balance));
    }

    function getInvestments(uint256 tokenId) external view returns (TokenData[] memory) {
        IPigletWallet wallet = getWallet(tokenId);
        IPigletWallet.TokenData[] memory investedTokens = wallet.listTokens();
        uint256 size = investedTokens.length + 1;
        if (address(wallet).balance > 0) {
            size++;
        }

        uint256 index = 0;
        TokenData[] memory prices = new TokenData[](size);
        prices[index] = _createTokenData(address(_token), _getTokenBalance(tokenId));
        for (uint256 i = 0; i < investedTokens.length; i++) {
            // making sure not to count PiFis deposited in the wallet twice
            if (investedTokens[i].token != address(_token)) {
                index++;
                prices[index] = _createTokenData(investedTokens[i].token, investedTokens[i].balance);
            }
        }

        if (address(wallet).balance > 0) {
            index++;
            prices[index].token = address(0);
            prices[index].balance = address(wallet).balance;
            prices[index].balanceInUSD = _oracle.getNativeTokenPrice(address(wallet).balance);
        }

        //trimming the size of the token if there were duplicated tokens
        if (index != size - 1) {
            TokenData[] memory temp = new TokenData[](index + 1);
            for (uint256 i = 0; i <= index; i++) {
                temp[i] = prices[i];
            }
            prices = temp;
        }
        return prices;
    }

    function getPigletData(uint256 tokenId) public view validToken(tokenId) returns (PigletData memory) {
        (uint256 pifiBalance, uint256 pifiBalanceInUSD) = getPiFiBalance(tokenId);
        PigletData memory data = PigletData(
            tokenURI(tokenId),
            tokenId,
            getLevel(tokenId),
            getEligibleLevel(tokenId),
            pifiBalance,
            getWallet(tokenId).getBalanceInUSD() + pifiBalanceInUSD,
            getDailyMintingAmount(tokenId),
            getTotalBoost(tokenId),
            getWallet(tokenId)
        );
        return data;
    }

    function pigletzByOwner(
        address pigletzOwner,
        uint256 start,
        uint256 limit
    ) external view returns (PigletData[] memory) {
        uint256 total = balanceOf(pigletzOwner);
        require(start <= total, "Start index must be less than or equal to total pigletz");
        uint256 end = start + limit;

        if (start == 0 && limit == 0) {
            end = total;
        }
        uint256 size = Math.min(total, end) - start;
        PigletData[] memory pigletz = new PigletData[](size);
        for (uint256 i = start; i < start + size; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(pigletzOwner, i);
            pigletz[i - start] = getPigletData(tokenId);
        }
        return pigletz;
    }

    function registerDeposit(uint256 tokenId, address token) public validToken(tokenId) onlyTokenOwner(tokenId) {
        IPigletWallet wallet = getWallet(tokenId);
        wallet.registerDeposit(token);
    }

    function deposit(
        uint256 tokenId,
        address sender,
        address token,
        uint256 amount
    ) public validToken(tokenId) onlyTokenOwner(tokenId) {
        IPigletWallet wallet = getWallet(tokenId);
        wallet.deposit(token, sender, amount);
    }
}