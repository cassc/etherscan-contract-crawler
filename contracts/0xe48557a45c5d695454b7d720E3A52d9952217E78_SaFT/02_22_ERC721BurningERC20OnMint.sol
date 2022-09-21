//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./IErc721BurningErc20OnMint.sol";
import "./ERC721Checkpointable.sol";

abstract contract ERC721BurningERC20OnMint is
    ERC721Checkpointable,
    IErc721BurningErc20OnMint,
    Ownable
{
    address public erc20TokenAddress;

    function setErc20TokenAddress(address erc20TokenAddress_)
        public
        override
        onlyOwner
    {
        erc20TokenAddress = erc20TokenAddress_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(IErc721BurningErc20OnMint).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     *   @dev this method hooks into ERC721's internal transfers mechanism (mint, burn, transfer) - see
     https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#ERC721-_beforeTokenTransfer-address-address-uint256-
     * - When from and to are both non-zero, from's amount will be transferred to to.
     * - When from is zero, amount will be minted for to.
     * - When to is zero, from's amount will be burned.
     *   from and to are never both zero.
     *   This function checks that the "to" address has at least a balance of 1, in order for them to qualify for
     *   minting an NFT, and if they do, we burn one token
     *   the above logic only applies to minting, other transfer operations are ignored
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        ERC721Checkpointable._beforeTokenTransfer(from, to, amount);
        //check if it's a mint
        if (from == address(0) && to != address(0)) {
            require(
                erc20TokenAddress != address(0),
                "erc20TokenAddress undefined"
            );
            uint256 balanceOfAddress = IERC20(erc20TokenAddress).balanceOf(to);
            require(balanceOfAddress >= 1, "user does not hold a token");
            ERC20Burnable(erc20TokenAddress).burnFrom(to, 1);
        }
    }
}