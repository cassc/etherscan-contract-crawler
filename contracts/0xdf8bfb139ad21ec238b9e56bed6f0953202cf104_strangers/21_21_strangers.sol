// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ERC721PartnerSeaDrop } from "./ERC721PartnerSeaDrop.sol";

//
//               @@@                                                                                                   @@@@
//          @@@@@@@@@@@#                                                                               @@@@@         @@@@@
//        @@@@@     @@@@@                                                        @@ @       @@@@      @@@@@@@      @@@ @@
//       @@@@      @@@@@                                                      @@@@@@@@    @@@ @@@     @@  @@      @@@ @@@
//       @@@@      @@@@      @@     @@ @           @@ @@.     @@@ @@@@     @@@@  @@@,   @@@  @@@    @@   @@     @@@  @@@
//       @@@@      /@      @@@@@@  @@@@@@        @@@@@@@     @@@ @@@@     @@@   @@@    @@@ @@@    @@@   @@    @@@@@@@@@@
//        @@@@        @@@@@@@@@   @@  @@@      @@@  @@@     @@@@@@@     @@@@   @@@@  @@@@ @     @@@    @@@@@@@@  @@@@@@
//          @@@@         @@@     @@  @@@     @@@@  @@(    @@@@@ @@@   @@@@@@@@@@@@ @@@ @@@@@@@@@@       @@@@@
//            @@@@      @@@    @@@  @@@    @@@@@ @@@@  @@@@@@   @@@@@@@   @@@ @@@@@       @@@
//  @@          @@@@   @@@   @@@    @@@@@@@@ @@@@@ @@@@@@@@@      @@@      @@@@@                         @@@@
//   @@@        @@@@   @@@@@@@      @@@@@@    @@&                        @@@ @@@      @@       @@    @@@@    /@@@
//    @@@@@@@@@@@@@     @@@                                            @@   @@@       @@@@@@@@@@@   @@@         @@
//        @@@@@@                                                      @@@ @@@@        @@       @@    @@@  @@   @@@
//                                                                    @@@@@@@         @@       @@      @@@@@@@@@
//                                                                     @@@                                  @@@@@@

contract strangers is ERC721PartnerSeaDrop {
    /// Variable for Delegate Address
    address public delegateAddress;

    /// Point Multiplier
    uint256 public pointsMultiplier = 86400;

    /// BoardedToken Struct
    struct BoardedToken {
        /// Boarded state
        bool boarded;
        /// The time BoardedToken was boarded at
        uint48 timeBoarded;
        /// Last time of update for this BoardedToken
        uint48 timeLastUpdated;
    }

    /// Default boarding state
    bool public boardingState;

    /// Default boarding point transfer state
    bool public allowPointsTransfer;

    /// Mapping for BoardedToken Struct
    mapping(uint256 => BoardedToken) public checkTokenBoardStatus;

    /// Mapping for wallet address to Boarded Token IDs
    mapping(address => uint256[]) public boardedTokenId;

    /// Mapping for Points to an Address
    mapping(address => uint256) public boarderAcc;

    /// Errors
    error TokenNotBoarded();
    error PointsTransferDeactivated();
    error InsufficientPointsBalance();
    error BoardingDisabled();
    error NotOwnerOfToken();
    error TokenBoarded();
    error NotOwnerOrDelegate();

    // =============================================================
    //                     Boarding Adjustments
    // =============================================================
    constructor(
        string memory name,
        string memory symbol,
        address administrator,
        address[] memory allowedSeaDrop
    ) ERC721PartnerSeaDrop(name, symbol, administrator, allowedSeaDrop) {}

    /// @notice Enables Boarding
    function enableBoarding() external {
        // Sender must be contract owner.
        onlyContractOwner();

        boardingState = true;
    }

    /// @notice Disables Boarding
    function disableBoarding() external {
        // Sender must be contract owner.
        onlyContractOwner();

        for (uint256 i = 1; i <= totalSupply(); ++i) {
            if (checkTokenBoardStatus[i].boarded) {
                boarderAcc[ownerOf(i)] += checkActiveBoardingPoints(i);
                checkTokenBoardStatus[i].boarded = false;
                checkTokenBoardStatus[i].timeBoarded = 0;
                checkTokenBoardStatus[i].timeLastUpdated = uint48(
                    block.timestamp
                );
                boardedTokenId[ownerOf(i)].pop();
                emit Deboarded(msg.sender, i, checkActiveBoardingPoints(i), block.timestamp);
            }
        }
        boardingState = false;
    }

    /// @dev Emitted when a token points are moved.
    event ActivePointsMoved(address owner, uint256 tokenId, uint256 value);

    /// @notice Moves active boarding points to owner's wallet
    /// @param _boardedToken Boarded token ID
    function withdrawActiveBoardingPoints(
        uint256 _boardedToken
    ) external nonReentrant {
        boarderAcc[msg.sender] += checkActiveBoardingPoints(_boardedToken);
        if (!checkTokenBoardStatus[_boardedToken].boarded) {
            revert TokenNotBoarded();
        }
        checkTokenBoardStatus[_boardedToken].timeLastUpdated = uint48(
            block.timestamp
        );
        emit ActivePointsMoved(
            msg.sender,
            _boardedToken,
            checkActiveBoardingPoints(_boardedToken)
        );
    }

    /// @notice Sets Point Multiplier
    /// @param _time Enter multiplier in seconds
    function setPointMultiplier(uint256 _time) external {
        // Sender must be contract owner.
        onlyContractOwner();

        pointsMultiplier = _time;
    }

    /// @notice Set Transfer Points state
    /// @param _state true or false
    function setPointTransfersOn(bool _state) external {
        // Sender must be contract owner.
        onlyContractOwner();

        allowPointsTransfer = _state;
    }

    /// @dev Emitted when a points are transferred.
    event PointsTransferred(address caller, address recipient, uint256 amount, uint256 blocktime);

    /// @notice Transfer Points to another address
    /// @param _to Receiving Address
    /// @param _amount Amount of Points
    function pointsTransfer(address _to, uint256 _amount) external {
        uint256 ownerBalance = boarderAcc[msg.sender];
        if (!allowPointsTransfer) {
            revert PointsTransferDeactivated();
        }
        if (_amount > ownerBalance) {
            revert InsufficientPointsBalance();
        }
        boarderAcc[msg.sender] -= _amount;
        boarderAcc[_to] += _amount;
        emit PointsTransferred(msg.sender, _to, _amount, block.timestamp);
    }

    /// @dev Emitted when a token points are moved.
    event PointsAdded(address caller, address recipient, uint256 amount, uint256 blocktime);

    /// @dev Emitted when a token points are moved.
    event PointsSubtracted(address caller, address recipient, uint256 amount, uint256 blocktime);

    /// @notice Add points to an address
    /// @param _to Address
    /// @param _amount Amount of Points
    function pointsAdd(address[] memory _to, uint256 _amount) external {
        // Require sender to be only delegate or contract owner.
        onlyDelegateOrContractOwner();

        for (uint256 i = 0; i < _to.length; ++i) {
            boarderAcc[_to[i]] += _amount;
            emit PointsAdded(msg.sender, _to[i], _amount, block.timestamp);
        }
    }

    /// @notice Remove points from an address
    /// @param _to Address
    /// @param _amount Amount of Points
    function pointsSubtract(address[] memory _to, uint256 _amount) external {
        // Require sender to be only delegate or contract owner.
        onlyDelegateOrContractOwner();

        for (uint256 i = 0; i < _to.length; ++i) {
            uint256 addressPointsBalance = boarderAcc[_to[i]];
            if (addressPointsBalance < _amount) {
                revert InsufficientPointsBalance();
            }
            boarderAcc[_to[i]] -= _amount;
            emit PointsSubtracted(msg.sender, _to[i], _amount, block.timestamp);
        }
    }

    // =============================================================
    //                       Boarding Functions
    // =============================================================

    /// @dev Emitted when a token is boarded.
    event Boarded(address owner, uint256 tokenId, uint256 blocktime);

    /// @dev Emitted when a token is deboarded.
    event Deboarded(address owner, uint256 tokenId, uint256 points, uint256 blocktime);

    /// @notice Boarding Function
    /// @param _boardableTokenId Token Id
    function boardToken(uint256 _boardableTokenId) public {
        if (!boardingState) {
            revert BoardingDisabled();
        }
        if (msg.sender != ownerOf(_boardableTokenId)) {
            revert NotOwnerOfToken();
        }
        BoardedToken storage _token = checkTokenBoardStatus[_boardableTokenId];
        if (_token.boarded) {
            revert TokenBoarded();
        }
        _token.timeBoarded = uint48(block.timestamp);
        _token.boarded = true;
        _token.timeLastUpdated = uint48(block.timestamp);
        emit Boarded(msg.sender, _boardableTokenId, block.timestamp);
        checkTokenBoardStatus[_boardableTokenId] = _token;
        boardedTokenId[msg.sender].push(_boardableTokenId);
    }

    /// @notice Multi-Boarding Function
    /// @param _boardableTokenIds Token Ids array
    function boardTokens(uint256[] memory _boardableTokenIds) external {
        for (uint256 i; i < _boardableTokenIds.length; i++) {
            boardToken(_boardableTokenIds[i]);
        }
    }

    /// @notice Deboarding function
    /// @param _boardableTokenId Token Id
    function deboardToken(uint256 _boardableTokenId) external {
        if (msg.sender != ownerOf(_boardableTokenId)) {
            revert NotOwnerOfToken();
        }
        BoardedToken storage _token = checkTokenBoardStatus[_boardableTokenId];
        if (!_token.boarded) {
            revert TokenNotBoarded();
        }
        uint256 tokenPoints = checkActiveBoardingPoints(_boardableTokenId);
        boarderAcc[msg.sender] += tokenPoints;
        _token.boarded = false;
        _token.timeBoarded = 0;
        _token.timeLastUpdated = uint48(block.timestamp);
        emit Deboarded(msg.sender, _boardableTokenId, tokenPoints, block.timestamp);
        checkTokenBoardStatus[_boardableTokenId] = _token;
        uint256[] memory _boardedToken = boardedTokenId[msg.sender];
        for (uint256 i = 0; i < _boardedToken.length; ++i) {
            if (_boardedToken[i] == _boardableTokenId) {
                _boardedToken[i] = _boardedToken[_boardedToken.length - 1];
            }
        }
        boardedTokenId[msg.sender] = _boardedToken;
        boardedTokenId[msg.sender].pop();
    }

    // =============================================================
    //                        Contract Checks
    // =============================================================

    /// @notice Returns the active board points accumulated since the last update
    /// @param _boardedTokenId Boarded Token ID
    function checkActiveBoardingPoints(
        uint256 _boardedTokenId
    ) public view returns (uint256 _points) {
        if (!checkTokenBoardStatus[_boardedTokenId].boarded) {
            return 0;
        }
        return ((block.timestamp -
            checkTokenBoardStatus[_boardedTokenId].timeLastUpdated) /
            pointsMultiplier); // Time in minutes
    }

    // =============================================================
    //                   Delegate Control Modifier
    // =============================================================

    function setDelegate(address _delegate) external {
        // Sender must be contract owner.
        onlyContractOwner();

        delegateAddress = _delegate;
    }

    function onlyContractOwner() public view {
        if (msg.sender != owner()) {
            revert OnlyOwner();
        }
    }

    function onlyDelegateOrContractOwner() public view {
        if (msg.sender != owner() && msg.sender != delegateAddress) {
            revert NotOwnerOrDelegate();
        }
    }

    // =============================================================
    //                Deboard Tokens before Transfers
    // =============================================================

    /// @notice Override function that deboards boarded tokenId if token is transferred or sold
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        BoardedToken storage _token = checkTokenBoardStatus[startTokenId];
        if (checkTokenBoardStatus[startTokenId].boarded) {
            uint256 tokenPoints = checkActiveBoardingPoints(startTokenId);
            boarderAcc[ownerOf(startTokenId)] += tokenPoints;
            _token.boarded = false;
            _token.timeBoarded = 0;
            _token.timeLastUpdated = uint48(block.timestamp);
            emit Deboarded(msg.sender, startTokenId, tokenPoints, block.timestamp);
            checkTokenBoardStatus[startTokenId] = _token;
            uint256[] storage _boardedToken = boardedTokenId[ownerOf(startTokenId)];
            for (uint256 i = 0; i < _boardedToken.length; ++i) {
                if (_boardedToken[i] == startTokenId) {
                    _boardedToken[i] = _boardedToken[_boardedToken.length - 1];
                }
            }
            boardedTokenId[ownerOf(startTokenId)] = _boardedToken;
            boardedTokenId[ownerOf(startTokenId)].pop();
        }
    }
}