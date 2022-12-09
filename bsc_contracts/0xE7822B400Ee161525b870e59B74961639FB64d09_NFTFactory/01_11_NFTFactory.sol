// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interface/INFTSignature.sol";
import "./interface/INFTFactory.sol";
import "./interface/IGegoRuleProxy.sol";
import "./library/Governance.sol";

contract NFTFactory is Governance, INFTFactory {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    event GegoAdded(
        uint256 indexed id,
        uint256 grade,
        uint256 quality,
        uint256 amount,
        uint256 resBaseId,
        uint256 ruleId,
        uint256 nftType,
        address author,
        address erc20,
        uint256 createdTime,
        uint256 blockNum,
        uint256 expiringTime
    );

    event GegoInjected(
        uint256 indexed id,
        uint256 amount
    );

    event GegoAmountReduced(
        uint256 indexed id,
        uint256 reducedAmount,
        uint256 realAmount,
        uint256 amount
    );

    event GegoAmountReduceReflected(
        uint256 indexed id,
        uint256 realAmount,
        uint256 amount
    );

    struct MintData{
        uint256 amount;
        uint256 resBaseId;
        uint256 nftType;
        uint256 ruleId;
    }

    struct MintExtraData {
        uint256 gego_id;
        uint256 grade;
        uint256 quality;
        uint256 expiringDuration;
        address author;
    }

    event NFTReceived(address operator, address from, uint256 tokenId, bytes data);

    // for minters
    mapping(address => bool) public _minters;

    mapping(uint256 => INFTSignature.Gego) public _gegoes;

    mapping(uint256 => IGegoRuleProxy) public _ruleProxys;

    mapping(address => bool) public _ruleProxyFlags;

    mapping(address => bool) public _nftPools;

    uint256 public _maxGegoV1Id = 1000000;
    uint256 public _adminGegoId = 100000;
    uint256 public _gegoId = _maxGegoV1Id;


    INFTSignature public _spynNftToken ;

    bool public _isUserStart = false;

    uint256 private _randomNonce;

    constructor(address spynNftToken) {
        _spynNftToken = INFTSignature(spynNftToken);
    }

    function setUserStart(bool start) public onlyGovernance {
        _isUserStart = start;
    }

    function addMinter(address minter) public onlyGovernance {
        _minters[minter] = true;
    }

    function removeMinter(address minter) public onlyGovernance {
        _minters[minter] = false;
    }

    function addNftPool(address pool) public onlyGovernance {
        _nftPools[pool] = true;
    }

    function removeNftPool(address pool) public onlyGovernance {
        _nftPools[pool] = false;
    }


    // only function for creating additional rewards from dust
    function seize(IERC20 asset, address teamWallet) public onlyGovernance {
        uint256 balance = asset.balanceOf(address(this));
        asset.safeTransfer(teamWallet, balance);
    }

    /**
     * @dev add gego mint strategy address
     * can't remove
     */
    function addGegoRuleProxy(uint256 nftType, address ruleProxy) public onlyGovernance{
        require(_ruleProxys[nftType] == IGegoRuleProxy(address(0)), "must null");

        _ruleProxys[nftType] = IGegoRuleProxy(ruleProxy);

        _ruleProxyFlags[ruleProxy] = true;
    }

    function isRulerProxyContract(address proxy) external view override returns ( bool ){
        return _ruleProxyFlags[proxy];
    }

    /*
     * @dev set gego contract address
     */
    function setGegoContract(address gego) public onlyGovernance{
        _spynNftToken = INFTSignature(gego);
    }

    function setCurrentGegoId(uint256 id) public onlyGovernance{
        _gegoId = id;
    }

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'GegoFactoryV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getGego(uint256 tokenId)
        external view override
        returns (
            uint256 grade,
            uint256 quality,
            uint256 amount,
            uint256 realAmount,
            uint256 resBaseId,
            uint256 ruleId,
            uint256 nftType,
            address author,
            address erc20,
            uint256 createdTime,
            uint256 blockNum,
            uint256 expiringTime
        )
    {
        INFTSignature.Gego storage gego = _gegoes[tokenId];
        require(gego.id > 0, "gego not exist");
        grade = gego.grade;
        quality = gego.quality;
        amount = gego.amount;
        realAmount = gego.realAmount;
        resBaseId = gego.resBaseId;
        ruleId = gego.ruleId;
        nftType = gego.nftType;
        author = gego.author;
        erc20 = gego.erc20;
        createdTime = gego.createdTime;
        blockNum = gego.blockNum;
        expiringTime = gego.expiringTime;
    }

    function getGegoStruct(uint256 tokenId)
        external override view
        returns (INFTSignature.Gego memory gego){
            require(_gegoes[tokenId].id > 0, "gego  not exist");
            gego = _gegoes[tokenId];
        }


    function setBaseResId(uint256 tokenId, uint256 resBaseId) external onlyGovernance {
        require(_gegoes[tokenId].id > 0, "gego not exist");
        _gegoes[tokenId].resBaseId = resBaseId;
    }

    function buy(uint256 nftType, uint256 ruleId, uint256 quantity, uint256[] memory resIds) public lock
    {

        address origin = msg.sender;

        if(_minters[msg.sender] == false){
            require(!origin.isContract(), "call to non-contract");
        }

        require(resIds.length == quantity, "invalid parameters");

        require(_isUserStart || _minters[msg.sender], "can't mint");

        require(_ruleProxys[nftType] != IGegoRuleProxy(address(0)), " invalid mint nftType!");

        address mintErc20;

        IGegoRuleProxy.MintParams memory params;
        params.user = msg.sender;
        params.amount = 0;
        params.ruleId = ruleId;
        params.fromAdmin = false;

        mintErc20 = _ruleProxys[nftType].costMultiple(params, quantity);

        for (uint256 index = 0; index < quantity; index ++) {
            _randomNonce++;
            INFTSignature.Gego memory gego = _ruleProxys[nftType].generate(msg.sender, 0, _randomNonce);

            uint256 gegoId = gego.id;
            if(gegoId == 0){
                _gegoId++;
                gegoId = _gegoId;
            }
            gego.id = gegoId;
            gego.blockNum = gego.blockNum > 0 ? gego.blockNum:block.number;
            gego.createdTime = gego.createdTime > 0?gego.createdTime:block.timestamp;
            gego.expiringTime = 0;

            gego.amount = 0;
            gego.realAmount = 0;
            gego.resBaseId = resIds[index];
            gego.erc20 = gego.erc20==address(0x0)?mintErc20:gego.erc20;

            gego.ruleId = ruleId;
            gego.nftType = nftType;
            gego.author = gego.author==address(0x0)?msg.sender:gego.author;

            _gegoes[gegoId] = gego;

            _spynNftToken.mint(msg.sender, gegoId);

            emit GegoAdded(
                gego.id,
                gego.grade,
                gego.quality,
                gego.amount,
                gego.resBaseId,
                gego.ruleId,
                gego.nftType,
                gego.author,
                gego.erc20,
                gego.createdTime,
                gego.blockNum,
                gego.expiringTime
            );
        }
    }

    function gmMint(MintData memory mintData, MintExtraData memory extraData) public {
        require(_minters[msg.sender], "can't mint");


        IGegoRuleProxy.MintParams memory params;
        params.user = msg.sender;
        params.amount = mintData.amount;
        params.ruleId = mintData.ruleId;
        params.fromAdmin = true;

        uint256 mintAmount;
        address mintErc20;

        (mintAmount,mintErc20) = _ruleProxys[mintData.nftType].cost(params);
        uint256 gegoId = extraData.gego_id;
        if(extraData.gego_id == 0){
            _gegoId++;
            gegoId = _gegoId;
        }else{
            if(gegoId > _gegoId){
                _gegoId = gegoId;
            }
        }

        INFTSignature.Gego memory gego;
        gego.id = gegoId;
        gego.blockNum = block.number;
        gego.createdTime = block.timestamp;
        gego.grade = extraData.grade;
        gego.quality = extraData.quality;
        gego.amount = mintAmount;
        gego.realAmount = mintAmount;
        gego.resBaseId = mintData.resBaseId;
        gego.ruleId = mintData.ruleId;
        gego.nftType = mintData.nftType;
        gego.author = extraData.author;
        gego.erc20 = mintErc20;
        if (mintAmount > 0) {
            gego.expiringTime = block.timestamp + extraData.expiringDuration;
        } else {
            gego.expiringTime = 0;
        }
        

        _gegoes[gegoId] = gego;

        _spynNftToken.mint(extraData.author, gegoId);

        emit GegoAdded(
            gego.id,
            gego.grade,
            gego.quality,
            gego.amount,
            gego.resBaseId,
            gego.ruleId,
            gego.nftType,
            gego.author,
            gego.erc20,
            gego.createdTime,
            gego.blockNum,
            gego.expiringTime
        );
    }

    function gmMintMulti(uint256 ruleId, uint256[] memory resIds, uint256 quantity, uint256 grade, uint256 quality, uint256 expiringDuration, address author) public {
        require(resIds.length == quantity, "invalid parameters");
        MintData memory mintData;
        mintData.amount = 0;
        mintData.resBaseId = 0;
        mintData.nftType = 0;
        mintData.ruleId = ruleId;

        MintExtraData memory extraData;
        extraData.gego_id = 0;
        extraData.grade = grade;
        extraData.quality = quality;
        extraData.expiringDuration = expiringDuration;
        extraData.author = author;

        for (uint256 i = 0; i < quantity; i ++) {
            _adminGegoId ++;
            extraData.gego_id = _adminGegoId;
            mintData.resBaseId = resIds[i];
            gmMint(mintData, extraData);
        }
    }

    function inject(uint256 tokenId, uint256 amount) external override returns (bool) {

        address origin = msg.sender;
        INFTSignature.Gego storage gego = _gegoes[tokenId];
        require(gego.id > 0, "not exist");

        if(_minters[msg.sender] == false){
            require(!origin.isContract(), "call to non-contract");
        }

        require(_isUserStart || _minters[msg.sender], "can't mint");
        require(_ruleProxys[gego.nftType] != IGegoRuleProxy(address(0)), " invalid mint nftType!");
        require(_spynNftToken.ownerOf(tokenId) == msg.sender, "not owner");

        IGegoRuleProxy.MintParams memory params;
        params.user = msg.sender;
        params.amount = amount;
        params.ruleId = gego.ruleId;
        params.fromAdmin = false;

        (uint256 mintAmount,,uint256 expiringDuration) = _ruleProxys[gego.nftType].inject(params, gego.amount);

        require(mintAmount > 0, "failed to inject");
        if (gego.amount == 0) {
            gego.expiringTime = block.timestamp + expiringDuration;
        }
        gego.realAmount = gego.realAmount + mintAmount;
        gego.amount = gego.amount + mintAmount;

        emit GegoInjected(tokenId, mintAmount);

        return true;
    }

    function takeFee(uint256 tokenId, uint256 feeAmount, address receipt, bool reflectAmount) external override returns (address) {
        INFTSignature.Gego storage gego = _gegoes[tokenId];
        require(gego.id > 0, "not exist");
        require(_nftPools[msg.sender], "caller is not operator");
        require(feeAmount < gego.amount, "invalid fee amount");

        address gegoToken = _ruleProxys[gego.nftType].takeFee(gego, feeAmount, receipt);
        gego.realAmount = gego.realAmount - feeAmount;
        if (reflectAmount) {
            gego.amount = gego.realAmount;
        }

        emit GegoAmountReduced(gego.id, feeAmount, gego.realAmount, gego.amount);
        return gegoToken;
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4) {
        //only receive the _nft staff
        if(address(this) != operator) {
            //invalid from nft
            return 0;
        }
        //success
        emit NFTReceived(operator, from, tokenId, data);
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}