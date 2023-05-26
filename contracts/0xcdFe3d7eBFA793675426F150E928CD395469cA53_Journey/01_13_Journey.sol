// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../shared/interfaces/RealmsToken.sol";
import "../shared/interfaces/LordsToken.sol";

contract Journey is ERC721Holder, Ownable, ReentrancyGuard, Pausable {
    // -------- EVENTS -------- //
    event StakeRealms(uint256[] tokenIds, address player);
    event UnStakeRealms(uint256[] tokenIds, address player);

    // -------- MAPPINGS -------- //
    mapping(address => uint256) public epochClaimed;
    mapping(uint256 => address) public ownership;
    mapping(address => mapping(uint256 => uint256)) public realmsStaked;

    // -------- PUBLIC ---------- //
    LordsToken public lordsToken;
    RealmsToken public realmsToken;
    address public bridge;
    uint256 public lordsPerRealm;
    uint256 public genesis;
    uint256 public epoch;
    uint256 public finalAge;
    uint256 public halvingAge;
    uint256 public halvingAmount;
    uint256 public gracePeriod;

    uint256 public epochLengh = 3600;

    constructor(
        uint256 _lordsPerRealm,
        uint256 _epoch,
        uint256 _halvingAge,
        uint256 _halvingAmount,
        address _realmsAddress,
        address _lordsToken
    ) {
        lordsPerRealm = _lordsPerRealm;
        epoch = _epoch;
        halvingAge = _halvingAge;
        halvingAmount = _halvingAmount;
        lordsToken = LordsToken(_lordsToken);
        realmsToken = RealmsToken(_realmsAddress);
    }

    // -------- EXTERNALS -------- //

    function setGracePeriod(uint256 _gracePeriod) external onlyOwner {
        gracePeriod = _gracePeriod;
    }

    function setGenesis(uint256 _time) external onlyOwner {
        genesis = _time;
    }

    function lordsIssuance(uint256 _new) external onlyOwner {
        lordsPerRealm = _new;
    }

    function updateRealmsAddress(address _newRealms) external onlyOwner {
        realmsToken = RealmsToken(_newRealms);
    }

    function updateLordsAddress(address _newLords) external onlyOwner {
        lordsToken = LordsToken(_newLords);
    }

    function updateEpochLength(uint256 _newEpoch) external onlyOwner {
        epoch = _newEpoch;
    }

    function setBridge(address _newBridge) external onlyOwner {
        bridge = _newBridge;
    }

    function setHalvingAmount(uint256 _halvingAmount) external onlyOwner {
        halvingAmount = _halvingAmount;
    }

    function setHalvingAge(uint256 _halvingAge) external onlyOwner {
        halvingAge = _halvingAge;
    }

    function setFinalAge(uint256 _finalAge) external onlyOwner {
        finalAge = _finalAge;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Boards the Ship (Stakes). Sets ownership of Token to Staker. Transfers NFT to Contract. Set's epoch date, Set's number of Realms staked in the Epoch.
     * @param _tokenIds Ids of Realms
     */
    function boardShip(uint256[] memory _tokenIds)
        external
        whenNotPaused
        nonReentrant
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                realmsToken.ownerOf(_tokenIds[i]) == msg.sender,
                "NOT_OWNER"
            );
            ownership[_tokenIds[i]] = msg.sender;

            realmsToken.safeTransferFrom(
                msg.sender,
                address(this),
                _tokenIds[i]
            );
        }

        if (getNumberRealms(msg.sender) == 0) {
            epochClaimed[msg.sender] = _epochNum();
        }

        realmsStaked[msg.sender][_epochNum()] += uint256(_tokenIds.length);

        emit StakeRealms(_tokenIds, msg.sender);
    }

    /**
     * @notice Exits the Ship
     * @param _tokenIds Ids of Realms
     */
    function exitShip(uint256[] memory _tokenIds)
        external
        whenNotPaused
        nonReentrant
    {
        _exitShip(_tokenIds);
    }

    /**
     * @notice Claims all available Lords for Owner.
     */
    function claimLords() external whenNotPaused nonReentrant {
        _claimLords();
    }

    // -------- INTERNALS -------- //

    /**
     * @notice Set's epoch = epoch * 1 hour.
     */
    function _epochNum() internal view returns (uint256) {
        if (finalAge != 0) {
            return finalAge;
        } else if (block.timestamp - genesis < gracePeriod) {
            return 0;
        } else if ((block.timestamp - genesis) / (epoch * epochLengh) == 0) {
            return 1;
        } else {
            return (block.timestamp - genesis) / (epoch * epochLengh) + 1;
        }
    }

    /**
     * @notice Exits Ship, and transfers all Realms back to owner. Claims any lords available.
     * @param _tokenIds Ids of Realms
     */
    function _exitShip(uint256[] memory _tokenIds) internal {
        (uint256 lords, ) = lordsAvailable(msg.sender);

        if (lords != 0) {
            _claimLords();
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(ownership[_tokenIds[i]] == msg.sender, "NOT_OWNER");

            ownership[_tokenIds[i]] = address(0);

            realmsToken.safeTransferFrom(
                address(this),
                msg.sender,
                _tokenIds[i]
            );
        }

        // Remove last in first
        if (_epochNum() == 0) {
            realmsStaked[msg.sender][_epochNum()] -= _tokenIds.length;
        } else {
            uint256 realmsInPrevious = realmsStaked[msg.sender][
                _epochNum() - 1
            ];
            uint256 realmsInCurrent = realmsStaked[msg.sender][_epochNum()];

            if (realmsInPrevious > _tokenIds.length) {
                realmsStaked[msg.sender][_epochNum() - 1] -= _tokenIds.length;
            } else if (realmsInCurrent == _tokenIds.length) {
                realmsStaked[msg.sender][_epochNum()] -= _tokenIds.length;
            } else if (realmsInPrevious <= _tokenIds.length) {
                // remove oldest first
                uint256 oldestFirst = (_tokenIds.length - realmsInPrevious);

                realmsStaked[msg.sender][_epochNum() - 1] -= (_tokenIds.length -
                    oldestFirst);

                realmsStaked[msg.sender][_epochNum()] -= oldestFirst;
            }
        }

        emit UnStakeRealms(_tokenIds, msg.sender);
    }

    function _claimLords() internal {
        require(_epochNum() > 1, "GENESIS_epochNum");

        (uint256 lords, uint256 totalRealms) = lordsAvailable(msg.sender);

        // set totalRealms staked in latest epoch - 1 so loop doesn't have to iterate again
        realmsStaked[msg.sender][_epochNum() - 1] = totalRealms;

        // set epoch claimed to current - 1
        epochClaimed[msg.sender] = _epochNum() - 1;

        require(lords > 0, "NOTHING_TO_CLAIM");

        lordsToken.approve(address(this), lords);

        lordsToken.transferFrom(address(this), msg.sender, lords);
    }

    // -------- GETTERS -------- //

    /**
     * @notice Lords available for the player
     */
    function lordsAvailable(address _player)
        public
        view
        returns (uint256 lords, uint256 totalRealms)
    {
        uint256 preHalvingRealms;
        uint256 postHalvingRealms;

        for (uint256 i = epochClaimed[_player]; i < _epochNum(); i++) {
            totalRealms += realmsStaked[_player][i];
        }

        if (epochClaimed[_player] <= halvingAge && _epochNum() <= halvingAge) {
            for (uint256 i = epochClaimed[_player]; i < _epochNum(); i++) {
                preHalvingRealms +=
                    realmsStaked[_player][i] *
                    ((_epochNum() - 1) - i);
            }
        } else if (
            _epochNum() >= halvingAge && epochClaimed[_player] < halvingAge
        ) {
            for (uint256 i = epochClaimed[_player]; i < halvingAge; i++) {
                preHalvingRealms +=
                    realmsStaked[_player][i] *
                    ((halvingAge) - i);
            }
        }

        if (_epochNum() > halvingAge && epochClaimed[_player] >= halvingAge) {
            for (uint256 i = epochClaimed[_player]; i < _epochNum(); i++) {
                postHalvingRealms +=
                    realmsStaked[_player][i] *
                    ((_epochNum() - 1) - i);
            }
        } else if (
            _epochNum() > halvingAge && epochClaimed[_player] < halvingAge
        ) {
            uint256 total;

            for (uint256 i = epochClaimed[_player]; i < _epochNum(); i++) {
                total += realmsStaked[_player][i] * ((_epochNum() - 1) - i);

                if (i < halvingAge) {
                    total -= realmsStaked[_player][i] * ((halvingAge) - i);
                }
            }

            postHalvingRealms = total;
        }

        if (_epochNum() > 1) {
            lords =
                (lordsPerRealm * preHalvingRealms) +
                (halvingAmount * postHalvingRealms);
        } else {
            lords = 0;
        }
    }

    /**
     * @notice Withdraw all Lords
     */
    function withdrawAllLords(address _destination) public onlyOwner {
        uint256 balance = lordsToken.balanceOf(address(this));
        lordsToken.approve(address(this), balance);
        lordsToken.transferFrom(address(this), _destination, balance);
    }

    function getEpoch() public view returns (uint256) {
        return _epochNum();
    }

    function getTimeUntilEpoch() public view returns (uint256) {
        return
            (epoch * epochLengh * (getEpoch())) - (block.timestamp - genesis);
    }

    function getNumberRealms(address _player) public view returns (uint256) {
        uint256 totalRealms;

        if (_epochNum() >= 1) {
            for (uint256 i = epochClaimed[_player]; i <= _epochNum(); i++) {
                totalRealms += realmsStaked[_player][i];
            }
            return totalRealms;
        } else {
            return realmsStaked[_player][0];
        }
    }

    // -------- MODIFIERS -------- //
    modifier onlyBridge() {
        require(msg.sender == bridge, "NOT_THE_BRIDGE");
        _;
    }

    // -------- BRIDGE FUNCTIONS -------- //
    /**
     * @notice Called only by future Bridge contract to withdraw the Realms
     * @param _tokenIds Ids of Realms
     */
    function bridgeWithdraw(address _player, uint256[] memory _tokenIds)
        public
        onlyBridge
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            ownership[_tokenIds[i]] = address(0);
            realmsToken.safeTransferFrom(address(this), _player, _tokenIds[i]);
        }
        emit UnStakeRealms(_tokenIds, _player);
    }
}