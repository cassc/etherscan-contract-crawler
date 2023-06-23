// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// import "hardhat/console.sol";

contract EnigmaMiningFactionsTwo is Ownable, ERC721A {
    // Interface imports
    AggregatorV3Interface internal priceFeed; // Chainlink Aggregator for USD-ETH conversion

    // Variable Declaration
    uint256 public MAX_NFTS = 4000;

    uint256 public MAX_MINT = 25;

    uint256 public presaleMintedCounter = 0;
    uint256 public publicMintedCounter = 0;

    uint256 public presaleReservedCounter = 0;

    uint256 public acceptedChangePercentage = 2;
    uint256 public mintPrice = 250; // 250 USD for each NFT
    uint256 public presaleMintPrice = 0; // 0 USD for each NFT already paid for

    bool public presaleMintActive = false;
    bool public publicMintActive = false;

    uint256 public startTime = 1677981600;

    enum TokenType {
        ETH,
        USDC
    }

    struct Whitelist {
        address addr;
        uint256 count;
    }

    string private _baseTokenURI = "";

    modifier noContracts() {
        require(msg.sender == tx.origin);
        _;
    }
    IERC20 public USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    mapping(address => uint256) public presaleReservations;

    // constructor
    constructor() ERC721A("EnigmaMiningFactionsTwo", "EMF2") {
        priceFeed = AggregatorV3Interface(
            // Goerli : 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
            // Mainnet : 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
    }

    // Public Functions

    /**
     * Returns the latest price based on inputted USD amount.
     */
    function getPriceRate(uint256 _amount) public view returns (uint256) {
        // prettier-ignore
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 adjust_price = uint256(price) * 1e10;
        uint256 usd = _amount * 1e18;
        uint256 rate = (usd * 1e18) / adjust_price;
        return rate;
    }

    /*
     * Returns the reservation amount left for each wallet
     */
    function getReservationCount(address _reservationAddress)
        public
        view
        returns (uint256)
    {
        return presaleReservations[_reservationAddress];
    }

    /**
     * Public Mint function
     * tokenType = 0 (Ethereum), 1 (USDC)
     */
    function publicMint(uint256 _mints, TokenType _tokenType)
        external
        payable
        noContracts
    {
        require(
            startTime != 0 && startTime <= block.timestamp,
            "Sale is not open"
        );
        require(
            publicMintActive == true,
            "Error: Public mint isn't active or has ended"
        );
        require(_mints <= MAX_MINT, "Error: Exceeds Max per TXN");
        require(
            totalSupply() + _mints + presaleReservedCounter <= MAX_NFTS,
            "Error: Exceeds Max Allocation"
        );
        
        uint256 _mintPrice = _mints * mintPrice;
        if (_tokenType == TokenType.ETH) {
            uint256 transactionPrice = getPriceRate(_mintPrice);
            uint256 priceFloor = (transactionPrice *
                (100 - acceptedChangePercentage)) / 100;
            uint256 priceCeil = (transactionPrice *
                (100 + acceptedChangePercentage)) / 100;
            require(
                msg.value >= priceFloor && msg.value <= priceCeil,
                "FD: Insufficient funds"
            );
            _mint(msg.sender, _mints);
            publicMintedCounter += _mints;
        } else {
            IERC20 token;
            if (_tokenType == TokenType.USDC) {
                token = USDC;

                // Would need to provide allowance before the transfer happens. Frontend will have to chain the two calls.
                require(
                    token.allowance(msg.sender, address(this)) >= _mintPrice,
                    "Error: Not enough allowance"
                );
                token.transferFrom(
                    msg.sender,
                    address(this),
                    _mintPrice * (10**6)
                );
                _mint(msg.sender, _mints);
                publicMintedCounter += _mints;
            }
        }
    }

    /**
     * Presale mint function to mint for already paid mints
     */
    function presaleMint(uint256 _mints)
        external
        payable
        noContracts
    {
        require(
            startTime != 0 && startTime <= block.timestamp,
            "Sale is not open"
        );
        uint256 availableMints = presaleReservations[msg.sender];
        require(availableMints > 0, "Error: No reservations found");
        require(availableMints >= _mints, "Error: Not enough reservations");
        require(_mints > 0, "Error: Invalid value");
        require(
            presaleMintActive == true,
            "Error: Presale Mint isn't active or has ended"
        );
        require(_mints <= MAX_MINT, "Error: Exceeds Max per TXN");
        require(
            totalSupply() + _mints <= MAX_NFTS,
            "Error: Exceeds Max Allocation"
        );
        presaleReservations[msg.sender] -= _mints;
        _mint(msg.sender, _mints);
        presaleMintedCounter += _mints;
        presaleReservedCounter -= _mints;
    }

    // Owner/Internal Functions

    /**
     * Whitelist for presale function
     * Adds address and count to whitelist presale
    */
    function whitelistForPresale(Whitelist[] memory users) external onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            if (presaleReservations[users[i].addr] > 0) {
                presaleReservations[users[i].addr] += users[i].count;
            } else {
                presaleReservations[users[i].addr] = users[i].count;
            }
            
            presaleReservedCounter += users[i].count;
        }
    }

    /**
     * Set reserved count for a particular address 
    */
    function setReservedCountForAddress(address _address, uint256 _count) external onlyOwner {
        if (presaleReservations[_address] > 0) {
            if (presaleReservations[_address] > _count) {
                presaleReservedCounter -= (presaleReservations[_address] - _count);
            } else {
                presaleReservedCounter += (_count - presaleReservations[_address]);
            }
        } 
        presaleReservations[_address] = _count;
    }

    /**
     * Set base URI
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * Treasury mint
     */
    function treasuryMint(uint256 _quantity, address _address)
        external
        onlyOwner
    {
        require(
            totalSupply() + _quantity <= MAX_NFTS,
            "Error: Cannot mint more than total supply"
        );
        _mint(_address, _quantity);
        publicMintedCounter += _quantity;
    }

    /**
     * Change mint price
     */
    function setSalePrice(uint256 _newMintPrice) external onlyOwner {
        mintPrice = _newMintPrice;
    }

    /**
     * Change pre-salemint price
     */
    function setPresalePrice(uint256 _newMintPrice) external onlyOwner {
        presaleMintPrice = _newMintPrice;
    }

    /**
     * Withdraw contract balances
     */
    function withdrawAll(address _wallet) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_wallet).transfer(balance);
        if (USDC.balanceOf(address(this)) > 0) {
            USDC.transfer(_wallet, USDC.balanceOf(address(this)));
        }
    }

    /**
     * Change USD-ETH conversion acceptance %
     */
    function setAcceptedChangePercentage(uint256 _newPercentage)
        external
        onlyOwner
    {
        require(_newPercentage > 0, "Error: Can't be 0");
        require(
            _newPercentage != acceptedChangePercentage,
            "Error: Same value as before"
        );
        acceptedChangePercentage = _newPercentage;
    }

    function setPresaleMintStatus(bool _newStatus) external onlyOwner {
        presaleMintActive = _newStatus;
    }

    function setPublicMintStatus(bool _newStatus) external onlyOwner {
        publicMintActive = _newStatus;
    }

    function setMaxNfts(uint256 maxNfts) external onlyOwner {
        MAX_NFTS = maxNfts;
    }

    function setMaxMints(uint256 maxMints) external onlyOwner {
        MAX_MINT = maxMints;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        startTime = _startTime;
    }

    function setPresaleMintedCounter(uint256 _presaleMintedCounter)
        external
        onlyOwner
    {
        presaleMintedCounter = _presaleMintedCounter;
    }

    function setPublicMintedCounter(uint256 _publicMintedCounter)
        external
        onlyOwner
    {
        publicMintedCounter = _publicMintedCounter;
    }

    function setPresaleReservedCounter(uint256 _presaleReservedCounter) external onlyOwner {
        presaleReservedCounter = _presaleReservedCounter;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}