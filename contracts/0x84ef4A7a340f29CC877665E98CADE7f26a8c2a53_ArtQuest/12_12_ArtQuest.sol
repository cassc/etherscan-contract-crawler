// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @custom:security-contact [email protected]
/// @custom:copyright © BlockChain Magic Pte Ltd // MMXXIII
/// @custom:info Kudos to the Prometheans (https://prometheans.xyz) for the
/// original idea

contract ArtQuest is ERC721, Ownable {
    using Address for address;
    using Strings for uint256;
    using Strings for uint48;

    // * Variables
    uint256 public immutable TIMER; // 90 Ethereum blocks - 18 minutes
    uint256 public immutable MAX_RESTARTS; // 31 restarts max

    uint256 public currentId;
    uint256 public lowestTick;
    uint256 public restartedAtBlock;
    uint256 public restartCount;

    // Metadata base URI
    string public baseURI;

    // Payout addresse
    address public W0;

    mapping(uint256 => TokenData) public tokens;

    struct TokenData {
        address owner;
        uint48 mintingBlock;
        uint48 mintingRound;
        uint48 tick;
    }

    // * Events
    event Minted(
        uint256 id,
        address indexed owner,
        uint256 indexed blockNumber,
        uint256 tick
    );
    event Restarted(uint256 blockNumber);
    event BaseURIUpdated(string indexed baseURI, address indexed updatedBy);
    event WithdrawalWalletUpdated(
        address indexed W0,
        address indexed updatedBy
    );
    event WithdrawCalled(address indexed calledBy, uint256 balance);

    // * Custom Errors
    error MintEndedForever();
    error TimerEnded();
    error RestartNotRequired();
    error InvalidTokenId(uint256 tokenId);
    error NoFundsToWithdraw();
    error NoAddressZero();

    constructor(
        string memory baseURI_,
        address W0_,
        uint256 timer_,
        uint256 max_restarts_
    ) ERC721("ArtQuest", "ARQ") {
        if (W0_ == address(0)) revert NoAddressZero();

        baseURI = baseURI_;
        W0 = W0_;
        TIMER = timer_;
        MAX_RESTARTS = max_restarts_;
        // Set the lowest tick to the timer value
        lowestTick = TIMER;
    }

    /**
     * @dev Public function to retrieve the contract description for OpenSea
     */
    function contractURI() external view returns (string memory) {
        return string(abi.encodePacked(baseURI, "contract.json"));
    }

    /**
     * @dev Public function that returns the status
     *
     * - return -3 if the mint has ended -> game over!
     * - return -2 if the timer has not started
     * - return -1 if the timer has ended
     * - return the value of current tick (0-90)
     */
    function timerStatus() public view returns (int256) {
        // Game Over!
        if (restartCount == MAX_RESTARTS && timerEnded()) return -3;

        // Timer has not started, no NFT minted yet or timer restarted and no mint after restart yet
        if (currentId == 0 || restartedAtBlock > tokens[currentId].mintingBlock)
            return -2;

        // Timer has ended but the game is not over
        if (timerEnded()) return -1;

        // Timer is running, return current tick
        return int256(TIMER - (block.number - lastMinted()));
    }

    /**
     * @dev Public function that returns true if the timer has ended
     */
    function timerEnded() internal view returns (bool) {
        return TIMER <= block.number - lastMinted();
    }

    /**
     * @dev Public function that returns the current tick if the timer has not ended
     */
    function currentTick() public view returns (uint256) {
        if (timerEnded()) revert TimerEnded();
        return TIMER - (block.number - lastMinted());
    }

    /**
     * @dev Public function that returns the block number of the last token minted, or the current block number if:
     * - no tokens minted yet
     * - the timer has been restarted
     */
    function lastMinted() public view returns (uint256) {
        return
            currentId == 0 || restartedAtBlock > tokens[currentId].mintingBlock
                ? block.number
                : tokens[currentId].mintingBlock;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 id_
    ) public view override returns (string memory) {
        if (!_exists(id_)) revert InvalidTokenId(id_);
        TokenData memory token = tokens[id_];
        return
            string(
                abi.encodePacked(
                    baseURI,
                    "/",
                    id_.toString(),
                    "/",
                    token.tick.toString(),
                    "/",
                    token.mintingBlock.toString()
                )
            );
    }

    /**
     * @dev Public function that restarts the timer, maximum of MAX_RESTARTS
     * times
     */
    function restart() external onlyOwner {
        if (restartCount == MAX_RESTARTS) revert MintEndedForever();
        if (!timerEnded()) revert RestartNotRequired();
        restartCount++;
        restartedAtBlock = block.number;
        emit Restarted(restartedAtBlock);
    }

    /**
     * @dev Mint a token to the msg.sender address
     */
    function mint() external payable {
        // The game is over, forever!
        if (timerStatus() == -3) revert MintEndedForever();

        uint256 elapsed = block.number - lastMinted();
        if (TIMER < elapsed) revert TimerEnded();

        uint256 tick = TIMER - elapsed;
        if (tick < lowestTick) lowestTick = tick;

        emit Minted(++currentId, msg.sender, block.number, tick);

        safeMint(msg.sender, currentId, tick);
    }

    /**
     * @dev Update the struct and call {IERC721-_safeMint}.
     */
    function safeMint(address to, uint256 id, uint256 tick) internal {
        tokens[id].owner = to;
        tokens[id].mintingBlock = uint48(block.number);
        tokens[id].mintingRound = uint48(restartCount);
        tokens[id].tick = uint48(tick);

        _safeMint(to, id);
    }

    /**
     * @dev Set the address of the withdrawal wallet
     *
     * @param W0_ Base URI for computing {tokenURI}
     */
    function setW0(address W0_) external onlyOwner {
        W0 = W0_;
        emit WithdrawalWalletUpdated(W0, msg.sender);
    }

    /**
     * @dev Set Base URI for computing {tokenURI}
     *
     * @param baseURI_ Base URI for computing {tokenURI}
     */
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
        emit BaseURIUpdated(baseURI, msg.sender);
    }

    /// @notice Transfer pending balance to the owners.
    function withdraw() external {
        uint256 balance = address(this).balance;
        if (balance == 0) revert NoFundsToWithdraw();
        Address.sendValue(payable(W0), balance);
        emit WithdrawCalled(msg.sender, balance);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}