// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
import "@openzeppelin/contracts/utils/Counters.sol";  
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; 
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";  
import "./MarketplaceUtils.sol";   
import "./NFT.sol";   
 

contract Marketplace is ReentrancyGuardUpgradeable ,MarketplaceUtils  {

    using Counters for Counters.Counter;
    
    Counters.Counter private _marketSaleIds; 
    Counters.Counter private _buysCounters; 
    Counters.Counter private _saleAndAuctionCounters;   

    uint256 private _value; 
    
     

    // uint256 private _percentSpaceArt;  
    // address payable private _walletMarketplace;
    // address payable private _walletMarketplace1;
    // address payable private _walletMarketplace2;

    
    mapping (uint256 => MarketId) countToTokenId;  
    mapping (uint256 => MarketId) countToTokenIdSaleAuction;  
    mapping (address => mapping (uint256 => MarketItem)) idTokenToMarketItem; 
    mapping (address => mapping (uint256=> MarketSale[])) idTokenToMarketSale;   
    mapping (uint256 => OwnerCollaborators[]) idTokenToOwnerCollaborators;   
    mapping (uint256 => Bid[]) idMarketToBit; 
    
    // function initialize() initializer public {
    //    _walletMarketplace = payable(0x0C5b407D017b37B46133D7790c42e8142d8Ec48d);
    //    _walletMarketplace1 = payable(0xa4aD82F7a87e0eFBC6E39821b95c776d435DBCdA);
    //    _walletMarketplace2 = payable(0x8cF87436240b0DAa29f2d40A677Bc7cE4457C0e7);
    //    _percentSpaceArt = 10; 
    // }

   
    
    
    function createMarketItem(
        address contractCreator,
        uint256 tokenId,
        uint64 royalities,
        OwnerCollaborators[] memory owners
    ) public {
         
        IERC721 itemToken = IERC721(contractCreator); 
        require(itemToken.ownerOf(tokenId) == msg.sender,'No es el propietario');
        idTokenToMarketItem[contractCreator][tokenId] = MarketItem(
            msg.sender, 
            royalities
        ); 
        
        for (uint64 i = 0; i < owners.length; i++) {
            idTokenToOwnerCollaborators[tokenId].push(
                OwnerCollaborators(
                    payable(owners[i].owner),
                    owners[i].value
                )
            );
        }
    }
    function bid(address addressContract,uint256 tokenId) public payable nonReentrant{
        require(
            idTokenToMarketSale[addressContract][tokenId].length > 0,
            "No existe una subasta"
        );
        uint64 index = uint64(idTokenToMarketSale[addressContract][tokenId].length - 1);
        MarketSale memory sale = idTokenToMarketSale[addressContract][tokenId][index];
        require(
            sale.auction,
            "Este item no se encuentra en subasta"
        );
        require(
            !sale.ended,
            "Subasta ya se encuentra finalizada"
        );
        if(!sale.inited){
            require(
                msg.value > sale.price,
                "Lance ofrecido debe ser mayor al precio de venta."
            );
            idTokenToMarketSale[addressContract][tokenId][index].inited = true;
            idTokenToMarketSale[addressContract][tokenId][index].auctionEndTime = block.timestamp + sale.time;
        }else{
            require(
                block.timestamp <= sale.auctionEndTime,
                "Subasta esta finalizada"
            );
            require(
                msg.value > sale.highestBid,
                "Lance ofrecido debe ser mayor al ultimo lance aceptado."
            );
            if(sale.auctionEndTime - 900 <= block.timestamp && sale.gap > 0)
                idTokenToMarketSale[addressContract][tokenId][index].auctionEndTime = sale.auctionEndTime  + sale.gap;
        }

        if (sale.highestBid != 0) {
            payable(sale.highestBidder).transfer(sale.highestBid);
        }
        idTokenToMarketSale[addressContract][tokenId][index].highestBidder = msg.sender;
        idTokenToMarketSale[addressContract][tokenId][index].highestBid = uint64(msg.value);
        idMarketToBit[sale.id].push(
            Bid(
                payable(msg.sender),
                uint64(msg.value)
            )
        );
    }
    function buys(address addressContract,uint256 tokenId) public payable nonReentrant{
       
        require(idTokenToMarketSale[addressContract][tokenId].length > 0,"No existe una venta");
        uint64 index = uint64(idTokenToMarketSale[addressContract][tokenId].length - 1);
        MarketSale memory sale = idTokenToMarketSale[addressContract][tokenId][index];
        require(sale.sale,"Este item no se encuentra en venta");
        require(!sale.inited, "Subasta ya se encuentra Iniciada");
        require(msg.value >= sale.price,"Lance ofrecido debe ser mayor o igual al precio de venta.");
        idTokenToMarketSale[addressContract][tokenId][index].highestBidder = msg.sender;
        idTokenToMarketSale[addressContract][tokenId][index].highestBid = uint64(msg.value);
        idTokenToMarketSale[addressContract][tokenId][index].inited = true; 
        
        idMarketToBit[sale.id].push(
            Bid(
                payable(msg.sender),
                uint64(msg.value)
            )
        );
        
       endAuctionAndSale(addressContract,tokenId);
         
    }   
    function createMarketSale(
        address addressContract,
        uint256 tokenId,
        bool sale,
        bool auction,
        uint256 price,
        uint64 time,
        uint64 gap
    ) public  {
         
        IERC721 itemToken = IERC721(addressContract); 
        require(itemToken.ownerOf(tokenId) == msg.sender,'No es el propietario');
        require(price >= 0, "Price must be at least 1 wei");
        for (uint64 i = 0; i < idTokenToMarketSale[addressContract][tokenId].length; i++) {
            require((idTokenToMarketSale[addressContract][tokenId][i].ended),'Antes de crear una nueva subasta,deve finalizar la subasta anterior');
        }
        if(price == 0){
            sale =  false;
            auction = true;
        }
        _marketSaleIds.increment();
        uint64 itemAuctionId = uint64(_marketSaleIds.current());
        idTokenToMarketSale[addressContract][tokenId].push(MarketSale(
            itemAuctionId,
            idTokenToMarketSale[addressContract][tokenId].length <= 0,
            msg.sender,
            address(0), 
            time,
            gap,
            0,
            0,
            price,
            false,
            sale,
            auction,
            false
        ));
        uint count  = _saleAndAuctionCounters.current();
        countToTokenIdSaleAuction[count] = MarketId(
            addressContract,
            tokenId
        ); 
        _saleAndAuctionCounters.increment();        
    }
    function endAuctionAndSale(address addressContract,uint256 tokenId) private {
        IERC721 itemToken = IERC721(addressContract);
        uint _percentSpaceArt = 10;  
        uint64 index = uint64(idTokenToMarketSale[addressContract][tokenId].length - 1);
        MarketSale memory sale =  idTokenToMarketSale[addressContract][tokenId][index];
        
        uint valueRoyalities = sale.highestBid * idTokenToMarketItem[addressContract][tokenId].royalities / 100;
        uint valueSeller = sale.highestBid - valueRoyalities;
        uint valueMarketplace = valueSeller * _percentSpaceArt / 100;
        uint valueBeneficiary = valueSeller  - valueMarketplace;  
         _value += valueMarketplace;
        if(sale.primary){
            for (uint64 i = 0; i < uint64(idTokenToOwnerCollaborators[tokenId].length); i++) {
                uint valueCollaborator = valueBeneficiary *  idTokenToOwnerCollaborators[tokenId][i].value / 100;
                idTokenToOwnerCollaborators[tokenId][i].owner.transfer(valueCollaborator); 
                
                 
            }
        }else{
            if(valueRoyalities > 0)
                payable(idTokenToMarketItem[addressContract][tokenId].creator).transfer(valueRoyalities);
            payable(itemToken.ownerOf(tokenId)).transfer(valueBeneficiary); 
        }
      
           
        itemToken.transferFrom(itemToken.ownerOf(tokenId),sale.highestBidder,tokenId);
        
        idTokenToMarketSale[addressContract][tokenId][index].ended = true; 
        uint count  = _buysCounters.current();
        countToTokenId[count] = MarketId(
            addressContract,
            tokenId
        ); 
        _buysCounters.increment();
    }
    function withdrawTeam() public payable nonReentrant{
        payable(0x0C5b407D017b37B46133D7790c42e8142d8Ec48d).transfer(_value * 20 /  100); 
        payable(0xa4aD82F7a87e0eFBC6E39821b95c776d435DBCdA).transfer(_value * 30 /  100);
        payable(0x8cF87436240b0DAa29f2d40A677Bc7cE4457C0e7).transfer(_value * 50 /  100);
        _value = 0;
    }
    function finishAuction(address addressContract,uint256 tokenId) public payable nonReentrant{
        IERC721 itemToken = IERC721(addressContract);
        require(itemToken.ownerOf(tokenId) == msg.sender,'No es el propietario');
        require(
                idTokenToMarketSale[addressContract][tokenId].length > 0,
                "No existe una subasta"
            );
        uint64 index = uint64(idTokenToMarketSale[addressContract][tokenId].length - 1);
        MarketSale memory sale = idTokenToMarketSale[addressContract][tokenId][index];
        require(
            sale.auction,
            "Este item no se encuentra en subasta"
        );
        require(
            sale.inited,
            "Subasta no iniciada"
        );
        require(
            !sale.ended,
            "Subasta ya se encuentra finalizada"
        );
        endAuctionAndSale(addressContract,tokenId);
        
    } 
    function cancelAuction(address addressContract,uint256 tokenId) public payable nonReentrant{
        IERC721 itemToken = IERC721(addressContract);
        require(
            idTokenToMarketSale[addressContract][tokenId].length > 0,
            "No existe una subasta"
        );
         
        uint64 index = uint64(idTokenToMarketSale[addressContract][tokenId].length - 1);
        MarketSale memory sale = idTokenToMarketSale[addressContract][tokenId][index];
        require(
            sale.auction,
            "Este item no se encuentra en subasta"
        );
        require(
            sale.inited,
            "Subasta no iniciada"
        );
        require(
            !sale.ended,
            "Subasta ya se encuentra finalizada"
        );
       
        if(itemToken.ownerOf(tokenId) != msg.sender){
            require(
                block.timestamp > sale.auctionEndTime  + (24*60*60),
                "Anulacion no permitida, aun no pasaron las 24 horas"
            );
            require(msg.sender == sale.highestBidder, "Anulacion no permitida, No eres el ganador de la subasta");
          
        } 
        payable(idTokenToMarketSale[addressContract][tokenId][index].highestBidder).transfer(sale.highestBid);
        idTokenToMarketSale[addressContract][tokenId][index].highestBid = 0;
        idTokenToMarketSale[addressContract][tokenId][index].ended = true; 
    } 
    function lastMarketSaleOfTokenId(MarketId memory data) public view returns (MarketSale memory){
        uint64 index = uint64(idTokenToMarketSale[data.contractCreator][data.tokenId].length);
       
        if(index <= 0)
           return  MarketSale(
                0,
                false,
                address(0),
                address(0), 
                0,
                0,
                0,
                0,
                0,
                false,
                false,
                false,
                false
            );
        else
            index -= 1;
         
        return idTokenToMarketSale[data.contractCreator][data.tokenId][index];
    } 
    function getmarketItem(address addressContract,uint256 tokenId) public view returns (MarketItem memory){
        return idTokenToMarketItem[addressContract][tokenId];
    }
    function fetchMarketSaleBuysRecent(uint limit) public view returns (MarketSaleIdToken[] memory) {
        uint itemCount = _buysCounters.current();
        uint currentIndex = 0;
        MarketSaleIdToken[] memory items = new MarketSaleIdToken[](limit); 
        for (uint i = itemCount; i > 0 && limit > 0; i--) {
            MarketSale memory martkeSale =  lastMarketSaleOfTokenId(countToTokenId[i - 1]);
            items[currentIndex].marketId = countToTokenId[i -1];
            items[currentIndex].marketSale = martkeSale;
            currentIndex += 1;
            limit -= 1;
        }
        return items;
    }
    function fetchMarketSaleAuctionActive(
        uint limit
    ) public view returns (MarketSaleIdToken[] memory) {
        uint itemCount = _saleAndAuctionCounters.current();
        uint currentIndex = 0; 
        
        MarketSaleIdToken[] memory items = new MarketSaleIdToken[](limit);
        for (uint i = itemCount; i > 0 && limit > 0; i--) {
            MarketSale memory martkeSale =  lastMarketSaleOfTokenId(countToTokenIdSaleAuction[i - 1]);
            if (martkeSale.ended == false){
                items[currentIndex].marketId = countToTokenIdSaleAuction[i - 1];
                items[currentIndex].marketSale = martkeSale;
                currentIndex += 1;
            }
             
        }
        return items;
    }
}