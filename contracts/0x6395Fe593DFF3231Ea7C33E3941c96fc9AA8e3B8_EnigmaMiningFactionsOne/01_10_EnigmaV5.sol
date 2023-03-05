// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// import "hardhat/console.sol";

contract EnigmaMiningFactionsOne is Ownable, ERC721A {
    // Interface imports
    AggregatorV3Interface internal priceFeed; // Chainlink Aggregator for USD-ETH conversion

    // Variable Declaration
    uint256 public MAX_NFTS = 10000;

    uint256 public MAX_MINT = 25;

    uint256 public presaleReserveCounter = 0;
    uint256 public presaleRedeemCounter = 0;
    uint256 public presaleMintedCounter = 0;
    uint256 public publicMintedCounter = 0;

    uint256 public acceptedChangePercentage = 2;
    uint256 public mintPrice = 125; // 125 USD for each NFT
    uint256 public presaleMintPrice = 112; // 112 USD for each NFT purchased under pre-sale
    uint256 public presaleReservePercent = 20;

    bool public presaleReserveActive = true;
    bool public presaleRedeemActive = true;
    bool public presaleMintActive = true;
    bool public publicMintActive = false;

    uint256 public startTime = 1677981600;

    enum TokenType {
        ETH,
        USDC
    }

    struct PresaleReservation {
        uint256 tokensReserved;
        TokenType currencyType;
    }

    string private _baseTokenURI = "";

    modifier noContracts() {
        require(msg.sender == tx.origin);
        _;
    }
    IERC20 public USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    mapping(address => PresaleReservation) public presaleReservations;

    // constructor
    constructor() ERC721A("EnigmaMiningFactionsOne", "EnigmaMiningFactionsOne") {
        priceFeed = AggregatorV3Interface(
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
        return presaleReservations[_reservationAddress].tokensReserved;
    }

    /*
     * Returns the reservation currency for given wallet
     */
    function getReservationCurrency(address _reservationAddress)
        public
        view
        returns (TokenType)
    {
        return presaleReservations[_reservationAddress].currencyType;
    }

    /**
     * Presale full Mint function
     * tokenType = 0 (Ethereum), 1 (USDC)
     */
    function presaleMint(uint256 _mints, TokenType _tokenType)
        external
        payable
        noContracts
    {
        require(
            startTime != 0 && startTime <= block.timestamp,
            "Sale is not open"
        );
        require(
            presaleMintActive == true,
            "Error: Presale mint isn't active or has ended"
        );
        require(_mints <= MAX_MINT, "Error: Exceeds Max per TXN");
        require(
            _mints + presaleReserveCounter + totalSupply() <= MAX_NFTS,
            "Error: Exceeds Max Allocation"
        );
        uint256 _mintPrice = _mints * presaleMintPrice;
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
            presaleMintedCounter += _mints;
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
                presaleMintedCounter += _mints;
            }
        }
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
            totalSupply() + _mints <= MAX_NFTS,
            "Error: Exceeds Max Allocation"
        );
        require(
            _mints + presaleReserveCounter + totalSupply() <= MAX_NFTS,
            "Error: Exceeds Max Public Sale Allocation"
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
     * Presale reservation function
     */
    function presaleReserve(uint256 _mints, TokenType _tokenType)
        external
        payable
        noContracts
    {
        require(
            startTime != 0 && startTime <= block.timestamp,
            "Sale is not open"
        );
        require(
            presaleReserveActive == true,
            "Error: Presale Reservation isn't active or has ended"
        );
        require(_mints <= MAX_MINT, "Error: Exceeds Max per TXN");
        require(
            _mints + presaleReserveCounter + totalSupply() <= MAX_NFTS,
            "Error: Exceeds Max Presale Allocation"
        );
        // require(
        //     presaleReservations[msg.sender].tokensReserved + _mints <= MAX_MINT,
        //     "Error: Exceeds maximum mint amount"
        // );
        if (presaleReservations[msg.sender].tokensReserved > 0) {
            if (_tokenType != presaleReservations[msg.sender].currencyType) {
                revert();
            }
        }
        uint256 _mintPrice = (_mints *
            presaleMintPrice *
            presaleReservePercent) / 100;
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
            presaleReservations[msg.sender].tokensReserved += _mints;
            presaleReservations[msg.sender].currencyType = _tokenType;
            presaleReserveCounter += _mints;
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
                presaleReservations[msg.sender].tokensReserved += _mints;
                presaleReservations[msg.sender].currencyType = _tokenType;
                presaleReserveCounter += _mints;
            }
        }
    }

    /**
     * Presale redeem function to pay 80%
     */
    function presaleRedeem(uint256 _mints, TokenType _tokenType)
        external
        payable
        noContracts
    {
        require(
            startTime != 0 && startTime <= block.timestamp,
            "Sale is not open"
        );
        uint256 availableMints = presaleReservations[msg.sender].tokensReserved;
        require(availableMints > 0, "Error: No reservations found");
        require(availableMints >= _mints, "Error: Not enough reservations");
        require(_mints > 0, "Error: Invalid value");
        require(
            presaleRedeemActive == true,
            "Error: Presale Disbursion isn't active or has ended"
        );
        require(_mints <= MAX_MINT, "Error: Exceeds Max per TXN");
        require(
            totalSupply() + _mints <= MAX_NFTS,
            "Error: Exceeds Max Allocation"
        );
        if (presaleReservations[msg.sender].tokensReserved > 0) {
            if (_tokenType != presaleReservations[msg.sender].currencyType) {
                revert();
            }
        }
        uint256 _mintPrice = (
            (_mints * presaleMintPrice * (100 - presaleReservePercent))
        ) / 100;
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
            presaleReservations[msg.sender].tokensReserved -= _mints;
            _mint(msg.sender, _mints);
            presaleRedeemCounter += _mints;
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
                presaleReservations[msg.sender].tokensReserved -= _mints;
                _mint(msg.sender, _mints);
                presaleRedeemCounter += _mints;
            }
        }
    }

    // Owner/Internal Functions

    /**
     * Presale rollover function
     * Will be used when presale reservations are not minted within a given time frame
     */
    function premintReservationRollover() external onlyOwner {
        require(presaleMintActive != true, "Error: Presale mint still active");
        require(
            presaleRedeemActive != true,
            "Error: Presale redeem still active"
        );
        presaleReserveCounter = 0;
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

    /**
     * Change presale Reservation Percent
     */
    function setPresaleReservationPercent(uint256 _presaleReservePercent)
        external
        onlyOwner
    {
        require(_presaleReservePercent > 0, "Error: Can't be 0");
        require(
            _presaleReservePercent != presaleReservePercent,
            "Error: Same value as before"
        );
        presaleReservePercent = _presaleReservePercent;
    }

    function setPresaleReserveStatus(bool _newStatus) external onlyOwner {
        presaleReserveActive = _newStatus;
    }

    function setPresaleRedeemStatus(bool _newStatus) external onlyOwner {
        presaleRedeemActive = _newStatus;
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

    function setPresaleReserveCounter(uint256 _presaleReserveCounter)
        external
        onlyOwner
    {
        presaleReserveCounter = _presaleReserveCounter;
    }

    function setPresaleRedeemCounter(uint256 _presaleReedemCounter)
        external
        onlyOwner
    {
        presaleRedeemCounter = _presaleReedemCounter;
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

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}