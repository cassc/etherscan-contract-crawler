// SPDX-License-Identifier: unlicensed
pragma solidity 0.8.17;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
// import "openzeppelin-solidity/contracts/utils/cryptography/ECDSA.sol";
import "./_ecdsa.sol";
// import ecdsa from solady library
interface INft {
    function mint(address to, uint8 amount) external;
}

contract KiraAuctionHandler is Ownable {
    mapping(address => uint8) alreadyPledgedMercenary;
    mapping(address => uint8) alreadyPledgedEnlisted;
    mapping(address => uint8) alreadyPledgedLastPhase;

    mapping(address => Bid) bids;
    mapping(address => bool) public alreadyBid;
    mapping(address => bool) public refunded;
    mapping(address => bool) public bidWinner;
    mapping(address => bool) public bidWhitelist;
    address public kiraTreasury;
    address public card;

    uint256 cutoffValue;
    uint256 minBid;
    uint256 maxBid;

    uint16 numberOfNfts;
    uint8 state;
    uint8 maxAmountBidPhase;

    bool paused;

    struct Phase {
        uint8 maxAmountPerUser;
        bool isOpen;
        uint16 pledgedTotalAmount;
        uint16 supplyAllocated;
        address signer;
        uint256 pledgedTotalEth;
        uint256 price;
    }

    struct Bid {
        uint256 amount;
        uint256 value;
    }

    Phase public mercenary;
    Phase public enlisted;
    Phase public lastPhase;

    event UserBid(address indexed bidder, uint256 amount, uint256 value);
    event userPledge(address indexed user, uint256 amount);
    modifier state1() {
        require(state == 1, "Bidding hasn't started yet");
        _;
    }

    modifier state2() {
        require(state == 2, "Refunds haven't started yet");
        _;
    }

    bool locked;
    modifier nonReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    constructor() {
        kiraTreasury = 0x6aD9356B3d0eEE5cA31DD757c95fB5AB67b01c33;
        minBid = 0.069 ether;
        maxBid = 0.099 ether;
        maxAmountBidPhase = 3;
        mercenary = Phase(
            2,
            false,
            0,
            1000,
            0xEAf4E461348Dd23928Bf77F0a3d3E55ea19D335E,
            0,
            0.069 ether
        );
        enlisted = Phase(
            1,
            false,
            0,
            3500,
            0xe9f5ea1Ff626d13cFBE1A7Dc47f40b9443EF2cCC,
            0,
            0.069 ether
        );
        lastPhase = Phase(
            1,
            false,
            0,
            0,
            0x3FB476663d8247ACDAAA9C220D91089ed04144b2,
            0,
            0.069 ether
        );
    }

    function newBid(uint8 amount) external payable state1 {
        require(!paused, "Paused");
        require(msg.sender == tx.origin, "No Smart Contracts!");
        require(!alreadyBid[msg.sender], "You have a bid already");
        require(amount > 0, "Amount must be greater than 0");
        uint256 value = msg.value / amount;
        if (!bidWhitelist[msg.sender]) {
            require(value >= minBid, "Bid amount is too low");
            require(value <= maxBid, "Bid amount is too high");
            require(amount <= maxAmountBidPhase, "Too many bids");
        }
        alreadyBid[msg.sender] = true;
        bids[msg.sender] = Bid(amount, value);
        emit UserBid(msg.sender, amount, value);
    }

    function processUserBid() public nonReentrant {
        require(state >= 2, "Not in the right state for this action");
        require(!refunded[msg.sender], "Refund already claimed");
        refunded[msg.sender] = true;
        uint256 refundAmount;
        Bid memory userBids = bids[msg.sender];
        require(userBids.amount > 0, "No bid found");
        if (!bidWinner[msg.sender]) {
            refundAmount = userBids.amount * userBids.value;
        } else {
            refundAmount = userBids.amount * (userBids.value - cutoffValue);
            INft(card).mint(msg.sender, 1);
        }
        (bool success, ) = payable(msg.sender).call{
            value: refundAmount,
            gas: 30000
        }("");
        require(success, "Refund failed");
    }

    function pledgeMercenary(
        uint8 amount,
        bytes calldata signature
    ) external payable {
        INft(card).mint(msg.sender, 1);
        Phase memory m = mercenary;
        require(m.isOpen, "Not open");
        require(amount > 0, "Amount must be greater than 0");
        uint8 numPledged = alreadyPledgedMercenary[msg.sender] + amount;
        require(
            numPledged <= m.maxAmountPerUser,
            "You would exceed the max amount per user"
        );
        require(msg.value == amount * m.price, "Incorrect amount of ETH sent");
        require(_validateData(msg.sender, signature, m.signer));
        require(
            m.pledgedTotalAmount + amount <= m.supplyAllocated,
            "Not enough supply left"
        );
        alreadyPledgedMercenary[msg.sender] = numPledged;
        mercenary.pledgedTotalEth += msg.value;
        mercenary.pledgedTotalAmount += amount;
        emit userPledge(msg.sender, amount);
    }

    function pledgeEnlisted(
        uint8 amount,
        bytes calldata signature
    ) external payable {
        INft(card).mint(msg.sender, 1);
        Phase memory e = enlisted;
        require(amount > 0, "Amount must be greater than 0");
        require(e.isOpen, "Not open");
        uint8 numPledged = alreadyPledgedEnlisted[msg.sender] + amount;
        require(
            numPledged <= e.maxAmountPerUser,
            "You would exceed the max amount per user"
        );
        require(msg.value == amount * e.price, "Incorrect amount of ETH sent");
        require(_validateData(msg.sender, signature, e.signer));
        require(
            e.pledgedTotalAmount + amount <= e.supplyAllocated,
            "Not enough supply left"
        );
        alreadyPledgedEnlisted[msg.sender] = numPledged;
        enlisted.pledgedTotalEth += msg.value;
        enlisted.pledgedTotalAmount += amount;
        emit userPledge(msg.sender, amount);
    }

    function pledgeLastPhase(
        uint8 amount,
        bytes calldata signature
    ) external payable {
        INft(card).mint(msg.sender, 1);
        Phase memory l = lastPhase;
        require(amount > 0, "Amount must be greater than 0");
        require(l.isOpen, "Not open");
        uint8 numPledged = alreadyPledgedLastPhase[msg.sender] + amount;
        require(
            numPledged <= l.maxAmountPerUser,
            "You would exceed the max amount per user"
        );
        require(msg.value == amount * l.price, "Incorrect amount of ETH sent");
        require(_validateData(msg.sender, signature, l.signer));
        require(
            l.pledgedTotalAmount + amount <= l.supplyAllocated,
            "Not enough supply left"
        );
        alreadyPledgedLastPhase[msg.sender] = numPledged;
        lastPhase.pledgedTotalEth += msg.value;
        lastPhase.pledgedTotalAmount += amount;
        emit userPledge(msg.sender, amount);
    }

    function setCard(address _card) external onlyOwner {
        card = _card;
    }

    function setKiraTreasury(address _kiraTreasury) external onlyOwner {
        require(
            _kiraTreasury != address(0),
            "Kira treasury address cannot be 0"
        );
        kiraTreasury = _kiraTreasury;
    }

    function openBids() external onlyOwner {
        state = 1;
    }

    function resumeBidPhase() external onlyOwner {
        cutoffValue = 0;
        numberOfNfts = 0;
        state = 1;
    }

    function finalizeBidPhase(
        uint256 _cutoffValue,
        uint16 _numberOfNfts
    ) external onlyOwner {
        cutoffValue = _cutoffValue;
        numberOfNfts = _numberOfNfts;
        state = 2;
    }

    function flipPaused() external onlyOwner {
        paused = !paused;
    }

    function setState(uint8 _state) external onlyOwner {
        state = _state;
    }

    function setMinMaxBid(uint256 _minBid, uint256 _maxBid) external onlyOwner {
        minBid = _minBid;
        maxBid = _maxBid;
    }

    function openPhase(uint8 i) external onlyOwner {
        if (i == 1) {
            mercenary.isOpen = true;
        } else if (i == 2) {
            enlisted.isOpen = true;
        } else if (i == 3) {
            lastPhase.isOpen = true;
        } else {
            revert("Invalid phase");
        }
    }

    function editSupplyAllocated(uint8 i, uint16 newSupply) external onlyOwner {
        if (i == 1) {
            mercenary.supplyAllocated = newSupply;
        } else if (i == 2) {
            enlisted.supplyAllocated = newSupply;
        } else if (i == 3) {
            lastPhase.supplyAllocated = newSupply;
        } else {
            revert("Invalid phase");
        }
    }

    function editPrice(uint8 i, uint256 newPrice) external onlyOwner {
        if (i == 1) {
            mercenary.price = newPrice;
        } else if (i == 2) {
            enlisted.price = newPrice;
        } else if (i == 3) {
            lastPhase.price = newPrice;
        } else {
            revert("Invalid phase");
        }
    }

    function editSigner(uint8 i, address newSigner) external onlyOwner {
        if (i == 1) {
            mercenary.signer = newSigner;
        } else if (i == 2) {
            enlisted.signer = newSigner;
        } else if (i == 3) {
            lastPhase.signer = newSigner;
        } else {
            revert("Invalid phase");
        }
    }

    function editMaxAmountPerUser(uint8 i, uint8 newMaxAmount)
        external
        onlyOwner
    {
        if (i == 1) {
            mercenary.maxAmountPerUser = newMaxAmount;
        } else if (i == 2) {
            enlisted.maxAmountPerUser = newMaxAmount;
        } else if (i == 3) {
            lastPhase.maxAmountPerUser = newMaxAmount;
        } else {
            revert("Invalid phase");
        }
    }

    function closePhase(uint8 i) external onlyOwner {
        if (i == 1) {
            mercenary.isOpen = false;
        } else if (i == 2) {
            enlisted.isOpen = false;
        } else if (i == 3) {
            lastPhase.isOpen = false;
        } else {
            revert("Invalid phase");
        }
    }

    function addWinners(address[] calldata winners) external onlyOwner {
        for (uint256 i; i < winners.length;) {
            bidWinner[winners[i]] = true;
            unchecked { ++i; }
        }
    }

    function removeWinners(address[] calldata winners) external onlyOwner {
        for (uint256 i; i < winners.length;) {
            bidWinner[winners[i]] = false;
            unchecked { ++i; }
        }
    }

    function addBidWhitelist(address[] calldata whitelist) external onlyOwner {
        for (uint256 i; i < whitelist.length;) {
            bidWhitelist[whitelist[i]] = true;
            unchecked { ++i; }
        }
    }

    function removeBidWhitelist(address[] calldata whitelist)
        external
        onlyOwner
    {
        for (uint256 i; i < whitelist.length;) {
            bidWhitelist[whitelist[i]] = false;
            unchecked { ++i; }
        }
    }

    // eth/token withdrawal
    function saveTokens(
        IERC20 tokenAddress,
        address walletAddress,
        uint256 amount
    ) external onlyOwner {
        require(
            walletAddress != address(0),
            "walletAddress can't be 0 address"
        );
        SafeERC20.safeTransfer(
            tokenAddress,
            walletAddress,
            amount == 0 ? tokenAddress.balanceOf(address(this)) : amount
        );
    }

    // for emergency
    function saveETH() external onlyOwner {
        require(
            kiraTreasury != address(0),
            "Kira treasury address cannot be 0"
        );
        (bool success, ) = payable(kiraTreasury).call{
            value: address(this).balance,
            gas: 50000
        }("");
        require(success, "Withdrawal failed");
    }

    function withdrawETHFromBids() external onlyOwner {
        require(
            kiraTreasury != address(0),
            "Kira treasury address cannot be 0"
        );
        require(
            cutoffValue > 0 && numberOfNfts > 0,
            "Some values are not set."
        );
        uint256 collectedAmount = numberOfNfts * cutoffValue;
        (bool success, ) = payable(kiraTreasury).call{
            value: collectedAmount,
            gas: 50000
        }("");
        require(success, "Withdrawal failed");
    }

    function withdrawETHFromMercenary() external onlyOwner {
        require(
            kiraTreasury != address(0),
            "Kira treasury address cannot be 0"
        );
        (bool success, ) = payable(kiraTreasury).call{
            value: mercenary.pledgedTotalEth,
            gas: 50000
        }("");
        require(success, "Withdrawal failed");
        mercenary.pledgedTotalEth = 0;
    }

    function withdrawETHFromEnlisted() external onlyOwner {
        require(
            kiraTreasury != address(0),
            "Kira treasury address cannot be 0"
        );
        (bool success, ) = payable(kiraTreasury).call{
            value: enlisted.pledgedTotalEth,
            gas: 50000
        }("");
        require(success, "Withdrawal failed");
        enlisted.pledgedTotalEth = 0;
    }

    function withdrawETHFromLastPhase() external onlyOwner {
        require(
            kiraTreasury != address(0),
            "Kira treasury address cannot be 0"
        );
        (bool success, ) = payable(kiraTreasury).call{
            value: lastPhase.pledgedTotalEth,
            gas: 50000
        }("");
        require(success, "Withdrawal failed");
        lastPhase.pledgedTotalEth = 0;
    }

    // views
    function getBid(address user) external view returns (Bid memory) {
        return bids[user];
    }

    function getPledgedMercenary(address user) external view returns (uint256) {
        return alreadyPledgedMercenary[user];
    }

    function getPledgedEnlisted(address user) external view returns (uint256) {
        return alreadyPledgedEnlisted[user];
    }

    function phaseDetails() external view returns (Phase memory, Phase memory, Phase memory) {
        return (mercenary, enlisted, lastPhase);
    }

    function bidDetails()
        external
        view
        returns (uint8, uint256, uint256, uint256, uint8, uint16)
    {
        return (maxAmountBidPhase, minBid, maxBid, cutoffValue, state, numberOfNfts);
    }

    function _validateData(
        address _user,
        bytes calldata signature,
        address signer
    ) internal view returns (bool) {
        bytes32 dataHash = keccak256(abi.encodePacked(_user));
        bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);

        address receivedAddress = ECDSA.recover(message, signature);
        return (receivedAddress != address(0) && receivedAddress == signer);
    }

    function saveAmountOfETH(uint256 val) external onlyOwner {
        require(
            kiraTreasury != address(0),
            "Kira treasury address cannot be 0"
        );
        (bool success, ) = payable(kiraTreasury).call{
            value: val,
            gas: 50000
        }("");
        require(success, "Withdrawal failed");
    }

    receive() external payable {}
}