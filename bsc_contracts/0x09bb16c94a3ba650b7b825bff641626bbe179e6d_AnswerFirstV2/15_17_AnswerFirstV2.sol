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

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./Interface/IAdorn1155.sol";
import "./Interface/IAvatar721.sol";

contract AnswerFirstV2 is ReentrancyGuard, Pausable, Ownable {

enum RegisterType {
        eCash,
        eAvatar,
        ePoints
    }

    event eSetIAM(
        uint256 activityId,
        address IAM
    );
    event eSetVAULT(
        uint256 activityId,
        address VAULT
    );
    event eSetFee(
        uint256 activityId,
        uint256 registerFee,
        uint256 stakeFee
    );
    event eSetAirDropId(
        uint256 activityId,
        uint256 dropId
    );

    event eUpdateSigner(
        uint256 activityId,
        address signer
    );

    event eNewActivity(
        uint256 activityId,
        uint256 startTime,
        uint256 endTime
    );

    event eSetActivityTime(
        uint256 activityId,
        uint256 startTime,
        uint256 endTime
    );

    event eRegister(
        uint256 tokenId, 
        address owner, 
        uint256 registerType, 
        uint256 timestamp,
        uint256 activityId,
        string affCode
    );

    event eWithdraw( 
    uint256[] ids, 
    address owner, 
    uint256 timestamp, 
    uint256 activityId 
    );

    struct RegisterInfo{
        uint256 tokenId;
        uint256 activityId;
    }

    struct ActivityInfo{
        uint256 registerCount;
        uint256 allPay;
        uint256 endTime;
        uint256 startTime;
    }

    struct SrcData {
        uint256 registerType;
        uint256 tokenId;
        bytes32 signCode;
        bytes wlSignature;   
    }

    using SafeERC20 for IERC20;
    using ECDSA for bytes32;
    using Address for address;

    using EnumerableSet for EnumerableSet.Bytes32Set;
    
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

    // //type hash
    bytes32 public constant TYPE_HASH = keccak256(
        "SrcData(uint256 registerType,uint256 tokenId,bytes32 signCode,bytes wlSignature)"
    );

    IAdorn1155 public _erc1155;
    IAvatar721 public _erc721;
    IERC20 public _erc20;

    uint256 public _registerFee = 20 ether;
    uint256 public _stakeFee = 1 ether;
    uint256 public _deltaTime = 24 hours;
    uint256 public _stakeDuration = 10 minutes;

    uint256 public _airDropId;
    uint256 public _activityId;

    address public _IAM;
    address public _VAULT;
    address public _SIGNER;

    uint256 public _MAX = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // for players
    mapping(uint256 => mapping( address => RegisterInfo )) public _registerInfo; // activityId=>address=>RegisterInfo
    // for activity info
    mapping(uint256 => ActivityInfo) public _activityInfo;

    modifier onlyIAM() {
        require(_IAM == msg.sender , "must call by IAM");
        _;
    }

    constructor(address erc20, address erc721, address erc1155, address VAULT,address SIGNER ) {

        require(erc1155 != address(0x0), "invalid erc1155 adddress ");
        require(erc721 != address(0x0), "invalid erc721 adddress ");
        require(erc20 != address(0x0), "invalid erc20 adddress ");

        require(VAULT != address(0x0), "invalid VAULT adddress ");
        require(SIGNER != address(0x0), "invalid SIGNER adddress ");

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256("AnswerFirstV2"),
                keccak256("2"),
                block.chainid,
                address(this)
            )
        );

        _erc20 = IERC20(erc20);
        _erc721 = IAvatar721(erc721);
        _erc1155 = IAdorn1155(erc1155);

        _VAULT = VAULT;
        _SIGNER = SIGNER;

        _IAM = msg.sender;
    }

    function setErc1155(address erc1155) public onlyOwner{
        require(erc1155 != address(0x0), "invalid erc1155 adddress ");
        _erc1155 = IAdorn1155(erc1155);
    }

    function setErc721(address erc721) public onlyOwner{
        require(erc721 != address(0x0), "invalid erc721 adddress ");
        _erc721 = IAvatar721(erc721);
    }

    function setErc20(address erc20) public onlyOwner{
        require(erc20 != address(0x0), "invalid erc20 adddress ");
        _erc20 = IERC20(erc20);
    }
    
    function setFee(uint256 registerFee,uint256 stakeFee) public onlyOwner{
        _registerFee = registerFee;
        _stakeFee = stakeFee;

        emit eSetFee(_activityId, registerFee,stakeFee);
    }

    function setActivityTime(uint256 startTime, uint256 deltaTime) public onlyOwner{
        _deltaTime = deltaTime;

        _activityInfo[_activityId].startTime = startTime;
        _activityInfo[_activityId].endTime = startTime + _deltaTime;

        emit eSetActivityTime(_activityId,startTime,startTime + _deltaTime);
    }

    function set1155Id(uint256 airDropId) public onlyOwner{
        _airDropId = airDropId;

        emit eSetAirDropId(_activityId, airDropId);
    }

    function setVault(address VAULT) public onlyOwner{

        require(VAULT != address(0x0), "invalid VAULT adddress ");
        _VAULT = VAULT;

        emit eSetVAULT(_activityId, VAULT);
    }


    function setIAM(address IAM) public onlyOwner {

        require(IAM != address(0x0), "invalid IAM adddress ");
        _IAM = IAM;

        emit eSetIAM(_activityId, IAM);
    }


    function updateSigner( address SIGNER) public onlyOwner {

    require(SIGNER != address(0x0), "SIGNER is zero address!");

        _SIGNER = SIGNER;

        emit eUpdateSigner(_activityId, SIGNER);
    }
    
    function onERC721Received(address /*operator*/ , address /*from*/ , uint256 /*tokenId*/, bytes calldata  /*data*/) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    function newActivity(uint256 airDropId, uint256 deltaTime) public onlyIAM {

        _deltaTime = deltaTime;

        _activityId++;
        _activityInfo[_activityId].startTime = block.timestamp;
        _activityInfo[_activityId].endTime = block.timestamp + _deltaTime;
        
        _airDropId = airDropId;

        emit eNewActivity(_activityId,block.timestamp,block.timestamp + _deltaTime);
    }

    function isRegister(uint256 activityId, address owner ) public view returns(bool){
        return _registerInfo[activityId][owner].activityId != 0;
    }

    function getRegisterInfo(uint256 activityId,address owner) public view returns(RegisterInfo memory ){
        return  _registerInfo[activityId][owner];
    }

    function getActivityInfo(uint256 activityId) public view returns(ActivityInfo memory ){
        return  _activityInfo[activityId];
    }

    function getAllRegisterInfo(address owner) public view returns(RegisterInfo[] memory ){

        RegisterInfo[] memory records = new RegisterInfo[](_activityId+1);
        for(uint256 i=0; i<=_activityId; i++){
        records[i] = _registerInfo[i][owner];
        }
        return records;
    }

    function register(SrcData calldata srcData, bytes memory dataSignature, string calldata affCode) public whenNotPaused nonReentrant {
        require( !isRegister(_activityId,msg.sender), "already registered!");
        require( block.timestamp < _activityInfo[_activityId].endTime, "register time is up!");

        _activityInfo[_activityId].registerCount += 1;
    

        if(srcData.registerType == (uint256)(RegisterType.eCash)){

            _erc20.safeTransferFrom(msg.sender, _VAULT, _registerFee);
            _activityInfo[_activityId].allPay += _registerFee;

            //set a invalid token Id
            _registerInfo[_activityId][msg.sender].tokenId = _MAX;
            
        }
        else if(srcData.registerType == (uint256)(RegisterType.eAvatar)){

            require( IERC721(address(_erc721)).ownerOf(srcData.tokenId) == msg.sender, "invalid owner!");
            IERC721(address(_erc721)).safeTransferFrom(msg.sender, address(this), srcData.tokenId);

            _registerInfo[_activityId][msg.sender].tokenId = srcData.tokenId;

            _erc20.safeTransferFrom(msg.sender, _VAULT, _stakeFee);
            _activityInfo[_activityId].allPay += _stakeFee;

        }
        else if(srcData.registerType == (uint256)(RegisterType.ePoints)){

            require(srcData.wlSignature.length>0,"lifeform: invalid wlSignature!");
            require(verify(srcData, msg.sender, dataSignature), "lifeform: this sign is not valid");

            require(IERC721(address(_erc721)).ownerOf(srcData.tokenId) == msg.sender, "invalid owner!");

            IERC721(address(_erc721)).safeTransferFrom(msg.sender, address(this), srcData.tokenId);
            _registerInfo[_activityId][msg.sender].tokenId = srcData.tokenId;

        }
        else{
            require(false, "invalid register type!");
        }

        _registerInfo[_activityId][msg.sender].activityId=_activityId;

        if(_airDropId>0){
            _erc1155.mint(msg.sender, _airDropId, 1, "");
        }

        emit eRegister(srcData.tokenId, msg.sender, srcData.registerType, block.timestamp, _activityId, affCode);
    }

    function withdrawNFTs() public whenNotPaused nonReentrant {

        uint256[] memory ids = new uint256[](_activityId);
        uint32 count=0;
        uint256 tokenId = 0;
        for(uint256 k=0; k<_activityId; k++){
            tokenId = _registerInfo[k][msg.sender].tokenId;
            if( _registerInfo[k][msg.sender].activityId >0 && tokenId != _MAX && isRegister(k, msg.sender)){
                IERC721(address(_erc721)).safeTransferFrom(address(this), msg.sender, tokenId);
                _registerInfo[k][msg.sender].activityId=0;

                ids[count]=tokenId;
                count = count+1;
            }
        }

        tokenId = _registerInfo[_activityId][msg.sender].tokenId;
        if( _registerInfo[_activityId][msg.sender].activityId >0 && tokenId != _MAX && block.timestamp >=  _activityInfo[_activityId].endTime+_stakeDuration){
            IERC721(address(_erc721)).safeTransferFrom(address(this), msg.sender, tokenId);
            _registerInfo[_activityId][msg.sender].activityId=0;

            ids[count]=tokenId;
            count = count+1;
        }

        require(count>0, "nothing to be withdrawed! the pledge hasn't expired yet");

        emit eWithdraw(ids, msg.sender, block.timestamp, _activityId);
    
    }

    //for finaly reward
    function reward(address[] calldata whiteList,uint256[] calldata amounts) onlyIAM external  {

        require(whiteList.length == amounts.length, "count not match!");

        uint256 cost = 0;
        for(uint256 i=0; i<amounts.length; i++){
            cost = cost + amounts[i];
        }

        require(_erc20.balanceOf(address(this)) >= cost, "invalid cost amount! ");

        for (uint256 i=0; i<whiteList.length; i++) {
            require(whiteList[i] != address(0),"Address is not valid");
            _erc20.safeTransfer(whiteList[i], amounts[i]);
        }
        
    }

    function urgencyWithdrawErc721(address erc721, address target, uint256[] calldata ids) external onlyOwner {
        for (uint256 i = 0; i < ids.length; ++i) {
            (IERC721)(erc721).safeTransferFrom(address(this), target, ids[i],"");
        }
    }

    //generate the whitelist user hash
    function hashWhiteList( address user, bytes32 signCode ) public pure returns (bytes32) {

        bytes32 message = keccak256(abi.encodePacked(user, signCode));
        // hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
        return message.toEthSignedMessageHash();
    }

    //generate the SrcData hash
    function hashCondition(SrcData calldata srcData) public pure returns (bytes32) {
        
        // struct SrcData {
        //     uint256 registerType;
        //     uint256 tokenId;
        //     bytes32 signCode;
        //     bytes wlSignature;   
        // }

        return keccak256(
            abi.encode(
                TYPE_HASH,
                srcData.registerType,
                srcData.tokenId,
                srcData.signCode,
                keccak256(srcData.wlSignature))
        );
    }

    function hashDigest(SrcData calldata srcData) public view returns (bytes32) {
        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            hashCondition(srcData)
        ));
    }

    function verifySignature(bytes32 hash, bytes memory  signature) public view returns (bool) {
        //hash must be a soliditySha3 with accounts.sign
        return hash.recover(signature) == _SIGNER;
    }

    function verifyCondition(SrcData calldata srcData, uint8 v, bytes32 r, bytes32 s) public view returns (bool) {
        bytes32 digest = hashDigest(srcData);
        return ecrecover(digest, v, r, s) == _SIGNER;    
    }

    function verify( SrcData calldata srcData, address user, bytes memory dataSignature ) public view returns (bool) {
    
        require(srcData.signCode != "","lifeform: invalid sign code!");

        bytes32 digest = hashDigest(srcData);
        require(verifySignature(digest,dataSignature),"lifeform: invalid dataSignatures! ");

        bytes32 hash = hashWhiteList(user, srcData.signCode);
        require( verifySignature(hash, srcData.wlSignature), "lifeform: invalid wlSignature! ");
        
        return true;
    }

    function pause() public onlyOwner{
        if(!paused()){
            _pause();
        }
        else{
            _unpause();
        }
    }
}