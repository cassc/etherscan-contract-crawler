// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CaringCreatures is ERC721, Ownable {
    uint256 private _totalSupply;
    uint256 private _maxSupply = 9999;
    uint256 public price = 0.07 ether;

    bool public publicsaleActive;
    bool public presaleActive;
    uint8 public activePresaleRound;
    uint256 public giveawayMaxSupply = 222;
    uint256 public mintedGiveawayCount;
    mapping(uint8 => PresaleRound) public presaleRounds;
    bool _limitedSale = true;
    uint256 _limitedSaleLimit = 3333;

    address private _wallet1 = 0x78167CCEe7fff8A8a2F17bFc0018ABEa9fe2D4E7;
    address private _wallet2 = 0x2Bf07070baAe1176B07A4a48827e64C6efAf9Fc1;

    string public provenanceHash;
    string public baseURI;

    struct PresaleRound {
        uint256 round;
        uint256 perWalletLimit;
        mapping(address => uint256) addresses;
        bool active;
    }

    constructor() ERC721("Caring Creatures", "CARE") {}

    function mint(uint256 count) external payable {
        require(msg.sender == tx.origin, "Reverted");
        require(publicsaleActive, "Public sale is not active");
        require(_totalSupply + count <= _maxSupply, "Can not mint more than max supply");
        require(count > 0 && count <= 11, "You can mint between 1 and 11 at once");
        require(msg.value >= count * price, "Insufficient payment");

        if (_limitedSale) {
            require(_totalSupply + count <= _limitedSaleLimit, "Can not mint more than limited supply");
        }

        for (uint256 i = 0; i < count; i++) {
            _totalSupply++;
            _mint(msg.sender, _totalSupply);
        }

        bool success = false;
        (success,) = _wallet1.call{value : msg.value * 965 / 1000}("");
        require(success, "Failed to send1");

        bool success2 = false;
        (success2,) = _wallet2.call{value : msg.value * 35 / 1000}("");
        require(success2, "Failed to send2");
    }

    function mintPresale(uint256 count) external payable {
        require(msg.sender == tx.origin, "Reverted");
        require(count > 0 && count <= 11, "You can mint between 1 and 11 at once");
        require(_totalSupply + remainingGiveawayMintCount() + count <= _maxSupply, "Can not mint more than max supply");
        require(msg.value >= count * price, "Insufficient payment");

        uint8 round;
        (, round) = activeMintingDetails();

        PresaleRound storage presaleRound = presaleRounds[round];
        require(presaleActive && presaleRound.active, "Round not active");
        require(presaleRound.addresses[msg.sender] >= count, "You do not have slot to mint");

        for (uint256 i = 0; i < count; i++) {
            _totalSupply++;
            _mint(msg.sender, _totalSupply);
            presaleRounds[round].addresses[msg.sender]--;
        }

        bool success = false;
        (success,) = _wallet1.call{value : msg.value * 965 / 1000}("");
        require(success, "Failed to send1");

        bool success2 = false;
        (success2,) = _wallet2.call{value : msg.value * 35 / 1000}("");
        require(success2, "Failed to send2");
    }

    function mintGiveaway(uint256 count) external onlyOwner {
        require(msg.sender == tx.origin, "Reverted");
        require(_totalSupply + count <= _maxSupply, "Can not mint more than max supply");
        require(mintedGiveawayCount + count <= giveawayMaxSupply, "Giveaway limit reached");
        require(count > 0 && count <= 30, "You can mint between 1 and 30 at once");
        for (uint256 i = 0; i < count; i++) {
            _totalSupply++;
            _mint(msg.sender, _totalSupply);
            mintedGiveawayCount++;
        }
    }

    function toggleLimitedSale() external onlyOwner {
        _limitedSale = !_limitedSale;
    }

    function updateLimitedSaleLimit(uint256 newLimit) external onlyOwner {
        _limitedSaleLimit = newLimit;
    }

    function remainingGiveawayMintCount() public view returns (uint256) {
        return giveawayMaxSupply - mintedGiveawayCount;
    }

    function updateGiveawayMaxSupply(uint256 newLimit) external onlyOwner {
        require(newLimit >= mintedGiveawayCount, "Already has more than that");
        require(_totalSupply + newLimit - mintedGiveawayCount <= _maxSupply, "More than max supply");
        giveawayMaxSupply = newLimit;
    }

    function setupPresaleRound(uint8 round, uint256 perWalletLimit) external onlyOwner {
        PresaleRound storage presaleRound = presaleRounds[round];
        presaleRound.round = round;
        presaleRound.perWalletLimit = perWalletLimit;
    }

    function activatePresaleRound(uint8 round) external onlyOwner {
        require(!publicsaleActive, "Publicsale is active");
        PresaleRound storage presaleRound = presaleRounds[round];
        require(presaleRound.round > 0, "Round not found");
        presaleRound.active = true;
        presaleActive = true;
        activePresaleRound = round;
        emit PresaleRoundActivated(round);
    }

    function completePresaleRound(uint8 round) external onlyOwner {
        require(presaleActive, "Presale is not active");
        PresaleRound storage presaleRound = presaleRounds[round];
        require(presaleRound.round > 0, "Round not found");
        presaleRound.active = false;
        presaleActive = false;
        activePresaleRound = 0;
        emit PresaleRoundCompleted(round);
    }

    function activatePublicsale() external onlyOwner {
        require(!presaleActive, "Presale is active");
        publicsaleActive = true;
        emit PublicsaleActivated();
    }

    function completePublicsale() external onlyOwner {
        require(publicsaleActive, "Publicsale is not active");
        publicsaleActive = false;
        emit PublicsaleCompleted();
    }

    function updateWhitelistOfRound(uint8 round, address[] memory addresses) external onlyOwner {
        require(presaleRounds[round].round > 0, "Round not found");
        PresaleRound storage presaleRound = presaleRounds[round];
        uint256 perWalletLimit = presaleRound.perWalletLimit;
        uint256 addressesLength = addresses.length;

        for (uint256 i = 0; i < addressesLength; i++) {
            presaleRound.addresses[addresses[i]] = perWalletLimit;
        }
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
        emit PriceUpdated(newPrice);
    }

    function setProvenanceHash(string memory newProvenanceHash) public onlyOwner {
        provenanceHash = newProvenanceHash;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function activeMintingDetails() public view returns (string memory publicOrPresale, uint8 round) {
        if (publicsaleActive) {
            publicOrPresale = "publicsale";
            round = 0;
        } else if (presaleActive) {
            publicOrPresale = "presale";
            round = activePresaleRound;
        } else {
            publicOrPresale = "mintingPaused";
            round = 0;
        }
    }

    function isWhitelisted(address account) public view returns (bool) {
        uint8 round;
        (, round) = activeMintingDetails();

        if (presaleRounds[round].addresses[account] > 0) {
            return true;
        }

        return false;
    }

    event PresaleRoundActivated(uint8 round);
    event PresaleRoundCompleted(uint8 round);
    event PublicsaleActivated();
    event PublicsaleCompleted();
    event PriceUpdated(uint256 price);
}