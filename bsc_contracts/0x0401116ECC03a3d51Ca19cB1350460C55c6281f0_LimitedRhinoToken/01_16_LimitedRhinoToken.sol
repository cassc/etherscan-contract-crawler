// SPDX-License-Identifier: MIT

pragma solidity =0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./LimitedRhinoTokenStorage.sol";
import {List} from  "../struct/RhinoTokenStructs.sol";


contract LimitedRhinoToken is ERC721, ERC721Enumerable, ReentrancyGuard, Ownable, LimitedRhinoTokenStorage {

    using Strings for uint256;

    uint256 private _tokenId = 1;

    string public baseURI;

    string public suffix = ".json";


    event BaseURI(string baseURI);
    event SetMerge(address oldMerge, address newMerge);
    event NftBurn(address owner, uint256 tokenId);
    event Create(address account, uint256 amount);
    event NewPricePer(uint256 oldAmount, uint256 newAmount);
    event NewPayee(address oldPayee, address newPayee);
    event SynthesisMint(address account, uint256 tokenId);


    constructor(string memory baseURI_, address payee_) ERC721("MiddleLevelLimitedRhinoToken","MLRT") {
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

    function mint(address _recipient, uint256 limitedTime) public onlyOwner returns(uint256 _mintTokenId, uint256 _time){
        require(_recipient != address(0), "ERC721: mint to the zero address");
        if(limitedTime == 100){
            require(subscribeAmount100 + 1 <= MAX_SUPPLY_100, "Purchase would exceed max tokens");
            subscribeAmount100 += 1;
        }else if(limitedTime == 200){
            require(subscribeAmount200 + 1 <= MAX_SUPPLY_200, "Purchase would exceed max tokens");
            subscribeAmount200 += 1;
        }else if(limitedTime == 300){
            require(subscribeAmount300 + 1 <= MAX_SUPPLY_300, "Purchase would exceed max tokens");
            subscribeAmount300 += 1;
        }else {
            require(false, "Limited dividend time error");
        }
        uint256 newTokenId;
        _mint(_recipient, (newTokenId = _tokenId++));
        idByLimitedTime[newTokenId] = limitedTime;
        firstHolder[newTokenId] = _recipient;

        return (newTokenId, limitedTime);
    }

    function withdraw(uint256 limitedTime) external nonReentrant returns(uint256 _mintTokenId, uint256 _time){
        address _recipient = msg.sender;
        List memory lt = lotteryList[_recipient][limitedTime];
        require(lt.amount > 0, "This address has no subscription quota");
        require(lt.reward + 1 <= lt.amount, "Account subscription share is insufficient");

        uint256 newTokenId;
        _mint(_recipient, (newTokenId = _tokenId++));
        idByLimitedTime[newTokenId] = limitedTime;
        firstHolder[newTokenId] = _recipient;

        List storage lottery = lotteryList[_recipient][limitedTime];
        lottery.reward += 1;
        return (newTokenId, limitedTime);
    }

    function withdrawList(uint256[] calldata mintAmount, uint256[] calldata limitedTime) external nonReentrant returns(uint256[] memory){
        address _recipient = msg.sender;
        uint256 amount;
        for(uint y; y < mintAmount.length; y++){
            amount += mintAmount[y];
        }
        uint256[] memory id = new uint256[](amount);
        uint256 index;
        for(uint j; j < mintAmount.length; j++){
            List memory lt = lotteryList[_recipient][limitedTime[j]];
            require(lt.amount > 0, "This address has no subscription quota");

            uint256 available = lt.amount - lt.reward;
            require(mintAmount[j] <= available, "Account subscription share is insufficient");

            for (uint i; i < mintAmount[j]; i++) {
                uint256 newTokenId;
                _mint(_recipient, (newTokenId = _tokenId++));
                idByLimitedTime[newTokenId] = limitedTime[j];
                firstHolder[newTokenId] = _recipient;

                id[index] = newTokenId;
                index += 1;
            }
            List storage lottery = lotteryList[_recipient][limitedTime[j]];
            lottery.reward += mintAmount[j];
        }
        return id;
    }

    function burn(address owner, uint256[] memory tokenId) external onlyMerge returns(bool){
        require(tokenId.length > 0, "ERC721: Array id is empty");
        uint256 level1;
        uint256 level2;
        uint256 level3;
        for(uint j; j < tokenId.length; j++){
            uint256 limitedTime = idByLimitedTime[tokenId[j]];
            if(limitedTime == 100){
                level1 += 1;
            } else if(limitedTime == 200){
                level2 += 1;
            } else if(limitedTime == 300){
                level3 += 1;
            }
        }
        require(level1 == 3, "100 Days Limited Benefit Card Error");
        require(level2 == 2, "200 Days Limited Benefit Card Error");
        require(level3 == 1, "300 Days Limited Benefit Card Error");

        for(uint i; i < tokenId.length; i++){
            require(owner == ownerOf(tokenId[i]), "ERC721: The tokenId is not owned by the owner");
            uint256 id = tokenId[i];
            _burn(id);
            delete idByLimitedTime[id];
        }
        return true;
    }

    function synthesisMint(address recipient, uint256 limitedTime) external onlyMerge returns(address, uint256, uint256){
        require(recipient != address(0), "ERC721: mint to the zero address");
        if(limitedTime == 100){
            require(subscribeAmount100 + 1 <= MAX_SUPPLY_100, "Purchase would exceed max tokens");
            subscribeAmount100 += 1;
        }else if(limitedTime == 200){
            require(subscribeAmount200 + 1 <= MAX_SUPPLY_200, "Purchase would exceed max tokens");
            subscribeAmount200 += 1;
        }else if(limitedTime == 300){
            require(subscribeAmount300 + 1 <= MAX_SUPPLY_300, "Purchase would exceed max tokens");
            subscribeAmount300 += 1;
        }else {
            require(false, "Limited dividend time error");
        }

        uint256 newTokenId;
        _mint(recipient, (newTokenId = _tokenId++));
        idByLimitedTime[newTokenId] = limitedTime;
        firstHolder[newTokenId] = recipient;

        emit SynthesisMint(recipient, newTokenId);
        return (recipient, newTokenId, limitedTime);
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

    function getIdAndLimitedTime(address owner) external view returns(uint256[] memory, uint256[] memory) {

        uint256[] memory ids = tokensOwnedByIds(owner);
        uint256[] memory limitedTime = new uint256[](ids.length);
        for(uint i; i < ids.length; i++){
            limitedTime[i] = idByLimitedTime[ids[i]];
        }
        return (ids, limitedTime);
    }

    function tokensOwnedByIds(address owner) public view returns(uint256[] memory) {
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

    function subscribeList(address[] calldata account, uint256[] calldata amount, uint256 limitedTime) external onlyOwner {
        require(account.length > 0, "Account array length is less than 0");
        uint256 sum;
        for (uint j = 0; j < amount.length; j++) {
            sum += amount[j];
        }
        if(limitedTime == 100){
            require(subscribeAmount100 + sum <= MAX_SUPPLY_100, "The total number of shares subscribed exceeds the largest token");
            subscribeAmount100 += sum;
        } else if(limitedTime == 200){
            require(subscribeAmount200 + sum <= MAX_SUPPLY_200, "The total number of shares subscribed exceeds the largest token");
            subscribeAmount200 += sum;
        } else if(limitedTime == 300){
            require(subscribeAmount300 + sum <= MAX_SUPPLY_300, "The total number of shares subscribed exceeds the largest token");
            subscribeAmount300 += sum;
        }else {
            require(false, "Limited dividend time error");
        }

        for (uint i = 0; i < account.length; i++) {
            require(account[i] != address(0), "ERC721: record to zero address");
            List storage list = lotteryList[account[i]][limitedTime];
            list.amount = list.amount += amount[i];
        }
    }

    function oneSubscribeList(address account, uint256 amount, uint256 limitedTime) external onlyOwner {
        require(account != address(0), "ERC721: record to zero address");
        if(limitedTime == 100){
            require(subscribeAmount100 + amount <= MAX_SUPPLY_100, "The total number of shares subscribed exceeds the largest token");
            subscribeAmount100 += amount;
        } else if(limitedTime == 200){
            require(subscribeAmount200 + amount <= MAX_SUPPLY_200, "The total number of shares subscribed exceeds the largest token");
            subscribeAmount200 += amount;
        } else if(limitedTime == 300){
            require(subscribeAmount300 + amount <= MAX_SUPPLY_300, "The total number of shares subscribed exceeds the largest token");
            subscribeAmount300 += amount;
        }else {
            require(false, "Limited dividend time error");
        }
        List storage list = lotteryList[account][limitedTime];
        list.amount = list.amount += amount;
    }

    modifier onlyMerge(){
        require(msg.sender == merge, "caller is not the merge address");
        _;
    }

}