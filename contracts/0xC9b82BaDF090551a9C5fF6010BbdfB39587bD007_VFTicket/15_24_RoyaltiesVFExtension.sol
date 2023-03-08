// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IRoyaltiesVF} from "../../royalties/IRoyaltiesVF.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

abstract contract RoyaltiesVFExtension is Context, IERC165, IERC2981 {
    //Contract for function access control
    IRoyaltiesVF private _royaltiesContract;

    constructor(address royaltiesContractAddress) {
        _royaltiesContract = IRoyaltiesVF(royaltiesContractAddress);
    }

    /**
     * @dev Get royalty information for a token based on the `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return
            _royaltiesContract.royaltyInfo(tokenId, address(this), salePrice);
    }

    /**
     * @dev Update the royalties contract
     *
     * Requirements:
     *
     * - the caller must be an admin role
     * - `royaltiesContractAddress` must support the IRoyaltiesVF interface
     */
    function _setRoyaltiesContract(address royaltiesContractAddress) internal {
        require(
            IERC165(royaltiesContractAddress).supportsInterface(
                type(IRoyaltiesVF).interfaceId
            ),
            "Contract does not support required interface"
        );
        _royaltiesContract = IRoyaltiesVF(royaltiesContractAddress);
    }
}