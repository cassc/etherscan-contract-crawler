// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/ILootBox.sol";
import "./interfaces/IManagement.sol";
import "./interfaces/IMicrophoneNFT.sol";

contract LootBox is ILootBox, ERC721 {
    using Counters for Counters.Counter;
    uint256 internal constant TOTAL_RARITIES = 5; // [0 (Bronze), 1 (Silver), 2 (Gold), 3 (Platinum), 4 (Diamond)]
    uint256 internal constant TOTAL_TYPES = 4; // [0 (Beginner), 1 (Cover), 2 (Riser), 3 (Master)]
    /**
        @dev Probability of unboxed MicNFT 
            - Key   : box_rarity_index * TOTAL_RARITIES + mic_rarity_index
            - Value : p-value * 100     (if p = 25% then Value = 25)
     */
    mapping(uint256 => uint256) public classDropRates;
    mapping(uint8 => mapping(uint8 => uint256[])) public kindDropRates;

    IManagement public management;

    Counters.Counter private nextId;
    string private baseTokenURI;

    modifier onlyAdmin() {
        require(_msgSender() == management.admin(), "Unauthorized: Admin only");
        _;
    }

    modifier AddressZero(address _addr) {
        require(_addr != address(0), "Set address to zero");
        _;
    }

    event NewBox(address indexed owner, uint256 lootBoxId, uint8 rarity);
    event OpenedBox(
        address indexed owner,
        uint256 lootBoxId,
        uint256 microphoneId
    );

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _management
    ) ERC721(_name, _symbol) AddressZero(_management) {
        baseTokenURI = _uri;

        // nextId is initialized to 1, since starting at 0 leads to higher gas cost for the first minter
        nextId.increment();

        classDropRates[0] = 97; // box = 0 (Bronze) , mic = 0 (Bronze)
        classDropRates[1] = 3; // box = 0 (Bronze) , mic = 1 (Silver)
        // classDropRates[2] = 0;  // box = 0 (Bronze) , mic = 2 (Gold)
        // classDropRates[3] = 0;  // box = 0 (Bronze) , mic = 3 (Diamond)
        // classDropRates[4] = 0;  // box = 0 (Bronze) , mic = 4 (Platinum)
        classDropRates[5] = 25; // box = 1 (Silver) , mic = 0 (Bronze)
        classDropRates[6] = 73; // box = 1 (Silver) , mic = 1 (Silver)
        classDropRates[7] = 2; // box = 1 (Silver) , mic = 2 (Gold)
        // classDropRates[8] = 0;  // box = 1 (Silver) , mic = 3 (Diamond)
        // classDropRates[9] = 0;  // box = 1 (Silver) , mic = 4 (Platinum)
        // classDropRates[10] = 0; // box = 2 (Gold) , mic = 0 (Bronze)
        classDropRates[11] = 27; // box = 2 (Gold) , mic = 1 (Silver)
        classDropRates[12] = 71; // box = 2 (Gold) , mic = 2 (Gold)
        classDropRates[13] = 2; // box = 2 (Gold) , mic = 3 (Diamond)
        // classDropRates[14] = 0; // box = 2 (Gold) , mic = 4 (Platinum)
        // classDropRates[15] = 0; // box = 3 (Diamond) , mic = 0 (Bronze)
        // classDropRates[16] = 0; // box = 3 (Diamond) , mic = 1 (Silver)
        classDropRates[17] = 30; // box = 3 (Diamond) , mic = 2 (Gold)
        classDropRates[18] = 68; // box = 3 (Diamond) , mic = 3 (Diamond)
        classDropRates[19] = 2; // box = 3 (Diamond) , mic = 4 (Platinum)
        // classDropRates[20] = 0; // box = 4 (Platinum) , mic = 0 (Bronze)
        // classDropRates[21] = 0; // box = 4 (Platinum) , mic = 1 (Silver)
        // classDropRates[22] = 0; // box = 4 (Platinum) , mic = 2 (Gold)
        classDropRates[23] = 35; // box = 4 (Platinum) , mic = 3 (Diamond)
        classDropRates[24] = 65; // box = 4 (Platinum) , mic = 3 (Platinum)

        kindDropRates[0][0] = [100, 0, 0, 0];
        kindDropRates[0][1] = [100, 0, 0, 0];
        kindDropRates[0][2] = [100, 0, 0, 0];
        kindDropRates[0][3] = [100, 0, 0, 0];
        kindDropRates[1][1] = [100, 0, 0, 0];
        kindDropRates[1][2] = [100, 0, 0, 0];
        kindDropRates[1][3] = [100, 0, 0, 0];
        kindDropRates[2][2] = [100, 0, 0, 0];
        kindDropRates[2][3] = [100, 0, 0, 0];
        kindDropRates[3][3] = [100, 0, 0, 0];

        management = IManagement(_management);
    }

    /**
        @notice Update new management
        @param _newManagement address of new management
        @dev Caller must be ADMIN
     */
    function updateManagement(address _newManagement)
        external
        AddressZero(_newManagement)
        onlyAdmin
    {
        management = IManagement(_newManagement);
    }

    /**
        @dev Update drop rate for mic classes from unboxing
        @notice Caller must be ADMIN
        @param _boxRarity Box rarity
        @param _microphoneClass Microphone class
        @param _dropRate Drop rate/probability
     */
    function updateClassDropRate(
        uint8 _boxRarity,
        uint8 _microphoneClass,
        uint256 _dropRate
    ) external onlyAdmin {
        // max class index is 2 (gold)
        classDropRates[
            _boxRarity * TOTAL_RARITIES + _microphoneClass
        ] = _dropRate;
    }

    /**
        @dev Update drop rate for mic breeding
        @notice Caller must be ADMIN
        @param _typeCol1 type of matron
        @param _typeCol2 type of sire
        @param _dropRates drop rate/probabilities
     */
    function updateKindDropRates(
        uint8 _typeCol1,
        uint8 _typeCol2,
        uint256[] calldata _dropRates
    ) external onlyAdmin {
        require(_dropRates.length == TOTAL_TYPES, "Invalid drop rates length");
        require(_typeCol1 <= _typeCol2, "Invalid column indexes");

        uint256 n = _dropRates.length;
        uint256 sum;
        uint256 val;
        for (uint256 i; i < n; i++) {
            val = _dropRates[i];
            if (val > 0) sum += val;
        }
        require(sum == 100, "Sum of dropRates must be 100");

        kindDropRates[_typeCol1][_typeCol2] = _dropRates;
    }

    /**
        @dev Mints a token to an address with a tokenURI.
        @param _to address of the future owner of the token
        @param _rarity lootbox rarity = [0 (Bronze), 1 (Silver), 2 (Gold), 3 (Diamond), 4 (Platinum)]
        @param _matronType matron microphone type
        @param _sireType sire microphone type
     */
    function mint(
        address _to,
        uint8 _rarity,
        uint8 _matronType,
        uint8 _sireType
    ) external {
        require(
            _msgSender() == management.breeding() || _msgSender() == management.minter(),
            "Unauthorized: Breeding contract or minter only" 
        );
        uint256 currentTokenId = (nextId.current() << 5) | _rarity;
        currentTokenId =
            (((currentTokenId << 5) | _matronType) << 5) |
            _sireType;

        nextId.increment();

        _safeMint(_to, currentTokenId);

        emit NewBox(_to, currentTokenId, _rarity);
    }

    /**
        @dev Returns the total tokens minted so far.
            1 is always subtracted from the Counter since it tracks the next available tokenId.
     */
    function totalSupply() public view returns (uint256) {
        return nextId.current() - 1;
    }

    function setBaseURI(string memory _uri) external onlyAdmin {
        baseTokenURI = _uri;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }

    function unbox(uint256 _tokenId) external {
        // solhint-disable-next-line
        require(tx.origin == msg.sender, "Only non-contract call");

        address msgSender = _msgSender();
        require(ownerOf(_tokenId) == msgSender, "Caller must own the box");

        (uint8 body, uint8 head, uint8 kind, uint8 class) = _generateMicro(
            _tokenId
        );

        uint256 microphoneId = IMicrophoneNFT(management.microphoneNFT()).mint(
            body,
            head,
            kind,
            class,
            msgSender
        );

        // Burn the looted box
        _burn(_tokenId);

        emit OpenedBox(msgSender, _tokenId, microphoneId);
    }

    function _generateMicro(uint256 _tokenId)
        private
        returns (
            uint8 _body,
            uint8 _head,
            uint8 _kinds,
            uint8 _class
        )
    {
        uint256 random = management.getRandom();
        uint256 value = random % 100;
        uint256 boxRarity = _sliceNumber(_tokenId, 5, 10);

        for (uint256 i = 0; i < TOTAL_RARITIES; i++) {
            uint256 probability = classDropRates[
                boxRarity * TOTAL_RARITIES + i
            ];
            if (value < probability) {
                _class = uint8(i);
                break;
            } else {
                value -= probability;
            }
        }

        random = random >> 8;
        value = random % 100;

        uint8 _matronType = _sliceNumber(_tokenId, 5, 5);
        uint8 _sireType = uint8(_tokenId & 31); // _sliceNumber(_tokenId, 5, 0);

        if (_matronType > _sireType) {
            uint8 temp = _matronType;
            _matronType = _sireType;
            _sireType = temp;
        }

        uint256[] memory probabilities = kindDropRates[_matronType][_sireType];
        for (uint256 i = 0; i < TOTAL_TYPES; i++) {
            if (value < probabilities[i]) {
                _kinds = uint8(i);
                break;
            } else {
                value -= probabilities[i];
            }
        }

        _body = uint8(random % 7);
        _head = uint8((random >> 8) % 7);
    }

    /**
        @dev given a number get a slice of any bits, at certain offset
        @param _n a number to be sliced
        @param _nbits how many bits long is the new number
        @param _offset how many bits to skip
     */
    function _sliceNumber(
        uint256 _n,
        uint256 _nbits,
        uint256 _offset
    ) private pure returns (uint8) {
        // mask is made by shifting left an offset number of times
        uint256 mask = uint256((2**_nbits) - 1) << _offset;
        // AND n with mask, and trim to max of _nbits bits
        return uint8((_n & mask) >> _offset);
    }
}