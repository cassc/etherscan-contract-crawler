// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";


interface ICampaignFactory {
    function recipient() external view returns (address);
}

contract Campaign is Initializable {
    bool public initialized;
    string public campaignId;
    address immutable owner;
    address immutable factory;
    address public campaignOwner;
    address public prizeAddress;
    uint256 public prizeAmount;
    uint256 public maxEntries;
    uint256 public startTimestamp;
    uint256 public endTimestamp;
    bytes32 private sealedSeed;
    uint256 private feeAmount;
    uint256 private depositAmount;

    uint256 private campaignOwnersContribution;
    uint256 private campaignOwnersContributionTotal;

    bytes32 public revealedSeed;

    mapping(address => bool) private freeEntry;
    mapping(address => address) private chain;
    mapping(uint256 => address) private cursorMap;

    uint256 public length;

    uint256 private rattleRandom;
    bool private cancelled;
    bool private depositReceived;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier onlyCampaignOwner() {
        require(msg.sender == campaignOwner, "Caller is not the campaign owner");
        _;
    }

    constructor(address _owner, address _factory) {
        owner = _owner;
        factory = _factory;
    }

    function initialize(
        address _campaignOwner,
        string memory _campaignId,
        address _prizeAddress,
        uint256 _prizeAmount,
        uint256 _maxEntries,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        bytes32 _sealedSeed,
        uint256 _deposit,
        uint256 _fee
    ) external initializer {
        campaignOwner = _campaignOwner;
        campaignId = _campaignId;
        prizeAddress = _prizeAddress;
        prizeAmount = _prizeAmount;
        maxEntries = _maxEntries;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        sealedSeed = _sealedSeed;
        rattleRandom = uint256(_sealedSeed);
        uint256 cent = getUSCentInWEI();
        feeAmount = cent * _fee;
        depositAmount = cent * _deposit;
    }

    function getUSDInWEI() public view returns (uint256) {
        address dataFeed;
        if (block.chainid == 1) {
            //Mainnet ETH/USD
            dataFeed = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        } else if (block.chainid == 5) {
            //Goerli ETH/USD
            dataFeed = 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e;
        } else if (block.chainid == 137) {
            //Polygon MATIC/USD
            dataFeed = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
        } else if (block.chainid == 80001) {
            //Mumbai MATIC/USD
            dataFeed = 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada;
        } else if (block.chainid == 56) {
            dataFeed = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
        } else if (block.chainid == 97) {
            //BSC BNBT/USD
            dataFeed = 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526;
        } else {
            // forTesting
            return 1e15;
        }
        AggregatorV3Interface priceFeed = AggregatorV3Interface(dataFeed);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return 1e26 / uint256(price);
    }

    function getUSCentInWEI() public view returns (uint256) {
        return getUSDInWEI() / 100;
    }

    event CampaignCreated(
        address campaignAddress,
        address campaignOwner,
        string campaignId,
        address prizeAddress,
        uint256 prizeAmount,
        uint256 maxEntries,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    function getDetail()
        public
        view
        returns (
            address _campaignOwner,
            string memory _campaignId,
            address _prizeAddress,
            uint256 _prizeAmount,
            uint256 _maxEntries,
            uint256 _startTimestamp,
            uint256 _endTimestamp,
            uint256 _entryCount
        )
    {
        return (
            campaignOwner,
            campaignId,
            prizeAddress,
            prizeAmount,
            maxEntries,
            startTimestamp,
            endTimestamp,
            length
        );
    }

    function hashMessage(address _user, uint256 _timestamp)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(this, _user, _timestamp));
    }

    function isStarted() public view returns (bool) {
        return block.timestamp >= startTimestamp;
    }

    function isNotClosed() public view returns (bool) {
        return block.timestamp < endTimestamp;
    }

    function isNotFull() public view returns (bool) {
        return length < maxEntries;
    }

    function isCancelled() public view returns (bool) {
        return cancelled;
    }

    function isDepositReceived() public view returns (bool) {
        return depositReceived;
    }

    function hasEntered(address _user) public view returns (bool) {
        return chain[_user] != address(0);
    }

    function getFreeDrawRemaining() public view returns (uint256) {
        return (feeAmount > 0) ? (campaignOwnersContribution / feeAmount) : 0;
    }

    function getStatus()
        public
        view
        returns (
            bool _hasEntered,
            bool _isStarted,
            bool _isNotClosed,
            bool _isRevealed,
            bool _isDepositReceived,
            bool _isCancelled,
            uint256 _totalEntries,
            uint256 _maxEntries,
            uint256 _fee,
            uint256 _freeDrawRemaining
        )
    {
        return (
            hasEntered(msg.sender),
            isStarted(),
            isNotClosed(),
            isRevealed(),
            isDepositReceived(),
            isCancelled(),
            length,
            maxEntries,
            feeAmount,
            getFreeDrawRemaining()
        );
    }

    function getFee() public view returns (uint256) {
        return feeAmount;
    }

    function setFeeZero() public onlyOwner {
        require(!isStarted(), "Campaign has started");
        feeAmount = 0;
        if (campaignOwnersContribution > 0) {
            payable(campaignOwner).transfer(campaignOwnersContribution);
            campaignOwnersContribution = 0;
        }
    }

    function getEntryCount() public view returns (uint256) {
        return length;
    }

    function deposit() public payable onlyCampaignOwner {
        require(!depositReceived, "Deposit has already been received");
        require(!isCancelled(), "Campaign has been cancelled");
        require(isNotClosed(), "Campaign has ended");
        require(msg.value >= depositAmount, "You need to pay the deposit");
        if (msg.value > depositAmount) {
            payable(msg.sender).transfer(msg.value - depositAmount);
        }
        depositReceived = true;
    }

    function getDepositAmount() public view returns (uint256) {
        return depositAmount;
    }

    function setCampaignOwnersContribution() public payable onlyCampaignOwner {
        require(!isCancelled(), "Campaign has been cancelled");
        require(isNotClosed(), "Campaign has ended");
        require(
            campaignOwnersContribution + msg.value <= maxEntries * feeAmount,
            "You cannot contribute more than the maximum amount"
        );
        campaignOwnersContribution += msg.value;
    }

    function getCampaignOwnersContribution() public view returns (uint256) {
        return campaignOwnersContribution;
    }

    function isFreeDraw() public view returns (bool) {
        return campaignOwnersContribution >= feeAmount;
    }

    function isRevealed() public view returns (bool) {
        return revealedSeed != 0;
    }

    function setEntry(
        uint256 _timestamp,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public payable {
        require(isNotFull(), "Already reached the maximum number of entries");
        require(isStarted(), "Campaign has not started yet");
        require(isNotClosed(), "Campaign has ended");
        require(!isCancelled(), "Campaign has been cancelled");
        require(
            _timestamp + 5 minutes > block.timestamp,
            "Timestamp is not valid"
        );
        require(chain[msg.sender] == address(0), "You have already entered");

        bytes32 message = hashMessage(msg.sender, _timestamp);

        require(
            ecrecover(message, v, r, s) == owner,
            "You need signatures from the owner to set an entry"
        );

        if (isFreeDraw()) {
            campaignOwnersContribution -= feeAmount;
            campaignOwnersContributionTotal += feeAmount;
            freeEntry[msg.sender] = true;
        } else {
            require(
                msg.value >= feeAmount,
                "You need to pay the entry fee to enter"
            );
        }

        uint256 rand = uint256(
            keccak256(abi.encodePacked(message, rattleRandom, length))
        );

        if (length == 0) {
            chain[msg.sender] = msg.sender;
            cursorMap[0] = msg.sender;
        } else {
            address cursor = cursorMap[rand % length];
            chain[msg.sender] = chain[cursor];
            chain[cursor] = msg.sender;
            cursorMap[length] = msg.sender;
        }
        length++;
        rattleRandom = rand;
    }

    function withdrawAll() public onlyOwner {
        require(
            endTimestamp + 365 days < block.timestamp,
            "Campaign has not ended yet"
        );
        payable(ICampaignFactory(factory).recipient()).transfer(address(this).balance);
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "transfer failed"
        );
    }

    function RecoverERC20(address _tokenAddress) public onlyOwner {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        safeTransfer(_tokenAddress, owner, balance);
    }

    function getPaybackAmount() public view returns (uint256) {
        return (length * feeAmount) / 2;
    }

    function payback() public payable onlyCampaignOwner {
        require(!isCancelled(), "Campaign has been cancelled already");
        require(revealedSeed == 0, "Campaign has already been revealed");

        require(
            msg.value >= getPaybackAmount(),
            "You need to pay 1/2 of the fee that user paid"
        );

        uint256 campaignOwnersBack = isDepositReceived() ? depositAmount : 0;
        depositReceived = false;
        campaignOwnersBack += campaignOwnersContributionTotal;
        campaignOwnersBack += campaignOwnersContribution;
        campaignOwnersBack += msg.value - getPaybackAmount();
        payable(campaignOwner).transfer(campaignOwnersBack);
        payable(ICampaignFactory(factory).recipient()).transfer(msg.value);
        cancelled = true;
    }

    function paybackWithdraw() public {
        require(isCancelled(), "Campaign has not been cancelled");
        require(
            chain[msg.sender] != address(0) && !freeEntry[msg.sender],
            "You don't have right to withdraw"
        );
        chain[msg.sender] = address(0);
        payable(msg.sender).transfer(feeAmount);
    }

    function revealSeed(bytes32 _seed) public {
        require(!isNotClosed(), "Campaign has not ended yet");
        require(!isCancelled(), "Campaign has been cancelled");
        require(revealedSeed == 0, "Seed has already been revealed");
        require(
            block.timestamp > endTimestamp + 7 days ||
                msg.sender == campaignOwner,
            "You can not reveal the seed"
        );
        require(
            keccak256(abi.encodePacked(campaignId, _seed)) == sealedSeed,
            "Seed is not correct"
        );
        revealedSeed = _seed;
        rattleRandom = uint256(
            keccak256(abi.encodePacked(_seed, rattleRandom))
        );
        if (isDepositReceived()) {
            payable(msg.sender).transfer(depositAmount);
            depositReceived = false;
        }
        if (campaignOwnersContribution > 0) {
            payable(campaignOwner).transfer(campaignOwnersContribution);
            campaignOwnersContribution = 0;
        }
        payable(ICampaignFactory(factory).recipient()).transfer(address(this).balance);
    }

    function canDraw() public view returns (bool) {
        return revealedSeed > 0;
    }

    function draw() public view returns (address[] memory _winners) {
        require(canDraw(), "Seed has not been confirmed yet");

        address[] memory winners = new address[](prizeAmount);
        uint256 winnerNum = prizeAmount < length ? prizeAmount : length;
        address cursor = cursorMap[rattleRandom % length];
        for (uint256 i = 0; i < winnerNum; i++) {
            winners[i] = chain[cursor];
            cursor = chain[cursor];
        }
        for (uint256 i = winnerNum; i < prizeAmount; i++) {
            winners[i] = campaignOwner;
        }

        return winners;
    }
}