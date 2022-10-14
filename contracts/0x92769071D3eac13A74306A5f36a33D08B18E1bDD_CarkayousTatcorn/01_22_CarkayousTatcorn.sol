// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../LushLinkCronosUnlimitedDrop.sol";

contract CarkayousTatcorn is LushLinkCronosUnlimitedDrop {

    mapping(uint => string) private overrideIds;


    ///////////////////////////
    // Constructor
    //////////////////////////

    constructor(address _ownerAddress) LushLinkCronosUnlimitedDrop(
        "Carkayous Tatcorn",
        "TATCORN",
        "https://www.lushlink.io/collection/VHB4VFMxV29BTk5YTzV2dWI3c0QwZz09/nft",
        _ownerAddress
    ){
        setMemberCost(0 ether);
        setRegularCost(0 ether);
        setDefaultRoyalty(0x02E7da2Fb19469EC942321CcF40A2AC54bf69057, 750);
    }


    ///////////////////////////
    // Metadata
    //////////////////////////

    function setTokenUri(uint _token, string memory _uri) external {
        require(_exists(_token), "nonexistent token");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        overrideIds[_token] = _uri;
    }

    function deleteTokenUri(uint _token) external {
        require(_exists(_token), "nonexistent token");
        require(bytes(overrideIds[_token]).length == 0, "already empty");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        delete overrideIds[_token];
    }

    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        if(bytes(overrideIds[_tokenId]).length > 0){
            return overrideIds[_tokenId];
        } else {
            return super.tokenURI(_tokenId);
        }
    }
}