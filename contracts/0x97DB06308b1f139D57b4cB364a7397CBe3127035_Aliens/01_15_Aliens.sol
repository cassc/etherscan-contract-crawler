//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MCV Aliens contract
 *
 * @notice Smart Contract provides ERC721 functionality with public and private sales options.
 */
contract Aliens is ERC721Enumerable, Ownable {
    // Use safeMath library for doing arithmetic with uint256 and uint8 numbers
    using SafeMath for uint256;
    using SafeMath for uint8;

    // max tokens for one airdrop transaction
    uint8 constant maxAirdrop = 100;

    // address to withdraw funds from contract
    address payable private withdrawAddress;

    // MCVAddress address of MCV smart contract
    address public MCVAddress;

    uint256 private airdropNonce;

    // price of a single token in wei
    uint256 public alienPrice;

    // maximum number of tokens that can be purchased on all Private sale
    uint8 public maxPurchasePrivate;

    // maximum number of tokens that can be purchased
    // in one transaction on Public sale
    uint8 public maxPurchase;

    // base uri for token metadata
    string private _baseTokenURI;

    // private sale current status - active or not
    bool private _privateSale;

    // public sale current status - active or not
    bool private _publicSale;

    // if minting freeze
    bool public _freeze;

    // if collection metadata freeze
    bool public _freezeMeta;

    // event that emits when private sale changes state
    event privateSaleState(bool active);

    // event that emits when public sale changes state
    event publicSaleState(bool active);

    // whitelisted addresses that can participate in the
    // private sale event and how many tokens could be minted for this address
    mapping(address => uint8) private _whiteList;

    /**
    * @dev contract constructor
    *
    * @param name is contract name
    * @param symbol is contract basic symbol
    * @param baseTokenURI is base (default) tokenURI with metadata
    * @param _withDrawAddress is address to withdraw funds from contract
    */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        address payable _withDrawAddress,
        address _MCVAddress
    ) ERC721(name,symbol) {
        _baseTokenURI = baseTokenURI;
        withdrawAddress = _withDrawAddress;
        MCVAddress = _MCVAddress;
    }

    /**
    * @dev set price for one Alien token
    *
    * @param price is a new price for Alien token
    */
    function setAlienPrice(uint256 price) public {
        alienPrice = price;
    }

    /**
    * @dev set maxPurchasePrivate value
    *
    * @param max is a new value for maxPurchasePrivate
    */
    function setMaxPurchasePrivate(uint8 max) public {
        maxPurchasePrivate = max;
    }

    /**
    * @dev set maxPurchase value
    *
    * @param max is a new value for maxPurchase
    */
    function setMaxPurchase(uint8 max) public {
        maxPurchase = max;
    }

    /**
    * @dev check if private sale is active now
    *
    * @return bool if private sale active
    */
    function isPrivateSaleActive() public view virtual returns (bool) {
        return _privateSale;
    }

    /**
    * @dev switch private sale state
    */
    function flipPrivateSaleState() external onlyOwner {
        _privateSale = !_privateSale;
        emit privateSaleState(_privateSale);
    }

    /**
    * @dev check if public sale is active now
    *
    * @return bool if public sale active
    */
    function isPublicSaleActive() public view virtual returns (bool) {
        return _publicSale;
    }

    /**
    * @dev switch public sale state
    */
    function flipPublicSaleState() external onlyOwner {
        _publicSale = !_publicSale;
        emit publicSaleState(_privateSale);
    }

    /**
    * @dev add ETH addresses to whitelist
    *
    * Requirements:
    * - private sale must be inactive
    *
    * @param addresses address[] array of ETH addresses that need to be whitelisted
    */
    function addWhitelistAddresses( address[] calldata addresses) external onlyOwner {
        require(!_privateSale, "Private sale is now running!!!");

        for (uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i] != address(0)) {
                _whiteList[addresses[i]] = maxPurchasePrivate;
            }
        }
    }

    /**
    * @dev remove ETH addresses from whitelist
    *
    * Requirements:
    * - private sale must be inactive
    *
    * @param addresses address[] array of ETH addresses that need to be removed from whitelist
    */
    function removeWhitelistAddresses(address[] calldata addresses) external onlyOwner {
        require(!_privateSale, "Private sale is now running!!!");

        for (uint256 i = 0; i < addresses.length; i++) {
            delete _whiteList[addresses[i]];
        }
    }

    /**
    * @dev check if address whitelisted
    *
    * @param _address address ETH address to check
    * @return bool whitelist status
    */
    function isWhitelisted(address _address) public view returns (bool) {
        return _whiteList[_address] > 0
        ? true
        : false;
    }

    /**
    * @dev freeze minting
    */
    function freezeMinting() external onlyOwner {
        _freeze = true;
    }

    /**
    * @dev freeze collection metadata
    */
    function freezeMetadata() external onlyOwner {
        _freezeMeta = true;
    }

    /**
    * @dev mint new Alien token to sender on private or public sale
    *
    * Mutual Requirements:
    * - sender should pay Alien price for each token
    * - all sale variable (maxPurchasePrivate, maxPurchase, alienPrice) must set and be greater than 0
    * - number of minted tokens should be greater than 0
    * - public or private sale should be activated
    *
    * Private Sale Requirements:
    * - number of minted tokens should be less than maxPurchasePrivate value
    * - sender can't hold more tokens than maxPurchasePrivate vaxwlue
    *
    * Public Sale Requirements:
    * - number of minted tokens should be less than maxPurchase value
    *
    * @param numberOfTokens is an amount of tokens to mint
    */
    function mint(uint8 numberOfTokens) public payable {
        require(maxPurchase > 0, "maxPurchase variable must be greater than 0");
        require(alienPrice > 0, "alienPrice variable must be greater than 0");
        require(numberOfTokens > 0, "Number of tokens cannot be lower than, or equal to 0!");
        require(_publicSale || _privateSale, "publicSale or privateSale must be active");
        require(alienPrice * numberOfTokens == msg.value, "Ether value sent is not correct!");
        require(!_freeze, "minting is freeze!");

        if (_privateSale) {
            require(maxPurchasePrivate > 0, "maxPurchasePrivate variable must be greater than 0");
            require(numberOfTokens <= maxPurchasePrivate, "Trying to mint too many tokens!");
            require(_whiteList[msg.sender] > 0, "Address not whitelisted ot sender private sale limit have reached!");
            require(numberOfTokens <=  _whiteList[msg.sender], "private sale limit have reached!");
            _whiteList[msg.sender] = uint8(_whiteList[msg.sender].sub(numberOfTokens));
        } else if (_publicSale) {
            require(numberOfTokens <= maxPurchase, "Trying to mint too many tokens!");
        } else {
            // just safety return
            return;
        }

        _mintTokens(msg.sender, numberOfTokens);
        payable(withdrawAddress).transfer(msg.value);
    }

    /**
    * @dev do airdrop to send Aliens tokens to all MCV holders
    *
    * @param numberOfTokens is an amount of tokens to send
    */
    function airdrop(uint8 numberOfTokens) external onlyOwner {
        require(numberOfTokens <= maxAirdrop, "maxAirdrop one tx limit have reached!");
        require(airdropNonce < IERC721Enumerable(MCVAddress).totalSupply(), "airdrop nonce should be less or equal to MCV total supply");
        require(!isPublicSaleActive() && !isPrivateSaleActive(), "public and private sales should be not active");

        for (uint8 i = 1; i <= numberOfTokens; i++) {
            _safeMint(IERC721Enumerable(MCVAddress).ownerOf(airdropNonce.add(1)), airdropNonce.add(1));
            airdropNonce = airdropNonce.add(1);
        }
    }

    /**
    * @dev mint new Alien tokens to given address
    *
    * @param to is address where to mint new token
    * @param numberOfTokens is an amount of tokens to mint
    */
    function _mintTokens(address to, uint8 numberOfTokens) private {
        for (uint8 i = 0; i < numberOfTokens; i++) {
            _safeMint(to, totalSupply().add(1) + 10000);
        }
    }

    /**
    * @dev set new baseURI for collection metadata
    * metadata should not be freeze
    *
    * @param _newURI is new baseURI for collection metadata
    */
    function setBaseURI(string memory _newURI) external onlyOwner {
        require(!_freezeMeta, "collection metadata freeze!");
        _baseTokenURI = _newURI;
    }

    /**
    * @dev get current collection metadata baseURI
    */
    function _baseURI() internal view override virtual returns (string memory) {
        return _baseTokenURI;
    }
}