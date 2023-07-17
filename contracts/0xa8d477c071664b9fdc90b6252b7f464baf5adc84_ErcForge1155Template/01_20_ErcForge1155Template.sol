/*
 /$$$$$$$$                     /$$$$$$$$                                          /$$          
| $$_____/                    | $$_____/                                         |__/          
| $$        /$$$$$$   /$$$$$$$| $$     /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$      /$$  /$$$$$$ 
| $$$$$    /$$__  $$ /$$_____/| $$$$$ /$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$    | $$ /$$__  $$
| $$__/   | $$  \__/| $$      | $$__/| $$  \ $$| $$  \__/| $$  \ $$| $$$$$$$$    | $$| $$  \ $$
| $$      | $$      | $$      | $$   | $$  | $$| $$      | $$  | $$| $$_____/    | $$| $$  | $$
| $$$$$$$$| $$      |  $$$$$$$| $$   |  $$$$$$/| $$      |  $$$$$$$|  $$$$$$$ /$$| $$|  $$$$$$/
|________/|__/       \_______/|__/    \______/ |__/       \____  $$ \_______/|__/|__/ \______/ 
                                                          /$$  \ $$                            
                                                         |  $$$$$$/                            
                                                          \______/                             
*/
//SPDX-License-Identifier: CC-BY-NC-ND
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "./ErcForgeNftCore.sol";
import "../interface/IErcForgeERC1155Mintable.sol";
import "../interface/IErcForgeInitiable.sol";

contract ErcForge1155Template is
    ERC1155Burnable,
    ERC1155Pausable,
    ErcForgeNftCore,
    IErcForgeERC1155Mintable,
    IErcForgeInitiable
{
    string public name;
    string public symbol;
    string public contractURI;

    mapping(uint256 => uint256) private _tokenSupply;
    mapping(uint256 => uint256) private _tokenPrice;

    constructor() ERC1155("") {}

    function init(
        address newOwner,
        string memory newName,
        string memory newSymbol,
        string memory newBaseTokenURI,
        string memory newContractURI,
        address royaltyReceiver,
        uint96 royaltyFee
    ) public {
        _init(newOwner, royaltyReceiver, royaltyFee);
        name = newName;
        symbol = newSymbol;
        contractURI = newContractURI;
        _setURI(newBaseTokenURI);
    }

    function setUri(string memory newUri) public onlyAdmin {
        _setURI(newUri);
    }

    function setContractURI(string memory newUri) public onlyAdmin {
        contractURI = newUri;
    }

    function setTokenPriceAndSupply(
        uint256[] memory ids,
        uint256[] memory prices,
        uint256[] memory supply
    ) public onlyAdmin {
        for (uint256 i = 0; i < ids.length; i++) {
            _tokenPrice[ids[i]] = prices[i];
            _tokenSupply[ids[i]] = supply[i];
        }
    }

    function getTokenPricesAndSupply(
        uint256[] memory ids
    ) public view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory supply = new uint256[](ids.length);
        uint256[] memory prices = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            prices[i] = _tokenPrice[ids[i]];
            supply[i] = _tokenSupply[ids[i]];
        }
        return (prices, supply);
    }

    function mint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external payable {
        uint256 value = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            if (_tokenSupply[ids[i]] < amounts[i]) {
                revert NoSupply();
            }
            if (amounts[i] == 0) {
                revert AmountShouldNotBeZero();
            }
            value += (_tokenPrice[ids[i]] * amounts[i]);
        }
        if (msg.value < value) {
            revert NotEnoughFunds();
        }

        for (uint256 i = 0; i < ids.length; i++) {
            _tokenSupply[ids[i]] -= amounts[i];
        }

        _mintBatch(to, ids, amounts, data);
    }

    function airdrop(
        address[] calldata to,
        uint256[] calldata id,
        uint256[] calldata amount
    ) external onlyAdmin {
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], id[i], amount[i], "");
        }
    }

    /**
     * @dev Pauses all token transfers.
     */
    function pause() public onlyAdmin {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     */
    function unpause() public onlyAdmin {
        _unpause();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

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

    /**
     * @dev OperatorFilter
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
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
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}