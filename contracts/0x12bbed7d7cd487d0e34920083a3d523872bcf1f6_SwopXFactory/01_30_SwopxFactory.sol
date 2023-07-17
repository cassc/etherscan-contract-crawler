// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./SwopXCollections.sol";

contract SwopXFactory is Ownable  {
    using SafeERC20 for IERC20;

    address private immutable nftImp;
    address [] private nftCollection;
    mapping (address => bool) isMintedCollection;

    event NewCollectionLog(address indexed contracts, address indexed owner,
    string  [2] name_symbol_,
    uint256 maxSypplyCollection, uint256 privatePriceWei,
    uint256 publicPriceWei, uint256 whiteListStartTime , uint256 publicStartTime_, uint256 maxMintPerAddress_);

    // SaleLogFactory event if there is sale either private or public sales
    event SaleLogFactory(address indexed collection, address minter, uint256 numOfTokens, uint256 cost);
    // CryptoLogFactory  event is called in the addToken function when 
    // the admain adds erc20 address and the price 
    event CryptoLogFactory(address indexed collection, bool isSupported, address paymentAddress, uint256 price);
    // ActiveLogLogFactory event is for activing or disactiving the sale active
    event ActiveLogLogFactory(address indexed collection, bool isActive);
    // RootLogFactory event runs if the tree of the root is updated 
    event RootLogFactory(address indexed collection, bytes32 root);
    // MintLogFactory event  is to mint a new token id
    event MintLogFactory(address indexed collection, address account, uint256 tokenId);
    // StartCollectionLogFactory event is called in setPublicTimeSale function 
    // and retruns if the owner changes the timestamp of the public sale timestamp and max mint per address
    // also this will activate the sale of the collection was deactivated
    event StartCollectionLogFactory(address indexed collection,address admain, uint256 time, uint256 maxMinPerAddress, bool saleIsActive);
    // CurrencySaleLog event is simialr to SaleLogFactory event but here it is for erc20 
    event CurrencySaleLog(address indexed collection,address account, uint256 numTokens, address paymentContract, uint256 cost);
  // WithdrawLog event is called in the withdraw function for withdraing fees
    event WithdrawLog(address indexed contracts, address indexed account, uint amount);

    modifier onlyCollection() {
        require(isMintedCollection[msg.sender], "Caller is not minted collection");
        _;
    }

    constructor() {
        nftImp = address(new SwopXCollections());
    }


    /*
    * @notice: this function runs for creating a collection
    * @param  name_symbol_ string is an array of name and symbol of the collection
    * @param  _admain address is the owner of the collection
    * @param  maxSypplyCollection_ uint256 is max sypply of the collection
    * @param  _privatePriceWei_startTime_ uint256 is an arry of the private price in Wei and private start time stamp
    * @param  _publicPriceWei_publicstartTime_ uint256 is an arry of the public pricd in Wei and the public start time stamp
    * @param maxMintPerAddress_ uint256 is how many a wallet address can mint
    * @param baseURI string of the URI
    * @param merkleroot bytes32 is the root of the waiting list of the private sale.
    */
    function createCollection(string [2] calldata name_symbol_, address _admain,
    uint256 maxSypplyCollection_, uint256 [2] calldata _privatePriceWei_startTime_, uint256 [2] calldata _publicPriceWei_publicstartTime_,
    uint256 maxMintPerAddress_, string calldata baseURI, bytes32 merkleroot) external   {
        require( maxSypplyCollection_ > 0, "It must be nonzero");
        address payable clone = payable(Clones.clone(nftImp));
        SwopXCollections(clone).initialize(
           name_symbol_, _admain, address(this),
            maxSypplyCollection_,_privatePriceWei_startTime_, _publicPriceWei_publicstartTime_, maxMintPerAddress_, baseURI, merkleroot);
        nftCollection.push(clone);

    isMintedCollection[clone] = true;

    emit NewCollectionLog(clone, msg.sender,
        name_symbol_, maxSypplyCollection_, _privatePriceWei_startTime_[0],  _publicPriceWei_publicstartTime_[0],  _privatePriceWei_startTime_[1] ,  _publicPriceWei_publicstartTime_[1], maxMintPerAddress_);
    }


    /*
    * @notice: this function returns all nft collection address
    */
    function getAllCollection() view external returns(address [] memory list){
        list = nftCollection;
    }

    // notifications of the events in collection contract
    function notifySaleLog(address minter, uint256 tokenID, uint256 cost) external onlyCollection() {
        emit SaleLogFactory(msg.sender, minter, tokenID, cost);
    }

    function notifyCryptoLog(bool isSupported, address paymentContract, uint256 price) external onlyCollection() {
        emit CryptoLogFactory(msg.sender, isSupported, paymentContract, price);
    }
    
    function notifyActiveLog(bool isActive) external onlyCollection() {
        emit ActiveLogLogFactory(msg.sender, isActive);
    }

    function notifyRootLog(bytes32 root) external onlyCollection() {
        emit RootLogFactory(msg.sender, root);
    }
    function notifyMintLog(address admain, uint256 tokenId) external onlyCollection() {
        emit MintLogFactory(msg.sender, admain, tokenId);
    }


    function notifyStartCollectionLog(address admain, uint256 time, uint256 maxMinPerAddress, bool saleIsActive) external onlyCollection() {
        emit StartCollectionLogFactory(msg.sender, admain, time, maxMinPerAddress, saleIsActive);
    }

    function notifyCurrencySaleLog(address account, uint256 numTokens, address paymentContract, uint256 cost) external onlyCollection() {
        emit CurrencySaleLog(msg.sender, account, numTokens, paymentContract, cost);
    }

    /*
    * @notice: to get collection by Id returns collection address
    */
    function getCollection(uint256 _id) view external returns(address ){
        address _cool = nftCollection[_id];
        return _cool;
    }

    /*
    * @notice: read the balance of this contract
    */
    function balance() external view returns(uint256 _balance) {
        _balance = address(this).balance;
    }

    /*
    * @notice: only the admin can withdraw.
    */
    function withdraw() external onlyOwner {
        uint256 contract_balance = address(this).balance;
        require(contract_balance > 0, "No funds available for withdrawal");

        payable(msg.sender).transfer(contract_balance);
    }

    /*
    * @notice: to withdraw the fees
    * @param _contract address of the erc20 token
    * @param _to address of the receiver address
    */
    function withdrawCurrency(address _contract, address _to) external onlyOwner {
        require( _contract != address(0) , "Zero Address");
        uint _amount = IERC20(_contract).balanceOf(address(this));
        IERC20(_contract).safeTransfer(_to, _amount);
        emit WithdrawLog(_contract, _to, _amount);
    }


}