//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SkyCrucible is Ownable, ERC721A, ReentrancyGuard {
    bool public MINT_AVAILABLE;
    string public NAME;
    string public SYMBOL;
    string public BASE_URI;
    uint256 public MAX_SUPPLY;
    uint256 public PRICE_PER_TOKEN_SET;
    uint256 public FREE_MINT_START;
    uint256 public FREE_MINT_END;
    uint256 public FREE_MINT_DIVISOR;
    uint8 public TOKEN_SET_QUANTITY;
    uint8 public MAX_PER_MINT_SET_QUANTITY;
    uint16 public FREE_MINTS_GIVEN;

    mapping(address => bool) public hasMintedFree;

    event NewMint(address minter, uint256 quantityOfSets);
    event MintOpened();
    event MintPaused();
    event MintSoldOut();

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        uint256 _maxSupply,
        uint256 _tokenSetPrice,
        uint8 _tokenSetQuantity,
        uint8 _maxPerMintSetQuantity,
        uint256 _freeMintStart,
        uint256 _freeMintEnd,
        uint256 _freeMintDivisor,
        bool _mintAvailable
    ) ERC721A(_name, _symbol) {
        NAME = _name;
        SYMBOL = _symbol;
        BASE_URI = _baseUri;
        MAX_SUPPLY = _maxSupply;
        PRICE_PER_TOKEN_SET = _tokenSetPrice;
        TOKEN_SET_QUANTITY = _tokenSetQuantity;
        MAX_PER_MINT_SET_QUANTITY = _maxPerMintSetQuantity;
        FREE_MINT_START = _freeMintStart;
        FREE_MINT_END = _freeMintEnd;
        FREE_MINT_DIVISOR = _freeMintDivisor;
        MINT_AVAILABLE = _mintAvailable;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mintedFree(address buyer) public view returns (bool) {
        return (hasMintedFree[buyer]);
    }

    function eligibleForFreeMint(address buyer) public view returns (bool) {
        return (activeFreeMintPeriod() &&
            !mintedFree(buyer) &&
            freeMintsAvailable() > 0);
    }

    function activeFreeMintPeriod() public view returns (bool) {
        uint256 currentTime = block.timestamp;

        return (currentTime >= FREE_MINT_START && currentTime < FREE_MINT_END);
    }

    function totalFreeMints() public view returns (uint256) {
        return (MAX_SUPPLY / FREE_MINT_DIVISOR);
    }

    function freeMintsAvailable() public view returns (uint256) {
        return (totalFreeMints() - FREE_MINTS_GIVEN);
    }

    function safeMint(uint256 quantity) external payable {
        require(MINT_AVAILABLE, "Minting is not currently available");

        require(
            quantity >= 1,
            "Invalid quantity. Quantity parameter must be greater than or equal to 1."
        );

        require(
            quantity <= MAX_PER_MINT_SET_QUANTITY,
            "Invalid quantity. Quantity parameter must be less than or equal to MAX_PER_MINT_SET_QUANTITY."
        );

        bool validNormalPrice = msg.value == (PRICE_PER_TOKEN_SET * quantity);
        bool validFreeMintPrice = msg.value ==
            (PRICE_PER_TOKEN_SET * (quantity - 1));

        require(
            (validNormalPrice || validFreeMintPrice),
            "Invalid ether call value provided for mint quantity. Expected quantity multiplied by PRICE_PER_TOKEN_SET."
        );

        safeMint(quantity * TOKEN_SET_QUANTITY, true);
    }

    function safeMint(uint256 _mintQuantity, bool _validMintRequest) private {
        safeMint(
            _mintQuantity,
            _validMintRequest,
            freeMintAttempt(_mintQuantity)
        );
    }

    function safeMint(
        uint256 _mintQuantity,
        bool,
        bool _freeMintAttempt
    ) private {
        if (_freeMintAttempt && eligibleForFreeMint(msg.sender)) {
            FREE_MINTS_GIVEN += 5;
            hasMintedFree[msg.sender] = true;
            _maxQuantityCheck(_mintQuantity, 5);
        } else if (_freeMintAttempt && !eligibleForFreeMint(msg.sender)) {
            require(false, "Sorry, you're not eligible for a free mint!");
        } else {
            _maxQuantityCheck(_mintQuantity, 0);
        }
    }

    function _maxQuantityCheck(uint256 _mintQuantity, uint256 _freeMintQuantity)
        private
    {
        uint256 mintTotal = _mintQuantity;

        if (totalSupply() + _mintQuantity > MAX_SUPPLY) {
            mintTotal = MAX_SUPPLY - totalSupply();
            uint256 paidForMints = (mintTotal - _freeMintQuantity);
            uint256 captureAmount = ((paidForMints / TOKEN_SET_QUANTITY) *
                PRICE_PER_TOKEN_SET);
            uint256 refund = msg.value - captureAmount;

            (bool success, ) = payable(msg.sender).call{value: refund}("");

            require(success, "Failed to send partial ether amount");
        }

        _safeMint(msg.sender, mintTotal);

        emit NewMint(msg.sender, (mintTotal / TOKEN_SET_QUANTITY));

        if (totalSupply() == MAX_SUPPLY) {
            emit MintSoldOut();
        }
    }

    function freeMintAttempt(uint256 _mintQuantity) private returns (bool) {
        return (msg.value ==
            PRICE_PER_TOKEN_SET * ((_mintQuantity / TOKEN_SET_QUANTITY) - 1));
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        BASE_URI = _baseUri;
    }

    function setFreeMintStart(uint256 _freeMintStart) public onlyOwner {
        FREE_MINT_START = _freeMintStart;
    }

    function setFreeMintEnd(uint256 _freeMintEnd) public onlyOwner {
        FREE_MINT_END = _freeMintEnd;
    }

    function setPricePerTokenSet(uint256 _pricePerTokenSet) public onlyOwner {
        PRICE_PER_TOKEN_SET = _pricePerTokenSet;
    }

    function setMintAvailable(bool _mintAvailable) public onlyOwner {
        MINT_AVAILABLE = _mintAvailable;

        if (_mintAvailable) {
            emit MintOpened();
        } else {
            emit MintPaused();
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function withdraw(address payee) public onlyOwner {
        uint256 balance = address(this).balance;

        payable(payee).transfer(balance);
    }
}