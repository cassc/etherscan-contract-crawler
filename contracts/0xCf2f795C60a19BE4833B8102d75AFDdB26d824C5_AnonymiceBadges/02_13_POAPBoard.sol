/* solhint-disable quotes */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721UniqueBound.sol";
import "./IPOAPBoard.sol";
import "./POAPLibrary.sol";

contract POAPBoard is Ownable, ERC721UniqueBound {
    mapping(uint256 => mapping(address => bool)) internal _poapOwners;
    mapping(address => mapping(uint256 => uint256)) internal _poaps;

    uint256 public boardCount;
    uint256 public poapCount;
    mapping(uint256 => POAPLibrary.Board) public boards;
    mapping(address => uint256) public currentBoard;
    mapping(address => uint256) public poapsBalanceOf;
    mapping(uint256 => bytes32) public merkleRootsByPOAPId;
    mapping(uint256 => bytes32) public merkleRootsByBoardId;
    mapping(address => mapping(uint256 => bool)) public availableBoards;
    mapping(address => mapping(uint256 => uint256)) public poapPositions;

    constructor(string memory name_, string memory symbol_) ERC721UniqueBound(name_, symbol_) {}

    function mint() external virtual {
        _mint(msg.sender);
        availableBoards[msg.sender][1] = true;
        currentBoard[msg.sender] = 1;
    }

    function claimBoard(uint256 boardId, bytes32[] calldata proof) external {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRootsByBoardId[boardId], leaf), "not in whitelist");
        _claimBoard(boardId, msg.sender);
    }

    function claimPOAP(uint256 id, bytes32[] calldata proof) public {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRootsByPOAPId[id], leaf), "not in whitelist");
        _claimPOAP(id, msg.sender);
    }

    function setCurrentBoard(uint256 boardId) external {
        _swapBoard(boardId, true);
    }

    function rearrangeBoard(uint256 boardId, uint256[] memory slots) external {
        if (boardId != currentBoard[msg.sender]) _swapBoard(boardId, false);
        _rearrangePOAPs(slots);
    }

    function rearrangePOAPs(uint256[] memory slots) external {
        _rearrangePOAPs(slots);
    }

    function _rearrangePOAPs(uint256[] memory slots) internal {
        POAPLibrary.Board memory selectedBoard = boards[currentBoard[msg.sender]];
        require(slots.length == selectedBoard.slots.length, "wrong size");
        for (uint256 index = 0; index < slots.length; index++) {
            uint256 poapId = slots[index];
            for (uint256 innerIndex = 0; innerIndex < index; innerIndex++) {
                require(poapId == 0 || poapId != slots[innerIndex], "already used");
            }
            poapPositions[msg.sender][index] = _poapOwners[poapId][msg.sender] ? poapId : 0;
        }
    }

    function _swapBoard(uint256 boardId, bool shouldWipe) internal {
        require(currentBoard[msg.sender] != boardId, "same board");
        require(availableBoards[msg.sender][boardId], "locked board");

        currentBoard[msg.sender] = boardId;
        if (shouldWipe) {
            POAPLibrary.Board memory selectedBoard = boards[boardId];
            for (uint256 index = 0; index < selectedBoard.slots.length; index++) {
                poapPositions[msg.sender][index] = 0;
            }
        }
    }

    function getAllPOAPs(address wallet) public view returns (uint256[] memory) {
        uint256 poapsCount = poapsBalanceOf[wallet];
        uint256[] memory poaps = new uint256[](poapsCount);
        for (uint256 index = 0; index < poapsCount; index++) {
            poaps[index] = _poaps[wallet][index];
        }
        return poaps;
    }

    function getBoardPOAPs(address wallet) public view returns (uint256[] memory) {
        POAPLibrary.Board memory selectedBoard = boards[currentBoard[wallet]];
        uint256[] memory poaps = new uint256[](selectedBoard.slots.length);
        for (uint256 index = 0; index < poaps.length; index++) {
            poaps[index] = poapPositions[wallet][index];
        }
        return poaps;
    }

    function getBoards(address wallet) public view returns (POAPLibrary.Board[] memory) {
        uint256 walletCount;
        for (uint256 boardId = 1; boardId <= boardCount; boardId++) {
            if (availableBoards[wallet][boardId]) {
                walletCount++;
            }
        }
        POAPLibrary.Board[] memory walletBoards = new POAPLibrary.Board[](walletCount);
        uint256 walletBoardsIndex;
        for (uint256 boardId = 1; boardId <= boardCount; boardId++) {
            if (availableBoards[wallet][boardId]) {
                walletBoards[walletBoardsIndex++] = boards[boardId];
            }
        }
        return walletBoards;
    }

    function getCurrentBoard(address wallet) public view returns (POAPLibrary.Board memory) {
        return boards[currentBoard[wallet]];
    }

    function getWalletState(address wallet)
        external
        view
        returns (
            uint256[] memory,
            POAPLibrary.Board[] memory,
            POAPLibrary.Board memory
        )
    {
        return (getAllPOAPs(wallet), getBoards(wallet), getCurrentBoard(wallet));
    }

    function getBoard(uint256 boardId) external view returns (POAPLibrary.Board memory) {
        return boards[boardId];
    }

    function _claimPOAP(uint256 poapId, address to) internal existingPOAP(poapId) {
        if (_poapOwners[poapId][to]) return;
        _poapOwners[poapId][to] = true;
        _poaps[to][poapsBalanceOf[to]] = poapId;
        poapsBalanceOf[to]++;
    }

    function _claimBoard(uint256 boardId, address to) internal existingBoard(boardId) {
        require(_minted(to), "mint required");
        require(!availableBoards[to][boardId], "already claimed");
        availableBoards[to][boardId] = true;
    }

    // OWNER FUNCTIONS

    function registerBoard(
        uint64 width,
        uint64 height,
        POAPLibrary.Slot[] memory slots
    ) external onlyOwner {
        boardCount++;
        POAPLibrary.Board storage newBoard = boards[boardCount];
        newBoard.id = uint128(boardCount);
        newBoard.width = width;
        newBoard.height = height;
        for (uint256 index = 0; index < slots.length; index++) {
            newBoard.slots.push(slots[index]);
        }
    }

    function registerPOAP() external onlyOwner {
        poapCount++;
    }

    function setPOAPCount(uint256 count) external onlyOwner {
        poapCount = count;
    }

    function overrideBoard(
        uint128 id,
        uint64 width,
        uint64 height,
        POAPLibrary.Slot[] memory slots
    ) external onlyOwner existingBoard(id) {
        POAPLibrary.Board storage newBoard = boards[id];
        newBoard.id = id;
        newBoard.width = width;
        newBoard.height = height;
        uint256 oldSlotsSize = newBoard.slots.length; // 3
        for (uint256 index = 0; index < slots.length; index++) {
            if (oldSlotsSize <= index) {
                newBoard.slots.push(slots[index]);
            } else {
                newBoard.slots[index] = slots[index];
            }
        }
    }

    function setMerkleRootsByPOAPId(uint256 poapId, bytes32 merkleRoot) external onlyOwner {
        merkleRootsByPOAPId[poapId] = merkleRoot;
    }

    function setMerkleRootsByBoardId(uint256 boardId, bytes32 merkleRoot) external onlyOwner {
        merkleRootsByBoardId[boardId] = merkleRoot;
    }

    modifier existingBoard(uint256 boardId) {
        require(boardId <= boardCount, "unknown board");
        _;
    }

    modifier existingPOAP(uint256 poapId) {
        require(poapId <= poapCount, "unknown poap");
        _;
    }
}
/* solhint-enable quotes */