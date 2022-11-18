// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IWorldCupMemoryNFT{
    function tokenIdAtTeam(uint256) external view returns(uint256);
    function winnerTeam() external view returns(uint256);
    function ownerOf(uint256) external view returns (address);
    function publicSaleOpen() external view returns(bool);
    function teamTotalSupply(uint256) external view returns (uint256);
}


contract RepuchasePool is Ownable{

    address public worldCupMemoryNFT ;
    bool public startRepurchase = false;
    uint256 public repurchasedAmount ;
    event Received(address, uint);

    modifier activityEnded(){
        require(IWorldCupMemoryNFT(worldCupMemoryNFT).publicSaleOpen() == false, "the activity is on");
        _;
    }
    
    function setNFTContractAddress( address _nftAddress) public onlyOwner{
        worldCupMemoryNFT = _nftAddress;
    }

    function getTeamIdByTokenId(uint256 _tokenId) public view returns(uint256){
        return IWorldCupMemoryNFT(worldCupMemoryNFT).tokenIdAtTeam(_tokenId);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function getContractBalance() public view returns(uint256){
        return address(this).balance;
    }

    function ownerWithdraw() public onlyOwner{
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

     function toggleRePurchase() external onlyOwner {
        startRepurchase = !startRepurchase;
    }
      
      function onERC721Received( address operator, address from, uint256 tokenId, bytes calldata data ) public  returns (bytes4) {
            return this.onERC721Received.selector;
    }

    function repurchase( uint256 _tokenId) public activityEnded{
       require(msg.sender == IWorldCupMemoryNFT(worldCupMemoryNFT).ownerOf(_tokenId),"not owner of NFT");
       require(IWorldCupMemoryNFT(worldCupMemoryNFT).tokenIdAtTeam(_tokenId) == IWorldCupMemoryNFT(worldCupMemoryNFT).winnerTeam(), "Not Winner Team");
       uint256 totalWinner =  IWorldCupMemoryNFT(worldCupMemoryNFT).teamTotalSupply(  IWorldCupMemoryNFT(worldCupMemoryNFT).winnerTeam() ) - repurchasedAmount ;
       IERC721(worldCupMemoryNFT).safeTransferFrom(msg.sender, address(this), _tokenId);
       uint256 divideAmount = address(this).balance /  totalWinner;
       repurchasedAmount = repurchasedAmount + 1;
       (bool sent, ) = msg.sender.call{value: divideAmount}("");
       require(sent, "send failed");
    }

}