// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./IBoardBuilder.sol";

contract TicTacTie is ERC721, IERC1155Receiver, IERC721Receiver {
    IBoardBuilder _boardBuilder =
        IBoardBuilder(0xE3D82449f12581af00433719b4727c0CF8839466);

    address payable _charity =
        payable(0x00B9d7Fe4a2d3aCdd4102Cfb55b98d193B94C0fa);
    uint256 _donations;
    address payable _owner =
        payable(0xf63c1D0B96572C02aEe09761d9254779EA1Ceb2A);

    IERC721 _prize721;
    IERC1155 _prize1155;
    uint256 _prizeTokenId;

    uint256 _currentBoardTokenId;
    uint256 _maxBoardSupply = 70;

    uint256 _price = 0.001945 ether;
    uint256 _minTieId = 500;
    uint256 _startingTieId = _minTieId;

    uint256 internal _leftToMint = 420;
    mapping(uint256 => uint256) internal _idSwaps;

    uint256 _victoriesToWin = 5;

    uint256 constant waitingFlag = 0;
    uint256 constant playingFlag = 1;

    uint256 constant _turnBlockDuration = 19938;
    uint256 constant _minTurnBlockDuration = 138;

    uint256 constant stateSize = 9;
    uint256 constant durationSize = 15;
    uint256 constant lastActionBlockSize = 25;
    uint256 constant victoriesSize = 6;
    uint256 constant tiesSize = 6;
    uint256 constant statusSize = 1; // 0 waiting, 1 playing

    uint256 constant statePosition = 0;
    uint256 constant durationPosition = statePosition + stateSize;
    uint256 constant lastActionBlockPosition = durationPosition + durationSize;
    uint256 constant victoriesPosition =
        lastActionBlockPosition + lastActionBlockSize;
    uint256 constant tiesPosition = victoriesPosition + victoriesSize;
    uint256 constant statusPosition = tiesPosition + tiesSize;

    uint256 constant stateSet = 2**stateSize - 1;
    uint256 constant durationSet = 2**durationSize - 1;
    uint256 constant lastActionBlockSet = 2**lastActionBlockSize - 1;
    uint256 constant victoriesSet = 2**victoriesSize - 1;
    uint256 constant tiesSet = 2**tiesSize - 1;
    uint256 constant statusSet = 2**statusSize - 1;

    uint256 constant stateMask = 4611686018427387392;
    uint256 constant durationMask = 4611686018410611199;
    uint256 constant lastActionBlockMask = 4611123068490743807;
    uint256 constant victoriesMask = 4576220171361845247;
    uint256 constant tiesMask = 2341871806232657919;
    uint256 constant statusMask = 2305843009213693951;

    event DidWin(
        address indexed from,
        uint256 indexed winningBoard,
        uint256 indexed losingBoard
    );
    event DidTie(
        address indexed from,
        uint256 indexed board1,
        uint256 indexed board2
    );

    mapping(uint256 => uint256) boards;
    mapping(uint256 => uint256) opponent;

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyBoardOwner(uint256 boardIndex) {
        require(ownerOf(boardIndex) == msg.sender, "E2");
        _;
    }

    constructor() ERC721("TicTacTie", "TTT") {
        _owner = payable(msg.sender);
    }

    function setPrice(uint256 price) public onlyOwner {
        _price = price;
    }

    function setCharity(address payable charity) external onlyOwner {
        _charity = charity;
    }

    function setPrize(
        address prize721Contract,
        address prize1155Contract,
        uint256 prizeTokenId,
        uint256 victoriesToWin
    ) external onlyOwner {
        _prize721 = IERC721(prize721Contract);
        _prize1155 = IERC1155(prize1155Contract);
        _prizeTokenId = prizeTokenId;
        _victoriesToWin = victoriesToWin;
    }

    function redeemFinalPrize(uint256 boardIndex)
        external
        onlyBoardOwner(boardIndex)
    {
        //require(_prizeTokenId != 0, "E3");
        require(victories(boardIndex) == _victoriesToWin, "E4");

        if (address(_prize721) != address(0)) {
            _prize721.safeTransferFrom(
                address(this),
                msg.sender,
                _prizeTokenId
            );
            _prize721 = IERC721(address(0));
        } else if (address(_prize1155) != address(0)) {
            _prize1155.safeTransferFrom(
                address(this),
                msg.sender,
                _prizeTokenId,
                1,
                ""
            );
            _prize1155 = IERC1155(address(0));
        }
        _prizeTokenId = 0;
    }

    function setSupply(uint256 additionalBoardSupply, address newBoardBuilder)
        public
        onlyOwner
    {
        _maxBoardSupply += additionalBoardSupply;
        _boardBuilder = IBoardBuilder(newBoardBuilder);
    }

    function mintTie(uint256 boardIndex)
        external
        payable
        onlyBoardOwner(boardIndex)
    {
        uint256 board = boards[boardIndex];
        uint256 ties = _countTies(board);

        require(ties > 0, "E5");
        require(_leftToMint > 0, "E6");

        uint256 index = _startingTieId + (block.timestamp % _leftToMint);
        uint256 tokenId = _idSwaps[index];

        if (tokenId == 0) {
            tokenId = index;
        }
        uint256 temp = _idSwaps[_leftToMint + _startingTieId - 1];
        if (temp == 0) {
            _idSwaps[index] = _leftToMint + _startingTieId - 1;
        } else {
            _idSwaps[index] = temp;
            delete _idSwaps[_leftToMint + _startingTieId - 1];
        }
        _leftToMint--;

        super._safeMint(msg.sender, tokenId);
        _charity.transfer(msg.value);

        boards[boardIndex] = (board & tiesMask) | ((ties - 1) << tiesPosition);
        _donations += msg.value;
    }

    function mint(uint256 tokenId) public payable {
        require(msg.value >= _price, "E7");
        require(tokenId > 0 && tokenId <= _maxBoardSupply, "E8");
        super._safeMint(msg.sender, tokenId);
        payable(owner()).transfer(msg.value);

        boards[tokenId] = (_turnBlockDuration << durationPosition);
    }

    function mintable() external view returns (uint256 bitmap) {
        for (uint256 i = 1; i <= _maxBoardSupply; i++) {
            if (_exists(i)) {
                bitmap |= 1 << i;
            }
        }
    }

    function boardState(uint256 boardIndex) external view returns (uint256) {
        return _boardState(boards[boardIndex]);
    }

    function expiryBlock(uint256 boardIndex) external view returns (uint256) {
        uint256 board = boards[opponent[boardIndex]];

        return
            ((board >> lastActionBlockPosition) & lastActionBlockSet) +
            ((board >> durationPosition) & durationSet);
    }

    function isBoardTurn(uint256 boardIndex) external view returns (bool) {
        return _isBoard1Turn(boards[boardIndex], boards[opponent[boardIndex]]);
    }

    function victories(uint256 boardIndex) public view returns (uint256) {
        return _countVictories(boards[boardIndex]);
    }

    function mintableTies(uint256 boardIndex) external view returns (uint256) {
        return _countTies(boards[boardIndex]);
    }

    function getOpponent(uint256 boardIndex)
        external
        view
        returns (uint256 theOpponent)
    {
        if (!_isWaiting(boards[boardIndex])) {
            theOpponent = opponent[boardIndex];
        }
    }

    function challenge(uint256 board1Index, uint256 board2Index)
        external
        onlyBoardOwner(board1Index)
    {
        // player has to be in a win state
        require(board1Index != board2Index, "E9");

        uint256 boardPlayer = boards[board1Index];
        uint256 boardOpponent = boards[board2Index];
        require(
            opponent[board1Index] != board2Index ||
                opponent[board2Index] != board1Index,
            "E10"
        );

        require(boardOpponent > 0, "E11");

        require(_isWaiting(boardPlayer) && _isWaiting(boardOpponent), "E12");

        uint256 board1LastBlock = block.number;
        uint256 board2LastBlock = block.number - 1;
        if (victories(board1Index) >= victories(board2Index)) {
            board1LastBlock = block.number - 1;
            board2LastBlock = block.number;
        }

        boards[board1Index] =
            (boardPlayer & statusMask & lastActionBlockMask & durationMask) |
            (playingFlag << statusPosition) |
            (_turnBlockDuration << durationPosition) |
            (board1LastBlock << lastActionBlockPosition); // first turn to who challenges
        boards[board2Index] =
            (boardOpponent & statusMask & lastActionBlockMask & durationMask) |
            (playingFlag << statusPosition) |
            (_turnBlockDuration << durationPosition) |
            (board2LastBlock << lastActionBlockPosition);
        opponent[board1Index] = board2Index;
        opponent[board2Index] = board1Index;
    }

    function whoAbandoned(uint256 boardIndex) external view returns (uint256) {
        uint256 board = boards[boardIndex];

        uint256 opponentBoardIndex = opponent[boardIndex];
        uint256 boardOpponent = boards[opponentBoardIndex];

        require(!_isWaiting(board) && !_isWaiting(boardOpponent), "E13");

        if (_didPlayer1Abandon(boardOpponent, board)) {
            return opponentBoardIndex;
        }

        if (_didPlayer1Abandon(board, boardOpponent)) {
            return boardIndex;
        }

        return 0;
    }

    function resetBoard(uint256 board, bool win)
        internal
        pure
        returns (uint256)
    {
        if (win) {
            return
                (board & victoriesMask & stateMask & statusMask) |
                ((_countVictories(board) + 1) << victoriesPosition) |
                (waitingFlag << statusPosition);
        } else {
            if (_countVictories(board) > 0) {
                return
                    (board & victoriesMask & stateMask & statusMask) |
                    ((_countVictories(board) - 1) << victoriesPosition) |
                    (waitingFlag << statusPosition);
            } else {
                return
                    (board & stateMask & statusMask) |
                    (waitingFlag << statusPosition);
            }
        }
    }

    function endGame(uint256 boardIndex) external {
        uint256 board = boards[boardIndex];

        uint256 opponentBoardIndex = opponent[boardIndex];
        require(opponentBoardIndex > 0, "E14");

        uint256 boardOpponent = boards[opponentBoardIndex];
        require(_didPlayer1Abandon(boardOpponent, board), "E15");

        boards[boardIndex] = resetBoard(board, true);
        boards[opponentBoardIndex] = resetBoard(boardOpponent, false);
        opponent[boardIndex] = 0;
        opponent[opponentBoardIndex] = 0;
    }

    function _isWaiting(uint256 board) internal pure returns (bool) {
        return ((board >> statusPosition) & statusSet) == waitingFlag;
    }

    function _boardState(uint256 board) internal pure returns (uint256) {
        return (board >> statePosition) & stateSet;
    }

    function _countTies(uint256 board) internal pure returns (uint256) {
        return (board >> tiesPosition) & tiesSet;
    }

    function _countVictories(uint256 board) internal pure returns (uint256) {
        return (board >> victoriesPosition) & victoriesSet;
    }

    function _boardStatus(uint256 board) internal pure returns (uint256) {
        return (board >> statusPosition) & statusSet;
    }

    function _isWin(uint256 state) internal pure returns (bool found) {
        return
            state == 448 ||
            state == 56 ||
            state == 7 ||
            state == 292 ||
            state == 146 ||
            state == 73 ||
            state == 273 ||
            state == 84;
    }

    function _isTie(uint256 state) internal pure returns (bool) {
        return state == 511;
    }

    function _isBoard1Turn(uint256 board1, uint256 board2)
        internal
        pure
        returns (bool)
    {
        return
            (board1 >> lastActionBlockPosition) & lastActionBlockSet <
            (board2 >> lastActionBlockPosition) & lastActionBlockSet;
    }

    function _didPlayer1Abandon(uint256 board1, uint256 board2)
        internal
        view
        returns (bool)
    {
        uint256 lastActionBlock1 = (board1 >> lastActionBlockPosition) &
            lastActionBlockSet;
        uint256 lastActionBlock2 = (board2 >> lastActionBlockPosition) &
            lastActionBlockSet;
        uint256 duration = (board1 >> durationPosition) & durationSet;
        if (lastActionBlock1 < lastActionBlock2) {
            return
                block.number > lastActionBlock1 + duration &&
                lastActionBlock1 > 0;
        }

        return false;
    }

    function play(uint256 boardIndex, uint16 coordinate)
        external
        onlyBoardOwner(boardIndex)
    {
        require(coordinate > 0 && coordinate <= 1 << 8, "E16");

        uint256 boardPlayer = boards[boardIndex];
        uint256 opponentBoardIndex = opponent[boardIndex];
        require(opponentBoardIndex > 0, "E14");

        uint256 boardOpponent = boards[opponentBoardIndex];

        require(
            ((boardPlayer >> statusPosition) |
                (boardOpponent >> statusPosition)) &
                statusSet ==
                playingFlag,
            "E17"
        );

        require(!_didPlayer1Abandon(boardPlayer, boardOpponent), "E18");
        require(!_didPlayer1Abandon(boardOpponent, boardPlayer), "E19");
        require(_isBoard1Turn(boardPlayer, boardOpponent), "E20");

        uint256 playerState = (boardPlayer >> statePosition) & stateSet;
        uint256 opponentState = (boardOpponent >> statePosition) & stateSet;

        require((playerState | opponentState) & coordinate == 0, "E21");

        uint256 state = playerState | coordinate;

        if (_isWin(state)) {
            boardPlayer = resetBoard(boardPlayer, true);
            boards[opponentBoardIndex] = resetBoard(boardOpponent, false);
            emit DidWin(msg.sender, boardIndex, opponentBoardIndex);
        } else if (_isTie(state | opponentState)) {
            uint256 newDuration = ((boardPlayer >> durationPosition) &
                durationSet) >> 1;
            if (newDuration < _minTurnBlockDuration) {
                newDuration = _minTurnBlockDuration;
            }
            boardPlayer =
                (boardPlayer &
                    stateMask &
                    durationMask &
                    lastActionBlockMask &
                    tiesMask) |
                (newDuration << durationPosition) |
                (block.number << lastActionBlockPosition) |
                ((_countTies(boardPlayer) + 1) << tiesPosition) |
                (playingFlag << statusPosition);
            boardOpponent =
                (boardOpponent &
                    stateMask &
                    durationMask &
                    lastActionBlockMask &
                    tiesMask) |
                (newDuration << durationPosition) |
                ((block.number - 1) << lastActionBlockPosition) |
                ((_countTies(boardOpponent) + 1) << tiesPosition) |
                (playingFlag << statusPosition);

            boards[opponentBoardIndex] = boardOpponent;

            emit DidTie(msg.sender, boardIndex, opponentBoardIndex);
        } else {
            boardPlayer =
                (boardPlayer & lastActionBlockMask) |
                (block.number << lastActionBlockPosition) |
                (state << statePosition);
        }

        boards[boardIndex] = boardPlayer;
    }

    function getAllBoardsSVG(uint256 startingIndex)
        external
        view
        returns (string[70] memory)
    {
        string[70] memory boardSVGs;
        for (uint256 i = startingIndex; i <= _maxBoardSupply; i++) {
            boardSVGs[i - 1] = string(_boardBuilder.getBoard(i, address(this)));
        }

        return boardSVGs;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "E22");

        if (tokenId >= _minTieId) {
            // it's a tie
            return _boardBuilder.getTie(tokenId);
        } else {
            // it's a board
            return _boardBuilder.getBoard(tokenId, address(this));
        }
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        //return
        //    bytes4(
        //        keccak256(
        //            "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
        //        )
        //    );
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}