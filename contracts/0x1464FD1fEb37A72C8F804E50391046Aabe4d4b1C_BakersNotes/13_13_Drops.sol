// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "lib/openzeppelin-contracts/contracts/token/common/ERC2981.sol";


contract BakersNotes is ERC1155, ERC1155Supply, ERC2981, Ownable {
    constructor(string memory _uri, address royaltyReceiver) ERC1155(_uri) {
        _setDefaultRoyalty(royaltyReceiver, 500);
        _setURI(_uri);
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return
            ERC1155.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /// @dev set the URI to your base URI here, don't forget the {id} param.
    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    /**
     * @notice Airdrop a token to multiple addresses at once.
     * No strict supply is set in the contract. All methods are ownerOnly,
     * it is up to the owner to control the supply by not minting
     * past their desired number for each token.
     * @dev Airdrop one token to each address in the calldata list,
     * setting the supply to the length of the list + previously minted (airdropped) supply. Add an addess once per
     * token you would like to send.
     * @param _token The tokenID to send
     * @param _list address[] list of wallets to send 1 token to, each.
     */
    function airdrop(uint256 _token, address[] calldata _list)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _list.length; i++) {
            _mint(_list[i], _token, 1, "");
        }
    }

    /**
     * @notice Sends multiple tokens to a single address
     * @param _tokenID The address to receive the tokens
     * @param _address The address to receive the tokens
     * @param _quantity How many to send she receiver
     */
    function batchMint(
        uint256 _tokenID,
        address _address,
        uint256 _quantity
    ) external onlyOwner {
        _mint(_address, _tokenID, _quantity, "");
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

        function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

}