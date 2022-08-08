// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../interface/IFractonTokenFactory.sol';
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ENS {
    function reclaim(uint256 id, address owner) external;

}

contract ENS4 is ERC721 {
    address public constant ENS_CONTRACT =
        0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85;
    address public constant FRACTON_FACTORY = 0x3Aec3113a09627Af7C9039954D8592fF0bC20c25;
    address public rent_market;
    string public constant ENS_BASE_URI =
        "https://metadata.ens.domains/mainnet/0x57f1887a8bf19b14fc0df6fd9b2acc9af147ea85/";

    event SafeWrap(address from, uint256 ENSName, uint256 tokenId);

    event SafeUnwrap(
        address from,
        address to,
        uint256 ENSName,
        uint256 tokenId
    );

    constructor() ERC721("Wrapped 4-Digit ENS", "ENS4") {}

    //fork from Openzepplin String.sol
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function ENSNametoId(uint256 ENSNameDigit) public pure returns (uint256) {
        require(
            999 < ENSNameDigit && ENSNameDigit < 10000,
            "not 4-digit number"
        );
        string memory name_string = toString(ENSNameDigit);
        return uint256(keccak256(abi.encodePacked(name_string)));
    }
    //set rent market when onboard, and assign rent market as ens controller
    function setRentMarket(address newrentmarket) external {
        address dao = IFractonTokenFactory(FRACTON_FACTORY).getDAOAddress();
        require(msg.sender == dao, 'only DAO');
        rent_market = newrentmarket;
    }

    function safeWrap(uint256 ENSName) external {
        uint256 tokenId = ENSNametoId(ENSName);

        IERC721(ENS_CONTRACT).transferFrom(_msgSender(),address(this),tokenId);
        //reclaim controller to Fracton DAO for resolving names if rent market not onboard
        if(rent_market != address(0)){
            ENS(ENS_CONTRACT).reclaim(tokenId, rent_market);
        }
        else{
            address dao = IFractonTokenFactory(FRACTON_FACTORY).getDAOAddress();
            ENS(ENS_CONTRACT).reclaim(tokenId, dao);
        }       
        _safeMint(_msgSender(), tokenId);
        emit SafeWrap(_msgSender(), ENSName, tokenId);
    }

    function safeUnwrap(uint256 ENSName) external {
        uint256 tokenId = ENSNametoId(ENSName);
        address owner = ownerOf(tokenId);

        require(_isApprovedOrOwner(_msgSender(), tokenId),"ERC721: transfer caller is not owner nor approved");

        _burn(tokenId);

        IERC721(ENS_CONTRACT).safeTransferFrom(address(this),_msgSender(),tokenId);

        emit SafeUnwrap(owner, _msgSender(), ENSName, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        pure
        override
        returns (string memory)
    {
        return
            string(abi.encodePacked(ENS_BASE_URI, Strings.toString(tokenId)));
    }
}