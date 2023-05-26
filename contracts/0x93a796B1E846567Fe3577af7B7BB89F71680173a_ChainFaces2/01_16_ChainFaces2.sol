// SPDX-License-Identifier: GPLv3

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./ChainFaces2Renderer.sol";
import "./ChainFaces2Errors.sol";

contract ChainFaces2 is ERC721, ERC721Enumerable, Ownable {

    /*************************
     COMMON
     *************************/

    // Sale stage enum
    enum Stage {
        STAGE_COMPLETE,
        STAGE_PRESALE,
        STAGE_MAIN_SALE
    }

    bool balanceNotWithdrawn;

    constructor(uint256 _tokenLimit, uint256 _secretCommit, address _renderer, bytes32 _merkleRoot) ERC721("ChainFaces Arena", unicode"ლ⚈෴⚈ლ")  {
        tokenLimit = _tokenLimit;
        secret = _secretCommit;
        merkleRoot = _merkleRoot;
        balanceNotWithdrawn = true;

        // Start in presale stage
        stage = Stage.STAGE_PRESALE;

        renderer = ChainFaces2Renderer(_renderer);

        // Mint ancients
        for (uint256 i = 0; i < 10; i++) {
            _createFace();
        }
    }

    fallback() external payable {}

    /*************************
     TOKEN SALE
     *************************/

    Stage public               stage;
    uint256 public             saleEnds;
    uint256 public immutable   tokenLimit;

    // Merkle distributor values
    bytes32 immutable merkleRoot;
    mapping(uint256 => uint256) private claimedBitMap;

    uint256 public constant saleLength = 60 minutes;
    uint256 public constant salePrice = 0.069 ether;

    uint256 secret;             // Entropy supplied by owner (commit/reveal style)
    uint256 userSecret;         // Pseudorandom entropy provided by minters

    // -- MODIFIERS --

    modifier onlyMainSaleOpen() {
        if (stage != Stage.STAGE_MAIN_SALE || mainSaleComplete()) {
            revert SaleNotOpen();
        }
        _;
    }

    modifier onlyPreSale() {
        if (stage != Stage.STAGE_PRESALE) {
            revert NotPreSaleStage();
        }
        _;
    }

    modifier onlyMainSale() {
        if (stage != Stage.STAGE_MAIN_SALE) {
            revert NotMainSaleStage();
        }
        _;
    }

    modifier onlySaleComplete() {
        if (stage != Stage.STAGE_COMPLETE) {
            revert SaleNotComplete();
        }
        _;
    }

    // -- VIEW METHODS --

    function mainSaleComplete() public view returns (bool) {
        return block.timestamp >= saleEnds || totalSupply() == tokenLimit;
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    // -- OWNER METHODS --

    // Reveal the faces
    function theGreatReveal(uint256 _secretReveal) external onlyOwner onlyMainSale {
        if (!mainSaleComplete()) {
            revert MainSaleNotComplete();
        }

        if (uint256(keccak256(abi.encodePacked(_secretReveal))) != secret) {
            revert InvalidReveal();
        }

        // Final secret is XOR between the pre-committed secret and the pseudo-random user contributed salt
        secret = _secretReveal ^ userSecret;

        // Won't be needing this anymore
        delete userSecret;

        stage = Stage.STAGE_COMPLETE;
    }

    // Start main sale
    function startMainSale() external onlyOwner onlyPreSale {
        stage = Stage.STAGE_MAIN_SALE;
        saleEnds = block.timestamp + saleLength;
    }

    // Withdraw sale proceeds
    function withdraw() external onlyOwner {
        // Owner can't reneg on bounty
        if (arenaActive()) {
            revert ArenaIsActive();
        }

        balanceNotWithdrawn = false;
        owner().call{value : address(this).balance}("");
    }

    // -- USER METHODS --

    function claim(uint256 _index, uint256 _ogAmount, uint256 _wlAmount, bytes32[] calldata _merkleProof, uint256 _amount) external payable onlyPreSale {
        // Ensure not already claimed
        if (isClaimed(_index)) {
            revert AlreadyClaimed();
        }

        // Prevent accidental claim of 0
        if (_amount == 0) {
            revert InvalidClaimAmount();
        }

        // Check claim amount
        uint256 total = _ogAmount + _wlAmount;
        if (_amount > total) {
            revert InvalidClaimAmount();
        }

        // Check claim value
        uint256 paidClaims = 0;
        if (_amount > _ogAmount) {
            paidClaims = _amount - _ogAmount;
        }
        if (msg.value < paidClaims * salePrice) {
            revert InvalidClaimValue();
        }

        // Verify the merkle proof
        bytes32 node = keccak256(abi.encodePacked(_index, msg.sender, _ogAmount, _wlAmount));
        if (!MerkleProof.verify(_merkleProof, merkleRoot, node)) {
            revert InvalidProof();
        }

        // Mark it claimed and mint
        _setClaimed(_index);

        for (uint256 i = 0; i < _amount; i++) {
            _createFace();
        }

        _mix();
    }

    // Mint faces
    function createFace() external payable onlyMainSaleOpen {
        uint256 count = msg.value / salePrice;

        if (count == 0) {
            revert InvalidMintValue();
        } else if (count > 20) {
            count = 20;
        }

        // Don't mint more than supply
        if (count + totalSupply() > tokenLimit) {
            count = tokenLimit - totalSupply();
        }

        // Mint 'em
        for (uint256 i = 0; i < count; i++) {
            _createFace();
        }

        _mix();

        // Send any excess ETH back to the caller
        uint256 excess = msg.value - (salePrice * count);
        if (excess > 0) {
            (bool success,) = msg.sender.call{value : excess}("");
            require(success);
        }
    }

    // -- INTERNAL METHODS --

    function _setClaimed(uint256 index) internal {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function _createFace() internal {
        uint256 tokenId = totalSupply();
        _mint(msg.sender, tokenId);
    }

    function _mix() internal {
        // Add some pseudorandom value which will be mixed with the pre-committed secret
        unchecked {
            userSecret += uint256(blockhash(block.number - 1));
        }
    }

    /*************************
     NFT
     *************************/

    modifier onlyTokenExists(uint256 _id) {
        if (!_exists(_id)) {
            revert NonExistentToken();
        }
        _;
    }

    ChainFaces2Renderer public renderer;

    // -- VIEW METHODS --

    function assembleFace(uint256 _id) external view onlyTokenExists(_id) returns (string memory) {
        return renderer.assembleFace(stage == Stage.STAGE_COMPLETE, _id, getFinalizedSeed(_id));
    }

    function tokenURI(uint256 _id) public view override onlyTokenExists(_id) returns (string memory) {
        return renderer.renderMetadata(stage == Stage.STAGE_COMPLETE, _id, getFinalizedSeed(_id), roundsSurvived[_id], ownerOf(_id));
    }

    function renderSvg(uint256 _id) external view onlyTokenExists(_id) returns (string memory) {
        uint256 rounds;

        // If face is still in the arena, show them with correct amount of scars
        if (ownerOf(_id) == address(this)) {
            rounds = currentRound;
        } else {
            rounds = roundsSurvived[_id];
        }

        return renderer.renderSvg(stage == Stage.STAGE_COMPLETE, _id, getFinalizedSeed(_id), rounds, ownerOf(_id));
    }

    // -- INTERNAL METHODS --

    function getFinalizedSeed(uint256 _tokenId) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(secret, _tokenId)));
    }

    /*************************
     ARENA
     *************************/

    uint256     arenaOpenedBlock;
    uint256     lionsLastFeeding;
    uint256     champion;

    uint256 public currentRound = 0;

    address constant happyFacePlace = 0x7039D65E346FDEEBbc72514D718C88699c74ba4b;
    uint256 public constant arenaWaitBlocks = 6969;
    uint256 public constant blocksPerRound = 69;

    mapping(uint256 => address) warriorDepositor;
    mapping(uint256 => uint256) public roundsSurvived;

    // -- MODIFIERS --

    modifier onlyOpenArena() {
        if (!entryOpen()) {
            revert ArenaEntryClosed();
        }
        _;
    }

    // -- VIEW METHODS --

    struct ArenaInfo {
        uint256 fallen;
        uint256 alive;
        uint256 currentRound;
        uint256 bounty;
        uint256 hunger;
        uint256 nextFeed;
        uint256 champion;
        uint256 entryClosedBlock;
        bool hungry;
        bool open;
        bool active;
        bool gameOver;
    }

    function arenaInfo() external view returns (ArenaInfo memory info) {
        info.fallen = balanceOf(happyFacePlace);
        info.alive = balanceOf(address(this));
        info.currentRound = currentRound;
        info.bounty = address(this).balance;
        info.hunger = howHungryAreTheLions();
        info.champion = champion;
        info.entryClosedBlock = entryClosedBlock();

        if (!theLionsAreHungry()) {
            info.nextFeed = lionsLastFeeding + blocksPerRound - block.number;
        }

        info.hungry = theLionsAreHungry();
        info.open = entryOpen();
        info.active = arenaActive();
        info.gameOver = block.number > info.entryClosedBlock && info.alive <= 1;
    }

    // Return array of msg.senders warriors filtered by alive or fallen
    function myWarriors(bool _alive) external view returns (uint256[] memory) {
        return ownerWarriors(msg.sender, _alive);
    }

    // Return array of owner's warriors filtered by alive or fallen
    function ownerWarriors(address _owner, bool _alive) public view returns (uint256[] memory) {
        address holdingAddress;
        if (_alive) {
            holdingAddress = address(this);
        } else {
            holdingAddress = happyFacePlace;
        }

        uint256 total = balanceOf(holdingAddress);
        uint256[] memory warriors = new uint256[](total);

        uint256 index = 0;

        for (uint256 i = 0; i < total; i++) {
            uint256 id = tokenOfOwnerByIndex(holdingAddress, i);

            if (warriorDepositor[id] == _owner) {
                warriors[index++] = id;
            }
        }

        assembly {
            mstore(warriors, index)
        }

        return warriors;
    }

    function arenaActive() public view returns (bool) {
        return arenaOpenedBlock > 0;
    }

    function entryOpen() public view returns (bool) {
        return arenaActive() && block.number < entryClosedBlock();
    }

    function entryClosedBlock() public view returns (uint256) {
        return arenaOpenedBlock + arenaWaitBlocks;
    }

    function totalSurvivingWarriors() public view returns (uint256) {
        return balanceOf(address(this));
    }

    function howHungryAreTheLions() public view returns (uint256) {
        uint256 totalWarriors = totalSurvivingWarriors();

        if (totalWarriors == 0) {
            return 0;
        }

        uint256 hunger = 1;

        // Calculate how many warriors got eaten (0.2% of warriors > 1000)
        if (totalWarriors >= 2000) {
            uint256 excess = totalWarriors - 1000;
            hunger = excess / 500;
        }

        // Never eat the last man standing
        if (hunger >= totalWarriors) {
            hunger = totalWarriors - 1;
        }

        // Generous upper bound to prevent gas overflow
        if (hunger > 50) {
            hunger = 50;
        }

        return hunger;
    }

    function theLionsAreHungry() public view returns (bool) {
        return block.number >= lionsLastFeeding + blocksPerRound;
    }

    // -- OWNER METHODS --

    function openArena() external payable onlyOwner onlySaleComplete {
        if (arenaActive()) {
            revert ArenaIsActive();
        }
        if (balanceNotWithdrawn) {
            revert BalanceNotWithdrawn();
        }

        // Open the arena
        arenaOpenedBlock = block.number;
        lionsLastFeeding = block.number + arenaWaitBlocks;
    }

    // -- USER METHODS --

    // Can be called every `blocksPerRound` blocks to kill off some eager warriors
    function timeToEat() external {
        if (!arenaActive()) {
            revert ArenaNotActive();
        }
        if (!theLionsAreHungry()) {
            revert LionsNotHungry();
        }

        uint256 totalWarriors = totalSurvivingWarriors();
        if (totalWarriors == 1) {
            revert LastManStanding();
        }
        if (totalWarriors == 0) {
            revert GameOver();
        }

        // The blockhash of every `blocksPerRound` block is used to determine who gets eaten
        uint256 entropyBlock;
        if (block.number - (lionsLastFeeding + blocksPerRound) > 255) {
            // If this method isn't called within 255 blocks of the period end, this is a fallback so we can still progress
            entropyBlock = (block.number / blocksPerRound) * blocksPerRound - 1;
        } else {
            // Use blockhash of every 69th block
            entropyBlock = (lionsLastFeeding + blocksPerRound) - 1;
        }
        uint256 entropy = uint256(blockhash(entropyBlock));
        assert(entropy != 0);

        // Update state
        lionsLastFeeding = block.number;
        currentRound++;

        // Kill off a percentage of warriors
        uint256 killCounter = howHungryAreTheLions();
        bytes memory buffer = new bytes(32);
        for (uint256 i = 0; i < killCounter; i++) {
            uint256 tmp;
            unchecked { tmp = entropy + i; }
            // Gas saving trick to avoid abi.encodePacked
            assembly { mstore(add(buffer, 32), tmp) }
            uint256 whoDied = uint256(keccak256(buffer)) % totalWarriors;
            // Go to your happy place, loser
            uint256 faceToEat = tokenOfOwnerByIndex(address(this), whoDied);
            _transfer(address(this), happyFacePlace, faceToEat);
            // Take one down
            totalWarriors--;
        }

        // Record the champion
        if (totalWarriors == 1) {
            champion = tokenOfOwnerByIndex(address(this), 0);
        }
    }

    function joinArena(uint256 _tokenId) external onlyOpenArena {
        _joinArena(_tokenId);
    }

    function multiJoinArena(uint256[] memory _tokenIds) external onlyOpenArena {
        if (_tokenIds.length > 20) {
            revert InvalidJoinCount();
        }

        for (uint256 i; i < _tokenIds.length; i++) {
            _joinArena(_tokenIds[i]);
        }
    }

    function leaveArena(uint256 _tokenId) external {
        if (warriorDepositor[_tokenId] != msg.sender) {
            revert NotYourWarrior();
        }

        // Can't leave arena if lions are hungry (unless it's the champ and the game is over)
        uint256 survivors = totalSurvivingWarriors();
        if (survivors != 1 && theLionsAreHungry()) {
            revert LionsAreHungry();
        }

        // Can't leave before a single round has passed
        uint256 round = currentRound;
        if (currentRound == 0) {
            revert LeavingProhibited();
        }

        // Record the warrior's achievement
        roundsSurvived[_tokenId] = round;

        // Clear state
        delete warriorDepositor[_tokenId];

        // Return warrior and pay bounty
        uint256 battleBounty = address(this).balance / survivors;
        _transfer(address(this), msg.sender, _tokenId);
        payable(msg.sender).transfer(battleBounty);

        // If this was the second last warrior to leave, the last one left is the champ
        if (survivors == 2) {
            champion = tokenOfOwnerByIndex(address(this), 0);
        }
    }

    // -- INTERNAL METHODS --

    function _joinArena(uint256 _tokenId) internal {
        // Send warrior to the arena
        transferFrom(msg.sender, address(this), _tokenId);
        warriorDepositor[_tokenId] = msg.sender;
    }

    /*************************
     MISC
     *************************/

    function onERC721Received(address, address, uint256, bytes memory) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }
}