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
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


//NFT interface
interface iNFTCollection {
    function balanceOf(address _owner) external view returns (uint);
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom( address from, address to, uint256 tokenId) external ;
}

contract NFTSellser is Ownable , AccessControl{

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole( ADMIN             , msg.sender);

        setMerkleRoot(0xb459efcce43c854e36a6669b7cb680bcda35bebf11a0f3663f7722cb968dace3);
        setSellserWalletAddress(0xa6EEdDCd3a1a3cAD0d0192ac50630AfB2e75a112);
        setNFTCollection(0x597D757f8502F1fe8E7dD6fc7FE884A51C5Ae2b9);
    }
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant MINTER_ROLE  = keccak256("MINTER_ROLE");


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
    bytes32 public merkleRoot;
    uint256 public cost = 390000000000000000;
    address public sellerWalletAddress = 0xdEcf4B112d4120B6998e5020a6B4819E490F7db6;

    //https://eth-converter.com/

    iNFTCollection public NFTCollection;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    function buy(uint256 _tokenId , bytes32[] calldata _merkleProof ) public payable callerIsUser{
        require(!paused, "the contract is paused");
        require(cost  <= msg.value, "insufficient funds");
        require(NFTCollection.ownerOf(_tokenId) == sellerWalletAddress , "NFT out of stock");
        bytes32 leaf = keccak256( abi.encodePacked(msg.sender, _tokenId) );
        require(MerkleProof.verifyCalldata(_merkleProof, merkleRoot, leaf), "user is not allowlisted");

        NFTCollection.safeTransferFrom( sellerWalletAddress , msg.sender , _tokenId );
    }

    function buyPie(uint256 _tokenId , bytes32[] calldata _merkleProof , address receiver) public payable callerIsUser onlyRole(MINTER_ROLE){
        require(!paused, "the contract is paused");
        require(cost  <= msg.value, "insufficient funds");
        require(NFTCollection.ownerOf(_tokenId) == sellerWalletAddress , "NFT out of stock");
        bytes32 leaf = keccak256( abi.encodePacked(receiver, _tokenId) );
        require(MerkleProof.verifyCalldata(_merkleProof, merkleRoot, leaf), "user is not allowlisted");

        NFTCollection.safeTransferFrom( sellerWalletAddress , receiver , _tokenId );
    }




    function setPause(bool _state) public onlyRole(ADMIN) {
        paused = _state;
    }

    function setCost(uint256 _newCost) public onlyRole(ADMIN) {
        cost = _newCost;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyRole(ADMIN) {
        merkleRoot = _merkleRoot;
    }    

    function setSellserWalletAddress(address _sellerWalletAddress) public onlyRole(ADMIN)  {
        sellerWalletAddress = _sellerWalletAddress;
    }

    function setNFTCollection(address _address) public onlyRole(ADMIN) {
        NFTCollection = iNFTCollection(_address);
    }

    function setSaleData(
        uint256 _newCost,
        bytes32 _merkleRoot,
        address _sellerWalletAddress,
        address _address
    ) public onlyRole(ADMIN){
        setCost(_newCost);
        setMerkleRoot(_merkleRoot);
        setSellserWalletAddress(_sellerWalletAddress);
        setNFTCollection(_address);
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

}