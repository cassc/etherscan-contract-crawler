// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@rari-capital/solmate/src/tokens/ERC721.sol";

/**
 * @title MintSchedule
 * @author 0xVersteckt
 * @dev Mint schedule struct for keeping track of price, {cadence} (mints per schedule) and how many {rounds} occur
 * @notice
 */
struct MintSchedule {
    uint256 price;
    uint256 cadence;
    uint256 rounds;
}

/**
 * @title Recipient
 * @author 0xVersteckt
 * @dev Used to keep track of airdrop recipients
 * @notice
 */
struct Recipient {
    uint256 tokenId;
    uint256 timestamp;
    address recipient;
}

/**
 * @title Big Brain Beings NFT
 * @author 0xVersteckt
 * @notice Potentially profitable otherworldly beings in the form of worthless jpegs
 */
contract BigBrainBeings is ERC721, Ownable {
    using Counters for Counters.Counter;

    /// @notice Max supply
    uint256 public constant MAX_SUPPLY = 20000;

    /// @notice Mint price
    uint256 public constant MINT_PRICE = 0.05 ether;

    string private _baseTokenURI = "";

    /// @notice Track current number of mints, starts with 1
    Counters.Counter private _mintCounter;

    /// @notice Track current mint schedules as minting progresses
    Counters.Counter private _mintScheduleCounter;

    /// @notice Tracks total mint schedules. Setup as a Counter to allow for dynamic progressive games.
    Counters.Counter private _totalMintScheduleCounter;

    /// @notice Tracks current round of current mint schedule
    Counters.Counter private _roundCounter;

    /// @notice Tracks total rounds completed
    Counters.Counter private _totalRoundCounter;

    /// @notice Tracks total existing price feeds
    Counters.Counter private _totalPriceFeedCounter;

    mapping(uint256 => MintSchedule) private _mintSchedules;

    /// @notice Keep track of selected recipients for each round
    mapping(uint256 => Recipient) private _recipients;

    /// @notice Creator address
    address private _creatorAddress;

    constructor() ERC721("Big Brain Beings", "BBB") {
        _creatorAddress = msg.sender;

        _setBaseTokenURI("https://api.bigbrainbeings.com/api/traits/");

        /// @notice 5 {cadence} * 4000 {rounds} = 20000 {MAX_SUPPLY}
        _addMintSchedule(MINT_PRICE, 5, 4000);

        /// @notice Start minting at 1 to reduce gas fees for first minter
        _mintCounter.increment();
    }

    modifier isCorrectPayment() {
        require(msg.value == MINT_PRICE, "Incorrect ETH value sent");
        _;
    }

    // #region Public views
    function getRecipientTokenByRound(
        uint256 index
    ) public view returns (uint256) {
        return _recipients[index].tokenId;
    }

    function getRecipientAddressByRound(
        uint256 index
    ) public view returns (address) {
        return _recipients[index].recipient;
    }

    function getRecipientInfoByRound(
        uint256 index
    ) public view returns (Recipient memory) {
        return _recipients[index];
    }

    function getTotalCompletedRounds() public view returns (uint256) {
        return _totalRoundCounter.current();
    }

    function getTotalSchedules() public view returns (uint256) {
        return _totalMintScheduleCounter.current();
    }

    function totalSupply() public view returns (uint256) {
        return _mintCounter.current() - 1;
    }

    function getMintsRemaining() public view returns (uint256) {
        return MAX_SUPPLY - totalSupply();
    }

    function getCurrentSchedule() public view returns (uint256) {
        return _mintScheduleCounter.current();
    }

    function getCurrentPool() public view returns (uint256) {
        return getPoolByIndex(getCurrentSchedule());
    }

    function getPoolByIndex(uint256 index) public view returns (uint256) {
        return _mintSchedules[index].cadence * _mintSchedules[index].price;
    }

    function setBaseTokenURI(string memory uri) public onlyOwner {
        _setBaseTokenURI(uri);
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId))
            );
    }

    // #endregion

    // #region Public mint methods
    function mint() external payable isCorrectPayment returns (uint256) {
        return _mintTo(msg.sender);
    }

    // #endregion

    // #region Private functions
    function _setBaseTokenURI(string memory uri) private {
        _baseTokenURI = uri;
    }
    
    function _mintTo(address receiver) internal returns (uint256) {
        require(totalSupply() + 1 <= MAX_SUPPLY, "MAX_SUPPLY hit");

        (bool success1, ) = address(_creatorAddress).call{
            value: (msg.value * 50) / 100
        }("");
        require(success1, "Send to creator failed");

        _safeMint(receiver, _mintCounter.current());

        // New round, select recipient
        if (
            _mintScheduleCounter.current() <
            _totalMintScheduleCounter.current() &&
            (_mintCounter.current() - _sumCompletedRounds()) %
                _mintSchedules[_mintScheduleCounter.current()].cadence ==
            0
        ) {
            uint256 selectedTokenId = _selectTokenId(_mintCounter.current());
            _recipients[_totalRoundCounter.current()] = Recipient(
                selectedTokenId,
                block.timestamp,
                this.ownerOf(selectedTokenId)
            );

            // New MintSchedule
            if (
                _roundCounter.current() ==
                _mintSchedules[_mintScheduleCounter.current()].rounds - 1
            ) {
                _mintScheduleCounter.increment();
                _roundCounter.reset();
            } else {
                _roundCounter.increment();
            }

            // Send Eth balance to recipient
            (bool success2, ) = address(
                _recipients[_totalRoundCounter.current()].recipient
            ).call{value: address(this).balance}("");
            require(success2, "Failed to send Ether");

            _totalRoundCounter.increment();
        }
        _mintCounter.increment();
        return
            _totalRoundCounter.current() > 0
                ? _recipients[_totalRoundCounter.current() - 1].tokenId
                : 0;
    }

    function _addMintSchedule(
        uint256 price,
        uint256 cadence,
        uint256 rounds
    ) private {
        _mintSchedules[_totalMintScheduleCounter.current()] = MintSchedule(
            price,
            cadence,
            rounds
        );
        _totalMintScheduleCounter.increment();
    }

    function _sumCompletedRounds() private view returns (uint256) {
        uint256 aggregateTotal;
        if (_mintScheduleCounter.current() > 0) {
            for (
                uint256 i = 0;
                i < _mintScheduleCounter.current();
                i = _unsafeIncrement(i)
            ) {
                unchecked {
                    aggregateTotal =
                        aggregateTotal +
                        (_mintSchedules[i].cadence * _mintSchedules[i].rounds);
                }
            }
        }
        return aggregateTotal;
    }

    function _selectTokenId(uint256 maxValue) private view returns (uint256) {
        return (uint256((_random() % maxValue) + 1));
    }

    function _unsafeIncrement(uint256 x) private pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }

    function _random() private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.prevrandao +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        gasleft() +
                        _mintCounter.current() +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number
                )
            )
        );
        return (seed - (seed / _mintCounter.current()));
    }

    function withdrawERC20(address tokenContract) external {
        bool success = IERC20(tokenContract).transfer(
            address(_creatorAddress),
            IERC20(tokenContract).balanceOf(address(this))
        );
        require(success, "Withdraw faied");
    }

    // #endregion
}