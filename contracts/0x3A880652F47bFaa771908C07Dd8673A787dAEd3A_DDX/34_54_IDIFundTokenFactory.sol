// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { DIFundToken } from "../DIFundToken.sol";

/**
 * @title DIFundToken
 * @author DerivaDEX (Borrowed/inspired from Compound)
 * @notice This is the token contract for tokenized DerivaDEX insurance
 *         fund positions. It implements the ERC-20 standard, with
 *         additional functionality around snapshotting user and global
 *         balances.
 * @dev The contract makes use of some nonstandard types not seen in
 *      the ERC-20 standard. The DIFundToken makes frequent use of the
 *      uint96 data type, as opposed to the more standard uint256 type.
 *      Given the maintenance of arrays of balances and allowances, this
 *      allows us to more efficiently pack data together, thereby
 *      resulting in cheaper transactions.
 */
interface IDIFundTokenFactory {
    function createNewDIFundToken(
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals
    ) external returns (address);

    function diFundTokens(uint256 index) external returns (DIFundToken);

    function issuer() external view returns (address);

    function getDIFundTokens() external view returns (DIFundToken[] memory);

    function getDIFundTokensLength() external view returns (uint256);
}