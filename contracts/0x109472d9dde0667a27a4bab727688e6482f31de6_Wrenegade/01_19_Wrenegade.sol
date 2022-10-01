// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/************************************************************
 * @title: Wrenegade                                         *
 * @author: HamEvs.eth                                       *
 ************************************************************/

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Authorized.sol";

contract Wrenegade is Authorized, ERC1155Supply, PaymentSplitter {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private counter;

    string public name = "Wrenegade";
    string public symbol = "WREN";

    string private baseUri;
    string private endUri;

    uint256 public walletMaxMint = 3;

    mapping(uint256 => Token) private tokens;

    struct Token {
        uint256 price;
        uint256 supply;
        uint256 saleStartTime;
        mapping(address => uint256) minted;
    }

    address[] private payees = [
        0x879fB2d773bc9Ff4Db164f555A7608E8CEe68d1a,
        0xB091a7d9E9FD6d008084CCf22058De5525eE6cA2
    ];
    uint256[] private splits = [90, 10];

    constructor(string memory _baseUri)
        ERC1155("")
        PaymentSplitter(payees, splits)
    {
        setUri(_baseUri, "");
    }

    modifier tokenExists(uint256 _tokenID) {
        require(exists(_tokenID), "Token ID does not exist");
        _;
    }

    /**
    @dev Fallback function.
    */
    fallback() external payable {}

    /**
    @dev Adds a new token.
    */
    function addToken(
        uint256 _price,
        uint256 _supply,
        uint256 _saleStartTime
    ) public onlyAuthorized {
        Token storage t = tokens[counter.current()];
        t.price = _price;
        t.supply = _supply;
        t.saleStartTime = _saleStartTime;

        counter.increment();
    }

    /**
    @dev Edits an existing token.
    */
    function editToken(
        uint256 _tokenID,
        uint256 _price,
        uint256 _supply,
        uint256 _saleStartTime
    ) external onlyOwner tokenExists(_tokenID) {
        require(
            _supply >= totalSupply(_tokenID),
            "EditToken: New supply must be greater than current supply."
        );

        Token storage t = tokens[_tokenID];
        t.price = _price;
        t.supply = _supply;
        t.saleStartTime = _saleStartTime;
    }

    /**
    @dev Returns a token's information.
     */
    function getTokenInfo(uint256 _tokenID)
        external
        view
        tokenExists(_tokenID)
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            tokens[_tokenID].price,
            tokens[_tokenID].supply,
            tokens[_tokenID].saleStartTime
        );
    }

    /**
    @dev Sets token uri.
     */
    function setUri(string memory _baseUri, string memory _endUri)
        public
        onlyOwner
    {
        baseUri = _baseUri;
        endUri = _endUri;
    }

    /**
    @dev Set token sale start time (seconds since epoch).
     */
    function setTokenSaleStartTime(uint256 _tokenID, uint256 _saleStartTime)
        external
        onlyAuthorized
        tokenExists(_tokenID)
    {
        Token storage t = tokens[_tokenID];
        t.saleStartTime = _saleStartTime;
    }

    /**
    @dev Set token price.
     */
    function setTokenPrice(uint256 _tokenID, uint256 _price)
        external
        onlyOwner
        tokenExists(_tokenID)
    {
        Token storage t = tokens[_tokenID];
        t.price = _price;
    }

    /**
    @dev Set wallet max mint.
     */
    function setWalletMaxMint(uint256 _walletMaxMint) external onlyOwner {
        walletMaxMint = _walletMaxMint;
    }

    /**
    @dev Send token to specified address.
     */
    function airdrop(
        uint256 _tokenID,
        uint256 _quantity,
        address _address
    ) external tokenExists(_tokenID) onlyOwner {
        require(_tokenID > 0, "airdrop: invalid token Id");
        require(
            isSupplyValid(_tokenID, _quantity),
            "airdrop: token supply exceeded"
        );

        _mint(_address, _tokenID, _quantity, "");
    }

    /**
    @dev Handle token mints.
    */
    function mint(uint256 _tokenID, uint256 _quantity)
        external
        payable
        tokenExists(_tokenID)
    {
        require(_tokenID > 0, "mint: invalid token Id");
        require(isSaleOpen(_tokenID), "mint: sale is closed");
        require(
            isSupplyValid(_tokenID, _quantity),
            "mint: token supply exceeded"
        );
        require(
            msg.value >= tokens[_tokenID].price,
            "mint: incorrect ether sent"
        );
        require(
            tokens[_tokenID].minted[msg.sender] + _quantity <= walletMaxMint,
            "mint: maximum mints per wallet exceeded"
        );

        tokens[_tokenID].minted[msg.sender] += _quantity;
        _mint(msg.sender, _tokenID, _quantity, "");
    }

    /**
    @dev Handle token mints to another wallet.
    */
    function mintTo(
        uint256 _tokenID,
        uint256 _quantity,
        address _to
    ) external payable tokenExists(_tokenID) {
        require(_tokenID > 0, "mintTo: invalid token Id");
        require(isSaleOpen(_tokenID), "mintTo: sale is closed");
        require(
            isSupplyValid(_tokenID, _quantity),
            "mintTo: token supply exceeded"
        );
        require(
            msg.value >= tokens[_tokenID].price,
            "mintTo: incorrect ether sent"
        );
        require(
            tokens[_tokenID].minted[_to] + _quantity <= walletMaxMint,
            "mintTo: maximum mints per wallet exceeded"
        );

        tokens[_tokenID].minted[_to] += _quantity;
        _mint(_to, _tokenID, _quantity, "");
    }

    /**
    @dev Return whether mints are open for a certain tokenID.
    */
    function isSaleOpen(uint256 _tokenID)
        public
        view
        tokenExists(_tokenID)
        returns (bool)
    {
        if (totalSupply(_tokenID) >= tokens[_tokenID].supply) {
            return false;
        } else if (block.timestamp < tokens[_tokenID].saleStartTime) {
            return false;
        } else {
            return true;
        }
    }

    /**
    @dev Return whether supply is valid for certain token.
    */
    function isSupplyValid(uint256 _tokenID, uint256 _quantity)
        internal
        view
        tokenExists(_tokenID)
        returns (bool)
    {
        return totalSupply(_tokenID) + _quantity <= tokens[_tokenID].supply;
    }

    /**
    @dev Return number of tokenId minted by address.
    */
    function walletTokenMinted(uint256 _tokenID, address _address)
        public
        view
        tokenExists(_tokenID)
        returns (uint256)
    {
        return tokens[_tokenID].minted[_address];
    }

    /**
    @dev Return array of balences of given wallet address.
    */
    function walletOfOwner(address _address)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](counter.current());

        for (uint256 i; i < counter.current(); i++) {
            result[i] = balanceOf(_address, i);
        }

        return result;
    }

    /**
    @dev Return array of totalSupply for all tokens.
    */
    function totalSupplyAll() external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](counter.current());

        for (uint256 i; i < counter.current(); i++) {
            result[i] = totalSupply(i);
        }

        return result;
    }

    /**
    @dev Indicates whether a token exists with a given tokenID.
    */
    function exists(uint256 _tokenID) public view override returns (bool) {
        return counter.current() > _tokenID;
    }

    /**
    @dev Return URI for existing tokenID.
    */
    function uri(uint256 _tokenID)
        public
        view
        override
        tokenExists(_tokenID)
        returns (string memory)
    {
        require(
            block.timestamp >= tokens[_tokenID].saleStartTime,
            "uri: token URI not available"
        );
        return string(abi.encodePacked(baseUri, _tokenID.toString(), endUri));
    }

    /**
    @dev Secret diamond sauce.
    */
    function diamondMint() public {
        require(totalSupply(0) < tokens[0].supply, "diamond: supply invalid");
        require(counter.current() >= 32, "diamond: mint not sold out yet");

        for (uint256 i = 1; i < counter.current(); i++) {
            require(balanceOf(msg.sender, i) > 0, "diamond: invalid requisite");
        }
        tokens[0].minted[msg.sender] += 1;
        _mint(msg.sender, 0, 1, "");
    }
}