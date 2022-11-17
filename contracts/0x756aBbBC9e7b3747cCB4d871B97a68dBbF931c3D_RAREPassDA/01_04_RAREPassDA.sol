// SPDX-License-Identifer: MIT

/// @title RARE Pass DA
/// @notice contract to implement dutch auction mint functionality for the RARE Pass
/// @author transientlabs.xyz

pragma solidity 0.8.17;

import "Ownable.sol";
import "ReentrancyGuard.sol";

interface RAREPass {
    function mintExternal(address recipient) external returns(uint256);
    function totalSupply() external view returns(uint256);
}

contract RAREPassDA is Ownable, ReentrancyGuard {

    // state variables
    bool public saleOpen;
    bool private _auctionSet;
    address public payoutAddress;
    uint256 public mintAllowance;

    uint256 public maxSupply;
    uint256 public auctionSupply;

    uint256 public startingPrice;
    uint256 public endingPrice;
    uint256 public stepDuration;
    uint256 public stepSize;
    uint256 public numSteps;
    uint256 public startsAt;

    RAREPass public rareContract;

    mapping(address => uint256) private _numMinted;
    mapping(address => bool) private _ofacList;

    // events
    event Sale(address indexed contractAddress, uint256 indexed tokenId, uint256 indexed saleValueWei, address buyer);

    constructor(
        address payout,
        uint256 allowance,
        uint256 maxSupply_,
        uint256 auctionSupply_,
        address passContractAddress
    )
    Ownable()
    ReentrancyGuard()
    {   
        payoutAddress = payout;
        mintAllowance = allowance;
        maxSupply = maxSupply_;
        auctionSupply = auctionSupply_;
        rareContract = RAREPass(passContractAddress);
    }

    /// @notice function to add addresses to the OFAC disallow list
    /// @dev requires contract owner
    function addToOfacList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _ofacList[addresses[i]] = true;
        }
    }

    /// @notice function to set rare pass contract address
    /// @dev requires contract owner
    function setRarePassContract(address rarePass) external onlyOwner {
        rareContract = RAREPass(rarePass);
    }

    /// @notice funciton to set auction details
    /// @dev requires contract owner
    function setAuctionDetails(uint256 startPrice, uint256 endPrice, uint256 auctionDuration, uint256 numAuctionSteps) external onlyOwner {
        startingPrice = startPrice;
        endingPrice = endPrice;
        stepDuration = auctionDuration / numAuctionSteps;
        stepSize = (startPrice - endPrice) / (numAuctionSteps);
        numSteps = numAuctionSteps;
        _auctionSet = true;
    }

    /// @notice function to open the sale
    /// @dev requires contract owner
    function openSale() external onlyOwner {
        require(_auctionSet, "auction not set");
        startsAt = block.timestamp;
        saleOpen = true;
    }

    /// @notice function to close the sale
    /// @dev requires contract owner
    function closeSale() external onlyOwner {
        saleOpen = false;
    }

    /// @notice function to set mint allowance
    /// @dev requires contract owner
    /// @dev useful if the mint allowance needs to change
    function setMintAllowance(uint256 newMintAllowance) external onlyOwner {
        mintAllowance = newMintAllowance;
    }

    /// @notice function to set payout address
    /// @dev requires contract owner
    /// @dev useful if payout address need to change
    function setPayoutAddress(address newPayoutAddress) external onlyOwner {
        payoutAddress = newPayoutAddress;
    }

    /// @notice function to mint to a wallet
    /// @dev requires contract owner
    /// @dev mints number to a specified address
    function ownerMint(address[] calldata recipients) external onlyOwner {
        require(rareContract.totalSupply() + recipients.length <= maxSupply, "no supply left");
        for (uint256 i = 0; i < recipients.length; i++) {
            rareContract.mintExternal(recipients[i]);
        }
    }

    /// @notice function to mint a pass
    /// @dev implements reentrancy guard so only one nft can be purchased in a single tx
    function buy() external payable nonReentrant {
        require(!_ofacList[msg.sender] && !_ofacList[tx.origin], "user is on the OFAC disallow list");
        require(saleOpen, "sale not open");
        require(_numMinted[msg.sender] < mintAllowance, "sender cannot mint more");
        require(rareContract.totalSupply() < auctionSupply, "no supply left");

        uint256 price = getPrice();
        require(msg.value >= price, "not enough ether attached");

        _numMinted[msg.sender]++;
        uint256 tokenId = rareContract.mintExternal(msg.sender);

        uint256 refund = msg.value - price;
        if (refund > 0) {
            (bool refundSuccess, ) = msg.sender.call{value: refund}("");
            require(refundSuccess, "refund failed");
        }
        (bool payoutSuccess, ) = payoutAddress.call{value: price}("");
        require(payoutSuccess, "payment transfer failed");

        emit Sale(address(rareContract), tokenId, price, msg.sender);
    }

    /// @notice function to get number minted by address
    function getNumMinted(address user) external view returns(uint256) {
        return _numMinted[user];
    }

    /// @notice function to get mint price
    /// @dev requires sale to be open
    function getPrice() public view returns(uint256) {
        require(saleOpen, "sale not yet open");
        uint256 numStepsSinceStart = (block.timestamp - startsAt) / stepDuration;
        if (numStepsSinceStart >= numSteps) {
            return(endingPrice);
        }
        uint256 price = startingPrice - numStepsSinceStart * stepSize;
        if (price < endingPrice) {
            return(endingPrice);
        } else {
            return(price);
        }
    }
}