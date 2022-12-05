//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";

contract Abstracto is
    ERC721A,
    Ownable,
    ReentrancyGuard,
    ERC2981,
    OperatorFilterer
{
    using Strings for uint256;

    uint256 public immutable maxSupply = 1000;
    uint256 public auctionStart;
    uint256 public maxMint = 20;
    uint256 public decrementInterval = 5 minutes;
    uint256 public decrementAmount = 0.2 ether;
    uint256 public decrementDuration = 5 minutes * 24;
    uint256 public startingPrice = 5 ether;
    uint256 public minimumPrice = 0.2 ether;
    bool public isActive;
    bool public operatorFilteringEnabled;

    string public baseURI;
    address public withdrawalAddressOne;
    address public withdrawalAddressTwo;

    constructor(
        string memory baseURI_,
        address _withdrawalAddressOne,
        address _withdrawalAddressTwo,
        address _royaltyReceiver,
        uint96 _royaltyEnumerator,
        address newOwner
    )
        ERC721A("Abstracto", "Abstracto") // Check the name
    {
        require(newOwner != address(0), "OWNER: ZERO_ADDRESS");
        baseURI = baseURI_;
        withdrawalAddressOne = _withdrawalAddressOne;
        withdrawalAddressTwo = _withdrawalAddressTwo;
        _setDefaultRoyalty(_royaltyReceiver, _royaltyEnumerator);
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        _transferOwnership(newOwner);
    }

    // --------- USER API -----------

    /**
     * @notice Mints a quantity of tokens to the caller
     * @param quantity - amount of tokens to mint
     */
    function mint(uint256 quantity) external payable nonReentrant {
        require(isActive, "SALE_NOT_STARTED");
        require(totalSupply() + quantity <= maxSupply, "MAX_SUPPLY_REACHED");
        require(
            _numberMinted(msg.sender) + quantity <= maxMint,
            "EXCEDEED_MAX_MINT"
        );
        require(msg.value >= quantity * _getPrice(), "PRICE: VALUE_TOO_LOW");

        _safeMint(msg.sender, quantity);
    }

    // --------- VIEW --------------

    /**
     * @notice Gets the current price of one token
     * @return - price of one token
     * @dev meant to be called by the frontend
     */
    function getCurrentPrice() public view returns (uint256) {
        return _getPrice();
    }

    /**
     * @notice Convenience function to fetch how much time is left until the next price drop
     * @return timeLeft - amount of time left until the next price drop
     * @dev meant to be called by the frontend
     */
    function getTimeLeft() public view returns (uint256 timeLeft) {
        timeLeft =
            decrementInterval -
            ((block.timestamp - auctionStart) % decrementInterval);
        return timeLeft;
    }

    /**
     * @notice Fetches the URI pointing to the token metadata
     * @param tokenId - the ID of the token
     * @return uri - the URI of the token metadata
     * @dev overriden from ERC721A. Reverts if token hasn't been minted
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory uri) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    // --------- INTERNAL -----------

    /**
     * @notice Gets the current price of an NFT
     * @return price - The price of one NFT
     * @dev used by the mint function to determine the correct price
     */
    function _getPrice() internal view returns (uint256 price) {
        uint256 decrement = decrementAmount *
            ((block.timestamp - auctionStart) / decrementInterval);

        if (decrement >= (startingPrice - minimumPrice)) {
            price = minimumPrice;
        } else {
            price = startingPrice - decrement;
        }

        return price;
    }

    // --------- RESTRICTED -----------

    /**
     * @notice Airdrops NFTs to an address
     * @param _user - address of the receiver
     * @param _quantity - amount of tokens to send
     * @dev only callable by owner
     */
    function airdrop(address _user, uint256 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= maxSupply, "MAX_SUPPLY_REACHED");

        _safeMint(_user, _quantity);
    }

    /**
     * @notice Repeats registration in case of an issue
     * @dev only callable by owner
     */
    function repeatRegistration() public onlyOwner {
        _registerForOperatorFiltering();
    }

    /**
     * @notice sets OS marketplace filtering enabled/disabled
     * @dev only callable by owner
     */
    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    /**
     * @notice Starts (or restarts) the auction
     * @dev only callable by owner
     * @dev If an auction has been stopped, this function will reset it to
     *      the initial auction parameters
     */
    function startAuction() external onlyOwner {
        require(!isActive, "ALREADY_STARTED");
        isActive = true;
        auctionStart = block.timestamp;
    }

    /**
     * @notice Stops the auction
     * @dev only callable by owner
     */
    function stopAuction() external onlyOwner {
        require(isActive, "ALREADY_INACTIVE");
        isActive = false;
    }

    /**
     * @notice Sets the baseURI for the metadata
     * @param baseURI_ - an IPFS or server link
     * @dev only callable by owner
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * @notice Sets the auction details
     * @param _maxPrice - The starting price of the auction
     * @param _minPrice - The minimum price of the auction
     * @param _decInterval - The amount of time between price drops
     * @param _decAmount - The reduction in price on each interval
     * @dev only callable by owner
     */
    function setDecrementFunction(
        uint256 _maxPrice,
        uint256 _minPrice,
        uint256 _decInterval,
        uint256 _decAmount
    ) external onlyOwner {
        require(_maxPrice >= _minPrice, "MAX_LESS_THAN_MIN");
        require(_decInterval > 0, "INTERVAL_TOO_LOW");
        uint256 priceDelta = _maxPrice - _minPrice;
        require(_decAmount <= priceDelta, "DEC_AMOUNT_TOO_HIGH");
        require(priceDelta % _decAmount == 0, "NOT_EVENLY_DIVISIBLE");

        decrementDuration = (priceDelta / _decAmount) * _decInterval;
        startingPrice = _maxPrice;
        minimumPrice = _minPrice;
        decrementAmount = _decAmount;
        decrementInterval = _decInterval;
    }

    /**
     * @notice Sets the maximum amount of NFTs an address can mint
     * @param _amount - the amount of NFTs to mint
     * @dev only callable by owner
     */
    function setMaxMint(uint256 _amount) external onlyOwner {
        require(_amount > 0, "AMOUNT_TOO_LOW");
        maxMint = _amount;
    }

    /**
     * @notice Sets the addresses where ETH balance will be withdrawn
     * @param first - address of first receiver
     * @param second - address of second receiver
     * @dev only callable by owner
     */
    function setWithdrawalAddresses(
        address first,
        address second
    ) external onlyOwner {
        withdrawalAddressOne = first;
        withdrawalAddressTwo = second;
    }

    /**
     * @notice Set the ERC2981 royalty information
     * @param _receiver - receiver of the royalties
     * @param _feeNumerator - royalty amount in basis points (0 - 10000 -> 0% - 100%)
     */
    function setDefaultRoyalty(
        address _receiver,
        uint96 _feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    /**
     * @notice Withdraw the contract ETH balance to the withdrawal address
     * @dev only callable by owner
     */
    function withdraw() external onlyOwner nonReentrant {
        uint256 shares = address(this).balance / 2;
        // Using call because transfer doesn't work with contract addresses, and call works with both accounts and contracts.
        (bool os1, ) = payable(withdrawalAddressOne).call{value: shares}("");
        (bool os2, ) = payable(withdrawalAddressTwo).call{value: shares}("");
        require(os1 && os2);
    }

    // --------- OVERRIDES -----------

    /**
     * @dev Override to support OS filtering
     */
    function approve(
        address operator,
        uint256 tokenId
    ) public payable virtual override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev Override to support OS filtering
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev Override to support OS filtering
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Override to support OS filtering
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev Override to support OS filtering
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable virtual override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function _operatorFilteringEnabled()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return operatorFilteringEnabled;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}