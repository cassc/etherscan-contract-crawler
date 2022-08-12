// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract MetaMLP45 is ERC721A, ERC2981, ReentrancyGuard, Ownable {
    using Strings for uint256;

    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;

    string public uri;

    uint256 public mintPrice;
    uint256 public maxSupply;
    uint256 public maxMintQuantityPerTx;
    uint256 public maxPerWallet;

    bool public paused;
    bool public whitelistMintEnabled;
    bool public publicMintEnabled;
    bool public privateMintEnabled;

    address payable public withdrawWallet;
    address payable public royaltySigner;

    uint96 public revenueShareInBips;

    /**
     * @dev Emitted when while the token with `tokenId` transfer from `tokenOwner` to
     * new  `newTokenOwner`.
     */
    event TokenTransferred(
        uint256 indexed tokenId,
        address sender,
        address receiver
    );

    /**
     * @dev Emitted when Revenue share transferred while transfer token for token `tokenId`
     * to `tokenOwner`.
     */
    event RevenueShareTransferred(
        uint256 _tokenId,
        uint256 saleAmt,
        uint256 revenueShare,
        address _receiver
    );
    /**
     * @dev Emitted when Owner withdraw the contract balance
     */
    event Withdraw(address, uint256);
    /**
     * @dev Emitted when Owner updates the mintPrice
     */
    event MintPriceUpdated(address, uint256);
    /**
     * @dev Emitted when Owner updates the maxMintQuantityPerTx
     */
    event MaxMintQuantityPerTxUpdated(address, uint256);
    /**
     * @dev Emitted when Owner updates the URI
     */
    event UriUpdated(address, string);
    /**
     * @dev Emitted when Owner updates the status of pause
     */
    event PauseUpdated(address, bool);
    /**
     * @dev Emitted when Owner updates the merkleRoot
     */
    event MerkleRoot(address, bytes32);
    /**
     * @dev Emitted when Owner updates the status of whitelistMintEnable
     */
    event WhiltelistMintEnableUpdated(address, bool);
    /**
     * @dev Emitted when Owner updates the status of publicMintEnable
     */
    event publicMintEnableUpdated(address, bool);
    /**
     * @dev Emitted when Owner updates the status of privateMintEnable
     */
    event privateMintEnableUpdated(address, bool);
    /**
     * @dev Emitted when Owner updates the maxSupply
     */
    event maxSupplyUpdated(address, uint256);
    /**
     * @dev Emitted when Owner updates the withdrawWallet Address
     */
    event WithdraWalletUpdated(address, address);
    /**
     * @dev Emitted when Owner updates the maxPerWallet
     */
    event MaxPerWalletUpdated(address, uint256);
    /**
     * @dev Emitted when Owner updates the royaltyInfo
     */
    event RoyaltyInfoUpdated(address, address, uint96);
    /**
     * @dev Emitted when Owner updates the royaltySigner Address
     */
    event RoyaltySignerUpdated(address, address);

    /**
     * @dev Initializes the contract
     * ***PARAMETERS***
     *  token name
     *  token symbol
     *  mint price
     *  max token supply
     *  maximum token per wallet
     *  withdraw wallet address
     *  token url,
     *  revenue share percentage in bips
     *  royalty fee percentage in bips
     *
     *  initialize default values
     *  Set royalty info and transfer ownership
     */
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _mintPrice,
        uint256 _maxSupply,
        uint256 _maxMintQuantityPerTx,
        uint256 _maxPerWallet,
        address payable _withdrawWallet,
        string memory _uri,
        uint96 _revenueShareInBips,
        uint96 _royaltyFeesInBips,
        address payable _royaltyOwner
    )
        ERC721A(_tokenName, _tokenSymbol)
        checkNullAddress(_withdrawWallet)
        checkNullAddress(_royaltyOwner)
    {
        setMintPrice(_mintPrice);
        seturi(_uri);
        maxSupply = _maxSupply;
        maxPerWallet = _maxPerWallet;
        withdrawWallet = _withdrawWallet;
        paused = false;
        whitelistMintEnabled = true;
        publicMintEnabled = false;
        privateMintEnabled = true;
        revenueShareInBips = _revenueShareInBips;
        royaltySigner = _royaltyOwner;
        setMaxMintQuantityPerTx(_maxMintQuantityPerTx);
        setRoyaltyInfo(_royaltyOwner, _royaltyFeesInBips);
    }

    /**
     * @dev to zero-check for the passed-in address
     */
    modifier checkNullAddress(address _address) {
        require(_address != address(0x0), "Address is null");
        _;
    }

    /**
     * @dev to check the provided quantity is exceeded with already minted nfts
     */
    modifier mintCompliance(uint256 _quantity) {
        require(
            _quantity > 0 && _quantity <= maxMintQuantityPerTx,
            "Invalid mint Quantity!"
        );
        require(
            totalSupply() + _quantity <= maxSupply,
            "Max supply exceeded, Sold out!"
        );
        _;
    }

    /**
     * @dev to check the msg.value is enough to mint token by multiplying mint price & quantity
     */
    modifier mintPriceCompliance(uint256 _quantity) {
        require(msg.value >= mintPrice * _quantity, "Wrong value!");
        _;
    }

    /**
     * @dev mint `_quantity` amount of token to caller `_msgSender()`.
     *
     * check the `quantity` not exceeded total supply using `mintComplier` modifier
     * check the `msg.value` is greater than price to mint using `mintPriceCompliance` modifier
     *
     * Emits a {TokenMinted} event.
     */
    function mint(uint256 _quantity)
        external
        payable
        mintCompliance(_quantity)
        mintPriceCompliance(_quantity)
    {
        require(!paused, "The contract is paused!");
        require(publicMintEnabled, "minting not enabled");
        require(
            (balanceOf(_msgSender()) + _quantity) <= maxPerWallet,
            "Exceed max per wallet"
        );
        _safeMint(_msgSender(), _quantity);
    }

    /**
     * @dev mint `_quantity` amount of token to a address `_receiver` from owner .
     *
     * check the `quantity` not exceeded total supply using `mintComplier` modifier
     *
     * add receiver in _tokenOwnerList & mint token
     * Emits a {TokenMintedForAddress} event.
     */
    function mintForAddress(uint256 _quantity, address _receiver)
        external
        mintCompliance(_quantity)
        onlyOwner
    {
        require(!paused, "The contract is paused!");
        require(privateMintEnabled, "private minting not enabled");
        require(
            balanceOf(_receiver) + _quantity < maxPerWallet,
            "Exceed max per wallet"
        );
        _safeMint(_receiver, _quantity);
    }

    /**
     * @dev mint `_quantity` amount of token to a whitelist address `_msgSender()` .
     *
     * Note: `_merkleProof` is the proof of merkle tree to identify the caller is whitelisted using merkle root.
     * Emits a {WhitelistedTokenMinted} event.
     */
    function whitelistMint(uint256 _quantity, bytes32[] calldata _merkleProof)
        external
        payable
        mintCompliance(_quantity)
        mintPriceCompliance(_quantity)
    {
        require(!paused, "The contract is paused!");
        // Verify whitelist requirements
        require(whitelistMintEnabled, "whitelist sale is not enabled!");
        require(!whitelistClaimed[_msgSender()], "Already claimed!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );
        whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _quantity);
    }

    /**
     * @dev transfers `tokenId` token from `_msgSender()` to `_receiver`.
     *
     * Emits a {TokenTransferred} event.
     */
    function transfer(uint256 _tokenId, address _receiver)
        external
        nonReentrant
    {
        require(_exists(_tokenId), "Token not existed");
        safeTransferFrom(_msgSender(), _receiver, _tokenId);
        emit TokenTransferred(_tokenId, _msgSender(), _receiver);
    }

    /**
     * @dev transfer revenue share amount to the very first owner of the token
     * calculate revenueShare from the `_saleAmt` amount and transfer the share to the
     * `_user` of the `_tokenId`.
     *
     * Emits a {RevenueShareTransferred} event.
     */
    function transferRevenueShare(
        uint256 _tokenId,
        address _user,
        uint256 _saleAmt
    ) external payable nonReentrant {
        require(_msgSender() == royaltySigner, "Invalid royalty Signer.");
        uint256 _revenueShare = calcRevenueShare(_tokenId, _saleAmt);
        require((_revenueShare * 1 wei) == msg.value, "Invalid Revenue share");
        (bool success, ) = payable(_user).call{value: _revenueShare * 1 wei}(
            ""
        );
        require(success, "Transfer failed");
        emit RevenueShareTransferred(_tokenId, _saleAmt, _revenueShare, _user);
    }

    /**
     * @dev withdraw contract balance to `withdrawWallet`.
     */
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = withdrawWallet.call{value: address(this).balance}(
            ""
        );
        require(success, "withdraw failed");
        emit Withdraw(_msgSender(), address(this).balance);
    }

    /**
     * @dev set mint price for token.
     **/
    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
        emit MintPriceUpdated(_msgSender(), _mintPrice);
    }

    /**
     * @dev set maximum mint amount per tx for token.
     **/
    function setMaxMintQuantityPerTx(uint256 _maxMintQuantityPerTx)
        public
        onlyOwner
    {
        maxMintQuantityPerTx = _maxMintQuantityPerTx;
        emit MaxMintQuantityPerTxUpdated(_msgSender(), _maxMintQuantityPerTx);
    }

    /**
     * @dev set url for token.
     **/
    function seturi(string memory _uri) public onlyOwner {
        uri = _uri;
        emit UriUpdated(_msgSender(), _uri);
    }

    /*** VIEW FUNCTIONS ***/

    /**
     * @dev calculate & returns revenue share amount for token id `_tokenId` using sale amount `_saleAmt`.
     *
     * Note: Check token id already minted and return revenue share amount
     */
    function calcRevenueShare(uint256 _tokenId, uint256 _saleAmt)
        public
        view
        returns (uint256)
    {
        require(_exists(_tokenId), "Token not existed");
        return (_saleAmt * revenueShareInBips) / _feeDenominator();
    }

    /**
     * @dev get balance of the contract.
     **/
    function getBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev toggle the pause/unpause for nft minting.
     **/
    function setPaused(bool _state) external onlyOwner {
        paused = _state;
        emit PauseUpdated(_msgSender(), _state);
    }

    /**
     * @dev set merkle root hash.
     **/
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit MerkleRoot(_msgSender(), _merkleRoot);
    }

    /**
     * @dev toggle the whitelist minting enable or not for nft minting.
     **/
    function setWhitelistMintEnabled(bool _state) external onlyOwner {
        whitelistMintEnabled = _state;
        emit WhiltelistMintEnableUpdated(_msgSender(), _state);
    }

    /**
     * @dev toggle the public minting enable or not for nft minting.
     **/
    function setPublicMintEnabled(bool _publicMintEnabled_) external onlyOwner {
        publicMintEnabled = _publicMintEnabled_;
        emit publicMintEnableUpdated(_msgSender(), _publicMintEnabled_);
    }

    /**
     * @dev toggle the private minting enable or not for nft minting.
     **/
    function setPrivateMintEnabled(bool _privateMintEnabled_)
        external
        onlyOwner
    {
        privateMintEnabled = _privateMintEnabled_;
        emit privateMintEnableUpdated(_msgSender(), _privateMintEnabled_);
    }

    /**
     * @dev set maximum no of token can mint using this contract.
     **/
    function updateMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
        emit maxSupplyUpdated(_msgSender(), _maxSupply);
    }

    /**
     * @dev update wallet of the amount withdraw account from contract.
     **/
    function updateWithdraWallet(address payable _withdrawWallet)
        external
        onlyOwner
        checkNullAddress(_withdrawWallet)
    {
        withdrawWallet = _withdrawWallet;
        emit WithdraWalletUpdated(_msgSender(), _withdrawWallet);
    }

    /**
     * @dev update How many tokens maximum a wallet can mint.
     **/
    function updateMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
        emit MaxPerWalletUpdated(_msgSender(), _maxPerWallet);
    }

    /**
     * @dev get token URI of the specified token `_tokenId`.
     **/
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    /**
     * @dev set royalty percentage to the royalty owner.
     **/
    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips)
        public
        onlyOwner
        checkNullAddress(_receiver)
    {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
        emit RoyaltyInfoUpdated(_msgSender(), _receiver, _royaltyFeesInBips);
    }

    /**
     * @dev set royalty signer.
     **/
    function setRoyaltySigner(address _signer)
        public
        onlyOwner
        checkNullAddress(_signer)
    {
        royaltySigner = payable(_signer);
        emit RoyaltySignerUpdated(_msgSender(), _signer);
    }
    /**
     * @dev view base url of the tokens.
     **/
    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }
    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    /**
     * @dev See {IERC2981-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return (ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId));
    }
}