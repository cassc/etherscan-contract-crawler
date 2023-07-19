// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../currency/VoteCheckpoints.sol";
import "../../currency/ECOx.sol";
import "../../policy/PolicedUtils.sol";
import "../IGeneration.sol";

/** @title ECOxStaking
 *
 */
contract ECOxStaking is VoteCheckpoints, PolicedUtils {
    /** The Deposit event indicates that ECOx has been locked up, credited
     * to a particular address in a particular amount.
     *
     * @param source The address that a deposit certificate has been issued to.
     * @param amount The amount of ECOx tokens deposited.
     */
    event Deposit(address indexed source, uint256 amount);

    /** The Withdrawal event indicates that a withdrawal has been made to a particular
     * address in a particular amount.
     *
     * @param destination The address that has made a withdrawal.
     * @param amount The amount in basic unit of 10^{-18} ECOx (weicoX) tokens withdrawn.
     */
    event Withdrawal(address indexed destination, uint256 amount);

    // the ECOx contract address
    IERC20 public immutable ecoXToken;

    constructor(Policy _policy, IERC20 _ecoXAddr)
        // Note that the policy has the ability to pause transfers
        // through ERC20Pausable, although transfers are paused by default
        // therefore the pauser is unset
        VoteCheckpoints("Staked ECOx", "sECOx", address(_policy), address(0))
        PolicedUtils(_policy)
    {
        require(
            address(_ecoXAddr) != address(0),
            "Critical: do not set the _ecoXAddr as the zero address"
        );
        ecoXToken = _ecoXAddr;
    }

    function deposit(uint256 _amount) external {
        address _source = msg.sender;

        require(
            ecoXToken.transferFrom(_source, address(this), _amount),
            "Transfer failed"
        );

        _mint(_source, _amount);

        emit Deposit(_source, _amount);
    }

    function withdraw(uint256 _amount) external {
        address _destination = msg.sender;

        // do this first to ensure that any undelegations in this function are caught
        _burn(_destination, _amount);

        require(ecoXToken.transfer(_destination, _amount), "Transfer Failed");

        emit Withdrawal(_destination, _amount);
    }

    function votingECOx(address _voter, uint256 _blockNumber)
        external
        view
        returns (uint256)
    {
        return getPastVotingGons(_voter, _blockNumber);
    }

    function totalVotingECOx(uint256 _blockNumber)
        external
        view
        returns (uint256)
    {
        return getPastTotalSupply(_blockNumber);
    }

    function transfer(address, uint256) public pure override returns (bool) {
        revert("sECOx is non-transferrable");
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public pure override returns (bool) {
        revert("sECOx is non-transferrable");
    }
}