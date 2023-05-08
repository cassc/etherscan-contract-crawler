// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";

contract SidGiftCardVoucher is Ownable {
    uint256 public constant THREE_DIGIT_VOUCHER = 0;
    uint256 public constant FOUR_DIGIT_VOUCHER = 1;
    uint256 public constant FIVE_DIGIT_VOUCHER = 2;

    uint256 public constant THREE_DIGIT_VOUCHER_VALUE = 650 * (10**18);
    uint256 public constant FOUR_DIGIT_VOUCHER_VALUE = 160 * (10**18);
    uint256 public constant FIVE_DIGIT_VOUCHER_VALUE = 5 * (10**18);

    mapping(uint256 => uint256) public voucherValues;

    constructor() {
        voucherValues[THREE_DIGIT_VOUCHER] = THREE_DIGIT_VOUCHER_VALUE;
        voucherValues[FOUR_DIGIT_VOUCHER] = FOUR_DIGIT_VOUCHER_VALUE;
        voucherValues[FIVE_DIGIT_VOUCHER] = FIVE_DIGIT_VOUCHER_VALUE;
    }

    function addCustomizedVoucher(uint256 tokenId, uint256 price) external onlyOwner {
        require(voucherValues[tokenId] == 0, "voucher already exsits");
        voucherValues[tokenId] = price;
    }
    
    function totalValue(uint256[] calldata ids, uint256[] calldata amounts) external view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            total += voucherValues[ids[i]] * amounts[i];
        }
        return total;
    }

    function isValidVoucherIds(uint256[] calldata id) external view returns (bool) {
        for (uint256 i = 0; i < id.length; i++) {
            if (voucherValues[id[i]] == 0) {
                return false;
            }
        }
        return true;
    }
}