//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IN.sol";
import "../interfaces/INOwnerResolver.sol";
import "../libraries/PotenzaUtils.sol";
import "./PotenzaPricing.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//               _____      _                                    //
//              |  __ \    | |                                   //
//              | |__) |__ | |_ ___ _ __  ______ _               //
//              |  ___/ _ \| __/ _ \ '_ \|_  / _` |              //
//              | |  | (_) | ||  __/ | | |/ / (_| |              //
//              |_|   \___/ \__\___|_| |_/___\__,_|              //
//                                                               //
//                                                               //
//  Art: Gavin Potenza                                           //
//  Dev: Archethect                                              //
//  Description: Contract for the creation of on-chain           //
//               Potenza Art with the possibility to burn        //
//               black/white art for color versions.             //
///////////////////////////////////////////////////////////////////

contract Potenza is PotenzaPricing {

    using SafeMath for uint256;
    using Address for address;


    string public metadataUri;
    string public metadataExtension;
    bool public openSale;
    bool public nPreSale;
    bool public publicPreSale;
    bool public colorBurn;
    uint16 public currentSupply;
    uint nonce;
    uint256 presaleNAddressAmount = 303;
    uint256 presaleNCount;
    uint256 presalePublicAmount = 819;
    uint256 presalePublicCount;
    uint256 presaleMintsPerAddress = 3;
    uint256 giveaways = 14;
    uint256 openSaleTimestamp;
    address giveawayAddress = 0x92D5561C7Ee3116B29117d10Ac79227c46C9C689;
    INOwnerResolver public immutable nOwnerResolver;

    mapping(uint256 => bool) burned;
    mapping(uint256 => bool) redeemed;
    mapping(address => uint256) redeemedByaddress;
    mapping(address => bool) presaleAddress;

    event Burnt(address to, uint256 burntTokenId1, uint256 burntTokenId2, uint256 colorTokenId);

    DerivativeParameters params = DerivativeParameters(false, false, 0, 1333, 3);

    constructor (string memory _name, string memory _symbol, address _n, address masterMint, address dao, address nOwnersRegistry) PotenzaPricing(_name, _symbol, IN(_n), params, 66600000000000000, 99900000000000000, masterMint, dao) {
        metadataUri = "https://arweave.net/Ug_hX5BSsh8WHnjFcWDqwWlWqULOqyZPFN4wL63-mGo/";
        metadataExtension = ".json";
        nOwnerResolver =  INOwnerResolver(nOwnersRegistry);
    }

    function switchOpenSale(bool status) public onlyAdmin {
        openSale = status;
        if(status && openSaleTimestamp == 0) {
            openSaleTimestamp = block.timestamp;
        }
    }

    function switchColorBurn(bool status) public onlyAdmin {
        colorBurn = status;
    }

    function switchNPresale(bool status) public onlyAdmin {
        nPreSale = status;
    }

    function switchPublicPresale(bool status) public onlyAdmin {
        publicPreSale = status;
    }

    function setPresaleAddresses(address[] calldata addresses) external onlyAdmin {
        for(uint256 i = 0; i < addresses.length; i++) {
            presaleAddress[addresses[i]] = true;
        }
    }

    /**
     * @notice Allow anyone to mint one or multiple tokens during the open sale. During the public presale only
               addresses of the presale list are eligible to buy an this up to 'presaleMintsPerAddress' tokens. Minted
               tokenId's are randomised.
     * @param recipient Recipient of the mint
     * @param amount Amount of tokens to mint
     * @param paid Amount paid for the mint
     */
    function mint(
        address recipient,
        uint8 amount,
        uint256 paid
    ) public virtual override nonReentrant {
        require(publicPreSale || openSale, "POTENZA:SALE_NOT_OPEN");
        require(amount <= derivativeParams.maxMintAllowance, "POTENZA:MINT_ABOVE_ALLOWANCE");
        require(totalMintsAvailable() >= amount, "POTENZA:MAX_ALLOCATION_REACHED");
        if(publicPreSale && !openSale) {
            require(presaleAddress[recipient], "POTENZA:NOT_ON_PRESALE_LIST");
            require(presalePublicCount + amount <= presalePublicAmount, "POTENZA:AMOUNT_EXCEEDS_PRESALE_LIMIT");
            require(redeemedByaddress[recipient] + amount <= presaleMintsPerAddress, "POTENZA:AMOUNT_EXCEEDS_PERSONAL_LIMIT");
            redeemedByaddress[recipient] += amount;
            presalePublicCount += amount;
        }
        require(paid == getNextPriceForOpenMintInWei(amount), "POTENZA:INVALID_PRICE");

        for (uint256 i = 0; i < amount; i++) {
            currentSupply++;
            uint256 id = randomId();
            _safeMint(recipient, id);
        }
    }

    /**
     * @notice Allow N holders to buy during the N presale or open sale with their N number. During the presale
               'presaleNAddressAmount' tokens can be minted in total. We try to match the tokenId with the
                N number if it is still available. If not, the tokenId is randomised.
     * @param recipient Recipient of the mint
     * @param tokenIds Ids to be minted
     * @param paid Amount paid for the mint
     */
    function mintWithN(
        address recipient,
        uint256[] calldata tokenIds,
        uint256 paid
    ) public override virtual nonReentrant {
        require(nPreSale || openSale, "POTENZA:SALE_NOT_OPEN");
        uint256 maxTokensToMint = tokenIds.length;
        require(maxTokensToMint <= derivativeParams.maxMintAllowance, "POTENZA:MINT_ABOVE_ALLOWANCE");
        require(totalMintsAvailable() >= maxTokensToMint, "POTENZA:MAX_ALLOCATION_REACHED");
        if(nPreSale && !openSale) {
            require(presaleNCount + maxTokensToMint <= presaleNAddressAmount, "POTENZA:AMOUNT_EXCEEDS_PRESALE_LIMIT");
            presaleNCount += maxTokensToMint;
        }
        require(paid == getNextPriceForNHoldersInWei(maxTokensToMint), "POTENZA:INVALID_PRICE");

        for (uint256 j = 0; j < maxTokensToMint; j++) {
            //Check for all tokenIds before minting.
            require(!redeemed[tokenIds[j]], "POTENZA:TOKEN_ALREADY_REDEEMED");
        }

        for (uint256 i = 0; i < maxTokensToMint; i++) {
            uint256 id = tokenIds[i];
            if(_exists(id) || burned[id]) {
                id = randomId();
            }
            currentSupply++;
            redeemed[tokenIds[i]] = true;
            _safeMint(recipient, id);
        }
    }


    /**
     * @notice Allow anyone to burn two Potenza tokens the own and mint a new colored token with the inherited rarity of the
     *         rarest token.
     * @param tokenId1 id of first token to burn
     * @param tokenId2 id of second token to burn
     */
    function burnForColor(uint256 tokenId1, uint256 tokenId2) public nonReentrant {
        require(ownerOf(tokenId1) == msg.sender && ownerOf(tokenId2) == msg.sender, "POTENZA:INCORRECT_OWNER");
        require(tokenId1 != tokenId2, "POTENZA:EQUAL_TOKENS");
        require(tokenId1 > 0 && tokenId1 <= MAX_N_TOKEN_ID && tokenId2 > 0 && tokenId2 <= MAX_N_TOKEN_ID, "POTENZA:INVALID_TOKEN");
        require(colorBurn, "POTENZA:BURN_INACTIVE");

        uint256 rarest = getRarityScore(tokenId1) < getRarityScore(tokenId2) ? tokenId2 : tokenId1;

        _burn(tokenId1);
        _burn(tokenId2);
        burned[tokenId1] = true;
        burned[tokenId2] = true;
        _mint(msg.sender, 10000+rarest);
        emit Burnt(msg.sender, tokenId1, tokenId2, 10000+rarest);
    }

    /**
     * @notice redeem giveaways
     */
    function redeemGiveaways() external onlyAdmin {
        for (uint256 i = 0; i < giveaways; i++) {
            currentSupply++;
            uint id = randomId();
            super._safeMint(giveawayAddress, id, "");
        }
    }

    /**
     * @notice Calculate the total available number of mints. This includes the 'Snark double burn'™ mechanism kicking in at 18 hours after the open sale started.
     * @return total mint available
     */
    function totalMintsAvailable() public view override returns (uint256) {
        uint256 totalAvailable = derivativeParams.maxTotalSupply - currentSupply;
        if(openSaleTimestamp != 0 && block.timestamp > openSaleTimestamp + 18 hours) {
            // Double candle burning starts and decreases max. mintable supply with 1 token per minute.
            uint256 doubleBurn = (block.timestamp - (openSaleTimestamp + 18 hours)) / 1 minutes;
            totalAvailable = totalAvailable > doubleBurn ? totalAvailable - doubleBurn : 0;
        }
        return totalAvailable;
    }

    function canMint(address account) public virtual override view returns (bool) {
        if(openSale &&
            (totalMintsAvailable() > 0)) {
            return true;
        }
        if(nPreSale &&
            (totalMintsAvailable() > 0) &&
            (nOwnerResolver.balanceOf(account) > 0) &&
            (presaleNCount < presaleNAddressAmount)) {
            return true;
        }
        if(publicPreSale &&
            (totalMintsAvailable() > 0) &&
            (presaleAddress[account] == true) &&
            (redeemedByaddress[account] < presaleMintsPerAddress)) {
            return true;
        }
        return false;
    }

    function getRarityScore(uint256 tokenId) public view returns (uint256) {
        tokenId = tokenId > 10000 ? tokenId-10000 : tokenId;
        uint[3] memory highestFrequency = PotenzaUtils.getHighestFrequency(tokenId, n);
        uint256 maxSequence = PotenzaUtils.getMaxSequence(tokenId, n);
        uint256 sum = PotenzaUtils.getSum(tokenId, n);
        uint256 zeroOrFourteen = PotenzaUtils.getZeroOrFourteenScore(tokenId, n);
        uint256 sumScore = (sum <= 30 || sum > 60) ? ((sum <= 20 || sum > 70) ? 10 : 5) : 0;
        return (((3*highestFrequency[0])+(2*highestFrequency[1])+highestFrequency[2]+(maxSequence*maxSequence) + sumScore + zeroOrFourteen) * 2) - 2;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(super.tokenURI(tokenId),metadataExtension));
    }

    function setMetadataURIAndExtension(string calldata metadataUri_, string calldata metadataExtension_) external onlyDAO {
        metadataUri = metadataUri_;
        metadataExtension = metadataExtension_;
    }

    function random() private view returns(uint256) {
        return uint256((uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.difficulty, nonce))) % MAX_N_TOKEN_ID) + 1);
    }

    function randomId() private returns (uint256) {
        uint256 id = random();
        nonce++;
        //Make sure we select an N number that has not been used for minting.
        while(_exists(id) || burned[id]) {
            nonce++;
            id = random();
        }
        return id;
    }

    function _baseURI() override internal view virtual returns (string memory) {
        return metadataUri;
    }
}