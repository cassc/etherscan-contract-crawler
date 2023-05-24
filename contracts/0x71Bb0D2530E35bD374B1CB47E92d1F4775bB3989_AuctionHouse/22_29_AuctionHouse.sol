// SPDX-License-Identifier: GPL-3.0

// The Wildxyz AuctionHouse.sol

// AuctionHouse.sol is a modified version of the original code from the
// NounsAuctionHouse.sol which is a modified version of Zora's AuctionHouse.sol:
// https://github.com/ourzora/auction-house/
// licensed under the GPL-3.0 license.

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

import './WildNFT.sol';
import './IAuctionHouse.sol';

interface SanctionsList {
    function isSanctioned(address addr) external view returns (bool);
}

interface IOasis {
    function balanceOf(address _address) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

interface IDelegationRegistry {
    /**
     * @notice Returns true if the address is delegated to act on your behalf for a token contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForContract(address delegate, address vault, address contract_) external view returns (bool);
}

contract AuctionHouse is IAuctionHouse, Pausable, ReentrancyGuard, Ownable {
    // auction variables (packed)
    uint256 public publicSaleMintMax; // max number of tokens per public sale mint

    uint256 public allowlistMintMax; // max number of tokens per allowlist mint
    uint256 public timeBuffer; // min amount of time left in an auction after last bid
    uint256 public minimumBid; // The minimum price accepted in an auction
    uint256 public minBidIncrement; // The minimum amount by which a bid must exceed the current highest bid
    uint256 public allowListPrice; // The allowlist price
    uint256 public duration; // 86400 == 1 day The duration of a single auction in seconds

    uint256 public raffleSupply; // max number of raffle winners
    uint256 public auctionSupply; // number of auction supply max of raffle ticket
    uint256 public allowlistSupply; // number allowlist supply
    uint256 public maxSupply; // max supply
    uint256 public promoSupply; // promo supply

    uint256 public oasisListStartDateTime; //oasislistStartDate
    uint256 public allowListStartDateTime; //allowListStartDateTime
    uint256 public allowListEndDateTime; //allowListEndDateTime
    uint256 public auctionStartDateTime; //==allowListEndDateTime;
    uint256 public auctionEndDateTime; //auctionEndDateTime

    uint256 public auctionExtentedTime;

    address payable public payee; // The address that receives funds from the auction
    address payable public admin; // for admin functions

    address public allowlistSigner; // The signer for the allowlist minting

    bool public auctionWinnersSet = false;
    bool public raffleWinnersSet = false;
    bool public auctionSettled = false;
    bool public settled = false;
    bool public publicSale = false;

    // the Oasis contract object
    IOasis public oasis;

    // NFT to auction
    WildNFT public nft;

    // OFAC sanctions list
    // mainnet: 0x40C57923924B5c5c5455c48D93317139ADDaC8fb
    // goerli: 0x5EBdB1188c0D54efB0a004c1d8737A922C1Ad8D2
    SanctionsList public sanctionsList;

    // Bids Struct
    struct Bid {
        address payable bidder; // The address of the bidder
        uint256 amount; // The amount of the bid
        bool minted; // has the bid been minted
        uint256 timestamp; // timestamp of the bid
        bool refunded; // refund difference between winning_bid and max_bid for winner; and all for losers
        bool winner; // is the bid the winner
        uint256 finalprice; // if won, what price won at
        bool rafflewinner; // only true if they were a raffle winner
    }

    // mapping of Bid structs
    mapping(address => Bid) public Bids;

    // allowList mapping 1=oasis;2=allowlist;0=not on list
    mapping(address => uint8) public allowList;
    mapping(address => uint256) public allowListMinted;

    mapping(uint256 => uint8) public oasisPassMints;

    /* MODIFIERS */

    // used by setVariablesBatch<X> methods
    mapping(uint64 => bool) private onlyOnceMapping;
    modifier onlyOnce(uint64 key) {
        require(onlyOnceMapping[key] == false);
        onlyOnceMapping[key] = true;
        _;
    }

    // Only allow the auction functions to be active when not paused
    modifier onlyUnpaused() {
        require(!paused(), 'AuctionHouse: paused');
        _;
    }

    // only allows admin to run function
    modifier onlyAdmin() {
        require(msg.sender == admin, 'AuctionHouse: only admin permitted.');
        _;
    }

    // Not on OFAC list
    modifier onlyUnsanctioned(address _to) {
        bool isToSanctioned = sanctionsList.isSanctioned(_to);
        require(!isToSanctioned, 'Blocked: OFAC sanctioned address');
        _;
    }

    /* CONSTRUCTOR */

    constructor(WildNFT _nft, address _payee, address _oasis, address _sanctions, address _allowlistSigner) {
        nft = _nft;
        payee = payable(_payee);
        oasis = IOasis(_oasis);
        sanctionsList = SanctionsList(_sanctions);

        allowlistSigner = _allowlistSigner;

        admin = payable(0x9DAF56fB5d08b1dad7e6A46e0d5E814F41d1b7F9);
    }

    /* INITIALIZER FUNCTIONS */

    function setVariablesBatch1(uint256 _allowlistMintMax, uint256 _timeBuffer, uint256 _minimumBid, uint256 _minBidIncrement, uint256 _allowListPrice, uint256 _duration, uint256 _publicSaleMintMax) public onlyOwner onlyOnce(1) {
        allowlistMintMax = _allowlistMintMax;
        timeBuffer = _timeBuffer;
        minimumBid = _minimumBid;
        minBidIncrement = _minBidIncrement;
        allowListPrice = _allowListPrice;
        duration = _duration;
        publicSaleMintMax = _publicSaleMintMax;
    }

    function setVariablesBatch2(uint256 _raffleSupply, uint256 _auctionSupply, uint256 _allowlistSupply, uint256 _maxSupply, uint256 _promoSupply, uint256 _oasisListStartDateTime, uint256 _allowListStartDateTime, uint256 _allowListEndDateTime, uint256 _auctionStartDateTime, uint256 _auctionEndDateTime) public onlyOwner onlyOnce(2) {
        raffleSupply = _raffleSupply;
        auctionSupply = _auctionSupply;
        allowlistSupply = _allowlistSupply;
        maxSupply = _maxSupply;
        promoSupply = _promoSupply;

        oasisListStartDateTime = _oasisListStartDateTime;
        allowListStartDateTime = _allowListStartDateTime;
        allowListEndDateTime = _allowListEndDateTime;
        auctionStartDateTime = _auctionStartDateTime;
        auctionEndDateTime = _auctionEndDateTime;
    }

    function setVariablesBatch3(address _payee, address _admin) public onlyOwner onlyOnce(3) {
        payee = payable(_payee);
        admin = payable(_admin);
    }

    /* OWNER FUNCTIONS */

    // set admin address;
    function setAdmin(address _admin) public onlyOwner {
        admin = payable(_admin);
    }

    // update payee for withdraw
    function setPayee(address payable _payee) public onlyOwner {
        payee = _payee;
    }

    // pause
    function pause() external override onlyOwner {
        _pause();
    }

    // unpause
    function unpause() external override onlyOwner {
        _unpause();
    }

    // withdraw
    function _withdraw() internal {
        require(auctionSettled == true && block.timestamp > auctionEndDateTime, 'Auction not settled||not ended.');
        (bool success, ) = payee.call{value: address(this).balance}('');
        require(success, 'Failed to send to payee.');
    }

    function withdraw() public onlyOwner {
        _withdraw();
    }

    function setRaffleWinners(address[] memory _raffleWinners) external onlyOwner {
        require(block.timestamp > auctionEndDateTime, 'Auction not over yet.');
        require(raffleWinnersSet == false, 'Raffle already settled');
        require(_raffleWinners.length <= raffleSupply, 'Incorrect number of winners');

        for (uint256 i = 0; i < _raffleWinners.length; i++) {
            Bid storage bid = Bids[_raffleWinners[i]];
            bid.winner = true;
            bid.finalprice = minimumBid;

            bid.rafflewinner = true;
        }

        raffleWinnersSet = true;
    }

    function setAuctionWinners(address[] memory _auctionWinners, uint256[] memory _prices) external onlyOwner {
        require(block.timestamp > auctionEndDateTime, 'Auction not over yet.');
        require(auctionWinnersSet == false, 'Auction already settled');

        for (uint256 i = 0; i < _auctionWinners.length; i++) {
            Bid storage bid = Bids[_auctionWinners[i]];
            bid.winner = true;
            bid.finalprice = _prices[i];

            bid.rafflewinner = false;
        }

        auctionWinnersSet = true;
    }

    /**
     * Settle an auction.
     */
    function settleBidder(address[] memory _bidders) external onlyOwner nonReentrant {
        require(block.timestamp > auctionEndDateTime, "Auction hasn't ended.");
        require(auctionWinnersSet == true && raffleWinnersSet == true, 'Auction winners not set');

        for (uint256 i = 0; i < _bidders.length; i++) {
            address bidder = _bidders[i];
            Bid storage bid = Bids[bidder];

            if (bid.winner == true && bid.minted == false && bid.refunded == false) {
                // if winner, mint and refunde diff if any, update Bids
                uint256 difference = bid.amount - bid.finalprice;
                if (difference > 0) {
                    (bool success, ) = bidder.call{value: difference}('');
                    require(success, 'Failed to refund difference to winner.');
                }

                uint256 tokenId = nft.mint(bidder);

                // different mint type for raffle winner
                if (bid.rafflewinner == true) {
                    emit TokenMint(bidder, tokenId, MintType.Raffle, false, address(0), false, 0);
                } else {
                    emit TokenMint(bidder, tokenId, MintType.Auction, false, address(0), false, 0);
                }

                bid.minted = true;
                bid.refunded = true;
            } else if (bid.winner == false && bid.refunded == false) {
                // if not winner, refund
                (bool success, ) = bidder.call{value: bid.amount}('');
                require(success, 'Failed to send refund to loser.');

                bid.refunded = true;
            }
        }
    }

    /** @notice Set the base URI for the NFTs.
        @dev Calls _setBaseURI internally, while emitting the event RevealMetadata. Only callable by the owner.
     */
    function revealMetadata(string memory _newBaseURI) external onlyOwner {
        nft.setBaseURIMinter(_newBaseURI);

        emit MetadataRevealed();
    }

    // Q: Should this be combined with settleBidder?
    function setAuctionSettled() external onlyOwner {
        require(auctionSettled == false, 'Auction already settled');
        auctionSettled = !auctionSettled;
        _withdraw();
        emit AuctionSettled();
    }

    function setTimes(uint256 allowListStart, uint256 _duration) public onlyOwner {
        oasisListStartDateTime = allowListStart + 90;
        allowListStartDateTime = allowListStart + 90;
        allowListEndDateTime = allowListStartDateTime + _duration;
        auctionStartDateTime = allowListEndDateTime;
        auctionEndDateTime = auctionStartDateTime + _duration;
    }

    function setAllowListPrice(uint256 _allowListPrice) public onlyOwner {
        allowListPrice = _allowListPrice;
    }

    /* ADMIN VARIABLE SETTERS FUNCTIONS */

    function setAllowlistSigner(address _signer) public onlyAdmin {
        allowlistSigner = _signer;
    }

    // set the 721 contract address
    function set721ContractAddress(WildNFT _nft) public onlyAdmin {
        nft = _nft;
    }

    function setAuctionSupply(uint256 _newAuctionSupply) public onlyAdmin {
        auctionSupply = _newAuctionSupply;
    }

    function setPromoSupply(uint256 _newPromoSupply) public onlyAdmin {
        promoSupply = _newPromoSupply;
    }

    function addToAllowList(address[] memory _addresses, uint8 _state) public onlyAdmin {
        for (uint256 i = 0; i < _addresses.length; i++) {
            address _address = _addresses[i];
            allowList[_address] = _state;

            emit AddedToAllowList(_address, _state);
        }
    }

    function removeFromAllowList(address[] memory _addresses) public onlyAdmin {
        for (uint256 i = 0; i < _addresses.length; i++) {
            address _address = _addresses[i];
            allowList[_address] = 0;

            emit RemovedFromAllowList(_address);
        }
    }

    function setPublicSaleMintMax(uint256 _newPublicSaleMintMax) public onlyAdmin {
        publicSaleMintMax = _newPublicSaleMintMax;
    }

    function setAllowlistMintMax(uint256 _newAllowlistMintMax) public onlyAdmin {
        allowlistMintMax = _newAllowlistMintMax;
    }

    function setOasislistStartDateTime(uint256 _newOasislistStartDateTime) public onlyAdmin {
        oasisListStartDateTime = _newOasislistStartDateTime;
    }

    function setAuctionStartDateTime(uint256 _newAuctionStartDateTime) public onlyAdmin {
        auctionStartDateTime = _newAuctionStartDateTime;
    }

    function setAuctionEndDateTime(uint256 _newAuctionEndDateTime) public onlyAdmin {
        auctionEndDateTime = _newAuctionEndDateTime;
    }

    function setAllowListStartDateTime(uint256 _newAllowListStartDateTime) public onlyAdmin {
        allowListStartDateTime = _newAllowListStartDateTime;
    }

    function setAllowListEndDateTime(uint256 _newAllowListEndDateTime) public onlyAdmin {
        allowListEndDateTime = _newAllowListEndDateTime;
    }

    function setPublicSale() public onlyAdmin {
        publicSale = !publicSale;
    }

    function setRaffleSupply(uint256 _newRaffleSupply) public onlyAdmin {
        raffleSupply = _newRaffleSupply;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyAdmin {
        maxSupply = _newMaxSupply;
    }

    // set the time buffer
    function setTimeBuffer(uint256 _timeBuffer) external override onlyAdmin {
        timeBuffer = _timeBuffer;
        emit AuctionTimeBufferUpdated(_timeBuffer);
    }

    // set the minimum bid
    function setMinimumBid(uint256 _minimumBid) external onlyAdmin {
        minimumBid = _minimumBid;
        emit AuctionMinimumBidUpdated(_minimumBid);
    }

    // set min bid incr
    function setMinBidIncrement(uint256 _minBidIncrement) external onlyAdmin {
        minBidIncrement = _minBidIncrement;
        emit AuctionMinBidIncrementUpdated(_minBidIncrement);
    }

    // set the duration
    function setDuration(uint256 _duration) external override onlyAdmin {
        duration = _duration;
        emit AuctionDurationUpdated(_duration);
    }

    // airdrop mint
    function promoMint(address _to, uint256 _qty) external onlyAdmin {
        require(promoSupply >= _qty, 'Not enough promo supply');
        require(block.timestamp <= allowListEndDateTime, 'Outside promo mint window');

        // this require is to avoid an empty error string if a transaction fails
        require((maxSupply - nft.totalSupply() - _qty) >= raffleSupply, 'Not enough supply remaining for raffle');

        for (uint256 i = 0; i < _qty; i++) {
            _promoMint(_to);
        }
        promoSupply -= _qty;
        auctionSupply = maxSupply - nft.totalSupply() - raffleSupply;
    }

    // airdrop batch mint; sends 1 to each address in array
    function promoBatchMint(address[] memory _to) external onlyAdmin {
        uint256 numAddresses = _to.length;

        require(promoSupply >= numAddresses, 'Not enough promo supply');
        require(block.timestamp <= allowListEndDateTime, 'Outside promo mint window');

        // this require is to avoid an empty error string if a transaction fails
        require((maxSupply - nft.totalSupply() - numAddresses) >= raffleSupply, 'Not enough supply remaining for raffle');

        for (uint256 i = 0; i < numAddresses; i++) {
            _promoMint(_to[i]);
        }
        promoSupply -= numAddresses;
        auctionSupply = maxSupply - nft.totalSupply() - raffleSupply;
    }

    /* PUBLIC FUNCTIONS */

    function allowlistMint(uint256 _qty, bytes memory _signature) external payable onlyUnsanctioned(msg.sender) {
        _allowlistMint(_qty, msg.sender, _signature);
    }

    function allowlistMintDelegated(uint256 _qty, address _vault) external payable onlyUnsanctioned(msg.sender) {
        require(IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B).checkDelegateForContract(msg.sender, _vault, address(oasis)));
        _allowlistMint(_qty, _vault, '');
    }

    function verifySignature(address _address, bytes memory _signature) public view returns (bool valid) {
        if (_signature.length == 65) {
            // we pass the uers _address and this contracts address to
            // verify that it is intended for this contract specifically
            bytes32 addressHash = keccak256(abi.encodePacked(_address, address(this)));
            bytes32 message = ECDSA.toEthSignedMessageHash(addressHash);
            address signerAddress = ECDSA.recover(message, _signature);

            return (signerAddress != address(0) && signerAddress == allowlistSigner);
        } else {
            return false;
        }
    }

    /* is address on allowlist
        returns which group (1 = oasis, 2 = allowlist) and tokens left to mint
    */
    function checkAllowlist(address _address, bytes memory _signature) public view returns (uint8 group, uint256 tokens) {
        uint256 oasisBalance = oasis.balanceOf(_address);
        if (oasisBalance > 0) {
            return (1, _oasisListQuantity(_address));
        }

        // must recover allowlistSigner from signature
        bool isValid = verifySignature(_address, _signature);

        if (isValid) {
            return (2, allowlistMintMax - allowListMinted[_address]);
        }

        return (0, 0);
    }

    /* INTERNAL FUNCTIONS */

    function _oasisListQuantity(address _address) internal view returns (uint256) {
        uint256 oasisCount = oasis.balanceOf(_address);
        uint256 quantity = 0;
        for (uint256 i = 0; i < oasisCount; i++) {
            uint256 tokenId = oasis.tokenOfOwnerByIndex(_address, i);
            quantity += allowlistMintMax - oasisPassMints[tokenId];
        }
        return quantity;
    }

    function _promoMint(address to) internal {
        uint256 tokenId = nft.mint(to);

        emit TokenMint(to, tokenId, MintType.Promo, false, address(0), false, 0);
    }

    // allowlist mint
    function _allowlistMint(uint256 _qty, address requester, bytes memory _signature) internal {
        require(msg.value >= allowListPrice * _qty, 'Not enough ETH sent');
        require(allowlistSupply - _qty >= 0, 'No more allowlist supply');

        address receiver = msg.sender;

        (uint group, uint256 allowance) = checkAllowlist(requester, _signature);

        require(group > 0, 'Not allowed');
        require(_qty <= allowance, 'Qty exceeds max allowed.');

        // this require is to avoid an empty error string if a transaction fails
        require((maxSupply - nft.totalSupply() - _qty) >= raffleSupply, 'Not enough supply remaining for raffle');

        if (group == 1) {
            // oasis list minter
            require(block.timestamp >= oasisListStartDateTime && block.timestamp <= allowListEndDateTime, 'Outside Oasis allowlist window');

            // start of markOasisPassesUsed
            uint256 oasisCount = oasis.balanceOf(requester);
            uint256 mintsLeft = _qty;

            for (uint256 i = 0; i < oasisCount; i++) {
                uint256 oasisId = oasis.tokenOfOwnerByIndex(requester, i);
                uint256 tokenAllowance = allowlistMintMax - oasisPassMints[oasisId];

                if (tokenAllowance == 0) {
                    // Oasis pass been fully minted
                    continue;
                }

                uint8 quantityMintedWithOasis = uint8(Math.min(tokenAllowance, mintsLeft));

                oasisPassMints[oasisId] += quantityMintedWithOasis;
                mintsLeft -= quantityMintedWithOasis;

                for (uint256 j = 0; j < quantityMintedWithOasis; j++) {
                    uint256 tokenId = nft.mint(receiver);

                    // we call this here to mark the oasis pass as used in the event itself
                    _emitAllowListTokenMint(requester, receiver, tokenId, true, oasisId);

                    allowlistSupply--;
                }
            }

            require(mintsLeft == 0, 'Not enough Oasis mint available');
            // end of markOasisPassesUsed
        } else {
            // other allowlist minter
            require(block.timestamp >= allowListStartDateTime && block.timestamp <= allowListEndDateTime, 'Outside allowlist window');

            for (uint256 i = 0; i < _qty; i++) {
                uint256 tokenId = nft.mint(receiver);

                _emitAllowListTokenMint(requester, receiver, tokenId, false, 0);

                allowlistSupply--;
            }

            allowListMinted[requester] += _qty;
        }

        auctionSupply = maxSupply - nft.totalSupply() - raffleSupply;
    }

    // helper to check if this is a delegated mint or not
    function _emitAllowListTokenMint(address requester, address receiver, uint256 tokenId, bool oasisUsed, uint256 oasisId) internal {
        if (requester != receiver) {
            // delegated
            emit TokenMint(receiver, tokenId, MintType.Allowlist, true, requester, oasisUsed, oasisId);
        } else {
            // not delegated
            emit TokenMint(receiver, tokenId, MintType.Allowlist, false, address(0), oasisUsed, oasisId);
        }
    }

    /**
     * Transfer ETH and return the success status.
     * This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{value: value, gas: 30_000}(new bytes(0));
        return success;
    }

    /* PUBLIC FUNCTIONS */

    // UNIVERSAL GETTER FOR AUCTION-RELATED VARIABLES
    function getAuctionInfo() public view returns (uint256 _auctionSupply, uint256 _auctionStartDateTime, uint256 _auctionEndDateTime, uint256 _auctionExtentedTime, bool _auctionWinnersSet, bool _auctionSettled, bool _settled, uint256 _timeBuffer, uint256 _duration, uint256 _minimumBid, uint256 _minBidIncrement) {
        return (auctionSupply, auctionStartDateTime, auctionEndDateTime, auctionExtentedTime, auctionWinnersSet, auctionSettled, settled, timeBuffer, duration, minimumBid, minBidIncrement);
    }

    // UNIVERSAL GETTER FOR ALLOWLIST AND RAFFLE-RELATED VARIABLES
    function getAllowlistAndRaffleInfo() public view returns (uint256 _raffleSupply, uint256 _allowListPrice, uint256 _allowListStartDateTime, uint256 _allowListEndDateTime, bool _raffleWinnersSet, bool _publicSale, uint256 _allowlistSupply, uint256 _totalMinted, uint256 _oasislistStartDateTime, uint256 _allowlistMintMax) {
        return (raffleSupply, allowListPrice, allowListStartDateTime, allowListEndDateTime, raffleWinnersSet, publicSale, allowlistSupply, nft.totalSupply(), oasisListStartDateTime, allowlistMintMax);
    }

    // Creates bids for the current auction
    function createBid() external payable nonReentrant onlyUnpaused onlyUnsanctioned(msg.sender) {
        address bidder = msg.sender;
        uint256 bidAmount = msg.value;

        // Check that the auction is live && Bid Amount is greater than minimum bid
        require(block.timestamp < auctionEndDateTime && block.timestamp >= auctionStartDateTime, 'Outside auction window.');
        require(bidAmount >= minimumBid, 'Bid amount too low.');

        // check if bidder already has bid
        if (Bids[bidder].amount > 0) {
            // if so, refund old and replace with new

            Bid storage existingBid = Bids[bidder];

            require(bidAmount > existingBid.amount, 'You can only increase your bid, not decrease.');

            _safeTransferETH(payable(bidder), existingBid.amount);

            existingBid.amount = bidAmount;
        } else {
            // otherwise, enter new bid.
            Bid memory new_bid;
            new_bid.bidder = payable(bidder);
            new_bid.amount = bidAmount;
            new_bid.timestamp = block.timestamp;
            new_bid.winner = false;
            new_bid.refunded = false;
            new_bid.minted = false;
            new_bid.finalprice = 0;
            Bids[bidder] = new_bid;
        }

        // Extend the auction if the bid was received within the time buffer
        // bool extended = auctionEndDateTime - block.timestamp < timeBuffer;
        //if (extended) {
        //    auctionEndDateTime = auctionEndDateTime + timeBuffer;
        //    auctionExtentedTime = auctionExtentedTime + timeBuffer;
        //}

        emit AuctionBid(bidder, bidAmount, false);
    }

    function publicSaleMint() public payable nonReentrant onlyUnpaused onlyUnsanctioned(msg.sender) {
        // if we didnt sell out, we can mint the remaining
        // for price of min bid
        // will error when supply is 0
        // Note: 1) is the auction closed and 2) is the raffle set and
        // 3) if the total supply is less than the max supply, then you can allow ppl to mint
        // require(auctionEndDateTime < block.timestamp, "Auction not over yet.");
        // require(raffleWinnersSet == true, "Raffle not settled yet.");
        require(nft.totalSupply() < nft.maxSupply(), 'No more tokens available.');
        require(publicSale == true, 'Not authorized.');
        require(msg.value >= minimumBid, 'Amount too low.');

        uint256 tokenId = nft.mint(msg.sender);

        emit TokenMint(msg.sender, tokenId, MintType.PublicSale, false, address(0), false, 0);

        auctionSupply--;
    }

    // multiple minting for public sale (do not use this for one mint, use publicSaleMint() instead)
    function publicSaleMintMultiple(uint256 _qty) public payable nonReentrant onlyUnpaused onlyUnsanctioned(msg.sender) {
        uint256 _maxSupply = nft.maxSupply();
        uint256 _totalSupply = nft.totalSupply();

        require(_qty <= publicSaleMintMax, 'Too many tokens requested.');

        require(_totalSupply < _maxSupply, 'No more tokens available.');

        // which one is better?
        require((_maxSupply - _totalSupply) >= _qty, 'Not enough supply left - 1.');
        require(auctionSupply >= _qty, 'Not enough supply left - 2.');
        //

        require(publicSale == true, 'Not authorized.');
        require(msg.value >= (minimumBid * _qty), 'Amount too low.');

        for (uint256 i = 0; i < _qty; i++) {
            uint256 tokenId = nft.mint(msg.sender);

            emit TokenMint(msg.sender, tokenId, MintType.PublicSale, false, address(0), false, 0);

            allowlistSupply--;
        }
    }
}