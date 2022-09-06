/*
 ██████╗██████╗ ██╗   ██╗██████╗ ████████╗██╗    ██╗███████╗ █████╗ ██████╗
██╔════╝██╔══██╗╚██╗ ██╔╝██╔══██╗╚══██╔══╝██║    ██║██╔════╝██╔══██╗██╔══██╗
██║     ██████╔╝ ╚████╔╝ ██████╔╝   ██║   ██║ █╗ ██║█████╗  ███████║██████╔╝
██║     ██╔══██╗  ╚██╔╝  ██╔═══╝    ██║   ██║███╗██║██╔══╝  ██╔══██║██╔══██╗
╚██████╗██║  ██║   ██║   ██║        ██║   ╚███╔███╔╝███████╗██║  ██║██║  ██║
 ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝        ╚═╝    ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝
https://cryptwear.io/
https://linktr.ee/cryptwear
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract CryptWear is ERC721, Ownable, ReentrancyGuard {

    enum MintType{PREMINT, ALLOWLIST, PUBLIC, GIFT}

    struct MintSettings {
        uint256 maxPreMintId;
        uint256 preMintIdNext;

        uint256 maxId;
        uint256 idNext;

        uint256 maxGiveaway;
        uint256 giveawayCounter;

        uint256 allowlistSalePrice;
        uint256 publicSalePrice;

        uint256 maxPreMintPerWallet;
        uint256 maxAllowlistMintPerWallet;

        bool publicMint;
    }

    struct WithdrawSettings {
        address withdrawAddress1;
        address withdrawAddress2;
        uint256 withdrawAddress2percentage;
    }

    function setWithdrawSettings(
        address _withdrawAddress1,
        address _withdrawAddress2,
        uint256 _withdrawAddress2percentage
    ) public onlyOwner {
        require(!withdrawSettingsFrozen, "settings frozen");
        withdrawSettings.withdrawAddress1 = _withdrawAddress1;
        withdrawSettings.withdrawAddress2 = _withdrawAddress2;
        withdrawSettings.withdrawAddress2percentage = _withdrawAddress2percentage;
    }

    function setMintSettings(
        uint256 _maxId,
        uint256 _maxGiveaway,

        uint256 _allowlistSalePrice,
        uint256 _publicSalePrice,

        uint256 _maxPreMintPerWallet,
        uint256 _maxAllowlistMintPerWallet,

        bool _publicMint
    ) public onlyOwner {
        require(!mintSettingsFrozen, "settings frozen");
        require(_maxGiveaway <= 100, "max giveaway < 100");
        require(_maxId <= 2400, "maxId <= 2400");
        mintSettings.maxId = _maxId;

        mintSettings.maxGiveaway = _maxGiveaway;

        mintSettings.allowlistSalePrice = _allowlistSalePrice;
        mintSettings.publicSalePrice = _publicSalePrice;

        mintSettings.maxPreMintPerWallet = _maxPreMintPerWallet;
        mintSettings.maxAllowlistMintPerWallet = _maxAllowlistMintPerWallet;

        mintSettings.publicMint = _publicMint;
    }

    MintSettings public mintSettings;
    WithdrawSettings public withdrawSettings;

    string private _collectionURI;
    string public baseURI;

    // used to validate allowlists
    bytes32 public preMerkleRoot;
    bytes32 public allowlistMerkleRoot;
    bytes32 public giftMerkleRoot;


    // keep track of those on allowlist who have claimed their NFT
    mapping(address => bool) public claimedAllowlist;
    mapping(address => bool) public claimedPre;
    mapping(address => bool) public claimedGift;


    bool public mintSettingsFrozen;
    bool public metadataFrozen;
    bool public contractURIFrozen;
    bool public withdrawSettingsFrozen;
    bool public revealed;
    address public proxyRegistryAddress;
    bool public proxyRegistryAddressAllowlistedApproved;


    constructor(string memory _baseURI, string memory collectionURI)
    ERC721("CryptWear", "C-WEAR")
    {
        proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
        proxyRegistryAddressAllowlistedApproved = true;


        setBaseURI(_baseURI, false);
        setCollectionURI(collectionURI);

        _mint(owner(), 1);

        mintSettings.maxPreMintId = 400;
        mintSettings.preMintIdNext = 2;

        mintSettings.maxId = 2400;
        mintSettings.idNext = 401;

        mintSettings.allowlistSalePrice = 0.2 ether;
        mintSettings.publicSalePrice = 0.25 ether;

        mintSettings.maxPreMintPerWallet = 10;
        mintSettings.maxAllowlistMintPerWallet = 10;

        withdrawSettings.withdrawAddress1 = 0x1eE3B20965C2C284c416542D481DEC028153Cb69;
        withdrawSettings.withdrawAddress2 = 0xAD57194cFdD9e7b64D681bcA51563B8bcf3F1CAd;

        withdrawSettings.withdrawAddress2percentage = 10;

        mintSettings.maxGiveaway = 100;
    }

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier canMint(uint256 numberOfTokens, MintType mintType) {
        if (mintType == MintType.PREMINT)
            require(
                (mintSettings.preMintIdNext - 1 + numberOfTokens) <= (mintSettings.maxPreMintId),
                "Not enough tokens remaining to mint"
            );
        else {
            require(
                (mintSettings.idNext - 1 + numberOfTokens) <= (mintSettings.maxId),
                "Not enough tokens remaining to mint"
            );

            if (mintType == MintType.PUBLIC)
                require(mintSettings.publicMint, "public mint disabled");


            if (mintType == MintType.ALLOWLIST)
                require(numberOfTokens <= mintSettings.maxAllowlistMintPerWallet, "Max wallet amount reached");


            else if (mintType == MintType.GIFT)
            {
                require(mintSettings.giveawayCounter + numberOfTokens <= mintSettings.maxGiveaway, "maxGiveaway reached!");
                mintSettings.giveawayCounter += numberOfTokens;
            }
        }
        _;
    }

    function mintPre(address to, uint256 amount, bytes32[] calldata proof)
    external
    canMint(amount, MintType.PREMINT) nonReentrant
    {
        require(amount <= mintSettings.maxPreMintPerWallet, "Max wallet amount reached");

        // Throw if address has already claimed tokens
        require(!claimedPre[to], "NFT is already claimed by this wallet");

        // Verify merkle proof, or revert if not in tree
        bytes32 leaf = keccak256(abi.encodePacked(to, amount));
        bool isValidLeaf = MerkleProof.verify(proof, preMerkleRoot, leaf);
        require(isValidLeaf, "not part of Merkle tree");

        claimedPre[to] = true;
        for (uint256 i = 0; i < amount; i++) {
            _mint(to, mintSettings.preMintIdNext++);
        }
    }


    function mintAllowlist(address to, uint256 amount, uint256 amountMaxByLeaf, bytes32[] calldata proof)
    external
    payable
    canMint(amount, MintType.ALLOWLIST)
    isCorrectPayment(mintSettings.allowlistSalePrice, amount)
    nonReentrant
    {
        // Throw if address has already claimed tokens
        require(!claimedAllowlist[to], "NFT is already claimed by this wallet");
        require(amount <= amountMaxByLeaf, "amount <= amountMaxByLeaf");

        // Verify merkle proof, or revert if not in tree
        bytes32 leaf = keccak256(abi.encodePacked(to, amountMaxByLeaf));
        bool isValidLeaf = MerkleProof.verify(proof, allowlistMerkleRoot, leaf);
        require(isValidLeaf, "not part of Merkle tree");

        claimedAllowlist[to] = true;
        for (uint256 i = 0; i < amount; i++) {
            _mint(to, mintSettings.idNext++);
        }
    }


    function mintGift(address to, uint256 amount, bytes32[] calldata proof)
    external
    canMint(amount, MintType.GIFT)
    nonReentrant
    {
        // Throw if address has already claimed tokens
        require(!claimedGift[to], "NFT is already claimed by this wallet");

        // Verify merkle proof, or revert if not in tree
        bytes32 leaf = keccak256(abi.encodePacked(to, amount));
        bool isValidLeaf = MerkleProof.verify(proof, giftMerkleRoot, leaf);
        require(isValidLeaf, "not part of Merkle tree");

        claimedGift[to] = true;
        for (uint256 i = 0; i < amount; i++) {
            _mint(to, mintSettings.idNext++);
        }
    }

    /**
    * @dev mints specified # of tokens to sender address
    */
    function mintPublic(address to, uint256 amount)
    external
    payable
    isCorrectPayment(mintSettings.publicSalePrice, amount)
    canMint(amount, MintType.PUBLIC)
    nonReentrant
    {
        for (uint256 i = 0; i < amount; i++) {
            _mint(to, mintSettings.idNext++);
        }
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============
    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        if (revealed) return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
        return string(abi.encodePacked(baseURI, Strings.toString(0), ".json"));
    }

    /**
    * @dev collection URI for marketplace display
    */
    function contractURI() public view returns (string memory) {
        return _collectionURI;
    }

    /**
       * Override isApprovedForAll to auto-approve OS's proxy contract
       */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
        // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (proxyRegistryAddressAllowlistedApproved && _operator == proxyRegistryAddress) {
            return true;
        }

        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    /**
    * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return mintSettings.maxId;
    }


    // ============ OWNER-ONLY ADMIN FUNCTIONS ============
    function setBaseURI(string memory _baseURI, bool _revealed) public onlyOwner {
        require(!metadataFrozen, "metadata frozen");
        baseURI = _baseURI;
        revealed = _revealed;
    }

    /**
    * @dev set collection URI for marketplace display
    */
    function setCollectionURI(string memory collectionURI) public onlyOwner {
        require(!contractURIFrozen, "contractURI frozen");
        _collectionURI = collectionURI;
    }

    function setProxyRegistryAddressAllowlistedApproved(bool _proxyRegistryAddressAllowlistedApproved) public onlyOwner {
        proxyRegistryAddressAllowlistedApproved = _proxyRegistryAddressAllowlistedApproved;
    }

    function setPreMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        preMerkleRoot = _merkleRoot;
    }

    function setAllowlistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        allowlistMerkleRoot = _merkleRoot;
    }

    function setGiftMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        giftMerkleRoot = _merkleRoot;
    }

    function freezeMintSettings() external onlyOwner {
        require(!mintSettingsFrozen, "already frozen");
        mintSettingsFrozen = true;
    }

    function freezeMetadata() external onlyOwner {
        require(!metadataFrozen, "already frozen");
        metadataFrozen = true;
    }


    function freezeWithdrawSettings() external onlyOwner {
        require(!withdrawSettingsFrozen, "already frozen");
        withdrawSettingsFrozen = true;
    }

    function freezeContractURI() external onlyOwner {
        require(!contractURIFrozen, "already frozen");
        contractURIFrozen = true;
    }

    /**
     * @dev withdraw funds for to specified account
     */
    function withdraw() public {
        require((
            (owner() == _msgSender()) ||
            (withdrawSettings.withdrawAddress1 == _msgSender()) ||
            (withdrawSettings.withdrawAddress2 == _msgSender())
            ), "Caller is not owner neither in the withdraw list");
        uint256 withdrawAddress2percentage = address(this).balance * withdrawSettings.withdrawAddress2percentage / 100;
        payable(withdrawSettings.withdrawAddress2).transfer(withdrawAddress2percentage);
        payable(withdrawSettings.withdrawAddress1).transfer(address(this).balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }


}