//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";
import "ReentrancyGuard.sol";
import "IfrToken.sol";
import "IwAsset.sol";
import "IMultiRewards.sol";
import "INonFungiblePositionManager.sol";

/// @title TrueFreezeGovernor contract
/// @author chalex.eth - CharlieDAO
/// @notice Main TrueFreeze contract

contract TrueFreezeGovernor is Ownable, ReentrancyGuard {
    uint256 internal constant N_DAYS = 365;
    uint256 internal constant MIN_LOCK_DAYS = 1;
    uint256 internal constant MAX_LOCK_DAYS = 1100;
    uint256 internal constant MAX_UINT = 2**256 - 1;

    /// @dev The token ID position data
    mapping(uint256 => Position) private _positions;

    /// @dev The ID of the next token that will be minted. Skips 0
    uint256 private _nextId = 1;

    ///@dev pack the parameters of the position in a struct
    struct Position {
        uint256 amountLocked;
        uint256 tokenMinted;
        uint256 lockingDate;
        uint256 maturityDate;
        bool active;
    }

    /* ----------- events --------------*/

    event lockedWAsset(
        address indexed minter,
        uint256 indexed tokenId,
        uint256 amountLocked,
        uint256 lockingDate,
        uint256 maturityDate
    );

    event withdrawedWAsset(
        address indexed withdrawer,
        uint256 indexed tokenId,
        uint256 amountWithdrawed,
        uint256 WAssetPenalty,
        uint256 frPenalty
    );

    /* ----------- Interfaces --------------*/

    IfrToken private immutable frToken;
    IwAsset private immutable wAsset;
    INonFungiblePositionManager private immutable nftPosition;
    IMultiRewards private immutable stakingContract;

    /* ----------- Constructor --------------*/

    constructor(
        address _wAssetaddress,
        address _frToken,
        address _NFTPosition,
        address _stakingAddress
    ) {
        wAsset = IwAsset(_wAssetaddress);
        frToken = IfrToken(_frToken);
        nftPosition = INonFungiblePositionManager(_NFTPosition);
        stakingContract = IMultiRewards(_stakingAddress);
        wAsset.approve(_stakingAddress, MAX_UINT);
        frToken.approve(_stakingAddress, MAX_UINT);
    }

    /* ----------- External functions --------------*/

    /// @notice lock wAsset (WETH,WAVAX,WMATIC...) and create a position represented by a NFT
    /// @dev locking create a position, reward by minting frToken and NFT associated to the position
    /// @param _amount wAsset amount to lock
    /// @param _lockDuration number of days to lock the wAsset
    function lockWAsset(uint256 _amount, uint256 _lockDuration)
        external
        nonReentrant
    {
        require(_amount > 0, "Amount must be more than 0");
        require(
            _lockDuration >= MIN_LOCK_DAYS && _lockDuration <= MAX_LOCK_DAYS,
            "Bad days input"
        );
        bool sent = wAsset.transferFrom(msg.sender, address(this), _amount);
        require(sent, "Error in sending WAsset");
        uint256 lockingDate = block.timestamp;
        uint256 maturityDate = lockingDate + (_lockDuration * 1 days);
        uint256 tokenToMint = _calculate_frToken(
            _amount,
            (_lockDuration * 1 days)
        );
        _createPosition(
            _amount,
            tokenToMint,
            lockingDate,
            maturityDate,
            _nextId
        );
        _mintToken(tokenToMint);
        nftPosition.mint(msg.sender, _nextId);

        emit lockedWAsset(
            msg.sender,
            _nextId,
            _amount,
            lockingDate,
            maturityDate
        );

        _nextId += 1;
    }

    /// @notice withdraw wAsset (WETH,WAVAX,WMATIC...) associated to the NFT position
    /// @dev withdraw the position associated to the NFT position
    /// @param _tokenId ID of the NFT token
    function withdrawWAsset(uint256 _tokenId) external nonReentrant {
        require(
            msg.sender == nftPosition.ownerOf(_tokenId),
            "Not the owner of tokenId"
        );
        require(
            _positions[_tokenId].active == true,
            "Position already withdrawed"
        );

        (
            uint256 amountLocked,
            uint256 tokenMinted,
            uint256 lockingDate,
            uint256 maturityDate,
            bool active
        ) = getPositions(_tokenId);
        uint256 feesToPay = getWAssetFees(_tokenId);
        _positions[_tokenId].active = false;
        _positions[_tokenId].amountLocked = 0;

        nftPosition.burn(_tokenId);
        uint256 progress = getProgress(_tokenId);
        if (progress >= 100) {
            // if progress > 100 sending back asset
            wAsset.transfer(msg.sender, amountLocked);
            emit withdrawedWAsset(msg.sender, _tokenId, amountLocked, 0, 0);
        } else if (progress < 100) {
            // if progress < 100 user need to pay a wAsset fee
            uint256 frPenalty = getUnlockCost(_tokenId);
            require(
                frToken.transferFrom(msg.sender, address(this), frPenalty),
                "Transfer failed"
            );

            uint256 sendToUser = amountLocked - feesToPay;
            wAsset.transfer(msg.sender, sendToUser);
            stakingContract.notifyRewardAmount(address(wAsset), feesToPay);

            if (progress <= 67) {
                // if progress < 67 user need to pay a wAsset fee and frToken fee
                (uint256 toSend, uint256 toBurn) = _calculateBurnAndSend(
                    tokenMinted,
                    frPenalty
                );
                frToken.burn(address(this), toBurn);
                stakingContract.notifyRewardAmount(address(frToken), toSend);
            } else {
                frToken.burn(address(this), frPenalty);
            }
            emit withdrawedWAsset(
                msg.sender,
                _tokenId,
                amountLocked,
                feesToPay,
                frPenalty
            );
        }
    }

    /* ----------- Internal functions --------------*/

    ///@dev create a mapping of position struct
    function _createPosition(
        uint256 _amount,
        uint256 _tokenMinted,
        uint256 _lockingDate,
        uint256 _maturityDate,
        uint256 tokenId
    ) private {
        _positions[tokenId] = Position({
            amountLocked: _amount,
            tokenMinted: _tokenMinted,
            lockingDate: _lockingDate,
            maturityDate: _maturityDate,
            active: true
        });
    }

    function _mintToken(uint256 _tokenToMint) private {
        frToken.mint(msg.sender, _tokenToMint);
    }

    /* ----------- View functions --------------*/

    ///@dev returns data for a given position
    function getPositions(uint256 tokenId)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        return (
            _positions[tokenId].amountLocked,
            _positions[tokenId].tokenMinted,
            _positions[tokenId].lockingDate,
            _positions[tokenId].maturityDate,
            _positions[tokenId].active
        );
    }

    ///@dev get the progress for a given position
    function getProgress(uint256 tokenId) public view returns (uint256) {
        (, , uint256 _lockingDate, uint256 _maturityDate, ) = getPositions(
            tokenId
        );
        return _calculateProgress(block.timestamp, _lockingDate, _maturityDate);
    }

    ///@dev get the frToken fee to pay for unlocking a position
    function getUnlockCost(uint256 _tokenId) public view returns (uint256) {
        uint256 _progress = getProgress(_tokenId);
        (, uint256 _TokenMinted, , , ) = getPositions(_tokenId);
        return _calculateWithdrawCost(_progress, _TokenMinted);
    }

    ///@dev get the wAsset fee to pay if position is unlock
    function getWAssetFees(uint256 _tokenId) public view returns (uint256) {
        (uint256 amountLocked, , , , ) = getPositions(_tokenId);
        uint256 progress = getProgress(_tokenId);
        if (progress >= 100) {
            return 0;
        } else {
            return _calculateWAssetFees(amountLocked);
        }
    }

    /* ----------- Pure functions --------------*/

    /// @notice Get the amount of frAsset that will be minted
    /// @return Return the amount of frAsset that will be minted
    function _calculate_frToken(uint256 _lockedAmount, uint256 _timeToLock)
        internal
        pure
        returns (uint256)
    {
        uint256 token = (_timeToLock * _lockedAmount) / (N_DAYS * 1 days);
        return token;
    }

    function _calculateProgress(
        uint256 _nBlock,
        uint256 _lockingDate,
        uint256 _maturityDate
    ) internal pure returns (uint256) {
        return
            (100 * (_nBlock - _lockingDate)) / (_maturityDate - _lockingDate);
    }

    function _calculateWithdrawCost(uint256 _progress, uint256 _frToken)
        internal
        pure
        returns (uint256)
    {
        uint256 unlockCost;
        if (_progress >= 100) {
            unlockCost = 0;
        } else if (_progress < 67) {
            unlockCost =
                _frToken +
                ((((20 * _frToken) / 100) * (100 - ((_progress * 3) / 2))) /
                    100);
        } else {
            unlockCost = (_frToken * (100 - ((_progress - 67) * 3))) / 100;
        }
        return unlockCost;
    }

    function _calculateWAssetFees(uint256 _lockedAmount)
        internal
        pure
        returns (uint256)
    {
        return (_lockedAmount * 25) / 10000;
    }

    ///@dev calculate how much token is burnt and sent to staking contract
    function _calculateBurnAndSend(uint256 _tokenMinted, uint256 _penaltyPaid)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 toSend = (_penaltyPaid - _tokenMinted) / 2;
        uint256 toBurn = _tokenMinted + (_penaltyPaid - _tokenMinted) - toSend;
        return (toSend, toBurn);
    }
}