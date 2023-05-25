// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.8.5;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Factory is Ownable { 

    using SafeMath for uint256;

    struct Asset {
        uint256 assetId;
    }

    Asset[] public assets;
    string internal baseTokenURI = 'https://immadegenbackend.herokuapp.com/';

    mapping (uint256 => address) public assetToOwner;
    mapping (address => uint256) ownerAssetCount;

    modifier onlyOwnerOf(uint _assetId) {
        require(msg.sender == assetToOwner[_assetId]);
        _;
    }
}