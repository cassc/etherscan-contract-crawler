// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMetaverserItems.sol";
import "./interfaces/IRent.sol";
contract MarketHelper is Ownable {
    IMetaverserItems public itemsContract;
    IRent public rentContract;
    struct UsersTokens {
        address user;
        uint256 tokens;
    }
    struct RentTokens {
        address user;
        uint256 tokenId;
        uint256 supply;
    }
    constructor(IMetaverserItems _itemsContract,IRent _rentContract) {
        itemsContract = _itemsContract;
        rentContract = _rentContract;

    }
    //get function
    
    function getAllUserItems(uint256 _from,uint256 _end,uint256  _tokenId) public view returns(UsersTokens[] memory ) {
        uint256 userCount=itemsContract.usersCounter();
        if(_end >  userCount ) {
            _end = userCount ;
        }

        uint256 total = _end - _from  ;
        UsersTokens[] memory _data = new UsersTokens[](total);
        uint cnt=0;
        for(uint256 i=_from; i< _end ;i++) {
            address _owner= itemsContract.getHolderAddressByIndex(i);
            _data[cnt]=UsersTokens(_owner,itemsContract.balanceOf(_owner, _tokenId ));
            cnt++;
        }

        return _data;
    }

    function getAllUserRents(uint256 _from,uint256 _end ) public view returns(RentTokens[] memory ) {
        uint256 userCount=rentContract.usersCounter();
        uint256 tokenCount=itemsContract.getTokenCount();
        if(_end >  userCount ) {
            _end = userCount ;
        }

        uint256 total = (_end - _from) * tokenCount ;
        RentTokens[] memory _data = new RentTokens[](total);
        uint cnt=0;
        for(uint256 i=_from; i< _end ;i++) {
            address _owner= rentContract.getHolderAddressByIndex(i);
            for(uint index=0;index<tokenCount;index++){
                _data[cnt] = RentTokens(_owner,index+1, rentContract.getLesseeTokens(_owner)[index].supply );
                cnt++;
            }
        }

        return _data;
    }
    function transferBatch(address[] memory receivers,uint256 _tokenId,uint256 _amount) public {
        for(uint256 i=0;i<receivers.length;i++) {
            itemsContract.safeTransferFrom(msg.sender, receivers[i], _tokenId, _amount, '0x');
        }
    }
    


}