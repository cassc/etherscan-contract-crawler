// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721A.sol";

interface MetadataProvider {
    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function tokenData(uint256 _tokenId) external view returns (bytes memory);
}

contract ApeScoundrelSquad is ERC721ABurnable, Ownable {
    constructor(
        uint16 _maxTotalSupply,
        uint16 _publicSaleTxLimit,
        uint16 _batchSize
    ) ERC721A("Ape Scoundrel Squad", "ASS") {
        saleConfig.MAX_TX_PUBLIC_SALE_CLAIM_QTY = _publicSaleTxLimit;
        saleConfig.MAX_TOTAL_SUPPLY = _maxTotalSupply;
        saleConfig.BATCH_SIZE = _batchSize;
    }

    using Strings for uint256;

    event VoucherUsed(
        address indexed _address,
        uint256 _nonce,
        uint256 _claimQty
    );

    string public BASE_URI;
    address public metadataProvider;
    address public signer;
    address public proxyRegistryAddress;
    bool IS_METADATA_LOCKED;
    bool IS_PROXY_REGISTRY_LOCKED;
    mapping(address => bool) public admins;
    mapping(uint256 => uint256) public voucherToMinted;

    struct SaleConfig {
        bool IS_PRESALE_ON; // turns on redeemVoucher functionality
        bool IS_PUBLIC_SALE_ON; // turn on mintSale
        uint16 BATCH_SIZE; // controls ERC721A max mint ranges to balance transfer cost for big batches
        uint16 MAX_TOTAL_SUPPLY;
        uint16 PUBLIC_SALE_KEY; // key to unlock public sale when it's on
        uint16 MAX_TX_PUBLIC_SALE_CLAIM_QTY; // max tokens that can be minted per transaction
        uint16 MAX_ADDRESS_PUBLIC_SALE_CLAIM_QTY; // max tokens that can be minted per address (public sale)
        uint16 BONUS_QTY; // if public sale transaction mints more than this qty then free mint is granted per each bonus qty
        uint16 FREE_MINT_RANGE_END; // makes a range of tokens free (e.g first 500 minted during public sale)
        uint64 SALE_MINT_PRICE;
    }

    SaleConfig public saleConfig;

    function setAdmins(address[] calldata _admins, bool _isActive)
        external
        isAdminOrOwner
    {
        for (uint256 i = 0; i < _admins.length; i++) {
            admins[_admins[i]] = _isActive;
        }
    }

    function setFreeMintRangeEnd(uint256 offset) external isAdminOrOwner {
        // config that helps create a range of free tokens for public sale
        // this should be activated only after presale is over

        saleConfig.FREE_MINT_RANGE_END = uint16(_totalMinted() + offset);
    }

    function setBatchSize(uint16 _batchSize) external isAdminOrOwner {
        saleConfig.BATCH_SIZE = _batchSize;
    }

    function setBonusQty(uint16 _bonusQty) external isAdminOrOwner {
        saleConfig.BONUS_QTY = _bonusQty;
    }

    function setSigner(address _signer) external isAdminOrOwner {
        signer = _signer;
    }

    function setProxyRegistryAddress(address _proxyRegistry)
        external
        isAdminOrOwner
    {
        require(!IS_PROXY_REGISTRY_LOCKED, "proxy registry is locked");
        proxyRegistryAddress = _proxyRegistry;
    }

    function lockProxyRegistry() external isAdminOrOwner {
        IS_PROXY_REGISTRY_LOCKED = true;
    }

    function setMaxTxPublicSaleQty(uint16 _maxQty) external isAdminOrOwner {
        saleConfig.MAX_TX_PUBLIC_SALE_CLAIM_QTY = _maxQty;
    }

    function setMaxAddressPublicSaleQty(uint16 _maxQty)
        external
        isAdminOrOwner
    {
        saleConfig.MAX_ADDRESS_PUBLIC_SALE_CLAIM_QTY = _maxQty;
    }

    function setIsPublicSaleOn(bool _isOn, uint16 _publicSaleKey)
        external
        isAdminOrOwner
    {
        saleConfig.IS_PUBLIC_SALE_ON = _isOn;
        saleConfig.PUBLIC_SALE_KEY = _publicSaleKey;
    }

    function setIsPresaleOn(bool _isOn) external isAdminOrOwner {
        saleConfig.IS_PRESALE_ON = _isOn;
    }

    function reduceMaxTotalSupply(uint16 _newMaxTotalSupply)
        external
        isAdminOrOwner
    {
        require(
            (_newMaxTotalSupply < saleConfig.MAX_TOTAL_SUPPLY) &&
                (_totalMinted() <= _newMaxTotalSupply)
        );

        saleConfig.MAX_TOTAL_SUPPLY = _newMaxTotalSupply;
    }

    function lockMetadata() external isAdminOrOwner {
        IS_METADATA_LOCKED = true;
    }

    function setSaleMintPrice(uint256 _newSaleMintPrice)
        external
        isAdminOrOwner
    {
        saleConfig.SALE_MINT_PRICE = uint64(_newSaleMintPrice);
    }

    function setMetadataProvider(address _provider) external isAdminOrOwner {
        require(!IS_METADATA_LOCKED, "metadata is locked");
        metadataProvider = _provider;
    }

    function setBaseURI(string calldata _baseURI) external isAdminOrOwner {
        require(!IS_METADATA_LOCKED, "metadata is locked");
        BASE_URI = _baseURI;
    }

    function _checkIfSenderIsOrigin() private view {
        require(tx.origin == msg.sender, "Cannot be called from a contract");
    }

    function _isAdminOrOwner() private view {
        require(
            admins[msg.sender] || owner() == msg.sender,
            "caller is not admin or owner"
        );
    }

    modifier isAdminOrOwner() {
        _isAdminOrOwner();
        _;
    }

    modifier senderIsOrigin() {
        _checkIfSenderIsOrigin();
        _;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function withdraw() external isAdminOrOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _batchMint(
        address _address,
        uint256 _claimQty,
        uint16 _batchSize
    ) private {
        uint256 batches = _claimQty / _batchSize;
        uint256 lastBatch = _batchSize;

        if (_claimQty % _batchSize != 0) {
            batches += 1;
            lastBatch = _claimQty % _batchSize;
        }

        for (uint256 i; i < batches; i++) {
            _safeMint(_address, i + 1 == batches ? lastBatch : _batchSize);
        }
    }

    function airdropMintTo(address _address, uint256 _qty)
        external
        isAdminOrOwner
    {
        SaleConfig memory cfg = saleConfig;
        require(
            _totalMinted() + _qty <= cfg.MAX_TOTAL_SUPPLY,
            "exceeds collection size"
        );
        _setAux(_address, uint64(_getAux(_address) + _qty));
        _batchMint(_address, _qty, cfg.BATCH_SIZE);
    }

    function redeemVoucher(
        address _address,
        uint256 _approvedQty,
        uint256 _price,
        uint256 _nonce,
        uint256 _expiryTimestamp,
        bool _isLastItemFree,
        uint256 _claimQty,
        bytes calldata _voucher
    ) external payable senderIsOrigin {
        SaleConfig memory cfg = saleConfig;

        require(cfg.IS_PRESALE_ON, "presale is not active");
        require(
            _totalMinted() + _claimQty <= cfg.MAX_TOTAL_SUPPLY,
            "exceeds collection size"
        );

        if (_expiryTimestamp != 0) {
            require(block.timestamp < _expiryTimestamp, "voucher is expired");
        }

        bytes32 hash = keccak256(
            abi.encodePacked(
                _address,
                _approvedQty,
                _price,
                _nonce,
                _expiryTimestamp,
                _isLastItemFree
            )
        );

        require(_verifySignature(signer, hash, _voucher), "invalid signature");

        uint256 totalWithClaimed = voucherToMinted[uint256(hash)] + _claimQty;
        require(totalWithClaimed <= _approvedQty, "exceeds approved qty");
        voucherToMinted[uint256(hash)] += _claimQty;

        // Make last item free if voucher allows
        string memory err = "not enough funds sent";
        if (totalWithClaimed == _approvedQty && _isLastItemFree) {
            require(msg.value >= _price * (_claimQty - 1), err);
        } else {
            require(msg.value >= _price * _claimQty, err);
        }

        // incrementing total number of minted vouchers
        uint64 newTotalMintedVouchers = uint64(_getAux(_address) + _claimQty);
        _setAux(_address, newTotalMintedVouchers);

        _batchMint(_address, _claimQty, cfg.BATCH_SIZE);
        emit VoucherUsed(_address, _nonce, _claimQty);
    }

    function mintSale(uint256 _claimQty, uint256 _publicSaleKey)
        external
        payable
        senderIsOrigin
    {
        SaleConfig memory cfg = saleConfig;
        require(cfg.IS_PUBLIC_SALE_ON, "sale is not active");
        require(cfg.PUBLIC_SALE_KEY == _publicSaleKey, "wrong key");

        if (cfg.FREE_MINT_RANGE_END < _totalMinted() + _claimQty) {
            // calculate discount
            uint256 discount = cfg.BONUS_QTY == 0
                ? 0
                : _claimQty / cfg.BONUS_QTY;

            require(
                msg.value >= cfg.SALE_MINT_PRICE * (_claimQty - discount),
                "not enough funds sent"
            );
        }

        require(
            _totalMinted() + _claimQty <= cfg.MAX_TOTAL_SUPPLY,
            "exceeds collection size"
        );
        require(
            _claimQty <= cfg.MAX_TX_PUBLIC_SALE_CLAIM_QTY,
            "claiming too much"
        );

        if (cfg.MAX_ADDRESS_PUBLIC_SALE_CLAIM_QTY != 0) {
            require(
                _numberMinted(msg.sender) - _getAux(msg.sender) + _claimQty <=
                    cfg.MAX_ADDRESS_PUBLIC_SALE_CLAIM_QTY,
                "exceeds allowed claim quantity per address"
            );
        }

        _batchMint(msg.sender, _claimQty, cfg.BATCH_SIZE);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() public view returns (uint256) {
        return _burnCounter;
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function numberBurned(address _owner) public view returns (uint256) {
        return _numberBurned(_owner);
    }

    function numberMintedVouchers(address _owner)
        public
        view
        returns (uint256)
    {
        return _getAux(_owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "query for nonexistent token");

        return
            metadataProvider != address(0)
                ? MetadataProvider(metadataProvider).tokenURI(_tokenId)
                : string(abi.encodePacked(BASE_URI, _tokenId.toString()));
    }

    function tokenData(uint256 _tokenId) public view returns (bytes memory) {
        require(_exists(_tokenId), "query for nonexistent token");
        require(metadataProvider != address(0), "metadata provider is not set");

        return MetadataProvider(metadataProvider).tokenData(_tokenId);
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool)
    {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
            proxyRegistryAddress
        );

        return
            (proxyRegistryAddress != address(0) &&
                address(proxyRegistry.proxies(_owner)) == _operator) ||
            super.isApprovedForAll(_owner, _operator);
    }

    function batchTransferFrom(
        address _from,
        address[] calldata _to,
        uint256[] calldata _tokenIds,
        bool _safe
    ) public {
        if (_safe) {
            for (uint256 i; i < _tokenIds.length; i++) {
                safeTransferFrom(_from, _to[i], _tokenIds[i]);
            }
            return;
        }

        for (uint256 i; i < _tokenIds.length; i++) {
            transferFrom(_from, _to[i], _tokenIds[i]);
        }
    }

    function batchBurn(uint256[] calldata _tokenIds) public {
        for (uint256 i; i < _tokenIds.length; i++) {
            burn(_tokenIds[i]);
        }
    }

    function _verifySignature(
        address _signer,
        bytes32 _hash,
        bytes memory _signature
    ) private pure returns (bool) {
        return
            _signer ==
            ECDSA.recover(ECDSA.toEthSignedMessageHash(_hash), _signature);
    }
}

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}