// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./interfaces/IAnito.sol";
import "./interfaces/IAnitoGacha.sol";
import "./interfaces/IDuende.sol";
contract AnitoGachaV3 is Pausable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant COMMON = 0;
    uint256 public constant EPIC = 1;
    uint256 public constant LEGENDARY = 2;
    uint256 public constant ALL = 3;
    uint256 public constant DUENDE = 4;

    mapping(uint256 => uint256) public gachaWhitelistPrices;
    mapping(uint256 => uint256) public gachaPrices;
    mapping(address => bool) public whitelistedAddresses;
    mapping(address => uint256) public whitelistAnitoLimit;
    mapping(uint256 => uint256) public wlMaxMintPerCategory;
    mapping(uint256 => uint256) public wlTotalMintedPerCategory;
    mapping(uint256 => uint256) public publicMaxMintPerCategory;
    mapping(uint256 => uint256) public publicTotalMintedPerCategory; 
    mapping(uint256 => bool) usedNonces;
    mapping(string => uint256) public voucherCodeUseCount;
    mapping(address => uint256) public mintedDuende;


    bool public privateSaleStatus;
    bool public publicSaleStatus;

    IAnito public anitoNFT;
    IDuende public duendeNFT;
    IAnitoGacha public anitoGachaV1;
    ERC20 public busdToken;
    address public treasuryAddress;

    address private signer;

    event VoucherUsed(address indexed player, string voucher_code, uint256 quantity, uint256 rarity);

    constructor(address _anitoNFT, address _busdAddress, address _treasuryAddress, address _anitoGachaV1, address _signer, address _duendeNFT){
        busdToken = ERC20(_busdAddress);
        treasuryAddress = _treasuryAddress;

        anitoGachaV1 = IAnitoGacha(_anitoGachaV1);
        
        gachaPrices[COMMON] = anitoGachaV1.gachaPrices(COMMON);
        gachaPrices[EPIC] = anitoGachaV1.gachaPrices(EPIC);
        gachaPrices[LEGENDARY] = anitoGachaV1.gachaPrices(LEGENDARY);
        gachaPrices[DUENDE] = 5 * 10 ** busdToken.decimals();

        publicTotalMintedPerCategory[COMMON] = anitoGachaV1.publicTotalMintedPerCategory(COMMON);
        publicTotalMintedPerCategory[EPIC] = anitoGachaV1.publicTotalMintedPerCategory(EPIC);
        publicTotalMintedPerCategory[LEGENDARY] = anitoGachaV1.publicTotalMintedPerCategory(LEGENDARY);

        publicMaxMintPerCategory[COMMON] = anitoGachaV1.publicMaxMintPerCategory(COMMON);
        publicMaxMintPerCategory[EPIC] = anitoGachaV1.publicMaxMintPerCategory(EPIC);
        publicMaxMintPerCategory[LEGENDARY] = anitoGachaV1.publicMaxMintPerCategory(LEGENDARY);
        publicMaxMintPerCategory[DUENDE] = 999;

        publicSaleStatus = true;

        anitoNFT = IAnito(_anitoNFT);
        duendeNFT = IDuende(_duendeNFT);

        signer = _signer;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setAnitoNFTAddress(address _anitoNFT) public onlyOwner {
        anitoNFT = IAnito(_anitoNFT);
    }

    function setTreasuryAddress(address _treasuryAddress) public onlyOwner {
        treasuryAddress = _treasuryAddress;
    }

    function setCategoryBUSDPrice(uint256 gachaCategory, uint256 busdPrice) public onlyOwner {
        gachaPrices[gachaCategory] = busdPrice;
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function getRemainingGachas() public view returns(uint256 common,uint256 epic,uint256 legendary){
        common = (publicMaxMintPerCategory[COMMON] - publicTotalMintedPerCategory[COMMON]);
        epic = (publicMaxMintPerCategory[EPIC] - publicTotalMintedPerCategory[EPIC]);
        legendary = (publicMaxMintPerCategory[LEGENDARY] - publicTotalMintedPerCategory[LEGENDARY]);
    }
    function buyGacha(
        uint256 gachaCategory, uint256 quantity, 
        uint256 voucherRarity,
        string memory voucherCode,
        uint256 voucherRate, 
        uint256 voucherType, 
        uint256 maxVoucherCodeUse,
        uint256 maxVoucherQuantityMode,
        address partnerAddress,
        uint256 nonce, bytes memory _sig
        ) public nonReentrant whenNotPaused {
        require(quantity > 0,"zero quantity");
        if(gachaCategory != DUENDE){
            require(anitoNFT.totalSupply() + quantity <= 10000, "max supply reached");
        }else{
            require(duendeNFT.totalSupply() + quantity <= 999, "max supply reached");
            require(mintedDuende[msg.sender] + quantity <= 20, "max duende mint reached");
            mintedDuende[msg.sender] += quantity;
        }
        require(publicSaleStatus,"sale not yet opened");
        require(gachaPrices[gachaCategory] > 0,"invalid price");
        
        require(publicTotalMintedPerCategory[gachaCategory] + quantity <= publicMaxMintPerCategory[gachaCategory],"max category reached");

        processVoucherMechanics(msg.sender,gachaCategory,quantity,voucherRarity,voucherCode,voucherRate,voucherType,maxVoucherCodeUse,maxVoucherQuantityMode,partnerAddress,nonce,_sig);

        publicTotalMintedPerCategory[gachaCategory] += quantity;
        
        if(gachaCategory != DUENDE){
            if(quantity > 1){
                anitoNFT.safeMint(msg.sender, quantity, gachaCategory);
            }else{
                anitoNFT.safeMintSingle(msg.sender,gachaCategory);
            }
        }else{
            if(quantity > 1){
                duendeNFT.safeMint(msg.sender, quantity);
            }else{
                duendeNFT.safeMintSingle(msg.sender);
            }
        }
    }

    function processVoucherMechanics(
        address player,
        uint256 gachaCategory,
        uint256 quantity,
        uint256 voucherRarity,
        string memory voucherCode,
        uint256 voucherRate,
        uint256 voucherType,
        uint256 maxVoucherCodeUse,
        uint256 maxVoucherQuantityMode,
        address partnerAddress,
        uint256 nonce,
        bytes memory _sig
    ) internal {
        if(voucherType > 0){
            bytes32 message = prefixed(
                keccak256(abi.encodePacked(
                    player, gachaCategory, quantity, voucherRarity, voucherCode, 
                    voucherRate, voucherType, maxVoucherCodeUse, maxVoucherQuantityMode, partnerAddress, nonce))
            );
            require(recoverSigner(message, _sig) == signer, "Invalid signer");
            require(!usedNonces[nonce],"nonce already used");

            if(voucherRarity != 3){
                require(voucherRarity == gachaCategory,"gacha category mismatch");
            }

            if(maxVoucherCodeUse > 0){
                if(maxVoucherQuantityMode == 0){
                    require(voucherCodeUseCount[voucherCode] + 1 <= maxVoucherCodeUse,"voucher code limit reached");
                    voucherCodeUseCount[voucherCode]++;
                }
                if(maxVoucherQuantityMode == 1){
                    require(voucherCodeUseCount[voucherCode] + quantity <= maxVoucherCodeUse,"voucher code limit reached");
                    voucherCodeUseCount[voucherCode] += quantity;
                }
            }

            if(maxVoucherQuantityMode == 0){
                emit VoucherUsed(player, voucherCode, 1, gachaCategory);
            }
            if(maxVoucherQuantityMode == 1){
                emit VoucherUsed(player, voucherCode, quantity, gachaCategory);
            }

            usedNonces[nonce] = true;
            uint256 grossAmount = gachaPrices[gachaCategory] * quantity;
            processDiscount(voucherType,grossAmount,voucherRate,partnerAddress);
            
        }else{
            processDefaultPayment(gachaCategory, quantity);
        }
    }

    function processDefaultPayment(uint256 gachaCategory, uint256 quantity) internal {
        busdToken.transferFrom(msg.sender, address(this), gachaPrices[gachaCategory] * quantity);
        busdToken.transfer(treasuryAddress,gachaPrices[gachaCategory] * quantity);
    }

    function processDiscount(uint256 voucherType, uint256 grossAmount, uint256 voucherRate, address partnerAddress) internal {
        uint256 discountAmount = 0;
        uint256 netAmount = 0;
        if(voucherType == 1 || voucherType == 3){
            discountAmount = (grossAmount * ((voucherRate*100))/ 10000);
            netAmount = grossAmount - discountAmount;
        }

        if(voucherType == 2 || voucherType == 4){
            discountAmount = (voucherRate * 10 ** busdToken.decimals());
            netAmount = grossAmount - discountAmount;
        }

        if(voucherType == 1 || voucherType == 2){
            busdToken.transferFrom(msg.sender, address(this), netAmount);
            busdToken.transfer(treasuryAddress, netAmount);
        }

        if(voucherType == 3 || voucherType == 4){
            busdToken.transferFrom(msg.sender, address(this), grossAmount);
            busdToken.transfer(treasuryAddress, netAmount);
            if(partnerAddress != address(0)){
                busdToken.transfer(partnerAddress, discountAmount);
            }else{
                busdToken.transfer(treasuryAddress, discountAmount);
            }
        }
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65, "Incorrect signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            //first 32 bytes, after the length prefix
            r := mload(add(sig, 0x20))
            //next 32 bytes
            s := mload(add(sig, 0x40))
            //final byte, first of next 32 bytes
            v := byte(0, mload(add(sig, 0x60)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}