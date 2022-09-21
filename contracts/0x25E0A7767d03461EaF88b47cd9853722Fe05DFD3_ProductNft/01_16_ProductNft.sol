//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { IERC2981, IERC165 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./utils/SlowMintable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


/**
@title ProductNft
@author Marco Huberts & Javier Gonzalez
@dev    Implementation of a Valorize Product Non Fungible Token using ERC1155.
*       Key information: the metadata should be ordered. The rarest NFTs should be the lowest tokenIds, then rarer and then rare NFTs.
*/
contract ProductNft is ERC1155, IERC2981, AccessControl, ReentrancyGuard, SlowMintable {
    using Counters for Counters.Counter;

    uint16 public immutable startRarerTokenIdIndex;
    uint16 public immutable startRareTokenIdIndex;
    uint16 public rarestTokensLeft;
    uint16 public rarerTokensLeft;
    uint16 public rareTokensLeft;
    Counters.Counter public rarestTokenIdCounter;
    Counters.Counter public rarerTokenIdCounter;
    Counters.Counter public rareTokenIdCounter;
    uint256 public PRICE_PER_RAREST_TOKEN;
    uint256 public PRICE_PER_RARER_TOKEN;
    uint256 public PRICE_PER_RARE_TOKEN;
    bool internal frozen = false;
    address public royaltyDistributorAddress;
    address public artistAddress;
    bytes32 public constant ARTIST_ROLE = keccak256("ARTIST_ROLE");

    mapping(uint256 => ProductStatus) public ProductStatusByTokenId;
  
    enum Rarity {rarest, rarer, rare}
    enum ProductStatus {not_ready, ready, redeemed}

    event MintedTokenInfo(uint256 tokenId, string rarity, string productStatus);

    constructor( 
        string memory baseURI_,
        address _royaltyDistributorAddress,
        address _artistAddress,
        uint16 _startRarerTokenIdIndex,
        uint16 _startRareTokenIdIndex,
        uint16 _totalAmountOfTokenIds
        ) ERC1155(baseURI_) {
            royaltyDistributorAddress = _royaltyDistributorAddress;
            artistAddress = _artistAddress;
            startRarerTokenIdIndex = _startRarerTokenIdIndex;
            startRareTokenIdIndex = _startRareTokenIdIndex;
            rarestTokensLeft = _startRarerTokenIdIndex;
            rarerTokensLeft = _startRareTokenIdIndex - _startRarerTokenIdIndex; 
            rareTokensLeft = _totalAmountOfTokenIds - _startRareTokenIdIndex;
            _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
            _setupRole(ARTIST_ROLE, _artistAddress);
            _setRoleAdmin(ARTIST_ROLE, ARTIST_ROLE);
            _setTokensToMintPerRarity(1, "rarest");
            _setTokensToMintPerRarity(12, "rarer");
            _setTokensToMintPerRarity(36, "rare");
            rarestBatchMint(1);
            rarerBatchMint(12);
            rareBatchMint(36);
            setTokenPrice();
    }

    function freeze() external onlyRole(DEFAULT_ADMIN_ROLE) {
        frozen = true;
    }

    function setURI(string memory _baseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!frozen);
        _setURI(_baseURI);
    }

    function setTokenPrice() internal {
        PRICE_PER_RAREST_TOKEN = 1.5 ether;
        PRICE_PER_RARER_TOKEN = 0.5 ether;
        PRICE_PER_RARE_TOKEN = 0.1 ether;
    }

    /**
    *@dev   This function allows the generation of a URI for a specific token Id with the format {baseUri}/{id}/{status}.json
    *       the id in this case is a decimal string representation of the token Id
    *@param tokenId is the token Id to generate or return the URI for.     
    */
    function uri(uint256 tokenId) public view override returns (string memory) {
        string[3] memory nftStatuses = ["not-ready", "ready", "redeemed"];
        string memory status = nftStatuses[uint256(ProductStatusByTokenId[tokenId])];
        return string(abi.encodePacked(super.uri(tokenId), Strings.toString(tokenId), "/", status, ".json"));
    }
    

    /**
    * @dev  This function returns the token rarity
    * @param _tokenId is the token Id of the NFT of interest
    */
    function returnRarityById(uint256 _tokenId) public view returns(string memory rarity) {
        if(_tokenId <= startRarerTokenIdIndex) {
            rarity = "Mycelia";

        } else if(_tokenId <= startRareTokenIdIndex && _tokenId > startRarerTokenIdIndex) {
            rarity = "Diamond";

        } else if (_tokenId > startRareTokenIdIndex) {
            rarity = "Silver";
        }
    }

    /**
    *@dev   Using this function, a given amount will be turned into an array.
    *       This array will be used in ERC1155's batch mint function. 
    *@param amount is the amount provided that will be turned into an array.
    */
    function _turnAmountIntoArray(uint16 amount) internal pure returns (uint256[] memory tokenAmounts) {
        tokenAmounts = new uint[](amount);
        for (uint256 i = 0; i < amount;) {
            tokenAmounts[i] = i + 1;
            unchecked {
                i++;
            }
        }
    }

    /**
    *@dev   A counter is used to track the token Ids that have been minted.
    *       A token Id will be returned and turned into an array. 
    *@param rarity The rarity defines at what point the count starts.
    *       Using requirements, rarities have been assigned a set of tokenIds. 
    */
    function _countBasedOnRarity(Rarity rarity) internal returns (uint256 tokenId) {
        if(rarity == Rarity.rarest) {
            rarestTokenIdCounter.increment();
            tokenId = rarestTokenIdCounter.current(); 
        } else if (rarity == Rarity.rarer) {
            rarerTokenIdCounter.increment();
            tokenId = startRarerTokenIdIndex + rarerTokenIdCounter.current();
        } else if (rarity == Rarity.rare) {
            rareTokenIdCounter.increment();
            tokenId = startRareTokenIdIndex + rareTokenIdCounter.current();
        }
    }
    
    /**
    *@dev   This sets the initial product status, creates a URI and emits that info on mint
    *@param tokenId the token Id that will be minted
    *@param rarity The rarity of the token. Initial product status is set based on the rarity
    */
    function _setAndEmitTokenInfo(uint256 tokenId, Rarity rarity) internal {
        _initialProductStatusBasedOnRarity(tokenId, rarity);
        string[3] memory nftStatuses = ["not-ready", "ready", "redeemed"];
        string memory status = nftStatuses[uint256(ProductStatusByTokenId[tokenId])];
        emit MintedTokenInfo(tokenId, returnRarityById(tokenId), status);
    }

    /**
    *@dev   For ERC1155's batch mint function, a an array of token Ids
    *       with equal length to the array of amounts is needed.  
    *@param rarity The rarity defines at what point the count starts.
    *@param amount the given amount that will be turned into an array as
    *       the _turnAmountIntoArray function is used. 
    *       For each entry in the amounts array, the counter will be used 
    *       to generate the next token Id and to store that Id in an array.
    */
    function _turnTokenIdsIntoArray(Rarity rarity, uint16 amount) internal returns (uint256[] memory tokenIdArray) {
        tokenIdArray = new uint[](_turnAmountIntoArray(amount).length); 
        for (uint16 i = 0; i < _turnAmountIntoArray(amount).length;) { 
            uint256 currentTokenId = _countBasedOnRarity(rarity);
            tokenIdArray[i] = currentTokenId;
            _setAndEmitTokenInfo(currentTokenId, rarity);
            unchecked {
                i++;
            }  
        }
    }

    /**
    *@dev   This function reduces the amount of tokens left based on 
    *       the amount that is be minted per rarity. 
    *@param amount the amount of tokens minted.
    *@param rarity the rarity of the token minted. 
    */
    function _reducesTokensLeft(uint16 amount, Rarity rarity) internal {
        for(uint16 i; i < _turnAmountIntoArray(amount).length;) {
            if (rarity == Rarity.rarest) {
                rarestTokensLeft--;
            } else if (rarity == Rarity.rarer) {
                rarerTokensLeft--;
            } else {
                rareTokensLeft--;
            }
            unchecked {
                i++;
            }  
        }
    }

    /**
    *@dev   This function allows the minting of the remaining tokens when 
    *       the batch mint amount is higher than the amount that is left.
    *       It will reduce the given amount based on the number of tokens left.
    *@param amountGiven: the amount that is given for batch minting.
    */
    function _permittedAmount(uint16 amountGiven, string memory rarity, uint16 tokensLeft) internal view returns (uint16 reducedAmount) {
        if (amountGiven > tokensLeft) {
            reducedAmount = tokensLeft;
        } else if (amountGiven > tokensLeftToMintPerRarityPerBatch[rarity]) {
            reducedAmount = tokensLeftToMintPerRarityPerBatch[rarity];
        } else {
            reducedAmount = amountGiven;
        }
    }

    /**
    *@dev   general requirements for minting functions and refunds 
    *       if value send is higher than price * amount
    *@param amount the amount given for batch minting.
    *@param price the constant price to mint each NFT.
    *@param tokensLeft the number of tokens left per rarity.
    */
    function _mintRequires(uint16 amount, uint256 price, uint256 tokensLeft) internal {
        require(amount > 0);
        require(tokensLeft > 0, "This rarity is sold out");
        require(msg.value >= price * amount, "Not enough ETH sent");
    }
    
    /**
    *@dev   sends ether stored in the contract to admin.
    */
    function withdrawEther() external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }

    /**
    *@dev   This minting function allows the minting of Rarest tokenIds.
    *@param amount Every call will recursively increment the tokenId 
    *       depending on the amount of tokens the user wants to batch mint.
    *       These tokenIds are associated with the Mycelia rarity. 
    *       This function can be called for 1.5 ETH.
    */
    function rarestBatchMint(uint16 amount) public payable slowMintStatus("rarest") {
        _mintRequires(amount, PRICE_PER_RAREST_TOKEN, rarestTokensLeft);
        
        _mintBatch(msg.sender, 
            _turnTokenIdsIntoArray(Rarity.rarest, _permittedAmount(amount, "rarest", rarestTokensLeft)), 
            _turnAmountIntoArray(_permittedAmount(amount, "rarest", rarestTokensLeft)), '');
        
        _reducesTokensLeft(_permittedAmount(amount, "rarest", rarestTokensLeft), Rarity.rarest);
        
        tokensLeftToMintPerRarityPerBatch["rarest"] = tokensLeftToMintPerRarityPerBatch["rarest"] - amount;
    }

    /**
    *@dev   This minting function allows the minting of Rarer tokenIds.
    *@param amount Every call will recursively increment the tokenId 
    *       depending on the amount of tokens the user wants to batch mint.
    *       These tokenIds are associated with the Diamond rarity. 
    *       This function can be called for 0.5 ETH.
    */
    function rarerBatchMint(uint16 amount) public payable slowMintStatus("rarer") {
        _mintRequires(amount, PRICE_PER_RARER_TOKEN, rarerTokensLeft);
        
        _mintBatch(msg.sender, 
            _turnTokenIdsIntoArray(Rarity.rarer, _permittedAmount(amount, "rarer", rarerTokensLeft)), 
            _turnAmountIntoArray(_permittedAmount(amount, "rarer", rarerTokensLeft)), '');
        
        _reducesTokensLeft(_permittedAmount(amount, "rarer", rarerTokensLeft), Rarity.rarer);
        
        tokensLeftToMintPerRarityPerBatch["rarer"] = tokensLeftToMintPerRarityPerBatch["rarer"] - amount;
    }

    /**
    *@dev   This minting function allows the minting of Rare tokenIds.
    *@param amount Every call will recursively increment the tokenId 
    *       depending on the amount of tokens the user wants to batch mint.
    *       These tokenIds are associated with the Silver rarity. 
    *       This function can be called for 0.1 ETH.
    */
    function rareBatchMint(uint16 amount) public payable slowMintStatus("rare") {
        _mintRequires(amount, PRICE_PER_RARE_TOKEN, rareTokensLeft);    
        
        _mintBatch(msg.sender, 
            _turnTokenIdsIntoArray(Rarity.rare, _permittedAmount(amount, "rare", rareTokensLeft)), 
            _turnAmountIntoArray(_permittedAmount(amount, "rare", rareTokensLeft)), '');
        
        _reducesTokensLeft(_permittedAmount(amount, "rare", rareTokensLeft), Rarity.rare);
        
        tokensLeftToMintPerRarityPerBatch["rare"] = tokensLeftToMintPerRarityPerBatch["rare"] - amount;
    }

    /**
    *@dev   This function sets the product status based on rarity upon mint. 
    *       rarities rarest and rare will be set to ready.
    *       Minted rarer tokens will be set to not ready.
    *@param tokenId the token Id of the token that is minted
    *@param rarity the rarity of the token that is minted.
    */
    function _initialProductStatusBasedOnRarity(uint256 tokenId, Rarity rarity) internal {
        if (rarity == Rarity.rare) {
            ProductStatusByTokenId[tokenId] = ProductStatus.ready;
        } else {
            ProductStatusByTokenId[tokenId] = ProductStatus.not_ready;
        }
    }

    /**
    *@dev   This function will switch the status of product deployment to ready. 
    *       If the token has not been redeemed and the product status is 
    *       not_ready the status will be set to ready.
    *       This can only be done for tokens of the Diamond/Rarer rarity.
    *@param tokenIdList is the array of token Ids that is used to change the 
    *       deployment status of a token launched using the Valorize Token Launcher
    */
    function switchProductStatusToReady(uint256[] memory tokenIdList) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for(uint256 i=0; i < tokenIdList.length;) {
            require(ProductStatusByTokenId[tokenIdList[i]] == ProductStatus.not_ready, "Status is already set to ready");
            ProductStatusByTokenId[tokenIdList[i]] = ProductStatus.ready;
            unchecked {
                i++;
            }            
        }
    }

    /**
    *@dev   This function will switch the status of product deployment to redeemed. 
    *       If the token has been redeemed and the product status is 
    *       ready the status will be set to redeemed.
    *       This can be done for all rarities.
    *@param tokenIdList is the array of token Ids that is used to change the 
    *       deployment status of a token launched using the Valorize Token Launcher
    */
    function switchProductStatusToRedeemed(uint256[] memory tokenIdList) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for(uint256 i=0; i < tokenIdList.length;) {
            require(ProductStatusByTokenId[tokenIdList[i]] == ProductStatus.ready, "Token is not ready");
            ProductStatusByTokenId[tokenIdList[i]] = ProductStatus.redeemed;
            unchecked {
                i++;
            }
        }
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
    *@dev   This function updates the royalty receiving address
    *@param newReceiver is the new address that replaces the previous address
    */
    function updateRoyaltyReceiver(address newReceiver) external onlyRole(ARTIST_ROLE) {
        artistAddress = newReceiver;
    }

    /**
    *@dev This function sets the amount of tokenIds that can be minted per rarity
    *@param amount given amount of tokenIds that can be minted
    *@param rarity the rarity of the NFTs that will be minted
    */
    function setTokensToMintPerRarity(uint16 amount, string memory rarity) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint16) {
        return super._setTokensToMintPerRarity(amount, rarity);
    }   


    /**
    * @dev  Information about the royalty is returned when provided with token id and sale price. 
    *       Royalty information depends on token id: if token id is smaller than 12 than the artist address is given.
    *       If token id is bigger than 12 than the funds will be sent to the contract that distributes royalties.
    * @param _tokenId is the tokenId of an NFT that has been sold on the NFT marketplace
    * @param _salePrice is the price of the sale of the given token id
    */
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view override returns (
        address,
        uint256 royaltyAmount
    ) {
        royaltyAmount = (_salePrice / 100) * 10;
        if (_tokenId <= startRarerTokenIdIndex) {
            return(artistAddress, royaltyAmount);
        } else {
            return(royaltyDistributorAddress, royaltyAmount); 
        }
    }    
}