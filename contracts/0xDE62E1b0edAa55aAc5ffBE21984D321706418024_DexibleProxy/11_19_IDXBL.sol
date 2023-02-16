//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IDXBL is IERC20, IERC20Metadata {
    struct FeeRequest {
        bool referred;
        address trader;
        uint amt;
        uint dxblBalance;
        uint16 stdBpsRate;
        uint16 minBpsRate;
    }

    function minter() external view returns (address);
    function discountPerTokenBps() external view returns(uint32);

    function mint(address acct, uint amt) external;
    function burn(address holder, uint amt) external;
    function setDiscountRate(uint32 discount) external;
    function setNewMinter(address minter) external;
    function computeDiscountedFee(FeeRequest calldata request) external view returns(uint);
}