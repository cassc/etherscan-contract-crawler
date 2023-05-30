// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ITuxERC20.sol";
import "./library/RankedSet.sol";
import "./library/AddressSet.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - Preminted initial supply
 *  - Ability for holders to burn (destroy) their tokens
 *  - No access control mechanism (for minting/pausing) and hence no governance
 *
 * This contract uses {ERC20Burnable} to include burn capabilities - head to
 * its documentation for details.
 *
 * _Available since v3.4._
 */
contract TuxERC20 is
    ITuxERC20,
    ERC20Burnable
{
    using RankedSet for RankedSet.Set;
    using AddressSet for AddressSet.Set;

    // Admin address for managing payout addresses
    address public owner;

    // Tux auctions address
    address public minter;

    // Currently featured auction
    uint256 public featured;

    // Timestamp of next featured auction
    uint256 public nextFeaturedTime;

    // Amount of time for featured auctions
    uint256 constant public featuredDuration = 3600; // 1 hour -> 3600 seconds

    // Amount of time between payouts
    uint256 constant public payoutsFrequency = 604800; // 7 days -> 604800 seconds

    // Timestamp of next payouts
    uint256 public nextPayoutsTime = block.timestamp + payoutsFrequency;

    // Payout amount to pinning and API services
    uint256 public payoutAmount = 100 * 10**18;

    // AddressSet of payout addresses to pinning and API services
    AddressSet.Set private _payoutAddresses;

    // RankedSet for queue of next featured auction
    RankedSet.Set private _featuredQueue;

    /**
     * @dev Mints 100,000 tokens and adds payout addresses.
     *
     * See {ERC20-constructor}.
     */
    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        owner = msg.sender;

        _mint(owner, 100000 * 10**18);

        _payoutAddresses.add(0x71C7656EC7ab88b098defB751B7401B5f6d8976F); // Etherscan
        // _payoutAddresses.add(0xInfura); // Infura
        // _payoutAddresses.add(0xPinata); // Pinata
        // _payoutAddresses.add(0xAlchemy); // Alchemy
        // _payoutAddresses.add(0xNFT.Storage); // nft.storage
    }

    /**
     * @dev Sets the minting address.
     */
    function setMinter(address minter_)
        external
    {
        require(
            msg.sender == owner,
            "Not owner address");

        minter = minter_;
    }

    /**
     * @dev Add a payout address, up to 10.
     */
    function addPayoutAddress(address payoutAddress)
        external
    {
        require(
            msg.sender == owner,
            "Not owner address");
        require(
            _payoutAddresses.length() < 10,
            "Maximum reached");

        _payoutAddresses.add(payoutAddress);
    }

    /**
     * @dev Remove a payout address.
     */
    function removePayoutAddress(address payoutAddress)
        external
    {
        require(
            msg.sender == owner,
            "Not owner address");

        _payoutAddresses.remove(payoutAddress);
    }

    /**
     * @dev Update payout amount up to 1000.
     */
    function updatePayoutAmount(uint256 amount)
        external
    {
        require(
            msg.sender == owner,
            "Not owner address");
        require(
            amount < 1000 * 10**18,
            "Amount too high");

        payoutAmount = amount;
    }

    /**
     * @dev Renounce ownership once payout addresses are added and the payout
     * amount gets settled.
     */
    function renounceOwnership()
        external
    {
        require(
            msg.sender == owner,
            "Not owner address");

        owner = address(0);
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must be the Tux auctions contract.
     */
    function mint(address to, uint256 amount)
        external
        virtual
        override
    {
        require(
            msg.sender == minter,
            "Not minter address");

        _mint(to, amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount)
        public
        override(ERC20Burnable)
    {
        _burn(msg.sender, amount);
    }

    /**
     * Add Tux auction to featured queue
     */
    function feature(uint256 auctionId, uint256 amount, address from)
        external
        virtual
        override
    {
        require(
            msg.sender == minter,
            "Not minter address");
        require(
            balanceOf(from) >= amount,
            "Not enough TUX");
        require(
            _featuredQueue.contains(auctionId) == false,
            "Already queued");
        require(
            amount >= 1 * 10**18,
            "Price too low");

        updateFeatured();

        _burn(from, amount);

        _featuredQueue.add(auctionId);
        _featuredQueue.rankScore(auctionId, amount);

        payouts();
    }

    function cancel(uint256 auctionId, address from)
        external
        virtual
        override
    {
        require(
            msg.sender == minter,
            "Not minter address");
        require(
            _featuredQueue.contains(auctionId) == true,
            "Not queued");

        _mint(from, _featuredQueue.scoreOf(auctionId));

        _featuredQueue.remove(auctionId);

        updateFeatured();
        payouts();
    }

    /**
     * Get featured items
     */
    function getFeatured(uint256 from, uint256 n)
        view
        public
        returns(uint256[] memory)
    {
        return _featuredQueue.valuesFromN(from, n);
    }

    /**
     * Get featured queue length
     */
    function getFeaturedLength()
        view
        public
        returns(uint256 length)
    {
        return _featuredQueue.length();
    }

    /**
     * Get if featured queue contains an auction ID
     */
    function getFeaturedContains(uint auctionId)
        view
        public
        returns(bool)
    {
        return _featuredQueue.contains(auctionId);
    }

    /**
     * Get next featured timestamp
     */
    function getNextFeaturedTime()
        view
        public
        returns(uint256 timestamp)
    {
        return nextFeaturedTime;
    }

    /**
     * Get featured price of queue item
     */
    function getFeaturedPrice(uint256 auctionId)
        view
        public
        returns(uint256 price)
    {
        return _featuredQueue.scoreOf(auctionId);
    }

    /**
     * Update featured queue
     */
    function updateFeatured()
        public
        override
    {
        if (block.timestamp < nextFeaturedTime || _featuredQueue.length() == 0) {
            return;
        }

        nextFeaturedTime = block.timestamp + featuredDuration;
        uint256 auctionId = _featuredQueue.head();
        _featuredQueue.remove(auctionId);
        featured = auctionId;

        _mint(msg.sender, 1 * 10**18);
    }

    /**
     * Mint weekly payouts to pinning and API services
     */
    function payouts()
        public
        override
    {
        if (block.timestamp < nextPayoutsTime) {
            return;
        }

        nextPayoutsTime = block.timestamp + payoutsFrequency;

        for (uint i = 0; i < _payoutAddresses.length(); i++) {
            _mint(_payoutAddresses.at(i), payoutAmount);
        }

        _mint(msg.sender, 1 * 10**18);
    }
}