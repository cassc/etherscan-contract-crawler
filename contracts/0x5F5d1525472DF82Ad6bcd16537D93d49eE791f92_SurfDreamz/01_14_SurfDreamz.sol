// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SurfDreamz is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(address => bool) surfSpotAddresses;
    mapping(address => bool) freeTokenRedeemed;

    uint public reserve = 400;
    uint public presale_reserve = 100;
    uint public price = 0.08 ether;
    uint public presale_price = 0.06 ether;
    uint public max_per_mint = 5;
    uint public constant presale_max_per_mint = 3;

    string public baseTokenURI;

    bool public _paused = false;
    bool public _isPresale = false;

    event tokensMinted(address _from, uint[] _tokens);

    constructor(string memory baseURI) ERC721("Surf Dreamz", "SurfDreamz") {
        setBaseURI(baseURI);
    }

    // ** - MINTING - ** //
    function claim(uint quantity) public payable {
        uint totalMinted = _tokenIds.current();
        uint[] memory tokenIds = new uint[](quantity);
        uint presaleQuantityAtCost = quantity - 1;

        require(!_paused, "Sale paused");
        require(totalMinted + quantity <= reserve, "Not enough NFTs!");

        if (_isPresale) {
            require(
                msg.value == presale_price * presaleQuantityAtCost,
                "Insufficient funds to redeem"
            );
            require(verifyUser(msg.sender), "You do not own a Surf Spot");
            require(
                !freeTokenRedeemed[msg.sender],
                "You have already redeemed your presale dreamz"
            );

            require(
                quantity > 0 && quantity <= presale_max_per_mint,
                "Cannot mint specified number of dreamz"
            );
        } else {
            require(
                msg.value == price * quantity,
                "Insufficient funds to redeem"
            );
            require(
                balanceOf(msg.sender) + quantity <= max_per_mint,
                "You have already redeemed max number of dreamz"
            );
            require(
                quantity > 0 && quantity <= max_per_mint,
                "Cannot mint specified number of dreamz"
            );
        }

        for (uint i = 0; i < quantity; i++) {
            uint id = _mintNFT();
            tokenIds[i] = id;
        }

        if (_isPresale) {
            freeTokenRedeemed[msg.sender] = true;
        }
        emit tokensMinted(msg.sender, tokenIds);
    }

    function _mintNFT() private returns (uint id) {
        uint newTokenID = _tokenIds.current();
        _safeMint(msg.sender, newTokenID);

        id = newTokenID;
        _tokenIds.increment();

        return id;
    }

    function presaleMint() public isSurfSpotOwner(msg.sender) hasNotRedeemed(msg.sender) {
        uint newTokenID = _tokenIds.current();
        uint[] memory tokenIds = new uint[](1);

        require(!_paused, "Sale paused");
        require(_isPresale, "Presale over");
        require(newTokenID <= presale_reserve, "Not enough NFTs!");
        require(verifyUser(msg.sender), "You do not own a Surf Spot");
        require(
                !freeTokenRedeemed[msg.sender],
                "You have already redeemed your presale dreamz"
        );

        uint id = _mintNFT();
        tokenIds[0] = id;

        freeTokenRedeemed[msg.sender] = true;
        emit tokensMinted(msg.sender, tokenIds);
    }

    // ** - ADMIN - ** //
    function addUsers(address[] memory _addressesToSurfSpotlist) public onlyOwner {
        for (uint i = 0; i < _addressesToSurfSpotlist.length; i++) {
            surfSpotAddresses[_addressesToSurfSpotlist[i]] = true;
        }
    }

    function verifyUser(address _surfSpotAddress) public view returns (bool) {
        bool userIsSurfSpotOwner = surfSpotAddresses[_surfSpotAddress];
        return userIsSurfSpotOwner;
    }

    function hasToken() private view returns (uint balance) {
        balance = balanceOf(msg.sender);
    }

    function getTokens() public view returns (uint[] memory) {
        uint balance = hasToken();
        uint[] memory tokens = new uint[](balance);

        for (uint i = 0; i < balance; i++) {
            tokens[i] = tokenOfOwnerByIndex(msg.sender, i);
        }

        return tokens;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function reserveNFTs() public onlyOwner {
        uint totalMinted = _tokenIds.current();
        require((totalMinted + 20) < reserve, "Not enough NFTs!");

        for (uint i = 0; i < 20; i++) {
            _mintNFT();
        }
    }

    function getPresaleState() public view returns (bool isPresale) {
        isPresale = _isPresale;
        return isPresale;
    }

    function getPausedState() public view returns (bool isPaused) {
        isPaused = _paused;
        return isPaused;
    }

    function pauseSale() public onlyOwner {
        _paused = true;
    }

    function unpauseSale() public onlyOwner {
        _paused = false;
    }

    function preSaleStart() public onlyOwner {
        _isPresale = true;
    }

    function preSaleStop() public onlyOwner {
        _isPresale = false;
    }

    function getPrice(uint quantity)
        public
        view
        returns (uint totalPrice)
    {
        totalPrice = price * quantity;

        return totalPrice;
    }

    function getPresalePrice(uint quantity)
        public
        view
        returns (uint totalPrice)
    {
        uint presaleQuantityAtCost = quantity - 1;
        totalPrice = presale_price * presaleQuantityAtCost;

        return totalPrice;
    }

    function setPrice(uint _price) public onlyOwner {
        price = _price;
    }

    function setMaxLimit(uint _max_per_mint) public onlyOwner {
        max_per_mint = _max_per_mint;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

        // ** - MODIFIERS - ** //
    modifier isSurfSpotOwner(address _address) {
        require(surfSpotAddresses[_address], "You do not own a Surf Spot");
        _;
    }

    modifier hasNotRedeemed(address _address) {
        require(
            !freeTokenRedeemed[_address],
            "You have already redeemed your presale dreamz"
        );
        _;
    }
}