//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { SD59x18, sd } from "@prb/math/src/SD59x18.sol";
import "../accessControl/AccessProtectedSummon.sol";
import "../tokens/NFT/OriginBlock.sol";
import "../tokens/NFT/Bezoge.sol"; 
import "../tokens/MBLKToken.sol"; 
import "../tokens/IUSDT.sol";
import "../IDO/MBLKIDOV2.sol"; 

contract SummoningV2 is ERC1155Holder,ReentrancyGuardUpgradeable, PausableUpgradeable, AccessProtectedUpgradable{
    using ECDSAUpgradeable for bytes32;
    using SafeERC20Upgradeable for ERC20Upgradeable;

    OriginBlock public  originBlock;
    Bezogi      public  bezogiNFT;
    MBLK        public  mblkToken;
    IERC20      public  ZOGI;
    IUSDT       public  USDT; 
    MBLKIDOV2   public  MblkIdo;
    string      public  refId;
    address     public  beneficiary;
    uint256     public  summonTime;
    bool        public  originBlockSummonPause;
    bool        public  bezogiSummonPause;
    int256      public  initialPrice;
    bool        public  idoStatus;
    bool        private initialized;

    mapping(uint256 => uint256) public summonCount;
    mapping(bytes32 => bool)    public originRecords;
    mapping(bytes32 => bool)    public bezogiRecords;

    mapping(bytes32 => address) public summonOwner;
    mapping(uint256 => bytes32) public tokenSummonId;
    mapping(bytes32 => bool)    public summonIdClaimed;    
    mapping(bytes32 => uint256) public summonStartTime;

    mapping(address => bool)    private authorizedSigners;

    event OriginBlockSummoned(bytes32 summonId, uint256 newNftId,address user, uint256 tokenId);
    event SummonClaimed(bytes32 summonId, uint256 newNftId, address userAddress, uint256 tokenId1, uint256 tokenId2);
    event BezogiSummonStarted(bytes32 summonId, address user, uint256 tokenId1, uint256 tokenId2, uint256 MBLKamount);


    function init(address originBlockAddr, address bezogiNFTaddr, address mblkAddr,
        address mblkIdoAddr, address zogiToken_,address usdtAddress_)external initializer {
        
        require(!initialized, "Can not re-initialize");
        
        initialized = true;
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        originBlock = OriginBlock(originBlockAddr);
        bezogiNFT = Bezogi(bezogiNFTaddr);
        mblkToken = MBLK(mblkAddr);
        MblkIdo = MBLKIDOV2(mblkIdoAddr);
        USDT = IUSDT(usdtAddress_);
        ZOGI = IERC20(zogiToken_);
        initialPrice = 100 * 10**18;
        summonTime = 7 days;
        idoStatus = true;
    }

    function originBlockSummonStatus(bool status_)external onlyOwner{
        originBlockSummonPause = status_;
    }

    function bezogiSummonStatus(bool status_)external onlyOwner{
        bezogiSummonPause = status_;
    }

    function updateSummonTime(uint256 time)external onlyOwner{
        require(time > 0, "Invalid time period");
        summonTime = time;
    }

    function updateIdoStatus(bool status) external onlyOwner{
        idoStatus = status;
    }
    /**
    * @dev Allows the origin block owner to summon a new NFT token by transferring a specified amount of the origin block token to this contract.
    * @param tokenId The ID of the origin block token to be transferred.
    * @param nonce A random number to ensure uniqueness of the summon.
    * @return summonId The unique identifier of the newly summoned NFT token.
    */
    function originBlockSummon(uint256 tokenId, uint256 nonce)
        public whenNotPaused nonReentrant returns(bytes32 summonId)
    {
        require(!originBlockSummonPause, "Summoning through origin block is paused");
        require(originBlock.balanceOf(msg.sender, tokenId) > 0, "Only orgin block owner can summon");

        uint256 amount = 1;
        summonId = keccak256(
            abi.encodePacked(
                tokenId,
                msg.sender,
                amount,
                nonce
            )
        );

        require(originRecords[summonId] == false, "record already exists");
        originRecords[summonId] = true;

        originBlock.safeTransferFrom(msg.sender, address(this), tokenId, amount, "0x");
        originBlock.burn(address(this), tokenId, amount);

        uint256 nftId = bezogiNFT.totalSupply();
        bezogiNFT.mintTo(msg.sender, amount);

        emit OriginBlockSummoned(summonId, nftId, msg.sender, tokenId);
        return summonId;
    }

    function bulkOriginBlockSummon(uint256 tokenId, uint256 nonce, uint256 amount)
        public whenNotPaused nonReentrant onlyAdmin
    {
        require(!originBlockSummonPause, "Summoning through origin block is paused");
        require(originBlock.balanceOf(msg.sender, tokenId) >= amount, "Only orgin block owner can summon");

        originBlock.safeTransferFrom(msg.sender, address(this), tokenId, amount, "0x");
        originBlock.burn(address(this), tokenId, amount);

        uint256 nftId = bezogiNFT.totalSupply();
        bezogiNFT.mintTo(msg.sender, amount);

        for(uint256 i = 0; i < amount; i++){
            bytes32 summonId = keccak256(
                abi.encodePacked(
                    tokenId,
                    msg.sender,
                    nftId+i,
                    nonce
                )
            );

            require(originRecords[summonId] == false, "record already exists");
            originRecords[summonId] = true;

            emit OriginBlockSummoned(summonId, nftId+i, msg.sender, tokenId);
        }
    }

    // payment type 
    // 1 = eth
    // 2 = usdt 
    // 3 = use ido allocation
    // 4 = mblk 


    function bezogiSummon(uint256[] memory nftInfo, uint8 paymentType, uint256 mblkUsdVal, uint256 nonce, bytes memory signature_) 
       public payable whenNotPaused nonReentrant returns(bytes32 summonId)
    {
        require(!bezogiSummonPause, "Summoning through bezogi is paused");
        require(bezogiNFT.ownerOf(nftInfo[0]) == msg.sender && bezogiNFT.ownerOf(nftInfo[1]) == msg.sender,
                "Only Bezogi NFT owner can summon");
        require(paymentType > 0 && paymentType < 5, "Invalid payment type");
    
        uint256 idoStage = MblkIdo.currentStage();

        if (paymentType != 4){
            require( (idoStage < 5) || (idoStatus== true), "Can not use this payment type, ido closed");
        }
        
        uint256 summonCostVal = getSummonCost(nftInfo[2], summonCount[nftInfo[0]], bezogiNFT.totalSupply());
        summonCostVal += getSummonCost(nftInfo[3], summonCount[nftInfo[1]], bezogiNFT.totalSupply());
        summonCostVal = summonCostVal/2;

        summonId = keccak256(
            abi.encodePacked(
                nftInfo[0], nftInfo[1],
                nftInfo[2], nftInfo[3],
                summonCount[nftInfo[0]], summonCount[nftInfo[1]],
                msg.sender, mblkUsdVal, nonce
            )
        ); 

        require(bezogiRecords[summonId] == false, "record already exists");
        bezogiRecords[summonId] = true;

        bytes32 prefixedHash = summonId.toEthSignedMessageHash();
        address msgSigner = recover(prefixedHash, signature_);

        require(authorizedSigners[msgSigner], "Invalid Signer");

        summonCount[nftInfo[0]] += 1;
        summonCount[nftInfo[1]] += 1;
        summonOwner[summonId] = msg.sender;
        tokenSummonId[nftInfo[0]] = summonId;
        tokenSummonId[nftInfo[1]] = summonId;

        if (paymentType == 1){
            summonCostVal = getSummonCostEth(summonCostVal);
            require(msg.value == summonCostVal, "Invalid eth amount");
            MblkIdo.getMBLKAllocation{value: msg.value}(paymentType, beneficiary, summonCostVal, refId);
        }
        if (paymentType == 2){
            summonCostVal = getSummonCostUsdt(summonCostVal);
            ERC20Upgradeable(address(USDT)).safeTransferFrom(msg.sender, address(this), summonCostVal);
            MblkIdo.getMBLKAllocation(3, beneficiary, summonCostVal, refId); // usdt = 3 in IDO contract
        }
        if (paymentType == 3){
            summonCostVal = getSummonCostMBLKAlloaction(summonCostVal);
            MblkIdo.decreaseAllocation(summonCostVal, msg.sender);
            MblkIdo.increaseAllocation(summonCostVal, beneficiary);
        }
        if (paymentType == 4){
            summonCostVal = getSummonCostMBLK(summonCostVal, mblkUsdVal);
            require(mblkToken.transferFrom(msg.sender, address(this), summonCostVal), "MBLK transfer failed");            
        }

        bezogiNFT.transferFrom(msg.sender, address(this), nftInfo[0]);
        bezogiNFT.transferFrom(msg.sender, address(this), nftInfo[1]);

        emit BezogiSummonStarted(summonId, msg.sender, nftInfo[0], nftInfo[1], summonCostVal);
        return summonId;
    }

    function claimSummon(bytes32 summonId, uint256 tokenId1, uint256 tokenId2 )
        public whenNotPaused nonReentrant
    {
        require(summonOwner[summonId] == msg.sender, "Only summon owner can claim");
        require(tokenSummonId[tokenId1] == summonId, "Invalid tokenId for summon claim");
        require(tokenSummonId[tokenId2] == summonId, "Invalid tokenId for summon claim");
        require(summonIdClaimed[summonId] == false, "SummonId already claimed");
        require(summonStartTime[summonId] + summonTime <= block.timestamp, "Can not summon during lock period");

        summonIdClaimed[summonId] = true;
        bezogiNFT.transferFrom(address(this), msg.sender, tokenId1);
        bezogiNFT.transferFrom(address(this), msg.sender, tokenId2);

        uint256 nftId = bezogiNFT.totalSupply();

        bezogiNFT.mintTo(msg.sender, 1);
        emit SummonClaimed(summonId, nftId, msg.sender, tokenId1, tokenId2);
    }

    function updateSignerStatus(address signer, bool status) external onlyOwner {
        authorizedSigners[signer] = status; 
    }

    function isSigner(address signer) external view returns (bool) {
        return authorizedSigners[signer];
    }

    function withdrawMBLK(uint256 mblkAmount, address withdrawAddr)external onlyOwner{
        mblkToken.transferFrom(address(this), withdrawAddr, mblkAmount);
    }
    
    function withdrawUsdt(uint256 amount,  address wallet)external onlyOwner{
        USDT.transfer(wallet, amount);
    }

    function withdrawEth(uint256 amount, address wallet) external onlyOwner{
        transferEth(amount, wallet);
    }

    function transferEth(uint256 amount, address to)private {
        (bool sent,) = to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
    function recover(bytes32 hash, bytes memory signature_) private pure returns(address) {
        return hash.recover(signature_);
    }

    function getSummonCostEth(uint256 summonCostVal)public view returns(uint256){
        uint256 ethRate = MblkIdo.ethUsdRate();
        summonCostVal = (summonCostVal * 1 ether) / (ethRate * 1000000000000000);
        return summonCostVal;
    }

    function getSummonCostMBLK(uint256 summonCostVal, uint256 mblkRate)public view returns(uint256){
        uint256 summonCost = summonCostVal / mblkRate; 
        return summonCost * 1000;
    }

    function getSummonCostUsdt(uint256 summonCostVal)public pure returns(uint256){
        summonCostVal = summonCostVal / (1*10**12);
        return summonCostVal;
    }

    function getSummonCostMBLKAlloaction(uint256 summonCostVal)public view returns(uint256){
        uint256 currentStage = MblkIdo.currentStage();
        uint256 currentRate = MblkIdo.usdtRate(currentStage);
        summonCostVal = (summonCostVal * currentRate)/1000; //divide by 1000 because rate has 3 extra decimals

        return summonCostVal;
    }

    function updateInitialPrice(int256 initialPrice_)external onlyOwner{
        initialPrice = initialPrice_;
    } 

    function getTotalSummonCost(uint256 nftId1, uint256 nftId2, uint256 nft1gen, uint256 nft2gen) public view returns(uint256){
        uint256 summonCostVal = getSummonCost(nft1gen, summonCount[nftId1], bezogiNFT.totalSupply());
        summonCostVal += getSummonCost(nft2gen, summonCount[nftId2], bezogiNFT.totalSupply());
        summonCostVal = summonCostVal/2;
        return summonCostVal;
    }

    // function to calculate summon cost
    function getSummonCost(uint256 gen, uint256 summonCount_, uint256 currentTotalSupply)public view returns(uint256){
        SD59x18 price = sd(initialPrice);

        SD59x18 result = price;
        result = result.mul(_genCost(int(gen))).mul(_summonCountCost(int(summonCount_))).
                mul(_supplyCost(int(currentTotalSupply)));
        
        return result.intoUint256();
    }
    
    function _genCost(int256 gen) private pure returns (SD59x18 result){
        SD59x18 k1 = sd(1.05e18);
        gen = gen * 10**18;
        SD59x18 generation = sd(gen);      
        
        result = k1;
        result = result.pow(generation);

    }

    function _summonCountCost(int256 summonCount_)private pure returns (SD59x18 result){
        SD59x18 k2 = sd(1.1e18);
        summonCount_ = summonCount_ * 10**18;
        SD59x18 summoncount = sd(summonCount_);

        result = k2;
        result = result.pow(summoncount);
    }

    function _supplyCost(int256 currentTotalSupply_)private pure returns (SD59x18 result){
        SD59x18 k3 = sd(0.15e18);
        SD59x18 initialTotalSupply = sd(4096e18);
        currentTotalSupply_ = currentTotalSupply_ * 10**18;
        SD59x18 currentTotalSupply = sd(currentTotalSupply_);
        
        result = currentTotalSupply;
        result = result.div(initialTotalSupply);
        result = result.pow(k3);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
    
    function renounceOwnership() public view override onlyOwner {
        revert("can't renounceOwnership here");
    }

    function setRefId(string memory refId_)public onlyOwner{
        refId = refId_;
    }

    function setBeneficiary(address beneficiary_)public onlyOwner{
        beneficiary = beneficiary_;
    }

    function approveUSDT(uint256 value) public{
        ERC20Upgradeable(address(USDT)).safeApprove(address(MblkIdo), value);
    }

}