// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

// OpenZeppelin imports
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Local imports
import { BaseTypes } from "../structs/BaseTypes.sol";
import { StateTypes } from "../structs/StateTypes.sol";
import { LibAppStorage } from "./LibAppStorage.sol";
import { IEquityBadge } from "../../interfaces/IEquityBadge.sol";

/**************************************

    Raise library

    ------------------------------

    Diamond storage containing raise data

 **************************************/

library LibRaise {
    using SafeERC20 for IERC20;

    // storage pointer
    bytes32 constant RAISE_STORAGE_POSITION = keccak256("angelblock.fundraising.raise");

    // structs: data containers
    struct RaiseStorage {
        mapping (string => BaseTypes.Raise) raises;
        mapping (string => BaseTypes.Vested) vested;
        mapping (string => StateTypes.ProjectInvestInfo) investInfo;
    }

    // diamond storage getter
    function raiseStorage() internal pure
    returns (RaiseStorage storage rs) {

        // declare position
        bytes32 position = RAISE_STORAGE_POSITION;

        // set slot to position
        assembly {
            rs.slot := position
        }

        // explicit return
        return rs;

    }

    // diamond storage getter: vested.erc20
    function getVestedERC20(string memory _raiseId) internal view
    returns (address) {

        // return
        return raiseStorage().vested[_raiseId].erc20;

    }

    // diamond storage getter: vested.ether
    function getVestedEther(string memory _raiseId) internal view
    returns (uint256) {

        // return
        return raiseStorage().vested[_raiseId].amount;

    }

    // diamond storage setter: raise
    function saveRaise(
        string memory _raiseId,
        BaseTypes.Raise memory _raise,
        BaseTypes.Vested memory _vested
    ) internal {

        // get storage
        RaiseStorage storage rs = raiseStorage();

        // save raise
        rs.raises[_raiseId] = _raise;
        rs.vested[_raiseId] = _vested;

    }

    // diamond storage getter: investment
    function getInvestment(
        string memory _raiseId,
        address _account
    ) internal view
    returns (uint256) {

        // return
        return raiseStorage().investInfo[_raiseId].invested[_account];

    }

    // diamond storage getter: total investment
    function getTotalInvestment(
        string memory _raiseId
    ) internal view
    returns (uint256) {

        // return
        return raiseStorage().investInfo[_raiseId].raised;

    }

    // diamond storage setter: investment
    function saveInvestment(
        string memory _raiseId,
        uint256 _investment
    ) internal {

        // tx.members
        address sender_ = msg.sender;

        // get storage
        RaiseStorage storage rs = raiseStorage();

        // save investment
        rs.investInfo[_raiseId].raised += _investment;
        rs.investInfo[_raiseId].invested[sender_] += _investment;

    }

    // diamond storage getter: hardcap
    function getHardCap(
        string memory _raiseId
    ) internal view returns (uint256) {

        // return
        return raiseStorage().raises[_raiseId].hardcap;

    }

    // errors
    error RaiseAlreadyExists(string raiseId);
    error RaiseDoesNotExists(string raiseId);
    error NotEnoughBalanceForInvestment(address sender, uint256 investment);
    error NotEnoughAllowanceForInvestment(address sender, uint256 investment);

    /**************************************

        Verify raise

     **************************************/

    function verifyRaise(string memory _raiseId) internal view {

        // get storage
        RaiseStorage storage rs = raiseStorage();

        // check existence
        if (bytes(rs.raises[_raiseId].raiseId).length != 0) {
            revert RaiseAlreadyExists(_raiseId);
        }

    }

    /**************************************

        Convert raise id to badge id

     **************************************/

    function convertRaiseToBadge(string memory _raiseId) internal view
    returns (uint256) {

        // existence check
        if (bytes(raiseStorage().raises[_raiseId].raiseId).length == 0) {
            revert RaiseDoesNotExists(_raiseId);
        }

        // return
        return uint256(keccak256(abi.encode(_raiseId)));

    }

    /**************************************

        Mint badge

     **************************************/

    function mintBadge(
        uint256 _badgeId,
        uint256 _investment
    ) internal {

        // tx.members
        address sender_ = msg.sender;

        // get badge
        IEquityBadge badge = LibAppStorage.getBadge();

        // erc1155 bytes conversion
        bytes memory data_ = abi.encode(_badgeId);

        // delegate on behalf
        badge.delegateOnBehalf(sender_, sender_, data_);

        // mint equity badge
        badge.mint(sender_, _badgeId, _investment, data_);

    }

    /**************************************

        Balance of badge

     **************************************/

    function badgeBalanceOf(
        address _owner,
        uint256 _badgeId
    ) internal view
    returns (uint256) {

        // return
        return LibAppStorage.getBadge().balanceOf(
            _owner,
            _badgeId
        );

    }

    /**************************************

        Total supply of badge

     **************************************/

    function badgeTotalSupply(uint256 _badgeId) internal view
    returns (uint256) {

        // return
        return LibAppStorage.getBadge().totalSupply(_badgeId);

    }

    /**************************************

        Collect USDT for investment

     **************************************/

    function collectUSDT(address _sender, uint256 _investment) internal {

        // tx.members
        address self_ = address(this);
        
        // get USDT contract
        IERC20 usdt_ = LibAppStorage.getUSDT();

        // check balance
        if (usdt_.balanceOf(_sender) < _investment)
            revert NotEnoughBalanceForInvestment(_sender, _investment);

        // check approval
        if (usdt_.allowance(_sender, address(this)) < _investment)
            revert NotEnoughAllowanceForInvestment(_sender, _investment);

        // transfer
        usdt_.safeTransferFrom(
            _sender,
            self_,
            _investment
        );

    } 

    /**************************************

        Check if given raise is still active

     **************************************/

    function isRaiseActive(string memory _raiseId) internal view
    returns (bool) {
        
        // tx.members
        uint256 now_ = block.timestamp;

        // get raise
        BaseTypes.Raise storage raise_ = raiseStorage().raises[_raiseId];

        // final check
        return raise_.start <= now_ && now_ <= raise_.end;

    }

    /**************************************

        Check if given raise finished already

     **************************************/

    function isRaiseFinished(string memory _raiseId) internal view
    returns (bool) {
        return raiseStorage().raises[_raiseId].end < block.timestamp;
    }

    /**************************************

        Check if given raise achieved softcap

     **************************************/

    function isSoftcapAchieved(string memory _raiseId) internal view
    returns (bool) {
        RaiseStorage storage rs = raiseStorage();
        return rs.raises[_raiseId].softcap <= rs.investInfo[_raiseId].raised;
    }

    /**************************************

        Make raise refund for given wallet

     **************************************/

    function refundUSDT(
        address _sender,
        string memory _raiseId
    ) internal {

        // prepare for transfer
        RaiseStorage storage rs = raiseStorage();
        uint256 investment_ = rs.investInfo[_raiseId].invested[_sender];
        rs.investInfo[_raiseId].invested[_sender] = 0;

        // transfer
        LibAppStorage.getUSDT().safeTransfer(
            _sender,
            investment_
        );

    }
}