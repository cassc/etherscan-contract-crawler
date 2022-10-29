// SPDX-License-Identifier: MIT

pragma solidity =0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./CartoonRhinoTokenStorage.sol";


contract CartoonRhinoToken is ERC721, ERC721Enumerable, ReentrancyGuard, Ownable, CartoonRhinoTokenStorage {

    using Strings for uint256;

    string public baseURI;

    string public suffix = ".json";

    event BaseURI(string baseURI);
    event SetMerge(address oldMerge, address newMerge);
    event Create(address account, uint256 amount);
    event NftBurn(address owner, uint256 tokenId);
    event NewPricePer(uint256 oldAmount, uint256 newAmount);
    event NewPayee(address oldPayee, address newPayee);
    event Subscribe(address account, uint256 tokenId);


    constructor(string memory baseURI_, address payee_) ERC721("CartoonRhinoToken","CRT") {
        baseURI = baseURI_;
        payee = payee_;
    }

    function create() external payable returns(bool){
        require(msg.value >= MIN_PRICE_PER, "Ether value sent is not correct");
        uint256 balance = address(this).balance;
        payable(payee).transfer(balance);
        emit Create(msg.sender, balance);
        return true;
    }

    function mint(address _recipient) public onlyOwner returns(uint _mintTokenId){
        require(_recipient != address(0), "ERC721: mint to the zero address");
        require(subscribeAmount + 1 <= MAX_SUPPLY, "Purchase would exceed max tokens");

        uint256 newTokenId;
        for(uint i = 1; i <= MAX_SUPPLY; i++){
            if(!tokenIdRecord[i]){
                newTokenId = i;
                break;
            }
        }
        _mint(_recipient, newTokenId);
        tokenIdRecord[newTokenId] = true;
        subscribeAmount += 1;
        return newTokenId;
    }

    function withdraw(uint256 tokenId) external nonReentrant returns(uint _mintTokenId){
        address _recipient = msg.sender;
        uint256[] memory list = lotteryList[_recipient];
        require(list.length > 0, "No NFT to claim");

        for (uint i; i < list.length; i++) {
            if(list[i] == tokenId){
                _mint(_recipient, tokenId);
                removeLotteryList(_recipient, tokenId);
                break;
            }
        }
        return tokenId;
    }

    function allWithdraw() external nonReentrant returns(uint256[] memory){
        address _recipient = msg.sender;
        uint256[] memory list = lotteryList[_recipient];
        require(list.length > 0, "No NFT to claim");

        for (uint i; i < list.length; i++) {
            _mint(_recipient, list[i]);
            removeLotteryList(_recipient, list[i]);
        }
        return list;
    }

    function withdrawList(uint256[] calldata tokenId) external nonReentrant returns(uint256[] memory){
        require(tokenId.length > 0, "token ID length is less than 0");

        address _recipient = msg.sender;
        uint256[] memory list = lotteryList[_recipient];
        require(list.length > 0, "No NFT to claim");

        for(uint i; i < tokenId.length; i++){

            for(uint j; j < list.length; j++){
                if(list[j] == tokenId[i]){
                    _mint(_recipient, tokenId[i]);
                    removeLotteryList(_recipient, tokenId[i]);
                    break;
                }
            }
        }
        return tokenId;
    }

    function removeLotteryList(address owner, uint256 tokenId) internal {
        uint256[] storage list = lotteryList[owner];
        uint len = list.length;
        uint index = len;
        for (uint y = 0; y < list.length; y++) {
            if (list[y] == tokenId) {
                index = y;
                break;
            }
        }
        list[index] = list[len - 1];
        list.pop();
    }

    function burn(address owner, uint256 tokenId) external onlyMerge returns(address, uint256){
        require(owner == ownerOf(tokenId), "ERC721: The tokenId is not owned by the owner");
        _burn(tokenId);
        emit NftBurn(owner, tokenId);
        return (owner, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = baseURI;
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), suffix))
        : '';
    }

    function blindBoxList(address owner) external view returns(uint256[] memory){
        uint256[] memory list = lotteryList[owner];
        return list;
    }

    function tokensOwnedByIds(address owner) external view returns(uint256[] memory) {
        uint tokenCount = balanceOf(owner);
        uint256[] memory ownedTokenIds = new uint256[](tokenCount);
        for(uint i = 0; i < tokenCount; i++){
            ownedTokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return ownedTokenIds;
    }

    function setMerge(address newMerge) external onlyOwner {
        require(newMerge != address(0), "ERC721: merge cannot be set to zero address");
        address oldMerge = merge;
        merge = newMerge;
        emit SetMerge(oldMerge, newMerge);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        require(bytes(baseURI_).length > 0,"The baseURI_ must be have");
        baseURI = baseURI_;
        emit BaseURI(baseURI_);
    }

    function setPricePer(uint256 newPrice) external onlyOwner {
        require(newPrice > 0,"Price value sent is not correct");
        uint256 old = MIN_PRICE_PER;
        MIN_PRICE_PER = newPrice;
        emit NewPricePer(old, newPrice);
    }

    function setPayee(address newPayee) external onlyOwner {
        require(newPayee != address(0), "ERC721: payee cannot be set to zero address");
        address old = payee;
        payee = newPayee;
        emit NewPayee(old, newPayee);
    }

    function subscribeList(address[] calldata account, uint256[] calldata tokenId) external onlyOwner {
        uint256 length = account.length;
        require(length > 0, "Account array length is less than 0");
        subscribeAmount += length;
        require(subscribeAmount <= MAX_SUPPLY, "The total number of shares subscribed exceeds the largest token");

        for (uint i = 0; i < account.length; i++) {
            require(!tokenIdRecord[tokenId[i]], "token ID already exists or minted");
            lotteryList[account[i]].push(tokenId[i]);
            tokenIdRecord[tokenId[i]] = true;
        }
    }

    function oneSubscribe(address account, uint256 tokenId) external onlyOwner {
        require(account != address(0), "ERC721: record to zero address");
        require(!tokenIdRecord[tokenId], "token ID already exists or minted");

        subscribeAmount += 1;
        require(subscribeAmount <= MAX_SUPPLY, "The total number of shares subscribed exceeds the largest token");

        lotteryList[account].push(tokenId);
        tokenIdRecord[tokenId] = true;
        emit Subscribe(account, tokenId);
    }

    modifier onlyMerge(){
        require(msg.sender == merge, "caller is not the merge address");
        _;
    }

}