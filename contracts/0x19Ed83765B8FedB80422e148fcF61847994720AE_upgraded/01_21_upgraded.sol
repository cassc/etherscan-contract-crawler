// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IMinter.sol";


contract upgraded is  ERC721Upgradeable, OwnableUpgradeable, DefaultOperatorFiltererUpgradeable {

    using Counters for Counters.Counter;
    
    address constant SNContract = 0xd532b88607B1877Fe20c181CBa2550E3BbD6B31C;
    address public burnAddress;
    bool public claimLive;
    string baseURI;    

    Counters.Counter private _tokenIdCounter;


    modifier hasSN(address owner){
        require(IERC721(SNContract).balanceOf(owner) > 0,"This wallet doesn't have any SN tokens.");
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(uint256[] calldata tokenIds) external hasSN(msg.sender){
        require(claimLive, "Claiming is paused or not started");
        address to = msg.sender;

        for(uint i = 0; i < tokenIds.length;){

            uint256 tokenId = tokenIds[i];
            require(IERC721(SNContract).ownerOf(tokenId) == to,"You don't own at least one of the tokens you input.");

            _mintInternal(to, tokenId);
            IERC721(SNContract).transferFrom(to,burnAddress,tokenId);
            
            unchecked { ++i;}
        }

        IMinter(0xEe6450565794D52D4d81C4F6FD71232d221589A5).mint(to);
    }

    function _mintInternal(address _to, uint256 _tokenId) internal{
        _mint(_to, _tokenId);
        _tokenIdCounter.increment();
    }

    function setBurnAddress(address newBurnAddress) external onlyOwner {
        burnAddress = newBurnAddress;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function claimSwitch() public onlyOwner {
        claimLive = !claimLive;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(payable(msg.sender).send(balance));
    }

    function transferFrom(address from, address to, uint256 tokenId) public override  onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override  onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function totalSupply() public view returns (uint){
        return _tokenIdCounter.current();
    }

    function isClaimed(uint tokenId) external view returns(bool tokenExists){
        return _exists(tokenId);
    }

    function tokensOfWallet(address wallet) public view returns(uint256[] memory ) {
        require(balanceOf(wallet) > 0, "This wallet doesn't hold any tokens.");
        uint256 tokenCount = balanceOf(wallet);
        uint256[] memory result = new uint256[](tokenCount);
        uint256 index = 0;

        for (uint256 tokenId = 1; tokenId < 8889; tokenId++) {
            if (index == tokenCount) break;

            if (_ownerOf(tokenId) == wallet) {
                result[index] = tokenId;
                index++;
            }
        }

        return result;
    }

    function tokenOfOwnerByIndex(address wallet, uint256 index) public view returns (uint256 tokenId) {
        require(index < balanceOf(wallet), "Owner index out of bounds");
        return tokensOfWallet(wallet)[index];
    
    }

}