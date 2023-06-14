// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { SafeMath } from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import { LibBytes } from "../libs/LibBytes.sol";
import { LibEIP712 } from "../libs/LibEIP712.sol";
import { LibPermit } from "../libs/LibPermit.sol";
import { SafeMath96 } from "../libs/SafeMath96.sol";
import { DIFundToken } from "./DIFundToken.sol";

/**
 * @title DIFundTokenFactory
 * @author DerivaDEX (Borrowed/inspired from Compound)
 * @notice This is the native token contract for DerivaDEX. It
 *         implements the ERC-20 standard, with additional
 *         functionality to efficiently handle the governance aspect of
 *         the DerivaDEX ecosystem.
 * @dev The contract makes use of some nonstandard types not seen in
 *      the ERC-20 standard. The DDX token makes frequent use of the
 *      uint96 data type, as opposed to the more standard uint256 type.
 *      Given the maintenance of arrays of balances, allowances, and
 *      voting checkpoints, this allows us to more efficiently pack
 *      data together, thereby resulting in cheaper transactions.
 */
contract DIFundTokenFactory {
    DIFundToken[] public diFundTokens;

    address public issuer;

    /**
     * @notice Construct a new DDX token
     */
    constructor(address _issuer) public {
        // Set issuer to deploying address
        issuer = _issuer;
    }

    function createNewDIFundToken(
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals
    ) external returns (address) {
        require(msg.sender == issuer, "DIFTF: unauthorized.");
        DIFundToken diFundToken = new DIFundToken(_name, _symbol, _decimals, issuer);
        diFundTokens.push(diFundToken);
        return address(diFundToken);
    }

    function getDIFundTokens() external view returns (DIFundToken[] memory) {
        return diFundTokens;
    }

    function getDIFundTokensLength() external view returns (uint256) {
        return diFundTokens.length;
    }
}