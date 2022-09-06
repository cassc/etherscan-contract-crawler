// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin/access/Ownable.sol";
import "openzeppelin/interfaces/IERC2981.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/security/ReentrancyGuard.sol";
import "openzeppelin/utils/Strings.sol";

import "solmate/utils/FixedPointMathLib.sol";

import "./interfaces/ISSMintableNFT.sol";
import "./types/ERC721A.sol";

/*//////////////////////////////////////////////////////////////
                            ERRORS
//////////////////////////////////////////////////////////////*/

error PublicSaleNotActive();

error SenderNeedsToRestBetweenFarts();
error SenderHasFartedTooManyTimes();
error YouMustFartAtLeastOnceToCallThisFunction();
error TooManyFartsCauseGlobalWarming();
error FartsArentFree();
error FartGotLostInTheEther();

error NotPermissionedMinter();


error WithdrawTransferFailed();

contract Fartz is ISSMintableNFT, Ownable, ERC721A, IERC2981, ReentrancyGuard {
    /* ========== DEPENDENCIES ========== */
    using SafeERC20 for IERC20;
    using FixedPointMathLib for uint256;
    using Strings for uint256;

    /* ====== CONSTANTS ====== */

    uint64 public MAX_SUPPLY = 9_009;
    uint64 public MAX_MINT_QUANTITY = 5;
    uint64 public MAX_MINT_ALLOWANCE = 10;

    uint64 public PUBLIC_SALE_PRICE;

    address private _ssmw = address(0);

    // Owners
    address payable private immutable _owner1;
    address payable private immutable _dev;

    /* ====== VARIABLES ====== */

    string public DESCRIPTION = "We all know what you did... metadata & img fully on chain, forever.";

    mapping (uint256 => bytes32) private _registeredDisturbances;
    mapping (bytes32 => bool)    private _knownDisturbances;

    bool public isPublicSaleActive = false;    

    uint16[] private _raritiesSmell = [
        1_700,
        1_700,
        1_700,
        500,
        200,
        1_100,
        1_100,
        1_100,
        800,
        100
    ];
    uint16[] private _raritiesWetness = [
        1_500, 
        200, 
        1_200, 
        2_000, 
        1_000, 
        1_000, 
        100, 
        1_500, 
        1_500 
    ];
    uint16[] private _raritiesCuisine = [
        1_000,
        700,
        1_100,
        500,
        500,
        1_000,
        1_300,
        700,
        500,
        200,
        1_000,
        1_500
    ];
    uint16[] private _raritiesDuration = [
        3_500,
        3_800,
        2_500,
        200
    ];
    uint16[] private _raritiesMethane = [
        1_000,
        1_000,
        1_000,
        1_000,
        1_000,
        1_000,
        1_000,
        1_000,
        1_000,
        1_000,
        1_000,
        1_000
    ];
    uint16[] private _raritiesWithWho = [
        1_500,
        2_500,
        1_500,
        1_000,
        1_500,
        1_500,
        500
    ];
    uint16[] private _raritiesWhereAreYou = [
        1_000,
        500,
        1_000,
        1_000,
        500,
        200,
        1_000,
        1_300,
        1_200,
        1_000,
        300,
        1_000
    ];
    uint16[] private _raritiesIntentionality = [
        2_500,
        2_500,
        2_500,
        2_300,
        200
    ];
    uint16[] private _raritiesRelief = [
        2_800,
        200,
        2_000,
        3_000,
        2_000
    ];

    string[] private _traitsSmell = [
        "rotten eggs",
        "skunk",
        "kinda good",
        "dead animal",
        "surprisingly none",
        "diesel",
        "raw sewage",
        "rancid milk",
        "burning plastic",
        "sweet vanilla and cinnamon"
    ];
    string[] private _traitsWetness = [
        "a tropical one",
        "a full blown monsoon",
        "a greasy one",
        "a dry one",
        "you need new underwear",
        "a day ender",
        "you shat yourself",
        "it left skidmarks forsure",
        "you need to check"
    ];
    string[] private _traitsCuisine = [
        "juicy shawarma",
        "gas station sushi",
        "refried beans",
        "street meat",
        "beefy burrito",
        "flaming curry",
        "fried chicken",
        "spicy pad thai",
        "korean bbq",
        "uncle O's chili",
        "truffle mac & cheese",
        "general tso's chicken"
    ];
    string[] private _traitsDuration = [
        "short",
        "medium",
        "long",
        "impressively long"
    ];
    string[] private _traitsMethane = [
        "1ml",
        "2ml",
        "3ml",
        "50ml",
        "70ml",
        "11ml",
        "13ml",
        "17ml",
        "19ml",
        "23ml",
        "29ml",
        "31ml"
    ];
    string[] private _traitsWithWho = [
        "alone",
        "friends",
        "coworkers",
        "significant other",
        "a crowd of strangers",
        "grandparents",
        "a hot date"
    ];
    string[] private _traitsWhereAreYou = [
        "at the symphony",
        "on mars",
        "at a urinal",
        "on live tv",
        "in a submarine",
        "top of eiffel tower",
        "at a funeral",
        "in an elevator",
        "on a plane",
        "in a library",
        "asleep in bed",
        "in waiting room"
    ];
    string[] private _traitsIntentionality = [
        "knew it was coming",
        "out of the blue",
        "premeditated",
        "emergency release",
        "Pearl Harbor"
    ];
    string[] private _traitsRelief = [
        "more on the way",
        "orgasmic",
        "still in pain",
        "bloat not diminished",
        "gonna need the restroom"
    ];
    
    string private constant svgStart = '<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="1000" viewBox="0 0 1000 1000"><defs><style>.c,.d,.e{fill:#fff;}.f,.g,.h{fill:#5E993E;}.f,.e{letter-spacing:0em;}.d{font-size:31.58px;}.d,.i,.j{font-family:monospace;}.k,.j{fill:#914190;}.i,.j{font-size:27.82px;}.l{stroke:#fff;stroke-miterlimit:10;stroke-width:2px;}.l,.m{fill:#231f20;}.g{letter-spacing:0em;}</style></defs><g id="a"><rect class="m" width="1000" height="1000"/></g><g id="b"><rect class="l" x="52.05" y="125" width="900" height="750"/><text class="d" transform="translate(143.11 193.06)"><tspan x="0" y="0">*************</tspan><tspan x="0" y="37.9">* FARTZ.WTF *</tspan><tspan x="0" y="75.79">*************</tspan></text><text class="d" transform="translate(143.11 759.58)"><tspan x="0" y="0">****************************</tspan><tspan x="0" y="37.9">* MAY YOU BE ALWAYS UPWIND *</tspan><tspan x="0" y="75.79">****************************</tspan></text><text class="i" transform="translate(143.11 338.43)"><tspan class="c" x="0" y="0">You minted Fart</tspan><tspan class="k" x="267.11" y="0">#';
    string private constant svgEnd = ' ~</tspan></text></g></svg>';

    /* ====== MODIFIERS ====== */

    modifier tokenExists(uint256 tokenId_) {
        if (!_exists(tokenId_))
            revert TokenDoesNotExist();
        _;
    }

    /* ====== CONSTRUCTOR ====== */

    constructor(address owner1_, address dev_) ERC721A("Fartz", "FRTZ") {
        _owner1 = payable(owner1_);
        _dev = payable(dev_);
    }

    receive() payable external {}

    function mint(uint256 quantity_)
    external payable
    nonReentrant
    {
        if (!isPublicSaleActive)
            revert PublicSaleNotActive();

        if (quantity_ == 0)
            revert YouMustFartAtLeastOnceToCallThisFunction();
        if (quantity_ > MAX_MINT_QUANTITY)
            revert SenderNeedsToRestBetweenFarts();
        if (_numberMinted(msg.sender) + quantity_ > MAX_MINT_ALLOWANCE)
            revert SenderHasFartedTooManyTimes();
        if (totalSupply() + quantity_ > MAX_SUPPLY)
            revert TooManyFartsCauseGlobalWarming();
        if (msg.value < (PUBLIC_SALE_PRICE * quantity_))
            revert FartsArentFree();

        // Generate and register farts
        uint256 supply_ = totalSupply();
        for (uint256 i = 0; i < quantity_; i++) {
            bytes32 fart_ = _generateFart(msg.sender, supply_ + i);
            _registeredDisturbances[supply_ + i] = fart_; 
            _knownDisturbances[fart_] = true; 
        }

        // Mint NFT
        _safeMint(
            msg.sender,
            quantity_
        );
    }

    function permissionedMint(address receiver_) external {
        if (msg.sender != _ssmw)
            revert NotPermissionedMinter();
        if (totalSupply() >= MAX_SUPPLY)
            revert TooManyFartsCauseGlobalWarming();
            
        uint256 supply_ = totalSupply();
        bytes32 fart_ = _generateFart(receiver_, supply_);
        _registeredDisturbances[supply_] = fart_; 
        _knownDisturbances[fart_] = true; 

        _safeMint(receiver_, 1);
    }

    function mintPromotional(address receiver_, uint256 quantity_)
    external onlyOwner
    nonReentrant
    {
        if (quantity_ == 0)
            revert YouMustFartAtLeastOnceToCallThisFunction();
        if (totalSupply() + quantity_ > MAX_SUPPLY)
            revert TooManyFartsCauseGlobalWarming();

        // Generate and register farts
        uint256 supply_ = totalSupply();
        for (uint256 i = 0; i < quantity_; i++) {
            bytes32 fart_ = _generateFart(receiver_, supply_ + i);
            _registeredDisturbances[supply_ + i] = fart_; 
            _knownDisturbances[fart_] = true; 
        }

        // Mint NFT
        _safeMint(
            msg.sender,
            quantity_
        );
    }

    /* ========== INTERNAL FUNCTION ========== */

    function _generateFart(address receiver_, uint256 tokenId_) internal view returns (bytes32) {
        // Create the seed
        uint256 seed_ = uint256(
            keccak256(abi.encode(block.timestamp, receiver_, tokenId_))
        );

        bytes32 fart_;
        bytes memory b = new bytes(9);

        // Select the random elements for each trait
        // 0 - smell
        b[0] = _generateRandomIndex(seed_, _raritiesSmell, 0);

        // 1 - wetness
        b[1] = _generateRandomIndex(seed_, _raritiesWetness, 1);

        // 2 - associated cuisine
        b[2] = _generateRandomIndex(seed_, _raritiesCuisine, 2);

        // 3 - duration
        b[3] = _generateRandomIndex(seed_, _raritiesDuration, 3);

        // 4 - quantity of methane
        b[4] = _generateRandomIndex(seed_, _raritiesMethane, 4);

        // 5 - who are you with
        b[5] = _generateRandomIndex(seed_, _raritiesWithWho, 5);

        // 6 - where are you
        b[6] = _generateRandomIndex(seed_, _raritiesWhereAreYou, 6);

        // 7 - intentionality
        b[7] = _generateRandomIndex(seed_, _raritiesIntentionality, 7);

        // 8 - level of relief
        b[8] = _generateRandomIndex(seed_, _raritiesRelief, 8);

        assembly {
            fart_ := mload(add(b, 0x20))
        }

        // Check for incompatabilities 
        // TODO: IMPLEMENT ME

        // Make sure the fart is unique
        if (_knownDisturbances[fart_])
            revert FartGotLostInTheEther();

        // Return the fart
        return fart_;
    }

    function _generateRandomIndex(
        uint256 seed_, 
        uint16[] storage rarities_, 
        uint8 traitId_
    ) private view returns (bytes1 index) {
        uint16 random10k = uint16(uint256(keccak256(abi.encode(seed_, traitId_))) % 10000);
        uint16 lowerBound;
        for (uint8 i = 0; i < rarities_.length; i++) {
            uint16 percentage = rarities_[i];

            if (random10k < percentage + lowerBound && random10k >= lowerBound) {
                return bytes1(i);
            }
            lowerBound = lowerBound + percentage;
        }
        revert();
    }

    function _buildFart(uint256 tokenId_) internal view returns (string memory properties, string memory svg) {
        // Grab the trait / dna for the fart
        bytes32 dna = _registeredDisturbances[tokenId_];

        return (
            _fartProperties(dna), 
            _renderFart(
                tokenId_,
                _traitsSmell[uint8(dna[0])],
                _traitsWetness[uint8(dna[1])],
                _traitsCuisine[uint8(dna[2])],
                _traitsDuration[uint8(dna[3])],
                _traitsMethane[uint8(dna[4])],
                _traitsWithWho[uint8(dna[5])],
                _traitsWhereAreYou[uint8(dna[6])],
                _traitsIntentionality[uint8(dna[7])],
                _traitsRelief[uint8(dna[8])]
            )
        );
    }
    
    function _fartProperties(bytes32 dna) internal view returns (string memory properties) {
        return string(
            abi.encodePacked(
                _packProperty("smell",               _traitsSmell[uint8(dna[0])], false),   
                _packProperty("wetness",             _traitsWetness[uint8(dna[1])], false),   
                _packProperty("associated cuisine",  _traitsCuisine[uint8(dna[2])], false),   
                _packProperty("duration",            _traitsDuration[uint8(dna[3])], false),   
                _packProperty("quantity of methane", _traitsMethane[uint8(dna[4])], false),   
                _packProperty("who are you with",    _traitsWithWho[uint8(dna[5])], false),   
                _packProperty("where are you",       _traitsWhereAreYou[uint8(dna[6])], false),   
                _packProperty("intentionality",      _traitsIntentionality[uint8(dna[7])], false),   
                _packProperty("level of relief",     _traitsRelief[uint8(dna[8])], true)
            )
        );
    }
    
    function _renderFart(
        uint256 tokenId_,
        string memory smell,
        string memory wetness,
        string memory cuisine,
        string memory duration,
        string memory methane,
        string memory withWho,
        string memory whereAreYou,
        string memory intentiality,
        string memory relief
    ) public pure returns (string memory svg) {
        return string(
            abi.encodePacked(
                svgStart,
                abi.encodePacked(
                    tokenId_.toString(),
                    '</tspan></text><text class="i" transform="translate(143.11 405.56)"><tspan class="c">Was executed </tspan><tspan class="h">',
                    whereAreYou,
                    '<tspan class="c">, </tspan>',
                    intentiality,
                    '</tspan></text><text class="i" style="text-align: center;" transform="translate(143.11 438.95)"><tspan class="c">In front of your</tspan><tspan class="h"> ',
                    withWho,
                    '</tspan></text><text class="i" transform="translate(143.11 472.34)"><tspan class="c">After eating</tspan><tspan class="f"> ',
                    cuisine
                ),
                abi.encodePacked(
                    '</tspan></text><text class="i" transform="translate(143.11 505.73)"><tspan class="c">It was</tspan><tspan class="h"> ',
                    duration,
                    '</tspan><tspan class="c"> and</tspan></text><text class="i" transform="translate(143.11 539.12)"><tspan class="c">smelled like</tspan><tspan class="h"> ',
                    smell,
                    '</tspan></text><text class="i" transform="translate(143.11 572.51)"><tspan class="c">It felt like</tspan><tspan class="h"> ',
                    wetness,
                    '</tspan></text><text class="i" transform="translate(143.11 605.9)"><tspan class="c">It released</tspan><tspan class="g"> ',
                    methane,
                    '</tspan><tspan class="e"> mL of methane</tspan></text><text class="j" transform="translate(143.11 685.79)"><tspan x="0" y="0">~ ',
                    relief
                ),
                svgEnd
            )
        );
    }
            
    function _packProperty(string memory name_, string memory trait_, bool last_) public pure returns (string memory svg) {
        string memory comma_ = ","; 
        if (last_) {
            comma_ = ""; 
        }
        return string(
            abi.encodePacked(
                '{"trait_type":"',
                name_,
                '","value":"',
                trait_,
                '"}',
                comma_
            )
        );
    }

    function destroy() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    /* ========== FUNCTION ========== */

    function setIsPublicSaleActive(bool isPublicSaleActive_) external onlyOwner {
        isPublicSaleActive = isPublicSaleActive_;
    }

    function setPublicSalePrice(uint64 price_) external onlyOwner {
        PUBLIC_SALE_PRICE = price_;
    }

    function setSudoSwapMintWrapperContract(address ssmw_) external onlyOwner {
        _ssmw = ssmw_;
    }

    function setDescription(string memory description_) external onlyOwner {
        DESCRIPTION = description_;
    }

    function withdraw() public {
        uint256 split_ = address(this).balance / 2;

        bool success_;
        (success_,) = _owner1.call{value : split_}("");
        if (!success_) revert WithdrawTransferFailed();

        (success_,) = _dev.call{value : split_}("");
        if (!success_) revert WithdrawTransferFailed();
    }

    function withdrawTokens(IERC20 token) public {
        uint256 balance_ = token.balanceOf(address(this));
        uint256 split_ = balance_ / 2;

        token.safeTransfer(_owner1, split_);
        token.safeTransfer(_dev, split_);
    }

    // ============ FUNCTION OVERRIDES ============

    function supportsInterface(bytes4 interfaceId_)
    public view virtual override(ERC721A, IERC165)
    returns (bool)
    {
        return
            interfaceId_ == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId_);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId_) public view virtual override tokenExists(tokenId_) returns (string memory) {
        (string memory properties, string memory svg) = _buildFart(tokenId_);

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                base64(
                    abi.encodePacked(
                        '{"name":"#', 
                        tokenId_.toString(),
                        '","description":"', 
                        DESCRIPTION, 
                        '","traits":[', 
                        properties, 
                        '],"image":"data:image/svg+xml;base64,',
                        base64(abi.encodePacked(svg)),
                        '"}'
                    )
                )
            )
        );
    }

    function getDNA(uint256 tokenId_) external view returns (bytes32) {
        return _registeredDisturbances[tokenId_];
    }

    function getOwnership(uint256 tokenId_) external view returns (TokenOwnership memory) {
        return _ownerships[tokenId_];
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId_, uint256 salePrice_)
    external view override
    tokenExists(tokenId_)
    returns (address receiver, uint256 royaltyAmount)
    {
        return (address(this), salePrice_.mulDivDown(69, 1000));
    }

    //  Base64 by Brecht Devos - <[email protected]>
    //  Provides a function for encoding some bytes in base64
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function base64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {mstore(sub(resultPtr, 2), shl(240, 0x3d3d))}
            case 2 {mstore(sub(resultPtr, 1), shl(248, 0x3d))}
        }

        return result;
    }
}