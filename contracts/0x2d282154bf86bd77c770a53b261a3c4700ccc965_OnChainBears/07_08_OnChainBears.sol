// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "solady/auth/Ownable.sol";
import "solady/utils/Base64.sol";
import "./interfaces/IOnChainBears.sol";

/*
   ____           ________          _          ____                      
  / __ \____     / ____/ /_  ____ _(_)___     / __ )___  ____ ___________
 / / / / __ \   / /   / __ \/ __ `/ / __ \   / __  / _ \/ __ `/ ___/ ___/
/ /_/ / / / /  / /___/ / / / /_/ / / / / /  / /_/ /  __/ /_/ / /  (__  ) 
\____/_/ /_/   \____/_/ /_/\__,_/_/_/ /_/  /_____/\___/\__,_/_/  /____/  
                                                                         
*/

/// @title On Chain Bears
/// @author ItsCuzzo

contract OnChainBears is IOnChainBears, Ownable, ERC721AQueryable {
    using Base64 for bytes;

    /// @dev Define `Trait` struct. Due to the nature of how traits
    /// are stored on-chain, this struct is used to manage trait information.
    /// `name`: Equivalent to `trait_type` in metadata.
    /// `value`: The value of `trait_type` in metadata.
    /// `pixels`: A string representation of the pixel placement associated with a trait.
    struct Trait {
        string name;
        string value;
        string pixels;
    }

    /// @dev Used with the `&` operator to parse the
    /// least significant 40 bits of a uint256 value.
    uint256 private constant _BIT_MASK = (1 << 40) - 1;

    /// @dev When parsing the `pixels` value of `Trait`, we use
    /// two lowercase letters to represent the x and y coordinates
    /// of our 24 x 24 SVG grid. We can imagine these letters to
    /// have a similar orientation to a traditional Caesar cipher.
    ///
    /// In the context of this contract, 'a' is 0, 'b' is 1, and so
    /// forth up until 'z' which is 25. With reference to an ASCII
    /// table, the decimal representation of a lowercase 'a' is
    /// 97. In order to derive the previously stated values, we
    /// need to minus 97 from the decimal value of the character
    /// being parsed, hence our `_ASCII_OFFSET` value.
    ///
    uint256 private constant _ASCII_OFFSET = 97;

    /// @dev This is the value that the cumulative weighting of
    /// each trait type should summate to. E.g. The sum of all
    /// weights within the `Hat` category should equal to 10000.
    /// See `_defineWeights()` for further clarity.
    uint64 private constant _TRAIT_WEIGHT = 10000;

    /// @dev Maps a token ID to a packed `dna` value. The
    /// most significant 16 bits are unused.
    ///
    ///  ------------------------
    /// | Bit Pos  | Trait       |
    /// |-------------------------
    /// | 0....39  | Hat         |
    /// | 40...79  | Eyes        |
    /// | 80..119  | Nose        |
    /// | 120.159  | Mouth       |
    /// | 160.199  | Fur         |
    /// | 200.239  | Background  |
    ///  ------------------------
    ///
    /// Layout: 32 Bytes (256 Bits)
    /// 0000000000000000000000000000000000000000000000000000000000000000
    ///     | BG     || Fur    || Mouth  || Nose   || Eyes   || Hat    |
    ///
    mapping(uint256 => uint256) private _dna;

    /// @dev Used to store the weights of each individual trait. There are
    /// 6 trait types, so we define the length of `_weights` to have 6 indices.
    uint16[][6] private _weights;

    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant MAX_MINT = 5;

    /// @dev Maps a trait identifier to an array of traits. Since the value
    /// of `0` is indicative of the `Hat` trait, `traits[0]` would return
    /// an array of `Trait` that is representive of all the possible hats.
    mapping(uint256 => Trait[]) public traits;

    constructor() ERC721A("On Chain Bears", "OCB") {
        _initializeOwner(msg.sender);
        _defineWeights();
    }

    /// @notice Function used to mint `amount` of tokens.
    /// @param amount Desired number of tokens to mint.
    /// @dev Mints are free! (づ｡◕w◕｡)づ
    function mint(uint256 amount) external {
        unchecked {
            if (msg.sender != tx.origin) revert NonEOA();
            if (amount > MAX_MINT) revert InvalidAmount();
            if (_totalMinted() + amount > MAX_SUPPLY) revert OverMaxSupply();
            if (_numberMinted(msg.sender) + amount > MAX_MINT) revert MaxMinted();

            uint256 id = _nextTokenId();
            
            /// Assign a DNA value for each of the tokens that are about to
            /// be minted. In the context of a 'real' project, you would
            /// opt to use either a commit-reveal scheme or oracle to prevent
            /// gaming of rare DNA. Since this is a free mint and stakes are
            /// low, naive generation of DNA values is adequate.
            for (uint256 i = id; i < id + amount; i++) {
                _dna[i] = uint256(keccak256(abi.encodePacked(
                    msg.sender, block.coinbase, i, "DNA"
                )));
            }

            _mint(msg.sender, amount);
        }
    }

    /// @notice Function used to store trait data on-chain.
    /// @param id Unique trait identifier.
    /// @param traitData An array of `Trait` associated with `id`.
    /// @dev This function will be called 6 times immediately after deployment
    /// to populate the trait data on-chain for each respective trait type.
    function addTraits(uint256 id, Trait[] calldata traitData) external onlyOwner {
        unchecked {
            for (uint256 i = 0; i < traitData.length; i++) {
                traits[id].push(Trait(
                    traitData[i].name,
                    traitData[i].value,
                    traitData[i].pixels
                ));
            }
        }
    }

    /// @notice Function used to return a token URI for `id`.
    /// @param id Unique token identifier.
    /// @dev This function has been overriden to allow for on-chain rendering.
    function tokenURI(uint256 id) public view override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(id)) revert NonExistent();
        Trait[] memory _traits = _parseTraitsFromDna(_dna[id]);
        return _getMetadata(id, _traits);
    }

    /// @dev Function called within the constructor to define the weighting associated
    /// with each trait type. The sum of each array equates to 10000 which allows for
    /// rarity percision to 2 decimal places. E.g. 10000 = 100.00% | 1000 = 10.00% 
    function _defineWeights() internal {
        
        // Ordering: Hats -> Eyes -> Noses -> Mouths -> Furs -> Backgrounds
        _weights[0] = [2500, 300, 600, 600, 200, 600, 600, 600, 600, 300, 300, 600, 600, 600, 400, 600];
        _weights[1] = [400, 200, 400, 700, 850, 850, 700, 800, 800, 850, 850, 850, 850, 700, 200];
        _weights[2] = [4750, 4750, 500];
        _weights[3] = [830, 830, 830, 830, 830, 830, 830, 830, 830, 830, 830, 870];
        _weights[4] = [1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000];
        _weights[5] = [500, 750, 1000, 1000, 1000, 1000, 1250, 1250, 500, 500, 1250];

        // Whilst not necessary, we conduct a sanity check here to ensure that all
        // weightings of each trait type summate to `_TRAIT_WEIGHT`.
        unchecked {
            for (uint256 i = 0; i < _weights.length; i++) {
                uint256 sum = 0;
                for (uint256 j = 0; j < _weights[i].length; j++) {
                    sum += _weights[i][j];
                }
                if (sum != _TRAIT_WEIGHT) revert Insane();
            }
        }
    }

    /// @dev Function used to parse a tokens associated traits from its DNA.
    function _parseTraitsFromDna(uint256 dna) internal view returns (Trait[] memory _traits) {

        _traits = new Trait[](_weights.length);

        uint256 roll;
        uint256 weight;
        uint256 traitWeight;

        // Iterate over `dna` to acquire the `roll` value for each trait.
        for (uint256 i = 0; i < _weights.length; i++) {
            
            // Determine the `roll` value for each trait. Upon each iteration, the
            // next most significant 40 bits will be shifted right and masked out.
            // The `roll` value will then be moduloed by 10000 to derive a value
            // between the bounds 0 and 9999.
            roll = (dna >> i * 40 & _BIT_MASK) % _TRAIT_WEIGHT;
            
            weight = 0;
            traitWeight = 0;

            // Using weighted random numbers, determine the rolled trait. This is an incredibly
            // useful algorithm to add rarity to traits in a simple yet efficient manner.
            // ref: https://www.rubyguides.com/2016/05/weighted-random-numbers/
            for (uint256 j = 0; j < _weights[i].length; j++) {
                traitWeight = _weights[i][j];

                if (roll <= weight + traitWeight) {
                    _traits[i] = traits[i][j];
                    break;
                }

                weight += traitWeight;
            }

        }

    }

    /// @dev Used to return the metadata attributes. All tokens will have 6 traits, so we
    /// can hardcode the array accesses. The `trait_type` values have been hardcoded as 
    /// ordering is guaranteed.
    function _getAttributes(Trait[] memory _traits) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"Hat","value":"', _traits[0].value, '"},',
            '{"trait_type":"Eyes","value":"', _traits[1].value, '"},',
            '{"trait_type":"Nose","value":"', _traits[2].value, '"},',
            '{"trait_type":"Mouth","value":"', _traits[3].value, '"},',
            '{"trait_type":"Fur","value":"', _traits[4].value, '"},',
            '{"trait_type":"Background","value":"', _traits[5].value, '"}'
        ));
    }

    /// @dev Used to return the complete metadata URI which has been base64 encoded. Many thanks
    /// to Vectorized of Solady who has written an extremely gas-efficient base64 `encode()` function
    /// in pure assembly.
    function _getMetadata(uint256 id, Trait[] memory _traits) internal pure returns (string memory) {
        return string(abi.encodePacked(
            "data:application/json;base64,",
            abi.encodePacked(
                '{"name":"Bear #', _toString(id),
                '","description":"On Chain Bears is a passion project inspired by the concept of on-chain NFTs, NFTs with no dependence on the outside world or external services such as IPFS. Rendered directly from the blockchain and destined to remain there forever. In the true spirit of decentralisation; CC0, 100% on-chain and 0% royalties.',
                '","image": "data:image/svg+xml;base64,', _getSVG(_traits),
                '","attributes":[', _getAttributes(_traits), ']}'
            ).encode())
        );
    }

    /// @dev Used to return the SVG XML. The algorithm used to generate the SVG is similar to that 
    /// used in Anonymice with a few minor differences. One such being that the `Trait` struct no
    /// longer requires a `pixelCount` attribute. Instead, the number of iterations is determined
    /// based off the byte length of `pixels`.
    function _getSVG(Trait[] memory _traits) internal pure returns (string memory) {
        
        // Represents a 24 x 24 grid, identical to the dimensions of our SVG artwork. This
        // variable will be used to determine which coordinates have already had a pixel placed.
        bool[24][24] memory placed;

        // Variable used to return the full `<rect>` properties of our SVG. Since no pixels
        // within our SVG artwork are void, we can expect 576 rect properties to be returned.
        string memory rects;

        // Variable used to store the casted bytes values of `pixels`.
        bytes memory b;

        // Iterate over each `Trait` in `_traits`.
        for (uint256 i = 0; i < _traits.length; i++) {

            // Cast `pixels` of `Trait` to type bytes, this allows for indices access
            // and the `length` property of `pixels`.
            b = bytes(_traits[i].pixels);

            // Lets assume we have a `pixels` value of `lq57mq57`. Since each series of 4
            // characters within `pixels` represents 1 pixel (p) worth of information we
            // can deconstruct `lq57mq57` as follows: p1 = `lq57` | p2 = `mq57`
            // With reference to `lq57`:
            //
            //   `l` : x coordinate (11).
            //   `q` : y coordinate (16).
            //   `57`: fill value in SVG style (c57).
            //
            // Since we can get the bytes length of `pixels`, we can infer the number of iterations
            // we need to make by simply dividing the `b.length` value by 4.
            for (uint256 j = 0; j < b.length / 4; j++) {

                // Parse out both `x` and `y` coordinate decimal values.
                uint256 x = uint8(b[j*4]) - _ASCII_OFFSET;
                uint256 y = uint8(b[j*4+1]) - _ASCII_OFFSET;

                // If a pixel has already been placed at coordinates `(x,y)` start the next iteration.
                if (placed[x][y]) continue;

                // Acknowledge that a pixel has been placed at `(x,y)`.
                placed[x][y] = true;

                // Concatenate the previous `rects` string with a new rect.
                rects = string(abi.encodePacked(
                    rects,
                    "<rect class='c", string(abi.encodePacked(b[j*4+2], b[j*4+3])),
                    "' x='", _toString(x),
                    "' y='", _toString(y),
                    "'/>"
                ));
            }

        }

        return abi.encodePacked(
            '<svg id="bears" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 24 24">',
            rects,
            "<style>",
            "rect{width:1px;height:1px;} #bears{shape-rendering: crispedges;}",
            ".c00{fill:#9ccc65}.c01{fill:#689f38}.c02{fill:#01579b}.c03{fill:#546e7a}.c04{fill:#80deea}.c05{fill:#b71c1c}.c06{fill:#ffeb3b}.c07{fill:#f44336}.c08{fill:#c5e1a5}.c09{fill:#00bcd4}.c10{fill:#42a5f5}.c11{fill:#ffff00}.c12{fill:#00c853}.c13{fill:#9fa8da}.c14{fill:#a1887f}.c15{fill:#9e9e9e}.c16{fill:#7cb342}.c17{fill:#03a9f4}.c18{fill:#ff5252}.c19{fill:#4dd0e1}.c20{fill:#ffff8d}.c21{fill:#c62828}.c22{fill:#673ab7}.c23{fill:#00897b}.c24{fill:#fbc02d}.c25{fill:#9c27b0}.c26{fill:#ff9800}.c27{fill:#4e342e}.c28{fill:#7c4dff}.c29{fill:#5d4037}.c30{fill:#00acc1}.c31{fill:#26c6da}.c32{fill:#ef9a9a}.c33{fill:#d32f2f}.c34{fill:#33691e}.c35{fill:#8d6e63}.c36{fill:#ff5722}.c37{fill:#ff6e40}.c38{fill:#ce93d8}.c39{fill:#bcaaa4}.c40{fill:#fff59d}.c41{fill:#b388ff}.c42{fill:#000000}.c43{fill:#ffee58}.c44{fill:#fff176}.c45{fill:#fafafa}.c46{fill:#fdd835}.c47{fill:#795548}.c48{fill:#ffc107}.c49{fill:#bdbdbd}.c50{fill:#76ff03}.c51{fill:#212121}.c52{fill:#ffd600}.c53{fill:#6d4c41}.c54{fill:#2196f3}.c55{fill:#ea80fc}.c56{fill:#424242}.c57{fill:#0097a7}.c58{fill:#f06292}.c59{fill:#ffffff}.c60{fill:#ef5350}.c61{fill:#aed581}.c62{fill:#f48fb1}.c63{fill:#eeeeee}.c64{fill:#d50000}.c65{fill:#8bc34a}.c66{fill:#0288d1}",
            "</style>",
            "</svg>"
        ).encode();

    }

    /// @dev Function used to override the starting token ID number.
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

}