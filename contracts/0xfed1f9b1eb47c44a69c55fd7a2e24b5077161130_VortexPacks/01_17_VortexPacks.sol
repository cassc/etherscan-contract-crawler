// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "closedsea/src/OperatorFilterer.sol";
import "./helpers/VortexRoles.sol";

//  __      __        _              _____           _
//  \ \    / /       | |            |  __ \         | |
//   \ \  / /__  _ __| |_ _____  __ | |__) |_ _  ___| | _____
//    \ \/ / _ \| '__| __/ _ \ \/ / |  ___/ _` |/ __| |/ / __|
//     \  / (_) | |  | ||  __/>  <  | |  | (_| | (__|   <\__ \
//      \/ \___/|_|   \__\___/_/\_\ |_|   \__,_|\___|_|\_\___/

contract VortexPacks is
    VortexRoles,
    ERC1155Burnable,
    ERC1155Pausable,
    OperatorFilterer,
    ERC2981
{
    error IncorrectRoleError();

    uint256 public constant MODERATOR = 1;
    uint256 public constant MINTER = 2;

    string public name;
    string public symbol;
    bool public operatorFilteringEnabled;

    constructor(string memory uri_, address[] memory _moderators)
        ERC1155(uri_)
    {
        name = "Vortex Packs";
        symbol = "VPX";

        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        for (uint256 i = 0; i < _moderators.length; i++) {
            _grantRole(MODERATOR, _moderators[i]);
        }

        _setDefaultRoyalty(msg.sender, 500);
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                      Modifiers                                      #
    // #                                                                                     #
    // #######################################################################################

    modifier onlyModerator() {
        if (!hasRole(MODERATOR, _msgSender())) revert IncorrectRoleError();
        _;
    }

    modifier onlyMinter() {
        if (!hasRole(MINTER, _msgSender())) revert IncorrectRoleError();
        _;
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                     Moderators                                      #
    // #                                                                                     #
    // #######################################################################################

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyModerator
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyModerator {
        operatorFilteringEnabled = value;
    }

    function setURI(string memory _uri) external onlyModerator {
        _setURI(_uri);
    }

    function pause() public virtual onlyModerator {
        _pause();
    }

    function unpause() public virtual onlyModerator {
        _unpause();
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                      Minting                                        #
    // #                                                                                     #
    // #######################################################################################

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual onlyMinter {
        _mint(to, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual onlyMinter {
        _mintBatch(to, ids, amounts, data);
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                  OperatorFilterer                                   #
    // #                                                                                     #
    // #######################################################################################

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator)
        internal
        pure
        override
        returns (bool)
    {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                       ERC1155                                       #
    // #                                                                                     #
    // #######################################################################################

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                       ERC165                                        #
    // #                                                                                     #
    // #######################################################################################

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
}