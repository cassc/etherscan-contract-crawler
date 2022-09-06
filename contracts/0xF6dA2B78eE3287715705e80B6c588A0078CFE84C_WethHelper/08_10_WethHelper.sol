// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "../Interfaces/IWETH9.sol";
import "../Interfaces/IBondDepository.sol";
import "../Interfaces/IWhitelistBondDepository.sol";

import "../Types/Signed.sol";

contract WethHelper is Signed {
    IWETH9 public weth;
    IBondDepository public bondDepo;
    IWhitelistBondDepository public whitelistBondDepo;
    IWhitelistBondDepository public publicPreListBondDepo;

    constructor(
        address _weth,
        ITheopetraAuthority _authority,
        address _bondDepo,
        address _whitelistBondDepo
    ) TheopetraAccessControlled(_authority) {
        weth = IWETH9(_weth);
        bondDepo = IBondDepository(_bondDepo);
        whitelistBondDepo = IWhitelistBondDepository(_whitelistBondDepo);
    }

    /**
     * @notice             Deposit to WETH, and subsequently deposit to the relevant Bond Depository
     * @dev                When the address of the Public Pre-List bond depository is non-zero (as set by `setPublicPreList`),
     *                     and `_isWhitelist` is true, then `deposit` will be called on the Public Pre-List
     *                     (as oposed to the Private Whitelist bond depository)
     * @param _id          the id of the bond market into which a deposit should be made
     * @param _maxPrice    the maximum price at which to buy
     * @param _user        the recipient of the payout
     * @param _referral    the front end operator address
     * @param _autoStake   bool, true if the payout should be automatically staked (this value is not used by the whitelist bond depository)
     * @param _isWhitelist bool, true if the bond depository is the whitelist bond depo or public pre-list bond depo
     * @param signature    the signature for verification of a whitelisted depositor
     */
    function deposit(
        uint256 _id,
        uint256 _maxPrice,
        address _user,
        address _referral,
        bool _autoStake,
        bool _isWhitelist,
        bytes calldata signature
    ) public payable {
        require(msg.value > 0, "No value");

        weth.deposit{ value: msg.value }();

        if (_isWhitelist && address(publicPreListBondDepo) == address(0)) {
            verifySignature("", signature);
            weth.approve(address(whitelistBondDepo), msg.value);
            whitelistBondDepo.deposit(_id, msg.value, _maxPrice, _user, _referral, signature);
        } else if (_isWhitelist) {
            weth.approve(address(publicPreListBondDepo), msg.value);
            publicPreListBondDepo.deposit(_id, msg.value, _maxPrice, _user, _referral, signature);
        } else {
            weth.approve(address(bondDepo), msg.value);
            bondDepo.deposit(_id, msg.value, _maxPrice, _user, _referral, _autoStake);
        }
    }

    /**
     * @notice             Set the address of the Public Pre-List Bond Depository
     * @dev                After setting to a non-zero address, calls to the `deposit` method with
     *                     `_isWhitelist` == true will result in deposits being made to the Public Pre-List bond depository
     *                     (as oposed to the Private Whitelist bond depository)
     *                     See also `deposit` method
     * @param _publicPreList          the address of the Public Pre-List Bond Depository Contract
     */
    function setPublicPreList(address _publicPreList) external onlyGovernor {
        publicPreListBondDepo = IWhitelistBondDepository(_publicPreList);
    }
}