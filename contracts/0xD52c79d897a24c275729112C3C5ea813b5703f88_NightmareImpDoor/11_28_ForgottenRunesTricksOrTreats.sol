// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../util/Ownablearama.sol";
import "./IForgottenRunesTricksOrTreats.sol";

abstract contract ForgottenRunesTricksOrTreats is
    ERC1155Supply,
    IForgottenRunesTricksOrTreats,
    Ownablearama
{
    mapping(uint256 => string) public tokenURIs;

    string public baseURI;

    //minters mapping
    mapping(address => bool) public minters;

    modifier onlyMinterOrOwner() {
        require(
            minters[msg.sender] || msg.sender == owner(),
            "ForgottenRunesTreats: only minter or owner can call this function"
        );
        _;
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyMinterOrOwner {
        _mint(to, id, amount, data);
    }

    // lets us override per token in case we need to
    function setTokenURI(uint256 _tokenId, string calldata _tokenURI)
        external
        onlyOwner
    {
        tokenURIs[_tokenId] = _tokenURI;
    }

    function setIsMinter(address _minter, bool _isMinter) external onlyOwner {
        minters[_minter] = _isMinter;
    }

    function setURI(string memory _uri) external onlyOwner {
        super._setURI(_uri);
    }

    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory tokenURI = tokenURIs[tokenId];

        return
            bytes(tokenURI).length > 0
                ? tokenURI
                : string(
                    abi.encodePacked(
                        super.uri(tokenId),
                        Strings.toString(tokenId)
                    )
                );
    }
}