// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {IERC2981} from "openzeppelin-contracts/contracts/interfaces/IERC2981.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

interface MetadataRenderer {
    function contractURI() external view returns (string memory);

    function render(uint256 id) external view returns (string memory);
}

error ArtistsGottaSurvive();
error MaxSupply();
error NonExistentTokenURI();

contract ArtistBingo is ERC721, Ownable {
    uint256 public constant MAX_SUPPLY = 250;
    uint8 public constant TOTAL_ACTS = 128;
    uint256 public constant PRICE = 0.05 ether;
    uint256 public nextTokenIdToMint;

    // accomplishments is a bitfield of which acts have been accomplished
    uint256 public accomplishments;

    // a card is a uint256 in which each byte-length block holds an act id
    mapping(uint256 => uint256) public cards;

    // (initial) an off-chain baseUri for rendering metadata
    string public baseUri;

    // (optional) an on-chain renderer for a given token id
    MetadataRenderer public renderer;

    event AccomplishmentsUpdated(
        uint256 indexed change,
        uint256 accomplishments
    );
    event MetadataRendererUpdated(MetadataRenderer renderer);

    constructor(string memory _baseUri) ERC721("Artist Bingo", "BINGO") {
        baseUri = _baseUri;

        // mint initial artist edition to deployer
        _safeMint(msg.sender, nextTokenIdToMint);
        unchecked {
            nextTokenIdToMint++;
        }
    }

    function mint(address to, uint256 amount) external payable {
        if (msg.value != amount * PRICE) revert ArtistsGottaSurvive();
        if (nextTokenIdToMint + amount > MAX_SUPPLY) revert MaxSupply();

        for (uint256 i = 0; i < amount; ) {
            _safeMint(to, nextTokenIdToMint);
            unchecked {
                nextTokenIdToMint++;
                i++;
            }
        }
    }

    function _mint(address to, uint256 id) internal virtual override {
        // generate pseudo-random card for this token id
        cards[id] = uint256(
            keccak256(
                abi.encodePacked(
                    id,
                    msg.sender,
                    blockhash(block.number - 1),
                    "shrugs wuz here"
                )
            )
        );
        super._mint(to, id);
    }

    function getPalette(uint256 id) external view returns (uint8) {
        // the 25th slot is a palette id, [0, 255]
        uint8 seed = uint8(cards[id] >> (8 * (31 - 24)));

        if (seed < 61) return 0; //  23.82%
        if (seed < 102) return 1; // 16.01%
        if (seed < 143) return 2; // 16.01%
        if (seed < 169) return 3; // 10.15%
        if (seed < 195) return 4; // 10.15%
        if (seed < 220) return 5; // 09.76%
        if (seed < 236) return 6; // 06.25%
        if (seed < 252) return 7; // 06.25%
        return 8; //                 01.56%
    }

    function getActs(uint256 id) external view returns (uint8[] memory) {
        uint256 squares = cards[id];

        uint256 used; // bitmap that tracks whether a specific number has been seen
        uint8 counter;
        uint8 seed;
        uint8 act;

        uint8[] memory acts = new uint8[](24);

        for (uint256 i = 0; i < 24; i++) {
            // get byte `seed` from word `squares`
            seed = uint8(squares >> (8 * (31 - i)));

            // reset counter for loop
            counter = 0;

            // determine next non-duplicate act
            while (true) {
                // derive an act
                act = (seed + counter) % TOTAL_ACTS;

                // if the act has not been seen, break
                if ((used & (1 << act)) == 0) break;

                // otherwise, increment counter and loop
                counter++;
            }

            // an act has been found

            // mark act as seen
            used |= (1 << act);

            // include in acts
            acts[i] = act;
        }

        return acts;
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    // this function strictly sets accomplishments to the provided argument
    // but also publishes the change from the current state as an audit trail
    function setAccomplishments(uint256 _accomplishments) external onlyOwner {
        emit AccomplishmentsUpdated(
            _accomplishments ^ accomplishments,
            _accomplishments
        );
        accomplishments = _accomplishments;
    }

    function setMetadataRenderer(
        MetadataRenderer _renderer
    ) external onlyOwner {
        renderer = _renderer;
        emit MetadataRendererUpdated(_renderer);
    }

    function withdraw(address to) external onlyOwner {
        SafeTransferLib.safeTransferETH(to, address(this).balance);
    }

    function contractURI() public view returns (string memory) {
        if (address(renderer) != address(0)) return renderer.contractURI();
        return string.concat(baseUri, "contract.json");
    }

    function tokenURI(
        uint256 id
    ) public view virtual override returns (string memory) {
        if (ownerOf(id) == address(0)) revert NonExistentTokenURI();
        if (address(renderer) != address(0)) return renderer.render(id);
        return string.concat(baseUri, Strings.toString(id));
    }

    function royaltyInfo(
        uint256,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        return (owner(), (salePrice * 5) / 100); // 5% royalties
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}