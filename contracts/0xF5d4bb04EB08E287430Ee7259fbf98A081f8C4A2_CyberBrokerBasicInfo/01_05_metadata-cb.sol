// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.14;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICyberBrokers.sol";
import "./ICyberBrokersMetadata.sol";

contract CyberBrokerBasicInfo is Ownable{

    address public cyberbrokers = 0x892848074ddeA461A15f337250Da3ce55580CA85;

    struct CyberBrokerBasicMeta {
        string talent;
        string gender;
        string background;
        string species;
        string class;
        string description;
    }

    constructor() {
    }

    function contains (string memory what, string memory source) internal pure returns(bool) {
        bytes memory whatBytes = bytes (what);
        bytes memory sourceBytes = bytes (source);

        require(sourceBytes.length >= whatBytes.length);

        bool found = false;
        for (uint i = 0; i <= sourceBytes.length - whatBytes.length; i++) {
            bool flag = true;
            for (uint j = 0; j < whatBytes.length; j++)
                if (sourceBytes [i + j] != whatBytes [j]) {
                    flag = false;
                    break;
                }
            if (flag) {
                found = true;
                break;
            }
        }
        return found;
    }

    function setCyberBrokersAddress(address addr) public onlyOwner {
        cyberbrokers = addr;
    }

    function getMetadataContract() public view returns(ICyberBrokersMetadata){
        address addr = ICyberBrokers(cyberbrokers).cyberBrokersMetadata();
        return ICyberBrokersMetadata(addr);
    }

    function getBasicMetadata(uint256 tokenId) public view returns (CyberBrokerBasicMeta memory metadata) {
        ICyberBrokersMetadata metadataContract = getMetadataContract();


        ///@dev Get the easiest info
        ICyberBrokersMetadata.CyberBrokerTalent memory talent = metadataContract.getTalent(tokenId);

        metadata.talent = talent.talent;
        metadata.species= talent.species;
        metadata.class= talent.class;
        metadata.description= talent.description;

        ///@dev get sex and background;
        uint256[] memory layerIds = metadataContract.getLayers(tokenId);
        uint256 backgroundLayerId = layerIds[0];
        uint256 genderLayerId = layerIds[1];

        ICyberBrokersMetadata.CyberBrokerLayer memory backgroundLayer = metadataContract.layerMap(backgroundLayerId);
        ICyberBrokersMetadata.CyberBrokerLayer memory genderLayer = metadataContract.layerMap(genderLayerId);

        metadata.background = backgroundLayer.key;


        if(contains("male-",genderLayer.key)){
            metadata.gender = "Male";
        }else if (contains("female-",genderLayer.key)){
            metadata.gender = "Female";
        }else{
            metadata.gender = "NA";
        }

        return metadata;
    }

}