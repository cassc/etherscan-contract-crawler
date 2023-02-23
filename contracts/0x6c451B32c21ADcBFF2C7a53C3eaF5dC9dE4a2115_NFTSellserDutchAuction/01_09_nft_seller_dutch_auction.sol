// SPDX-License-Identifier: MIT
// Copyright (c) 2023 Keisuke OHNO (kei31.eth)

/*

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


//NFT interface
interface iNFTCollection {
    function balanceOf(address _owner) external view returns (uint);
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom( address from, address to, uint256 tokenId) external ;
}

contract NFTSellserDutchAuction is Ownable , AccessControl{

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole( ADMIN             , msg.sender);

    }
    bytes32 public constant ADMIN = keccak256("ADMIN");


    //
    //withdraw section
    //

    address public withdrawAddress = 0xdEcf4B112d4120B6998e5020a6B4819E490F7db6;

    function setWithdrawAddress(address _withdrawAddress) public onlyOwner {
        withdrawAddress = _withdrawAddress;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }


    //
    //buy section
    //

    bool public paused = true;
    address public sellerWalletAddress = 0xdEcf4B112d4120B6998e5020a6B4819E490F7db6;

    //https://eth-converter.com/

    iNFTCollection public NFTCollection;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    function buy(uint256 _tokenId  ) public payable callerIsUser{
        require( !paused, "the contract is paused" );
        require( auctionPhase == 2 , "Not Auction Now" );
        require( getCost() <= msg.value, "insufficient funds" );
        require( NFTCollection.ownerOf(_tokenId) == sellerWalletAddress , "NFT out of stock" );

        NFTCollection.safeTransferFrom( sellerWalletAddress , msg.sender , _tokenId );
    }

    function setPause(bool _state) public onlyRole(ADMIN) {
        paused = _state;
    }

    function setSellserWalletAddress(address _sellerWalletAddress) public onlyRole(ADMIN)  {
        sellerWalletAddress = _sellerWalletAddress;
    }

    function setNFTCollection(address _address) public onlyRole(ADMIN) {
        NFTCollection = iNFTCollection(_address);
    }

    function nftOwnerOf(uint256 _tokenId)public view returns(address){
        return NFTCollection.ownerOf(_tokenId);
    }

    function NFTinStock(uint256 _tokenId)public view returns(bool){
        if( NFTCollection.ownerOf(_tokenId) == sellerWalletAddress ){
            return true;
        }else{
            return false;
        }
    }

    function setSalesData(
        address _sellerWalletAddress,
        address _collectionAddress,
        address _withdrawAddress,
        uint256 _costStart,
        uint256 _costEnd,
        uint256 _auctionDuration
        )public onlyRole(ADMIN){

        setSellserWalletAddress(_sellerWalletAddress);
        setNFTCollection(_collectionAddress);
        setWithdrawAddress(_withdrawAddress);
        setCostStart(_costStart);
        setCostEnd(_costEnd);
        setAuctionDuration(_auctionDuration);
        
    }



    //1: Before the auction starts, standby
    //2: In auction
    //3: Auction pause

    uint256 public auctionPhase = 1;
    uint256 public timeStart;
    uint256 public timeEnd;
    uint256 public costStart = 5000000000000000000;
    uint256 public costEnd = 100000000000000000;
    uint256 public auctionDuration = 3600;
    uint256 internal timeRemaining;
    uint256 internal costSlot;



    function setCostStart(uint256 _costStart) public onlyRole(ADMIN) {
        costStart = _costStart;
    }

    function setCostEnd(uint256 _costEnd) public onlyRole(ADMIN) {
        costEnd = _costEnd;
    }

    function setAuctionDuration(uint256 _auctionDuration) public onlyRole(ADMIN) {
        auctionDuration = _auctionDuration;
    }

    function auctionStart() public onlyRole(ADMIN) {

        //phase check and write
        require( auctionPhase == 1 , "Auction Phase is not standby" );
        auctionPhase = 2;//change to In auction

        require( costEnd < costStart , "Cost Error");
        require( paused == true , "Pause Error");

        timeStart = block.timestamp;
        timeEnd = timeStart + auctionDuration;

        setPause(false);
    }

    function auctionRestart() public onlyRole(ADMIN) {

        //phase check and write
        require( auctionPhase == 3 , "Auction Phase is not pause" );
        auctionPhase = 2;//change to In auction

        timeEnd = block.timestamp + timeRemaining;
        timeStart = timeEnd - auctionDuration;

    }

    function auctionPause() public onlyRole(ADMIN) {

        //phase check and write
        require( auctionPhase == 2 , "Auction Phase is in auction" );
        auctionPhase = 3;//change to pause

        if( block.timestamp < timeEnd){
            timeRemaining = timeEnd - block.timestamp;
        }else{
            timeRemaining = 0;
        }

        costSlot = getCost();
    }

    function auctionReset() public onlyRole(ADMIN) {

        //phase check and write
        require( auctionPhase == 3 , "Auction Phase is not pause" );
        auctionPhase = 1;//change to standby

    }
    
    function getCost() public view returns(uint256){
        uint256 _cost = costStart;

        if( auctionPhase == 1){
            _cost = costStart;

        }else if( auctionPhase == 2 ){
            if(block.timestamp <= timeStart ){
                _cost = costStart;
            }else if( timeStart < block.timestamp && block.timestamp <= timeEnd){
                _cost = costEnd + ( ( costStart - costEnd ) * ( timeEnd - block.timestamp ) ) / auctionDuration;
            }else{
                _cost = costEnd;
            }

        }else if( auctionPhase == 3){
            _cost = costSlot;

        }else{
            _cost = costStart;
        }

        return _cost;
    }


    function timeLeft() public view returns(uint256){

        uint256 _timeLeft = 0;

        if( auctionPhase == 1){//before auction , standby
            _timeLeft = auctionDuration;

        }else if( auctionPhase == 2 ){//in auction
            if(block.timestamp <= timeStart ){
                _timeLeft = auctionDuration;
            }else if( timeStart < block.timestamp && block.timestamp <= timeEnd){
                _timeLeft = timeEnd - block.timestamp;
            }else{
                _timeLeft = 0;
            }

        }else if( auctionPhase == 3){//pause
            _timeLeft = timeRemaining;

        }else{
            _timeLeft = auctionDuration;
        }

        return _timeLeft;        
    }


}