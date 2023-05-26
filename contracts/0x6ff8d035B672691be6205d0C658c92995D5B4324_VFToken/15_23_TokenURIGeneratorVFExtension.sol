// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ITokenURIGeneratorVF} from "../../urigenerator/ITokenURIGeneratorVF.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

abstract contract TokenURIGeneratorVFExtension is Context, IERC165 {
    //Contract for function access control
    ITokenURIGeneratorVF private _tokenURIGeneratorContract;

    constructor(address tokenURIGeneratorContractAddress) {
        if (tokenURIGeneratorContractAddress != address(0)) {
            _tokenURIGeneratorContract = ITokenURIGeneratorVF(
                tokenURIGeneratorContractAddress
            );
        }
    }

    function renderingContractTokenURI(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return _tokenURIGeneratorContract.tokenURI(tokenId);
    }

    function getRenderingContract() public view returns (address) {
        return address(_tokenURIGeneratorContract);
    }

    /**
     * @dev Update the royalties contract
     *
     * Requirements:
     *
     * - the caller must be an admin role
     * - `tokenURIGeneratorContractAddress` must support the IRoyaltiesVF interface
     */
    function _setRenderingContract(address tokenURIGeneratorContractAddress)
        internal
    {
        require(
            IERC165(tokenURIGeneratorContractAddress).supportsInterface(
                type(ITokenURIGeneratorVF).interfaceId
            ),
            "Contract does not support required interface"
        );
        _tokenURIGeneratorContract = ITokenURIGeneratorVF(
            tokenURIGeneratorContractAddress
        );
    }
}