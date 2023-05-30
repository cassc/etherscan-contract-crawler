// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./BlockBasedSale.sol";
import "./EIP712Whitelisting.sol";

contract OxStandardV2 is
    Ownable,
    ERC721,
    ERC721Enumerable,
    EIP712Whitelisting,
    VRFConsumerBase,
    BlockBasedSale,
    ReentrancyGuard
{
    using Address for address;
    using SafeMath for uint256;

    event Airdrop(address[] addresses, uint256 amount);
    event AssignAirdropAddress(address indexed _address);
    event AssignBaseURI(string _value);
    event AssignDefaultURI(string _value);
    event AssignRandomNess(uint256 seed);
    event AssignRevealBlock(uint256 _blockNumber);
    event AssignSettlementBlockNumber(uint256 settlementBlockNumber);
    event DisableDutchAuction();
    event EnableDucthAuction();
    event OGClaim(address indexed _address);
    event PermanentURI(string _value, uint256 indexed _id);
    event Purchased(
        address indexed account,
        uint256 indexed index
    );
    event RandomseedRequested(uint256 timestamp);
    event RandomseedFulfilmentSuccess(
        uint256 timestamp,
        bytes32 requestId,
        uint256 seed
    );
    event RandomseedFulfilmentFail(uint256 timestamp, bytes32 requestId);
    event WithdrawNonPurchaseFund(uint256 balance);

    enum SaleState {
        NotStarted,
        PrivateSaleBeforeWithoutBlock,
        PrivateSaleBeforeWithBlock,
        PrivateSaleDuring,
        PrivateSaleEnd,
        PrivateSaleEndSoldOut,
        PublicSaleBeforeWithoutBlock,
        PublicSaleBeforeWithBlock,
        PublicSaleDuring,
        PublicSaleEnd,
        PublicSaleEndSoldOut,
        PauseSale,
        AllSalesEnd
    }

    PaymentSplitter private _splitter;

    struct chainlinkParams {
        address coordinator;
        address linkToken;
        bytes32 keyHash;
    }

    struct revenueShareParams {
        address[] payees;
        uint256[] shares;
    }

    bool public dutchEnabled = false;
    bool public randomseedRequested = false;

    bytes32 public keyHash;
    bytes32 private hashedSecret;

    uint256 public revealBlock = 0;
    uint256 public seed = 0;
    uint256 public totalOGClaimed = 0;
    uint256 private settlementBlockNumber;

    mapping(address => bool) private _airdropAllowed;
    mapping(address => uint256) private _privateSaleClaimed;
    mapping(address => uint256) private _ogClaimed;

    string public _defaultURI;
    string public _tokenBaseURI;

    constructor(
        uint256 _privateSalePrice,
        uint256 _publicSalePrice,
        string memory name,
        string memory symbol,
        uint256 _maxSupply,
        chainlinkParams memory chainlink,
        revenueShareParams memory revenueShare
    )
        ERC721(name, symbol)
        EIP712Whitelisting(name)
        VRFConsumerBase(chainlink.coordinator, chainlink.linkToken)
    {
        _splitter = new PaymentSplitter(
            revenueShare.payees,
            revenueShare.shares
        );
        keyHash = chainlink.keyHash;
        maxSupply = _maxSupply;
        publicSalePrice = _publicSalePrice;
        privateSalePrice = _privateSalePrice;
    }

    modifier airdropRoleOnly() {
        require(_airdropAllowed[msg.sender], "Only airdrop role allowed.");
        _;
    }

    modifier shareHolderOnly() {
        require(_splitter.shares(msg.sender) > 0, "not a shareholder");
        _;
    }

    function airdrop(address[] memory addresses, uint256 amount)
        external
        nonReentrant
        airdropRoleOnly
    {
        require(
            totalSupply().add(addresses.length.mul(amount)) <= maxSupply,
            "Exceed max supply limit."
        );

        require(
            totalReserveMinted.add(addresses.length.mul(amount)) <= maxReserve,
            "Insufficient reserve."
        );

        totalReserveMinted = totalReserveMinted.add(
            addresses.length.mul(amount)
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            _mintToken(addresses[i], amount);
        }
        emit Airdrop(addresses, amount);
    }

    function setAirdropRole(address addr) external onlyOwner {
        emit AssignAirdropAddress(addr);
        _airdropAllowed[addr] = true;
    }

    function setRevealBlock(uint256 blockNumber) external operatorOnly {
        emit AssignRevealBlock(blockNumber);
        revealBlock = blockNumber;
    }

    function freeze(uint256[] memory ids) external operatorOnly {
        for (uint256 i = 0; i < ids.length; i += 1) {
            emit PermanentURI(tokenURI(ids[i]), ids[i]);
        }
    }

    function mintOg(bytes calldata signature)
        external
        payable
        nonReentrant
        returns (bool)
    {
        require(msg.sender == tx.origin, "Contract is not allowed.");
        require(
            getState() == SaleState.PrivateSaleDuring,
            "Sale not available."
        );

        if (getState() == SaleState.PrivateSaleDuring) {
            require(isOGwhitelisted(signature), "Not OG whitelisted.");
            require(_ogClaimed[msg.sender] == 0, "Already Claimed OG.");
            require(
                totalPrivateSaleMinted.add(1) <= privateSaleCapped,
                "Purchase exceed private sale capped."
            );

            require(msg.value >= getPriceByMode(), "Insufficient funds.");

            emit OGClaim(msg.sender);
            _ogClaimed[msg.sender] = _ogClaimed[msg.sender] + 1;
            totalPrivateSaleMinted = totalPrivateSaleMinted + 1;
            totalOGClaimed = totalOGClaimed + 1;

            _mintToken(msg.sender, 1);

            payable(_splitter).transfer(msg.value);

            return true;
        }

        return false;
    }

    function mintToken(uint256 amount, bytes calldata signature)
        external
        payable
        nonReentrant
        returns (bool)
    {
        require(msg.sender == tx.origin, "Contract is not allowed.");
        require(
            getState() == SaleState.PrivateSaleDuring ||
                getState() == SaleState.PublicSaleDuring,
            "Sale not available."
        );

        if (getState() == SaleState.PublicSaleDuring) {
            require(
                amount <= maxPublicSalePerTx,
                "Mint exceed transaction limits."
            );
            require(
                msg.value >= amount.mul(getPriceByMode()),
                "Insufficient funds."
            );
            require(
                totalSupply().add(amount).add(availableReserve()) <= maxSupply,
                "Purchase exceed max supply."
            );
        }

        if (getState() == SaleState.PrivateSaleDuring) {
            require(isEIP712WhiteListed(signature), "Not whitelisted.");
            require(
                amount <= maxPrivateSalePerTx,
                "Mint exceed transaction limits"
            );
            require(
                _privateSaleClaimed[msg.sender] + amount <=
                    maxWhitelistClaimPerWallet,
                "Mint limit per wallet exceeded."
            );
            require(
                totalPrivateSaleMinted.add(amount) <= privateSaleCapped,
                "Purchase exceed private sale capped."
            );

            require(
                msg.value >= amount.mul(getPriceByMode()),
                "Insufficient funds."
            );
        }

        if (
            getState() == SaleState.PrivateSaleDuring ||
            getState() == SaleState.PublicSaleDuring
        ) {
            _mintToken(msg.sender, amount);
            if (getState() == SaleState.PublicSaleDuring) {
                totalPublicMinted = totalPublicMinted + amount;
            }
            if (getState() == SaleState.PrivateSaleDuring) {
                _privateSaleClaimed[msg.sender] =
                    _privateSaleClaimed[msg.sender] +
                    amount;
                totalPrivateSaleMinted = totalPrivateSaleMinted + amount;
            }
            payable(_splitter).transfer(msg.value);
            
        }

        return true;
    }

    function setBaseURI(string memory baseURI) external governorOnly {
        _tokenBaseURI = baseURI;
        emit AssignBaseURI(baseURI);
    }

    function setDefaultURI(string memory defaultURI) external operatorOnly {
        _defaultURI = defaultURI;
        emit AssignDefaultURI(defaultURI);
    }

    function requestChainlinkVRF() external operatorOnly {
        require(!randomseedRequested, "Chainlink VRF already requested");
        require(
            LINK.balanceOf(address(this)) >= 2000000000000000000,
            "Insufficient LINK"
        );
        requestRandomness(keyHash, 2000000000000000000);
        randomseedRequested = true;
        emit RandomseedRequested(block.timestamp);
    }

    function getState() public view returns (SaleState) {
        uint256 supplyWithoutReserve = maxSupply - maxReserve;
        uint256 mintedWithoutReserve = totalPublicMinted +
            totalPrivateSaleMinted;

        if (
            salePhase != SalePhase.None &&
            overridedSaleState == OverrideSaleState.Close
        ) {
            return SaleState.AllSalesEnd;
        }

        if (
            salePhase != SalePhase.None &&
            overridedSaleState == OverrideSaleState.Pause
        ) {
            return SaleState.PauseSale;
        }

        if (
            salePhase == SalePhase.Public &&
            mintedWithoutReserve == supplyWithoutReserve
        ) {
            return SaleState.PublicSaleEndSoldOut;
        }

        if (salePhase == SalePhase.None) {
            return SaleState.NotStarted;
        }

        if (
            salePhase == SalePhase.Public &&
            publicSale.endBlock > 0 &&
            block.number > publicSale.endBlock
        ) {
            return SaleState.PublicSaleEnd;
        }

        if (
            salePhase == SalePhase.Public &&
            publicSale.beginBlock > 0 &&
            block.number >= publicSale.beginBlock
        ) {
            return SaleState.PublicSaleDuring;
        }

        if (
            salePhase == SalePhase.Public &&
            publicSale.beginBlock > 0 &&
            block.number < publicSale.beginBlock &&
            block.number > privateSale.endBlock
        ) {
            return SaleState.PublicSaleBeforeWithBlock;
        }

        if (
            salePhase == SalePhase.Public &&
            publicSale.beginBlock == 0 &&
            block.number > privateSale.endBlock
        ) {
            return SaleState.PublicSaleBeforeWithoutBlock;
        }

        if (
            salePhase == SalePhase.Private &&
            totalPrivateSaleMinted == privateSaleCapped
        ) {
            return SaleState.PrivateSaleEndSoldOut;
        }

        if (
            salePhase == SalePhase.Private &&
            privateSale.endBlock > 0 &&
            block.number > privateSale.endBlock
        ) {
            return SaleState.PrivateSaleEnd;
        }

        if (
            salePhase == SalePhase.Private &&
            privateSale.beginBlock > 0 &&
            block.number >= privateSale.beginBlock
        ) {
            return SaleState.PrivateSaleDuring;
        }

        if (
            salePhase == SalePhase.Private &&
            privateSale.beginBlock > 0 &&
            block.number < privateSale.beginBlock
        ) {
            return SaleState.PrivateSaleBeforeWithBlock;
        }

        if (salePhase == SalePhase.Private && privateSale.beginBlock == 0) {
            return SaleState.PrivateSaleBeforeWithoutBlock;
        }

        return SaleState.NotStarted;
    }

    function getStartSaleBlock() external view returns (uint256) {
        if (
            SaleState.PrivateSaleBeforeWithBlock == getState() ||
            SaleState.PrivateSaleDuring == getState()
        ) {
            return privateSale.beginBlock;
        }

        if (
            SaleState.PublicSaleBeforeWithBlock == getState() ||
            SaleState.PublicSaleDuring == getState()
        ) {
            return publicSale.beginBlock;
        }

        return 0;
    }

    function getEndSaleBlock() external view returns (uint256) {
        if (
            SaleState.PrivateSaleBeforeWithBlock == getState() ||
            SaleState.PrivateSaleDuring == getState()
        ) {
            return privateSale.endBlock;
        }

        if (
            SaleState.PublicSaleBeforeWithBlock == getState() ||
            SaleState.PublicSaleDuring == getState()
        ) {
            return publicSale.endBlock;
        }

        return 0;
    }

    function tokenBaseURI() external view returns (string memory) {
        return _tokenBaseURI;
    }

    function isRevealed() public view returns (bool) {
        return seed > 0 && revealBlock > 0 && block.number > revealBlock;
    }

    function getMetadata(uint256 tokenId) public view returns (string memory) {
        if (_msgSender() != owner()) {
            require(tokenId <= totalSupply(), "Token not exists.");
        }

        if (!isRevealed()) return "default";

        uint256[] memory metadata = new uint256[](maxSupply + 1);

        for (uint256 i = 1; i <= maxSupply; i += 1) {
            metadata[i] = i;
        }

        for (uint256 i = 2; i <= maxSupply; i += 1) {
            uint256 j = (uint256(keccak256(abi.encode(seed, i))) %
                (maxSupply)) + 1;

            if (j >= 2 && j <= maxSupply) {
                (metadata[i], metadata[j]) = (metadata[j], metadata[i]);
            }
        }

        return Strings.toString(metadata[tokenId]);
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
                        _tokenBaseURI,
                        getMetadata(tokenId),
                        ".json"
                    )
                )
                : _defaultURI;
    }

    function availableReserve() public view returns (uint256) {
        return maxReserve - totalReserveMinted;
    }

    function getMaxSupplyByMode() external view returns (uint256) {
        if (getState() == SaleState.PrivateSaleDuring) return privateSaleCapped;
        if (getState() == SaleState.PublicSaleDuring)
            return maxSupply - totalPrivateSaleMinted - maxReserve;
        return 0;
    }

    function getMintedByMode() external view returns (uint256) {
        if (getState() == SaleState.PrivateSaleDuring)
            return totalPrivateSaleMinted;
        if (getState() == SaleState.PublicSaleDuring) return totalPublicMinted;
        return 0;
    }

    function getTransactionCappedByMode() external view returns (uint256) {
        return
            getState() == SaleState.PrivateSaleDuring
                ? maxPrivateSalePerTx
                : maxPublicSalePerTx;
    }

    function availableForSale() external view returns (uint256) {
        return maxSupply - totalSupply();
    }

    function getPriceByMode() public view returns (uint256) {
        if (getState() == SaleState.PrivateSaleDuring) return privateSalePrice;

        if (getState() == SaleState.PublicSaleDuring) {
            if (!dutchEnabled) {
                return publicSalePrice;
            }

            uint256 passedBlock = block.number - publicSale.beginBlock;
            uint256 discountPrice = passedBlock.mul(priceFactor).div(
                discountBlockSize
            );

            if (discountPrice >= publicSalePrice.sub(lowerBoundPrice)) {
                return lowerBoundPrice;
            } else {
                return publicSalePrice.sub(discountPrice);
            }
        }

        return publicSalePrice;
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

    function startPublicSaleBlock() external view returns (uint256) {
        return publicSale.beginBlock;
    }

    function endPublicSaleBlock() external view returns (uint256) {
        return publicSale.endBlock;
    }

    function startPrivateSaleBlock() external view returns (uint256) {
        return privateSale.beginBlock;
    }

    function endPrivateSaleBlock() external view returns (uint256) {
        return privateSale.endBlock;
    }

    function setBlockNumbertoGenSeed(bytes32 _hashedSecret)
        external
        governorOnly
    {
        require(
            bytes(_tokenBaseURI).length != 0,
            "The token base URI is not set yet"
        );
        require(!randomseedRequested, "The random already requested");
        require(
            settlementBlockNumber == 0 ||
                block.number - settlementBlockNumber >= 256,
            "settlementBlockNumber block is already set"
        );

        //set settlementBlockNumber to the future block
        settlementBlockNumber = block.number + 10;
        hashedSecret = _hashedSecret;
        emit AssignSettlementBlockNumber(settlementBlockNumber);
    }

    function setRandomResultToSeed(bytes32 _secret) external governorOnly {
        require(
            settlementBlockNumber != 0,
            "Settlement block number not exists"
        );
        require(
            block.number > settlementBlockNumber,
            "Settlement block number not reached"
        );
        require(
            block.number - settlementBlockNumber < 256,
            "Settlement block number expired."
        );
        require(
            keccak256(abi.encodePacked(_secret)) == hashedSecret,
            "Incorrect secret"
        );

        seed = uint256(
            keccak256(
                abi.encodePacked(blockhash(settlementBlockNumber), _secret)
            )
        );
        randomseedRequested = true;
        emit AssignRandomNess(seed);
    }

    function release(address payable account) external virtual shareHolderOnly {
        require(
            msg.sender == account || msg.sender == owner(),
            "Release: no permission"
        );

        _splitter.release(account);
    }

    function withdraw() external governorOnly {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        emit WithdrawNonPurchaseFund(balance);
    }

    function enableDutchAuction() external operatorOnly {
        dutchEnabled = true;
        emit EnableDucthAuction();
    }

    function disableDutchAuction() external operatorOnly {
        dutchEnabled = false;
        emit DisableDutchAuction();
    }

    function _mintToken(address addr, uint256 amount) internal returns (bool) {
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenIndex = totalSupply();
            if (tokenIndex < maxSupply) {
                _safeMint(addr, tokenIndex + 1);
                emit Purchased(addr, tokenIndex);
            }
        }
        return true;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
        internal
        override
    {
        if (randomNumber > 0) {
            seed = randomNumber;
            emit RandomseedFulfilmentSuccess(block.timestamp, requestId, seed);
        } else {
            seed = 1;
            emit RandomseedFulfilmentFail(block.timestamp, requestId);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}