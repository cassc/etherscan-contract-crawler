// SPDX-License-Identifier: MIT
/*
 $$$$$$\                      $$$$$$$$\ $$\                     
$$  __$$\                     $$  _____|\__|                    
$$ /  $$ |$$$$$$$\   $$$$$$\  $$ |      $$\  $$$$$$\   $$$$$$\  
$$ |  $$ |$$  __$$\ $$  __$$\ $$$$$\    $$ |$$  __$$\ $$  __$$\ 
$$ |  $$ |$$ |  $$ |$$$$$$$$ |$$  __|   $$ |$$ |  \__|$$$$$$$$ |
$$ |  $$ |$$ |  $$ |$$   ____|$$ |      $$ |$$ |      $$   ____|
 $$$$$$  |$$ |  $$ |\$$$$$$$\ $$ |      $$ |$$ |      \$$$$$$$\ 
 \______/ \__|  \__| \_______|\__|      \__|\__|       \_______|                                             
                                                     
*/
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OneFireMarket is ERC721URIStorage, ReentrancyGuard {
    //counter for counting the number of tokenId's minted
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    //the commission OneFire earn's from every sale on the platform.
    uint256 commissionPercentage = 3;
    //this is the listing fee OneFire take's when minting an item.
    //NOTE: the listing fee is only taken when minting, when you are relisting no fee is taken & this may go to 0 in the future.
    uint256 listingPrice = 0;
    uint256 minbidincrement = 0.0078 ether; //min incr for a bid.
    address payable master; //address of the contract owner.

    //this is were all nft in the market is stored,
    //it's keeps track of every nft minted.
    mapping(uint256 => MarketItem) public idToMarketItem;

    //this is the structure of how every nft is stored in the mapping up there.
    struct MarketItem {
        uint256 tokenId; //the item token id.
        address payable artist; //the artist who created the item.
        address payable seller; //who put up the nft for sale.
        address payable maxBidder; //the highest bidder for this item.
        uint256 maxBid; //the highest bid for this item.
        uint256 price; //the price of the nft.
        bool sold; //checks if it's sold or not.
        bool listed; //checks if it's listed or not.
        bool offer; //checks if the item has offer.
        uint256 artistPercentage; //the peercentage each item over take's
        uint256 expiration; //when the auction will close/timeout.
        bool bid; //checks if there is a bid.
    }

    //this is event is logged whenever an item is minted.
    event MarketItemCreated(
        uint256 indexed tokenId,
        address artist,
        address seller,
        address maxBidder,
        uint256 maxBid,
        uint256 price,
        bool sold,
        bool listed
    );

    constructor() ERC721("OneFire", "Fire") {
        master = payable(msg.sender);
    }

    //Updates the listing price of the contract
    ///Only owner of this contract can call this function,
    ///this is the function to update the listing fee that the market takes for listing nft.
    function updateListingPrice(uint256 _listingPrice) public payable {
        require(master == msg.sender);
        listingPrice = _listingPrice;
    }

    //the minbidincrement is the minimum amount you can increase at a time of bid.
    ///Only the owner can call the function,
    ///this function is to update the min bid incr of the platform
    function updateMinbidincrement(uint256 _Minbidincrement) public payable {
        require(master == msg.sender);
        minbidincrement = _Minbidincrement;
    }

    //this is a function to get the current listing fee of the platform.
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    //this function updates the artist of any nft.
    function updateArtist(address newartist, uint256 tokenId) public payable {
        require(idToMarketItem[tokenId].artist == msg.sender);
        idToMarketItem[tokenId].artist = payable(newartist);
    }

    //this function updates the artist percentage of the any nft.
    function updateArtistPercent(uint256 _percent, uint256 tokenId)
        public
        payable
    {
        require(idToMarketItem[tokenId].artist == msg.sender);
        require(_percent < 11);
        idToMarketItem[tokenId].artistPercentage = _percent;
    }

    //this is a function to get the artist for any nft.
    function getArtist(uint256 tokenId) public view returns (address) {
        return idToMarketItem[tokenId].artist;
    }

    //this is a function to get the artist percent.
    function getArtistPercent(uint256 tokenId) public view returns (uint256) {
        return idToMarketItem[tokenId].artistPercentage;
    }

    //this is the function to mint a new nft on OneFire.
    ///You can decide to list the item as you mint or mint before listing it's up to you.
    function createToken(
        string memory tokenURI,
        uint256 price,
        bool listed,
        uint256 artistPercentage
    ) public payable returns (uint256) {
        _tokenIds.increment(); //increase's the total item minted by 1
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        //calls the creatmarketitm and passes the data to it.
        createMarketItem(newTokenId, price, listed, artistPercentage);
        //returns the tokenId of the newly minted nft.
        return newTokenId;
    }

    //grabs all the data from above function and then proceed with it.
    function createMarketItem(
        uint256 tokenId,
        uint256 price,
        bool listed,
        uint256 artistPercentage
    ) private nonReentrant {
        require(artistPercentage < 11); //require's that the percentage an artist take is not more than 10.
        require(price > 0 ether); //require's that you can list an nft for 0 ether.
        require(msg.value >= listingPrice); //require's the person who is minting to pay the listing fee to the platform.
        payable(master).transfer(msg.value); //send's listing fee to the contract owner.

        //checks if the msg.sender wants to list the nft or not,
        //if true it save's this to the mapping if not it save's the listed == false.
        if (listed == true) {
            idToMarketItem[tokenId] = MarketItem(
                tokenId,
                payable(msg.sender), //sets the the caller to the artist.
                payable(msg.sender), //sets the caller to the seller.
                payable(address(0)),
                0,
                price,
                false,
                listed,
                false,
                artistPercentage,
                0,
                false
            );
        } else if (listed == false) {
            idToMarketItem[tokenId] = MarketItem(
                tokenId,
                payable(msg.sender), //sets the the caller to the artist.
                payable(msg.sender), //sets the the caller to the seller.
                payable(address(0)),
                0,
                price,
                false,
                listed,
                false,
                artistPercentage,
                0,
                false
            );
        }

        //if an item is listed it emit this  if its not it emit the listed == false.
        if (listed == true) {
            _transfer(msg.sender, address(this), tokenId);
            emit MarketItemCreated(
                tokenId,
                msg.sender,
                msg.sender,
                address(0),
                0,
                price,
                false,
                listed
            );
        }

        if (listed == false) {
            emit MarketItemCreated(
                tokenId,
                msg.sender,
                msg.sender,
                address(0),
                0,
                price,
                false,
                listed
            );
        }
    }

    //this function is simple it simply allow's you to relist your owned asset/nft.
    ///the market doesn't charge anythin to relist an nft,
    ///when an nft is relisted it is automatically is put up for both auction an buy,
    ///after relisted anyone can place a bid or buy the item.
    function resellToken(uint256 tokenId, uint256 price)
        public
        payable
        nonReentrant
    {
        require(price > 0);
        require(ownerOf(tokenId) == msg.sender);
        address lastHightestBidder = idToMarketItem[tokenId].maxBidder;
        uint256 lastHighestBid = idToMarketItem[tokenId].maxBid;
        if (lastHighestBid != 0) {
            idToMarketItem[tokenId].maxBid = 0;
            idToMarketItem[tokenId].maxBidder = payable(address(0));
            idToMarketItem[tokenId].offer = false;
            payable(address(lastHightestBidder)).transfer(lastHighestBid);
        }
        idToMarketItem[tokenId].sold = false;
        idToMarketItem[tokenId].listed = true;
        idToMarketItem[tokenId].price = price;
        idToMarketItem[tokenId].seller = payable(msg.sender);
        _transfer(msg.sender, address(this), tokenId);
    }

    //this function allows you cancel a listed nft for sale/auction..
    ///only the seller of this token can call this function.
    function cancelSale(uint256 tokenId) public nonReentrant {
        //checks and make sure that there is no bid for this item.
        require(idToMarketItem[tokenId].bid != true);
        //checks if the owner is the caller.
        require(idToMarketItem[tokenId].seller == msg.sender);
        //make's sure the item is listed we don't people unlisting an item that is not on sale.
        require(ownerOf(tokenId) == payable(address(this)));
        //transfer the item from the escrow which is were it is heard back to the owner address
        _transfer(address(this), msg.sender, tokenId);
        //do some important change's on the id struct in the mapping.
        idToMarketItem[tokenId].sold = false;
        idToMarketItem[tokenId].listed = false;
    }

    //this is to buy an item listed for sale.
    /// You may buy this item with the value sent
    /// along with this transaction.
    function createMarketSale(uint256 tokenId) public payable nonReentrant {
        uint256 price = idToMarketItem[tokenId].price; //gets the nft price.
        uint256 artistPercentage = idToMarketItem[tokenId].artistPercentage; //artist percentage.
        address seller = idToMarketItem[tokenId].seller; //gets the nft seller.
        address artist = idToMarketItem[tokenId].artist; //gets the artis who created the item.
        require(idToMarketItem[tokenId].bid != true); //make's sure there is no bid
        require(ownerOf(tokenId) == payable(address(this))); //make's sure the item is listed
        require(msg.sender != idToMarketItem[tokenId].seller); //make sure the seller does not buy his/her nft
        require(msg.value == price); // makes sure the buyer is paying the asking price
        require(idToMarketItem[tokenId].listed == true); //make's sure again that the item is listed before continuing.
        idToMarketItem[tokenId].sold = true; //set the sold to true
        idToMarketItem[tokenId].listed = false; //unlist iem.

        //this function splits the funds between parties.
        uint256 commissionAmount = (msg.value * commissionPercentage) / 100;
        uint256 artistAmount = (msg.value * artistPercentage) / 100;
        uint256 amountToTransferToTokenOwner = msg.value -
            commissionAmount -
            artistAmount;

        bool success;
        //sends 3% to the funds contract owner
        (success, ) = payable(master).call{value: commissionAmount}("");
        require(success);

        //sends the 90% of the funds to the seller
        (success, ) = seller.call{value: amountToTransferToTokenOwner}("");
        require(success);

        //send's 7% of the funds to the artist who created the nft.
        (success, ) = artist.call{value: artistAmount}("");
        require(success);

        //then before transfering the nft to the buyer.
        _transfer(address(this), msg.sender, tokenId);
    }

    //this is a function to placebid for an item
    ///the bid amount will be sent along side this transaction,
    ///the only way you will get your ETH back is if you get outbided,
    ///if you place a bid when the timer is 15min or less the timer resets itself back to 15min.
    function placebid(uint256 tokenId) public payable nonReentrant {
        require(idToMarketItem[tokenId].listed == true); //make's sure the item is listed for auction/sale.
        require(msg.value > idToMarketItem[tokenId].price + minbidincrement); //make's sure the bid is higher than the price.
        uint256 duration = 24 hours; //The duration set for the bid
        uint256 expiration = block.timestamp + duration; // Timeout
        if (idToMarketItem[tokenId].expiration > 0) {
            //checks if this is the first bid.
            require(block.timestamp <= idToMarketItem[tokenId].expiration);
        }
        uint256 durationend = 15 minutes; //The duration set for the bid
        uint256 expirationend = block.timestamp + durationend; // Timeout
        if (
            idToMarketItem[tokenId].expiration <= block.timestamp + durationend
        ) {
            //checks if the time is less than 15 min.
            idToMarketItem[tokenId].expiration = expirationend; //sets the timer back to 15mins.
        }
        require(idToMarketItem[tokenId].seller != msg.sender); //make's sure the seller is not trying to bid.
        require(msg.value > idToMarketItem[tokenId].maxBid + minbidincrement); //checks if the bid is higher than the last bid
        if (idToMarketItem[tokenId].bid == false) {
            //if this is the first bid then the timer will start and the auction will last for 24hours.
            idToMarketItem[tokenId].expiration = expiration;
        }
        address lastHightestBidder = idToMarketItem[tokenId].maxBidder;
        uint256 lastHighestBid = idToMarketItem[tokenId].maxBid;
        idToMarketItem[tokenId].bid = true;
        idToMarketItem[tokenId].maxBid = msg.value;
        idToMarketItem[tokenId].maxBidder = payable(msg.sender);
        if (lastHighestBid != 0) {
            //check if there is a bid is there is one the it transfer the bid back to its bidder.
            payable(address(lastHightestBidder)).transfer(lastHighestBid);
        }
    }

    //this is the function to finalize bid after the timer has expired or ended.
    /// By doing this you are finilizing the auction for this nft,
    ///alongside you are earning 2% of this sale,
    ///any bid you finalize you earn two percent.
    function finilizeBid(uint256 tokenId) public nonReentrant {
        require(idToMarketItem[tokenId].bid == true); //check if bid is true
        require(block.timestamp >= idToMarketItem[tokenId].expiration); //check if the bid as expired or not.
        uint256 finilizerPercentage = 2; //the percent to send to whoever finalize this bid
        uint256 artistPercentage = idToMarketItem[tokenId].artistPercentage; //artist percentage.
        uint256 maxBid = idToMarketItem[tokenId].maxBid; //get the highest bid
        address seller = idToMarketItem[tokenId].seller; //gets seller
        address artist = idToMarketItem[tokenId].artist; //gets artist
        address maxBidder = idToMarketItem[tokenId].maxBidder; //get highest bidder
        address finilizer = msg.sender; //whoever finalized the auction/bid
        //does some changes for this tokenId
        idToMarketItem[tokenId].maxBid = 0;
        idToMarketItem[tokenId].price = maxBid;
        idToMarketItem[tokenId].bid = false;
        idToMarketItem[tokenId].expiration = 0;
        uint256 commissionAmount = (maxBid * commissionPercentage) / 100;
        uint256 artistAmount = (maxBid * artistPercentage) / 100;
        uint256 finalAmount = (maxBid * finilizerPercentage) / 100;
        uint256 amountToTransferToTokenOwner = maxBid -
            commissionAmount -
            artistAmount -
            finalAmount;

        bool success;
        //sends 3% of the funds contract owner
        (success, ) = payable(master).call{value: commissionAmount}("");
        require(success);

        //sends the 90% of the funds to the seller
        (success, ) = seller.call{value: amountToTransferToTokenOwner}("");
        require(success);

        //send's 7% of the funds to the artist who created the nft.
        (success, ) = artist.call{value: artistAmount}("");
        require(success);
        //send's 2% of the sale to whoever finalized the deal/bid.
        (success, ) = finilizer.call{value: finalAmount}("");
        require(success);
        //transer the nft to the winner of the auction.
        _transfer(address(this), maxBidder, tokenId);
        //do some changes to the tokenid,
        idToMarketItem[tokenId].listed = false;
        idToMarketItem[tokenId].sold = true;
    }

    //this function is to create an offer
    ///this is a function to create an offer
    ///you can only make an offer if the item is unlisted if listed please place a bid instead.
    function createOffer(uint256 tokenId) public payable nonReentrant {
        require(idToMarketItem[tokenId].listed == false); //make's sure the item is not listed.
        require(ownerOf(tokenId) != msg.sender); //make's sure the only is not the one offering the price.
        require(msg.value > idToMarketItem[tokenId].maxBid); //your offer must be higher than the last one.
        address lastHightestBidder = idToMarketItem[tokenId].maxBidder; //last highset bidder/offerer.
        uint256 lastHighestBid = idToMarketItem[tokenId].maxBid; //last highest offer
        idToMarketItem[tokenId].maxBid = msg.value; //make''s this the new highest offer.
        idToMarketItem[tokenId].maxBidder = payable(msg.sender); //make's the msg.sender the new highest offerer
        if (lastHighestBid != 0) {
            payable(address(lastHightestBidder)).transfer(lastHighestBid);
        } //check's if there was an offer and send's the fund back to the respective owner.
        idToMarketItem[tokenId].offer = true; //set offer to true
    }

    //cancel an offer that was made.
    ///if there is an offer on this tokenid and you are the one who made it you can cancel it by calling this function.
    function cancelOffer(uint256 tokenId) public nonReentrant {
        require(idToMarketItem[tokenId].offer == true); //make's sure there is an offer.
        //sets some uint and address that will be used later
        uint256 maxBid = idToMarketItem[tokenId].maxBid;
        address maxBidder = idToMarketItem[tokenId].maxBidder;
        //make's sure the one who made the offer is the one calling this function.
        require(idToMarketItem[tokenId].maxBidder == msg.sender);
        idToMarketItem[tokenId].maxBid = 0; //set's highest offer to '0'
        idToMarketItem[tokenId].maxBidder = payable(address(0)); //set the offerer to '0' address.
        idToMarketItem[tokenId].offer = false; //set  offer to false.
        payable(address(maxBidder)).transfer(maxBid); //transfer money back to the offerer.
    }

    //function to accept offer
    ///if you own this tokenId you will be able to call this function and accept the offer on it..
    function acceptOffer(uint256 tokenId) public nonReentrant {
        require(idToMarketItem[tokenId].offer == true); //make's sure there is an offer
        require(ownerOf(tokenId) == msg.sender); //make's sure you are the owner.
        uint256 artistPercentage = idToMarketItem[tokenId].artistPercentage; //artist percentage.
        //set some uint and address to be used later.
        uint256 maxBid = idToMarketItem[tokenId].maxBid;
        address owner = ownerOf(tokenId);
        address artist = idToMarketItem[tokenId].artist;
        address maxBidder = idToMarketItem[tokenId].maxBidder;
        idToMarketItem[tokenId].maxBid = 0; //set highest bid to '0'.
        idToMarketItem[tokenId].price = maxBid; //set price to highest bid.
        idToMarketItem[tokenId].maxBidder = payable(address(0)); //make's  the highest bidder the '0' address.

        //set some uint to be used later.
        uint256 commissionAmount = (maxBid * commissionPercentage) / 100;
        uint256 artistAmount = (maxBid * artistPercentage) / 100;
        uint256 amountToTransferToTokenOwner = maxBid -
            commissionAmount -
            artistAmount;

        bool success;
        //sends 3% of the funds contract owner
        (success, ) = payable(master).call{value: commissionAmount}("");
        require(success);

        //sends 90% of the fund to the token owner
        (success, ) = owner.call{value: amountToTransferToTokenOwner}("");
        require(success);

        //sends 7% of the fund to the creator of the nft.
        (success, ) = artist.call{value: artistAmount}("");
        require(success);

        _transfer(msg.sender, maxBidder, tokenId); //transfer the ownership of the nft to the highest bidder

        idToMarketItem[tokenId].offer = false; //set offer to false.
    }

    /*
       @dev Allows the current owner to transfer control of the contract to a newOwner.
       @param _newOwner The address to transfer ownership to.
      */
    function transferOwnership(address _newOwner) public {
        require(msg.sender == master);
        master = payable(_newOwner);
    }

    ///get's the current number of tokens on the market
    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    //this gets all the current item on the OneFire market place
    ///returns a list of all the nft that a currently in the market.
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _tokenIds.current();
        uint256 unsoldItemCount = _tokenIds.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (
                idToMarketItem[i + 1].listed == true ||
                idToMarketItem[i + 1].listed == false ||
                idToMarketItem[i + 1].sold == true ||
                idToMarketItem[i + 1].sold == false
            ) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    ///this is to fetch the nft that any address holds that is from this contract/marketplace.
    function fetchHisNFTs(address _address)
        public
        view
        returns (MarketItem[] memory)
    {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                ownerOf(i + 1) == address(_address) ||
                idToMarketItem[i + 1].maxBidder == address(_address)
            ) {
                itemCount += 1;
            } else if (
                idToMarketItem[i + 1].seller == address(_address) &&
                idToMarketItem[i + 1].sold == false &&
                idToMarketItem[i + 1].listed == true
            ) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                ownerOf(i + 1) == address(_address) ||
                idToMarketItem[i + 1].maxBidder == address(_address)
            ) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            } else if (
                idToMarketItem[i + 1].seller == address(_address) &&
                idToMarketItem[i + 1].sold == false &&
                idToMarketItem[i + 1].listed == true
            ) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    ///this is to fetch a specific nft.
    function fetchTokenDetails(uint256 _token)
        public
        view
        returns (MarketItem[] memory)
    {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].tokenId == _token) {
                itemCount += 1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].tokenId == _token) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    ///this function enables admin to change the url of any token
    function setUserUrl(uint256 tokenId, string memory Url_) public {
        require(msg.sender == master);
        _setTokenURI(tokenId, Url_);
    }
}