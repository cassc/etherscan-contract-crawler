// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interface/IsHATE.sol";
import "./interface/IDistributor.sol";

contract HATEStaking is Ownable{
    /* ========== EVENTS ========== */

    event DistributorSet(address distributor);

    /* ========== DATA STRUCTURES ========== */

    struct Epoch {
        uint256 length; // in seconds
        uint256 number; // since inception
        uint256 end; // timestamp
        uint256 distribute; // amount
    }

    struct Claim {
        uint256 deposit; // if forfeiting
        uint256 gons; // staked balance
        uint256 expiry; // end of warmup period
        bool lock; // prevents malicious delays for claim
    }

    /* ========== STATE VARIABLES ========== */

    IERC20 public immutable HATE;
    IsHATE public immutable sHATE;

    Epoch public epoch;

    IDistributor public distributor;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _HATE, address _sHATE, uint256 _epochLength) {
        require(_HATE != address(0), "Zero address: HATE");
        HATE = IERC20(_HATE);
        require(_sHATE != address(0), "Zero address: sHATE");
        sHATE = IsHATE(_sHATE);

        epoch = Epoch({length: _epochLength, number: 0, end: block.timestamp + _epochLength, distribute: 0});
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice stake HATE
     * @param _to address
     * @param _amount uint
     */
    function stake(address _to, uint256 _amount) external {
        HATE.transferFrom(msg.sender, address(this), _amount);
        rebase();
        sHATE.transfer(_to, _amount);
    }

    /**
     * @notice redeem sHATE for HATEs
     * @param _to address
     * @param _amount uint
     */
    function unstake(address _to, uint256 _amount, bool _rebase) external {
        if (_rebase) rebase();
        sHATE.transferFrom(msg.sender, address(this), _amount);
        require(_amount <= HATE.balanceOf(address(this)), "Insufficient HATE balance in contract");
        HATE.transfer(_to, _amount);
    }

    /**
     * @notice trigger rebase if epoch over
     */
    function rebase() public {
        if (epoch.end <= block.timestamp) {
            sHATE.rebase(epoch.distribute, epoch.number);

            epoch.end = epoch.end + epoch.length;
            epoch.number++;

            if (address(distributor) != address(0)) {
                distributor.distribute();
            }

            uint256 balance = HATE.balanceOf(address(this));
            uint256 staked = sHATE.circulatingSupply();

            if (balance <= staked) {
                epoch.distribute = 0;
            } else {
                epoch.distribute = balance - staked;
            }
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice send staker their amount as sHATE
     * @param _to address
     * @param _amount uint
     */
    function _send(address _to, uint256 _amount) internal returns (uint256) {
        sHATE.transfer(_to, _amount); // send as sHATE (equal unit as HATE)
        return _amount;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice returns the sHATE index, which tracks rebase growth
     * @return uint
     */
    function index() public view returns (uint256) {
        return sHATE.index();
    }

    /**
     * @notice seconds until the next epoch begins
     */
    function secondsToNextEpoch() external view returns (uint256) {
        return epoch.end - block.timestamp;
    }

    /* ========== MANAGERIAL FUNCTIONS ========== */

    /**
     * @notice sets the contract address for LP staking
     * @param _distributor address
     */
    function setDistributor(address _distributor) external onlyOwner {
        distributor = IDistributor(_distributor);
        emit DistributorSet(_distributor);
    }
}