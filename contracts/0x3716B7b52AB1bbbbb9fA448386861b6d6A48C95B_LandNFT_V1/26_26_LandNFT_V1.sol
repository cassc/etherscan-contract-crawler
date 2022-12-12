// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

/// @title LandNFT Version 1.0
contract LandNFT_V1 is Initializable, ERC721Upgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for *;

    uint256 constant public MAX_SUPPLY_MINT = 5000;
    uint256 constant public MINT_LIMIT = 20;
    uint256 constant public MINT_PRICE_USDC = 500000000;

    bytes32 public whitelistMerkleRoot;
    bytes32 public discount2PerMerkleRoot;
    bytes32 public discount3PerMerkleRoot;
    bytes32 public discount5PerMerkleRoot;

    uint256 public maxSupply;
    uint256 public maxSupplyMint;

    address public treasuryAddress;

    string public baseURI;

    uint256 private _tokenIdList;

    IERC20 public usdcToken;
    ERC721 public token;

    mapping (uint256 => bool) public isNonMintTokenIds;
    mapping (uint256 => string) public tokenUriHash;

    uint256 public tokenIdListIndex;
    uint256 public tokenIdListIndexCounter;
    mapping (uint256 => uint256) public tokenIdList;

    uint256 public totalSupply;
    uint256 public numberOfPurchases;

    event SetWhitelistMerkleRootEvent(bytes32 _whitelistMerkleRoot);
    event SetTreasuryAddressEvent(address _treasuryAddress);
    event SetRemoveMintEvent(uint256[] _tokenIds);
    event TransferTokensEvent(address indexed account, string tokenURI);
    event PurchasedNftPriceEvent(address indexed account, uint256 price);

    /* ========== CONSTRUCTOR ============= */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory __baseURI,
        uint256 _maxSupply,
        uint256 _maxSupplyMint,
        bytes32 _whitelistMerkleRoot,
        bytes32 _discount2PerMerkleRoot,
        bytes32 _discount3PerMerkleRoot,
        bytes32 _discount5PerMerkleRoot,
        address _usdcAddress,
        address _treasuryAddress
    ) public initializer {
        baseURI = __baseURI;
        maxSupply = _maxSupply;
        maxSupplyMint = _maxSupplyMint;

        whitelistMerkleRoot = _whitelistMerkleRoot;
        discount2PerMerkleRoot = _discount2PerMerkleRoot;
        discount3PerMerkleRoot = _discount3PerMerkleRoot;
        discount5PerMerkleRoot = _discount5PerMerkleRoot;

        usdcToken = IERC20(_usdcAddress);
        treasuryAddress = _treasuryAddress;

        totalSupply = 0;
        tokenIdListIndex = 0;
        tokenIdListIndexCounter = 0;
        numberOfPurchases = 0;

        baseURI = __baseURI;

        __Ownable_init();
        __ERC721_init("EDOLANDNFT", "EDOLAND");
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @param tokenId uint256
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory __baseURI = _baseURI();
        return bytes(__baseURI).length > 0 ? string(abi.encodePacked(__baseURI, tokenUriHash[tokenId])) : "";
    }

    /* ========== BEFORE PUBLICATION ============= */

    /**
     * @param _whitelistMerkleRoot bytes32
     */
    function setWhitelistMerkleRoot(
        bytes32 _whitelistMerkleRoot
    )
        external
        onlyOwner
    {
        whitelistMerkleRoot = _whitelistMerkleRoot;

        emit SetWhitelistMerkleRootEvent(_whitelistMerkleRoot);
    }

    /**
     * @param _root bytes32
     * @param _discountPercent uint256
     */
    function setDiscountMerkleRoot(
        bytes32 _root,
        uint256 _discountPercent
    )
        external
        onlyOwner
    {
        require(
            _discountPercent == 2 || _discountPercent == 3 || _discountPercent == 5,
            "LandNFT: setDiscountMerkleRoot: Please select one of 2,3,5"
        );

        if (_discountPercent == 2) {
            discount2PerMerkleRoot = _root;
        } else if (_discountPercent == 3) {
            discount3PerMerkleRoot = _root;
        } else if (_discountPercent == 5) {
            discount5PerMerkleRoot = _root;
        }
    }

    /**
     * @param _treasuryAddress address
     */
    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        require(
            _treasuryAddress != address(0),
            "LandNFT: setTreasuryAddress: set from the zero address"
        );

        treasuryAddress = _treasuryAddress;
        
        emit SetTreasuryAddressEvent(_treasuryAddress);
    }

    /**
     * @param _tokenIds uint256[]
     * @param _length uint256
     * @param _bool bool
     */
    function setRemoveMint(
        uint256[] memory _tokenIds,
        uint256 _length,
        bool _bool
    )
        external
        onlyOwner
    {
        for (uint i = 0; i < _length; i++) {
            require(i < _length, "LandNFT: setRemoveMint: The length of tokenIds and length do not match");
            isNonMintTokenIds[_tokenIds[i]] = _bool;
        }

        emit SetRemoveMintEvent(_tokenIds);
    }

    /**
     * @param __tokenIdList uint256[]
     * @param __tokenUriList uint256[]
     */
    function setTokenUriHash (
        uint256[] memory __tokenIdList,
        string[] memory __tokenUriList
    )
        external
        onlyOwner
    {
        require(__tokenIdList.length == __tokenUriList.length);

        for (uint16 i; i < __tokenIdList.length; i++) {
            uint256 tokenId = __tokenIdList[i];
            tokenUriHash[tokenId] = __tokenUriList[i];

            tokenIdList[tokenIdListIndexCounter] = tokenId;
            tokenIdListIndexCounter.add(1);
        }
    }

    /**
     * @param _tokenId uint256
     * @return bool
     */
    function isRemoveMint(uint256 _tokenId) public view returns(bool) {
        return isNonMintTokenIds[_tokenId];
    }

    /**
     * @param _maxSupplyMint uint256
     */
    function setSupplyMint(uint256 _maxSupplyMint) external onlyOwner {
        maxSupplyMint = _maxSupplyMint;
    }

    /* ========== AFTER PUBLICATION ============= */

    /**
     * @return _totalSupply uint256
     * @return _maxSupplyMint uint256
     */
    function supplyInfo() public view returns(
        uint256 _totalSupply,
        uint256 _maxSupplyMint
    ) {
        return (totalSupply, maxSupplyMint);
    }

    /**
     * @param _ethereumAddress address
     * @return uint256
     */
    function getMintableNumber(
        address _ethereumAddress
    )
        public
        view
        returns (uint256)
    {
        return MINT_LIMIT.sub(ERC721Upgradeable.balanceOf(_ethereumAddress));
    }

    /**
     * @param _mintNum uint256
     * @param _whitelistMerkleProof bytes32[]
     */
    function buy(
        uint256 _mintNum, 
        bytes32[] calldata _whitelistMerkleProof,
        bytes32[] calldata _discount2PerMerkleProof,
        bytes32[] calldata _discount3PerMerkleProof,
        bytes32[] calldata _discount5PerMerkleProof
    ) external {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProofUpgradeable.verify(_whitelistMerkleProof, whitelistMerkleRoot, leaf),
            "LandNFT: buy: Invalid proof"
        );

        require(_mintNum <= MINT_LIMIT, "LandNFT: buy: Invalid number of purchases");

        uint256 totalBalance = ERC721Upgradeable.balanceOf(msg.sender).add(_mintNum);
        require(totalBalance <= MINT_LIMIT, "LandNFT: buy: You have exceeded the maximum number of purchases");
        require(_mintNum < MAX_SUPPLY_MINT.sub(totalSupply), "LandNFT: buy: Invalid number of mint");

        uint256 tokenPrice = getTokenPrice(
            _discount2PerMerkleProof,
            _discount3PerMerkleProof,
            _discount5PerMerkleProof
        );

        require(
            usdcToken.balanceOf(msg.sender) >= tokenPrice.mul(_mintNum),
            "LandNFT: buy: Insufficient balance"
        );

        transferTokens(_mintNum, tokenPrice);
    }

    /* ========== OTHER OPARATION ============= */

    function mintTo(
        address recipient,
        uint256 count,
        uint256[] memory tokenIds
    )
        external
        onlyOwner
    {
        require(
            recipient != address(0),
            "LandNFT: mintTo: mint from the zero address"
        );

        for (uint256 i; i < count; i++) {
            require(isNonMintTokenIds[tokenIds[i]], "LandNFT: mintTo: Error");
            _safeMint(recipient, tokenIds[i]);
            totalSupply++;
        }
    }

    /* ========== INTERNAL ============= */

    /**
     * @notice If multiple discounts are eligible, apply the highest discount
     * @param _discount2PerMerkleProof bytes32[]
     * @param _discount3PerMerkleProof bytes32[]
     * @param _discount5PerMerkleProof bytes32[]
     */
    function getTokenPrice(
        bytes32[] calldata _discount2PerMerkleProof,
        bytes32[] calldata _discount3PerMerkleProof,
        bytes32[] calldata _discount5PerMerkleProof
    )
        view
        internal
        returns(uint256)
    {
        uint256 tokenPrice = MINT_PRICE_USDC;
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        if (MerkleProofUpgradeable.verify(_discount2PerMerkleProof, discount2PerMerkleRoot, leaf)) {
            tokenPrice = MINT_PRICE_USDC.sub(MINT_PRICE_USDC.mul(2).div(100));
        }
        if (MerkleProofUpgradeable.verify(_discount3PerMerkleProof, discount3PerMerkleRoot, leaf)) {
            tokenPrice = MINT_PRICE_USDC.sub(MINT_PRICE_USDC.mul(3).div(100));
        }
        if (MerkleProofUpgradeable.verify(_discount5PerMerkleProof, discount5PerMerkleRoot, leaf)) {
            tokenPrice = MINT_PRICE_USDC.sub(MINT_PRICE_USDC.mul(5).div(100));
        }

        return tokenPrice;
    }

    /**
     * @param _mintNum uint256
     * @param _tokenPrice uint256
     */
    function transferTokens(uint256 _mintNum, uint256 _tokenPrice) internal {
        for (uint256 i; i < _mintNum; i++) {
            for (uint256 index; index < MAX_SUPPLY_MINT; index++) {
                uint256 tokenId = tokenIdList[tokenIdListIndex];
                if (!isNonMintTokenIds[tokenId]) {
                    _safeMint(msg.sender, tokenId);
                    totalSupply++;
                    tokenIdListIndex++;
                    numberOfPurchases++;
                    emit TransferTokensEvent(msg.sender, tokenURI(tokenId));
                    break;
                } else {
                    tokenIdListIndex++;
                }
            }
        }
        usdcToken.transferFrom(msg.sender, treasuryAddress, _tokenPrice.mul(_mintNum));
        emit PurchasedNftPriceEvent(msg.sender, _tokenPrice.mul(_mintNum));
    }
}