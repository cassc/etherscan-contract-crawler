// SPDX-License-Identifier: MIT


pragma solidity 0.8.14;

// For Remix
 import "[email protected]/contracts/ERC721A.sol";
 import "[email protected]/contracts/extensions/ERC721AQueryable.sol";

// For Local
// import "erc721a/contracts/ERC721A.sol";
// import "erc721a/contracts/extensions/ERC721AQueryable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./DIGI.sol";

contract NFT is ERC721A("Digi Collect Labs", "DCL"), ERC2981, Ownable, ERC721AQueryable {
    // Variables
    uint256 public constant maxSupply = 10000;

    uint256 public maxDigiCollectPerWallet = 300;
    uint256 public digiCollectPrice = 0.01 ether;
    uint256 public saleActiveTime = type(uint256).max; // sale is closed by default

    string digiCollectImages;

    // these lines are called only once when the contract is deployed
    constructor() {
        autoApproveMarketplace(0x1E0049783F008A0085193E00003D00cd54003c71); // OpenSea
        autoApproveMarketplace(0xDef1C0ded9bec7F1a1670819833240f027b25EfF); // Coinbase
        autoApproveMarketplace(0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e); // LooksRare
        autoApproveMarketplace(0x4feE7B061C97C9c496b01DbcE9CDb10c02f0a0Be); // Rarible
        autoApproveMarketplace(0xF849de01B080aDC3A814FaBE1E2087475cF2E354); // X2y2
    }

    // Airdrop DigiCollect
    function giftDigiCollect(address[] memory _sendNftsTo, uint256 _digiCollectQty)
        external
        onlyOwner
        digiCollectAvailable(_sendNftsTo.length * _digiCollectQty)
    {
        for (uint256 i = 0; i < _sendNftsTo.length; i++) _safeMint(_sendNftsTo[i], _digiCollectQty);
    }

    // withdraw eth
    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    // setters
    function setDigiCollectPrice(uint256 _digiCollectPrice) external onlyOwner {
        digiCollectPrice = _digiCollectPrice;
    }

    function setMaxDigiCollectPerWallet(uint256 _maxDigiCollectPerWallet) external onlyOwner {
        maxDigiCollectPerWallet = _maxDigiCollectPerWallet;
    }

    function setSaleActiveTime(uint256 _saleActiveTime) external onlyOwner {
        saleActiveTime = _saleActiveTime;
    }

    function setDigiCollectImages(string memory _digiCollectImages) external onlyOwner {
        digiCollectImages = _digiCollectImages;
    }

    function setRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    // System Related
    function _baseURI() internal view override returns (string memory) {
        return digiCollectImages;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Helper Modifiers
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is a sm");
        _;
    }

    modifier saleActive(uint256 _saleActiveTime) {
        require(block.timestamp > _saleActiveTime, "Nope, sale is not open");
        _;
    }

    modifier mintLimit(uint256 _digiCollectQty, uint256 _maxDigiCollectPerWallet) {
        require(
            _numberMinted(msg.sender) + _digiCollectQty <= _maxDigiCollectPerWallet,
            "DigiCollect max x wallet exceeded"
        );
        _;
    }

    modifier digiCollectAvailable(uint256 _digiCollectQty) {
        require(_digiCollectQty + totalSupply() <= maxSupply, "Currently are sold out");
        _;
    }

    // Price Module:
    uint256 public nftSoldPacketSize = 200;

    function set_nftSoldPacketSize(uint256 _nftSoldPacketSize) external onlyOwner {
        nftSoldPacketSize = _nftSoldPacketSize;
    }

    uint256 public priceIncrease = 0.005 ether;

    function set_priceIncrease(uint256 _priceIncrease) external onlyOwner {
        priceIncrease = _priceIncrease;
    }

    uint256 commission = 20; // % commission

    function set_commission(uint256 _commission) external onlyOwner {
        commission = _commission;
    }

    uint256 blocksPerDay = 6400;

    function set_blocksPerDay(uint256 _blocksPerDay) external onlyOwner {
        blocksPerDay = _blocksPerDay;
    }

    function getPrice(uint256 _qty) public view returns (uint256 priceNow) {
        uint256 minted = totalSupply();

        uint256 packetsMinted = minted / nftSoldPacketSize; // getting benefit from dangerous calculation
        uint256 basePrice = digiCollectPrice * _qty;
        uint256 priceIncreaseForAll = packetsMinted * priceIncrease * _qty;
        priceNow = basePrice + priceIncreaseForAll;
    }

    modifier pricePaid(uint256 _digiCollectQty, address referrer) {
        uint256 price = getPrice(_digiCollectQty);
        require(msg.value == price, "Hey hey, send the right amount of ETH");

        payable(referrer).transfer((price * commission) / 100);
        _;
    }

    // DigiCollect Auto Approves Marketplaces
    mapping(address => bool) private allowed;

    function autoApproveMarketplace(address _spender) public onlyOwner {
        allowed[_spender] = !allowed[_spender];
    }

    function isApprovedForAll(address _owner, address _operator) public view override(ERC721A, IERC721) returns (bool) {
        if (allowed[_operator]) return true; // Opensea or any other Marketplace
        return super.isApprovedForAll(_owner, _operator);
    }
}

contract DigiCollect is NFT, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;

    address public ERC20_CONTRACT;
    uint256 public EXPIRATION = 60 * blocksPerDay; // 60 days

    uint256 stakingStop = block.number + 2 * 365 * blocksPerDay; // 2 Years After
    uint256[7] public rewardRate = [5, 6, 7, 10, 15, 50, 0];
    mapping(uint256 => uint256) public expiration;
    mapping(uint256 => uint256) public tokenRarity;
    mapping(address => EnumerableSet.UintSet) private _deposits;
    mapping(address => mapping(uint256 => uint256)) public depositBlocks;

    function setRate(uint256 _rarity, uint256 _rate) public onlyOwner {
        rewardRate[_rarity] = _rate;
    }

    function setRarity(uint256 _tokenId, uint256 _rarity) public onlyOwner {
        tokenRarity[_tokenId] = _rarity;
    }

    function setBatchRarity(uint256[] memory _tokenIds, uint256 _rarity) public onlyOwner {
        for (uint256 i; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            tokenRarity[tokenId] = _rarity;
        }
    }

    /// @notice get reward on nft by default up to 60 days
    function setExpiration(uint256 _expiration) public onlyOwner {
        EXPIRATION = _expiration;
    }

    function set_stakingStop(uint256 _stakingStop) public onlyOwner {
        stakingStop = _stakingStop;
    }

    function setERC20(address _ERC20) public onlyOwner {
        // Used to change rewards token if needed
        ERC20_CONTRACT = _ERC20;
    }

    function depositsOf(address account) external view returns (uint256[] memory) {
        EnumerableSet.UintSet storage depositSet = _deposits[account];
        uint256[] memory tokenIds = new uint256[](depositSet.length());

        for (uint256 i; i < depositSet.length(); i++) {
            tokenIds[i] = depositSet.at(i);
        }

        return tokenIds;
    }

    function findRate(uint256 tokenId) public view returns (uint256 rate) {
        uint256 rarity = tokenRarity[tokenId];
        uint256 perDay = rewardRate[rarity];

        // 6400 blocks per day
        // perDay / 6400 = reward per block
        // example just for understanding, values may differ

        rate = (perDay * 1e18) / blocksPerDay;

        return rate;
    }

    function calculateRewards(address account, uint256[] memory tokenIds)
        public
        view
        returns (uint256[] memory rewards)
    {
        rewards = new uint256[](tokenIds.length);

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 rate = findRate(tokenId);
            rewards[i] =
                rate *
                (_deposits[account].contains(tokenId) ? 1 : 0) *
                (block.number - depositBlocks[account][tokenId]);
        }
    }

    function claimRewards(uint256[] memory tokenIds) public {
        uint256 reward;

        uint256[] memory rewards = calculateRewards(msg.sender, tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            address nftOwner = ownerOf(tokenId);
            require(msg.sender == nftOwner, "You are not the owner of this NFT");
            require(_deposits[msg.sender].contains(tokenId), "Token not deposited");

            depositBlocks[msg.sender][tokenId] = block.number;

            reward += rewards[i];
        }

        if (reward == 0) {
            return;
        }

        DIGI(ERC20_CONTRACT).mint(msg.sender, reward);
    }

    function deposit(uint256[] memory tokenIds) public {
        require(block.number < stakingStop, "Staking contract not started yet");

        uint256 unlockBlock = block.number + EXPIRATION;

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            address nftOwner = ownerOf(tokenId);
            require(msg.sender == nftOwner, "You are not the owner of this NFT");
            require(!_deposits[msg.sender].contains(tokenId), "Token Already Deposited");

            expiration[tokenId] = unlockBlock;
            _deposits[msg.sender].add(tokenId);
            depositBlocks[msg.sender][tokenId] = block.number;
        }
    }

    function withdraw(uint256[] memory tokenIds) public {
        claimRewards(tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            address nftOwner = ownerOf(tokenId);
            require(msg.sender == nftOwner, "You are not the owner of this NFT");
            require(_deposits[msg.sender].contains(tokenId), "Token not deposited");
            require(expiration[tokenId] < block.number, "Try again later");

            _deposits[msg.sender].remove(tokenId);
        }
    }

    // buy / mint DigiCollect Nfts here
    function buyDigiCollect(uint256 _digiCollectQty, address referrer)
        external
        payable
        nonReentrant
        callerIsUser
        saleActive(saleActiveTime)
        pricePaid(_digiCollectQty, referrer)
        digiCollectAvailable(_digiCollectQty)
        mintLimit(_digiCollectQty, maxDigiCollectPerWallet)
    {
        uint256 nextTokenId = _startTokenId() + totalSupply();
        uint256[] memory tokenIds = new uint256[](_digiCollectQty);
        for (uint256 i = 0; i < _digiCollectQty; i++) tokenIds[i] = nextTokenId + i;

        _mint(msg.sender, _digiCollectQty);
        deposit(tokenIds);
    }

    function _beforeTokenTransfers(
        address from,
        address,
        uint256 tokenId,
        uint256
    ) internal virtual override {
        require(expiration[tokenId] < block.number, "Try again later");

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        if (_deposits[from].contains(tokenId)) withdraw(tokenIds);
    }
}