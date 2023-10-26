// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interface/IsQWA.sol";
import "./interface/IDistributor.sol";

/// @title   QWAStaking
/// @notice  QWA Staking
contract QWAStaking is Ownable {

    /// DATA STRUCTURES ///

    struct Epoch {
        uint256 length; // in seconds
        uint256 number; // since inception
        uint256 end; // timestamp
        uint256 distribute; // amount
    }

    /// STATE VARIABLES ///

    /// @notice QWA address
    IERC20 public immutable QWA;
    /// @notice sQWA address
    IsQWA public immutable sQWA;

    /// @notice Current epoch details
    Epoch public epoch;

    /// @notice Distributor address
    IDistributor public distributor;

    /// CONSTRUCTOR ///

    /// @param _QWA                   Address of QWA
    /// @param _sQWA                  Address of sQWA
    /// @param _epochLength            Epoch length
    /// @param _secondsTillFirstEpoch  Seconds till first epoch starts
    constructor(
        address _QWA,
        address _sQWA,
        uint256 _epochLength,
        uint256 _secondsTillFirstEpoch
    ) {
        QWA = IERC20(_QWA);
        sQWA = IsQWA(_sQWA);

        epoch = Epoch({
            length: _epochLength,
            number: 0,
            end: block.timestamp + _secondsTillFirstEpoch,
            distribute: 0
        });
    }

    /// MUTATIVE FUNCTIONS ///

    /// @notice stake QWA
    /// @param _to address
    /// @param _amount uint
    function stake(address _to, uint256 _amount) external {
        rebase();
        QWA.transferFrom(msg.sender, address(this), _amount);
        sQWA.transfer(_to, _amount);
    }

    /// @notice redeem sQWA for QWA
    /// @param _to address
    /// @param _amount uint
    function unstake(address _to, uint256 _amount, bool _rebase) external {
        if (_rebase) rebase();
        sQWA.transferFrom(msg.sender, address(this), _amount);
        require(
            _amount <= QWA.balanceOf(address(this)),
            "Insufficient QWA balance in contract"
        );
        QWA.transfer(_to, _amount);
    }

    ///@notice Trigger rebase if epoch over
    function rebase() public {
        if (epoch.end <= block.timestamp) {
            sQWA.rebase(epoch.distribute, epoch.number);

            epoch.end = epoch.end + epoch.length;
            epoch.number++;

            if (address(distributor) != address(0)) {
                distributor.distribute();
            }

            uint256 balance = QWA.balanceOf(address(this));
            uint256 staked = sQWA.circulatingSupply();

            if (balance <= staked) {
                epoch.distribute = 0;
            } else {
                epoch.distribute = balance - staked;
            }
        }
    }

    /// INTERNAL FUNCTIONS ///

    /// @notice         Send sQWA upon staking
    /// @param _to      Address of where sending sQWA
    /// @param _amount  Amount of sQWA to send
    /// @return _sent   Amount of sQWA sent
    function _send(
        address _to,
        uint256 _amount
    ) internal returns (uint256 _sent) {
        sQWA.transfer(_to, _amount); // send as sQWA (equal unit as QWA)
        return _amount;
    }

    /// VIEW FUNCTIONS ///

    /// @notice           Returns econds until the next epoch begins
    /// @return seconds_  Till next epoch
    function secondsToNextEpoch() external view returns (uint256 seconds_) {
        return epoch.end - block.timestamp;
    }

    /// MANAGERIAL FUNCTIONS ///

    /// @notice              Sets the contract address for LP staking
    /// @param _distributor  Distributor Address
    function setDistributor(address _distributor) external onlyOwner {
        distributor = IDistributor(_distributor);
    }
}