//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {ERC721, ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./IdUtils.sol";
import "./ActiveAfterBlock.sol";

contract MutagenToken is ERC721Enumerable, ActiveAfterBlock, IdUtils {
    /*******************************
     * Constants, structs & events *
     *******************************/

    // Print bonding curve parameters - NEVER MUTATE
    // All the BC prices need to be even numbers for feeShare
    // in _collectFees to be calculated correctly
    uint256 constant PRINT_FEE_BASE = 0.2 ether;
    uint256 constant PRINT_CURVE_EXPONENT = 4;
    uint256 constant PRINT_CURVE_COEFFICIENT = 0.00000002 ether;

    // Probability in % that a rare variant occurs
    uint8 constant RARE_VARIANT_PROBABILITY = 2;

    // Maximum number of Genesis tokens
    uint8 constant MAX_GENESIS_TOKENS = 40;

    // Maximum number of Mutagen tokens
    uint16 constant MAX_MUTAGEN_TOKENS = 4096;

    struct Genesis {
        // Print nonce, this is used to ensure all print IDs are unique
        uint256 printNonce;
        // Active print count
        uint256 printSupply;
        // Keep print count trackers in another array, one counter per generation
        uint256[] printCounts;
        // Print fees that are claimable by the Genesis holder
        uint256 fees;
        // Rare variants, (layer, variant) indexes
        uint8[2] moon;
        uint8[2] punk;
        // Generations are all realized variant combinations
        uint8[4][] generations;
    }

    event Print(
        address to,
        uint8 genesisIdx,
        uint16 generationIdx,
        uint256 nextPrintValue
    );

    event Burn(
        address from,
        uint8 genesisIdx,
        uint16 generationIdx,
        uint256 nextBurnValue
    );

    event Mutation(uint8 genesisIdx, uint8[4] newGeneration);

    event PermanentURI(string _value, uint256 indexed _id);

    /*************
     * Variables *
     *************/

    // Bonding curve reserve
    uint256 public reserve;

    // Protocol fees balance
    uint256 public protocolFees;

    // Global rare variant trackers
    uint8 public remainingPunkMutations = 2;
    uint8 public remainingMoonMutations = 4;

    // Base URL for Genesis and Mutagen assets
    string public assetsBaseURL;

    // Base URL for the metadata API
    string public metadataBaseURL;

    // Genesis storage
    Genesis[MAX_GENESIS_TOKENS] private _geneses;

    // Address for the EVPool that is allowed to mint Genesis and Mutagen tokens
    address private _minter;

    // Mapping for stored token URIs
    mapping(uint256 => string) private _tokenURIs;

    constructor(
        string memory _assetsBaseURL,
        uint256 _startingBlock,
        string memory _metadataBaseURL
    ) ERC721("Mutagen", "MUTAGEN") {
        assetsBaseURL = _assetsBaseURL;
        startingBlock = _startingBlock;
        metadataBaseURL = _metadataBaseURL;

        // Initialize Geneses in storage
        _initGenesis(0, [2, 3], [1, 3], [0, 0, 0, 0]);
        _initGenesis(1, [0, 3], [3, 3], [2, 0, 3, 2]);
        _initGenesis(2, [3, 3], [2, 3], [2, 0, 0, 0]);
        _initGenesis(3, [2, 3], [3, 3], [0, 0, 1, 1]);
        _initGenesis(4, [2, 3], [1, 3], [0, 0, 0, 0]);
        _initGenesis(5, [3, 3], [2, 3], [3, 1, 0, 0]);
        _initGenesis(6, [0, 3], [3, 3], [0, 0, 0, 1]);
        _initGenesis(7, [0, 3], [1, 3], [1, 2, 1, 2]);
        _initGenesis(8, [3, 3], [2, 3], [2, 1, 1, 0]);
        _initGenesis(9, [3, 3], [2, 3], [2, 2, 1, 0]);
        _initGenesis(10, [0, 3], [3, 3], [0, 1, 1, 1]);
        _initGenesis(11, [3, 3], [2, 3], [3, 0, 1, 0]);
        _initGenesis(12, [0, 3], [2, 3], [0, 0, 0, 0]);
        _initGenesis(13, [3, 3], [1, 3], [0, 0, 0, 0]);
        _initGenesis(14, [3, 3], [2, 3], [0, 1, 1, 0]);
        _initGenesis(15, [3, 3], [2, 3], [3, 1, 2, 1]);
        _initGenesis(16, [0, 3], [0, 2], [1, 1, 0, 2]);
        _initGenesis(17, [3, 3], [2, 3], [1, 1, 1, 1]);
        _initGenesis(18, [1, 3], [3, 3], [3, 1, 1, 2]);
        _initGenesis(19, [0, 3], [3, 3], [1, 1, 3, 0]);
        _initGenesis(20, [0, 3], [1, 3], [0, 0, 0, 0]);
        _initGenesis(21, [3, 3], [0, 3], [1, 1, 2, 0]);
        _initGenesis(22, [0, 3], [0, 2], [1, 1, 1, 0]);
        _initGenesis(23, [0, 3], [3, 3], [1, 3, 1, 2]);
        _initGenesis(24, [3, 3], [0, 3], [1, 3, 3, 2]);
        _initGenesis(25, [3, 3], [1, 3], [1, 0, 1, 1]);
        _initGenesis(26, [3, 3], [2, 3], [3, 3, 2, 2]);
        _initGenesis(27, [3, 3], [2, 3], [3, 1, 0, 2]);
        _initGenesis(28, [0, 3], [1, 3], [1, 1, 2, 1]);
        _initGenesis(29, [0, 3], [3, 3], [0, 0, 0, 1]);
        _initGenesis(30, [1, 3], [0, 3], [0, 0, 0, 0]);
        _initGenesis(31, [0, 3], [2, 3], [0, 0, 0, 0]);
        _initGenesis(32, [0, 3], [3, 3], [2, 1, 2, 2]);
        _initGenesis(33, [0, 3], [2, 3], [2, 3, 0, 1]);
        _initGenesis(34, [0, 2], [0, 3], [0, 0, 3, 0]);
        _initGenesis(35, [0, 3], [2, 3], [0, 0, 1, 2]);
        _initGenesis(36, [3, 3], [2, 3], [1, 3, 1, 0]);
        _initGenesis(37, [0, 3], [1, 3], [2, 0, 1, 2]);
        _initGenesis(38, [0, 3], [1, 3], [0, 0, 0, 0]);
        _initGenesis(39, [0, 3], [1, 3], [2, 0, 3, 1]);
    }

    /****************
     * User actions *
     ****************/

    /**
     * @dev Create a new print of a Genesis
     */
    function print(uint256 genesisId)
        external
        payable
        isTokenType(genesisId, GENESIS_TOKEN)
        isActive
    {
        // Get a reference to the genesis we're printing
        uint8 genesisIdx = unpackGenesisId(genesisId);
        Genesis storage genesis = _geneses[genesisIdx];

        // Get the current generation index
        uint16 generationIdx = uint16(genesis.generations.length) - 1;

        // Get the index and ID of the new print
        uint256 printId = packPrintId(
            genesisIdx,
            genesis.printNonce,
            generationIdx
        );

        // Collect printing fees
        uint256 usedFees = _collectFees(genesisIdx);

        // Update Genesis state
        genesis.printNonce += 1;
        genesis.printCounts[generationIdx] += 1;
        genesis.printSupply += 1;

        // Mint the token
        _safeMint(msg.sender, printId);

        // Refund any excess ether
        _refundExcess(usedFees);

        // Emit printing event
        emit Print(
            msg.sender,
            genesisIdx,
            generationIdx,
            getPrintValue(genesis.printSupply + 1)
        );
    }

    /**
     * @dev Burn a print and get the reserve ether back from the bonding curve
     */
    function burn(uint256 printId)
        external
        onlyTokenOwner(printId)
        isTokenType(printId, PRINT_TOKEN)
    {
        // Get a reference to the genesis we're modifying
        (uint8 genesisIdx, , uint16 generationIdx) = unpackPrintId(printId);
        Genesis storage genesis = _geneses[genesisIdx];

        // Get the amount to be refunded to the burner
        uint256 burnValue = getBurnValue(genesis.printSupply);

        // Update Genesis state
        genesis.printSupply -= 1;
        genesis.printCounts[generationIdx] -= 1;

        // Subtract reserves
        reserve -= burnValue;

        // Burn the token
        _burn(printId);

        // Refund ether
        _send(burnValue, msg.sender);

        // Emit burn event
        emit Burn(
            msg.sender,
            genesisIdx,
            generationIdx,
            getBurnValue(genesis.printSupply)
        );
    }

    /**
     * @dev Trigger a mutation on a Genesis token you own. Burns a Mutagen in the process.
     */
    function mutate(uint256 genesisId, uint256 mutagenId)
        external
        onlyTokenOwner(genesisId)
        isTokenType(genesisId, GENESIS_TOKEN)
        onlyTokenOwner(mutagenId)
        isTokenType(mutagenId, MUTAGEN_TOKEN)
        isActive
    {
        // Get a reference to the Genesis we're mutating
        uint8 genesisIdx = unpackGenesisId(genesisId);
        Genesis storage genesis = _geneses[genesisIdx];

        // Burn the Mutagen
        _burn(mutagenId);

        // Make a copy of the latest generation so we can update it
        uint8[4] memory newGeneration = genesis.generations[
            genesis.generations.length - 1
        ];

        // Get mutation parameters from the Mutagen
        (uint8 layer, uint8 variant, ) = unpackMutagenId(mutagenId);

        if (
            // Case 1: The layer has no rare variants
            layer != genesis.punk[0] && layer != genesis.moon[0]
        ) {
            // Pick any of the 4 variants with equal probability
            newGeneration[layer] = uint8(variant % 4);
        } else if (
            // Case 2: The layer has a rare moon variant and it will activate
            layer == genesis.moon[0] &&
            remainingMoonMutations > 0 &&
            variant < RARE_VARIANT_PROBABILITY
        ) {
            // Activate rare variant and decrease remaining count
            newGeneration[layer] = genesis.moon[1];
            remainingMoonMutations -= 1;
        } else if (
            // Case 3: The layer has a rare Cryptopunk variant and it will activate
            layer == genesis.punk[0] &&
            remainingPunkMutations > 0 &&
            variant < RARE_VARIANT_PROBABILITY
        ) {
            // Activate rare variant and decrease remaining count
            newGeneration[layer] = genesis.punk[1];
            remainingPunkMutations -= 1;
        } else {
            // Case 4: The layer has rare variant(s) but they weren't activated
            // Pick one of the non-rare variants with equal probability.
            // Assume that the rare variants are sorted to the end of the layer.
            uint8 regularVariantCount = 4 -
                (genesis.punk[0] == layer ? 1 : 0) -
                (genesis.moon[0] == layer ? 1 : 0);
            newGeneration[layer] = uint8(variant % regularVariantCount);
        }

        // Update the Genesis state by adding the new generation
        genesis.generations.push(newGeneration);
        // And the print counter for that new generation
        genesis.printCounts.push(0);

        // If the Genesis has any accrued fees, send them to it's owner
        uint256 fees = genesis.fees;
        if (fees > 0) {
            genesis.fees = 0;
            _send(fees, msg.sender);
        }

        // Emit mutation event
        emit Mutation(genesisIdx, newGeneration);
    }

    /**************************
     * Querying Mutagen state *
     **************************/

    /**
     * @dev Get the value of the next print from the bonding curve
     */
    function getPrintValue(uint256 printNumber)
        public
        pure
        returns (uint256 value)
    {
        return
            (printNumber - 1)**PRINT_CURVE_EXPONENT *
            PRINT_CURVE_COEFFICIENT +
            PRINT_FEE_BASE;
    }

    /**
     * @dev Get the value of the next burn from the bonding curve
     */
    function getBurnValue(uint256 printNumber)
        public
        pure
        returns (uint256 value)
    {
        return printNumber > 0 ? (getPrintValue(printNumber) * 9) / 10 : 0;
    }

    /**
     * @dev Get the current Genesis state
     */
    function getGenesisState(uint256 genesisIdx)
        external
        view
        returns (
            uint8[4][] memory generations,
            uint256[] memory printCounts,
            uint256 printSupply,
            uint256 fees,
            uint256 nextPrintValue,
            uint256 nextBurnValue,
            uint8[2] memory punk,
            uint8[2] memory moon
        )
    {
        Genesis memory genesis = _geneses[genesisIdx];

        fees = genesis.fees;
        generations = genesis.generations;
        printCounts = genesis.printCounts;
        printSupply = genesis.printSupply;
        nextPrintValue = getPrintValue(genesis.printSupply + 1);
        nextBurnValue = genesis.printSupply > 0
            ? getBurnValue(genesis.printSupply)
            : 0;
        punk = genesis.punk;
        moon = genesis.moon;
    }

    /**
     * @dev Get the token metadata URI
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        // Check that the token exists
        require(_exists(tokenId), "Token does not exist");

        // Try to get the URI from storage
        string memory _tokenURI = _tokenURIs[tokenId];

        // If a token URI has been set for this token, return that
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        // Otherwise fall back to the main tokenURI()
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Get all assets associated with the token
     */
    function tokenAssets(uint256 tokenId)
        external
        view
        returns (string[4] memory assets)
    {
        if (_tokenType(tokenId) == MUTAGEN_TOKEN) {
            (, , uint256 mutagenIdx) = unpackMutagenId(tokenId);

            assets[0] = string(
                abi.encodePacked(
                    assetsBaseURL,
                    "/mutagen/",
                    _uint2str(mutagenIdx),
                    ".svg"
                )
            );
        } else if (_tokenType(tokenId) == GENESIS_TOKEN) {
            uint256 genesisIdx = unpackGenesisId(tokenId);
            Genesis memory genesis = _geneses[genesisIdx];
            uint8[4] memory generation = genesis.generations[
                genesis.generations.length - 1
            ];

            for (uint8 i = 0; i < 4; i++) {
                assets[i] = string(
                    abi.encodePacked(
                        assetsBaseURL,
                        "/genesis/",
                        _uint2str(genesisIdx),
                        "/l",
                        _uint2str(i),
                        "v",
                        _uint2str(generation[i]),
                        ".png"
                    )
                );
            }
        } else if (_tokenType(tokenId) == PRINT_TOKEN) {
            (uint256 genesisIdx, , uint16 printGeneration) = unpackPrintId(
                tokenId
            );
            Genesis memory genesis = _geneses[genesisIdx];
            uint8[4] memory generation = genesis.generations[printGeneration];

            for (uint8 i = 0; i < 4; i++) {
                assets[i] = string(
                    abi.encodePacked(
                        assetsBaseURL,
                        "/genesis/",
                        _uint2str(genesisIdx),
                        "/l",
                        _uint2str(i),
                        "v",
                        _uint2str(generation[i]),
                        ".png"
                    )
                );
            }
        }
    }

    /*******************
     * Admin functions *
     *******************/

    /**
     * @dev Update the address that is allowed to mint new tokens
     */
    function setMinter(address newMinter) external onlyOwner {
        _minter = newMinter;
    }

    /**
     * @dev Mint a Genesis token
     */
    function mintGenesis(address to, uint8 genesisIdx) external onlyMinter {
        require(genesisIdx < MAX_GENESIS_TOKENS, "Invalid Genesis index");
        uint256 genesisId = packGenesisId(genesisIdx);

        _safeMint(to, genesisId);
    }

    /**
     * @dev Mint a Mutagen token
     */
    function mintMutagen(
        address to,
        uint8 layer,
        uint8 variant,
        uint16 mutagenIdx
    ) external onlyMinter {
        require(layer < 4, "Invalid layer");
        require(variant < 100, "Invalid variant number");
        require(mutagenIdx < MAX_MUTAGEN_TOKENS, "Invalid Mutagen index");

        uint256 mutagenId = packMutagenId(layer, variant, mutagenIdx);
        _safeMint(to, mutagenId);
    }

    /**
     * @dev Withdraw all collected fees. Callable by the owner.
     */
    function withdrawProtocolFees(address to) public onlyOwner {
        uint256 fees = protocolFees;
        protocolFees = 0;
        _send(fees, to);
    }

    /**
     * @dev Set metadata base URL
     */
    function setMetadataBaseURL(string memory newURI) external onlyOwner {
        metadataBaseURL = newURI;
    }

    /**
     * @dev Set a static URI for a token
     */
    function setTokenURI(uint256 tokenId, string memory newURI)
        external
        onlyOwner
    {
        // Try to get the URI from storage
        string memory _tokenURI = _tokenURIs[tokenId];

        // Make sure we can only set this once
        require(bytes(_tokenURI).length == 0, "Token URI already set");

        _tokenURIs[tokenId] = newURI;
        emit PermanentURI(newURI, tokenId);
    }

    /*************
     * Modifiers *
     *************/

    /**
     * @dev Only allow the owner of a specific token to call this function
     */
    modifier onlyTokenOwner(uint256 tokenId) {
        require(msg.sender == ownerOf(tokenId), "Not the token owner");
        _;
    }

    /**
     * @dev Only allow the minter address to call this function
     */
    modifier onlyMinter() {
        require(msg.sender == _minter, "Not the minter");
        _;
    }

    /*************
     * Internals *
     *************/

    /**
     * @dev Initialize a Genesis in storage
     */
    function _initGenesis(
        uint8 genesisIdx,
        uint8[2] memory moon,
        uint8[2] memory punk,
        uint8[4] memory startingGeneration
    ) internal {
        require(genesisIdx < MAX_GENESIS_TOKENS, "Invalid Genesis index");
        Genesis storage genesis = _geneses[genesisIdx];

        // Set the Genesis properties
        genesis.moon = moon;
        genesis.punk = punk;

        // Push the initial state into generations
        genesis.generations.push(startingGeneration);

        // Initialize printing-related state
        genesis.printCounts.push(0);
        genesis.printNonce = 0;
        genesis.printSupply = 0;
    }

    /**
     * @dev Update print fee related balances
     */
    function _collectFees(uint256 genesisIdx) internal returns (uint256) {
        Genesis storage genesis = _geneses[genesisIdx];
        uint256 fee = getPrintValue(genesis.printSupply + 1);
        require(msg.value >= fee, "Insufficient value");

        // 90% goes into reserve for future burns
        uint256 reserveFee = getBurnValue(genesis.printSupply + 1);
        // 10% is split equally between the protocol and genesis owner
        uint256 feeShare = (fee - reserveFee) / 2;
        require(reserveFee + feeShare + feeShare == fee, "Fees do not add up");

        reserve += reserveFee;
        genesis.fees += feeShare;
        protocolFees += feeShare;

        return fee;
    }

    /**
     * @dev Refund any excess ether to the sender
     */
    function _refundExcess(uint256 usedFees) internal {
        if (msg.value > usedFees) {
            _send(msg.value - usedFees, msg.sender);
        }
    }

    /**
     * @dev Send an amount of ether to the caller
     */
    function _send(uint256 amount, address to) internal {
        require(
            address(this).balance - amount >= reserve,
            "Cannot send reserves"
        );

        (bool success, ) = to.call{value: amount}("");
        require(success, "Payment failed");
    }

    /**
     * @dev Base URI for tokenId()
     */
    function _baseURI() internal view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    metadataBaseURL,
                    "?contractAddress=",
                    _contractAddress(),
                    "&tokenId="
                )
            );
    }

    /**
     * @dev Get a string with this contract's address
     */
    function _contractAddress() internal view returns (string memory) {
        bytes memory s = new bytes(40);

        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(
                uint8(uint256(uint160(address(this))) / (2**(8 * (19 - i))))
            );
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = _char(hi);
            s[2 * i + 1] = _char(lo);
        }

        return string(abi.encodePacked("0x", s));
    }

    /**
     * @dev Convert bytes to an ASCII character
     */
    function _char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    /**
     * @dev Convert uint to a string
     */
    function _uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}