// SPDX-License-Identifier: Apache-2.0



/*
    ███████╗ █████╗  ██████╗ ██╗     ███████╗███╗   ██╗███████╗████████╗
    ██╔════╝██╔══██╗██╔════╝ ██║     ██╔════╝████╗  ██║██╔════╝╚══██╔══╝
    █████╗  ███████║██║  ███╗██║     █████╗  ██╔██╗ ██║█████╗     ██║
    ██╔══╝  ██╔══██║██║   ██║██║     ██╔══╝  ██║╚██╗██║██╔══╝     ██║
    ███████╗██║  ██║╚██████╔╝███████╗███████╗██║ ╚████║██║        ██║
    ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═══╝╚═╝        ╚═╝
*/

pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

import "./Interface/token/ERC721/ERC721.sol";
import "./Interface/token/ERC20/IERC20.sol";
import "./Interface/utils/Strings.sol";
import "./Interface/utils/Base64.sol";

// @custom:security-contact EAGLE TEAM
contract EAGLENFT is ERC721 {
    using Strings for uint256;
    // @EAGLETOKEN EAGLE ERC20 address
    IERC20 public EAGLETOKEN;

    address public immutable NFTWallet;
    uint128 public TigerEagleCardTAllowancel;
    uint128 public PhoenixEagleCardTAllowancel;
    // @imageURL EAGLENT imageURL
    string[25] private imageURL;

    // @initToken This variable is used only once
    uint128 private initToken = 1;
    uint128 private batchMint = 3;
    uint128 private _currentSupply;

    // @tokenConfig NFT configure
    struct tokenConfig {
        uint256 creationTime;
        uint256 EAGLESerial;
        bool onSale;
        mapping(uint256 => bool) Receive;
        uint256 orderId;
        uint256 nftUrlId;
    }

    // @orderNFTList NFT market order configure
    //lowerShelf： Judge whether the order exists
    struct orderNFTList {
        uint256 tokenId;
        uint256 price;
        uint256 NFTListingTime;
        bool lowerShelf;
        address listingAddr;
}

    // @NFTDate Record user address and type
    struct NFTDate {
        address owner;
        uint256 serial;
    }

    // @NFTConfig NFT configure Point by NFT Token Id
    mapping(uint256 => tokenConfig) private NFTConfig;
    // @orderNFTLists NFT market order configure Point by NFT market order Id
    orderNFTList[] private orderNFTLists;
    // @NFTConfig
    mapping(uint256 => NFTDate) public NFTCurrency;
    mapping(address => uint256[]) public myNFT;
    mapping(address => uint256[]) public myOrderIds;
    mapping(uint256=>uint256[])private orderTypeId;
    mapping(uint256 => bool) private NFTEstablish;

    event listNFTEvent(
        uint256 tokenId,
        uint256 price,
        uint256 listingTime,
        bool onSale
    );
    event buyNFTEvent(
        uint256 tokenId,
        address from,
        address to,
        uint256 price,
        bool onSale,
        bool lowerShelf
    );
    event cancelNFTListEvent(uint256 tokenId, bool lowerShelf, bool onSale);

    constructor()
        ERC721("EAGLENFT", "EAGLE")
    {
        NFTWallet = 0xE9b96157c80407ABf53176E930b40d51dae6c9D7;
        TigerEagleCardTAllowancel = 68;
        PhoenixEagleCardTAllowancel = 688;
    }

    // @init init EagleToken This function can only be used once
    // The purpose is to load EagleToken address
    // init img ipfs url
    function init(string[25] memory imgUrl,address _EagleToken)external{
        require(initToken == 1,"initToken is not 1");
        EAGLETOKEN = IERC20(_EagleToken);
        for (uint i = 0;i<imgUrl.length;i++){
            imageURL[i] = imgUrl[i];
        }
        initToken = 0;
    }

    function mint(uint256 tokenId) private {
        NFTCurrency[tokenId].owner = NFTWallet;
        _mint(NFTWallet, tokenId);
        _currentSupply++;
        myNFT[NFTWallet].push(tokenId);
    }

    // @mintTigerEagleCard Mint TigerEagleCard
    function mintTigerEagleCard() private {
        uint256 tokenId = _currentSupply;
        NFTCurrency[tokenId].serial = 0;
        mint(tokenId);
        NFTConfig[tokenId].EAGLESerial = 0;
        NFTConfig[tokenId].nftUrlId = tokenId % 15;
    }

    // @mintPhoenixEagleCard Mint PhoenixEagleCard
    function mintPhoenixEagleCard() private {
        uint256 tokenId = _currentSupply;
        NFTCurrency[tokenId].serial = 1;
        mint(tokenId);
        NFTConfig[tokenId].EAGLESerial = 1;
        NFTConfig[tokenId].nftUrlId = tokenId % 10 + 15;
    }

    function mintAllNFT1()external{
        require(batchMint == 3,"batchMint is not 3");
        uint128  TigerEagleCardTnum = 68;
        uint128  PhoenixEagleCardNum = 229;
        for(uint128 i = 0;i<TigerEagleCardTnum;i++){
            mintTigerEagleCard();
        }
        for(uint128 i = 0;i<PhoenixEagleCardNum;i++){
            mintPhoenixEagleCard();
        }
        batchMint = 2;
    }


    function mintAllNFT2()external{
        require(batchMint == 2,"batchMint is not 2");
        uint128  PhoenixEagleCardNum = 229;
        for(uint128 i = 0;i<PhoenixEagleCardNum;i++){
            mintPhoenixEagleCard();
        }
        batchMint = 1;
    }

    function mintAllNFT3()external{
        require(batchMint == 1,"batchMint is not 1");
        uint128  PhoenixEagleCardNum = 230;
        for(uint128 i = 0;i<PhoenixEagleCardNum;i++){
            mintPhoenixEagleCard();
        }
        batchMint = 0;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (NFTEstablish[tokenId] == false) {
            NFTConfig[tokenId].creationTime = block.timestamp;
            NFTEstablish[tokenId] = true;
        }
        NFTCurrency[tokenId].owner = from;
        removeOwnerId(from, tokenId);
        super._transfer(from, to, tokenId);
        myNFT[to].push(tokenId);
    }

    // @removeOwnerId remove my nft from tokenid
    function removeOwnerId(address user, uint256 tokenId) private {
        uint256 ownerNum = balanceOf(user);
        uint256 index;
        for (uint256 i = 0; i < ownerNum; i++) {
            if (myNFT[user][i] == tokenId) {
                index = i;
            }
        }
        require(index < myNFT[user].length, "index is not myNFT[user].length");
        for (uint256 i = index; i < myNFT[user].length - 1; i++) {
            myNFT[user][i] = myNFT[user][i + 1];
        }
        myNFT[user].pop();
    }

    // @myNFTTokenIds return my NFT IDS
    function myNFTTokenIds() public view returns (uint256[] memory) {
        return myNFT[msg.sender];
    }
    function myOrderIdList() public view returns (uint256[] memory) {
        return myOrderIds[msg.sender];
    }

    function removeOrderIds(address user, uint256 orderid) private {
        uint256 OrderIdNum =  myOrderIds[msg.sender].length;
        uint256 index;
        for (uint256 i = 0; i < OrderIdNum; i++) {
            if (myOrderIds[user][i] == orderid) {
                index = i;
            }
        }
        require(index < myOrderIds[user].length, "index is not myOrderIds[user].length");
        for (uint256 i = index; i < myOrderIds[user].length - 1; i++) {
            myOrderIds[user][i] = myOrderIds[user][i + 1];
        }
        myOrderIds[user].pop();
    }



    // @tokenURI return NFT tokenURI
    // return NFT details encoding form of base64
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        uint256 serial = NFTConfig[tokenId].EAGLESerial;
        uint256 nftUrlId = NFTConfig[tokenId].nftUrlId;
        string memory cardName = tokenType(tokenId);
        string memory name = string(
            abi.encodePacked(cardName, "EAGLE NFT#", tokenId.toString())
        );
        string memory description = string(
            abi.encodePacked("This NFT is ", cardName, ":")
        );
        string memory image = string(abi.encodePacked("https://gateway.pinata.cloud/ipfs/", imageURL[nftUrlId]));
        uint256 creationTime = NFTConfig[tokenId].creationTime;
        string memory sale = NFTConfig[tokenId].onSale ? "true" : "false";
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"token_id":',
                        tokenId.toString(),
                        ',"name":"',
                        name,
                        '","image":"',
                        image,
                        '","NFTUrlId":"',
                        nftUrlId.toString(),
                        '","sale":"',
                        sale,
                        '","serial":"',
                        serial.toString(),
                        '","createTime":"',
                        creationTime.toString(),
                        '","description":"',
                        description,
                        '"}'
                    )
                )
            )
        );
        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        return output;
    }

    // @sellNFT NFT market order
    // List your NFT in the market
    // precondition：You must receive the NFT reward of this month before you can sell it
    // NFT must be authorized to the contract
    function sellNFT(uint256 _tokenId, uint256 _price) external {
        require(_exists(_tokenId), "URI query for nonexistent token");
        require(_msgSender() == ownerOf(_tokenId), "you not owner this NFT");
        require(
            NFTConfig[_tokenId].onSale == false,
            "This NFT cannot be sold. Please cancel the sale first"
        );
        uint256 receiveNum = (block.timestamp -
            NFTConfig[_tokenId].creationTime) / 30 days;
        if (receiveNum > 12) {
            receiveNum = 12;
        }
        if (receiveNum != 0) {
            require(
                NFTConfig[_tokenId].Receive[receiveNum] == true,
                "This NFT cannot be sold,Please get the reward of this month first"
            );
        }
        _transfer(msg.sender, address(this), _tokenId);
        orderNFTList memory NFT = orderNFTList({
            tokenId: _tokenId,
            price: _price,
            NFTListingTime: block.timestamp,
            lowerShelf: true,
            listingAddr:msg.sender
        });
        orderNFTLists.push(NFT);
        NFTConfig[_tokenId].onSale = true;
        NFTConfig[_tokenId].orderId = orderNFTLists.length - 1;
        orderTypeId[0].push(NFTConfig[_tokenId].orderId);
        uint256 serial = NFTConfig[_tokenId].EAGLESerial;
        if  (serial == 0){
            orderTypeId[1].push(NFTConfig[_tokenId].orderId);
        }else{
            orderTypeId[2].push(NFTConfig[_tokenId].orderId);
        }
        myOrderIds[msg.sender].push(NFTConfig[_tokenId].orderId);
        emit listNFTEvent(_tokenId, _price, block.timestamp, true);
    }

    function getorderIdUseTokenId(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return NFTConfig[_tokenId].orderId;
    }

    // @buyNFT Buy NFT in the market
    // precondition：You must first approve the contract for a sufficient amount(EAGLETOKEN>orderNFTLists[orderID].price)
    function buyNFT(uint256 orderID) external {
        address tokenowner = orderNFTLists[orderID].listingAddr;
        uint256 price = orderNFTLists[orderID].price;
        uint256 tokenId = orderNFTLists[orderID].tokenId;
        require(orderNFTLists[orderID].lowerShelf == true, "This NFT is off the shelf");
        require(NFTConfig[tokenId].onSale == true);
        require(
            EAGLETOKEN.allowance(_msgSender(), address(this)) > price,
            "insufficient allowance"
        );
        EAGLETOKEN.transferFrom(_msgSender(), tokenowner, price);
        _transfer(address(this), _msgSender(), tokenId);
        NFTConfig[tokenId].onSale = false;
        orderNFTLists[orderID].lowerShelf = false;
        uint256 serial = NFTConfig[tokenId].EAGLESerial;
        removeIdDate(0,orderID);
        removeOrderIds(tokenowner,orderID);
        if  (serial == 0){
            removeIdDate(1,orderID);
        }else{
            removeIdDate(2,orderID);
        }
        emit buyNFTEvent(
            tokenId,
            _msgSender(),
            tokenowner,
            price,
            false,
            false
        );
    }

    // @cancelNFTList Cancel your NFT to be listed in the NFT market
    // Close NFT order for sale
    function cancelNFTList(uint256 orderID) external {
        uint256 tokenId = orderNFTLists[orderID].tokenId;
        address tokenowner = orderNFTLists[orderID].listingAddr;
        require(orderNFTLists[orderID].lowerShelf == true, "This NFT is off the shelf");
        require(NFTConfig[tokenId].onSale == true, "This NFT is not on sale");
        require(_msgSender() == tokenowner, "you not owner this NFT");
        orderNFTLists[orderID].lowerShelf = false;
        NFTConfig[tokenId].onSale = false;
        _transfer(address(this),msg.sender, tokenId);
        uint256 serial = NFTConfig[tokenId].EAGLESerial;
        removeIdDate(0,orderID);
        removeOrderIds(tokenowner,orderID);
        if  (serial == 0){
            removeIdDate(1,orderID);
        }else{
            removeIdDate(2,orderID);
        }
        emit cancelNFTListEvent(orderNFTLists[orderID].tokenId, false, false);
    }

    // @setNFTConfigReceiveOnlyEAGLETOKEN Set NFTConfig Receive Only EAGLETOKEN
    // Receive the reward of the specified month
    // Only after receiving rewards can they be sold in the market
    function setNFTConfigReceiveOnlyEAGLETOKEN(uint256 _tokenId, uint256 _batch)
        external
    {
        require(msg.sender == address(EAGLETOKEN), "you are not EAGLETOKEN");
        NFTConfig[_tokenId].Receive[_batch] = true;
    }

    function removeIdDate(uint256 types,uint orderId)public {
        uint256 index;
        uint256 ownerNum = orderTypeId[types].length-1;
        for (uint i =0;i < ownerNum ;i++){
            if(orderTypeId[types][i] == orderId){
                index = i;
            }
        }

        require(index < orderTypeId[types].length, "index out of bounds");
        for (uint i = index;i<orderTypeId[types].length-1;i++){
            orderTypeId[types][i] = orderTypeId[types][i+1];
        }
        orderTypeId[types].pop();

    }

    // @getdate return orderIds
    // 0 => all orderIds ; 1 => TigerEagle orderIds ; 2 => PhoenixEagleCard orderIds
    function getdate(uint256 orderListId)public view returns(uint256[] memory){
        return orderTypeId[orderListId];
    }

    // @getOrderDetails return order details
    function getOrderDetails(uint256 orderID)
        public
        view
        returns (string memory)
    {
        uint256 tokenId = orderNFTLists[orderID].tokenId;
        require(_exists(tokenId), "URI query for nonexistent token");
        uint256 price = orderNFTLists[orderID].price;
        uint256 serial = NFTConfig[tokenId].EAGLESerial;
        uint256 NFTListingTime = orderNFTLists[orderID].NFTListingTime;
        string memory owner = Strings.toHexString(uint256(uint160(ownerOf(tokenId))), 20);
        string memory name = tokenType(tokenId);
        string memory description = string(
            abi.encodePacked(
                '{"token_id":',
                    tokenId.toString(),
                    ',"order_id":',
                    orderID.toString(),
                    ',"serial":',
                    serial.toString(),
                    ',"name":"',
                    name,
                    '","price":',
                    price.toString(),
                    ',"NFTListingTime":',
                    NFTListingTime.toString(),
                    ',"owner":"',
                    owner,
                    '"}'
            )
        );
        return description;
    }



    // @totalSupply Query NFT totalsupply
    function totalSupply() external view returns (uint256) {
        return _currentSupply;
    }

    // @tokenType Query the type of an NFT
    function tokenType(uint256 tokenId) public view returns (string memory) {
        uint256 serial = NFTConfig[tokenId].EAGLESerial;
        string memory cardName;
        if (serial == 0) {
            cardName = "TigerEagleCard";
        } else {
            cardName = "PhoenixEagleCard";
        }
        return cardName;
    }


    // @getNFTCreateTime Query appoint NFT create time
    function getNFTCreateTime(uint256 tokenId) external view returns (uint256) {
        return NFTConfig[tokenId].creationTime;
    }

    // @getNFTDraw Query Whether the reward has been received in the specified month
    function getNFTDraw(uint256 tokenId, uint256 _batch)
        external
        view
        returns (bool)
    {
        if(_batch > 12){
            _batch = 12;
        }
        return NFTConfig[tokenId].Receive[_batch];
    }

    // @getNFTEAGLESerial get nft type
    function getNFTEAGLESerial(uint256 tokenId) public view returns (uint256) {
        return NFTConfig[tokenId].EAGLESerial;
    }

    // @getNFTCardNumber Query the respective quantity of the current two NFTs
    function getNFTCardNumber()
        external
        view
        returns (uint128 tigerEaglecardNum, uint128 PhoenixEagleCardNum)
    {
        return (
            68 - TigerEagleCardTAllowancel,
            688 - PhoenixEagleCardTAllowancel
        );
    }

    // @getNFTConfig get nft owner address and type
    function getNFTConfig()
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256 total = _currentSupply;
        address[] memory owner = new address[](total);
        uint256[] memory serial = new uint256[](total);
        for (uint256 i = 0; i < total; i++) {
            NFTDate storage nftdates = NFTCurrency[i];
            owner[i] = nftdates.owner;
            serial[i] = nftdates.serial;
        }
        return (owner, serial);
    }

    function getSale(uint256 tokenId) external view returns (bool) {
        return NFTConfig[tokenId].onSale;
    }
}