// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Keisuke OHNO

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



pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


interface INFTCollection {
    function ownerOf(uint256 tokenId_) external view returns (address);
    function safeTransferFrom(address from,address to,uint256 tokenId) external payable;
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}



contract NFTLockerCore is Ownable{
    address public developerAddress = 0xdEcf4B112d4120B6998e5020a6B4819E490F7db6;
    address public TARGET_CONTRACT_ADDRESS;
    bytes32 internal constant ADMIN = keccak256("ADMIN");
    mapping(uint256 => address) public SBTTokenIdByholder;
    mapping(uint256 => uint256) public SBTTokenIdByTokenId;
    uint256 public sbtNextIndex = 0;
    bool public isSBT = true;

    INFTCollection NFTCollection;

    event StartLock(address indexed holder,
        uint256 indexed sbtTokenId,uint256 indexed originalTokenId, uint256 startTime);
    event EndLock(address indexed holder,
        uint256 indexed sbtTokenId,uint256 indexed originalTokenId, uint256 endTime);
}

abstract contract NFTLockeradmin is NFTLockerCore,AccessControl,ERC721Holder,ERC721Enumerable{
    function supportsInterface(bytes4 interfaceId) public view virtual 
        override(AccessControl,ERC721Enumerable) returns (bool) {
        return
        interfaceId == type(IAccessControl).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    // modifier
    modifier onlyAdmin() {
        require(hasRole(ADMIN, msg.sender), "You are not authorized.");
        _;
    }

    // onlyOwner
    function setAdminRole(address[] memory admins) external onlyOwner{
        for (uint256 i = 0; i < admins.length; i++) {
            _grantRole(ADMIN, admins[i]);
        }
    }

    function revokeAdminRole(address[] memory admins) external onlyOwner{
        for (uint256 i = 0; i < admins.length; i++) {
            _revokeRole(ADMIN, admins[i]);
        }
    }

    // function setCollection(address _address) external onlyAdmin{
    //     NFTCollection = INFTCollection(_address);
    // }

    function setIsSBT(bool _state) external onlyAdmin {
       isSBT = _state;
    }

    function setDeveloperAddress(address _address) external onlyAdmin {
       developerAddress = _address;
    }

    function donationWithdraw() external onlyAdmin {
        (bool os, ) = payable(developerAddress).call{value: address(this).balance}("");
        require(os);
    }
}

contract NFTLocker is NFTLockeradmin{
    // constructor() ERC721("NFT Locker" , "NFTL"){
    // }
    constructor() ERC721("TereQN Locker" , "TQNL"){
        TARGET_CONTRACT_ADDRESS = 0xc44cD2685D21fc78766c6168909abdB6CcE040fD;
        NFTCollection = INFTCollection(TARGET_CONTRACT_ADDRESS);

        _setRoleAdmin(ADMIN, ADMIN);
        _setupRole(ADMIN, msg.sender);  // set owner as admin
    }

    // ==========================================================================
    // Locker session
    // ==========================================================================
    // external
    //function deposit(address _contractAddress , uint256 _tokenId )external{
    function deposit(uint256 _originalTokenId)external{
        require(NFTCollection.ownerOf(_originalTokenId) == msg.sender, "You are not the owner of NFT.");

        // deposit
        NFTCollection.safeTransferFrom(msg.sender, address(this) , _originalTokenId);

        // receipt
        sbtNextIndex++;
        SBTTokenIdByTokenId[sbtNextIndex] = _originalTokenId;
        SBTTokenIdByholder[sbtNextIndex] = msg.sender;
        _safeMint(msg.sender, sbtNextIndex );
        emit StartLock(msg.sender,sbtNextIndex,_originalTokenId,block.timestamp);
    }

    function withdraw(uint256 _sbtTokenId )external payable{
        require(ownerOf(_sbtTokenId) == msg.sender, "You are not the owner of NFT(SBT)." );
        uint256 _originalTokenId = SBTTokenIdByTokenId[_sbtTokenId];

        // withdraw
        NFTCollection.safeTransferFrom(address(this),msg.sender,_originalTokenId);
        SBTTokenIdByholder[_sbtTokenId] = address(0);
        _burn(_sbtTokenId);
        emit EndLock(msg.sender,_sbtTokenId,_originalTokenId,block.timestamp);
    }

    // ==========================================================================
    // view session
    // ==========================================================================
    function thisaddress()external view returns(address){
        return address(this);
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalToken = sbtNextIndex;
            uint256 resultIndex = 0;

            for(uint256 tokenId = 1; tokenId <= totalToken; tokenId++) {
                if(SBTTokenIdByholder[tokenId] == _owner){
                    result[resultIndex] = tokenId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function tokensOfOwnerOriginalNFT(address _owner) external view returns(uint256[] memory ownerTokens) {
        return NFTCollection.tokensOfOwner(_owner);
    }


    // override
    function tokenURI(uint256 _sbtTokenId) public view override returns (string memory) {
        return NFTCollection.tokenURI(SBTTokenIdByTokenId[_sbtTokenId]);
    }

    // ==========================================================================
    // sbt session
    // ==========================================================================
    function _beforeTokenTransfer( address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override{
        require( isSBT == false || from == address(0) || to == address(0), "transfer is prohibited");
        super._beforeTokenTransfer(from, to, startTokenId, quantity);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(IERC721,ERC721) {
        require( isSBT == false , "setApprovalForAll is prohibited");
        super.setApprovalForAll(operator, approved);
    }

    function approve(address to, uint256 tokenId) public virtual override(IERC721,ERC721) {
        require( isSBT == false , "approve is prohibited");
        super.approve(to, tokenId);
    }
}