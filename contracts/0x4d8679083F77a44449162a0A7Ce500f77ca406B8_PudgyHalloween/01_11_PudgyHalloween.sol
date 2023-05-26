// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PudgyPenguinsInterface.sol";

contract PudgyHalloween is ERC1155, Ownable {

    PudgyPenguinsInterface public pudgyPenguins;

    uint256 public startEvent = 1635364800;
    uint256 public endEvent = 1636081200;

    mapping (uint256 => bool) private _pudgyPenguinsUsed;
    mapping (uint256 => uint256) private _pudgyHalloweenIds;

    uint256 private RANDOM_SEED = 5718512354;

    constructor(string memory _baseURI) ERC1155(_baseURI) {
        setURI(_baseURI);
    }

    function MintPudgyHalloween(uint256[] memory _tokenIds) public {

        require(block.timestamp >= startEvent, "Event not started");
        require(block.timestamp <= endEvent, "Event ended");

        address wallet = _msgSender();

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256  _tokenId = _tokenIds[i];
            require(pudgyPenguins.ownerOf(_tokenId) == wallet, "Bad owner!");
            require(canClaim(_tokenId), "Already Claimed!");

            _pudgyPenguinsUsed[_tokenId] = true;

            uint256 id = getRandomPudgyHalloween(_tokenId);

            _pudgyHalloweenIds[_tokenId] = id;

            _mint(wallet, id, 1, "");
        }

    }

    function getRandomPudgyHalloween(uint256 _tokenIds) private view returns(uint256){
        uint256 bigNumber = uint(keccak256(abi.encodePacked(block.timestamp, _tokenIds, RANDOM_SEED))) % 100;
        if(bigNumber <= 10) return 1;
        if(bigNumber <= 30) return 2;
        return 3;
    }

    function getPudgyHalloweenId(uint256 _token) public view returns(uint256){
        return _pudgyHalloweenIds[_token];
    }

    function getClaimed(address wallet) public view returns(uint256[] memory) {

        uint256[] memory tokens = pudgyPenguins.walletOfOwner(wallet);
        uint256[] memory claimed = new uint256[](tokens.length);

        for(uint256 i = 0; i < tokens.length; i++){
            if(!canClaim(tokens[i])){
                claimed[i] = tokens[i];
            }else{
                claimed[i] = 99999;
            }
        }

        return claimed;
    }
    function canClaim(uint256 _tokenId) public view returns(bool) {
        return _pudgyPenguinsUsed[_tokenId] == false;
    }

    function customOwnerAirdrop(address[] memory _wallets, uint256 _id, uint256 _count) public onlyOwner{
        for(uint256 i = 0; i < _wallets.length; i++){
            _mint(_wallets[i], _id, _count, "");
        }
    }

    function setURI(string memory _baseURI) public onlyOwner {
        _setURI(_baseURI);
    }

    function setPudgyPenguins(address _pudgyPenguins) public onlyOwner {
        pudgyPenguins = PudgyPenguinsInterface(_pudgyPenguins);
    }
    function setStartEvent(uint256 _start) public onlyOwner {
        startEvent = _start;
    }
    function setEndEvent(uint256 _end) public onlyOwner {
        endEvent = _end;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = address(this).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

}