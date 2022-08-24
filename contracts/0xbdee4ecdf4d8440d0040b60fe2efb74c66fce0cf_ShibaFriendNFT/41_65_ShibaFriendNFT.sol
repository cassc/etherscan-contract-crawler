//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ShibaFriendNFT is
    ERC1155PresetMinterPauser
{
    using Strings for uint256;
    string public name;
    string public symbol;

    string public _uriBase;

    uint[] public IdPrefixs;
    mapping(string => uint) public NFTGroupPrefixs;

    mapping(uint => uint) public NumberOfTypeNFT;

    uint public TotalType;

    constructor(string memory uri) ERC1155PresetMinterPauser(uri) {
        _uriBase = uri;
        name = "SHIBAFRIEND NFT";
        symbol = "SHIBANFT";
    }

    function setBaseUri(string memory baseUri)
        external
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ShibaFriendNFT: Caller is not admin");
        _uriBase = baseUri;
    }

    function addGroupNFT(string memory _groupNamePrefix, uint _numberOfType)
        external
    {
        require(hasRole(MINTER_ROLE, _msgSender()) ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender())
                , "ShibaFriendNFT: must have minter role to mint");

        require(_numberOfType > 0, "ShibaFriendNFT: Number of type not allow");

        if(NFTGroupPrefixs[_groupNamePrefix] == 0) {
            uint idPrefix = uint256(_stringToBytes32(_groupNamePrefix));
            NFTGroupPrefixs[_groupNamePrefix] = idPrefix;
            IdPrefixs.push(idPrefix);
        }
        else {
            TotalType = TotalType - NumberOfTypeNFT[NFTGroupPrefixs[_groupNamePrefix]];
        }
        NumberOfTypeNFT[NFTGroupPrefixs[_groupNamePrefix]] = _numberOfType;
        TotalType = TotalType + _numberOfType;
    }

    function getAllNFTID()
        external
        view
        returns(uint[] memory)
    {
        uint[] memory rs = new uint[](TotalType);
        uint idx = 0;

        for(uint i = 0; i < IdPrefixs.length; i++) {
            for(uint j = 0; j < NumberOfTypeNFT[IdPrefixs[i]]; j++) {
                rs[idx] = IdPrefixs[i] + j;
                idx = idx + 1;
            }
        }
        return rs;
    }

    function _stringToBytes32(string memory source)
        internal
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(source, 32))
        }
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