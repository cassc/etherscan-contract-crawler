// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./abstract/CustomErrors.sol";
import "./interfaces/ICybaspaceGenesisCollection.sol";
import "./interfaces/ITokenMinter.sol";

contract TokenMinter is Ownable, CustomErrors, ITokenMinter {
    ICybaspaceGenesisCollection public collection;

    uint256 public devShare;

    address private withdrawalDevTeam;
    address private withdrawalCompany;

    ///// MODIFIERS ////////////////////////////////////////////////
    modifier checkAddress(address _address) {
        if (_address == address(0)) revert AddressZero();
        _;
    }

    ////////////////////////////////////////////////////////////////

    /**
     * @param _collection Address of the CybaspaceGenesis collection contract
     * @param _devShare Share of funds for dev team
     */
    constructor(ICybaspaceGenesisCollection _collection, uint256 _devShare) {
        collection = _collection;
        devShare = _devShare;
    }

    /**
     * @dev Mints a CybaspaceGenesisToken to the given address
     *
     * @param _to Address which will receive the token
     */
    function mintToken(address _to) external payable {
        collection.mint(_to, msg.value);
    }

    /**
     * @notice Set dev team wallet can only decrease dev share, company wallet only increase
     * @dev Sets dev share
     *
     * @param _devShare New dev share value
     */
    function setDevShare(uint256 _devShare) external {
        if (_devShare > devShare && msg.sender != withdrawalCompany) revert WithdrawalParamsAccessDenied();
        if (_devShare < devShare && msg.sender != withdrawalDevTeam) revert WithdrawalParamsAccessDenied();
        uint256 oldShare = devShare;
        devShare = _devShare;
        emit devShareSet(_msgSender(), oldShare, devShare);
    }

    /**
     * @notice Callable only by the currently set dev team wallet / owner of contract if not set
     * @dev Sets withdrawal address for dev team to equal the specified value
     *
     * @param _address New address value for withdrawing funds for dev team
     */
    function setAddressDevTeam(
        address _address
    ) external checkAddress(_address) {
        if (withdrawalDevTeam == address(0)) {
            if (msg.sender != owner()) revert WithdrawalParamsAccessDenied();
        } else if (msg.sender != withdrawalDevTeam)
            revert WithdrawalParamsAccessDenied();
        withdrawalDevTeam = _address;
        emit WithdrawalAddressSet(_msgSender(), _address, "withdrawalDevTeam");
    }

    /**
     * @notice Callable only by the currently set company wallet / owner of contract if not set
     * @dev Sets withdrawal address for company to equal the specified value
     *
     * @param _address New address value for withdrawing funds for company
     */
    function setAddressCompany(
        address _address
    ) external checkAddress(_address) {
        if (withdrawalCompany == address(0)) {
            if (msg.sender != owner()) revert WithdrawalParamsAccessDenied();
        } else if (msg.sender != withdrawalCompany)
            revert WithdrawalParamsAccessDenied();
        withdrawalCompany = _address;
        emit WithdrawalAddressSet(_msgSender(), _address, "withdrawalCompany");
    }

    /**
     * @notice Callable only by the owner of this contract / deployer wallet
     * @dev withdraws funds according to share rule for involved participants
     */
    function withdraw() external onlyOwner {
        if (address(this).balance <= 0) revert CurrentSupplyExceedsMaxSupply();
        if (withdrawalDevTeam == address(0)) revert AddressZeroForWithdraw();
        if (withdrawalCompany == address(0)) revert AddressZeroForWithdraw();

        uint256 balance = address(this).balance;

        uint256 shareDevTeamFunds = ((balance * devShare) / 10000);
        uint256 shareCompanyFunds = ((balance * (10000 - devShare)) / 10000);

        payable(withdrawalDevTeam).transfer(shareDevTeamFunds);
        emit PaidOut(_msgSender(), withdrawalDevTeam, shareDevTeamFunds);
        payable(withdrawalCompany).transfer(shareCompanyFunds);
        emit PaidOut(_msgSender(), withdrawalCompany, shareCompanyFunds);

        emit Withdrawn(_msgSender(), balance);
    }
}