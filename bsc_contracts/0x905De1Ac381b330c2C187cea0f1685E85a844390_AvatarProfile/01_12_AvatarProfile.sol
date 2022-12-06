/***
* MIT License
* ===========
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
 __         __     ______   ______     ______   ______     ______     __    __    
/\ \       /\ \   /\  ___\ /\  ___\   /\  ___\ /\  __ \   /\  == \   /\ "-./  \   
\ \ \____  \ \ \  \ \  __\ \ \  __\   \ \  __\ \ \ \/\ \  \ \  __<   \ \ \-./\ \  
 \ \_____\  \ \_\  \ \_\    \ \_____\  \ \_\    \ \_____\  \ \_\ \_\  \ \_\ \ \_\ 
  \/_____/   \/_/   \/_/     \/_____/   \/_/     \/_____/   \/_/ /_/   \/_/  \/_/ 
                                                                                  
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract AvatarProfile is Ownable, ReentrancyGuard  {

    event NFT721Received(address operator, address from, uint256 tokenId, bytes data);
    event NFT1155Received(address operator, address from, uint256 tokenId, uint256 amount, bytes data);
    event eSetAvatar(
        address collect,
        uint256 erdType,
        uint256 tokenId,
        uint256 oldTokenId,
        address sender
    );

    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    // using Address for address;
    using SafeMath for uint256;

    struct AvatarSet{
        address collect;
        uint256 tokenId;
    }

    struct CollectionSet{
        address collect;
        uint256 ercType;
    }

    //for default url
    string public _defaultUrl;

    //for iams
    EnumerableSet.AddressSet private _IAMs;

    //for avatar collections
    EnumerableMap.AddressToUintMap private _collections;

    //for user avatar sets
    mapping(address => EnumerableMap.AddressToUintMap ) private _userAvatars;

    modifier onlyIAM() {
        require(_IAMs.contains(msg.sender), "must call by IAM");
        _;
    }

    constructor(address avatar721, string memory defaultUrl){
        _collections.set(avatar721,721);
        _defaultUrl = defaultUrl;

        addIAM(msg.sender);
    }

    function addIAM(address IAM) public onlyOwner {
        require( !_IAMs.contains(IAM), " iam already existed!" );
        _IAMs.add(IAM);
    }

    function removeIAM(address IAM) public onlyOwner {
        _IAMs.remove(IAM);
    }

    function setDefaultUrl(string memory defaultUrl) public onlyOwner {
        _defaultUrl = defaultUrl;
    }

    function addCollection(address collect, uint256 ercType ) public onlyIAM{
        _collections.set(collect,ercType);
    }

    function removeCollection(address collect) public onlyIAM {
        _collections.remove(collect);
    }

    function setAvatar( address collect, uint256 tokenId ) external  nonReentrant {
        
        require( _collections.contains(collect), "invalid collect!" );

        uint256 ercType = _collections.get(collect);
        
        bool have;
        uint256 oldTokenId;

        if(ercType == 721 ){
            IERC721 avatar = (IERC721)(collect);
            require( avatar.ownerOf(tokenId) == msg.sender, "invalid tokenId!");

            (have,oldTokenId) = _userAvatars[msg.sender].tryGet(collect);
            if(!have){
                avatar.safeTransferFrom(msg.sender, address(this), tokenId,"");
                oldTokenId = type(uint256).max;
            }
            else{
                avatar.safeTransferFrom( address(this), msg.sender, oldTokenId,"");
                avatar.safeTransferFrom( msg.sender, address(this), tokenId,"");
            }
            _userAvatars[msg.sender].set(collect,tokenId);
        }

        else  if(ercType == 1155 ){
            IERC1155 avatar = (IERC1155)(collect);
            require( avatar.balanceOf(msg.sender,tokenId) > 0, "invalid tokenId!");

            (have,oldTokenId) = _userAvatars[msg.sender].tryGet(collect);
            if(!have){
                avatar.safeTransferFrom(msg.sender, address(this), tokenId, 1, "");
                oldTokenId = type(uint256).max;
            }
            else{
                avatar.safeTransferFrom( address(this), msg.sender, oldTokenId, 1, "");
                avatar.safeTransferFrom( msg.sender, address(this), tokenId, 1, "");
            }
            _userAvatars[msg.sender].set(collect,tokenId);
        }
        else{
            require( false, "invalid erc type!" );
        }
       
        emit eSetAvatar(
                collect,
                ercType,
                tokenId,
                oldTokenId,
                msg.sender
            );  
    }

    function resetAvatar( address collect ) external nonReentrant {
        
        require( _collections.contains(collect), "invalid collect!" );
        
        uint256 ercType = _collections.get(collect);

        bool have;
        uint256 oldTokenId;

        (have,oldTokenId) = _userAvatars[msg.sender].tryGet(collect);
        require( have, "it hasn't set any avatars before !" );

        if(ercType == 721 ){
            _userAvatars[msg.sender].remove(collect);
            IERC721 avatar = (IERC721)(collect);
            avatar.safeTransferFrom( address(this), msg.sender, oldTokenId,"");
        }
        else if(ercType == 1155 ){
            _userAvatars[msg.sender].remove(collect);
            IERC1155 avatar = (IERC1155)(collect);
            avatar.safeTransferFrom( address(this), msg.sender, oldTokenId,1,"");
        }
        else{
            require( false, "invalid erc type!" );
        }
        
        emit eSetAvatar(
                collect,
                ercType,
                type(uint256).max,
                oldTokenId,
                msg.sender
            );  
    }

    function getAvatarSet(address owner) public view returns( AvatarSet[] memory) {

        uint256 length = _userAvatars[owner].length();
        AvatarSet[] memory avatars = new AvatarSet[](length);

        uint256 tokenId;
        address collect;
        for(uint32 i=0; i<length; i++){
            (collect,tokenId) = _userAvatars[owner].at(i);
            avatars[i].tokenId = tokenId;
            avatars[i].collect = collect;
        }
        return avatars;
    }

    function getAvatarId(address collect, address owner) public view returns( uint256 ) {

        require( _collections.contains(collect), "invalid collect!" );
        
        bool have;
        uint256 oldTokenId;
        (have,oldTokenId) = _userAvatars[owner].tryGet(collect);

        require( have, "it hasn't set any avatars before !" );
    
        return oldTokenId;
    }

    function getAvatarUrl(address collect, address owner) public view returns( string memory ) {

        require( _collections.contains(collect), "invalid collect!" );
    
        uint256 ercType = _collections.get(collect);
        bool have;
        uint256 oldTokenId;

        if(ercType == 721 ){
            (have,oldTokenId) = _userAvatars[owner].tryGet(collect);
            if(have){
                IERC721Metadata avatar = (IERC721Metadata)(collect);
                return avatar.tokenURI(oldTokenId);
            }
            else{
                return _defaultUrl;
            }
        }
        else if(ercType == 1155 ){
            (have,oldTokenId) = _userAvatars[owner].tryGet(collect);
            if(have){
                //* If the `\{id\}` substring is present in the URI, it must be replaced by
                //* clients with the actual token type ID.
                IERC1155MetadataURI avatar = (IERC1155MetadataURI)(collect);
                return avatar.uri(oldTokenId);
            }
            else{
                return _defaultUrl;
            }
        }
        else{
            return _defaultUrl;
        }

    }

    function getCollectSet() public view returns( CollectionSet[] memory) {

        uint256 length = _collections.length();
        CollectionSet[] memory collections = new CollectionSet[](length);

        uint256 ercType;
        address collect;
        for(uint32 i=0; i<length; i++){
            (collect,ercType) = _collections.at(i);
            collections[i].ercType = ercType;
            collections[i].collect = collect;
        }
        return collections;
    }

    function urgencyWithdrawErc721(address collect, address target, uint256[] calldata ids) external onlyOwner {
        for (uint256 i = 0; i < ids.length; ++i) {
            (IERC721)(collect).safeTransferFrom(address(this), target, ids[i],"");
        }
    }

    function urgencyWithdrawErc1155(address erc1155, address target, uint256[] calldata ids,  uint256[] calldata amounts) public onlyOwner {
        IERC1155(erc1155).safeBatchTransferFrom(address(this), target, ids,amounts,"");
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4) {
        //only receive the _nft staff
        if(address(this) != operator) {
            //invalid from nft
            return 0;
        }
        //success
        emit NFT721Received(operator, from, tokenId, data);
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function onERC1155Received(address operator, address from, uint256 tokenId, uint256 amount, bytes memory data) public returns (bytes4) {
        //only receive the _nft staff
        if(address(this) != operator) {
            //invalid from nft
            return 0;
        }
        //success
        emit NFT1155Received(operator, from, tokenId, amount, data);
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

}