//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";

contract LandNFT is
    ERC1155PresetMinterPauser
{
    using Strings for uint256;
    string public name;
    string public symbol;

    string public _uriBase;

    mapping(string => uint) public nftTypeIDs;

    uint public numberOfType;

    constructor(string memory _uri) ERC1155PresetMinterPauser(_uri) {
        _uriBase = _uri;
        numberOfType = 0;
        name = "LANDSNFT";
        symbol = "LANDSNFT";
    }

    function setBaseUri(string memory _base)
        external
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "LandNFT: Caller is not admin");
        _uriBase = _base;
    }

    function addType(string memory _typeName)
        external
    {
        require(hasRole(MINTER_ROLE, _msgSender()) ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender())
                , "LandNFT: not minter");

        if(nftTypeIDs[_typeName] == 0) {
            numberOfType = numberOfType + 1;
            nftTypeIDs[_typeName] = numberOfType;
        }
    }

    function getNftTypeID(string memory _typeName)
        external
        view
        returns(uint)
    {
        return nftTypeIDs[_typeName];
    }

    // Update for nft metadata.
    function uri(uint256 tokenId)
        override
        public
        view
        returns (string memory)
    {
        return string(abi.encodePacked(_uriBase, Strings.toString(tokenId)));
    }
}