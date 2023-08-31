/*
        By Participating In 
       The Quantum Wealth Network 
     You Are Accelerating Your Wealth
With A Strong Network Of Beautiful Souls 

Telegram: https://t.me/+JsdS-pXyFXNlZTgx
Twitter: https://twitter.com/QuantumWN
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interface/IsQWN.sol";
import "./interface/IDistributor.sol";

/// @title   QWNStaking
/// @notice  QWN Staking
contract QWNStaking is Ownable {
    /// EVENTS ///

    event DistributorSet(address distributor);

    /// DATA STRUCTURES ///

    struct Epoch {
        uint256 length; // in seconds
        uint256 number; // since inception
        uint256 end; // timestamp
        uint256 distribute; // amount
    }

    /// STATE VARIABLES ///

    /// @notice QWN address
    IERC20 public immutable QWN;
    /// @notice sQWN address
    IsQWN public immutable sQWN;

    /// @notice Current epoch details
    Epoch public epoch;

    /// @notice Distributor address
    IDistributor public distributor;

    /// CONSTRUCTOR ///

    /// @param _QWN                   Address of QWN
    /// @param _sQWN                  Address of sQWN
    /// @param _epochLength            Epoch length
    /// @param _secondsTillFirstEpoch  Seconds till first epoch starts
    constructor(
        address _QWN,
        address _sQWN,
        uint256 _epochLength,
        uint256 _secondsTillFirstEpoch
    ) {
        require(_QWN != address(0), "Zero address: QWN");
        QWN = IERC20(_QWN);
        require(_sQWN != address(0), "Zero address: sQWN");
        sQWN = IsQWN(_sQWN);

        epoch = Epoch({
            length: _epochLength,
            number: 0,
            end: block.timestamp + _secondsTillFirstEpoch,
            distribute: 0
        });
    }

    /// MUTATIVE FUNCTIONS ///

    /// @notice stake QWN
    /// @param _to address
    /// @param _amount uint
    function stake(address _to, uint256 _amount) external {
        rebase();
        QWN.transferFrom(msg.sender, address(this), _amount);
        sQWN.transfer(_to, _amount);
    }

    /// @notice redeem sQWN for QWN
    /// @param _to address
    /// @param _amount uint
    function unstake(address _to, uint256 _amount, bool _rebase) external {
        if (_rebase) rebase();
        sQWN.transferFrom(msg.sender, address(this), _amount);
        require(
            _amount <= QWN.balanceOf(address(this)),
            "Insufficient QWN balance in contract"
        );
        QWN.transfer(_to, _amount);
    }

    ///@notice Trigger rebase if epoch over
    function rebase() public {
        if (epoch.end <= block.timestamp) {
            sQWN.rebase(epoch.distribute, epoch.number);

            epoch.end = epoch.end + epoch.length;
            epoch.number++;

            if (address(distributor) != address(0)) {
                distributor.distribute();
            }

            uint256 balance = QWN.balanceOf(address(this));
            uint256 staked = sQWN.circulatingSupply();

            if (balance <= staked) {
                epoch.distribute = 0;
            } else {
                epoch.distribute = balance - staked;
            }
        }
    }

    /// INTERNAL FUNCTIONS ///

    /// @notice         Send sQWN upon staking
    /// @param _to      Address of where sending sQWN
    /// @param _amount  Amount of sQWN to send
    /// @return _sent   Amount of sQWN sent
    function _send(
        address _to,
        uint256 _amount
    ) internal returns (uint256 _sent) {
        sQWN.transfer(_to, _amount); // send as sQWN (equal unit as QWN)
        return _amount;
    }

    /// VIEW FUNCTIONS ///

    /// @notice         Returns the sQWN index, which tracks rebase growth
    /// @return index_  Index of sQWN
    function index() public view returns (uint256 index_) {
        return sQWN.index();
    }

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
        emit DistributorSet(_distributor);
    }
}