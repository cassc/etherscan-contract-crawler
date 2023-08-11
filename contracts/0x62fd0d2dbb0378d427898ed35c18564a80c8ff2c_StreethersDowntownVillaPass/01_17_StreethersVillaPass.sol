// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * ██╗░░░██╗██╗██╗░░░░░██╗░░░░░░█████╗░  ██████╗░░█████╗░░██████╗░██████╗
 * ██║░░░██║██║██║░░░░░██║░░░░░██╔══██╗  ██╔══██╗██╔══██╗██╔════╝██╔════╝
 * ╚██╗░██╔╝██║██║░░░░░██║░░░░░███████║  ██████╔╝███████║╚█████╗░╚█████╗░
 * ░╚████╔╝░██║██║░░░░░██║░░░░░██╔══██║  ██╔═══╝░██╔══██║░╚═══██╗░╚═══██╗
 * ░░╚██╔╝░░██║███████╗███████╗██║░░██║  ██║░░░░░██║░░██║██████╔╝██████╔╝
 * ░░░╚═╝░░░╚═╝╚══════╝╚══════╝╚═╝░░╚═╝  ╚═╝░░░░░╚═╝░░╚═╝╚═════╝░╚═════╝░
 */

/**
 * Streethers Downtown Villa Pass ERC 1155 Smart Contract
 */

contract StreethersDowntownVillaPass is ERC1155, ERC1155Supply, Ownable {
    address private streethersNftAddr =
        0x2b8d14bf74741d33E814978816E7c36B9802E568;
    address private streethTokenAddr =
        0xB840d10D840eF47c233FEC1fd040F5B145a6DfA5;

    bool public isClaimActive = false;
    string public _name = "STREETHERS Downtown Villa Pass";
    string public _symbol = "VILLAPASS";
    string private _contractURI;
    string private newBaseURI;

    mapping(uint256 => string) private _tokenURIs;
    mapping(address => bool) public claimedAddress;

    constructor() ERC1155("") {}

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory newContractURI) public onlyOwner {
        _contractURI = newContractURI;
    }

    function claimPass() public {
        require(isClaimActive, "Claim must be active");
        require(!claimedAddress[msg.sender], "Already claimed");

        ERC721 streethers = ERC721(streethersNftAddr);
        IERC20 streeth = IERC20(streethTokenAddr);

        uint256 nftBalance = streethers.balanceOf(msg.sender);
        require(nftBalance > 0, "Not Streether Holder!");

        uint256 tokenBalance = streeth.balanceOf(msg.sender);

        if (tokenBalance > 30000 ether) _mint(msg.sender, 1, nftBalance, "");
        else _mint(msg.sender, 0, nftBalance, "");

        claimedAddress[msg.sender] = true;
    }

    function flipClaimState() public onlyOwner {
        isClaimActive = !isClaimActive;
    }

    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(exists(id), "Nonexistent token");
        return _tokenURIs[id];
    }

    function _setTokenURI(uint256 _tokenId, string memory _tokenUri)
        external
        onlyOwner
    {
        _tokenURIs[_tokenId] = _tokenUri;
    }
}