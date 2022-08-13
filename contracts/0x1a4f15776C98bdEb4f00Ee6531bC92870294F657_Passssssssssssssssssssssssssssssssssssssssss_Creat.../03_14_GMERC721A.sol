pragma solidity ^0.8.7;

import "@nftgm/ERC721A.sol";
import "@openzeppelin/Ownable.sol";
import "@openzeppelin/ECDSA.sol";


    error SaleInactive();
    error SoldOut();
    error InvalidPrice();
    error WithdrawFailed();
    error InvalidQuantity();
    error InvalidProof();


contract GMERC721A is ERC721A, Ownable {
    uint256 public supply;
    uint256 private presaleCount;
    mapping(address => uint256) private airdropAmount;

    struct PreSaleInfo {
        bool open;
        uint64 startTimestamp;
        uint64 endTimestamp;
        uint256 presalePrice;
        uint64 max_mint;
        uint64 presaleSupply;
        bool whiteOpen;
    }


    struct PublicSaleInfo {
        uint64 startTimestamp;
        uint64 endTimestamp;
        uint256 publicSalePrice;
        uint64 max_mint;
    }

    PreSaleInfo public preSaleInfo;
    PublicSaleInfo public publicSaleInfo;

    string public _baseTokenURI;

    address public withdrawAddresses;

    address[]  public receivers;
    uint256[]  public basisPoints;

    // TODO: update Address
    address public validator = 0x1dAc6e36d28EDEF697Be57aCb75c46a63f65A113;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        uint256 _supply,
        address _withdrawAddress,
        PreSaleInfo memory _preSaleInfo,
        PublicSaleInfo memory _publicSaleInfo,
        address[]  memory _receivers,
        uint256[]  memory _basisPoints
    ) ERC721A(_name, _symbol) {
        _baseTokenURI = _baseUri;
        supply = _supply;
        withdrawAddresses = _withdrawAddress;
        preSaleInfo = _preSaleInfo;
        publicSaleInfo = _publicSaleInfo;
        receivers = _receivers;
        basisPoints = _basisPoints;
    }

    function mint(uint256 qty) external payable {
        if (block.timestamp < publicSaleInfo.startTimestamp || block.timestamp > publicSaleInfo.endTimestamp) revert SaleInactive();
        if (_currentIndex + (qty - 1) > supply) revert SoldOut();
        if (msg.value != publicSaleInfo.publicSalePrice * qty) revert InvalidPrice();
        uint256 preSaleMint = _getAux(msg.sender);

        uint256 publicMint = _numberMinted(msg.sender) - preSaleMint + qty - getAirdropMint(msg.sender);
        if (publicMint > publicSaleInfo.max_mint) revert InvalidQuantity();

        _safeMint(msg.sender, qty);
    }

    function presale(uint64 qty, bytes calldata signature) external payable {
        if (!preSaleInfo.open) revert SaleInactive();
        if (block.timestamp < preSaleInfo.startTimestamp || block.timestamp > preSaleInfo.endTimestamp) revert SaleInactive();
        if (presaleCount + qty > preSaleInfo.presaleSupply) revert SoldOut();
        if (msg.value != preSaleInfo.presalePrice * qty) revert InvalidPrice();
        if (preSaleInfo.whiteOpen) {
            checkWhitelistMintValidator(msg.sender, signature);
        }
        uint64 preSaleMint = getPreSaleMint(msg.sender) + qty;
        if (preSaleMint > preSaleInfo.max_mint) revert InvalidQuantity();

        _safeMint(msg.sender, qty);
        _setAux(msg.sender, preSaleMint);
        presaleCount += qty;
    }

    function checkWhitelistMintValidator(address mintToAddress, bytes memory validatorSig) public view {
        bytes32 validatorHash = keccak256(abi.encodePacked(mintToAddress));
        checkSign(validatorSig, ECDSA.toEthSignedMessageHash(validatorHash), validator, "invalid validator sign!");
    }

    function checkSign(bytes memory sign, bytes32 hashCode, address signer, string memory words) public pure {
        require(ECDSA.recover(hashCode, sign) == signer, words);
    }


    function getPreSaleMint(address owner) public view returns (uint64) {
        return _getAux(owner);
    }

    function getPreSaleCount() public view returns (uint256) {
        return presaleCount;
    }


    function getAirdropMint(address owner) public view returns (uint256) {
        return airdropAmount[owner];
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPublicSaleInfo(PublicSaleInfo memory _publicSaleInfo) external onlyOwner {
        publicSaleInfo = _publicSaleInfo;
    }

    function setPresaleInfo(PreSaleInfo memory _preSaleInfo) external onlyOwner {
        preSaleInfo = _preSaleInfo;
    }

    function freeMint(uint256 qty, address recipient) external onlyOwner {
        if (_currentIndex + (qty - 1) > supply) revert SoldOut();
        _safeMint(recipient, qty);
    }

    function airdrop(address[] memory recipients, uint256[] memory qtys) external onlyOwner {
        require(recipients.length == qtys.length, "Invalid input");
        uint256 total = 0;
        for (uint i = 0; i < qtys.length; i++) {
            total += qtys[i];
        }
        if (_currentIndex + (total - 1) > supply) revert SoldOut();

        for (uint i = 0; i < recipients.length; i++) {
            airdropAmount[recipients[i]] += qtys[i];
            _safeMint(recipients[i], qtys[i]);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success,) = withdrawAddresses.call{value : balance}("");
        if (!success) revert WithdrawFailed();
    }

    function setRoyalties(address payable[] calldata _receivers, uint256[] calldata _basisPoints) external onlyOwner {
        receivers = _receivers;
        basisPoints = _basisPoints;
        require(receivers.length == basisPoints.length, "Invalid input");
        uint256 totalBasisPoints;
        for (uint i = 0; i < basisPoints.length; i++) {
            totalBasisPoints += basisPoints[i];
        }
        require(totalBasisPoints < 10000, "Invalid total royalties");
    }

    function royaltyInfo(uint256 tokenId, uint256 value) external view virtual returns (address, uint256) {
        require(_exists(tokenId), "Nonexistent token");
        require(receivers.length <= 1, "More than 1 royalty receiver");

        if (receivers.length == 0) {
            return (address(this), 0);
        }
        return (receivers[0], basisPoints[0] * value / 10000);
    }

    /**
     *  @dev EIP-2981
     *
     * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
     *
     * => 0x2a55205a = 0x2a55205a
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721A)
    returns (bool)
    {
        return super.supportsInterface(interfaceId) || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981;
    }
}