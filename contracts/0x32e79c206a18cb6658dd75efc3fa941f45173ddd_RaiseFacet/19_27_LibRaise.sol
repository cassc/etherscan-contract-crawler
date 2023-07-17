// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

// OpenZeppelin imports
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Local imports
import { LibAppStorage } from "./LibAppStorage.sol";
import { IEscrow } from "../interfaces/IEscrow.sol";
import { IEquityBadge } from "../../interfaces/IEquityBadge.sol";
import { BaseTypes } from "../structs/BaseTypes.sol";
import { StateTypes } from "../structs/StateTypes.sol";

/**************************************

    Raise library

    ------------------------------

    Diamond storage containing raise data

 **************************************/

/// @notice Library containing RaiseStorage and low level functions.
library LibRaise {
    // -----------------------------------------------------------------------
    //                              Library usage
    // -----------------------------------------------------------------------

    using SafeERC20 for IERC20;

    // -----------------------------------------------------------------------
    //                              Constants
    // -----------------------------------------------------------------------

    /// @dev Raise storage pointer.
    bytes32 constant RAISE_STORAGE_POSITION = keccak256("angelblock.fundraising.raise");
    /// @dev Precision for reclaim calculations.
    uint256 constant PRICE_PRECISION = 10 ** 18;

    // -----------------------------------------------------------------------
    //                              Structs
    // -----------------------------------------------------------------------

    /// @dev Raise storage struct.
    /// @param raises Mapping of raise id to particular raise struct
    /// @param vested Mapping of raise id to vested token information
    /// @param investInfo Mapping of raise id to raise state information
    struct RaiseStorage {
        mapping(string => BaseTypes.Raise) raises;
        mapping(string => BaseTypes.Vested) vested;
        mapping(string => StateTypes.ProjectInvestInfo) investInfo;
    }

    // -----------------------------------------------------------------------
    //                              Errors
    // -----------------------------------------------------------------------

    error NotEnoughBalanceForInvestment(address sender, uint256 investment); // 0xaff6db15
    error NotEnoughAllowance(address sender, address spender, uint256 amount); // 0x892e7739

    // -----------------------------------------------------------------------
    //                              Diamond storage
    // -----------------------------------------------------------------------

    /// @dev Function returning raise storage at storage pointer slot.
    /// @return rs RaiseStorage struct instance at storage pointer position
    function raiseStorage() internal pure returns (RaiseStorage storage rs) {
        // declare position
        bytes32 position = RAISE_STORAGE_POSITION;

        // set slot to position
        assembly {
            rs.slot := position
        }

        // explicit return
        return rs;
    }

    // -----------------------------------------------------------------------
    //                              Getters / Setters
    // -----------------------------------------------------------------------

    /// @dev Diamond storage getter: raises->raiseType.
    /// @param _raiseId ID of raise
    /// @return Type of raise {Standard, EarlyStage}
    function getRaiseType(string memory _raiseId) internal view returns (BaseTypes.RaiseType) {
        return raiseStorage().raises[_raiseId].raiseType;
    }

    /// @dev Diamond storage getter: raises->owner.
    /// @param _raiseId ID of raise
    /// @return Owner of raise
    function getRaiseOwner(string memory _raiseId) internal view returns (address) {
        // return
        return raiseStorage().raises[_raiseId].owner;
    }

    /// @dev Diamond storage getter: hardcap.
    /// @param _raiseId ID of raise
    /// @return Hardcap of raise
    function getHardCap(string memory _raiseId) internal view returns (uint256) {
        // return
        return raiseStorage().raises[_raiseId].raiseDetails.hardcap;
    }

    /// @dev Diamond storage getter: vested->erc20.
    /// @param _raiseId ID of raise
    /// @return ERC20 address of raise
    function getVestedERC20(string memory _raiseId) internal view returns (address) {
        // return
        return raiseStorage().vested[_raiseId].erc20;
    }

    /// @dev Diamond storage getter: vested->amount.
    /// @param _raiseId ID of raise
    /// @return Amount of vested ERC20 of raise
    function getVestedAmount(string memory _raiseId) internal view returns (uint256) {
        // return
        return raiseStorage().vested[_raiseId].amount;
    }

    /// @dev Diamond storage setter: vested->erc20.
    /// @param _raiseId ID of raise
    /// @param _token Address of ERC20
    function setVestedERC20(string memory _raiseId, address _token) internal {
        raiseStorage().vested[_raiseId].erc20 = _token;
    }

    /// @dev Diamond storage setter: raise.
    /// @param _raiseId ID of raise
    /// @param _raise Raise to save
    /// @param _vested Vested currency and amount to save for raise
    function saveRaise(string memory _raiseId, BaseTypes.Raise memory _raise, BaseTypes.Vested memory _vested) internal {
        // get storage
        RaiseStorage storage rs = raiseStorage();

        // save raise
        rs.raises[_raiseId] = _raise;
        rs.vested[_raiseId] = _vested;
    }

    /// @dev Diamond storage setter: investment.
    /// @param _raiseId ID of raise
    /// @param _investment Invested amount to save
    function saveInvestment(string memory _raiseId, uint256 _investment) internal {
        // tx.members
        address sender_ = msg.sender;

        // get storage
        RaiseStorage storage rs = raiseStorage();

        // save investment
        rs.investInfo[_raiseId].raised += _investment;
        rs.investInfo[_raiseId].invested[sender_] += _investment;
    }

    /// @dev Diamond storage getter: investment.
    /// @param _raiseId ID of raise
    /// @param _account Address to check investment for
    /// @return Amount of investment
    function getInvestment(string memory _raiseId, address _account) internal view returns (uint256) {
        // return
        return raiseStorage().investInfo[_raiseId].invested[_account];
    }

    /// @dev Diamond storage getter: total investment.
    /// @param _raiseId ID of raise
    /// @return Sum of all investments in raise
    function getTotalInvestment(string memory _raiseId) internal view returns (uint256) {
        // return
        return raiseStorage().investInfo[_raiseId].raised;
    }

    // -----------------------------------------------------------------------
    //                              Badge module
    // -----------------------------------------------------------------------

    /**************************************

        Convert raise id to badge id

     **************************************/

    /// @dev Convert raise to badge.
    /// @param _raiseId ID of raise
    /// @return ID of badge (derived from hash of raise ID)
    function convertRaiseToBadge(string memory _raiseId) internal pure returns (uint256) {
        // return
        return uint256(keccak256(abi.encode(_raiseId)));
    }

    /**************************************

        Mint badge

     **************************************/

    /// @dev Mint badge.
    /// @param _badgeId ID of badge
    /// @param _investment Amount of badges to mint is proportional to investment amount
    function mintBadge(uint256 _badgeId, uint256 _investment) internal {
        // tx.members
        address sender_ = msg.sender;

        // get badge
        IEquityBadge badge = LibAppStorage.getBadge();

        // erc1155 bytes conversion
        bytes memory data_ = abi.encode(_badgeId);

        // mint equity badge
        badge.mint(sender_, _badgeId, _investment, data_);
    }

    /**************************************

        Set token URI

     **************************************/

    /// @dev Set badge URI.
    /// @param _badgeId ID of badge
    /// @param _uri URI to set
    function setUri(uint256 _badgeId, string memory _uri) internal {
        // set uri
        LibAppStorage.getBadge().setURI(_badgeId, _uri);
    }

    // -----------------------------------------------------------------------
    //                              Raise module
    // -----------------------------------------------------------------------

    /**************************************

        Collect vested ERC20

     **************************************/

    /// @dev Collect vested ERC20 to start a raise.
    /// @dev Validation: Requires startup to have enough ERC20 and provide allowance.
    /// @dev Events: Transfer(address from, address to, uint256 value).
    /// @param _token Address of ERC20
    /// @param _sender Address of startup to withdraw ERC20 from
    /// @param _escrow Address of cloned Escrow instance for raise
    /// @param _amount Amount of ERC20 to collect
    function collectVestedToken(address _token, address _sender, address _escrow, uint256 _amount) internal {
        // tx.members
        address self_ = address(this);

        // erc20
        IERC20 erc20_ = IERC20(_token);

        // allowance check
        uint256 allowance_ = erc20_.allowance(_sender, self_);
        if (allowance_ < _amount) {
            revert NotEnoughAllowance(_sender, self_, allowance_);
        }

        // vest erc20
        erc20_.safeTransferFrom(_sender, _escrow, _amount);
    }

    /**************************************

        Collect USDT for investment

     **************************************/

    /// @dev Collect USDT from investor.
    /// @dev Validation: Requires investor to have assets and provide enough allowance.
    /// @dev Events: Transfer(address from, address to, uint256 value).
    /// @param _sender Address of investor
    /// @param _investment Amount of investment
    /// @param _escrow Address of escrow
    function collectUSDT(address _sender, uint256 _investment, address _escrow) internal {
        // get USDT contract
        IERC20 usdt_ = LibAppStorage.getUSDT();

        // check balance
        if (usdt_.balanceOf(_sender) < _investment) revert NotEnoughBalanceForInvestment(_sender, _investment);

        // check approval
        if (usdt_.allowance(_sender, address(this)) < _investment) revert NotEnoughAllowance(_sender, address(this), _investment);

        // transfer
        usdt_.safeTransferFrom(_sender, _escrow, _investment);
    }

    /**************************************

        Raise exists

     **************************************/

    /// @dev Check if raise exists.
    /// @param _raiseId ID of raise
    /// @return True if fundraising exists
    function raiseExists(string memory _raiseId) internal view returns (bool) {
        // return
        return bytes(raiseStorage().raises[_raiseId].raiseId).length != 0;
    }

    /**************************************

        Check if given raise is still active

     **************************************/

    /// @dev Check if raise is active.
    /// @param _raiseId ID of raise
    /// @return True if investment round is ongoing
    function isRaiseActive(string memory _raiseId) internal view returns (bool) {
        // tx.members
        uint256 now_ = block.timestamp;

        // get raise
        BaseTypes.Raise storage raise_ = raiseStorage().raises[_raiseId];

        // final check
        return raise_.raiseDetails.start <= now_ && now_ <= raise_.raiseDetails.end;
    }

    /**************************************

        Check if given raise finished already

     **************************************/

    /// @dev Check if raise is finished.
    /// @param _raiseId ID of raise
    /// @return True if investment round is finished
    function isRaiseFinished(string memory _raiseId) internal view returns (bool) {
        return raiseStorage().raises[_raiseId].raiseDetails.end < block.timestamp;
    }

    /**************************************

        Check if given raise achieved softcap

     **************************************/

    /// @dev Check if softcap was achieved.
    /// @param _raiseId ID of raise
    /// @return True if softcap was achieved
    function isSoftcapAchieved(string memory _raiseId) internal view returns (bool) {
        RaiseStorage storage rs = raiseStorage();
        return rs.raises[_raiseId].raiseDetails.softcap <= rs.investInfo[_raiseId].raised;
    }

    // -----------------------------------------------------------------------
    //                              Refund module
    // -----------------------------------------------------------------------

    /// @dev Check if USDT was refunded to investor.
    /// @param _raiseId ID of raise
    /// @param _account Address of investor
    /// @return True if investor was refunded
    function investmentRefunded(string memory _raiseId, address _account) internal view returns (bool) {
        return raiseStorage().investInfo[_raiseId].investmentRefunded[_account];
    }

    /// @dev Check if collateral was refunded to startup.
    /// @param _raiseId ID of raise
    /// @return True if startup was refunded
    function collateralRefunded(string memory _raiseId) internal view returns (bool) {
        return raiseStorage().investInfo[_raiseId].collateralRefunded;
    }

    /**************************************

        Make raise refund for given wallet

     **************************************/

    /// @dev Refund USDT to investor.
    /// @dev Events: Escrow.Withdraw(address token, address receiver, uint256 amount).
    /// @param _sender Address of receiver
    /// @param _escrow Address of escrow
    /// @param _raiseId ID of raise
    /// @param _investment Amount of invested USDT
    function refundUSDT(address _sender, address _escrow, string memory _raiseId, uint256 _investment) internal {
        // prepare for transfer
        RaiseStorage storage rs = raiseStorage();
        rs.investInfo[_raiseId].investmentRefunded[_sender] = true;

        // get USDT token address
        address usdt_ = address(LibAppStorage.getUSDT());

        // prepare Escrow 'ReceiverData'
        IEscrow.ReceiverData memory receiverData_ = IEscrow.ReceiverData({ receiver: _sender, amount: _investment });

        // transfer
        IEscrow(_escrow).withdraw(usdt_, receiverData_);
    }

    /**************************************

        Refund startup

     **************************************/

    /// @dev Refund collateral to startup.
    /// @dev Events: Escrow.Withdraw(address token, address receiver, uint256 amount).
    /// @param _sender Address of recipient
    /// @param _escrow Address of escrow
    /// @param _raiseId ID of raise
    /// @param _collateral Amount of deposited ERC20
    function refundCollateral(address _sender, address _escrow, string memory _raiseId, uint256 _collateral) internal {
        // load storage
        RaiseStorage storage rs = raiseStorage();

        // prepare for transfer
        rs.investInfo[_raiseId].collateralRefunded = true;

        // get vested token address
        address vestedToken_ = getVestedERC20(_raiseId);

        // prepare Escrow 'ReceiverData'
        IEscrow.ReceiverData memory receiverData_ = IEscrow.ReceiverData({ receiver: _sender, amount: _collateral });

        // transfer
        IEscrow(_escrow).withdraw(vestedToken_, receiverData_);
    }

    // -----------------------------------------------------------------------
    //                              Reclaim module
    // -----------------------------------------------------------------------

    /**************************************

        Get unsold tokens

     **************************************/

    /// @dev Get amount of unsold tokens.
    /// @param _raiseId ID of raise
    /// @param _diff Amount of unsold base asset
    /// @return Amount of tokens to reclaim
    function getUnsold(string memory _raiseId, uint256 _diff) internal view returns (uint256) {
        // get price (ratio of 1 wei of base asset to wei of token)
        BaseTypes.Price memory price_ = raiseStorage().raises[_raiseId].raiseDetails.price;

        // calculate how much tokens are unsold
        return (price_.tokensPerBaseAsset * _diff) / PRICE_PRECISION;
    }

    /**************************************

        Reclaim unsold tokens

     **************************************/

    /// @dev Reclaim unsold tokens.
    /// @dev Events: Escrow.Withdraw(address token, address receiver, uint256 amount).
    /// @param _escrow Escrow address
    /// @param _sender Receiver address
    /// @param _raiseId ID of raise
    /// @param _unsold Amount of tokens to reclaim
    function reclaimUnsold(address _escrow, address _sender, string memory _raiseId, uint256 _unsold) internal {
        // get erc20
        address erc20_ = raiseStorage().vested[_raiseId].erc20;

        // prepare data
        IEscrow.ReceiverData memory receiverData_ = IEscrow.ReceiverData({ receiver: _sender, amount: _unsold });

        // send tokens
        IEscrow(_escrow).withdraw(erc20_, receiverData_);
    }
}