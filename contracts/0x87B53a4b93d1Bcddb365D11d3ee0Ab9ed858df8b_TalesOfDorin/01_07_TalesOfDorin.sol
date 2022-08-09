// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

contract TalesOfDorin is ERC721A, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    enum MINT_PHASE{FIRST, SECOND, THIRD}

    // phase 1 allowance data
    mapping(address => bool) public phase1FreeMintAllowed;
    mapping(address => uint256) public phase1PaidMintQuota;

    // phase 2 mint data
    mapping(address => bool) public phase2FreeMinted;
    mapping(address => uint256) public phase2PaidMinted;

    // phase 3 mint data
    mapping(address => uint256) public phase3TotalMinted;

    // maximum  number of mints allowed per address in phase 3
    uint256 public MAX_ALLOWED_IN_PHASE_3 = 10;

    // base uri of tokens
    string public BASE_URI = "";

    // pre reveal uri
    string public PRE_REVEAL_URI = "";

    // mint price for paid mints
    uint256 public PUBLIC_PRICE = 0.0069 ether;

    // maximum supply of tokens
    uint256 public MAX_SUPPLY = 4444;

    // Is the mint in progress?
    bool public MINT_STARTED = false;

    // whether revealed or not?
    bool public REVEALED = false;

    // Phase of the mint (FIRST/SECOND/THIRD)
    MINT_PHASE public PHASE = MINT_PHASE.FIRST;

    constructor(string memory _baseUri, string memory _preRevealUri, uint256 _totalSupply) ERC721A("Tales of Dorin", "TOD") {
        setBaseURI(_baseUri);
        setPreRevealURI(_preRevealUri);
        setMaxSupply(_totalSupply);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /// set phase of the mint
    /// @param _phase phase to set
    function setPhase(MINT_PHASE _phase) public onlyOwner {
        PHASE = _phase;
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to withdraw Ether");
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficient balance");
        _withdraw(msg.sender, balance);
    }

    function withdrawAmount(address to, uint256 amount) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficient balance");
        require(amount <= balance, "Insufficient balance");
        _withdraw(to, balance);
    }

    function setPublicPrice(uint256 _newPrice) public onlyOwner {
        PUBLIC_PRICE = _newPrice * (1 ether);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();

        if (REVEALED) {
            return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), '.json')) : '';
        }

        return PRE_REVEAL_URI;
    }


    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        BASE_URI = _baseTokenURI;
    }
    function setPreRevealURI(string memory _preRevealTokenURI) public onlyOwner {
        PRE_REVEAL_URI = _preRevealTokenURI;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        MAX_SUPPLY = _maxSupply;
    }

    function setMintStarted(bool _mintStarted) public onlyOwner {
        MINT_STARTED = _mintStarted;
    }

    function setRevealed(bool _revealed) public onlyOwner {
        REVEALED = _revealed;
    }

    // Add new addresses to whitelist for a phase
    function addToWhitelist(MINT_PHASE _mintPhase, address[] memory _whitelistedAddresses) external onlyOwner {
        require(_mintPhase == MINT_PHASE.FIRST || _mintPhase == MINT_PHASE.SECOND, "Invalid mint phase");

        if (_mintPhase == MINT_PHASE.FIRST) {
            for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
                phase1FreeMintAllowed[_whitelistedAddresses[i]] = true;
                phase1PaidMintQuota[_whitelistedAddresses[i]] = 2;
            }
        }

    }


    struct MintCountAllowed {
        uint256 free;
        uint256 paid;
    }

    /// get allowance of a user at any phase of the mint
    /// @param _user user to get allowance for
    function getMintCountAllowedForAddress(address _user) public view returns (MintCountAllowed memory) {
        if (PHASE == MINT_PHASE.FIRST) {
            return MintCountAllowed(phase1FreeMintAllowed[_user] ? 1 : 0, phase1PaidMintQuota[_user]);
        } else if (PHASE == MINT_PHASE.SECOND) {
            return MintCountAllowed(phase2FreeMinted[_user] ? 0 : 1, 2 - phase2PaidMinted[_user]);
        } else {
            return MintCountAllowed(0, MAX_ALLOWED_IN_PHASE_3 - phase3TotalMinted[_user]);
        }
    }

    function _mintPhase1(address user, uint256 amount, uint256 ethPaid) internal {
        require(amount <= (phase1FreeMintAllowed[user] ? 1 : 0) + phase1PaidMintQuota[user],
            "You have reached your max mint quota, please try minting lesser number of tokens");

        uint256 payableTokensCount = amount - (phase1FreeMintAllowed[user] ? 1 : 0);
        uint256 amountPayable = payableTokensCount * PUBLIC_PRICE;

        require(ethPaid >= amountPayable, "Amount paid is lesser than required amount");

        _safeMint(user, amount);

        phase1FreeMintAllowed[user] = false;
        phase1PaidMintQuota[user] -= payableTokensCount;
    }

    // phase 2 mint
    function _mintPhase2(address user, uint256 amount, uint256 ethPaid) internal {
        require(amount + (phase2FreeMinted[user] ? 1 : 0) + phase2PaidMinted[user] <= 3,
            "You have reached your max mint quota, please try minting lesser number of tokens");

        uint256 payableTokensCount = amount - (phase2FreeMinted[user] ? 0 : 1);
        uint256 amountPayable = payableTokensCount * PUBLIC_PRICE;

        require(ethPaid >= amountPayable, "Amount paid is lesser than required amount");

        _safeMint(user, amount);

        phase2FreeMinted[user] = true;
        phase2PaidMinted[user] += payableTokensCount;
    }

    // phase 3 mint
    function _mintPhase3(address user, uint256 amount, uint256 ethPaid) internal {
        require(phase3TotalMinted[user] + amount <= MAX_ALLOWED_IN_PHASE_3,
            "You have reached your max mint quota, please try minting lesser number of tokens");

        require(ethPaid >= amount * PUBLIC_PRICE, "Amount paid is lesser than required amount");

        _safeMint(user, amount);

        phase3TotalMinted[user] += amount;
    }

    // mint tokens
    function mint(uint256 amount) external payable callerIsUser returns (bool success) {
        require(amount > 0, "You have to mint at least 1 token");
        require(MINT_STARTED, "Minting has not started yet");
        require(_totalMinted() + amount <= MAX_SUPPLY,
            "Total supply reached, please try minting lesser number of tokens");

        if (PHASE == MINT_PHASE.FIRST) {
            _mintPhase1(msg.sender, amount, msg.value);
        } else if (PHASE == MINT_PHASE.SECOND) {
            _mintPhase2(msg.sender, amount, msg.value);
        } else if (PHASE == MINT_PHASE.THIRD) {
            _mintPhase3(msg.sender, amount, msg.value);
        }

        success = true;
    }

    // owner mint tokens
    function ownerMint(address to, uint256 tokens) external onlyOwner {
        require(totalSupply() + tokens <= MAX_SUPPLY, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");

        _safeMint(to, tokens);
    }
}