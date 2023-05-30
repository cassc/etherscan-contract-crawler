// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {OperatorFilterer} from "./OperatorFilterer.sol";

contract Suits is ERC1155Burnable, OperatorFilterer, ERC2981, Ownable {
    using Address for address;
    using Strings for uint256;

    string public _baseURI = "ipfs://bafybeifmmcn23zbasfneenl57qdxbtyww6clomr5aihpzqikczhwbssr6a/";
    string public _contractURI =
        "https://bafkreichz2nd24gyfsuq2a7ho3nzzprofiuvhxjlvvqna2n5qlsydrlmwm.ipfs.nftstorage.link/";
    bool public operatorFilteringEnabled = true;
    mapping(address => bool) public isBurnerContract;

    string public name = "Moth Valley - Season 1";
    string public symbol = "MVS1";

    constructor() ERC1155(_baseURI) {
        _registerForOperatorFiltering();
        _setDefaultRoyalty(0x90cBfc638B991fb240C687Cab76806439D2730D0, 1000);
        operatorFilteringEnabled = true;
    }

    //airdrop ...
    function airdrop(
        address[] memory recipients,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external onlyOwner{
       
        require(
            recipients.length == tokenIds.length &&
                tokenIds.length == amounts.length,
            "recipient, tokenId, and amount array lengths must match"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], tokenIds[i], amounts[i], "");
        }
    }

    function burnXBatch(
        address from,
        uint256[] memory tokenIDs,
        uint256[] memory amounts
    ) external {
        require(isBurnerContract[_msgSender()], "only burner contract");
        _burnBatch(from, tokenIDs, amounts);
    }

    /*///////////////////////////////////////////////////////////////
                    CONTRACT MANAGEMENT OPERATIONS
    //////////////////////////////////////////////////////////////*/
    function setBaseURI(string memory newuri) public onlyOwner {
        _baseURI = newuri;
    }

    function setContractURI(string memory newuri) public onlyOwner {
        _contractURI = newuri;
    }

    function setBurnerContract(
        address burner,
        bool isBurner
    ) external onlyOwner {
        isBurnerContract[burner] = isBurner;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function reclaimERC20(IERC20 erc20Token) public onlyOwner {
        erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
    }

    function reclaimERC721(IERC721 erc721Token, uint256 id) public onlyOwner {
        erc721Token.safeTransferFrom(address(this), msg.sender, id);
    }

    function reclaimERC1155(
        IERC1155 erc1155Token,
        uint256 id,
        uint256 amount
    ) public onlyOwner {
        erc1155Token.safeTransferFrom(
            address(this),
            msg.sender,
            id,
            amount,
            ""
        );
    }

    /*///////////////////////////////////////////////////////////////
                             OTHER THINGS
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseURI, tokenId.toString(), ".json"));
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return
            ERC1155.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

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
    ) public override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(
        address operator
    ) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    function version1() internal {}
}