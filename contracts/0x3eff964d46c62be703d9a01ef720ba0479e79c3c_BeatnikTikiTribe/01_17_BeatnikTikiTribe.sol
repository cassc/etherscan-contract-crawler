//SPDX-License-Identifier: MIT

/*

 ____                     __               __          ______    __              ______           __                
/\  _`\                  /\ \__         __/\ \        /\__  _\__/\ \      __    /\__  _\       __/\ \               
\ \ \L\ \     __     __  \ \ ,_\   ___ /\_\ \ \/'\    \/_/\ \/\_\ \ \/'\ /\_\   \/_/\ \/ _ __ /\_\ \ \____     __   
 \ \  _ <'  /'__`\ /'__`\ \ \ \/ /' _ `\/\ \ \ , <       \ \ \/\ \ \ , < \/\ \     \ \ \/\`'__\/\ \ \ '__`\  /'__`\ 
  \ \ \L\ \/\  __//\ \L\.\_\ \ \_/\ \/\ \ \ \ \ \\`\      \ \ \ \ \ \ \\`\\ \ \     \ \ \ \ \/ \ \ \ \ \L\ \/\  __/ 
   \ \____/\ \____\ \__/.\_\\ \__\ \_\ \_\ \_\ \_\ \_\     \ \_\ \_\ \_\ \_\ \_\     \ \_\ \_\  \ \_\ \_,__/\ \____\
    \/___/  \/____/\/__/\/_/ \/__/\/_/\/_/\/_/\/_/\/_/      \/_/\/_/\/_/\/_/\/_/      \/_/\/_/   \/_/\/___/  \/____/
                                                                                                                                                                                                                                        
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract BeatnikTikiTribe is Ownable, ERC721Enumerable, ERC721Burnable, ERC721Pausable {

    using Counters for Counters.Counter;

    event TikisClaimed(uint256 _totalClaimed, address _owner, uint256 _numOfTokens, uint256[] _tokenIds);

    Counters.Counter private _tokenIdTracker;
    
    string public provenanceHash;
    uint256 public startingIndexBlock;
    uint256 public startingIndex;
    uint public maxTikisInTx;
    uint256 public revealTimestamp;
    bool public saleEnabled;
    uint256 public price;
    string public metadataBaseURL;

    uint256 public constant maxTikis = 9999;

    constructor (string memory _metadataBaseURL, uint256 _revealTimestamp) 
    ERC721("Beatnik Tiki Tribe", "BTT") {
        revealTimestamp = _revealTimestamp;
        metadataBaseURL = _metadataBaseURL;
        
        saleEnabled = false;
        maxTikisInTx = 10;
        price = 0.07 ether;
        startingIndexBlock = 0;
        startingIndex = 0;
        provenanceHash = "";
    }

    function setRevealTimestamp(uint256 timestamp) public onlyOwner {
        revealTimestamp = timestamp;
    }

    function setBaseURI(string memory baseURL) public onlyOwner {
        metadataBaseURL = baseURL;
    }

    function setMaxTikisInTx(uint num) public onlyOwner {
        maxTikisInTx = num;
    }

    function flipSaleEnabled() public onlyOwner {
        saleEnabled = !(saleEnabled);
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        provenanceHash = _provenanceHash;
    }

    function emergencySetStartingIndex() public onlyOwner {
        _setStartingIndex();
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        address payable _sender = payable(_msgSender());
        _sender.transfer(_balance);
    }

    function mintTikiToAddress(address to) public onlyOwner {
        require(_tokenIdTracker.current() < maxTikis, "TikiTribe: All Tikis have already been claimed");
        _safeMint(to, _tokenIdTracker.current() + 1);
        _tokenIdTracker.increment();
    }

    function reserveTikis(uint num) public onlyOwner {
        uint i;
        for (i=0; i<num; i++)
            mintTikiToAddress(msg.sender);
    }

    function pause() public virtual onlyOwner {
        _pause();
    }

    function unpause() public virtual onlyOwner {
        _unpause();
    }

    function getCurrentCount() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function mintTikis(uint256 numOfTokens) public payable {
        require(saleEnabled, "TikiTribe: Cannot claim Tikis at the moment");
        require(_tokenIdTracker.current() + numOfTokens <= maxTikis, "TikiTribe: Claim will exceed maximum available Tikis");
        require(numOfTokens > 0, "TikiTribe: Must claim atleast one Tiki");
        require(numOfTokens <= maxTikisInTx, "TikiTribe: Cannot claim more than 10 Tikis in one tx");
        require(msg.value >= (price * numOfTokens), "TikiTribe: Insufficient funds to claim Tikis");
        
        address payable _sender = payable(_msgSender());
        _sender.transfer(msg.value - (price * numOfTokens));

        uint256[] memory ids = new uint256[](numOfTokens);
        for(uint i=0; i<numOfTokens; i++) {
            uint256 _tokenid = _tokenIdTracker.current() + 1;
            ids[i] = _tokenid;
            _safeMint(msg.sender, _tokenid);
            _tokenIdTracker.increment();
        }
        
        if (startingIndexBlock == 0 && (_tokenIdTracker.current() == maxTikis || block.timestamp >= revealTimestamp)) {
            _setStartingIndex();
        }

        emit TikisClaimed(_tokenIdTracker.current(), _sender, numOfTokens, ids);
    }

    function _setStartingIndex() internal {
        startingIndexBlock = block.number - 1;
        startingIndex = uint(blockhash(startingIndexBlock)) % maxTikis;

        if (startingIndex == 0)
            startingIndex = 10;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataBaseURL;
    }

    function _beforeTokenTransfer(
        address from, 
        address to, 
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable, ERC721, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Enumerable, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}