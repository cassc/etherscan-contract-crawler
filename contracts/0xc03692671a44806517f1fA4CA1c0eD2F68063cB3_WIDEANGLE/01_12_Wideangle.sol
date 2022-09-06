// SPDX-License-Identifier: MIT

//WIDEANGLE

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract WIDEANGLE is ERC721, ReentrancyGuard {
    using Strings for uint256;
    address public WIDEANGLE_ADMIN_WALLET;
    address public WIDEANGLE_OWNER;
    IERC20 private constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    struct Category {
        uint256 counter;
        uint256 maxSupply;
        uint256 publicSalePrice;
        uint256 preSalePrice;
        uint256 privateSalePrice;
    }
    mapping (address => uint256) whitelists;
    mapping (address => uint256) addressToMintCount;
    mapping (uint256 => Category) categoryId;
    mapping (uint256 => uint256) category;
    mapping (address => uint256) privateSaleAddresses;
    mapping (uint256 => uint256) mintFunctionsState;
    string _base_URI;
    uint256 _tokenIdCounter;
    uint256 sellIsClose;
    uint256 stableorEth;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PricesChanged(uint256 bronze, uint256 silver, uint256 gold, uint256 diamond);
    event Minted(address ownerAddress, uint256[] categories);
    constructor(string memory name, string memory symbol, string memory baseURI,uint256[] memory categoryMaxSupplies,uint256[] memory categoryCounters,uint256[] memory categoryPrices,uint256[] memory categoryPreSalePrices,uint256[] memory categoryPrivSalePrices)
    ERC721(name, symbol)
    {
        for(uint256 i = 0 ; i <= 3 ; i++){
            categoryId[i].maxSupply = categoryMaxSupplies[i];
            categoryId[i].publicSalePrice = categoryPrices[i];
            categoryId[i].counter= categoryCounters[i];
            categoryId[i].privateSalePrice= categoryPrivSalePrices[i];
            categoryId[i].preSalePrice= categoryPreSalePrices[i];

        }
        WIDEANGLE_OWNER=_msgSender();
        WIDEANGLE_ADMIN_WALLET=0x408743abff75a89148FB5E84e38C7181747BB365;
        _tokenIdCounter+=1;
        _base_URI = baseURI;
        sellIsClose=1;
        stableorEth= 0;
    }

    modifier onlyOwner() {
        require(WIDEANGLE_OWNER == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    modifier privatesaleTime() {
        require(mintFunctionsState[0]==1,"Private sale is not available.");
        _;
    }

    modifier presaleTime() {
        require(mintFunctionsState[1]==1,"Presale is not available.");
        _;
    }

    modifier publicsaleTime() {
        require(mintFunctionsState[2]==1,"Public sale is not available.");
        _;
    }


    function addWhitelist(address[] memory whitelistAddresses) external onlyOwner {
        for(uint256 i = 0 ; i< whitelistAddresses.length; i++){
            whitelists[whitelistAddresses[i]]=1;
        }

    }

    function whichCategory(uint256 tokenId) external view returns(string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if(category[tokenId]==0) return "BRONZE";
        else if(category[tokenId]==1) return "SILVER";
        else if(category[tokenId]==2) return "GOLD";
        else return "DIAMOND";
    }

    function setBaseURI(string memory newUri)
    external
    onlyOwner {
        _base_URI = newUri;

    }

    function ownerMint(uint numberOfTokens, uint256 _category)
    external
    onlyOwner
    {
        require(categoryId[_category].counter+numberOfTokens<=categoryId[_category].maxSupply,"Exceeds total supply");
        for (uint i = 0; i < numberOfTokens; i++) {
            mint(_category);
        }
    }

    function privateSale(uint256[] memory categories)
    external
    nonReentrant
    privatesaleTime

    {
        require(privateSaleAddresses[_msgSender()] == 1,"Unidentified wallet address.");
        require(categories.length>0 , "Wrong category.");
        require(categories.length<=4 , "Maximum mint count exceeded.");
        uint256 price = 0;
        for(uint256 i = 0 ;i < categories.length ; i++){
            price += categoryId[categories[i]].privateSalePrice;
        }
        USDT.transferFrom(_msgSender(),WIDEANGLE_ADMIN_WALLET,price);
        for (uint256 i = 0 ;i < categories.length ; i++){
            uint256 _category = categories[i];
            require(_category<=3 , "Wrong category.");
            require(_category>=0 , "Wrong category.");
            require(categoryId[_category].counter+1<=categoryId[_category].maxSupply,"Exceeds total supply.");
            mint(_category);
        }
        emit Minted(_msgSender(),categories);
    }

    function preSaleMint(uint256 [] memory _categories)
    external
    nonReentrant
    presaleTime
    payable
    {
        require(whitelists[_msgSender()]==1,"You are not whitelisted.");
        require(_categories.length>0 , "Wrong category.");
        require(_categories.length<=4 , "Maximum mint count exceeded.");
        uint256 price = 0;
        if(stableorEth==0){
            require(msg.value==0);
            for(uint256 i = 0 ;i < _categories.length ; i++){
                price += categoryId[_categories[i]].preSalePrice;
            }
            USDT.transferFrom(_msgSender(),WIDEANGLE_ADMIN_WALLET,price);
        }
        else{
            for(uint256 i = 0 ;i < _categories.length ; i++){
                price += categoryId[_categories[i]].preSalePrice;
            }
            require(msg.value==price);
            payable(WIDEANGLE_ADMIN_WALLET).transfer(msg.value);
        }
        for (uint256 i = 0 ;i < _categories.length ; i++){
            uint256 _category = _categories[i];
            require(_category<=3 , "Wrong category.");
            require(_category>=0 , "Wrong category.");
            require(categoryId[_category].counter+1<=categoryId[_category].maxSupply,"Exceeds total supply");
            mint(_category);
        }
        emit Minted(_msgSender(),_categories);

    }
    function publicSaleMint(uint256[] memory categories)
    external
    nonReentrant
    publicsaleTime
    payable
    {
        require(categories.length>0 , "Wrong category.");
        require(categories.length<=4 , "Maximum mint count exceeded.");
        uint256 price = 0;
        if(stableorEth==0){
            require(msg.value==0);
            for(uint256 i = 0 ;i < categories.length ; i++){
                price += categoryId[categories[i]].publicSalePrice;
            }
            USDT.transferFrom(_msgSender(),WIDEANGLE_ADMIN_WALLET,price);
        }
        else{
            for(uint256 i = 0 ;i < categories.length ; i++){
                price += categoryId[categories[i]].publicSalePrice;
            }
            require(msg.value==price,"wrong price");
            payable(WIDEANGLE_ADMIN_WALLET).transfer(msg.value);
        }
        for (uint256 i = 0 ;i < categories.length ; i++){
            uint256 _category = categories[i];
            require(_category<=3 , "Wrong category.");
            require(_category>=0 , "Wrong category.");
            require(categoryId[_category].counter+1<=categoryId[_category].maxSupply,"Exceeds total supply");
            mint(_category);
        }
        emit Minted(_msgSender(),categories);

    }


    function mint(uint256 _category) internal {
        uint256 tokenId = categoryId[_category].counter;
        categoryId[_category].counter ++;
        _tokenIdCounter ++;
        category[tokenId] = _category;
        addressToMintCount[_msgSender()]++;
        _mint(_msgSender(), tokenId);
    }


    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(_base_URI, tokenId.toString(),".json"));

    }

    function changeOwner(address newOwner) external onlyOwner{
        address oldOwner = WIDEANGLE_OWNER;
        WIDEANGLE_OWNER = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);

    }
    function changeAdmin(address newAdmin) external onlyOwner{
        WIDEANGLE_ADMIN_WALLET= newAdmin;

    }
    function totalSupply() public view returns (uint) {
        return _tokenIdCounter - 1;
    }

    function changePublicSaleMintPrice(uint256 bronze, uint256 silver, uint256 gold, uint256 diamond) external onlyOwner{
        categoryId[0].publicSalePrice=bronze;
        categoryId[1].publicSalePrice=silver;
        categoryId[2].publicSalePrice=gold;
        categoryId[3].publicSalePrice=diamond;
        emit PricesChanged(bronze,silver,gold,diamond);

    }
    function changePreSaleMintPrice(uint256 bronze, uint256 silver, uint256 gold, uint256 diamond) external onlyOwner{
        categoryId[0].preSalePrice=bronze;
        categoryId[1].preSalePrice=silver;
        categoryId[2].preSalePrice=gold;
        categoryId[3].preSalePrice=diamond;
        emit PricesChanged(bronze,silver,gold,diamond);

    }
    function changePrivateSaleMintPrice(uint256 bronze, uint256 silver, uint256 gold, uint256 diamond) external onlyOwner{
        categoryId[0].privateSalePrice=bronze;
        categoryId[1].privateSalePrice=silver;
        categoryId[2].privateSalePrice=gold;
        categoryId[3].privateSalePrice=diamond;
        emit PricesChanged(bronze,silver,gold,diamond);

    }
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(sellIsClose==0,"You can not sell");
        _setApprovalForAll(_msgSender(), operator, approved);
    }
    function setPrivateSaleAddresses(address[] memory addresses) external onlyOwner{
        for(uint256 i = 0 ; i < addresses.length; i++){
            privateSaleAddresses[addresses[i]] = 1;

        }
    }
    function approve(address to, uint256 tokenId) public virtual override {

        require(sellIsClose==0,"You can not sell");
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }
    function setSalePermission() external onlyOwner{
        sellIsClose = 0;
    }
    function switchMintFunction(uint256 whichFunction)external onlyOwner {
        for(uint256 i = 0 ; i<3; i++){
            mintFunctionsState[i] = whichFunction ==i ? 1: 0;
        }
    }
    function paymentMethod(uint256 _switch) external onlyOwner{
        stableorEth=_switch;
    }
}