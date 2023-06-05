// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Metaminds is ERC721, Ownable {
    uint256 private _totalSupply;
    uint256 private _maxSupply = 6000;
    uint256 public price = 0.07 ether;

    bool public publicsaleActive = true;
    bool public presaleActive;
    uint8 public activePresaleRound;
    mapping(uint8 => PresaleRound) public presaleRounds;
    mapping(address => uint8) public publicsaleMints;
    uint256 public publicsaleMintLimit = 10;

    address private _wallet1 = 0xE80d24499E41732365c7d13a627A0984E337E297;
    address private _wallet2 = 0x57B478Bd672D9Be308AA0b1bA23547833897C730;
    address private _wallet3 = 0xb86A3dE08A88a7BB77E82B8D5EC2eAeEE3e56E64;

    string public provenanceHash;
    string public baseURI;

    struct PresaleRound {
        uint256 round;
        uint256 perWalletLimit;
        mapping(address => uint256) addresses;
        bool active;
    }

    constructor() ERC721("Metaminds", "MINDS") {}

    function mintPublicsale(uint256 count) external payable {
        require(msg.sender == tx.origin, "Reverted");
        require(publicsaleActive, "Public sale is not active");
        require(_totalSupply + count <= _maxSupply, "Can not mint more than max supply");
        require(count > 0 && count <= 5, "Out of per transaction mint limit");
        require(msg.value >= count * price, "Insufficient payment");
        require(publicsaleMints[msg.sender] + count <= publicsaleMintLimit, "Per wallet mint limit");

        for (uint256 i = 0; i < count; i++) {
            _totalSupply++;
            publicsaleMints[msg.sender]++;
            _mint(msg.sender, _totalSupply);
        }

        distributePayment();
    }

    function mintPresale(uint256 count) external payable {
        require(msg.sender == tx.origin, "Reverted");
        require(count > 0 && count <= 2, "Out of per transaction mint limit");
        require(_totalSupply + count <= _maxSupply, "Can not mint more than max supply");
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

        distributePayment();
    }

    function distributePayment() internal {
        bool success = false;
        (success,) = _wallet1.call{value : msg.value / 2}("");
        require(success, "Failed to send1");

        bool success2 = false;
        (success2,) = _wallet2.call{value : msg.value / 2}("");
        require(success2, "Failed to send2");
    }

    function mintGiveaway() external onlyOwner {
        require(msg.sender == tx.origin, "Reverted");
        require(_totalSupply < 230, "Out of limit");
        if (_totalSupply < 140) { // 5 times
            for (uint256 i = 0; i < 14; i++) {
                _totalSupply++;
                _mint(_wallet1, _totalSupply);
                _totalSupply++;
                _mint(_wallet2, _totalSupply);
            }
        } else if (_totalSupply < 230) {
            for (uint256 i = 0; i < 10; i++) { // 3 times
                _totalSupply++;
                _mint(_wallet1, _totalSupply);
                _totalSupply++;
                _mint(_wallet2, _totalSupply);
                _totalSupply++;
                _mint(_wallet3, _totalSupply);
            }
        }

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

    function setPerWalletMintLimitForPublicsale(uint256 newLimit) external onlyOwner {
        publicsaleMintLimit = newLimit;
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