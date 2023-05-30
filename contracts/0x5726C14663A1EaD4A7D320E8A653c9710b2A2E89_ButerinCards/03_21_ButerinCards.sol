//SPDX-License-Identifier: MIT

/// @title JPEG Mining
/// @author Xatarrer
/// @notice Unaudited
pragma solidity ^0.8.0;

import "./Array.sol";
import "./ButerinCardsLib.sol";
import "./ButerinCardsBackA.sol";
import "./ButerinCardsBackB.sol";
import "./ERC721Enumerable.sol";
import "./SSTORE2.sol";
import "./Ownable.sol";
import "./LibString.sol";
import "./MerkleProof.sol";

contract ButerinCards is ERC721Enumerable, Ownable {
    event Mined(
        address indexed minerAddress,
        uint256 indexed uploadedKB,
        uint256 indexed tokenId,
        uint8 phaseId,
        uint16 tokenIdWithinPhase,
        uint8 quoteId,
        uint8 bgDirectionId,
        uint8 bgPaletteId,
        uint16 lastTokenIdInScan,
        uint32 Nbytes,
        uint8 Nicons,
        uint32 seed
    );

    // State variables
    mapping(address => uint256) public Nmined; // Number of cards mined by an address
    uint256[] public chunks; // Array of tightly pack card data and metadata
    string public baseURLAnimation =
        "https://yellow-immense-spider-81.mypinata.cloud/ipfs/Qmczf1nd4uHzLxWRZ68pc2PWXBPKcRkoc39ZgQkB8X5bgy/index.html";

    // Constants
    string private constant _NAME = "Buterin Cards";
    string private constant _SYMBOL = "VITALIK";
    bytes32 private immutable _ROOT;
    uint256 public immutable TOKEN_ID_FIRST_BLUE_CHROMINANCE; // TokenId of first blue chrominance chunk
    uint256 public immutable TOKEN_ID_FIRST_RED_CHROMINANCE; // TokenId of first red chrominance chunk
    uint256 public immutable N_EMPTY_BLUE_COLOR_CHUNKS;
    uint256 public immutable N_EMPTY_RED_COLOR_CHUNKS;
    address public immutable JPEG_HEADER_POINTER; // Pointer to JPEG header

    constructor(
        bytes32 root,
        string memory jpegHeader,
        uint256 tokenIdFirstBlueChrominance,
        uint256 tokenIdFirstRedChrominance,
        uint256 NemptyBlueColorChunks,
        uint256 NemptyRedColorChunks
    ) ERC721(_NAME, _SYMBOL) {
        _ROOT = root;
        JPEG_HEADER_POINTER = SSTORE2.write(bytes(jpegHeader));
        TOKEN_ID_FIRST_BLUE_CHROMINANCE = tokenIdFirstBlueChrominance;
        TOKEN_ID_FIRST_RED_CHROMINANCE = tokenIdFirstRedChrominance;
        N_EMPTY_BLUE_COLOR_CHUNKS = NemptyBlueColorChunks;
        N_EMPTY_RED_COLOR_CHUNKS = NemptyRedColorChunks;
    }

    function setBaseURLAnimation(string calldata newBaseURLAnimation) external onlyOwner {
        baseURLAnimation = newBaseURLAnimation;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        // Retrieve chunk data
        ButerinCardsLib.ChunkUnpacked memory chunk = unpackChunk(tokenId);
        string memory cardIdStr = LibString.toString(tokenId + 1);
        string memory NiconsStr = LibString.toString(chunk.Nicons);
        string memory NkilobytesStr = LibString.toString(chunk.Nbytes / 1024);

        bytes[] memory bytesSegments = new bytes[](43);
        bytesSegments[0] = bytes("data:application/json;charset=UTF-8,%7B%22name%22%3A%22Buterin%20Card%20%23");
        bytesSegments[1] = bytes(cardIdStr);
        bytesSegments[2] = bytes(
            "%22%2C%22description%22%3A%22Introducing%20the%20Buterin%20Cards%2C%20a%20unique%20on-chain%20collection%20of%202%2C015%20cards%20celebrating%20Ethereum's%20co-founder%2C%20Vitalik%20Buterin.%20Inspired%20by%20the%20iconic%20Nakamoto%20Cards%20on%20Bitcoin%2C%20the%20Buterin%20Cards%20aim%20to%20pay%20tribute%20to%20Vitalik's%20immense%20contributions%20to%20blockchain%20technology.%20%20%5Cn%5CnPermanently%20stored%20on%20the%20Ethereum%20blockchain%2C%20these%20cards%20are%20the%20result%20of%20a%20collaborative%20effort%20by%20JPEG%20miners%20who%20work%20together%20to%20upload%20each%20card's%20data%20on-chain.%20The%20face%20side%20of%20each%20card%20features%20an%20HTML%20and%20SVG-coded%20frame%20surrounding%20a%20JPEG%20image%20of%20Vitalik%20Buterin%2C%20designed%20by%20Xatarrer.%20At%20over%2010%20MB%2C%20this%20image%20holds%20the%20record%20for%20the%20largest%20stored%20JPEG%20on-chain%20at%20the%20time%20of%20minting.%20%20%5Cn%5CnAdding%20to%20the%20uniqueness%20of%20the%20cards%2C%20the%20face%20side%20background%2C%20designed%20by%20Pawe%C5%82%20Dudko%2C%20showcases%20mesmerizing%2C%20dynamically%20moving%20rays%20of%20color.%20As%20a%20fusion%20of%20profile%20picture%20(pfp)%20NFTs%20and%20generative%20art%2C%20the%20Buterin%20Cards%20possess%20randomly-selected%20attributes%20during%20minting%2C%20such%20as%20one%20of%2045%20possible%20quotes%20from%20Vitalik.%20%20%5Cn%5CnThe%20Buterin%20Cards%20are%20the%20second%20collection%20to%20utilize%20a%20technique%20called%20JPEG%20Mining.%20In%20this%20process%2C%20the%20miners%20are%20responsible%20for%20uploading%20the%20NFT%20components%2C%20including%20the%20HTML%2C%20SVG%2C%20and%20Vitalik%20JPEG.%20Using%20Progressive%20JPEG%20technology%2C%20the%20image%20is%20revealed%20as%20it%20is%20mined%2C%20and%20miners%20are%20rewarded%20with%20a%20Buterin%20Card%20for%20their%20efforts.%20%20%5Cn%5CnThe%20JPEG%20mining%20process%20of%20the%20Buterin%20Cards%20consists%20of%20six%20phases%3A%20%20%5Cn%5Cu270F%5CuFE0F%20Pencil%20Drawing%3A%20Miners%20upload%20the%20HTML%20and%20SVG%2C%20receiving%20a%20card%20with%20a%20hand-drawn%20vectorized%20SVG%20version%20of%20the%20JPEG%2C%20as%20no%20JPEG%20data%20is%20available%20yet.%20%20%5Cn%5CuD83D%5CuDD33%20Black%20%26%20White%3A%20The%20intensity%20component%20of%20the%20progressive%20JPEG%20is%20uploaded%2C%20rendering%20the%20image%20in%20pure%20black%20and%20white.%20%20%5Cn%5CuD83C%5CuDF2B%5CuFE0F%20Grey%20Shades%3A%20Additional%20bits%20for%20the%20intensity%20component%20reveal%20a%20range%20of%20grey%20tones.%20%20%5Cn%5CuD83D%5CuDFE6%20Blue%20Chroma%3A%20The%20blue%20chroma%20is%20uploaded%2C%20introducing%20blue%20and%20green%20hues%20to%20the%20JPEG.%20%20%5Cn%5CuD83D%5CuDFE5%20Red%20Chroma%3A%20The%20red%20chroma%20is%20added%2C%20infusing%20red%20and%20pink%20shades%20into%20the%20image.%20%20%5Cn%5CuD83C%5CuDF04%20In%20the%20final%20phase%2C%20the%20AC%20components%20are%20uploaded%2C%20enhancing%20the%20image%20resolution.%22%2C%22attributes%22%3A%5B%7B%22trait_type%22%3A%22Quote%20Title%22%2C%22value%22%3A%22"
        );
        bytesSegments[3] = bytes(ButerinCardsLib.quoteName(chunk.quoteId));
        bytesSegments[4] = bytes("%22%7D%2C%7B%22trait_type%22%3A%22Phase%22%2C%22value%22%3A%22");
        bytesSegments[5] = bytes(ButerinCardsLib.phaseName(chunk.phaseId));
        bytesSegments[6] = bytes("%22%7D%2C%7B%22trait_type%22%3A%22Background%20Direction%22%2C%22value%22%3A%22");
        bytesSegments[7] = bytes(ButerinCardsLib.bgDirection(chunk.bgDirectionId));
        bytesSegments[8] = bytes("%22%7D%2C%7B%22trait_type%22%3A%22Background%20Palette%22%2C%22value%22%3A%22");
        bytesSegments[9] = bytes(ButerinCardsLib.bgPalette(chunk.bgPaletteId));
        bytesSegments[10] = bytes(
            "%22%7D%2C%7B%22display_type%22%3A%22boost_number%22%2C%22trait_type%22%3A%22Number%20of%20Icons%22%2C%22value%22%3A"
        );
        bytesSegments[11] = bytes(NiconsStr);
        bytesSegments[12] = bytes("%7D%2C%7B%22trait_type%22%3A%22Uploaded%20%5BKB%5D%22%2C%22value%22%3A");
        bytesSegments[13] = bytes(NkilobytesStr);
        bytesSegments[14] = bytes("%7D%5D%2C%22animation_url%22%3A%22");
        bytesSegments[15] = bytes(baseURLAnimation);
        bytesSegments[16] = bytes("?cardId=");
        bytesSegments[17] = bytes(cardIdStr);
        bytesSegments[18] = bytes("&phaseId=");
        bytesSegments[19] = bytes(LibString.toString(chunk.phaseId));
        bytesSegments[20] = bytes("&tokenIdWithinPhase=");
        bytesSegments[21] = bytes(LibString.toString(chunk.tokenIdWithinPhase));
        bytesSegments[22] = bytes("&kiloBytes=");
        bytesSegments[23] = bytes(NkilobytesStr);
        bytesSegments[24] = bytes("&quoteId=");
        bytesSegments[25] = bytes(LibString.toString(chunk.quoteId));
        bytesSegments[26] = bytes("&bgDirection=");
        bytesSegments[27] = bytes(LibString.toString(chunk.bgDirectionId));
        bytesSegments[28] = bytes("&bgPalette=");
        bytesSegments[29] = bytes(LibString.toString(chunk.bgPaletteId));
        bytesSegments[30] = bytes("&seed=");
        bytesSegments[31] = bytes(LibString.toString(chunk.seed));
        bytesSegments[32] = bytes("&Nicons=");
        bytesSegments[33] = bytes(NiconsStr);
        bytesSegments[34] = bytes("%22%2C%22image%22%3A%22");
        bytesSegments[35] = bytes(ButerinCardsBackA.cardBackPiece0());
        bytesSegments[36] = bytes(ButerinCardsBackA.cardBackPiece1(chunk.Nicons));
        bytesSegments[37] = bytes(ButerinCardsBackB.cardBackPiece2());
        bytesSegments[38] = bytes(chunk.quoteId < 8 ? ".2" : "0");
        bytesSegments[39] = bytes(ButerinCardsBackB.cardBackPiece3());
        bytesSegments[40] = bytes(ButerinCardsLib.cardBackPiece4());
        bytesSegments[41] = bytes(ButerinCardsLib.cardBackPiece5(chunk.phaseId));
        bytesSegments[42] = bytes("%22%7D");

        return string(Array.join(bytesSegments));
    }

    function onchainAnimation(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        // Retrieve chunk data
        ButerinCardsLib.ChunkUnpacked memory chunk = unpackChunk(tokenId);

        // Communicates to the miner that its card is not fully uploaded just yet
        if (chunk.lastTokenIdInScan >= totalSupply()) ButerinCardsLib.cardNotAvailable(chunk.lastTokenIdInScan);

        uint256 NHTMLChunks = unpackChunk(0).lastTokenIdInScan + 1;
        uint256 NJPEGChunks;

        /**
            Let's fuse all the parts together:
            If phaseId == 0, then
                1. _HTML_BEGINNING
                2. User parameters separated by commas
                3...M+1. HTML scans
            If phaseId > 0, then
                1. _HTML_BEGINNING
                2. User parameters separated by commas
                3. JPEG header
                4...(N+2). JPEG scans
                N+4. JPEG footer
                N+5...N+M+4. HTML scans
            Know that
                N + M = tokenId +1
         */

        // Create big array of bytes and copy necessary segments
        bytes[] memory bytesSegments = new bytes[](
            chunk.phaseId == 0 ? chunk.lastTokenIdInScan + 3 : chunk.phaseId == 1 || chunk.phaseId == 2
                ? chunk.lastTokenIdInScan + 5
                : chunk.phaseId == 3 // Ads red empty chroma NOT blue empty chroma NOR red chroma
                ? chunk.lastTokenIdInScan + 5 - N_EMPTY_BLUE_COLOR_CHUNKS
                : chunk.phaseId == 4 // Add empty blue chroma NOT red empty chroma NOR blue chroma
                ? chunk.lastTokenIdInScan +
                    5 +
                    TOKEN_ID_FIRST_BLUE_CHROMINANCE -
                    TOKEN_ID_FIRST_RED_CHROMINANCE -
                    N_EMPTY_RED_COLOR_CHUNKS
                : chunk.lastTokenIdInScan + 5 - N_EMPTY_BLUE_COLOR_CHUNKS - N_EMPTY_RED_COLOR_CHUNKS
        );

        bytesSegments[0] = htmlHeader();

        uint256 ind;
        if (chunk.phaseId > 0) {
            // JPEG header
            bytesSegments[2] = SSTORE2.read(JPEG_HEADER_POINTER);

            // Number JPEG chunks (includes all chromas (including empty) regardless)
            NJPEGChunks = chunk.lastTokenIdInScan + 1 - NHTMLChunks;

            bytes memory tempChunk;
            // Add JPEG chunks
            for (
                uint i = NHTMLChunks + N_EMPTY_BLUE_COLOR_CHUNKS + N_EMPTY_RED_COLOR_CHUNKS;
                i < NHTMLChunks + NJPEGChunks;
                i++
            ) {
                if (chunk.phaseId != 4 || i < TOKEN_ID_FIRST_BLUE_CHROMINANCE) {
                    tempChunk = SSTORE2.read(unpackChunk(i).dataPointer);
                    ind = i - NHTMLChunks - N_EMPTY_BLUE_COLOR_CHUNKS - N_EMPTY_RED_COLOR_CHUNKS + 3;
                    bytesSegments[ind] = tempChunk;
                } else if (i >= TOKEN_ID_FIRST_RED_CHROMINANCE) {
                    // We skip blue chroma in phase 4
                    tempChunk = SSTORE2.read(unpackChunk(i).dataPointer);
                    ind =
                        i -
                        NHTMLChunks -
                        N_EMPTY_BLUE_COLOR_CHUNKS -
                        N_EMPTY_RED_COLOR_CHUNKS +
                        TOKEN_ID_FIRST_BLUE_CHROMINANCE -
                        TOKEN_ID_FIRST_RED_CHROMINANCE +
                        3;
                    bytesSegments[ind] = tempChunk;
                }
            }

            // Add empty blue color chunks if necessary
            for (uint256 i = NHTMLChunks; i < NHTMLChunks + N_EMPTY_BLUE_COLOR_CHUNKS; i++) {
                if (chunk.phaseId == 1 || chunk.phaseId == 2) {
                    // B&W, Grey Tones and Red Chroma phases need empty blue chroma
                    tempChunk = SSTORE2.read(unpackChunk(i).dataPointer);
                    ind = i + NJPEGChunks - NHTMLChunks - N_EMPTY_BLUE_COLOR_CHUNKS - N_EMPTY_RED_COLOR_CHUNKS + 3;
                    bytesSegments[ind] = tempChunk;
                } else if (chunk.phaseId == 4) {
                    // Red Chroma phase needs empty blue chroma
                    tempChunk = SSTORE2.read(unpackChunk(i).dataPointer);
                    ind =
                        i +
                        NJPEGChunks -
                        NHTMLChunks -
                        N_EMPTY_BLUE_COLOR_CHUNKS -
                        N_EMPTY_RED_COLOR_CHUNKS +
                        TOKEN_ID_FIRST_BLUE_CHROMINANCE -
                        TOKEN_ID_FIRST_RED_CHROMINANCE +
                        3;
                    bytesSegments[ind] = tempChunk;
                }
            }

            // Add empty red color chunks if necessary
            for (
                uint i = NHTMLChunks + N_EMPTY_BLUE_COLOR_CHUNKS;
                i < NHTMLChunks + N_EMPTY_BLUE_COLOR_CHUNKS + N_EMPTY_RED_COLOR_CHUNKS;
                i++
            ) {
                if (chunk.phaseId == 1 || chunk.phaseId == 2) {
                    // B&W and Grey Tones phases need empty red chroma
                    tempChunk = SSTORE2.read(unpackChunk(i).dataPointer);
                    ind = i + NJPEGChunks - NHTMLChunks - N_EMPTY_BLUE_COLOR_CHUNKS - N_EMPTY_RED_COLOR_CHUNKS + 3;
                    bytesSegments[ind] = tempChunk;
                } else if (chunk.phaseId == 3) {
                    // Blue Chroma phase needs empty red chroma
                    tempChunk = SSTORE2.read(unpackChunk(i).dataPointer);
                    ind = i + NJPEGChunks - NHTMLChunks - 2 * N_EMPTY_BLUE_COLOR_CHUNKS - N_EMPTY_RED_COLOR_CHUNKS + 3;
                    bytesSegments[ind] = tempChunk;
                }
            }

            // JPEG footer
            bytesSegments[ind + 1] = jpegFooter();

            // Correct number JPEG chunks (exclude empty chroma and blue chroma if necessary)
            if (chunk.phaseId == 3 || chunk.phaseId == 5) NJPEGChunks -= N_EMPTY_BLUE_COLOR_CHUNKS;
            if (chunk.phaseId >= 4) NJPEGChunks -= N_EMPTY_RED_COLOR_CHUNKS;
            if (chunk.phaseId == 4) NJPEGChunks -= TOKEN_ID_FIRST_RED_CHROMINANCE - TOKEN_ID_FIRST_BLUE_CHROMINANCE;
        }

        // HTML chunks
        for (uint256 i = 0; i < NHTMLChunks; i++) {
            ind = i + NJPEGChunks + (chunk.phaseId > 0 ? 4 : 2);
            bytesSegments[ind] = SSTORE2.read(unpackChunk(i).dataPointer);
        }

        // HTML parameters
        bytesSegments[1] = ButerinCardsLib.paramsHTML(tokenId, chunk);

        return string(Array.join(bytesSegments));
    }

    function unpackChunk(uint tokenId) public view returns (ButerinCardsLib.ChunkUnpacked memory) {
        uint chunk = chunks[tokenId];
        return
            ButerinCardsLib.ChunkUnpacked({
                dataPointer: address(uint160(chunk)), // 20 bytes
                phaseId: uint8((chunk >> 160) & 0x7), // 3 bits
                tokenIdWithinPhase: uint16((chunk >> 163) & 0x7FF), // 11 bits
                lastTokenIdInScan: uint16((chunk >> 174) & 0x7FF), // 11 bits
                quoteId: uint8((chunk >> 185) & 0x3F), // 6 bits
                bgDirectionId: uint8((chunk >> 191) & 0x3), // 2 bits
                bgPaletteId: uint8((chunk >> 193) & 0xF), // 4 bits
                Nicons: uint8((chunk >> 197) & 0x3), // 2 bits
                Nbytes: uint32((chunk >> 199) & 0x1FFFFFF), // 25 bits
                seed: uint32((chunk >> 224) & 0xFFFFFFFF) // 32 bits
            });
    }

    function _packChunk(ButerinCardsLib.ChunkUnpacked memory chunk) private pure returns (uint) {
        return
            uint(uint160(chunk.dataPointer)) |
            (uint(chunk.phaseId) << 160) |
            (uint(chunk.tokenIdWithinPhase) << 163) |
            (uint(chunk.lastTokenIdInScan) << 174) |
            (uint(chunk.quoteId) << 185) |
            (uint(chunk.bgDirectionId) << 191) |
            (uint(chunk.bgPaletteId) << 193) |
            (uint(chunk.Nicons) << 197) |
            (uint(chunk.Nbytes) << 199) |
            (uint(chunk.seed) << 224);
    }

    function _rndParams(ButerinCardsLib.ChunkUnpacked memory chunk, uint256 tokenId_) private view {
        uint256 rndUniform = uint256(
            keccak256(
                abi.encodePacked(block.number, block.timestamp, block.basefee, block.coinbase, msg.sender, tokenId_)
            )
        );

        chunk.seed = uint32(rndUniform); // Uniform distribution between 0 and 2**32-1

        uint temp = rndUniform >> 32;
        chunk.bgDirectionId = temp & 0x3 > 1 ? 2 : temp & 0x1 == 1 ? 1 : 0; // Diagonal (2) has 0.5 probability, vertical(1) and horizontal(0) have 0.25 probability

        temp = (rndUniform >> 34) & 0xFFFF; // Use 16 bits to approximate custom distribution between 1 and 10
        if (temp < 0x30A4) chunk.bgPaletteId = 1;
        else if (temp < 0x5C29) chunk.bgPaletteId = 2;
        else if (temp < 0x8290) chunk.bgPaletteId = 3;
        else if (temp < 0xA3D8) chunk.bgPaletteId = 4;
        else if (temp < 0xC000) chunk.bgPaletteId = 5;
        else if (temp < 0xD70B) chunk.bgPaletteId = 6;
        else if (temp < 0xE8F6) chunk.bgPaletteId = 7;
        else if (temp < 0xF5C3) chunk.bgPaletteId = 8;
        else if (temp < 0xFD71) chunk.bgPaletteId = 9;
        else chunk.bgPaletteId = 10;

        temp = (rndUniform >> 240) & 0xFFFF; // Use 16 bits to approximate custom distribution between 0 and 44
        if (temp < 0x02ba) chunk.quoteId = 0;
        else if (temp < 0x0597) chunk.quoteId = 1;
        else if (temp < 0x0897) chunk.quoteId = 2;
        else if (temp < 0x0bb9) chunk.quoteId = 3;
        else if (temp < 0x0efd) chunk.quoteId = 4;
        else if (temp < 0x1264) chunk.quoteId = 5;
        else if (temp < 0x15ed) chunk.quoteId = 6;
        else if (temp < 0x1999) chunk.quoteId = 7;
        else if (temp < 0x1d67) chunk.quoteId = 8;
        else if (temp < 0x2158) chunk.quoteId = 9;
        else if (temp < 0x256b) chunk.quoteId = 10;
        else if (temp < 0x29a0) chunk.quoteId = 11;
        else if (temp < 0x2df8) chunk.quoteId = 12;
        else if (temp < 0x3273) chunk.quoteId = 13;
        else if (temp < 0x3710) chunk.quoteId = 14;
        else if (temp < 0x3bcf) chunk.quoteId = 15;
        else if (temp < 0x40b1) chunk.quoteId = 16;
        else if (temp < 0x45b5) chunk.quoteId = 17;
        else if (temp < 0x4adb) chunk.quoteId = 18;
        else if (temp < 0x5024) chunk.quoteId = 19;
        else if (temp < 0x5590) chunk.quoteId = 20;
        else if (temp < 0x5b1e) chunk.quoteId = 21;
        else if (temp < 0x60ce) chunk.quoteId = 22;
        else if (temp < 0x66a1) chunk.quoteId = 23;
        else if (temp < 0x6c96) chunk.quoteId = 24;
        else if (temp < 0x72ae) chunk.quoteId = 25;
        else if (temp < 0x78e8) chunk.quoteId = 26;
        else if (temp < 0x7f45) chunk.quoteId = 27;
        else if (temp < 0x85c4) chunk.quoteId = 28;
        else if (temp < 0x8c65) chunk.quoteId = 29;
        else if (temp < 0x9329) chunk.quoteId = 30;
        else if (temp < 0x9a0f) chunk.quoteId = 31;
        else if (temp < 0xa118) chunk.quoteId = 32;
        else if (temp < 0xa843) chunk.quoteId = 33;
        else if (temp < 0xaf91) chunk.quoteId = 34;
        else if (temp < 0xb701) chunk.quoteId = 35;
        else if (temp < 0xbe93) chunk.quoteId = 36;
        else if (temp < 0xc648) chunk.quoteId = 37;
        else if (temp < 0xce20) chunk.quoteId = 38;
        else if (temp < 0xd61a) chunk.quoteId = 39;
        else if (temp < 0xde36) chunk.quoteId = 40;
        else if (temp < 0xe675) chunk.quoteId = 41;
        else if (temp < 0xeed6) chunk.quoteId = 42;
        else if (temp < 0xf759) chunk.quoteId = 43;
        else chunk.quoteId = 44;
    }

    /// @param dataChunk will be a piece of HTML in UTF-8 or a piece of JPEG in base64
    function mine(
        string calldata dataChunk,
        uint8 phaseId,
        uint16 tokenIdWithinPhase,
        uint16 lastTokenIdInScan,
        bytes32[] calldata proof
    ) external {
        // Get the next tokenIdx
        uint256 tokenId = totalSupply();

        // Check hash matches
        _verifyDataChunk(dataChunk, tokenId, phaseId, tokenIdWithinPhase, lastTokenIdInScan, proof);

        // Generate random color, quote and seed
        ButerinCardsLib.ChunkUnpacked memory chunk;
        _rndParams(chunk, tokenId);

        // Pass rest of data
        chunk.dataPointer = SSTORE2.write(bytes(dataChunk));
        chunk.phaseId = phaseId;
        chunk.tokenIdWithinPhase = tokenIdWithinPhase;
        chunk.lastTokenIdInScan = lastTokenIdInScan;
        chunk.Nicons = uint8(Nmined[msg.sender] % 3);
        chunk.Nbytes = uint32(bytes(dataChunk).length);
        if (tokenId > 0) chunk.Nbytes += unpackChunk(tokenId - 1).Nbytes;

        // Pack and store chunk
        chunks.push(_packChunk(chunk));

        // Mint card
        _mint(msg.sender, tokenId);

        // Increment counter of mined cards by sender
        Nmined[msg.sender]++;

        // Emit event
        emit Mined(
            msg.sender,
            bytes(dataChunk).length,
            tokenId,
            phaseId,
            tokenIdWithinPhase,
            chunk.quoteId,
            chunk.bgDirectionId,
            chunk.bgPaletteId,
            lastTokenIdInScan,
            chunk.Nbytes,
            chunk.Nicons,
            chunk.seed
        );
    }

    function _verifyDataChunk(
        string calldata dataChunk,
        uint256 tokenId,
        uint8 phaseId,
        uint16 tokenIdWithinPhase,
        uint16 lastTokenIdInScan,
        bytes32[] calldata proof
    ) private view {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(dataChunk, tokenId, phaseId, tokenIdWithinPhase, lastTokenIdInScan)))
        );
        require(MerkleProof.verifyCalldata(proof, _ROOT, leaf), "Invalid data");
    }

    function htmlHeader() public pure returns (bytes memory) {
        return
            bytes(
                "data:text/html;charset=utf-8,%3C!DOCTYPE%20html%3E%0D%0A%3Chtml%3E%0D%0A%20%20%20%20%3Chead%3E%0D%0A%20%20%20%20%20%20%20%20%3Cscript%3E%0D%0A%20%20%20%20%20%20%20%20%20%20%20%20var%20%5B%0D%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20cardId%2C%0D%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20phaseId%2C%0D%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20tokenIdWithinPhase%2C%0D%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20kiloBytes%2C%0D%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20quoteId%2C%0D%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20bgDirection%2C%0D%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20bgPalette%2C%0D%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20Nicons%2C%0D%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20seed%2C%0D%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20jpegB64%0D%0A%20%20%20%20%20%20%20%20%20%20%20%20%5D%20%3D%20%5B"
            );
    }

    function jpegFooter() public pure returns (bytes memory) {
        return bytes("/9k=");
    }
}
