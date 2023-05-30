// SPDX-License-Identifier: MIT
// author: Giovanni Vignone
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Muttniks is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private MuttnikID;
    uint256 private maxsupply;
    address private contract_creator;
    mapping(uint256 => string) private _tokenURIs;
    address private MuttnikVerify;

    constructor(address verificationaccount) ERC721("Muttniks", "Laika") {
        contract_creator = msg.sender;
        maxsupply = 9999;
        MuttnikVerify = verificationaccount;
    }
    
    function _getAllMetadata() public view returns (string[] memory){
        string[] memory ret = new string[](MuttnikID.current());
        for(uint i = 0; i<MuttnikID.current();i++){
            ret[i] = _tokenURIs[i];
        }
        return ret;
    }

    function _changeVerification(address verificationaddress) onlyOwner public{
        MuttnikVerify = verificationaddress;
    }

    function _withdraw(uint256 amountinwei, bool getall, address payable exportaddress) onlyOwner public returns (bool){
        if(getall == true){
            exportaddress.transfer(address(this).balance);
            return true;
        }
        require(amountinwei<address(this).balance,"Contract is not worth that much yet");
        exportaddress.transfer(amountinwei);
        return true;
    }

   function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }




    function verificationfunc(bytes32 specialhash, bytes memory sig)
       public pure returns (address)
    {
        (bytes32 ready, bytes32 steady, uint8 vroom) = separatesig(sig);
        return ecrecover(specialhash, vroom, ready, steady);
    }
    function separatesig(bytes memory sig)
        public pure returns (bytes32 ready, bytes32 steady, uint8 vroom)
    {
        require(sig.length == 65, "sig not right size");
        assembly {
            ready := mload(add(sig, 32))
            steady := mload(add(sig, 64))
            vroom := byte(0, mload(add(sig, 96)))
        }
    }


    function createMuttnik(string memory pinatalink, address customerwallet, bytes32 specialhash, bytes memory sig)
        public payable
        returns (uint256)
    {
        require(MuttnikVerify == verificationfunc(specialhash, sig));
        require(msg.value >= 60000000000000000);
        require(MuttnikID.current() <= maxsupply, "Muttniks are sold out!");
        require(msg.sender != address(0) && msg.sender != address(this));
        uint256 uniquetokenID = MuttnikID.current();
        _safeMint(contract_creator, uniquetokenID);
        _safeTransfer(contract_creator, customerwallet, uniquetokenID,"");
        _setTokenURI(uniquetokenID, pinatalink);
        MuttnikID.increment();
        return uniquetokenID;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "TokenURI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    function nextmuttnik() public view returns (uint256) {
        return MuttnikID.current();
    }
}