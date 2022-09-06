// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/Common.sol";
import "../utils/SigVer.sol";
import "./MagicFolkGems.sol";
import "./MagicFolkItems.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MagicFolk is
    ERC165,
    ERC721,
    ERC721Enumerable,
    ERC721Holder,
    CommonConstants,
    IERC1155Receiver,
    ReentrancyGuard,
    SigVer,
    AccessControl,
    Ownable
{
    using Counters for Counters.Counter;

    struct Stats {
        uint8 powerLevel;
        Item mainHand;
        Item offHand;
        Item pet;
    }

    struct Payee {
        address wallet;
        uint16 percentagePoints;
        bytes24 payeeId;
    }

    // Setup payees
    // Hardcoded here instead of being added by an external function
    // for the sake of immutability and transparency.
    Payee[11] public _payees;

    event Equipped(
        uint256 indexed _tokenId,
        uint256 indexed _itemId,
        ItemType _itemType
    );
    event Unequipped(
        uint256 indexed _tokenId,
        uint256 indexed _itemId,
        ItemType _itemType
    );
    event Staked(uint256 indexed _tokenId, address owner);
    event Unstaked(uint256 indexed _tokenId, address owner);
    event publicSaleToggled(bool state);
    event privateSaleToggled(bool state);
    event stakingToggled(bool state);

    // token id => stats
    mapping(uint256 => Stats) private _tokenStats;
    // Private sale
    mapping(address => uint256) private _totalMintsPerAddress;
    // Public sale
    mapping(address => uint256) public _mintNonce;

    // Staking
    mapping(uint256 => uint256) private _lastClaims;
    mapping(uint256 => address) public _tokenOwners;
    mapping(address => uint256[]) public _stakedTokens;

    Counters.Counter private _tokenIdCounter;
    MagicFolkItems MAGIC_FOLK_MAINHAND;
    MagicFolkItems MAGIC_FOLK_OFFHAND;
    MagicFolkItems MAGIC_FOLK_PET;
    MagicFolkGems MAGIC_FOLK_GEMS;

    // MINT CONSTANTS
    uint256 public constant PUBLIC_ALLOWANCE = 10;
    uint256 public constant MAX_MINT = 9500;
    uint256 public constant TEAM_MINT = 500;
    uint256 public constant PRIVATE_PRICE = 0.1 ether;
    uint256 public constant PUBLIC_PRICE = 0.125 ether;
    address public constant FEE_ADDRESS =
        0x670326f4470d4D2F5347377Ff187717a81aB1318;

    uint256 public _fees = 60.0 ether;
    uint256 public _teamMinted = 0;
    address public _signer;

    // Gems per day per power level
    uint256 _gemRate = 10;
    uint256 constant SECONDS_PER_DAY = 86400;
    string public _URI = "https://cdn-stg.magicfolk.io/api/genesis/";

    uint8[MAX_MINT + TEAM_MINT] private _basePowerLevels; // token id => base power level

    bool private _publicSale = false;
    bool private _privateSale = false;
    bool private _powerLevelsSet = false;
    bool public _publicSaleSignatureRequired = true;
    bool public _stakingEnabled = false;
    bool public _listable = false;
    bool public _initialFeesWithdrawn = false;

    constructor(
        address signer,
        address magicFolkMainhand,
        address magicFolkOffhand,
        address magicFolkPet
    ) ERC721("Magic Folk", "MF") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _signer = signer;
        MAGIC_FOLK_MAINHAND = MagicFolkItems(magicFolkMainhand);
        MAGIC_FOLK_OFFHAND = MagicFolkItems(magicFolkOffhand);
        MAGIC_FOLK_PET = MagicFolkItems(magicFolkPet);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Setup payees
        _payees[0] = Payee(
            0x586a6c03DA4959C6341845C210b4CdBec930Af37,
            265,
            "ELON_MUSK"
        );
        _payees[1] = Payee(
            0xa8fD19cb5F949677504DD90f8B6efe044286e6B2,
            80,
            "DONALD_TRUMP"
        );
        _payees[2] = Payee(
            0xD85aA7341a63B413972c8e8D63Ae7a7bC08A5aFD,
            25,
            "WARREN_BUFFET"
        );
        _payees[3] = Payee(
            0x4fB91f8b17702aFf47BE977A226dDdabf5475661,
            25,
            "JEFF_BEZOS"
        );
        _payees[4] = Payee(
            0x7913FEDA30503465EDAdc674a66fbDcB581f6840,
            120,
            "BILL_GATES"
        );
        _payees[5] = Payee(
            0x2E8a3F14feDA7FA7690260a06A1656BFe20bE1aC,
            60,
            "LEBRON_JAMES"
        );
        _payees[6] = Payee(
            0x60d1082D0fdaB22990f56A70B68AdDC049F75EC8,
            100,
            "NICOLAS_CAGE"
        );
        _payees[7] = Payee(
            0x71dcB19A6D322C9D826aA6b61442828436Aa6fb2,
            50,
            "KENDRICK_LAMAR"
        );
        _payees[8] = Payee(
            0x996107A817f0fbaF389F1DCC1A48Dfb2eDb78D33,
            25,
            "R_KELLY"
        );
        _payees[9] = Payee(
            0xAB1ca28b50EdC107023d81e71640da3ee26F93A0,
            150,
            "LIL_DICKY"
        );
        _payees[10] = Payee(
            0x3750737d7fbF284705a329AB674D9309485B5bE2,
            100,
            "JIMMY_CARR"
        );

        uint256 percentagePointSum = 0;
        for (uint256 i = 0; i < _payees.length; i++) {
            percentagePointSum += _payees[i].percentagePoints;
        }
        require(percentagePointSum == 1000, "INVALID_PERCENTAGES");
    }

    function setMagicFolkGemsContract(address magicFolkGems)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        MAGIC_FOLK_GEMS = MagicFolkGems(magicFolkGems);
    }

    function setMagicFolkItemsContract(
        address magicFolkItems,
        ItemType itemType
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (itemType == ItemType.Mainhand) {
            MAGIC_FOLK_MAINHAND = MagicFolkItems(magicFolkItems);
        } else if (itemType == ItemType.Offhand) {
            MAGIC_FOLK_OFFHAND = MagicFolkItems(magicFolkItems);
        } else if (itemType == ItemType.Pet) {
            MAGIC_FOLK_PET = MagicFolkItems(magicFolkItems);
        } else {
            revert();
        }
    }

    function setSignerAddress(address signer)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _signer = signer;
    }

    function setBaseURI(string calldata URI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _URI = URI;
    }

    /**
    @dev Once enabled, listing on OpenSea cannot be disabled again. 
     */
    function enableListings() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _listable = true;
    }

    /**
    @dev To prevent buyers listing on OpenSea before public and private sales
         have ended, we override this function to return false unless listings
         have been enabled. 
    */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        if (!_listable) {
            return false;
        } else {
            return super.isApprovedForAll(owner, operator);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return _URI;
    }

    function publicSaleActive() public view returns (bool) {
        return _publicSaleActive();
    }

    function togglePublicSale() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!_privateSaleActive());
        _publicSale = !_publicSale;
        emit publicSaleToggled(_publicSale);
    }

    function toggleStaking() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _stakingEnabled = !_stakingEnabled;
        emit stakingToggled(_stakingEnabled);
    }

    function togglePublicSaleSigRequired() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _publicSaleSignatureRequired = !_publicSaleSignatureRequired;
    }

    function privateSaleActive() public view returns (bool) {
        return _privateSaleActive();
    }

    function togglePrivateSale() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!_publicSaleActive());
        _privateSale = !_privateSale;
        emit privateSaleToggled(_privateSale);
    }

    // Power levels for legendary NFTs will be set after reveal
    function setPowerLevels(
        uint8[] calldata powerLevels,
        uint256[] calldata tokenIds
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!_powerLevelsSet);
        require(powerLevels.length == tokenIds.length);
        for (uint256 i = 0; i < powerLevels.length; i++) {
            _basePowerLevels[tokenIds[i]] = powerLevels[i];
        }
    }

    function lockPowerLevels() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!_powerLevelsSet);
        _powerLevelsSet = true;
    }

    /**
        @dev Mints an NFT for the public sale. Uses a nonce, msgHash and signature
             to ensure minting is only possible through our website. 
        @param qty Amount to be minted
        @param mintNonce Nonce value that's incremented after each mint, used to
                         ensure signature + msgHash are unique. Can be retrieved
                         via ._mintNonce(address) before being hashed + signed and
                         passed into function. 
        @param msgHash hashed message, should match the message that's been signed
                       by our keypair on frontend. 
                       (['address', 'uint256'], [buyerAddress, mintNonce])
        @param signature signed version of msgHash
     */
    function safeMintPublic(
        uint256 qty,
        uint256 mintNonce,
        bytes32 msgHash,
        bytes calldata signature
    ) external payable nonReentrant {
        address to = _msgSender();
        require(_publicSaleActive(), "Public sale not active");
        require(msg.value >= qty * PUBLIC_PRICE, "Insufficient funds");
        require(qty <= PUBLIC_ALLOWANCE, "EXCEED_ALLOWANCE");
        require(
            _tokenIdCounter.current() + qty - _teamMinted <= MAX_MINT,
            "SOLD_OUT"
        );
        require(mintNonce == _mintNonce[to], "INVALID_NONCE");
        require(
            _verifyMsg(to, mintNonce, msgHash, signature, _signer) ||
                !_publicSaleSignatureRequired,
            "INVALID_SIG"
        );

        for (uint256 i = 0; i < qty; i++) {
            _safeMint(to);
        }

        _mintNonce[to]++;
    }

    /**
        @dev Mints an NFT for the private sale. Eligibility and allowance for
             private sale are verified, hashed, and signed to ensure only those
             eligible can mint. 
        @param qty Amount to be minted
        @param privateSaleAllowance Total number of NFTs this account can mint
                                    in the private sale.
        @param msgHash hashed message, should match the message that's been signed
                       by our keypair on frontend. 
                       (['address', 'uint256'], [buyerAddress, privateSaleAllowance])
        @param signature signed version of msgHash
     */
    function safeMintPrivate(
        uint256 qty,
        uint256 privateSaleAllowance,
        bytes32 msgHash,
        bytes calldata signature
    ) external payable nonReentrant {
        address to = _msgSender();
        require(_privateSaleActive(), "Private sale not active");
        require(msg.value >= qty * PRIVATE_PRICE, "Insufficient funds");
        require(
            qty + _totalMintsPerAddress[to] <= privateSaleAllowance,
            "Exceeded allowance"
        );
        require(
            _verifyMsg(to, privateSaleAllowance, msgHash, signature, _signer),
            "INVALID_SIG"
        );
        require(
            _tokenIdCounter.current() + qty - _teamMinted <= MAX_MINT,
            "SOLD_OUT"
        );

        for (uint256 i = 0; i < qty; i++) {
            _safeMint(to);
        }

        _totalMintsPerAddress[to] += qty;
    }

    function teamMint(uint256 qty) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_publicSaleActive() || _privateSaleActive());
        address to = msg.sender;
        require(qty + _teamMinted <= TEAM_MINT, "TEAM_MINT_LIMIT_REACHED");
        for (uint256 i = 0; i < qty; i++) {
            _safeMint(to);
        }
        _teamMinted += qty;
    }

    function isTokenStaked(uint256 tokenId) public view returns (bool) {
        return _isTokenStaked(tokenId);
    }

    function stakeToken(uint256 tokenId) external nonReentrant {
        _stakeToken(msg.sender, tokenId);
    }

    function stakeTokens(uint256[] calldata tokenIds) external nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stakeToken(msg.sender, tokenIds[i]);
        }
    }

    function getQuantityStaked(address owner) public view returns (uint256) {
        return _stakedTokens[owner].length;
    }

    function getStakedTokens(address owner)
        public
        view
        returns (uint256[] memory)
    {
        return _stakedTokens[owner];
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 totalOwned = balanceOf(owner);
        uint256[] memory ret = new uint256[](totalOwned);
        for (uint256 i = 0; i < totalOwned; i++) {
            ret[i] = ERC721Enumerable.tokenOfOwnerByIndex(owner, i);
        }
        return ret;
    }

    function setGemRate(uint256 newGemRate)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setGemRate(newGemRate);
    }

    function _stakeToken(address user, uint256 tokenId) internal {
        require(_isApprovedOrOwner(user, tokenId), "NOT_AUTHORISED");
        require(!_isTokenStaked(tokenId), "ALREADY_STAKED");
        _setLastClaim(tokenId);
        _tokenOwners[tokenId] = user;
        _stakedTokens[user].push(tokenId);
        safeTransferFrom(user, address(this), tokenId);
    }

    function unstakeToken(uint256 tokenId) external nonReentrant {
        _unstakeToken(msg.sender, tokenId);
    }

    function unstakeTokens(uint256[] calldata tokenIds) external nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _unstakeToken(msg.sender, tokenIds[i]);
        }
    }

    function claimGems(uint256 tokenId) public nonReentrant {
        require(_isTokenStaked(tokenId), "NOT_STAKED");
        require(_tokenOwners[tokenId] == _msgSender(), "NOT_AUTHORISED");
        uint256 allocation = _calcAllocation(tokenId);
        require(allocation > 0, "NO_GEMS");
        MAGIC_FOLK_GEMS.mint(_msgSender(), allocation);
        _setLastClaim(tokenId);
    }

    function claimAllGems() external {
        uint256[] memory stakedTokens = _stakedTokens[_msgSender()];
        for (uint256 i = 0; i < stakedTokens.length; i++) {
            if (_calcAllocation(stakedTokens[i]) > 0) {
                claimGems(stakedTokens[i]);
            }
        }
    }

    function getAllocation(uint256 tokenId) public view returns (uint256) {
        return _calcAllocation(tokenId);
    }

    function getTotalUnclaimed(address owner) public view returns (uint256) {
        uint256 sum = 0;
        uint256[] memory stakedTokens = _stakedTokens[owner];
        for (uint256 i = 0; i < stakedTokens.length; i++) {
            sum += _calcAllocation(stakedTokens[i]);
        }
        return sum;
    }

    function _safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _rollStats(tokenId);
    }

    // Was originally going to use Chainlink VRF, but we decided to base
    // power levels on rarity so they'll be written after reveal.
    // Defaults to 5, legendary NFTs will have a higher power level.
    function _rollStats(uint256 tokenId) internal {
        _setBasePowerLevel(tokenId, 5);
    }

    modifier tokenExists(uint256 tokenId) {
        require(_exists(tokenId), "Token does not exist.");
        _;
    }

    function getStats(uint256 tokenId)
        public
        view
        tokenExists(tokenId)
        returns (Stats memory)
    {
        Stats memory stats = _getStats(tokenId);
        require(
            _basePowerLevels[tokenId] > 0,
            "Token traits have not been initialized."
        );
        return stats;
    }

    function getGemRate() public view returns (uint256) {
        return _getGemRate();
    }

    function getBasePowerLevel(uint256 tokenId)
        public
        view
        tokenExists(tokenId)
        returns (uint8)
    {
        return _getBasePowerLevel(tokenId);
    }

    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external override returns (bytes4) {
        require(_operator == _from, "NOT_AUTHORISED");
        require(
            msg.sender == address(MAGIC_FOLK_MAINHAND) ||
                msg.sender == address(MAGIC_FOLK_OFFHAND) ||
                msg.sender == address(MAGIC_FOLK_PET),
            "INVALID_TOKEN_TYPE"
        );

        (uint256 _nftTokenId, Item memory _item) = decodeOwnerIdAndItem(_data);
        require(
            ownerOf(_nftTokenId) == _from || _tokenOwners[_nftTokenId] == _from,
            "NOT_YOUR_NFT"
        );
        require(_item.itemId == _id, "INVALID_DECODED_ID");
        require(_value == 1, "CAN_ONLY_EQUIP_ONE");
        require(
            _item.itemType == MagicFolkItems(msg.sender)._itemType(),
            "INVALID_ITEMTYPE"
        );

        _equip(_item, _nftTokenId);
        return ERC1155_RECEIVED_VALUE;
    }

    function unequip(address from, bytes calldata data) external {
        require(
            msg.sender == address(MAGIC_FOLK_MAINHAND) ||
                msg.sender == address(MAGIC_FOLK_OFFHAND) ||
                msg.sender == address(MAGIC_FOLK_PET),
            "Invalid caller"
        );
        (uint256 nftTokenId, Item memory item) = decodeOwnerIdAndItem(data);
        require(
            ownerOf(nftTokenId) == from || _tokenOwners[nftTokenId] == from,
            "NOT_YOUR_NFT"
        );
        _unequip(item, nftTokenId);

        IERC1155(msg.sender).safeTransferFrom(
            address(this),
            from,
            item.itemId,
            1,
            ""
        );
        emit Unequipped(nftTokenId, item.itemId, item.itemType);
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert();
    }

    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 amount;
        uint256 balance = address(this).balance;
        bool success = false;
        if (!_initialFeesWithdrawn) {
            if (balance <= _fees) {
                amount = balance;
            } else {
                amount = _fees;
            }
            (success, ) = payable(FEE_ADDRESS).call{ value: amount }("");
            require(success, "NOPE");
            _initialFeesWithdrawn = true;
        } else {
            for (uint256 i = 0; i < _payees.length; i++) {
                (success, ) = payable(_payees[i].wallet).call{
                    value: (balance * _payees[i].percentagePoints) / 1000
                }("");
                require(success);
            }
        }
    }

    function setFees(uint256 newFees) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _fees = newFees;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, IERC165, ERC165, AccessControl)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceID) ||
            interfaceID == type(IERC1155Receiver).interfaceId ||
            interfaceID == 0x01ffc9a7 || // ERC165
            interfaceID == 0x4e2312e0; // ERC1155_ACCEPTED ^ ERC1155_BATCH_ACCEPTED;;
    }

    function _isTokenStaked(uint256 tokenId) internal view returns (bool) {
        return ownerOf(tokenId) == address(this);
    }

    function _unstakeToken(address user, uint256 tokenId) internal {
        require(_isTokenStaked(tokenId), "NOT_STAKED");
        require(_tokenOwners[tokenId] == user, "NOT_AUTHORISED");
        uint256 allocation = _calcAllocation(tokenId);
        // require(allocation > 0, "CANT_UNSTAKE_YET");

        if (allocation > 0) {
            MAGIC_FOLK_GEMS.mint(_msgSender(), allocation);
        }

        uint256 i = 0;
        uint256 lastTokenIndex = _stakedTokens[user].length - 1;
        while (_stakedTokens[user][i] != tokenId) {
            i++;
        }
        _stakedTokens[user][i] = _stakedTokens[user][lastTokenIndex];
        _stakedTokens[user].pop();
        _lastClaims[tokenId] = 0;
        delete _tokenOwners[tokenId];
        _safeTransfer(address(this), user, tokenId, "");
    }

    function _publicSaleActive() internal view returns (bool) {
        return _publicSale;
    }

    function _privateSaleActive() internal view returns (bool) {
        return _privateSale;
    }

    function _equip(Item memory _item, uint256 _nftTokenId) internal {
        require(
            !(_isEquipped(_nftTokenId, _item.itemType)),
            "Slot is not empty"
        );

        Stats memory stats = _getItemStats(_nftTokenId);

        if (_item.itemType == ItemType.Mainhand) {
            stats.mainHand = _item;
        } else if (_item.itemType == ItemType.Offhand) {
            stats.offHand = _item;
        } else if (_item.itemType == ItemType.Pet) {
            stats.pet = _item;
        } else {
            revert();
        }

        stats.powerLevel += _item.powerLevel;
        _setStats(_nftTokenId, stats);
        emit Equipped(_nftTokenId, _item.itemId, _item.itemType);
    }

    function _unequip(Item memory _item, uint256 _nftTokenId) internal {
        require(_isEquipped(_nftTokenId, _item.itemType), "Slot is empty");

        Stats memory stats = _getItemStats(_nftTokenId);

        if (_item.itemType == ItemType.Mainhand) {
            require(stats.mainHand.itemId == _item.itemId, "Incorrect item");
            stats.mainHand = _emptyItem();
        } else if (_item.itemType == ItemType.Offhand) {
            require(stats.offHand.itemId == _item.itemId, "Incorrect item");
            stats.offHand = _emptyItem();
        } else if (_item.itemType == ItemType.Pet) {
            require(stats.pet.itemId == _item.itemId, "Incorrect item");
            stats.pet = _emptyItem();
        } else {
            revert();
        }

        stats.powerLevel -= _item.powerLevel;
        _setStats(_nftTokenId, stats);
    }

    function _isEquipped(uint256 nftTokenId, ItemType slot)
        internal
        view
        tokenExists(nftTokenId)
        returns (bool)
    {
        Stats memory stats = _getItemStats(nftTokenId);

        if (slot == ItemType.Mainhand) {
            return stats.mainHand.itemType == ItemType.Mainhand;
        } else if (slot == ItemType.Offhand) {
            return stats.offHand.itemType == ItemType.Offhand;
        } else {
            return stats.pet.itemType == ItemType.Pet;
        }
    }

    function _getItemStats(uint256 tokenId)
        internal
        view
        tokenExists(tokenId)
        returns (Stats memory)
    {
        Stats memory stats = _tokenStats[tokenId];
        return stats;
    }

    function _getStats(uint256 tokenId)
        internal
        view
        tokenExists(tokenId)
        returns (Stats memory)
    {
        Stats memory stats = _getItemStats(tokenId);
        stats.powerLevel = stats.powerLevel + _getBasePowerLevel(tokenId);
        return stats;
    }

    function _setStats(uint256 tokenId, Stats memory stats)
        internal
        tokenExists(tokenId)
    {
        _tokenStats[tokenId] = stats;
    }

    function _setBasePowerLevel(uint256 tokenId, uint8 _powerLevel)
        internal
        tokenExists(tokenId)
    {
        _basePowerLevels[tokenId] = _powerLevel;
    }

    function _getBasePowerLevel(uint256 tokenId)
        internal
        view
        tokenExists(tokenId)
        returns (uint8)
    {
        return _basePowerLevels[tokenId];
    }

    function _calcAllocation(uint256 tokenId) internal view returns (uint256) {
        Stats memory stats = _getStats(tokenId);
        uint256 timeDeltaDays = (block.timestamp - _getLastClaim(tokenId)) /
            SECONDS_PER_DAY;

        return timeDeltaDays * stats.powerLevel * _gemRate;
    }

    function _getLastClaim(uint256 tokenId)
        internal
        view
        tokenExists(tokenId)
        returns (uint256)
    {
        return _lastClaims[tokenId];
    }

    function _setLastClaim(uint256 tokenId) internal tokenExists(tokenId) {
        _lastClaims[tokenId] = block.timestamp;
    }

    function _setGemRate(uint256 newGemRate) internal {
        _gemRate = newGemRate;
    }

    function _getGemRate() internal view returns (uint256) {
        return _gemRate;
    }

    function _emptyItem() internal pure returns (Item memory) {
        return Item(0, 0, ItemType.Empty);
    }
}