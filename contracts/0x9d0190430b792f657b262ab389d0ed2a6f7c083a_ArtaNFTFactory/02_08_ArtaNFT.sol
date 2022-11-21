import "./Vendor.sol";
import "./IsAdmin.sol";
import "./IArtaNFTFactory.sol";

pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

contract ArtaNFT is ERC721Pausable, IsAdmin, Ownable {
    string _name;
    string _symbol;

    uint256 public nextTokenId = 1;
    uint256 public maxMintLimit;
    address public feeERC20Address;
    address payable public mintFeeAddr;
    uint256 public mintFeeAmount;
    IArtaNFTFactory public factory;
    string public defaultTokenURI;
    bool public isOpen;

    IERC20 public quoteErc20;
    mapping(uint256 => address payable) public tokenCreators;

    constructor (
        string memory name,
        string memory symbol,
        string memory defaultTokenURI_,
        bool isOpen_,
        address coin,
        address payable feeAccount,
        uint256 feeAmount,
        uint256 _maxMintLimit
    ) public {
        _name = name;
        _symbol = symbol;
        maxMintLimit = _maxMintLimit;
        feeERC20Address = coin;
        quoteErc20 = IERC20(coin);
        mintFeeAddr = feeAccount;
        mintFeeAmount = feeAmount;
        nextTokenId = 1;
        factory = IArtaNFTFactory(_msgSender());
        if(isOpen_)
            setBaseURI(defaultTokenURI_);
        else
            defaultTokenURI = defaultTokenURI_;
    }

    receive() external payable {}

    function mint(bytes32[] memory merkleProof) public payable {
        require(
            maxMintLimit == 0 || nextTokenId <= maxMintLimit,
            "max mint limit has been reached"
        );
        uint256 whiteListPrice = factory.beforeMint(_msgSender(), merkleProof);
        uint256 feeAmount = whiteListPrice == 0 ? mintFeeAmount : whiteListPrice;

        if (feeERC20Address == address(0)) {
            require(msg.value >= feeAmount, "msg value too low");
            mintFeeAddr.transfer(feeAmount);
            _msgSender().transfer(msg.value - feeAmount);
        } else {
            if (feeAmount != 0) {
                quoteErc20 = IERC20(feeERC20Address);
                require(
                    quoteErc20.balanceOf(_msgSender()) >= feeAmount,
                    "your price is too low"
                );
                quoteErc20.transferFrom(
                    _msgSender(),
                    mintFeeAddr,
                    feeAmount
                );
            }
        }

        uint256 tokenId = nextTokenId;
        _mint(_msgSender(), tokenId);
        tokenCreators[tokenId] = _msgSender();
        nextTokenId++;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    // override approve 
    function approve(address to, uint256 tokenId) public virtual override {
        factory.checkBlacklistMarketplaces(to);
        super.approve(to, tokenId);
    }

    // override setApprovalForAll 
    function setApprovalForAll(address operator, bool approved) public virtual override {
        factory.checkBlacklistMarketplaces(operator);
        super.setApprovalForAll(operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        factory.checkBlacklistMarketplaces(from);
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        factory.checkBlacklistMarketplaces(from);
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
    {
        factory.checkBlacklistMarketplaces(from);
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function isAdmin(address addr) external view override returns (bool){
        return factory.isAdmin(addr);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if(!isOpen)
            return defaultTokenURI;
        return super.tokenURI(tokenId);
    }

    function setBaseURI(string memory baseUri) public onlyAdmin {
        _setBaseURI(baseUri);
        isOpen = true;
    }
    
    modifier onlyAdmin() {
        require(factory.isAdmin(_msgSender()), 'Must have admin role');
        _;
    }
}