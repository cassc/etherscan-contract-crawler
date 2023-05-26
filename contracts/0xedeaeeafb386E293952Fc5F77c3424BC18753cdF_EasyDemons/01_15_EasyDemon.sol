// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
                                          
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";


contract EasyDemons is ERC721A, Ownable, ReentrancyGuard, PullPayment {
    using Strings for uint256;
    bytes32 public root;
    bytes32 public raffleRoot;

    // all stage used in frontend
    enum Stage {
        Shutdown,
        PublicSale,
        WaitPresale,
        Presale,
        WaitRaffle,
        RaffleSale,
        Pause,
        DevMint,
        Clearance
    }

    struct TokenBatchPriceData {
        uint256 pricePaid;
        uint256 qtyMinted;
    }

    mapping(address => TokenBatchPriceData[]) public userToTokenBatchPriceData;

    Stage public stage;
    bool public isDutchAuction = true;
    bool isEnableClaim = false;
    
    // begin::Prod
    uint256 public constant MAX_STEP = 12;
    uint256 public constant AUCTION_PERIOD = 30 minutes;

    uint256 public constant MAX_DEVMINT_SUPPLY = 333;
    uint256 public constant MAX_PRESALE_SUPPLY = 4000;
    uint256 public constant MAX_WL_SUPPLY = 3990;
    uint256 public constant MAX_PUBLIC_SUPPLY = 2666;
    uint256 public constant TOTAL_SUPPLY = 6666;

    uint256 public constant DISCOUNT_RATE = 0.05 ether;
    uint256 public constant AUCTION_INITIAL_PRICE = 0.6 ether;
    uint256 public constant AUCTION_BOTTOM_PRICE = 0;
    // end::Prod

    // begin::Dev
    // uint256 public constant MAX_STEP = 5;
    // uint256 public constant AUCTION_PERIOD = 5 minutes;

    // uint256 public constant MAX_DEVMINT_SUPPLY = 1;
    // uint256 public constant MAX_PRESALE_SUPPLY = 5;
    // uint256 public constant MAX_WL_SUPPLY = 4;
    // uint256 public constant MAX_PUBLIC_SUPPLY = 5;
    // uint256 public constant TOTAL_SUPPLY = 15;

    // uint256 public constant DISCOUNT_RATE = 0.05 ether;
    // uint256 public constant AUCTION_INITIAL_PRICE = 0.6 ether;
    // uint256 public constant AUCTION_BOTTOM_PRICE = 0;
    // end::Dev

    uint256 public publicSaleAllowance = 6;
    uint256 public finalPrice = 0;
    uint256 public normalPrice = 0.6 ether;
    uint256 public presalePrice = 0.13 ether;
    uint256 public rafflePrice = 0.13 ether;

    uint256 public presaleQtyMinted;
    mapping(address => uint256) public presalePurchases;
    uint256 public publicQtyMinted;
    mapping(address => uint256) public publicSalePurchases;
    uint256 public raffleQtyMinted;
    mapping(address => uint256) public raffleSalePurchases;
    uint256 public devMintQtyMinted;
    mapping(address => uint256) public devMintPurchases;

    string private _contractURI;
    string private _baseTokenURI;
    string private _defaultTokenURI;
    uint256 public DA_STARTING_AT;

    address private constant walletA = 0xb5B8D71B82ABf6bB21e432FF7E02eDcDC840d7ca;
    address private constant walletB = 0xa4589D18B04Dd6B6ca606F9cbFb3c3B5Ac2DDDd8;
    address private constant walletC = 0x9a69B8134C7676Db6B84a868d6bDE5B989Bb32CB;

    modifier onlySender {
        require(msg.sender == tx.origin, "caller is not the sender");
        _;
    }

    constructor(
        string memory defaultTokenURI,
        bytes32 merkleroot
    ) 
        ERC721A("Easy Demons", "DEMON")  
    {
        _defaultTokenURI = defaultTokenURI;
        root = merkleroot;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
    
    function setMerkleRoot(bytes32 merkleroot) onlyOwner external 
    {
        root = merkleroot;
    }

    function setRaffleRoot(bytes32 merkleroot) onlyOwner external {
        raffleRoot = merkleroot;
    }

    function presaleQtyRemaining() public view returns (uint256) {
        return MAX_WL_SUPPLY - presaleQtyMinted;
    }

    function publicSaleQtyRemaining() public view returns (uint256) {
        return MAX_PUBLIC_SUPPLY - publicQtyMinted;
    }

    function raffleSaleQtyRemaining() public view returns (uint256) {
        return raffleSaleSupply() - raffleQtyMinted;
    }

    function raffleSaleSupply() public view returns (uint256) {
        return presaleQtyRemaining() + publicSaleQtyRemaining() - devMintQtyMinted;
    }

    function price() public view returns (uint256) {
        if(stage == Stage.PublicSale && isDutchAuction == true) {
            return _auctionPricing();
        }

        if(stage == Stage.PublicSale && isDutchAuction == false) {
            return normalPrice;
        }

        if(stage == Stage.Presale) {
            return finalPrice * 60 / 100;
        }

        if(stage == Stage.RaffleSale) {
            return rafflePrice;
        }

        return normalPrice;
    }

    function _auctionPricing() internal view returns (uint256) {
        if(DA_STARTING_AT > block.timestamp) {
            return 0;
        }

        uint256 timeElapsed = block.timestamp - DA_STARTING_AT;
        uint256 step = timeElapsed / AUCTION_PERIOD;

        if(step < MAX_STEP) {
            return AUCTION_INITIAL_PRICE - (DISCOUNT_RATE * step);
        }

        return AUCTION_BOTTOM_PRICE;
    }
    
    function setNormalPrice(uint256 price_) external onlyOwner {
        normalPrice = price_;
    }

    function setPresalePrice(uint256 price_) external onlyOwner {
        presalePrice = price_;
    }

    function setRafflePrice(uint256 price_) external onlyOwner {
        rafflePrice = price_;
    }

    // devMint == gifting
    function devMint(address to, uint256 tokenQuantity) external onlyOwner {
        require(stage == Stage.DevMint, "not active");
        require(totalSupply() + tokenQuantity <= TOTAL_SUPPLY, "exceed alloc");
        require(devMintQtyMinted + presaleQtyMinted + tokenQuantity <= MAX_PRESALE_SUPPLY, "exceed presale alloc" );
        require(devMintQtyMinted + tokenQuantity <= MAX_DEVMINT_SUPPLY, "exceed devmint alloc");

        devMintQtyMinted += tokenQuantity;
        _safeMint(to, tokenQuantity);
        
    }

     function clearanceMint(address to, uint256 tokenQuantity) external onlyOwner {
        require(stage == Stage.Clearance, "not active");
        require(totalSupply() + tokenQuantity <= TOTAL_SUPPLY, "exceed alloc");

        _safeMint(to, tokenQuantity);
        
    }

    function presaleMint(uint256 tokenQuantity, uint256 allowance, bytes32[] calldata proof) external payable onlySender nonReentrant {
        require(_verify(_leaf(msg.sender, allowance), proof), "invalid MP");
        require(stage == Stage.Presale, "not active");
        require(totalSupply() + tokenQuantity <= TOTAL_SUPPLY, "exceed alloc");
        require(presaleQtyMinted + tokenQuantity <= MAX_WL_SUPPLY, "exceed presale alloc");
        require(tokenQuantity <= allowance, "exceed trx allow");
        require(presalePurchases[msg.sender] + tokenQuantity <= allowance, "exceed wal allow");
        require(price() * tokenQuantity == msg.value, "ETH not match");

        presalePurchases[msg.sender] += tokenQuantity;

        presaleQtyMinted+=tokenQuantity;
        _safeMint(msg.sender, tokenQuantity);
        
    }

    function raffleMint(uint256 tokenQuantity, uint256 allowance, bytes32[] calldata proof) external payable onlySender nonReentrant {
        require(_verify(_leaf(msg.sender, allowance), proof), "invalid MP");
        require(stage == Stage.RaffleSale, "not active");
        require(totalSupply() + tokenQuantity <= TOTAL_SUPPLY, "exceed alloc");
        require(raffleQtyMinted + tokenQuantity <= raffleSaleSupply(), "exceed raffle alloc");
        require(tokenQuantity <= allowance, "exceed trx allow");
        require(balanceOf(msg.sender) <= tokenQuantity + allowance, "exceed wal allow");
        require(price() * tokenQuantity == msg.value, "ETH not match");

        raffleSalePurchases[msg.sender] += tokenQuantity;

        raffleQtyMinted+=tokenQuantity;
        _safeMint(msg.sender, tokenQuantity);
    
    }

    function publicMint(uint256 tokenQuantity) external payable onlySender nonReentrant {
        require(stage == Stage.PublicSale, "not active");
        require(totalSupply() + tokenQuantity <= TOTAL_SUPPLY, "exceed alloc");
        require(publicQtyMinted + tokenQuantity <= MAX_PUBLIC_SUPPLY, "exceed public alloc");
        require(tokenQuantity <= publicSaleAllowance, "exceed trx allow");
        uint256 costToMint = price() * tokenQuantity;
        require(msg.value >= costToMint, "eth value incorrect");
        if(isDutchAuction == true) {
            require(block.timestamp >= DA_STARTING_AT, "auction not started");
        }

        publicSalePurchases[msg.sender] += tokenQuantity;

        publicQtyMinted += tokenQuantity;
        _safeMint(msg.sender, tokenQuantity);
        

        _addAuctionPurchaseHistory(msg.sender, msg.value, tokenQuantity);

        if(publicSaleQtyRemaining() == 0) {
            finalPrice = price();
        }

        if(msg.value > costToMint) {
            (bool success,) = msg.sender.call{ value: msg.value - costToMint }("");
            require(success, "Address: unable to send value, recipient may have reverted");
        }
    }

    function _addAuctionPurchaseHistory(address buyer, uint256 pricePaid, uint256 qtyMinted) internal {
        if(isDutchAuction == false) return;

        TokenBatchPriceData[] storage histories = userToTokenBatchPriceData[buyer];
        histories.push(TokenBatchPriceData(pricePaid, qtyMinted));
    }

    function _removeAuctionPurchaseHistory(address buyer) internal {
        TokenBatchPriceData[] storage histories = userToTokenBatchPriceData[buyer];

        for(uint256 i = histories.length; i > 0; i--) {
            histories.pop();
        }
    }

    function isEligibleClaim(address buyer) public view returns (bool) {
        TokenBatchPriceData[] memory histories = userToTokenBatchPriceData[buyer];

        if(histories.length == 0) return false;

        return true; 
    }

    function claimableAmount(address buyer) public view returns (uint256) {
        TokenBatchPriceData[] memory histories = userToTokenBatchPriceData[buyer];
        uint256 _claimableAmount = 0;

        for(uint256 i; i < histories.length; i++) {
            _claimableAmount += histories[i].pricePaid - ( finalPrice * histories[i].qtyMinted );
        }

        return _claimableAmount;
    }

    function spentAmount(address buyer) external view returns (uint256) {
        TokenBatchPriceData[] memory histories = userToTokenBatchPriceData[buyer];
        uint256 _spentAmount = 0;

        for(uint256 i; i < histories.length; i++) {
            _spentAmount += histories[i].pricePaid;
        }

        return _spentAmount;
    }

    function spentQty(address buyer) external view returns (uint256) {
        TokenBatchPriceData[] memory histories = userToTokenBatchPriceData[buyer];
        uint256 _spentQty = 0;

        for(uint256 i; i < histories.length; i++) {
            _spentQty += histories[i].qtyMinted;
        }

        return _spentQty;
    }

    function setClaimStatus(bool status) external onlyOwner {
        isEnableClaim = status;
    }

    function claimRefund() external nonReentrant() {
        require(isEnableClaim == true, "not enabled");
        require(isEligibleClaim(msg.sender) == true, "not eligible");
        uint256 _claimableAmount = claimableAmount(msg.sender);
        require(address(this).balance >= _claimableAmount, "not enough balance");
        
        _removeAuctionPurchaseHistory(msg.sender);
        _asyncTransfer(msg.sender, _claimableAmount);
        withdrawPayments(payable(msg.sender));
    }

    // get all token by owner addresss
    function tokensOfOwner(address address_) public virtual view returns (uint256[] memory) {
        uint256 _balance = balanceOf(address_);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = totalSupply();
        for (uint256 i = 0; i < _loopThrough; i++) {
            bool _exists = _exists(i);
            if (_exists) {
                if (ownerOf(i) == address_) { _tokens[_index] = i; _index++; }
            }
            else if (!_exists && _tokens[_balance - 1] == 0) { _loopThrough++; }
        }
        return _tokens;
    }
    
    function withdraw() external onlyOwner {
        uint256 walletABalance = address(this).balance * 50 / 100;
        uint256 walletBBalance = address(this).balance * 41 / 100;
        uint256 walletCBalance = address(this).balance * 9 / 100;

        Address.sendValue(payable(walletA), walletABalance);
        Address.sendValue(payable(walletB), walletBBalance);
        Address.sendValue(payable(walletC), walletCBalance);
    }

    // change stage presale, sale, and shutdown
    function setStage(Stage _stage) external onlyOwner {
        stage = _stage;
    }

    function setAuctionTimestamp(uint256 timestamp) external onlyOwner {
        DA_STARTING_AT = timestamp;
    }

    function setDutchAuctionStatus(bool status_) external onlyOwner {
        isDutchAuction = status_;
    }

    function setPublicAllowance(uint256 _allowance) external onlyOwner {
        publicSaleAllowance = _allowance;
    }
    
    function getPublicAllowance() external view returns (uint256) {
        return publicSaleAllowance;
    }

    function earning() external view returns (string memory){
        return (address(this).balance).toString();
    }

    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }
    
    function setBaseURI(string calldata URI) external onlyOwner {
        _baseTokenURI = URI;
    }
    
    function setDefaultTokenURI(string calldata URI) external onlyOwner {
        _defaultTokenURI = URI;
    }
    
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function baseURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    // get tokenURI by index, add default base uri
    function tokenURI(uint256 tokenId) public override view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _baseURI = baseURI();
        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId.toString())) : _defaultTokenURI;
    }


    function _leaf(address account, uint256 allowance) internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, allowance));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }
}