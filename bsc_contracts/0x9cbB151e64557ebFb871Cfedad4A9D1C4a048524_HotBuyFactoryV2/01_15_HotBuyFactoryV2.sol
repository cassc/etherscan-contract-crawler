/***
* MIT License
* ===========
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
 __         __     ______   ______     ______   ______     ______     __    __    
/\ \       /\ \   /\  ___\ /\  ___\   /\  ___\ /\  __ \   /\  == \   /\ "-./  \   
\ \ \____  \ \ \  \ \  __\ \ \  __\   \ \  __\ \ \ \/\ \  \ \  __<   \ \ \-./\ \  
 \ \_____\  \ \_\  \ \_\    \ \_____\  \ \_\    \ \_____\  \ \_\ \_\  \ \_\ \ \_\ 
  \/_____/   \/_/   \/_/     \/_____/   \/_/     \/_____/   \/_/ /_/   \/_/  \/_/ 
                                                                                  
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./Interface/IAdorn721.sol";
import "./Interface/IAdorn1155.sol";

contract HotBuyFactoryV2 is Ownable,ReentrancyGuard{

    using ECDSA for bytes32;
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using EnumerableMap for EnumerableMap.UintToUintMap;

    //event mint
    event eMint(
        address user,
        uint256 costAmount,
        uint256 historyCount,
        uint256 stageSoldAmount,
        uint256 mintCount,
        uint256 tokenId
    );

    struct ProjcetInfo{
        address costErc20;
        uint256 saleAmount;
        bool isUserStart;
    }

    struct Condition {

        uint256 price;          //nft per cost erc20
        uint256 startTime;      //the start time
        uint256 endTime;        //the end time
        uint256 limitCount;     //a quota
        uint256 maxSoldAmount;  //the max sold amount
        bytes32 signCode;       //signCode
        uint256 tokenId;        //the token id, if erctype is 721,the tokenid is zero
        uint256 stage;          //cur stage
        address nftContract;    //the hotbuy nft contract address
        address costErc20;      //the cost token address,zero is gas token address
        bytes wlSignature;      //enable white
    }

    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 public immutable DOMAIN_SEPARATOR;

    bytes32 public constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    //type hash
    bytes32 public constant TYPE_HASH = keccak256(
        "Condition(uint256 price,uint256 startTime,uint256 endTime,uint256 limitCount,uint256 maxSoldAmount,bytes32 signCode,uint256 tokenId,uint256 stage,address nftContract,address costErc20,bytes wlSignature)"
    );

    // launchpad nft project info
    mapping(address => EnumerableMap.AddressToUintMap ) private _projcetSaleAmount; //nft contract->costErc20->saleAmount
    mapping(address => mapping(address => bool) ) public _projcetSwitch; //nft contract->costErc20->switch

    // super minters
    mapping(address => EnumerableSet.AddressSet ) private _IAMs; //nft contract->IAMs

    // tags show address can join in open sale
    mapping(address =>EnumerableSet.Bytes32Set) private _signCodes;//erc721/1155->signCode

    // the user get count for 721
    mapping(address => mapping (uint256 => EnumerableMap.AddressToUintMap )) private _721HistoryCount;//erc721->stage->user buyCount

    // the user get count for 1155
    mapping(address =>mapping (uint256 => mapping (uint256 => EnumerableMap.AddressToUintMap ))) private _1155HistoryCount;//erc1155->stage->stage user buyCount

    // the 721 had sold count
    mapping(address => EnumerableMap.UintToUintMap ) private _721SoldCount; //erc721->stage->sold count

    // the 1155 had sold count
    mapping(address => mapping (uint256 => EnumerableMap.UintToUintMap) ) private _1155SoldCount; //erc1155->stage->tokenid->sold count

    address public _SIGNER;
    address public _VAULT;

    constructor(address SIGNER, address VAULT) {
        
        _SIGNER = SIGNER;
        _VAULT = VAULT;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256("HotBuyFactoryV2"),
                keccak256("2"),
                block.chainid,
                address(this)
            )
        );
    }

    function setProject(address nftContract, address costErc20) public onlyOwner{

        if(!_projcetSaleAmount[nftContract].contains(costErc20)){
            _projcetSaleAmount[nftContract].set(costErc20,0);
        }
        _projcetSwitch[nftContract][costErc20] = true;
    }

    function setUserStart(address nftContract, address costErc20, bool start) public onlyOwner {
        _projcetSwitch[nftContract][costErc20] = start;
    }

    function addIAM(address nftContract,address minter) public onlyOwner {
        _IAMs[nftContract].add(minter);
    }

    function removeIAM(address nftContract,address minter) public onlyOwner {
        _IAMs[nftContract].remove(minter);
    }

    function isValidSignCode(address nftContract,bytes32 signCode) view public returns(bool) {
        return !_signCodes[nftContract].contains(signCode);
    }

    function isIAM(address nftContract,address minter) view public returns(bool) {
        return _IAMs[nftContract].contains(minter);
    }

    function getChainId() view public returns(uint256) {
        return block.chainid;
    }

    function getHistoryCount(address nftContract, uint256 stage, uint256 tokenId, address user) view public returns(uint256) {
        bool have;
        uint256 historyCount;
        (have,historyCount) = _721HistoryCount[nftContract][stage].tryGet(user);
        if(have){
            return historyCount;
        }

        (have,historyCount) = _1155HistoryCount[nftContract][stage][tokenId].tryGet(user);
        return historyCount;
    }

    function getSoldCount(address nftContract, uint256 stage, uint256 tokenId) view public returns(uint256) {
        bool have;
        uint256 soldCount;
        (have,soldCount) = _721SoldCount[nftContract].tryGet(stage);
        if(have || soldCount!=0){
            return soldCount;
        }

        (have,soldCount) = _1155SoldCount[nftContract][stage].tryGet(tokenId);
        return soldCount;
    }

    // get ProjcetInfo
    function getProjectInfo(address nftContract) view public returns( ProjcetInfo [] memory infos ) {

        uint256 length = _projcetSaleAmount[nftContract].length();
        infos = new ProjcetInfo[](length);

        address costErc20;
        uint256 saleAmount;

        for(uint256 i= 0; i<_projcetSaleAmount[nftContract].length(); i++){

            (costErc20,saleAmount) = _projcetSaleAmount[nftContract].at(i);

            infos[i].costErc20 = costErc20;
            infos[i].saleAmount = saleAmount;
            infos[i].isUserStart = _projcetSwitch[nftContract][costErc20];
        }
    }

    function mintAdornWithETH(uint64  ercType,uint256 mintCount,  Condition calldata condition, bytes memory dataSignature) public payable nonReentrant
    {
        address nftContract = condition.nftContract;
        address costErc20 = condition.costErc20;
        require(costErc20 == address(0x0), "invalid mint method!" );

        uint256 costAmount = condition.price.mul(mintCount);
        if(costAmount > 0){

            require(msg.value >= costAmount, "invalid cost amount! ");
            payable(_VAULT).transfer(msg.value);

            bool have;
            uint256 saleAmount;
            (have,saleAmount) = _projcetSaleAmount[nftContract].tryGet(costErc20);
            if(!have){
                saleAmount = 0;
            }
            saleAmount += costAmount;
            _projcetSaleAmount[nftContract].set(costErc20,saleAmount);
        }
      
        if(ercType == 1155 ){
            _mint1155(nftContract,costErc20,mintCount,condition,dataSignature);
        }
        else if(ercType == 721 ){
            _mint721(nftContract,costErc20,mintCount,condition,dataSignature);
        }
        else{
            require(false, "invalid mint ercType!" );
        }
            
    }

    function mintAdorn(uint64  ercType,uint256 mintCount, Condition calldata condition, bytes memory dataSignature )  public nonReentrant {

        address nftContract = condition.nftContract;
        address costErc20 = condition.costErc20;
        require(costErc20 != address(0x0),"invalid cost token address!");

        uint256 costAmount = condition.price.mul(mintCount);
        if(costAmount > 0){

            IERC20 costToken =  IERC20(costErc20);
            uint256 balanceBefore = costToken.balanceOf(_VAULT);
            costToken.safeTransferFrom(msg.sender, _VAULT, costAmount);
            uint256 balanceAfter = costToken.balanceOf(_VAULT);

            bool have;
            uint256 saleAmount;
            (have,saleAmount) = _projcetSaleAmount[nftContract].tryGet(costErc20);
            if(!have){
                saleAmount = 0;
            }
            saleAmount += balanceAfter.sub(balanceBefore);
            _projcetSaleAmount[nftContract].set(costErc20,saleAmount);
            
        }

        if(ercType == 1155 ){
            _mint1155(nftContract,costErc20,mintCount,condition,dataSignature);
        }
        else if(ercType == 721 ){
            _mint721(nftContract,costErc20,mintCount,condition,dataSignature);
        }
        else{
            require(false, "invalid mint ercType!" );
        }

    } 


    // mint721 asset
    function _mint721(address nftContract, address costErc20, uint256 mintCount, Condition calldata condition, bytes memory dataSignature )  internal {

        require(mintCount>0, "invalid mint count!");

        bool exist = _IAMs[nftContract].contains(msg.sender);
        if(!exist){
            require(!msg.sender.isContract(), "call to non-contract");
        }
        require(_projcetSwitch[nftContract][costErc20] || exist  , "can't mint" );

        require( block.timestamp >= condition.startTime && block.timestamp < condition.endTime, "out date" );
        
        uint256 stage = condition.stage;
        bool have ;
        uint256 historyCount;
        (have,historyCount)= _721HistoryCount[nftContract][stage].tryGet(msg.sender);
        if(!have){
            historyCount = 0;
        }

        if(!exist){

            require(verify(condition, msg.sender, dataSignature), "this sign is not valid");

            uint256 count = historyCount + mintCount;
            require(count <= condition.limitCount,"sale count is max ");

            //once signCode
            require(isValidSignCode(nftContract,condition.signCode),"invalid signCode!");
        }

        historyCount += mintCount;
        _721HistoryCount[nftContract][stage].set(msg.sender,historyCount);
        
         uint256 soldCount;
        (have,soldCount) = _721SoldCount[nftContract].tryGet(stage);
        if(!have){
            soldCount = 0;
        }
        soldCount += mintCount;
        require(soldCount <= condition.maxSoldAmount,"stage sold count is max ");
        _721SoldCount[nftContract].set(stage,soldCount);

        IAdorn721(nftContract).mint(msg.sender,mintCount);

        _signCodes[nftContract].add(condition.signCode);

        uint256 costAmount = condition.price.mul(mintCount);
        emit eMint(
                msg.sender,
                costAmount,
                historyCount,
                soldCount,
                mintCount,
                0
            );
    } 


    // mint1155 asset
    function _mint1155(address nftContract, address costErc20, uint256 mintCount, Condition calldata condition, bytes memory dataSignature )  internal {

        require(mintCount>0, "invalid mint count!");

        bool exist = _IAMs[nftContract].contains(msg.sender);
        if(!exist){
            require(!msg.sender.isContract(), "call to non-contract");
        }
        require( _projcetSwitch[nftContract][costErc20] || exist  , "can't mint" );

        require( block.timestamp >= condition.startTime && block.timestamp < condition.endTime, "out date" );

        uint256 tokenId = condition.tokenId;
        uint256 stage = condition.stage;

        bool have ;
        uint256 historyCount;
        (have,historyCount)= _1155HistoryCount[nftContract][stage][tokenId].tryGet(msg.sender);
        if(!have){
            historyCount = 0;
        }

        if(!exist){

            require(verify(condition, msg.sender, dataSignature), "this sign is not valid");

            uint256 count = historyCount + mintCount;
            require(count <= condition.limitCount,"sale count is max ");

            //once signCode
            require(isValidSignCode(nftContract,condition.signCode),"invalid signCode!");
        }

        historyCount += mintCount;
        _1155HistoryCount[nftContract][stage][tokenId].set(msg.sender,historyCount);
        
        uint256 soldCount;
        (have,soldCount) = _1155SoldCount[nftContract][stage].tryGet(tokenId);
        if(!have){
            soldCount = 0;
        }
        soldCount += mintCount;
        require(soldCount <= condition.maxSoldAmount,"stage sold count is max ");
        _1155SoldCount[nftContract][stage].set(tokenId,soldCount);

        IAdorn1155(nftContract).mint(msg.sender,tokenId,mintCount,"");

        _signCodes[nftContract].add(condition.signCode);

        uint256 costAmount = condition.price.mul(mintCount);
        emit eMint(
                msg.sender,
                costAmount,
                historyCount,
                soldCount,
                mintCount,
                tokenId
            );
    } 

    function withdrawETH(address wallet) external onlyOwner {
        require(wallet != address(0),"the wallet address is zero!");
        payable(wallet).transfer(address(this).balance);
    }

    function urgencyWithdraw(address erc20, address wallet) external onlyOwner {
        require(wallet != address(0),"the wallet address is zero!");
        IERC20(erc20).safeTransfer(wallet, IERC20(erc20).balanceOf(address(this)));
    }

    function updateSigner( address signer) external onlyOwner {
        require(signer != address(0),"the signer address is zero!");
        _SIGNER = signer;
    }

    function updateVault( address vault) external onlyOwner {
        require(vault != address(0),"the vault address is zero!");
        _VAULT = vault;
    }

    function hashCondition(Condition calldata condition) public pure returns (bytes32) {


        // uint256 price;          //nft per cost erc20
        // uint256 startTime;      //the start time
        // uint256 endTime;        //the end time
        // uint256 limitCount;     //a quota
        // uint256 maxSoldAmount;  //the max sold amount
        // bytes32 signCode;       //signCode
        // uint256 tokenId;        //the token id, if erctype is 721,the tokenid is zero
        // uint256 stage;           //cur stage
        // address nftContract;    //the hotbuy nft contract address
        // address costErc20;      //the cost token address,zero is gas token address
        // bytes wlSignature;      //enable white

        return keccak256(
            abi.encode(
                TYPE_HASH,
                condition.price,
                condition.startTime,
                condition.endTime,
                condition.limitCount,
                condition.maxSoldAmount,
                condition.signCode,
                condition.tokenId,
                condition.stage,
                condition.nftContract,
                condition.costErc20,
                keccak256(condition.wlSignature))
        );
    }

    function hashWhiteList( address user, bytes32 signCode ) public pure returns (bytes32) {

        bytes32 message = keccak256(abi.encodePacked(user, signCode));
        // hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
        return message.toEthSignedMessageHash();
    }

    function hashDigest(Condition calldata condition) public view returns (bytes32) {
        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            hashCondition(condition)
        ));
    }

    function verifySignature(bytes32 hash, bytes memory  signature) public view returns (bool) {
        //hash must be a soliditySha3 with accounts.sign
        return hash.recover(signature) == _SIGNER;
    }

    function verifyCondition(Condition calldata condition, uint8 v, bytes32 r, bytes32 s) public view returns (bool) {
        bytes32 digest = hashDigest(condition);
        return ecrecover(digest, v, r, s) == _SIGNER;    
    }

    function verify(  Condition calldata condition, address user, bytes memory dataSignature ) public view returns (bool) {
       
        require(condition.signCode != "","invalid sign code!");

        bytes32 digest = hashDigest(condition);
        require(verifySignature(digest,dataSignature)," invalid dataSignatures! ");

        if(condition.wlSignature.length >0 ){
            bytes32 hash = hashWhiteList(user, condition.signCode);
            require( verifySignature(hash, condition.wlSignature), "invalid wlSignature! ");
        }

        return true;
    }
}