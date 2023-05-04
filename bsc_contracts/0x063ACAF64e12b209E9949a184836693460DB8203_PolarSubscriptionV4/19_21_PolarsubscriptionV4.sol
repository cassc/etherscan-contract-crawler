// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Referral.sol";
import "./Storage.sol";

contract PolarSubscriptionV4 is ERC721URIStorage, ERC721Enumerable, Pausable, Ownable, Storage, Referral, AutomationCompatibleInterface {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("PolarSubscription", "PS") {
        treasurer = msg.sender;
        lastTimestamp = block.timestamp;
    }


    //CHAINLINK AUTOMATION
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {

        upkeepNeeded = false;
        uint256 counter;

        if((block.timestamp - lastTimestamp) > 1 days){     //how often should the automation run?


            for(uint i; i < _tokenIdCounter.current(); i++){
                if(idToTime[i] + 1 days < block.timestamp){ //Adjust to timeframe you would like
                    upkeepNeeded = true;
                    counter++;
                }
            }
            
            uint256[] memory toBeUpdated = new uint256[](counter);
            uint zaehler;

            for(uint i; i < _tokenIdCounter.current(); i++){
                if(idToTime[i] + 1 days < block.timestamp && isSubscribed[i] == true){ //Adjust to timeframe you would like
                    toBeUpdated[zaehler] = i;
                    zaehler++;
                }
            }
            performData = abi.encode(toBeUpdated);

            return (upkeepNeeded, performData);
        }
    }


    function performUpkeep(bytes calldata performData) external {

        uint256[] memory toBeUpdated = abi.decode(performData, (uint256[]));

        for(uint i; i < toBeUpdated.length; i++){
            _setTokenURI(toBeUpdated[i], IpfsUri[1]);
            isSubscribed[i] = false;
        }

        lastTimestamp = block.timestamp;
    }


//MINTING AND RESUBSCRIBING

    function safeMint() public {
        require(tokenAddress.allowance(msg.sender, address (this)) >= rate, "allowance too low");
        require(isHolder[msg.sender] == false, "address already holder");
        tokenAddress.transferFrom(msg.sender, address(this), rate);
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        idToTime[tokenId] = block.timestamp;
        addressToId[msg.sender] = tokenId;
        isSubscribed[tokenId] = true;
        isHolder[msg.sender] = true;

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, IpfsUri[0]);
    }

    function mintWithReferral(address referral) public {
        require(msg.sender != referral, "you cannot refer yourself");
        require(tokenAddress.allowance(msg.sender, address (this)) >= referralRate, "allowance too low");
        require(isHolder[msg.sender] == false, "address already holder");

        tokenAddress.transferFrom(msg.sender, address(this), referralRate);
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        idToTime[tokenId] = block.timestamp;
        addressToId[msg.sender] = tokenId;
        isSubscribed[tokenId] = true;
        isHolder[msg.sender] = true;

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, IpfsUri[0]);        
        _refer(referral);
    }

    function resubscribe() public{
        require(tokenAddress.allowance(msg.sender, address (this)) >= rate, "allowance too low");
        require(isHolder[msg.sender] == true, "address not holder yet");
        tokenAddress.transferFrom(msg.sender, address(this), rate);
        uint tokenId = addressToId[msg.sender];
        idToTime[tokenId] = block.timestamp;
        isSubscribed[tokenId] = true;
        _setTokenURI(tokenId, IpfsUri[0]);
    }

    function resubscribeWithReferral(address referral) public{
        require(msg.sender != referral, "you cannot refer yourself");
        require(tokenAddress.allowance(msg.sender, address (this)) >= referralRate, "allowance too low");
        require(isHolder[msg.sender] == true, "address not holder yet");

        tokenAddress.transferFrom(msg.sender, address(this), referralRate);
        uint tokenId = addressToId[msg.sender];


        idToTime[tokenId] = block.timestamp;
        isSubscribed[tokenId] = true;
        _setTokenURI(tokenId, IpfsUri[0]);        
        _refer(referral);
    }


    

//WITHDRAWALS
    function userWithdrawReferral()public {
        _verifyUser();
        uint balance = referralDB[msg.sender].balance;
        referralDB[msg.sender].balance = 0;
        tokenAddress.transfer(msg.sender, balance*10**18);
    }

    function withdrawTreasury() public onlyOwner {
        uint amount = tokenAddress.balanceOf(address(this))*90 / 100;
        tokenAddress.transfer(treasurer, amount);
    }

//PAUSE/UNPAUSE CONTRACT
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

// The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
   




//THESE FUNCTIONS INCLUDE JUST THE LOGIC OF THE CHAINLINK AUTOMATION FOR TESTING. DO NOT USE THESE IN PRODUCTION

    function checkUpkeep2()
        external
        view
        onlyOwner
        returns (bool upkeepNeeded)
    {

        upkeepNeeded = false;
        uint256 counter;

        for(uint i; i < _tokenIdCounter.current(); i++){
            if(idToTime[i] + 35 days < block.timestamp && isSubscribed[i] == true){
                upkeepNeeded = true;
                counter++;
            }
        }
        
        uint256[] memory toBeUpdated = new uint256[](counter);
        uint zaehler;

        for(uint i; i < _tokenIdCounter.current(); i++){
            if(idToTime[i] + 35 days < block.timestamp && isSubscribed[i] == true){
                toBeUpdated[zaehler] = i;
                zaehler++;
            }
        }
        return (upkeepNeeded);
    }
    

    function performUpkeep2(uint _id) external onlyOwner {
            _setTokenURI(_id, IpfsUri[1]);
            isSubscribed[_id] = false;
    }

}