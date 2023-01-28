// SPDX-License-Identifier: MIT
/*
                            .__  .__                
_______   ___________  ____ |  | |  |   ___________ 
\_  __ \_/ __ \_  __ \/  _ \|  | |  | _/ __ \_  __ \
 |  | \/\  ___/|  | \(  <_> )  |_|  |_\  ___/|  | \/
 |__|    \___  >__|   \____/|____/____/\___  >__|   
             \/                            \/           
*/
pragma solidity ^0.8.9;
import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ISqueakersNFT {
    function setTokenURI(uint256 tokenId, string memory uri) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract Reroller is Ownable{

    ISqueakersNFT squeakersNFT;
    address public backendAddress;

    event SqueakerRerolled(address indexed _ownerAddress, uint256 indexed _tokenId, string _uri);

    constructor(address _squeakersNFTAddress, address _backendAddress) {
        squeakersNFT = ISqueakersNFT(_squeakersNFTAddress);
        backendAddress = _backendAddress;
    }

    function setSigner(address _backendAddress) public onlyOwner {
        require(msg.sender == backendAddress, "Only backend can set signer");
        backendAddress = _backendAddress;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setSqueakersNFT(address _squeakersNFTAddress) public onlyOwner {
        squeakersNFT = ISqueakersNFT(_squeakersNFTAddress);
    }

    function rerollSqueaker(uint256 _tokenId, string memory _uri, bytes memory _signature, bytes32 _hashTest, bytes32 _hashSign) public {
        require(squeakersNFT.ownerOf(_tokenId) == msg.sender, "You are not the owner of this token");

        //hash the uri
        bytes32 uriHash = keccak256(abi.encodePacked(_uri, _tokenId));

        //check if the hash is the same as the one sent by the backend
        require(uriHash == _hashTest, "The hash is not valid");

        address signer = getSigner(_hashSign, _signature);
        require(signer == backendAddress, "The signature is not valid");

        squeakersNFT.setTokenURI(_tokenId, _uri);

        emit SqueakerRerolled(msg.sender, _tokenId, _uri);
    }

    //use ecrecover to get the address of the signer
    function getSigner(bytes32 _hash, bytes memory _signature) public pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        //Check the signature length
        if (_signature.length != 65) {
            return (address(0));
        }
        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solhint-disable-next-line avoid-low-level-calls
            return ecrecover(_hash, v, r, s);
        }
    }

}