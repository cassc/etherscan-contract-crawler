//SPDX-License-Identifier: MIT


import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "./interfaces/IENSToken.sol";
import "./interfaces/IManager.sol";
import "./interfaces/IMetadata.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

pragma solidity ^0.8.13;

contract MetadataProviderV1 is IMetadata {

    using Strings for uint256;

    IManager public Manager;
    ENS private ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e); 
    IENSToken public ensToken = IENSToken(0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85);
    string public DefaultImage = 'ipfs://QmYWSU93qnqDvAwHGEpJbEEghGa7w7RbsYo9mYYroQnr1D'; //QmaTFCsJ9jsPEQq9zgJt9F38TJ5Ys3KwVML3mN1sZLZbxE

    constructor(IManager _manager){
        Manager = _manager;
    }

   function tokenURI(uint256 tokenId) public view returns(string memory){
        
        string memory label = Manager.IdToLabelMap(tokenId);

        uint256 ownerId = Manager.IdToOwnerId(tokenId);
        string memory parentName = Manager.IdToDomain(ownerId);
        string memory ensName = string(abi.encodePacked(label, ".", parentName, ".eth"));
        string memory locked = (ensToken.ownerOf(ownerId) == address(Manager)) && (Manager.TokenLocked(ownerId)) ? "True" : "False";
        string memory image = Manager.IdImageMap(ownerId);

        bytes32 hashed = Manager.IdToHashMap(tokenId);
        string memory avatar = Manager.text(hashed, "avatar");
        address resolver = ens.resolver(hashed);
        string memory active = resolver == address(Manager) ? "True" : "False";

        uint256 expiry = ensToken.nameExpires(ownerId);
        
        return string(  
            abi.encodePacked(
                'data:application/json;utf8,{"name": "'
                , ensName
                , '","description": "Transferable '
                , parentName
                , '.eth sub-domain","image":"'
                , bytes(avatar).length == 0 ? 
                    (bytes(image).length == 0 ? DefaultImage : image)
                    : avatar
                , '","attributes":[{"trait_type" : "parent name", "value" : "'
                , parentName
                , '.eth"},{"trait_type" : "parent locked", "value" : "'
                , locked
                , '"},{"trait_type" : "active", "value" : "'
                , active
                , '" },{"trait_type" : "parent expiry", "display_type": "date","value": ', expiry.toString(), '}]}'
                        )
                            );               
    }


}