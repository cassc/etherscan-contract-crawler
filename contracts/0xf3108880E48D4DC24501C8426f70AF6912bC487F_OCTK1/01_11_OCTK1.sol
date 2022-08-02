// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-0.8/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts-0.8/utils/Strings.sol";
import "@openzeppelin/contracts-0.8/access/Ownable.sol";

/**
 * @title OCTK1 is an ERC1155 Token deployed by Octofan.
 * @dev OCTK1
 * Based on;
 * https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155
 */
contract OCTK1 is ERC1155, Ownable {

    string private _baseUri;
    string[] private _links;
    uint256[] private _amounts;

    /**
     * @dev Constructor that gives owner all of existing tokens.
     */
    constructor(uint256 initialAmount, uint256[] memory punderations, string memory baseUri, string[] memory links) ERC1155("") Ownable() {
        require(links.length == punderations.length, string(abi.encodePacked("Links length and punderations length should be equals to : ", Strings.toString(links.length))));
        _baseUri = baseUri;
        _links = links;
        for (uint256 i = 0; i < _links.length; i++) {
            _amounts.push(punderations[i] * initialAmount);
            _mint(_msgSender(), i+1, _amounts[i], "");
        }
    }

    /// @notice The name of the collection in this contract.
    /// @return The name of the tokens.
    function name() external pure returns (string memory) {
        return "Octofan OCTK1 sales";
    }

    /// @notice The abbreviated name of the collection in this contract.
    /// @return The symbol of the tokens.
    function symbol() external pure returns (string memory) {
        return "OCTK1";
    }

    /// @notice The initial number of for each token id.
    /// @return The initial numbers.
    function amounts() external view returns (uint256[] memory) {
        return _amounts;
    }

    /// @notice The initial number of for a token id.
    /// @return The initial number.
    function amount(uint256 id) external view returns (uint256) {
        _check(id);
        return _amounts[id-1];
    }

    /// @notice Set the base uri.
    function setBaseUri(string calldata baseUri) public onlyOwner {
        _baseUri = baseUri;
    }

    /// @notice The baseUri.
    /// @return The base uri.
    function getBaseUri() public view returns(string memory){
        return _baseUri;
    }

    function _check(uint256 id) internal view{
        require(id >= 1 && id <= _links.length, string(abi.encodePacked("Non existant token: ", Strings.toString(id))));
    }

    /// @notice Set link for a token id.
    function setLink(uint256 id, string calldata link) public onlyOwner {
        _check(id);
        _links[id-1] = link;
    }

    /// @notice The link for a token id.
    /// @return The link.
    function getLink(uint256 id) public view returns(string memory){
        _check(id);
        return _links[id-1];
    }

    /// @notice Set all links.
    function setLinks(string[] calldata links) public onlyOwner {
        require(links.length == _links.length, string(abi.encodePacked("Links length should be equals to : ", Strings.toString(_links.length))));
        for (uint256 i = 0; i < links.length; i++) {
            _links[i] = links[i];
        }
    }

    /// @notice All links for token ids.
    /// @return The initial number.
    function getLinks() public view returns(string[] memory){
        return _links;
    }

    /// @notice The uri for a token id.
    /// @return The uri.
    function uri(uint256 id) public view override returns (string memory) {
        _check(id);
        return string(abi.encodePacked(_baseUri, _links[id-1]));
    }
}