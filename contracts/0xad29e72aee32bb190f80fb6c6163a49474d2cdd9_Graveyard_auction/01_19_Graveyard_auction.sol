// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/* open source library for ERC1155 standard interface */
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 

/* This contract issues tokens for several classes of spaceships with different rarity */
contract Graveyard_auction is Initializable, ERC1155Upgradeable, OwnableUpgradeable, ERC1155BurnableUpgradeable, ERC1155SupplyUpgradeable, UUPSUpgradeable { /* Contract inherits from ERC1155 spec */
    /* Declaring custom structs for holding individual bids (Bidlink) and sets of bids for each item (SubAuction) */

    struct BidLink {
        address payable bidder;
        uint256 value;
        uint256 bid_price;
    }

    struct SubAuction {
        mapping(uint => mapping(uint => BidLink)) bids;
        uint256 bidcount;
        uint256 initial_price;
        uint256 step;
        uint256 end_time;
        uint256 duration;
        uint256 current_price;
        uint256 round;
        bool initialized;
        bool ended;
    }

    struct Settings {
        uint256 initial_price;
        uint256 step;
        uint256 duration;
    }

    bool private wasDistributed;
    uint256 private auctionsCount;

    mapping(uint => SubAuction) public subauctions;
    string private baseURI;
    SubAuction private settings;

    function initialize() initializer public {
        wasDistributed = false;
        auctionsCount = 0;

        __Ownable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __UUPSUpgradeable_init();
    }

    function createAuctions(uint256 count, uint256 initial_price, uint256 step, uint256 duration) external onlyOwner {
        for(uint256 id = 1; id <= count; id++){
            _mint(owner(), id, 1, "");

            SubAuction storage subauction = subauctions[id];
            subauction.bidcount = 0;
            subauction.initial_price = initial_price;
            subauction.end_time = 0;
            subauction.duration = duration;
            subauction.step = step;
            subauction.round = 0;
            subauction.current_price = initial_price;
            subauction.initialized = true;
        }

        settings.initial_price = initial_price;
        settings.step = step;
        settings.duration = duration;

        auctionsCount = count;
    }

    function getAuction(uint256 id) public view returns(
        uint256 bidcount,
        uint256 step,
        uint256 end_time,
        uint256 current_price,
        uint256 round,
        bool initialized,
        bool ended
    ) {
        bidcount = subauctions[id].bidcount;
        step = subauctions[id].step;
        end_time = subauctions[id].end_time;
        current_price = subauctions[id].current_price;
        round = subauctions[id].round;
        initialized = subauctions[id].initialized;
        ended = subauctions[id].ended;
    }

    function getBid(uint256 auction_id, uint256 bid_id) public view returns(
        address bidder,
        uint256 bid_price
    ) {
        SubAuction storage auction = subauctions[auction_id];
        BidLink memory bidLink = auction.bids[auction.round][bid_id];

        bidder = bidLink.bidder;
        bid_price = bidLink.bid_price;
    }

    function distributeEndedAuctions(uint256 endedPrice) external onlyOwner {
        for(uint256 id = 1; id <= auctionsCount; id++){
            if(block.timestamp > subauctions[id].end_time && !subauctions[id].ended && subauctions[id].initialized && subauctions[id].bidcount > 0){
                BidLink memory current = subauctions[id].bids[subauctions[id].round][subauctions[id].bidcount];

                if(subauctions[id].current_price < endedPrice){
                    uint256 amount = current.value - 2300 * tx.gasprice;
                    current.value = 0;
                    current.bidder.transfer(amount);

                    subauctions[id].round = subauctions[id].round + 1;
                    subauctions[id].bidcount = 0;
                    subauctions[id].initial_price = settings.initial_price;
                    subauctions[id].step = settings.step;
                    subauctions[id].end_time = 0;
                    subauctions[id].duration = settings.duration;
                    subauctions[id].current_price = settings.current_price;
                    subauctions[id].initialized = true;
                    subauctions[id].ended = false;
                } else {
                    safeTransferFrom(owner(), current.bidder, id, 1, "");
                    subauctions[id].ended = true;
                }
            }
        }
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    event BidEvent(
        address bidder,
        uint256 auction_id,
        uint256 bid_price,
        uint256 time
    );

    function bid(uint256 id) payable public {
        require(subauctions[id].initialized, "Id doesn't exist");
        require(msg.value >= subauctions[id].current_price + subauctions[id].step, "Sent value below current price + step");

        /* if auction has already ended, throw error */
        require(subauctions[id].end_time == 0 || block.timestamp < subauctions[id].end_time, "Auction has ended");

        if(subauctions[id].bidcount > 0){
            uint256 amount = subauctions[id].bids[subauctions[id].round][subauctions[id].bidcount].value - 2300 * tx.gasprice;
            subauctions[id].bids[subauctions[id].round][subauctions[id].bidcount].value = 0;
            subauctions[id].bids[subauctions[id].round][subauctions[id].bidcount].bidder.transfer(amount);
        } else {
            subauctions[id].end_time = block.timestamp + subauctions[id].duration;
        }

        if(subauctions[id].end_time - block.timestamp < 60 * 15){
            subauctions[id].end_time = block.timestamp + 60 * 15;
        }

        BidLink memory new_bid = BidLink({
            bidder: payable(msg.sender), 
            value: msg.value,
            bid_price: msg.value
        });
        subauctions[id].bidcount++;
        subauctions[id].current_price = msg.value;
        subauctions[id].bids[subauctions[id].round][subauctions[id].bidcount] = new_bid;

        emit BidEvent(msg.sender, id, msg.value, block.timestamp);
    }

    function setBaseURI(string memory newuri) external onlyOwner {
        baseURI = newuri;
    }

    function uri(uint256 tokenId) public view override virtual returns (string memory){
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}