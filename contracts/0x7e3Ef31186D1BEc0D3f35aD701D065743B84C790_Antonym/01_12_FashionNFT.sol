//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Antonym is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant WHITELIST_MAX = 4400;
    uint256 public constant RESERVE_MAX = 88; 
    uint256 public constant TOTAL_MAX = 8888; 
    uint256 public constant MAX_SALE_QUANTITY = 3; 
    uint256 public whitelistPrice = 0.185 ether; 
    uint256 public whitelistCount;
    uint256 public reserveCount;

    uint32 public startTime;
    bool public saleActive;
    bool public whitelistActive;
    bool private whitelistEnded;

    struct DAVariables {
        uint64 saleStartPrice;
        uint64 duration;
        uint64 interval;
        uint64 decreaseRate;
    }

    DAVariables public daVariables;

    mapping(address => uint256) public whitelists;

    string private baseURI;
    bool public revealed;

    address private paymentAddress;
    address private royaltyAddress;
    uint96 private royaltyBasisPoints = 810;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    constructor() ERC721A("Antonym", "ANTONYM") {}

    /**
     * @notice not locked modifier
     */
    modifier notEnded() {
        require(!whitelistEnded, "WHITELIST_ENDED");
        _;
    }

    /**
     * @notice mint from whitelist
     * @dev must occur before public sale
     */
    function mintWhitelist(uint256 _quantity) external payable notEnded {
        require(whitelistActive, "WHITELIST_INACTIVE");
        uint256 remaining = whitelists[msg.sender];
        require(whitelistCount + _quantity <= WHITELIST_MAX, "WHITELIST_MAXED");
        require(remaining != 0 && _quantity <= remaining, "UNAUTHORIZED");
        require(msg.value == whitelistPrice * _quantity, "INCORRECT_ETH");
        if (_quantity == remaining) {
            delete whitelists[msg.sender];
        } else {
            whitelists[msg.sender] = whitelists[msg.sender] - _quantity;
        }
        whitelistCount = whitelistCount + _quantity;
        _safeMint(msg.sender, _quantity);
    }

    /**
     * @notice buy from sale (dutch auction)
     * @dev must occur after whitelist sale
     */
    function buy(uint256 _quantity) external payable {
        require(saleActive, "SALE_INACTIVE");
        require(tx.origin == msg.sender, "NOT_EOA");
        require(
            _numberMinted(msg.sender) + _quantity <= MAX_SALE_QUANTITY,
            "QUANTITY_MAXED"
        );
        require(
            (totalSupply() - reserveCount) + _quantity <=
                TOTAL_MAX - RESERVE_MAX,
            "SALE_MAXED"
        );
        uint256 mintCost;
        DAVariables memory _daVariables = daVariables;
        if (block.timestamp - startTime >= _daVariables.duration) {
            mintCost = whitelistPrice * _quantity;
        } else {
            uint256 steps = (block.timestamp - startTime) /
                _daVariables.interval;
            mintCost =
                (daVariables.saleStartPrice -
                    (steps * _daVariables.decreaseRate)) *
                _quantity;
        }
        require(msg.value >= mintCost, "INSUFFICIENT_ETH");
        _mint(msg.sender, _quantity, "", true);
        if (msg.value > mintCost) {
            payable(msg.sender).transfer(msg.value - mintCost);
        }
    }

    /**
     * @notice release reserve
     */
    function releaseReserve(address _account, uint256 _quantity)
        external
        onlyOwner
    {
        require(_quantity > 0, "INVALID_QUANTITY");
        require(reserveCount + _quantity <= RESERVE_MAX, "RESERVE_MAXED");
        reserveCount = reserveCount + _quantity;
        _safeMint(_account, _quantity);
    }

    /**
     * @notice return number of tokens minted by owner
     */
    function saleMax() external view returns (uint256) {
        if (!whitelistEnded) {
            return TOTAL_MAX - RESERVE_MAX - WHITELIST_MAX;
        }
        return TOTAL_MAX - RESERVE_MAX - whitelistCount;
    }

    /**
     * @notice return number of tokens minted by owner
     */
    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    /**
     * @notice return current sale price
     */
    function getCurrentPrice() external view returns (uint256) {
        if (!saleActive) {
            return daVariables.saleStartPrice;
        }
        DAVariables memory _daVariables = daVariables;
        if (block.timestamp - startTime >= _daVariables.duration) {
            return whitelistPrice;
        } else {
            uint256 steps = (block.timestamp - startTime) /
                _daVariables.interval;
            return
                daVariables.saleStartPrice -
                (steps * _daVariables.decreaseRate);
        }
    }

    /**
     * @notice active whitelist
     */
    function activateWhitelist() external onlyOwner {
        !whitelistActive ? whitelistActive = true : whitelistActive = false;
    }

    /**
     * @notice active sale
     */
    function activateSale() external onlyOwner {
        require(daVariables.saleStartPrice != 0, "SALE_VARIABLES_NOT_SET");
        if (!whitelistEnded) whitelistEnded = true;
        if (whitelistActive) whitelistActive = false;
        if (startTime == 0) {
            startTime = uint32(block.timestamp);
        }
        !saleActive ? saleActive = true : saleActive = false;
    }

    /**
     * @notice set sale startTime
     */
    function setSaleVariables(
        uint32 _startTime,
        uint64 _saleStartPrice,
        uint64 _duration,
        uint64 _interval,
        uint64 _decreaseRate
    ) external onlyOwner {
        require(!saleActive);
        startTime = _startTime;
        daVariables = DAVariables({
            saleStartPrice: _saleStartPrice,
            duration: _duration,
            interval: _interval,
            decreaseRate: _decreaseRate
        });
    }

    /**
     * @notice set base URI
     */
    function setBaseURI(string calldata _baseURI, bool reveal) external onlyOwner {
        if (!revealed && reveal) revealed = reveal; 
        baseURI = _baseURI;
    }

    /**
     * @notice set payment address
     */
    function setPaymentAddress(address _paymentAddress) external onlyOwner {
        paymentAddress = _paymentAddress;
    }

    /**
     * @notice set royalty address
     */
    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
    }

    /**
     * @notice set royalty rate
     */
    function setRoyalty(uint96 _royaltyBasisPoints) external onlyOwner {
        royaltyBasisPoints = _royaltyBasisPoints;
    }

    /**
     * @notice set whitelist price
     */
    function setWhitelistPrice(uint256 _newPrice) external onlyOwner {
        whitelistPrice = _newPrice;
    }

    /**
     * @notice add addresses to whitelist
     */
    function setWhitelist(address[] calldata whitelisters, bool ogStatus)
        external
        onlyOwner
    {
        uint256 quantity = ogStatus ? 2 : 1;
        for (uint256 i; i < whitelisters.length; i++) {
            whitelists[whitelisters[i]] = quantity;
        }
    }

    /**
     * @notice token URI
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Cannot query non-existent token");
        if (revealed) {
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
        } else{
            return baseURI;
        }
    }

    /**
     * @notice royalty information
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(_tokenId), "Cannot query non-existent token");
        return (royaltyAddress, (_salePrice * royaltyBasisPoints) / 10000);
    }

    /**
     * @notice supports interface
     * @dev overridden for EIP2981 royalties
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A)
        returns (bool)
    {
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice transfer funds
     */
    function transferFunds() external onlyOwner {
        (bool success, ) = payable(paymentAddress).call{
            value: address(this).balance
        }("");
        require(success, "TRANSFER_FAILED");
    }
}