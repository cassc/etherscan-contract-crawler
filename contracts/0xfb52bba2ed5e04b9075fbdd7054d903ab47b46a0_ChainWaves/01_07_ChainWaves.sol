// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/tokens/ERC721.sol";
import "solmate/auth/Owned.sol";
import "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import "./AnonymiceLibrary.sol";
import "./ChainWavesGenerator.sol";
import "./ChainWavesErrors.sol";

contract ChainWaves is ChainWavesErrors, ERC721, Owned {
    using AnonymiceLibrary for uint8;

    struct Trait {
        string traitName;
        string traitType;
    }

    uint256 public constant MAX_SUPPLY = 512;
    uint256 public constant MINT_PRICE = 0.0256 ether;
    uint256 public constant MINT_START = 1674156600;
    uint256 public constant MAX_MINT = 3;
    uint256 public snowcrashReserve = 120;
    bool public MINTING_LIVE;

    uint256 public totalSupply;

    // TODO: generate actual root (this is folded faces)
    bytes32 constant snowcrashRoot =
        0xea35e50958ff75fe96e04a6dd792de75a26dd0c2a2d12e8a4c485d938961eb39;

    bool private freeMinted;

    mapping(address => uint256) mintInfo;
    mapping(uint256 => uint256) tokenIdToHash;
    mapping(uint256 => Trait[]) public traitTypes;

    //Mappings

    ChainWavesGenerator chainWavesGenerator;

    //uint arrays
    uint16[][6] private TIERS;

    constructor()
        ERC721("ChainWaves", "CA")
        Owned(0xB6eE8B1899e4cad7e28015995B82969e44BD0bb0)
    {
        chainWavesGenerator = new ChainWavesGenerator();

        //Palette
        TIERS[0] = [1000, 1500, 1400, 1700, 1200, 400, 400, 1600, 800];
        //Noise
        TIERS[1] = [1000, 4000, 4000, 1000];
        //Speed
        TIERS[2] = [1000, 4000, 4000, 1000];
        //Char set
        TIERS[3] = [2250, 2250, 2250, 2250, 600, 400];
        //Detail
        TIERS[4] = [1000, 6000, 3000];
        //NumCols
        TIERS[5] = [800, 6200, 2600, 400];
    }

    //prevents someone calling read functions the same block they mint
    modifier disallowIfStateIsChanging() {
        if ((mintInfo[msg.sender] >> 8) == block.number) revert Stap();
        _;
    }

    /**
     * @dev Converts a digit from 0 - 10000 into its corresponding rarity based on the given rarity tier.
     * @param _randinput The input from 0 - 10000 to use for rarity gen.
     * @param _rarityTier The tier to use.
     */
    function rarityGen(uint256 _randinput, uint8 _rarityTier)
        internal
        view
        returns (uint8)
    {
        uint16 currentLowerBound;
        uint256 tiersLength = TIERS[_rarityTier].length;
        for (uint8 i; i < tiersLength; ++i) {
            uint16 thisPercentage = TIERS[_rarityTier][i];
            if (
                _randinput >= currentLowerBound &&
                _randinput < currentLowerBound + thisPercentage
            ) return i;
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        revert();
    }

    /**
     * @param _a The address to be used within the hash.
     */
    function hash(address _a, uint256 _tokenId)
        internal
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        _a,
                        _tokenId
                    )
                )
            );
    }

    function normieMint(uint256 _amount) external payable {
        if (_amount > MAX_MINT) revert MaxThree();
        if (msg.value != MINT_PRICE * _amount) revert MintPrice();

        uint256 minterInfo = mintInfo[msg.sender];
        if ((minterInfo & 0xF) != 0) revert PublicMinted();

        minterInfo |= 1;
        minterInfo = (minterInfo & 0xFF) + (block.number << 8);
        mintInfo[msg.sender] = minterInfo;

        mintInternal(msg.sender, _amount);
    }

    // TODO: add merkle root,
    function snowcrashMint(bytes32[] calldata merkleProof) external payable {
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, snowcrashRoot, node),
            "Not on WL"
        );
        if (msg.value != MINT_PRICE) revert MintPrice();

        uint256 minterInfo = mintInfo[msg.sender];
        if (((minterInfo & 0xF0) >> 4) != 0) revert SnowcrashMinted();
        if (snowcrashReserve == 0) revert ReserveClosed();
        --snowcrashReserve;

        minterInfo |= (1 << 4);
        minterInfo = (minterInfo & 0xFF) + (block.number << 8);
        mintInfo[msg.sender] = minterInfo;

        mintInternal(msg.sender, 1);
    }

    function freeMints(
        address[] calldata _addresses,
        uint256[] calldata _amount
    ) external payable onlyOwner {
        if (freeMinted) revert FreeMintDone();
        uint256 addressesLength = _addresses.length;
        if (addressesLength != _amount.length) revert ArrayLengths();
        for (uint256 i; i < addressesLength; ++i) {
            mintInternal(_addresses[i], _amount[i]);
        }

        freeMinted = true;
    }

    function mintInternal(address _to, uint256 _amount) internal {
        if (!MINTING_LIVE || block.timestamp < MINT_START) revert NotLive();
        if (_amount == 0) revert MintZero();
        if (totalSupply + _amount + snowcrashReserve > MAX_SUPPLY)
            revert SoldOut();
        uint256 nextTokenId = totalSupply;
        uint256 newTotalSupply = totalSupply + _amount;

        for (; nextTokenId < newTotalSupply; ++nextTokenId) {
            tokenIdToHash[nextTokenId] = hash(_to, nextTokenId);
            _mint(_to, nextTokenId);
        }
        totalSupply = newTotalSupply;
    }

    // hash stuff

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     * From anonymice
     */

    function buildHash(uint256 _t) internal view returns (string memory) {
        // This will generate a 4 character string.
        string memory currentHash = "";
        uint256 tokenHash = tokenIdToHash[_t];

        for (uint8 i; i < 6; ++i) {
            uint16 _randinput = uint16(
                uint256(keccak256(abi.encodePacked(tokenHash, i))) % 10000
            );
            currentHash = string(
                abi.encodePacked(
                    currentHash,
                    rarityGen(_randinput, i).toString()
                )
            );
        }
        return currentHash;
    }

    // Views

    function hashToMetadata(string memory _hash)
        public
        view
        disallowIfStateIsChanging
        returns (string memory)
    {
        string memory metadataString;

        for (uint8 i; i < 6; ++i) {
            uint8 thisTraitIndex = AnonymiceLibrary.parseInt(
                AnonymiceLibrary.substring(_hash, i, i + 1)
            );

            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    '{"trait_type":"',
                    traitTypes[i][thisTraitIndex].traitType,
                    '","value":"',
                    traitTypes[i][thisTraitIndex].traitName,
                    '"}'
                )
            );

            if (i != 5)
                metadataString = string(abi.encodePacked(metadataString, ","));
        }

        return string(abi.encodePacked("[", metadataString, "]"));
    }

    function _tokenIdToHash(uint256 _tokenId)
        public
        view
        disallowIfStateIsChanging
        returns (string memory tokenHash)
    {
        if (_tokenId >= totalSupply) revert NonExistantId();
        tokenHash = buildHash(_tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory _URI)
    {
        if (_tokenId >= totalSupply) revert NonExistantId();
        string memory _hash = _tokenIdToHash(_tokenId);
        _URI = string(
            abi.encodePacked(
                "data:application/json;base64,",
                AnonymiceLibrary.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "CH41NW4V35 #',
                                AnonymiceLibrary.toString(_tokenId),
                                '","description": "Fully onchain generative art SVG collection. Created by McToady & Circolors."',
                                ',"image": "data:image/svg+xml;base64,',
                                AnonymiceLibrary.encode(
                                    bytes(
                                        abi.encodePacked(
                                            "<svg viewBox='0 0 20 20' width='600' height='600' xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMidYMin'><rect width='20' height='20' fill='#",
                                            chainWavesGenerator.buildSVG(
                                                _tokenId,
                                                _hash
                                            ),
                                            "</svg>"
                                        )
                                    )
                                ),
                                '","attributes":',
                                hashToMetadata(_hash),
                                "}"
                            )
                        )
                    )
                )
            )
        );
    }

    // Owner Functions
    /**
     * @dev Add a trait type
     * @param _traitTypeIndex The trait type index
     * @param traits Array of traits to add
     */

    function addTraitType(uint256 _traitTypeIndex, Trait[] memory traits)
        external
        payable
        onlyOwner
    {
        for (uint256 i; i < traits.length; ++i) {
            traitTypes[_traitTypeIndex].push(
                Trait(traits[i].traitName, traits[i].traitType)
            );
        }

        return;
    }

    function flipMint() external payable onlyOwner {
        MINTING_LIVE = !MINTING_LIVE;
    }

    function withdraw() external payable onlyOwner {
        uint256 twelve = (address(this).balance / 100) * 12;
        uint256 eightythree = (address(this).balance / 100) * 83;
        uint256 five = (address(this).balance / 100) * 5;
        (bool sentI, ) = payable(
            address(0x4533d1F65906368ebfd61259dAee561DF3f3559D)
        ).call{value: twelve}("");
        if (!sentI) revert WithdrawFail();
        (bool sentC, ) = payable(
            address(0x888f8AA938dbb18b28bdD111fa4A0D3B8e10C871)
        ).call{value: five}("");
        if (!sentC) revert WithdrawFail();
        (bool sentT, ) = payable(
            address(0xE4260Df86f5261A41D19c2066f1Eb2Eb4F009e84)
        ).call{value: eightythree}("");
        if (!sentT) revert WithdrawFail();
    }

    function wipeSnowcrashReserve() external payable onlyOwner {
        snowcrashReserve = 0;
    }
}