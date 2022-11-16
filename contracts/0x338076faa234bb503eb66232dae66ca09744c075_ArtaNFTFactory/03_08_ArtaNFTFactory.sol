// File: contracts/OpenGateNFTV3.sol

pragma solidity =0.6.6;
import "./Vendor.sol";
import "./Initializable.sol";
import "./IWhiteList.sol";
import "./IArtaNFTFactory.sol";
import "./ArtaNFT.sol";

contract ArtaNFTFactory is AccessControl, Initializable, IArtaNFTFactory {
    bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');

    mapping(address => bool) nftMap;
    address[] public nfts;

    IWhiteList public whiteList;
    mapping(address => bool) private _BlacklistMarketplaces;

    event Create(address indexed sender, string indexed name, address indexed nft, string symbol, address coin, address feeAcount, uint256 feeAmout);
    event SetOpen(address indexed sender, bool indexed open);
    event SetAdmin(address indexed sender, address indexed account);
    event SetCoin(address indexed sender, address indexed coin);
    event SetAccount(address indexed sender, address indexed account);
    event SetAmount(address indexed sender, uint256 indexed amount);
    
    function initialize(
        IWhiteList _whiteList
    ) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        whiteList = _whiteList;
    }

    function deployNFT(
        string memory name,
        string memory symbol,
        string memory defaultTokenURI_,
        bool isOpen_,
        address coin,
        address payable feeAccount,
        uint256 feeAmount,
        uint256 _maxMintLimit
    ) public onlyAdmin returns (address pair) {
        return _deployNFT(            
            name,
            symbol,
            defaultTokenURI_,
            isOpen_,
            coin,
            feeAccount,
            feeAmount,
            _maxMintLimit
            );
    }

    // function upgradeLogic(address _nftLogic) public onlyAdmin {
    //     nftLogic = _nftLogic;
    //     for (uint256 i = 0; i < nfts.length; i++) {
    //         BEP20UpgradeableProxy(payable(nfts[i])).upgradeTo(_nftLogic);
    //     }
    // }

    function upgradeWhiteList(IWhiteList _whiteList) public onlyAdmin {
        whiteList = _whiteList;
    }


    function _deployNFT(
        string memory name,
        string memory symbol,
        string memory defaultTokenURI_,
        bool isOpen_,
        address coin,
        address payable feeAccount,
        uint256 feeAmount,
        uint256 _maxMintLimit
    ) private returns (address pair) {
        ArtaNFT nft = new ArtaNFT(name, symbol, defaultTokenURI_, isOpen_, coin, feeAccount, feeAmount, _maxMintLimit);
        pair = address(nft);
        _addNFT(pair);
        emit Create(_msgSender(), name, pair, symbol, coin, feeAccount, feeAmount);
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Must have admin role');
        _;
    }

    function _addNFT(address _nft) private {
        nftMap[_nft] = true;
        nfts.push(_nft);
    }

    function setAdmin(address _address) public onlyAdmin {
        _setupRole(DEFAULT_ADMIN_ROLE, _address);
        emit SetAdmin(_msgSender(), _address);
    }

    function beforeMint(address addr, bytes32[] calldata merkleProof) external override returns (uint256) {
        address token = msg.sender;
        require(nftMap[token], 'NFT contract not found');
        bool allOpen = whiteList.getCollectionAllOpen(token);
        uint256 price = whiteList.whiteListPrice(token, addr, merkleProof);
        require(allOpen || price != 0, 'Mint not opening');
        if(price != 0)
            whiteList.addWhiteListUsedCount(token, addr);
        return price;
    }

    function setWhiteList(
        address token,
        bytes32 merkleRoot,
        string calldata merkleTreeFile,
        uint256 price,
        uint256 limit
    ) external onlyAdmin {
        whiteList.setWhiteList(token, merkleRoot, merkleTreeFile, price, limit);
    }

        function setCollectionWhiteListOpen(address token, bool open)
        external
        onlyAdmin
    {
        whiteList.setCollectionWhiteListOpen(token, open);
    }

    function setCollectionAllOpen(address token, bool open) external onlyAdmin {
        whiteList.setCollectionAllOpen(token, open);
    }

    function setBlacklistMarketplace(address[] memory markets, bool[] memory approved) public onlyAdmin {
        require(markets.length == approved.length, "Invalid Param");
        for(uint256 i=0; i<markets.length; i++) {
            _BlacklistMarketplaces[markets[i]] = approved[i];
        }
    }

    function checkBlacklistMarketplaces(address addr) external override {
        require(_BlacklistMarketplaces[addr] == false, "BlackList Marketplace");
    }

    function isAdmin(address addr) external view override returns (bool){
        return  addr == address(this) || hasRole(DEFAULT_ADMIN_ROLE, addr);
    }
}