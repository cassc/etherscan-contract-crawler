// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract Calendar is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    address public _donation_wallet;
    uint256 public _listing_price = 0 ether;
    string private _unrevealed_URI;
    Counters.Counter public _token_id_counter;
    bool public _sale_is_active = false;
    mapping(address => mapping(uint256 => uint256)) public user_per_day;
    mapping(uint256 => uint256) public token_to_day;
    mapping(uint256 => Artist) private artist;

    uint256 public _startdate;
    uint8 public _maxday = 24;
    uint256 public _max_per_day = 1;

    struct Artist {
        string name;
        string uri;
    }

    constructor(uint256 startdate_, address donation_wallet_)
        ERC721("Wishes", "W22")
    {
        _startdate = startdate_;
        _donation_wallet = donation_wallet_;
    }

    /**
     *  Calculate the current day. Always rounded down. => +1
     */

    function calculateDay() public view returns (uint256 day) {
        if (block.timestamp < _startdate) {
            return 0;
        }
        return day = ((block.timestamp - _startdate) / 1 days) + 1;
    }

    /** Check if a token exists.
     *  token_to_day[tokenId_] check which day the token was minted on.
     *  day_to_uri[...] matches the day to the corresponding URI
     *  if the URI for the token is not set or the current day is less
     *  or equal the current day the unrevealed URI is returned.
     *
     *  The description is onchain and the image is returned one day after it minted.
     */
    function tokenURI(uint256 tokenId_)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId_);

        string memory _tokenURI = artist[token_to_day[tokenId_]].uri;
        string memory artist_name = artist[tokenId_].name;
        if (
            (bytes(_tokenURI).length == 0) ||
            (calculateDay() <= token_to_day[tokenId_])
        ) {
            _tokenURI = _unrevealed_URI;
            artist_name = "unknown";
        }

        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "Wishes 2022 #',
            tokenId_.toString(),
            '",',
            '"description":'
            '"',
            artist_name,
            '",',
            '"image": "',
            _tokenURI,
            '",',
            '"attributes": [{"trait_type": "Day", "value":"',
            token_to_day[tokenId_].toString(),
            '"},{"trait_type": "Artist", "value":"',
            artist_name,
            '"}]',
            "}"
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }

    /** To be able to mint, sale has to be active.
     *  The current block timestamp must not be below the 1st of December.
     *  The current day is calculated.
     *  The current day has to be smaller or equal than 24. December.
     *  User only allowed to mint 3 per day.
     *  The neede funds are calculated. (price * amount)
     *  Check if enough funds submitted.
     *  If more than the needed funds submitted, transfer them to donation wallet.
     *  -- all checks passed --
     *  Save the current day for future discount
     *  Set the token day (token_to_day) for all tokens to the current day.
     *  Mint tokens.
     */
    function mint(uint256 amount_) public payable {
        require(_sale_is_active, "Sale is not open");
        if (block.timestamp < _startdate) {
            revert("Mint not started, yet");
        }
        uint256 day = calculateDay();
        require(day <= _maxday, "Mint is over");
        require(
            user_per_day[msg.sender][day] + amount_ <= _max_per_day,
            "Amount restricted"
        );

        uint256 funds_needed = (_listing_price * amount_);

        require(msg.value >= funds_needed, "Not enough funds submitted");

        uint256 donation = msg.value - funds_needed;
        if (donation > 0) {
            payable(_donation_wallet).transfer(donation);
        }
        user_per_day[msg.sender][day] += amount_;
        for (uint i = 0; i < amount_; i++) {
            _token_id_counter.increment();
            uint256 id = _token_id_counter.current();
            token_to_day[id] = day;
            _safeMint(msg.sender, id);
        }
    }

    /**
     *  Function to set the revealed URI for a single day
     */
    function setDayReveal(
        uint256 day,
        string calldata newURI_,
        string calldata newName_
    ) public onlyOwner {
        artist[day].uri = newURI_;
        artist[day].name = newName_;
    }

    /**
     *  Function to set the start date
     */
    function setStartDate(uint256 startdate_) public onlyOwner {
        _startdate = startdate_;
    }

    /**
     *  Function to set the max day
     */
    function setMaxDay(uint8 maxday_) public onlyOwner {
        _maxday = maxday_;
    }

    /**
     *  Function to set the max amount per day
     */
    function setMaxPerDay(uint256 max_per_day_) public onlyOwner {
        _max_per_day = max_per_day_;
    }

    /**
     *  Function to set the revealed URI for all 24 days
     */
    function setDaysReveal(
        string[] calldata allPaths,
        string[] calldata allNames
    ) public onlyOwner {
        require(
            allPaths.length == _maxday && allNames.length == _maxday,
            "Set all URIs at once."
        );
        for (uint i = 0; i < _maxday; i++) {
            artist[i + 1].uri = allPaths[i];
            artist[i + 1].name = allNames[i];
        }
    }

    /**
     *  Function to set the unrevealed uri
     */
    function setUnrevealedUri(string memory unrevealed_URI_) public onlyOwner {
        _unrevealed_URI = unrevealed_URI_;
    }

    /**
     *  Function to set the listing price
     */
    function setListingPrice(uint256 listing_price_) public onlyOwner {
        _listing_price = listing_price_;
    }

    /**
     *  Function to flip the sale state
     */
    function flipSaleState() public onlyOwner {
        _sale_is_active = !_sale_is_active;
    }

    /**
     *  Function to update the donation wallet
     */
    function setDonationWallet(address donation_wallet_) public onlyOwner {
        _donation_wallet = donation_wallet_;
    }

    /**
     *  Function to have an easy access to all images after reveal.
     */
    function returnArtists() public view returns (Artist[] memory) {
        uint256 day = calculateDay();
        require(day > 0, "nothing to show, yet.");
        if (day > _maxday) {
            day = _maxday + 1;
        }
        Artist[] memory artistArray = new Artist[](day);
        artistArray[0].name = "unknown";
        artistArray[0].uri = _unrevealed_URI;

        for (uint i = 1; i < day; i++) {
            artistArray[i].name = artist[i].name;
            artistArray[i].uri = artist[i].uri;
        }
        return artistArray;
    }

    /**
     * Withdraw funds. No worries.
     * We only cover costs for deployment and contract interactions.
     * Additional funds will be sent to donation wallet.
     */

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}