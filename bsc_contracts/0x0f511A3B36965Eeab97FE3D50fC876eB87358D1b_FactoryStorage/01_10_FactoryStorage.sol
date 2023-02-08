// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/*
  ______                     ______                                 
 /      \                   /      \                                
|  ▓▓▓▓▓▓\ ______   ______ |  ▓▓▓▓▓▓\__   __   __  ______   ______  
| ▓▓__| ▓▓/      \ /      \| ▓▓___\▓▓  \ |  \ |  \|      \ /      \ 
| ▓▓    ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\\▓▓    \| ▓▓ | ▓▓ | ▓▓ \▓▓▓▓▓▓\  ▓▓▓▓▓▓\
| ▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓    ▓▓_\▓▓▓▓▓▓\ ▓▓ | ▓▓ | ▓▓/      ▓▓ ▓▓  | ▓▓
| ▓▓  | ▓▓ ▓▓__/ ▓▓ ▓▓▓▓▓▓▓▓  \__| ▓▓ ▓▓_/ ▓▓_/ ▓▓  ▓▓▓▓▓▓▓ ▓▓__/ ▓▓
| ▓▓  | ▓▓ ▓▓    ▓▓\▓▓     \\▓▓    ▓▓\▓▓   ▓▓   ▓▓\▓▓    ▓▓ ▓▓    ▓▓
 \▓▓   \▓▓ ▓▓▓▓▓▓▓  \▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓\▓▓▓▓  \▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓ 
         | ▓▓                                             | ▓▓      
         | ▓▓                                             | ▓▓      
          \▓▓                                              \▓▓         
 * App:             https://ApeSwap.finance
 * Medium:          https://ape-swap.medium.com
 * Twitter:         https://twitter.com/ape_swap
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * Discord:         https://ApeSwap.click/discord
 * Reddit:          https://reddit.com/r/ApeSwap
 * Instagram:       https://instagram.com/ApeSwap.finance
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "@ape.swap/contracts/contracts/v0.8/access/PendingOwnable.sol";
import "./interfaces/IFactoryStorage.sol";
import "./interfaces/ICustomBill.sol";

contract FactoryStorage is IFactoryStorage, PendingOwnable {
    /* ======== STATE VARIABLES ======== */
    BillDetails[] public billDetails;

    address public billFactory;

    mapping(address => uint256) public indexOfBill;

    /* ======== EVENTS ======== */

    event BillCreation(address treasury, address bill, address nftAddress);
    event FactoryChanged(address newFactory);

    /* ======== OWNER FUNCTIONS ======== */

    /**
        @notice pushes bill details to array
        @param _billCreationDetails ICustomBill.BillCreationDetails
        @param _customBill address
        @param _billNFT address
        @return _treasury address
        @return _bill address
     */
    function pushBill(
        ICustomBill.BillCreationDetails memory _billCreationDetails,
        address _customTreasury,
        address _customBill,
        address _billNFT
    ) external override returns (address _treasury, address _bill) {
        require(billFactory == msg.sender, "Not Factory");

        indexOfBill[_customBill] = billDetails.length;

        billDetails.push(BillDetails({
            payoutToken: _billCreationDetails.payoutToken,
            principalToken: _billCreationDetails.principalToken,
            treasuryAddress: _customTreasury,
            billAddress: _customBill,
            billNft: _billNFT,
            tierCeilings: _billCreationDetails.tierCeilings,
            fees: _billCreationDetails.fees
    }));

        emit BillCreation(_customTreasury, _customBill, _billNFT);
        return (_customTreasury, _customBill);
    }

    /**
        @notice returns total bills
     */
    function totalBills() public view override returns(uint) {
        return  billDetails.length;
    }

    /**
     * @notice get BillDetails at index
     * @param _index Index of BillDetails to look up
     */
    function getBillDetails(uint256 _index) external view override returns (BillDetails memory) {
        require(_index < totalBills(), "index out of bounds");
        return billDetails[_index];
    }

    function billFees(uint256 _billId) external view returns (uint256[] memory, uint256[] memory) {
        BillDetails memory bill = billDetails[_billId];
        uint256 length = bill.tierCeilings.length;
        uint256[] memory _tierCeilings = new uint[](length);
        uint256[] memory _fees = new uint[](length);
        for (uint256 i = 0; i < length; i++) {
            _tierCeilings[i] = bill.tierCeilings[i];
            _fees[i] = bill.fees[i];
        }
        return (_tierCeilings, _fees);
    }

    /**
        @notice changes factory address
        @param _factory address
     */
    function setFactoryAddress(address _factory) external onlyOwner {
        billFactory = _factory;
        emit FactoryChanged(billFactory);
    }
}