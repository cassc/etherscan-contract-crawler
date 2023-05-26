// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./PaymentHandler.sol";

contract Samurai2088 is ERC721Enumerable, Ownable, PaymentHandler {
    using Counters for Counters.Counter;

    uint256 public constant PRICE = 0.1 ether;
    uint256 public constant MAX_PER_ADDRESS = 10;
    uint256 public immutable maxElements;
    mapping(address => uint256) public mintCount;
    mapping(uint256 => string) public specialTokenURIs;
    string public baseURI;
    Counters.Counter private _tokenCounter;
    address private immutable _ticketSigningAddress;

    enum MintState {
        CLOSED,
        PRESALE,
        PUBLIC
    }
    MintState public mintState;

    event SamuraiBorn(address indexed minter, uint256 indexed tokenId);
    event MintStateChanged(MintState newState);

    constructor(
        string memory baseURI_,
        uint256 maxElements_,
        address ticketSigningAddress,
        address payable[] memory payees_,
        uint256[] memory shares_
    ) ERC721("Samurai2088", "SA88") PaymentHandler(payees_, shares_) {
        maxElements = maxElements_;
        _ticketSigningAddress = ticketSigningAddress;
        setMintState(MintState.CLOSED);
        setBaseURI(baseURI_);
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setSpecialTokenURI(uint256 tokenId, string memory uri)
        external
        onlyOwner
    {
        specialTokenURIs[tokenId] = uri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory specialURI = specialTokenURIs[tokenId];
        if (bytes(specialURI).length > 0) {
            return specialURI;
        }
        return super.tokenURI(tokenId);
    }

    function setMintState(MintState newState) public onlyOwner {
        mintState = newState;
        emit MintStateChanged(newState);
    }

    function totalToken() public view returns (uint256) {
        return _tokenCounter.current();
    }

    function reserveSamurais(uint256 legendaryCount, address communityAddress)
        public
        onlyOwner
    {
        require(
            _tokenCounter.current() == 0,
            "Can only reserve the first samurais"
        );
        require(legendaryCount <= maxElements, "Too many legendary Samurai");
        // Legendaries
        _unsafeMint(communityAddress, legendaryCount);
        // Team
        _unsafeMint(0x08df486d3646f54bd33785b0D88b0b1592A3F6CE, 1); // Laurent
        _unsafeMint(0x9710739368b6d14dD2cAc5F3095Dd41fCE8Ff8Bf, 1); // Clement
        _unsafeMint(0x242B0785ee336d8fB396DB1feF4FF012b61fCE58, 1); // JB
        _unsafeMint(0x0d04f850574a99f82f80E0c9469250958E94Ff20, 2); // Devs
        _unsafeMint(0x2Ce9355F1921A75039f2648815193D0387741A8d, 1); // Adrien
        _unsafeMint(0xaCF32962799138c871c7d97492164303Dd9aFA08, 1); // Manu
        // VIPs
        _unsafeMint(0x8DcF566147328955CD8cC7777356a531b0ca50a9, 1);
        _unsafeMint(0xc02e9Dd402E3c03AE4Cbc7B8a652ab5F465EC37F, 1);
        _unsafeMint(0xC7908024586487712bdCF5c5a067AAa7b1A1f936, 1);
        _unsafeMint(0x16182C7F8588F723c53460E2Cafe88EcE2AB65dd, 1);
        _unsafeMint(0x45f5c437E59e40a76878D5732Cc3BF5b269C7FE8, 1);
        _unsafeMint(0x6457A438e924EEeb2aA14C254db044bf774b62Eb, 1);
        _unsafeMint(0x4322d50b13433Df82104C87992Ea251194624B69, 1);
        _unsafeMint(0x21e34789AD22c8f18665B2b6463BdD1ac211f7f1, 1);
        _unsafeMint(0x322B00D7a6b2Fcd873c9F3154A1C00e4FC0967cD, 1);
        _unsafeMint(0x8411a8ba27D7F582c2860758BF2F901B851c30D3, 1);
        _unsafeMint(0x6E01Ca5a433B58FDDCf3824E2E54240bBf52D890, 1);
        _unsafeMint(0x345ba3AA3D0F67EAE88397C419879F403642DF25, 1);
        _unsafeMint(0xa5809BC8BF14B4b20A0d45B56843E9B2c1Ca6166, 1);
        _unsafeMint(0x8FfA96BE04321Cf59AFb16CEE515C9ff90fAF4d7, 1);
        _unsafeMint(0xBEbe0c09065c3221bC854a46AD537350523f2410, 1);
        _unsafeMint(0x26b8F9213F782F9eE159F86d1E256DE59de4FDA2, 1);
        _unsafeMint(0xbeB142Bf66640417d001DC11cfF5a7006679013B, 1);
    }

    function preSaleMint(
        bytes memory ticketSignature,
        uint8 ticketAllowance,
        uint256 count
    ) external payable {
        require(
            mintState == MintState.PRESALE,
            "Only available during presale"
        );
        address sender = _msgSender();
        bytes memory encodedData = abi.encode(sender, ticketAllowance);
        bytes32 digest = ECDSA.toEthSignedMessageHash(keccak256(encodedData));
        address recoveredAddress = ECDSA.recover(digest, ticketSignature);
        require(recoveredAddress == _ticketSigningAddress, "Invalid signature");
        _requireValidCountAndPrice(sender, count, ticketAllowance);
        _unsafeMint(sender, count);
    }

    function mint(uint256 count) external payable {
        require(
            mintState == MintState.PUBLIC,
            "Only available during the public sale"
        );
        address sender = _msgSender();
        _requireValidCountAndPrice(sender, count, MAX_PER_ADDRESS);
        _unsafeMint(sender, count);
    }

    function _requireValidCountAndPrice(
        address sender,
        uint256 count,
        uint256 allowance
    ) private view {
        require(count > 0, "Count must be greater than 0");
        uint256 alreadyMinted = mintCount[sender];
        require(
            alreadyMinted + count <= allowance,
            "Address not allowed to mint that many Samurais"
        );
        require(
            totalToken() + count <= maxElements,
            "Not enough Samurais left to mint"
        );
        require(msg.value >= PRICE * count, "Price not met");
    }

    function _unsafeMint(address _to, uint256 _count) private {
        mintCount[_to] += _count;
        for (uint256 i = 0; i < _count; i++) {
            _tokenCounter.increment();
            uint256 tokenId = _tokenCounter.current();
            _safeMint(_to, tokenId);
            emit SamuraiBorn(_to, tokenId);
        }
    }
}