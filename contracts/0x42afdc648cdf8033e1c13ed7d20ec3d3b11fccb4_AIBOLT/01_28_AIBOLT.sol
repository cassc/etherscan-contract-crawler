// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AIORBIT.sol";
import "./BoltLib.sol";
import "./IEventNFT.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {Base64} from "./Base64.sol";

contract AIBOLT is ERC721A, Ownable, IERC2981, ReentrancyGuard, Pausable {
    address public eventsNFT;

    address payable public royaltiesRecipient;
    uint256 public royaltyRate = 75; // Default 7.5% royalty rate
    uint16 public constant AIORBIT_PER_AIBOLT = 5;

    AIORBIT public aiorbit;

    mapping(uint16 => uint256[]) public tokenIdToEvents;
    mapping(uint16 => uint16[AIORBIT_PER_AIBOLT]) public _aiorbitPerAibolt;

    uint256 public tokenPrice;
    mapping(address => bool) public allowList;

    event TokenEventAdded(
        uint16 indexed tokenId,
        uint256 indexed eventId,
        address indexed originalCaller
    );

    event TokenForged(uint16[] indexed tokenIds, uint16[] indexed _aiorbitIds);

    modifier onlyEventNFT() {
        require(
            msg.sender == eventsNFT,
            "Only EventNFT can call this function"
        );
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address payable _royaltiesRecipient,
        address _eventsNFT,
        AIORBIT _aiorbit,
        uint256 _tokenPrice
    ) ERC721A(name, symbol) {
        royaltiesRecipient = _royaltiesRecipient;
        aiorbit = _aiorbit;
        eventsNFT = _eventsNFT;
        tokenPrice = _tokenPrice;
        pause();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setEventNFT(address _eventsNFT) public onlyOwner {
        eventsNFT = _eventsNFT;
    }

    function setTokenPrice(uint256 _tokenPrice) public onlyOwner {
        tokenPrice = _tokenPrice;
    }

    // Mint function for owner to airdrop tokens
    function airdrop(
        address[] memory recipients,
        uint8[] memory howMany
    ) public onlyOwner {
        unchecked {
            for (uint16 i = 0; i < recipients.length; i++) {
                _mint(recipients[i], howMany[i]);
            }
        }
    }

    // New mint function for users to purchase token
    function mint(uint8 howMany) public payable nonReentrant whenNotPaused {
        require(
            totalSupply() + howMany <= 2000,
            "Maximum supply of 2,000 reached"
        );
        require(
            balanceOf(msg.sender) + howMany <= 5,
            "Cannot exceed mint limit of 5 per wallet"
        );
        require(allowList[msg.sender], "Not on the allow list");
        require(msg.value == tokenPrice * howMany, "Incorrect payment value");
        _mint(msg.sender, howMany);

        // Transfer the ether to the contract's owner
        payable(owner()).transfer(msg.value);
    }

    function addToAllowList(address[] memory addrs) public onlyOwner {
        for (uint i = 0; i < addrs.length; i++) {
            allowList[addrs[i]] = true;
        }
    }

    function removeFromAllowList(address[] memory addrs) public onlyOwner {
        for (uint i = 0; i < addrs.length; i++) {
            allowList[addrs[i]] = false;
        }
    }

    function forge(
        uint16[] memory tokenIds,
        uint16[] memory _aiorbitIds
    ) public {
        require(
            _aiorbitIds.length % AIORBIT_PER_AIBOLT == 0,
            "Incorrect number of AIORBIT IDs provided"
        );
        require(
            tokenIds.length * AIORBIT_PER_AIBOLT == _aiorbitIds.length,
            "Mismatch between number of tokens and aiorbits"
        );

        uint16 aiorbitIndex = 0;
        for (uint16 k = 0; k < tokenIds.length; k++) {
            uint16 tokenId = tokenIds[k];
            require(
                ownerOf(tokenId) == msg.sender,
                "Caller must own the AIBOLT"
            );

            uint16[AIORBIT_PER_AIBOLT] memory aiorbitIdsForToken;

            for (uint16 j = 0; j < AIORBIT_PER_AIBOLT; j++) {
                uint16 aiorbitId = _aiorbitIds[aiorbitIndex + j];
                require(
                    aiorbit.ownerOf(aiorbitId) == msg.sender,
                    "Caller must own the AIORBITs"
                );
                aiorbitIdsForToken[j] = aiorbitId;
                aiorbit.transferFrom(
                    msg.sender,
                    0x000000000000000000000000000000000000dEaD,
                    aiorbitId
                );
            }

            _aiorbitPerAibolt[tokenId] = aiorbitIdsForToken;
            tokenIdToEvents[tokenId].push(1); // Event #1: Inception (Reveal)
            aiorbitIndex += AIORBIT_PER_AIBOLT;
        }

        emit TokenForged(tokenIds, _aiorbitIds);
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist");

        IEventNFT eventNFT = IEventNFT(eventsNFT);
        uint256[] memory tokenEvents = tokenIdToEvents[uint16(_tokenId)];
        uint256 tokenEventsLength = tokenEvents.length;
        uint16[AIORBIT_PER_AIBOLT] memory _aiorbitTokenIds = [
            uint16(1),
            uint16(1),
            uint16(1),
            uint16(1),
            uint16(1)
        ];

        // Revealed
        if (tokenEventsLength != 0) {
            _aiorbitTokenIds = _aiorbitPerAibolt[uint16(_tokenId)];
        }

        BoltLib.AIBOLTData memory data = BoltLib.generateAIBOLTData(
            _aiorbitTokenIds
        );

        if (tokenEvents.length > 0) {
            data = getLatestEventData(data, tokenEvents[tokenEventsLength - 1]);
        }

        string memory svg = BoltLib.generateSVG(data, tokenEvents, eventNFT);

        // Generate traits JSON string
        string memory traits = BoltLib.generateTraits(
            data,
            tokenEvents,
            eventNFT
        );

        // Combine all parts to create the final JSON string
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "AIBOLT #',
                        toString(_tokenId),
                        '", "description": "The first ever dynamic on-chain storytelling NFTs. Every AIBOLT is fully on-chain, and their traits (visually and rarity) are upgradeable by causing Events. Events are transactions recorded on-chain. When chain of Events are stacked, a lore is written by AI that can be adapted to other mediums.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),
                        '", "attributes": ',
                        traits,
                        "}"
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function getLatestEventData(
        BoltLib.AIBOLTData memory data,
        uint256 latestEventId
    ) public view returns (BoltLib.AIBOLTData memory) {
        IEventNFT.Event memory eventNFT = IEventNFT(eventsNFT).getEvent(
            latestEventId
        );

        if (bytes(eventNFT.sun).length != 0) {
            data.sun = eventNFT.sun;
            data.sunSvg = eventNFT.sunSvg;
        }

        if (bytes(eventNFT.planet1).length != 0) {
            data.planets[0].theme = eventNFT.planet1;
            data.planets[0].svg = eventNFT.planet1Svg;
        }

        if (bytes(eventNFT.planet2).length != 0) {
            data.planets[1].theme = eventNFT.planet2;
            data.planets[1].svg = eventNFT.planet2Svg;
        }

        if (bytes(eventNFT.planet3).length != 0) {
            data.planets[2].theme = eventNFT.planet3;
            data.planets[2].svg = eventNFT.planet3Svg;
        }

        if (eventNFT.numPlanets != 0) {
            data.numPlanets = eventNFT.numPlanets;
        }

        return data;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, IERC165) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId);
    }

    function addTokenEvent(
        uint16 tokenId,
        uint256 eventId,
        address originalCaller
    ) public onlyEventNFT {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        require(
            ownerOf(tokenId) == originalCaller,
            "Caller must own the AIBOLT"
        );
        require(msg.sender == eventsNFT, "Not authorized Event contract");
        tokenIdToEvents[tokenId].push(eventId);

        emit TokenEventAdded(tokenId, eventId, originalCaller);
    }

    // Override royaltyInfo function from EIP-2981
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        return (royaltiesRecipient, (_salePrice * royaltyRate) / 1000);
    }
}