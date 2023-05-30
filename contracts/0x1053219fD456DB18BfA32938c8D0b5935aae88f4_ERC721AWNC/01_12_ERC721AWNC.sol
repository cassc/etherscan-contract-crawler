// SPDX-License-Identifier: MIT
// Creator: Chiru Labs
// modified: robbie oh ([email protected])

pragma solidity ^0.8.9;

import './ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract ERC721AWNC is ERC721A, Ownable {
    uint256 internal constant MAX_SUPPLY = 10_203;
    uint256 internal constant MIGRATION_AMOUNT = 884;
    uint256 internal constant PARTNERS_CAP = 2_000;
    uint256 internal constant BASE_PRICE = 0.09 ether;

    uint256 public privatePrice = BASE_PRICE;
    uint256 public publicPrice = BASE_PRICE;
    uint256 public maxPrivateAmountPerAddress = 5;
    uint256 public maxPublicAmountPerTransaction = 100;

    uint256 public partnersMintedAmount;

    uint256 public publicMintedAmount;
    uint256 public maxPublicSaleSupply;

    bytes32 private _merkleRootWhitelist;

    bool internal _isLocked = false; // TODO discuss if making it public

    bool public isMigrated = false;
    bool public isPrivateSaleOpened = false;
    bool public isPublicSaleOpened = false;

    uint32 public currentPrivateRound = 0;

    string internal _currentBaseURL = 'https://storage.googleapis.com/weirdnomadclub/metadata/';

    mapping(uint256 => string) public ipfsURI;

    event MigrationMinted(address migrationWalletAddress, uint256 baseTokenId, uint256 amount);
    event PartnersMinted(address partnersWalletAddress, uint256 amount);

    event PrivateMinted(address minter, uint256 amount);
    event PublicMinted(address minter, uint256 amount);
    event MerkleRootWhitelistChanged(bytes32 newMerkleRoot);

    event PrivateSaleOpened();
    event PrivateSaleClosed();
    event PublicSaleOpened();
    event PublicSaleClosed();

    event IPFSURLSet(uint256 tokenId, string uri);

    constructor() Ownable() ERC721A('Weird Nomad Club Genesis', 'WNCG') {}

    modifier afterMigrated() {
        require(isMigrated, 'NFT: not migrated yet');
        _;
    }

    modifier onPrivateSale() {
        require(isPrivateSaleOpened, 'NFT: not opened private sale');
        _;
    }

    modifier onPublicSale() {
        require(isPublicSaleOpened, 'NFT: not opened public sale');
        _;
    }

    modifier limitSupply(uint256 _amount) {
        require((totalSupply() + _amount) <= MAX_SUPPLY, 'NFT: exceeded total supply');
        _;
    }

    modifier notContractCall() {
        require(tx.origin == msg.sender, 'NFT: not allowed contract call');
        _;
    }

    function mintPrivate(uint256 _amount, bytes32[] calldata _merkleProof)
        external
        payable
        onPrivateSale
        limitSupply(_amount)
    {
        require(msg.value == _amount * privatePrice, 'NFT: not paid exact price');
        require(isWhitelist(msg.sender, _merkleProof), 'NFT: not whitelisted');

        if (currentPrivateRound != _getPrivateRound(msg.sender)) {
            _setPrivateRound(msg.sender, currentPrivateRound);
        }

        require(
            (_getPrivateAmount(msg.sender) + _amount) <= maxPrivateAmountPerAddress,
            'NFT: exceeded private amount per address'
        );

        _incPrivateAmount(msg.sender, uint32(_amount));
        _safeMint(msg.sender, _amount);

        emit PrivateMinted(msg.sender, _amount);
    }

    function _getPrivateRound(address owner) internal view returns (uint32) {
        return uint32((_getAux(owner) >> 32) & 0xffffffff);
    }

    function _getPrivateAmount(address owner) internal view returns (uint32) {
        return uint32(_getAux(owner) & 0xffffffff);
    }

    function _setPrivateRound(address owner, uint32 round) internal {
        // NOTE set `round` and also reset amount to 0
        _setAux(owner, uint64(round) << 32);
    }

    function _incPrivateAmount(address owner, uint32 amount) internal {
        _setAux(owner, (_getAux(owner) & 0xffffffff00000000) | (_getPrivateAmount(owner) + amount));
    }

    function mintPublic(uint256 _amount) external payable onPublicSale limitSupply(_amount) notContractCall {
        require(msg.value == _amount * publicPrice, 'NFT: not paid exact price');
        require(_amount <= maxPublicAmountPerTransaction, 'NFT: exceeded public amount per transaction');
        require(
            maxPublicSaleSupply == 0 || publicMintedAmount + _amount <= maxPublicSaleSupply,
            "NFT: exceeded public sale's supply"
        );

        _safeMint(msg.sender, _amount);
        publicMintedAmount += _amount;

        emit PublicMinted(msg.sender, _amount);
    }

    // admin
    function mintMigration(
        address _migrationWalletAddress,
        uint256 _baseTokenId,
        uint256 _amount
    ) external onlyOwner {
        require(!isMigrated, 'NFT: already migrated');
        require(_currentIndex == _baseTokenId, 'NFT: invalid baseTokenId');
        require(totalSupply() + _amount <= MIGRATION_AMOUNT, 'NFT: exceeded migration amount');

        _safeMint(_migrationWalletAddress, _amount);

        isMigrated = totalSupply() == MIGRATION_AMOUNT;

        emit MigrationMinted(_migrationWalletAddress, _baseTokenId, _amount);
    }

    function mintPartners(address _partnersWalletAddress, uint256 _amount)
        external
        onlyOwner
        afterMigrated
        limitSupply(_amount)
    {
        require(partnersMintedAmount + _amount <= PARTNERS_CAP, 'NFT: exceeded partners capacity');

        _safeMint(_partnersWalletAddress, _amount);
        partnersMintedAmount += _amount;

        emit PartnersMinted(_partnersWalletAddress, _amount);
    }

    function setMerkleRootWhitelist(bytes32 _newMerkleRootWhitelist) external onlyOwner {
        _merkleRootWhitelist = _newMerkleRootWhitelist;

        emit MerkleRootWhitelistChanged(_newMerkleRootWhitelist);
    }

    function openPrivateSale(uint256 _price, uint256 _maxAmountPerAddress) external onlyOwner afterMigrated {
        require(totalSupply() < MAX_SUPPLY, 'NFT: fully minted total supply');
        require(!isPrivateSaleOpened, 'NFT: already opened private sale');
        require(_price >= BASE_PRICE, 'NFT: lower price than the base price');

        isPrivateSaleOpened = true;
        currentPrivateRound++;
        privatePrice = _price;
        maxPrivateAmountPerAddress = _maxAmountPerAddress;

        emit PrivateSaleOpened();
    }

    function reopenPrivateSale() external onlyOwner afterMigrated {
        require(totalSupply() < MAX_SUPPLY, 'NFT: fully minted total supply');
        require(!isPrivateSaleOpened, 'NFT: already opened private sale');
        require(currentPrivateRound != 0, 'NFT: not found the previous private sale');

        isPrivateSaleOpened = true;

        emit PrivateSaleOpened();
    }

    function closePrivateSale() external onlyOwner {
        require(isPrivateSaleOpened, 'NFT: already closed private sale');

        isPrivateSaleOpened = false;

        emit PrivateSaleClosed();
    }

    // NOTE if `_maxSaleAmount` is `0`, it means `unlmited`.
    function openPublicSale(
        uint256 _price,
        uint256 _maxAmountPerTransaction,
        uint256 _maxSaleSupply
    ) external onlyOwner afterMigrated {
        require(totalSupply() < MAX_SUPPLY, 'NFT: fully minted total supply');
        require(!isPublicSaleOpened, 'NFT: already opened public sale');
        require(_price >= BASE_PRICE, 'NFT: lower price than the base price');

        isPublicSaleOpened = true;
        publicPrice = _price;
        maxPublicAmountPerTransaction = _maxAmountPerTransaction;
        maxPublicSaleSupply = _maxSaleSupply;

        emit PublicSaleOpened();
    }

    function reopenPublicSale() external onlyOwner afterMigrated {
        require(totalSupply() < MAX_SUPPLY, 'NFT: fully minted total supply');
        require(!isPublicSaleOpened, 'NFT: already opened public sale');

        isPublicSaleOpened = true;

        emit PublicSaleOpened();
    }

    function closePublicSale() external onlyOwner {
        require(isPublicSaleOpened, 'NFT: already closed public sale');

        isPublicSaleOpened = false;

        emit PublicSaleClosed();
    }

    function sendEthers(address _to) external onlyOwner {
        payable(_to).transfer(address(this).balance);
    }

    function setBaseURL(string calldata _newBaseURL) external onlyOwner {
        _currentBaseURL = _newBaseURL;
    }

    function setIpfsURI(uint256 tokenId, string calldata uri) public onlyOwner {
        ipfsURI[tokenId] = uri;
        emit IPFSURLSet(tokenId, uri);
    }

    struct TokenUrl {
        uint256 tokenId;
        string uri;
    }

    function setIpfsURIBatch(TokenUrl[] calldata urls) external onlyOwner {
        for (uint256 i = 0; i < urls.length; i++) {
            setIpfsURI(urls[i].tokenId, urls[i].uri);
        }
    }

    function setLocked(bool _locked) external onlyOwner {
        require(_isLocked != _locked, 'NFT: same locked status');
        _isLocked = _locked;
    }

    /*
    function transferOwnership(address newOwner) public {
    }
    */

    // view
    function isWhitelist(address _address, bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_merkleProof, _merkleRootWhitelist, node);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (bytes(ipfsURI[tokenId]).length == 0) {
            return _tokenURI(tokenId);
        }
        return ipfsURI[tokenId];
    }

    // internal
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        require(!_isLocked, 'NFT: locked token transfer');
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURL;
    }

    fallback() external payable {
        revert();
    }

    receive() external payable {
        revert();
    }
}