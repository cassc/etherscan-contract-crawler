// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "closedsea/src/OperatorFilterer.sol";

contract DogTag is ERC1155, ERC2981, Ownable, OperatorFilterer {
    event Minted(address indexed receiver, uint256 tokenId, uint256 quantity);

    mapping(address => bool) public allowedMinters;
    using Strings for uint256;

    bool public operatorFilteringEnabled;
    string public baseURI = "https://d3lv6x67zfy1o4.cloudfront.net/dogtag/json/";

    constructor() ERC1155("") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        allowedMinters[msg.sender] = true;
        _setDefaultRoyalty(msg.sender, 750);
    }

    // =========================================================================
    //                              Token Logic
    // =========================================================================
    function mint(address to, uint256 tokenId, uint256 amount, bytes memory data) public {
        require(allowedMinters[msg.sender], "DogTag: only allowed minter can mint tokens");
        _mint(to, tokenId, amount, data);
        emit Minted(to, tokenId, amount);
    }

    function burn(address from, uint256 id, uint256 amount) external {
        _burn(from, id, amount);
    }

    function setAllowedMinter(address newAllowedMinter, bool status) public onlyOwner {
        allowedMinters[newAllowedMinter] = status;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) {
            revert("Ether transfer failed");
        }
    }

    // =========================================================================
    //                              Metadata
    // =========================================================================
    function setBaseURI(string calldata _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, _id.toString()));
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseURI, "contractURI"));
    }

    // =========================================================================
    //                           Operator filter
    // =========================================================================

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
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

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    // =========================================================================
    //                                 ERC2891
    // =========================================================================

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // =========================================================================
    //                                  ERC165
    // =========================================================================

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return ERC1155.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}