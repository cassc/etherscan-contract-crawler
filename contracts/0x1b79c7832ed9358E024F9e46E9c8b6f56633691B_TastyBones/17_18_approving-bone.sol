// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract ApprovingBone is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    string public baseURI;
    uint256 public maxBones = 450;
    bool public boneMintActive = true;

    mapping (address => bool) public earlyAccessAddresses;
    mapping(address => uint256) addressBlockBought;

    address public creator;

    constructor(address owner) ERC721("Approving Bone", "ACBONE")  {
        transferOwnership(owner);
        // setBaseURI for metadata
        setBaseURI('https://bone-api.approvingcorgis.com/api/token/');
        creator = msg.sender;
    }

    /**
     * mint Bones
     */
    function mintBone() public {
        uint256 supply = totalSupply();

        require(addressBlockBought[msg.sender] < block.timestamp, "Not allowed to Mint on the same Block");
        require(!Address.isContract(msg.sender),"Contracts are not allowed to mint");
        require(boneMintActive, "Minting Approving Bone Is Not Yet Active");
        require(isAddressReserved(msg.sender), "You need to be whitelisted");
        require(supply <= maxBones, "Exceeds maximum Corgis supply" );

        addressBlockBought[msg.sender] = block.timestamp;
        _safeMint( msg.sender, supply + 1 );

        delete earlyAccessAddresses[msg.sender];
    }

    /**
     * mint Bones
     */
    function mintSpecialBones(uint256 _numberOfTokens) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply <= maxBones, "Exceeds maximum Bones supply" );

        for(uint256 i; i < _numberOfTokens; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    /**
     * Returns Bones of the Caller
     */
    function bonesOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function isAddressReserved(address _ogAddress) internal view returns(bool) {
        return earlyAccessAddresses[_ogAddress];
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function toggleBoneMintActive() public onlyOwner {
        boneMintActive = !boneMintActive;
    }

    function changeMaxBones(uint256 _maxBones) public onlyOwner {
        maxBones = _maxBones;
    }

    function addReservationAddress(address _ogAddress) public onlyOwner {
        earlyAccessAddresses[_ogAddress] = true;
    }

    function addMultipleAddresses(address[] memory _ogAddress) public onlyOwner {
        for (uint256 i = 0; i < _ogAddress.length; i++) {
            earlyAccessAddresses[_ogAddress[i]] = true;
        }
    }
}