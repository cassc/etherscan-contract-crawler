// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../interface/IFractonTokenFactory.sol';
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ENS {
    function reclaim(uint256 id, address owner) external;

}

contract ENS3 is ERC721 {
    address public constant ENS_CONTRACT =
        0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85;
    address public constant FRACTON_FACTORY = 0x3Aec3113a09627Af7C9039954D8592fF0bC20c25;
    address public rent_market;
    string public constant ENS_BASE_URI =
        "https://metadata.ens.domains/mainnet/0x57f1887a8bf19b14fc0df6fd9b2acc9af147ea85/";

    event SafeWrap(address from, string ENSName, uint256 tokenId);

    event SafeUnwrap(
        address from,
        address to,
        string ENSName,
        uint256 tokenId
    );

    constructor() ERC721("Wrapped 3-Digit ENS", "ENS3") {}
    //temp
    function ENSNametoId(string memory ENSName) public pure returns (uint256) {
        bytes memory buffer = bytes(ENSName);
        require(buffer.length == 3, "not 3 digit number");
        for(uint8 i=0; i<3; i++){
            uint8 numberbybytes = uint8(buffer[i]) - 48;
            require(0 <= numberbybytes && numberbybytes < 10, "not 3 digit number");
        }
        return uint256(keccak256(abi.encodePacked(ENSName)));
    }

    function setRentMarket(address newrentmarket) external {
        address dao = IFractonTokenFactory(FRACTON_FACTORY).getDAOAddress();
        require(msg.sender == dao, 'only DAO');
        rent_market = newrentmarket;
    }

    function safeWrap(string memory ENSName) external {
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

    function safeUnwrap(string memory ENSName) external {
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