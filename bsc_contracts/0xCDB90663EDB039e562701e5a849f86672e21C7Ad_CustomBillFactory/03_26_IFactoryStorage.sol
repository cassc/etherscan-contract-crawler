// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "./ICustomBill.sol";

interface IFactoryStorage {
    struct BillDetails {
        address payoutToken;
        address principalToken;
        address treasuryAddress;
        address billAddress;
        address billNft;
        uint256[] tierCeilings;
        uint256[] fees;
    }

    function totalBills() external view returns(uint);

    function getBillDetails(uint256 index) external returns (BillDetails memory);

    function pushBill(
        ICustomBill.BillCreationDetails calldata _billCreationDetails,
        address _customTreasury,
        address billAddress,
        address billNft
    ) external returns (address _treasury, address _bill);
}