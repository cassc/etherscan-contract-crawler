// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import {Module, Enum, FactoryFriendly} from "@gnosis.pm/zodiac/contracts/core/Module.sol";
import {Crowdfund} from "szns/Crowdfund.sol";
import {CaptainGuard} from "szns/CaptainGuard.sol";
import {BuyModule} from "szns/zodiac/modules/BuyModule.sol";
import {ListModule} from "szns/zodiac/modules/ListModule.sol";
import {IClaimActions} from "szns/interfaces/IClaimActions.sol";
import {IClaimEvents} from "szns/interfaces/IClaimEvents.sol";
import {ICrowdfundActions} from "szns/interfaces/ICrowdfundActions.sol";
import {IShipEvents} from "szns/interfaces/IShipEvents.sol";
import {Order} from "seaport/interfaces/ConsiderationInterface.sol";
import {OrderComponents} from "seaport/lib/ConsiderationStructs.sol";

struct ShipSetupArgs {
    string name;
    string symbol;
    uint256 endDuration;
    uint256 tokensPerEth;
    uint256 minRaise;
    uint256 captainFeeRate;
    uint256 sznsDAOFeeRate;
    address captain;
    address[] nfts;
}

contract ShipModule is
    Module,
    Crowdfund,
    ICrowdfundActions,
    IClaimActions,
    IClaimEvents,
    IShipEvents,
    BuyModule,
    ListModule,
    CaptainGuard
{
    error NoClaimAvailable();
    error NoContribution();
    error NFTNotBoughtYet();
    error CallFailed();
    error UseContributeMethod();
    error ClaimFailed();

    // Abandon errors and events
    error NoAbandonAlreadyClosed();
    error NoAbandonNFTBought();

    //Buy errors
    error RaiseNotMet();
    error BuyClosed();

    event CaptainClaimed(address captain, uint256 amount);
    error CaptainClaimFailed();

    error ZeroAddressShipModule();

    //List errors
    error ListNotAllowed();

    // Represents total claimable at a snapshot event
    mapping(uint256 => uint256) public claims;
    mapping(address => mapping(uint256 => bool)) public claimed;

    uint256 public captainFees;
    uint256 public captainFeeRate;
    uint256 public sznsDaoFeeRate;
    address public immutable SZNSDAO;

    bool private nftBought;

    constructor(
        address _avatar,
        address _target,
        address _sznsDAO,
        address _seaport,
        address _conduit,
        address _royaltyEngine,
        ShipSetupArgs memory _sv
    )
        Crowdfund(_sv.endDuration, _sv.tokensPerEth, _sv.minRaise)
        BuyModule(_seaport)
        CaptainGuard(_sv.captain)
        ListModule(_seaport, _conduit, _royaltyEngine)
    {
        if (_sznsDAO == address(0)) revert ZeroAddressShipModule();
        SZNSDAO = _sznsDAO;
        bytes memory initParams = abi.encode(_avatar, _target, _sv);
        setUp(initParams); // If we do this here, it can not be inherited
    }

    /**
     * @dev Initialize function, will be triggered when a new proxy is deployed
     * @param initializeParams Parameters of initialization encoded
     * @notice This function will initialize the contract, including setting the avatar, target, and ship setup arguments.
     * @notice This function will also transfer ownership of the contract to the provided avatar address.
     */
    function setUp(
        bytes memory initializeParams
    ) public override(FactoryFriendly, BuyModule, ListModule) initializer {
        __Ownable_init();

        (address _avatar, address _target, ShipSetupArgs memory _sv) = abi
            .decode(initializeParams, (address, address, ShipSetupArgs));

        // Initialize ERC20 snapshot
        __ERC20_init(_sv.name, _sv.symbol);
        __ERC20Snapshot_init();

        // Initialize Crowdfund
        __Crowdfund_init(_sv.endDuration, _sv.tokensPerEth, _sv.minRaise);

        // BuyModule specific setup
        __BuyModule_setUp(_sv.nfts);

        // All immutable variables need to be set
        // after proxy initialization
        captainFeeRate = _sv.captainFeeRate;
        sznsDaoFeeRate = _sv.sznsDAOFeeRate;
        CAPTAIN = _sv.captain;

        setRecipient(payable(address(this)));

        avatar = _avatar; // safe
        target = _target; // contract to call exec
        transferOwnership(_avatar);
    }

    /**
     * @dev This function is the fallback function of the contract, which allows users to make payments to the contract.
     * @notice This function will take a snapshot of the user's balance and distribute the payment among the captain, SZNSDAO and the user's balance.
     * @notice Revert if the contribution period is open or if the call to the avatar or SZNSDAO contract fail.
     * @notice This will only work via call.value() calls and not send()/transfer() when transferring ETH to this contract
     * @notice https://github.com/ConsenSysMesh/Ethereum-Development-Best-Practices/wiki/Fallback-functions-and-the-fundamental-limitations-of-using-send()-in-Ethereum-&-Solidity
     */
    function _receive() internal {
        // Don't take any snapshots if we are currently taking contributions
        if (_hasRaiseClosed()) {
            uint256 passengersShare = (msg.value * (100e18 - captainFeeRate)) /
                100e18;

            uint256 daoShare = (msg.value * sznsDaoFeeRate) / 100e18;

            _snapshot(passengersShare - daoShare);

            captainFees += (msg.value - passengersShare);

            (bool success, ) = avatar.call{value: (msg.value - daoShare)}("");
            if (!success) revert CallFailed();

            (success, ) = SZNSDAO.call{value: daoShare}("");
            if (!success) revert CallFailed();
        } else {
            revert UseContributeMethod();
        }
    }

    receive() external payable {
        _receive();
    }

    // Fallback function is called when msg.data is not empty
    fallback() external {
        _receive();
    }

    /**
     * @dev This function returns the claim amount for a user, given their account address and claim ID.
     * @param account The address of the user's account.
     * @param claimID The ID of the claim.
     * @return claimAmount The amount of tokens that the user can claim.
     * @notice Revert if the user has already claimed their tokens.
     */
    function getClaimAmount(
        address account,
        uint256 claimID
    ) public view returns (uint256 claimAmount) {
        if (claimed[account][claimID]) {
            claimAmount = 0;
        } else {
            claimAmount =
                (balanceOfAt(account, claimID) * claims[claimID]) /
                totalSupply();
        }
    }

    /// @dev Get the total claims for an address
    /// @param account The address to get total claim amounts
    /// @return totalClaims the amount claimed
    function getTotalClaims(
        address account
    ) public view returns (uint256 totalClaims) {
        unchecked {
            // Snapshots start at index 1
            for (uint256 i = 1; i <= _getCurrentSnapshotId(); ++i) {
                totalClaims += getClaimAmount(account, i);
            }
        }
    }

    /**
     * @dev This function checks if a user has a claim available for a given snapshot ID.
     * @param account The address of the user's account.
     * @param claimID The ID of the snapshot.
     * @return True if the user has a claim available for the snapshot, false otherwise.
     */
    function hasClaim(
        address account,
        uint256 claimID
    ) public view virtual returns (bool) {
        return balanceOfAt(account, claimID) > 0 && !claimed[account][claimID];
    }

    /**
     * @dev This function allows a user to claim the tokens that they are entitled to for a given snapshot ID.
     * @param claimID The ID of the snapshot.
     * @return claimedAmount The amount of tokens claimed by the user.
     * @notice Revert if the user does not have a claim available for the snapshot ID.
     * @notice Emit Claimed event on successful claim.
     */
    function claim(uint256 claimID) public returns (uint256 claimedAmount) {
        if (!hasClaim(msg.sender, claimID)) {
            revert NoClaimAvailable();
        }

        claimedAmount = getClaimAmount(msg.sender, claimID);

        // Mark claimed first to prevent reentrancy
        claimed[msg.sender][claimID] = true;

        bool success = exec(msg.sender, claimedAmount, "", Enum.Operation.Call);

        if (success) {
            emit Claimed(msg.sender, claimedAmount, claimID);
        } else {
            revert ClaimFailed();
        }
    }

    /// @dev Bulk claim revenue
    /// @param claimIDs Array of claim events to claim
    /// @return claimedAmount the amount claimed
    function bulkClaim(
        uint256[] memory claimIDs
    ) public returns (uint256 claimedAmount) {
        unchecked {
            uint256 len = claimIDs.length;
            for (uint256 i = 0; i < len; ) {
                claimedAmount += claim(claimIDs[i]);
                ++i;
            }
        }
    }

    /**
     * @dev This function allows the captain to end the fundraising period and take a snapshot of the target contract's balance.
     * @notice Revert if the fundraising period has already been force closed, if the caller is not the captain, or if the NFT has not been purchased yet.
     */
    function endRaise() public {
        if (_hasRaiseClosed()) {
            //If raise was already force closed
            revert RaiseClosed();
        } else if (_isRaiseOpen()) {
            // If sail raise still active
            // Check only captain call call this
            if (!isCaptain()) revert NotCaptain();

            // Captain can only call if nft bought
            if (!nftBought) revert NFTNotBoughtYet();
        }

        _snapshot(target.balance);

        _endRaise();

        // if no nft bought and raise was force ended the ship essentially ended
        if (!nftBought) {
            emit Abandon(msg.sender, target, target.balance);
        }
    }

    /**
     * @dev This function allows the captain to abandon the ship, ending the fundraising period and taking a snapshot of the target contract's balance.
     * @notice Revert if the fundraising period has already been force closed, or if the NFT has been purchased.
     * @notice Emit Abandon event on successful abandonment of ship.
     */
    function abandonShip() public onlyCaptain {
        if (_hasRaiseClosed()) {
            //If raise was already force closed
            revert NoAbandonAlreadyClosed();
        } else if (nftBought) {
            //If bought the captain can no longer abandon ship
            revert NoAbandonNFTBought();
        }

        _snapshot(target.balance);

        _endRaise();

        emit Abandon(msg.sender, target, target.balance);
    }

    /**
     * @dev This function allows the captain to claim their fees from the contract.
     * @notice Revert if the caller is not the captain.
     * @notice Emit CaptainClaimed event on successful claim of captain's fees.
     */
    function claimCaptainFees() public onlyCaptain {
        uint256 fees = captainFees;

        // Prevent reentrency
        delete captainFees;

        bool success = exec(msg.sender, fees, "", Enum.Operation.Call);

        if (success) {
            emit CaptainClaimed(msg.sender, fees);
        } else {
            revert CaptainClaimFailed();
        }
    }

    /**
     * @dev This function creates a new snapshot and records the amount of tokens that are claimable.
     * @param claimable The amount of tokens that are claimable.
     * @notice Emit Claimable event on successful creation of snapshot with claimable value and id.
     */
    function _snapshot(uint256 claimable) internal {
        uint256 id = super._snapshot();

        claims[id] = claimable;

        emit Claimable(claimable, id);
    }

    /**
     * @dev This function allows a user to contribute to the contract and mint new tokens.
     * @notice Revert if the user sends a value of 0.
     * @return minted The number of tokens minted for the user.
     * @notice Revert if the call to the avatar contract fails.
     */
    function contribute() public payable returns (uint256 minted) {
        if (msg.value == 0) {
            revert NoContribution();
        }

        minted = _contribute();

        (bool success, bytes memory data) = avatar.call{value: msg.value}("");
        require(success, string(data));
    }

    /**
     * @dev This function allows the captain to buy an NFT from OpenSea.
     * @param seaportOrder The order from OpenSea for the NFT.
     * @notice Revert if the fundraising period has closed, if the fundraising goal has not been met, or if the caller is not the captain.
     */
    function buy(Order calldata seaportOrder) public override onlyCaptain {
        if (!_isRaiseOpen() || _hasRaiseClosed()) {
            revert BuyClosed();
        } else if (!_hasRaiseMet()) {
            revert RaiseNotMet();
        } else {
            nftBought = true;
        }

        super.buy(seaportOrder);
    }

    /**
     * @dev This function allows the captain to list an NFT on OpenSea after the fundraising period has closed.
     * @param nftContract The contract address of the NFT.
     * @param tokenID The ID of the NFT.
     * @param amount The amount to be listed.
     * @param duration The duration of the listing.
     * @notice Revert if the fundraising period is still open, or if the caller is not the captain.
     */
    function list(
        address nftContract,
        uint256 tokenID,
        uint256 amount,
        uint256 duration
    ) public override onlyCaptain {
        if (!_hasRaiseClosed()) {
            revert ListNotAllowed();
        } else {
            super.list(nftContract, tokenID, amount, duration);
        }
    }

    /**
     * @dev This function allows the captain to cancel one or more orders on OpenSea.
     * @param orders The orders to be cancelled.
     * @notice Revert if the caller is not the captain.
     */
    function cancel(
        OrderComponents[] calldata orders
    ) public override onlyCaptain {
        super.cancel(orders);
    }

    /**
     * @dev This function checks if the total contributions have met the minimum raise goal.
     * @return true if the goal has been met, false otherwise.
     */
    function hasRaiseMet() external view returns (bool) {
        return _hasRaiseMet();
    }

    /**
     * @dev This function checks if the fundraising period is still open.
     * @return true if the fundraising period is open, false otherwise.
     */
    function isRaiseOpen() external view returns (bool) {
        return _isRaiseOpen();
    }
}