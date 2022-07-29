// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/security/Pausable.sol";

import "./MerkleProof.sol";
import "./ERC1155D.sol";
import "./Fields.sol";
import "./Treasury.sol";

abstract contract Base is Fields, Pausable, Treasury, ERC1155 {
    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() public onlyAdmin {
        super._pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() public onlyAdmin {
        super._unpause();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(Treasury, ERC1155)
        returns (bool)
    {
        return
            ERC1155.supportsInterface(interfaceId) ||
            Treasury.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        if (paused()) revert PASSTransferPaused();
    }

    function ownerOfERC721Like(uint256 id) external view returns (address) {
        if (id > MAX_SUPPLY) revert IdNotValid();
        address owner_ = _owners[id].addr;
        if (owner_ == address(0)) revert IdNotValid();
        return owner_;
    }

    function getERC721BalanceOffChain(address _address)
        public
        view
        returns (uint256)
    {
        uint256 counter = 0;
        for (uint256 i; i < _owners.length; i++) {
            if (_owners[i].addr == _address) {
                counter++;
            }
        }
        return counter;
    }

    function getERC721OffChainTokensOf(address _address)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerBalance = getERC721BalanceOffChain(_address);
        uint256[] memory result = new uint256[](ownerBalance);
        uint256 counter = 0;
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (_owners[i].addr == _address) {
                result[counter] = i;
                unchecked {
                    counter++;
                }
            }
        }
        return result;
    }
}