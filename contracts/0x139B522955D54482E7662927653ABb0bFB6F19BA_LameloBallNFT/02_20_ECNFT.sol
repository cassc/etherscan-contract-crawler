//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.0 <0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";



contract ECNFT is ERC721, Ownable, Pausable {
    using Strings for uint256;
    using SafeMath for uint256;
    using SafeMath for uint16;

    // sale conditions
    uint256 public immutable sale_start;
    uint256 public sale_end;

    address public controller;
    address payable public creator_wallet;
    address payable public owner_wallet;
    uint256 public creator_fee_percentage;
    IERC721 public ec_contract_address;

    event SaleSet(uint256 start, uint256 end);
    event ControllerSet(address);
    event CreatorWallet(address);
    event OwnerWallet(address);

    event CARD_Ordered(
        uint256 indexed card_type,
        uint256 indexed tokenID,
        address buyer,
        uint256 price_paid
    );

    event Refund(
        address buyer,
        uint256 sent,
        uint256 purchased,
        uint256 refund
    );

    struct CardStructure {
        uint256 last_transfer;
    }
    mapping(uint256 => CardStructure) CardData;

    struct CardTypeStructure {
        string className;
        uint16 start;    // class starting serial
        uint16 end;      // class end serial
        uint16 sold;     // sold
        uint16 reserved; // class reserved count
        uint256 price;   // price
    }
    mapping(uint256 => CardTypeStructure) public CardType;
    mapping(uint256 => uint256) public CardTypePrice;

    uint256 public cardTypeCount = 0;

    bool public _initialised; // Contract is _initialised
    bool public _FuzeBlown;   // Set data folder lock.
    bool public _Evolved;     // Evolved trait

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _sale_start,
        uint256 _sale_end,
        address payable _owner_wallet,
        address payable _creator_wallet,
        uint256 _creator_fee,
        address _ec_contract_address
    ) ERC721(_name, _symbol) {
        require(
            _sale_start < _sale_end,
            "Construct: Sale End must be higher than Sale Start"
        );
        require(
            _owner_wallet != address(0),
            "Construct: Owner Wallet cannot be 0x"
        );
        require(
            _creator_wallet != address(0),
            "Construct: Creator Wallet cannot be 0x"
        );
        sale_start = _sale_start;
        sale_end = _sale_end;
        creator_wallet = _creator_wallet;
        owner_wallet = _owner_wallet;
        creator_fee_percentage = _creator_fee;

        ec_contract_address = IERC721(_ec_contract_address);

        emit SaleSet(_sale_start, _sale_end);
        emit CreatorWallet(_creator_wallet);
        emit OwnerWallet(_owner_wallet);
    }

    //// Setup methods
    // Card Related Ops
    function setNewCardType(
        string memory _className,
        uint16 _start,
        uint16 _end,
        uint16 _reserved,
        uint256 _price
    ) public onlyOwner notInitialised {

        require(_end > _start, "end must be larger than start");
        require(_end > _start + _reserved, "too many reserve cards allocated");

        // validate start index is higher than last end
        if (cardTypeCount > 0) {
            CardTypeStructure memory _localCard = CardType[cardTypeCount - 1];
            require(
                _start > _localCard.end,
                "NewCardType: start must be larger than previous end"
            );
        }

        CardType[cardTypeCount] = CardTypeStructure(
            _className,
            _start,
            _end,
            0,
            _reserved,
            _price
        );

        CardTypePrice[cardTypeCount] = _price;

        cardTypeCount++;
    }

    function retrieveSpecialCards(address _to) public onlyAllowed initialised {
        // card 1 -> auction contract
        _mint(_to, 1);
        
        // sale starts from id 2
        CardType[0].sold++;

        // card 498, 499, 500 -> random distribution contract
        _mint(_to, CardType[0].end);
        _mint(_to, CardType[0].end.sub(1));
        _mint(_to, CardType[0].end.sub(2));
    }

    /*
     * 
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override {
        require(transferAllowed(_from, _to), "Transfer not allowed while sale is in progress");
        CardData[_tokenId].last_transfer = getTimestamp();
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    function transferAllowed(address _from, address _to) public view returns(bool) {
        // to minimise gas cost in the long run check this first.
        if(getTimestamp() > sale_end) return true;

        // minting
        if(_from == address(0)) return true;

        // Requirement: Lock token transfers while sale is on.
        // owner and controller should be allowed to send or receive them.
        if(_from == owner() || _from == controller) return true;
        if(_to == owner() || _to == controller) return true;
           
        return false;
    }


    // ENTRY POINT 1/2 TO SALE CONTRACT
    function buyCard(uint256 _card_type)
        external
        payable
        initialised
        saleActive
        whenNotPaused
    {
        buyCardInternal(_card_type, 0);
    }


    // ENTRY POINT 2/2 TO SALE CONTRACT
    function buyCardWithDiscount(uint256 _card_type, uint256 _ec_token_id)
        external
        payable
        initialised
        saleActive
        whenNotPaused
    {
        buyCardInternal(_card_type, _ec_token_id);
    }

    function buyCardInternal(uint256 _card_type, uint256 _ec_token_id) internal {

        uint256 balance = msg.value;
        require( CardTypePrice[_card_type] > 0, "Invalid card type");

        uint256 card_remaining = getRemainingCardsOfType(_card_type);
        require(card_remaining > 0, "Sorry no cards of this type available");

        uint256 _discount = 0;
        if(_ec_token_id > 0) {
            _discount = getDiscountPercentage(_ec_token_id);
        }

        uint256 j = 0;
        for (j=0; j < 50; j++) {

            card_remaining = getRemainingCardsOfType(_card_type);
            uint256 nextId = getNextAvailableIdOfType(_card_type);
            uint256 cardPrice = getCardPrice(nextId, _card_type, _discount);

            if (balance < cardPrice) {
                if (j == 0) {
                    revert("Not enough sent");
                }

                splitFee(msg.value.sub(balance));
                payable(msg.sender).transfer(balance);
                emit Refund(msg.sender, msg.value, j, balance);
                return;
            }

            if(card_remaining > 0) {
                assignCard(msg.sender, _card_type);
                balance = balance.sub(cardPrice);
            } else {
                break;
            }
        }

        splitFee(msg.value.sub(balance));
        payable(msg.sender).transfer(balance);
        emit Refund(msg.sender, msg.value, j, balance);
    }

    function splitFee(uint256 _value) internal {
        uint256 creatorPart = _value.mul(creator_fee_percentage).div(100);
        uint256 ownerPart = _value.sub(creatorPart);
        creator_wallet.transfer(creatorPart);
        owner_wallet.transfer(ownerPart);
    }

    function assignCard(address _buyer, uint256 _card_type) internal {

        CardTypeStructure storage _thisCardType = CardType[_card_type];
        uint256 newCardId = _thisCardType.start.add(_thisCardType.sold);
        _mint(_buyer, newCardId);
        _thisCardType.sold++;

        emit CARD_Ordered(_card_type, newCardId, msg.sender, msg.value );
    }

    function getCardPrice(uint256 _TokenId, uint256 _card_type, uint256 _discount) public view initialised returns(uint256) {
        require(_card_type <= cardTypeCount, "Invalid card type");
        require(_discount < 1000, "Discount cannot be over 100%");

        uint256 cardPrice;
        // card type 0 has tiered pricing
        if(_card_type == 0 && _TokenId <= 500) {
            //   1 - 100 => 0
            // 101 - 200 => 1
            // 201 - 300 => 2
            // 301 - 400 => 3
            // 401 - 500 => 4
            uint256 tier = _TokenId.sub(1).div(100);
            uint256 basePrice = CardTypePrice[_card_type];
            uint256 tierIncrease = basePrice.div(10);
            cardPrice = basePrice.add( tier.mul(tierIncrease) );

        } else {
            cardPrice = CardTypePrice[_card_type];
        }
        
        if(_discount > 0) {
            cardPrice = cardPrice.sub( cardPrice.div(1000).mul(_discount));
        }
        return cardPrice;
    }

    function getDiscountPercentage(uint256 tokenId) public view initialised returns(uint256) {
        require(ec_contract_address.ownerOf(tokenId) == msg.sender, "Buyer not owner of provided token id");
        
        if(tokenId <= 100) {
            return 100;
        } 
        
        if (tokenId <= 1000) {
            return 50;
        }

        if (tokenId <= 10000) {
            return 25;
        }

        return 0;
    }


    function mintTheRest(uint256 _card_type, address target) external onlyAllowed {
        require(sale_is_over(), "not until it's over");
        require( CardTypePrice[_card_type] > 0, "Invalid card type");

        uint256 remaining = getRemainingCardsOfType(_card_type);
        uint256 toMint = 50;
        
        remaining = Math.min(remaining, toMint);
        require(remaining > 0, "none remaining of that type");
        for (uint16 j = 0; j < remaining; j++) {
            assignCard(target, _card_type);
        }
    }

    //// onlyAllowed Methods

    /* After finalization the images will be assigned to match the trait data
     * but due to onboarding more artists we will have a late assignment.
     * when it is proven OK we burn
     *
     * should be of the format ipfs://<hash>/path
     */
    function setDataFolder(string memory _baseURI) public onlyAllowed {
        require(!_FuzeBlown, "This data can no longer be changed");
        _setBaseURI(_baseURI);
    }

    function contractURI() public view returns (string memory) {
        string memory base = baseURI();
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, "contract.json"));
    }

    function burnDataFolder() external onlyAllowed {
        require(bytes(baseURI()).length > 10, "Data Folder length too short");
        _FuzeBlown = true;
    }

    function setEvolved() external onlyAllowed {
        _Evolved = true;
    }

    function setController(address _controller) public onlyOwner {
        controller = _controller;
        emit ControllerSet(_controller);
    }

    function setInitialised() public onlyOwner notInitialised {
        require(cardTypeCount > 0, "Contract needs at least one card type");
        _initialised = true;
    }

    function extendSaleBy(uint256 _seconds) external onlyAllowed {
        sale_end = sale_end.add(_seconds);
    }

    function stopSale() external onlyAllowed {
        sale_end = block.timestamp;
    }

    function pause() external onlyAllowed {
        _pause();
    }

    function unpause() external onlyAllowed {
        _unpause();
    }

    //// blackhole prevention methods / drain

    function drain() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function retrieveERC20(address _tracker, uint256 amount)
        external
        onlyOwner
    {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }

    //// Web3 helper methods

    function how_long_more(bool _end)
        public
        view
        returns (
            uint256 Days,
            uint256 Hours,
            uint256 Minutes,
            uint256 Seconds
        )
    {
        uint256 gap;
        if(_end) {
            require(getTimestamp() < sale_end, "Missed It");
            gap = sale_end - getTimestamp();
        } else {
            require(getTimestamp() < sale_start, "Missed It");
            gap = sale_start - getTimestamp();
        }
        Days = gap / (24 * 60 * 60);
        gap = gap % (24 * 60 * 60);
        Hours = gap / (60 * 60);
        gap = gap % (60 * 60);
        Minutes = gap / 60;
        Seconds = gap % 60;
        return (Days, Hours, Minutes, Seconds);
    }

    function getRemainingCardsOfType(uint256 _card_type) public view returns (uint256) {
        CardTypeStructure memory _localCard = CardType[_card_type];

        return (
            _localCard.end
                .add(1)
                .sub(_localCard.start)
                .sub(_localCard.reserved)
                .sub(_localCard.sold)
        );
    }

    function getNextAvailableIdOfType(uint256 _card_type) public view returns (uint256) {
        CardTypeStructure memory _localCard = CardType[_card_type];
        return (_localCard.start.add(_localCard.sold));
    }

    function is_sale_on() public view returns (bool) {
        if (sale_is_over()) return false;
        if (getTimestamp() < sale_start) return false;
        return true;
    }

    function sale_is_over() public view returns (bool) {
        return (getTimestamp() > sale_end);
    }

    function getTimestamp() public view virtual returns (uint256) {
        return block.timestamp;
    }

    function TokenExists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function getLastTransfer(uint256 tokenId) external view returns (uint256) {
        CardStructure storage _card = CardData[tokenId];
        return _card.last_transfer;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        // reformat to directory structure as below
        string memory folder = (tokenId % 100).toString();
        string memory file = tokenId.toString();
        string memory slash = "/";
        return
            string(abi.encodePacked(baseURI(), folder, slash, file, ".json"));
    }


    //// Modifiers

    modifier onlyAllowed() {
        require(
            msg.sender == owner() || msg.sender == controller,
            "Not Authorised"
        );
        _;
    }

    modifier saleActive() {
        require(is_sale_on(), "Sale must be on");
        _;
    }

    modifier notInitialised() {
        require(!_initialised, "Must not be initialised");
        _;
    }

    modifier initialised() {
        require(_initialised, "Must be initialised");
        _;
    }
}