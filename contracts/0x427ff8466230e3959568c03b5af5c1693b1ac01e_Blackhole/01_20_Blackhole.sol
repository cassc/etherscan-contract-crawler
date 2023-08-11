// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./IBlackholeRenderer.sol";
import "./Withdrawable.sol";

/**
 *                                  the Black Hole
 *                   generates on-chain perpetual NFTs every 8th block.
 *                      mint, price goes up. burn, price goes down.
 *                             all ETH fall into its mass.
 *          the Black Hole dissolves after 42 hours with no burns and no mints.
 *                  last address that burnt their NFT, owns the mass.
 *                            tokens #1 to #10 are special.
 *
 *                              with love, by miragenesi.
 */

//                                   .
//                                                          .
//                                    .           .
//                                        .          .
//                                .    .    . .    .    . .
//                                 .    ..  .    ...   ..    .     .
//                        .    .   .. :    .... ...  .  ..   .    .    .
//                     .   .   : .  . .:.::.    .!^    .:.  . .:  .
//          .        .  .  .    .: ... . :77^::^~??: ...!7.   ..    .  .        .
//                         ... : ::^!!!~7?77~~77777~~????^..  ..^....     .   .
//                 .  . .   :..::^:7J!!~^:.         ..:^~!!7?7!~^:   .   . .
//             .        :: .:::!?77~:                     .:!?!^:.    . ..    .
//                  . . .:..^:7!!:                            ^??!!!^.::
//              .     :  ::!7?7:                                ^!7:..^:  .  .   .
//           .    . . :.::.?J^                                   .!J?^:     ..
//             .    . ..:!!?:                                      ~?~~~:  .   . . .
//                ...:.:^?J:                                        !?^..^::
//          .  . .   .::~?!                                          ?Y7:.^. ...
//           .  .. ...:^J?                                           ^YJ~ ^ . . .  .
//                ...:.!~?:                                          ~Y!!:.~. .. .
//   .        .  .. ..::^J!                                          ?JJ^:
//    .    .   .   .:..:~??^                                        !7:~?:   .     .
//          .     .   .:^~7?:                                      ~J7  !. . ..  .   .
//                  ..:..^:!J^                                   .~??J. ^^.       .     .
//             .  .     .:^!7?7:                                ^77..!  ^:.
//         .     .  . . :...^^7?~:                            ^?J?! ^:  ^ ..   .       .
//                 .  .  . ^:..!7!7~:                     .:!J7:^! ::  .:       .
//            .      .   . .. ^^.^^7J?~~^:.         ..:^~~7!?7.:: .:   :   .
//              .      .   .. .: :^ ~7^^!?J?!^!7777!~!JJ7:.^^.:. :.   .:      .
//                       .  . .. .:  ^..^^~!~.:~77~:.^~::.:... .:    ..         .
//                            .  .  .. ....:.::.:: :. :...   ...    ..   . .
//                        . .       . .. .  . .. . . . .   ..      ..
//                            .  . . .    . . .. . .    ...      ..    .
//                                                   ..        ..
//                                           . . .           ..
//                                                            .
//                                                       .

contract Blackhole is
    ERC721,
    ERC2981,
    DefaultOperatorFilterer,
    Ownable,
    Withdrawable
{
    struct Mintable {
        bool minted;
        uint256 seed;
    }

    uint256 constant MINTABLE_BLOCK_INTERVAL = 8;
    uint256 constant MAX_MINTABLE_PER_WINDOW = 256 / MINTABLE_BLOCK_INTERVAL;
    uint256 public constant TIME_TO_COLLAPSE = 42 hours;
    uint256 public constant SPECIAL_TOKENS = 10;
    uint256 public constant CREATOR_SHARE = 5; // %
    uint256 public constant SPECIAL_TOKEN_SHARE = 1; // %

    IBlackholeRenderer internal _renderer;

    mapping(uint256 => bool) public withdrawnToken;
    mapping(uint256 => bool) public blockUsed;
    uint256[] public mintedSeeds;
    bool public withdrawnCreator;
    bool public withdrawnLast;

    uint256 public immutable increase;
    uint256 public immutable minPrice;
    uint256 public lastTimestamp;
    address public lastBurner;
    uint256 public burnt;

    constructor(
        address renderer,
        uint256 minPrice_,
        uint256 increase_
    ) ERC721("BLACKHOLE", "HOLE") {
        _renderer = IBlackholeRenderer(renderer);
        minPrice = minPrice_;
        increase = increase_;
        lastTimestamp = block.timestamp;
    }

    modifier notDissolved() {
        require(
            block.timestamp < lastTimestamp + TIME_TO_COLLAPSE ||
                mintedSeeds.length < SPECIAL_TOKENS,
            "dissolved"
        );
        _;
    }

    modifier dissolved() {
        require(
            block.timestamp >= lastTimestamp + TIME_TO_COLLAPSE &&
                mintedSeeds.length >= SPECIAL_TOKENS,
            "not dissolved"
        );
        _;
    }

    receive() external payable {}

    // Admin

    function setRenderer(IBlackholeRenderer renderer) public onlyOwner {
        _renderer = IBlackholeRenderer(renderer);
    }

    // NFT logic

    function currentPrice() public view returns (uint256) {
        return minPrice + (increase * mintedSeeds.length) - (increase * burnt);
    }

    function minted() public view returns (uint256) {
        return mintedSeeds.length;
    }

    function mint(uint256 blockNumber) public payable notDissolved {
        require(msg.value >= currentPrice(), "not enough ether");
        require(!blockUsed[blockNumber], "block already minted");
        require(blockNumber >= block.number - 256, "block too old");
        require(blockNumber % MINTABLE_BLOCK_INTERVAL == 0, "invalid block");

        blockUsed[blockNumber] = true;
        lastTimestamp = block.timestamp;
        mintedSeeds.push(uint256(blockhash(blockNumber)));
        super._mint(msg.sender, mintedSeeds.length);
    }

    function burn(uint256 tokenId) public notDissolved {
        require(tokenId > SPECIAL_TOKENS, "can't burn a special token");
        require(ownerOf(tokenId) == msg.sender, "not the owner");
        lastBurner = msg.sender;
        burnt++;
        lastTimestamp = block.timestamp;

        _burn(tokenId);
    }

    function render(uint256 seed) public view returns (string memory) {
        return _renderer.renderSVG(seed, 0, false);
    }

    function mintable()
        public
        view
        returns (
            uint256[MAX_MINTABLE_PER_WINDOW] memory blocks,
            uint256[MAX_MINTABLE_PER_WINDOW] memory seeds,
            uint256[MAX_MINTABLE_PER_WINDOW] memory tokenIds
        )
    {
        uint256 currentBlockNumber = block.number; // Get the block number before the current one
        uint256 startingBlock = currentBlockNumber;
        while (
            startingBlock % MINTABLE_BLOCK_INTERVAL != 0 ||
            uint256(blockhash(startingBlock)) == 0
        ) {
            startingBlock--;
        }
        uint256 index = 0;
        uint256 minTokenId = 0;
        if (mintedSeeds.length > MAX_MINTABLE_PER_WINDOW) {
            minTokenId = mintedSeeds.length - MAX_MINTABLE_PER_WINDOW;
        }
        for (
            uint256 i = startingBlock;
            i > currentBlockNumber - 256;
            i -= MINTABLE_BLOCK_INTERVAL
        ) {
            seeds[index] = uint256(blockhash(i));
            blocks[index] = i;
            for (uint256 j = mintedSeeds.length; j > minTokenId; j--) {
                if (mintedSeeds[j - 1] == seeds[index]) {
                    tokenIds[index] = j;
                    break;
                }
            }
            index++;
        }
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        bool showStar = false;
        if (tokenId <= SPECIAL_TOKENS && !withdrawnToken[tokenId]) {
            showStar = true;
        }
        return _renderer.renderSVG(mintedSeeds[tokenId - 1], tokenId, showStar);
    }

    // Blackhole logic
    function withdraw() public dissolved {
        require(lastBurner == msg.sender, "not the last one");
        require(withdrawnLast == false, "already withdrawn");
        withdrawnLast = true;
        _withdraw();
    }

    function withdrawCreator() public onlyOwner notDissolved {
        require(withdrawnCreator == false, "already withdrawn");
        withdrawnCreator = true;
        _withdrawShare(CREATOR_SHARE);
    }

    function withdrawToken(uint256 tokenId) public notDissolved {
        require(withdrawnToken[tokenId] == false, "already withdrawn");
        require(_ownerOf(tokenId) == msg.sender, "not the owner");
        require(tokenId <= SPECIAL_TOKENS, "invalid token id");
        withdrawnToken[tokenId] = true;
        _withdrawShare(SPECIAL_TOKEN_SHARE);
    }

    // Royalty enforcement

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public virtual onlyOwner {
        super._setDefaultRoyalty(receiver, feeNumerator);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC2981) returns (bool) {
        return
            ERC721.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}