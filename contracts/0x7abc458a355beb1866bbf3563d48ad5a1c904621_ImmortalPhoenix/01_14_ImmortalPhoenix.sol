// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721EnumerableCheap.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

struct Phoenix {
        uint128 hash;
        uint8 level;
        string name;
}

struct MetadataStruct {

    uint tokenId;
    uint collectionId;
    uint numTraits;
    string description;
    string unRevealedImage;

}

struct PaymentStruct {
    address membersAddress;
    uint owed;
    uint payed;
}

struct ResurrectionInfo {
    uint tokenId;
    uint128 hash;
}


contract IBlazeToken {

    function updateTokens(address userAddress) external {}

    function updateTransfer(address _fromAddress, address _toAddress) external {}

    function burn(address  _from, uint256 _amount) external {}

}

contract IMetadataHandler {

    function tokenURI(Phoenix memory _phoenix, MetadataStruct memory _metadataStruct) external view returns(string memory)  {}

    function getSpecialToken(uint _collectionId, uint _tokenId) external view returns(uint) {}

    function resurrect(uint _collectionId, uint _tokenId) external {}

    function rewardMythics(uint _collectionId, uint _numMythics) external {}
}

/**
 __     __    __     __    __     ______     ______     ______   ______     __           
/\ \   /\ "-./  \   /\ "-./  \   /\  __ \   /\  == \   /\__  _\ /\  __ \   /\ \          
\ \ \  \ \ \-./\ \  \ \ \-./\ \  \ \ \/\ \  \ \  __<   \/_/\ \/ \ \  __ \  \ \ \____     
 \ \_\  \ \_\ \ \_\  \ \_\ \ \_\  \ \_____\  \ \_\ \_\    \ \_\  \ \_\ \_\  \ \_____\    
  \/_/   \/_/  \/_/   \/_/  \/_/   \/_____/   \/_/ /_/     \/_/   \/_/\/_/   \/_____/    
                                                                                         
             ______   __  __     ______     ______     __   __     __     __  __         
            /\  == \ /\ \_\ \   /\  __ \   /\  ___\   /\ "-.\ \   /\ \   /\_\_\_\        
            \ \  _-/ \ \  __ \  \ \ \/\ \  \ \  __\   \ \ \-.  \  \ \ \  \/_/\_\/_       
             \ \_\    \ \_\ \_\  \ \_____\  \ \_____\  \ \_\\"\_\  \ \_\   /\_\/\_\      
              \/_/     \/_/\/_/   \/_____/   \/_____/   \/_/ \/_/   \/_/   \/_/\/_/      
                                                                                         
*/


contract ImmortalPhoenix is ERC721EnumerableCheap, Ownable {

    mapping(uint256 => Phoenix) tokenIdToPhoenix;

    uint[6] levelUpCosts;

    bool public publicMint;

    uint16 public maxSupply = 5001;

    uint8 public totalLevelSix;

    uint8 public maxLevelSix = 200;

    //Price in wei = 0.055 eth
    uint public price = 0.055 ether;

    uint public nameCost = 80 ether;

    uint public resurrectCost = 100 ether;

    IMetadataHandler metadataHandler;

    mapping(address => uint) addressToLevels;

    IBlazeToken blazeToken;

    uint[] roleMaxMint;

    bytes32[] roots;

    PaymentStruct[] payments;

    mapping(address => uint) numMinted;

    mapping(string => bool) nameTaken;

    ResurrectionInfo previousResurrection;

    bool allowResurrection;

    uint resurrectionId;

    event LeveledUp(uint id, address indexed userAddress);
    event NameChanged(uint id, address indexed userAddress);

    constructor(address _blazeTokenAddress, address _metadataHandlerAddress, uint[] memory _roleMaxMint, PaymentStruct[] memory _payments) ERC721Cheap("Immortal Phoenix", "Phoenix") {

        levelUpCosts = [10 ether, 20 ether, 30 ether, 40 ether, 50 ether, 60 ether];

        blazeToken = IBlazeToken(_blazeTokenAddress);
        metadataHandler = IMetadataHandler(_metadataHandlerAddress);
        roleMaxMint = _roleMaxMint;

        for(uint i = 0; i < _payments.length; i++) {
            payments.push(_payments[i]);
        }
        
    }

    /**
     _      _      _      _    _      _____    _     _     _      _____    
    /\ "-./  \   /\ \   /\ "-.\ \   /\__  _\ /\ \   /\ "-.\ \   /\  ___\   
    \ \ \-./\ \  \ \ \  \ \ \-.  \  \/_/\ \/ \ \ \  \ \ \-.  \  \ \ \__ \  
     \ \_\ \ \_\  \ \_\  \ \_\\"\_\    \ \_\  \ \_\  \ \_\\"\_\  \ \_____\ 
      \/_/  \/_/   \/_/   \/_/ \/_/     \/_/   \/_/   \/_/ \/_/   \/_____/

    */

    /**
     * @dev Generates a random number that will be used by the metadata manager to generate the image.
     * @param _tokenId The token id used to generated the hash.
     * @param _address The address used to generate the hash.
     */
    function generateTraits(
        uint _tokenId,
        address _address
    ) internal view returns (uint128) {

        //TODO: turn back to internal

        return uint128(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                block.timestamp,
                                block.difficulty,
                                _tokenId,
                                _address
                                
                            )
                        )   
                    )
                );

    }

    /**
     * @dev internal function that mints a phoenix, generates its hash and base values, can be called by public or whistlist external functions.
     * @param thisTokenId is the token id of the soon to be minted phoenix
     * @param sender is the address to mint to
     */
    function mint(uint256 thisTokenId, address sender) internal {

        tokenIdToPhoenix[thisTokenId] = Phoenix(
            generateTraits(thisTokenId, sender),
            1,
            string("")
        );

        _mint(sender, thisTokenId);

    }

    /**
     * @dev public mint function, mints the requested number of phoenixs.
     * @param _amountToMint the number of phoenixs to mint in this transaction, limited to a max of 5
     */
    function mintPhoenix(uint _amountToMint) external payable {

        require(publicMint == true, "Minting isnt public at the moment");

        require(_amountToMint > 0, "Enter a valid amount to mint");

        require(_amountToMint < 6, "Attempting to mint too many");

        require(price * _amountToMint == msg.value, "Incorrect ETH value");

        uint tokenId = totalSupply();
        require(tokenId + _amountToMint < maxSupply, "All tokens already minted");

        address sender = _msgSender();

        for(uint i = 0; i < _amountToMint; i++) {
        
            mint(tokenId + i, sender);

        }

        blazeToken.updateTokens(sender);
        
        addressToLevels[sender] += _amountToMint;   
    }

    /**
     * @dev Mints new Phoenix if the address is on the whitelist.
     * @param _merkleProof the proof required to verify if this address is on the whilelist
     * @param _amountToMint is the number of phoenixs requested to mint, limited based on the whitelist the user is on
     * @param _merkleIndex is the index of the whitelist the user has submitted a proof for
     */
    function mintPhoenixWhiteList(bytes32[] calldata _merkleProof, uint _amountToMint, uint _merkleIndex) external payable {

        require(_amountToMint > 0, "Enter a valid amount to mint");

        uint thisTokenId = totalSupply();

        require(price * _amountToMint == msg.value, "Incorrect ETH value");
        require(thisTokenId + _amountToMint < maxSupply, "All tokens already minted");

        address sender = _msgSender();

        bytes32 leaf = keccak256(abi.encodePacked(sender));

        require(MerkleProof.verify(_merkleProof, roots[_merkleIndex], leaf), "Invalid proof");

        require(numMinted[sender] + _amountToMint <= roleMaxMint[_merkleIndex], "Trying to mint more than allowed");

        numMinted[sender] += _amountToMint;

        for(uint i = 0; i < _amountToMint; i++) {
            mint(thisTokenId + i, sender);
        }

        blazeToken.updateTokens(sender);

        addressToLevels[sender] += _amountToMint;
        
    }

    /** 
         __  __     ______   __     __         __     ______   __  __    
        /\ \/\ \   /\__  _\ /\ \   /\ \       /\ \   /\__  _\ /\ \_\ \   
        \ \ \_\ \  \/_/\ \/ \ \ \  \ \ \____  \ \ \  \/_/\ \/ \ \____ \  
         \ \_____\    \ \_\  \ \_\  \ \_____\  \ \_\    \ \_\  \/\_____\ 
          \/_____/     \/_/   \/_/   \/_____/   \/_/     \/_/   \/_____/                                                          

    */

    /**
    * @dev Levels up the chosen phoenix by the selected levels at the cost of blaze tokens
    * @param _tokenId is the id of the phoenix to level up
    * @param _levels is the number of levels to level up by
    */
    function levelUp(uint _tokenId, uint8 _levels) external {

        address sender = _msgSender();

        require(sender == ownerOf(_tokenId), "Not owner of token");

        uint8 currentLevel = tokenIdToPhoenix[_tokenId].level;

        uint8 level = currentLevel + _levels;

        if(level >= 6) {

            uint specialId = metadataHandler.getSpecialToken(0, _tokenId);

            if(specialId == 0) {
                require(level  <= 6, "Cant level up to seven unless unique");
                require(totalLevelSix < maxLevelSix, "Already max amount of levels 6 phoenixs created");
                totalLevelSix++;
            } else {
                require(level <= 7, "Not even uniques can level past 7");
            }

        }

        uint cost;
        for(uint8 i = currentLevel - 1; i < level; i++) {

            cost += levelUpCosts[i];

        }
        
        blazeToken.updateTokens(sender);

        blazeToken.burn(sender, cost);

        addressToLevels[sender] += uint(_levels);
        tokenIdToPhoenix[_tokenId].level = level;

        emit LeveledUp(_tokenId, sender);

    }

    /**
    * @dev Makes sure the name is valid with the constraints set
    * @param _name is the desired name to be verified
    * @notice credits to cyberkongz
    */ 
    function validateName(string memory _name) public pure returns (bool){

        bytes memory byteString = bytes(_name);
        
        if(byteString.length == 0) return false;
        
        if(byteString.length >= 20) return false;

        for(uint i; i < byteString.length; i++){

            bytes1 character = byteString[i];

            //limit the name to only have numbers, letters, or spaces
            if(
                !(character >= 0x30 && character <= 0x39) &&
                !(character >= 0x41 && character <= 0x5A) &&
                !(character >= 0x61 && character <= 0x7A) &&
                !(character == 0x20)
            )
                return false;
        }

        return true;
    }

    /**
    * @dev Changes the name of the selected phoenix, at the cost of blaze tokens
    * @param _name is the desired name to change the phoenix to
    * @param _tokenId is the id of the token whos name will be changed
    */
    function changeName(string memory _name, uint _tokenId) external {

        require(_msgSender() == ownerOf(_tokenId), "Only the owner of this token can change the name");

        require(validateName(_name) == true, "Invalid name");

        require(nameTaken[_name] == false, "Name is already taken");

        string memory currentName = tokenIdToPhoenix[_tokenId].name;

        blazeToken.burn(_msgSender(), nameCost);

        if(bytes(currentName).length == 0) {

            nameTaken[currentName] = false;

        }

        nameTaken[_name] = true;

        tokenIdToPhoenix[_tokenId].name = _name;

        emit NameChanged(_tokenId, _msgSender());

    }

    /**
    * @dev rerolls the traits of a phoenix, consuming blaze to rise anew from the ashes. This process happens with a slight delay to get info from the next resurection to take place
    * @param _tokenId is the id of the phoenix to be reborn
    */
    function resurrect(uint _tokenId) external {

        address sender = _msgSender();

        require(sender == ownerOf(_tokenId), "Only the owner of this token can resurect their phoenix");
        require(allowResurrection == true, "Resurection isn't allowed at this time");

        blazeToken.burn(sender, resurrectCost);

        uint128 hash = generateTraits(_tokenId, sender);

        ResurrectionInfo memory prevRes = previousResurrection;

        if(prevRes.hash != 0) {

            uint128 newHash = uint128(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                block.timestamp,
                                block.difficulty,
                                prevRes.hash,
                                hash,
                                prevRes.tokenId     
                            )
                        )   
                    )
                );

            Phoenix memory phoenix = tokenIdToPhoenix[prevRes.tokenId];

            phoenix.hash = newHash;

            tokenIdToPhoenix[prevRes.tokenId] = phoenix;

        }

        metadataHandler.resurrect(resurrectionId, _tokenId);

        previousResurrection = ResurrectionInfo(_tokenId, hash);

    }

    /**
         ______     ______     ______     _____    
        /\  == \   /\  ___\   /\  __ \   /\  __-.  
        \ \  __<   \ \  __\   \ \  __ \  \ \ \/\ \ 
         \ \_\ \_\  \ \_____\  \ \_\ \_\  \ \____- 
          \/_/ /_/   \/_____/   \/_/\/_/   \/____/ 
                                           
    */
    
    /**
     * @dev Returns metadata for the token by asking for it from the set metadata manager, which generates the metadata all on chain
     * @param _tokenId is the id of the phoenix requesting its metadata.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId));

        Phoenix memory _phoenix = tokenIdToPhoenix[_tokenId];

        MetadataStruct memory metaDataStruct = MetadataStruct(_tokenId,
                        0,
                            6,
                                "5000 Onchain Immortal Phoenix risen from the ashes onto the Ethereum blockchain ready to take nft land by storm.",
                                    "iVBORw0KGgoAAAANSUhEUgAAADAAAAAwAgMAAAAqbBEUAAAAAXNSR0IArs4c6QAAAAxQTFRFAAAAuo+P+vr6/f3+BbtU0AAAAMNJREFUKM+t0b0NwyAQBeBHFBrXQezgKRiBgpOriFHwKC4t78MoqZM7QDaW8tPkWUJ8MveEbDy74A94TDtyzAcoBsvMUeDv3mZKJK/hyJlgyFsBCDoocgUqADcYZwq8gjw6MbRXDhwVBa4CU4UvMAKoawEPMVp4CEemhnHlxTZsW2ko+8syzNxQMcyXReoqAIZ6A3xBVyB9HUZ0x9Zy02OEb9owy2p/oeYjXDfD336HJpr2QyblDuX/tOgTUgd1QuwAxgtmj7BFtSVEWwAAAABJRU5ErkJggg=="
                                        );

        

        string memory metaData = metadataHandler.tokenURI(
            _phoenix,
                metaDataStruct
                    );

        return metaData;

        
    }

    function getLastResurrection() public view returns (ResurrectionInfo memory) {

        return previousResurrection;

    }

    /**
    * @dev returns the total levels of phoenixs a user has, used by the blaze contract to calculate token generation rate
    * @param _userAddress is the address in question
    */
    function getTotalLevels(address _userAddress) external view returns(uint) {

        return addressToLevels[_userAddress];

    }

    /**
     * @dev Returns the info about a given phoenix token
     * @param _tokenId of desired phoenix
    */
    function getPhoenixFromId(uint _tokenId) public view returns(Phoenix memory) {
        require(_tokenId < totalSupply(), "Token id outside range");
        return tokenIdToPhoenix[_tokenId];
    }

    /**
     * @dev Returns an array of token ids the address owns, mainly for frontend use, and helps with limitations set by storing less info
     * @param _addr address of interest
    */
    function getPhoenixesOfAddress(address _addr) public view returns(uint[] memory) {

        uint[] memory tempArray;

        if(addressToLevels[_addr] == 0) {
            return tempArray;
        }

        tempArray = new uint[](addressToLevels[_addr]);
        uint total = 0;
        for(uint i = 0; i < totalSupply(); i++) {
            if(_owners[i] == _addr) {
                tempArray[total] = i;
                total++;
            }
        }

        uint[] memory finalArray = new uint[](total);
        for(uint i = 0; i < total; i++) {
            finalArray[i] = tempArray[i];
        }
        
        return finalArray;

    }


    /**
         ______     __     __     __   __     ______     ______    
        /\  __ \   /\ \  _ \ \   /\ "-.\ \   /\  ___\   /\  == \   
        \ \ \/\ \  \ \ \/ ".\ \  \ \ \-.  \  \ \  __\   \ \  __<   
         \ \_____\  \ \__/".~\_\  \ \_\\"\_\  \ \_____\  \ \_\ \_\ 
          \/_____/   \/_/   \/_/   \/_/ \/_/   \/_____/   \/_/ /_/ 
                                                           
    */

    /**
    * @dev Sets the blaze token contract
    * @param _tokenAddress address of the blaze token
    */
    function setBlazeToken(address _tokenAddress) external onlyOwner {
        blazeToken = IBlazeToken(_tokenAddress);
    }

    /**
    * @dev sets the contract interface to interact with the metadata handler, which generates the phoenixs metadata on chain
    * @param _metaAddress is the address of the metadata handler
    */
    function setMetadataHandler(address _metaAddress) external onlyOwner {
        metadataHandler = IMetadataHandler(_metaAddress);
    }


    /**
    * @dev mint function called once after deploying the contract to reward the teams hard work, 2 will be minted for each team member, to a total of 8
    * @param addresses is an array of addresses of the devs that can mint
    * @param numEach is the number of phoenixs minted per address
    */
    function devMint(address[] calldata addresses, uint numEach) external onlyOwner {

        uint supply = totalSupply();

        require(supply + (addresses.length * numEach) <= 8, "Trying to mint more than you should");

        for(uint i = 0; i < addresses.length; i++) {

            address addr = addresses[i];

            for(uint j = 0; j < numEach; j++) {
                mint(supply, addr);
                supply++;
            }

            addressToLevels[addr] += numEach;

        }

    }

     /**
     * @dev Withdraw ether from this contract to the team for the agreed amounts, only callable by the owner
     */
    function withdraw() external onlyOwner {

        address thisAddress = address(this);

        require(thisAddress.balance > 0, "there is no balance in the address");
        require(payments.length > 0, "havent set the payments");

        for(uint i = 0; i < payments.length; i++) {

            if(thisAddress.balance == 0) {
                return;
            }

            PaymentStruct memory payment = payments[i];

            uint paymentLeft = payment.owed - payment.payed;

            if(paymentLeft > 0) {

                uint amountToPay;

                if(thisAddress.balance >= paymentLeft) {

                    amountToPay = paymentLeft;


                } else {
                    amountToPay = thisAddress.balance;
                }

                payment.payed += amountToPay;
                payments[i].payed = payment.payed;

                payable(payment.membersAddress).transfer(amountToPay);

            } 

        }

        if(thisAddress.balance > 0) {

            payable(payments[payments.length - 1].membersAddress).transfer(thisAddress.balance);
        }
        
    }

    /**
    * @dev sets the root of the merkle tree, used to verify whitelist addresses
    * @param _root the root of the merkle tree
    */
    function setMerkleRoots(bytes32[] calldata _root) external onlyOwner {
        roots = _root;
    }

    /**
    * @dev Lowers the max supply in case minting doesnt sell out
    * @param _newMaxSupply the new, and lower max supply
    */ 
    function lowerMaxSupply(uint _newMaxSupply) external onlyOwner {
        require(_newMaxSupply >= totalSupply());
        require(_newMaxSupply < maxSupply);

        maxSupply = uint16(_newMaxSupply);
    }

    /**
    * @dev toggles the ability for anyone to mint to whitelist only, of vice versa
    */
    function togglePublicMint() external onlyOwner {
        publicMint = !publicMint;
    }

    // @notice Will receive any eth sent to the contract
    receive() external payable {

    }

    /**
    * @dev Reverts the name back to the base initial name, will be used by the team to revert offensive names
    * @param _tokenId token id to be reverted
    */
    function revertName(uint _tokenId) external onlyOwner {

        tokenIdToPhoenix[_tokenId].name = ""; 

    }

    /**
    * @dev Toggle the ability to resurect phoenix tokens and reroll traits
    */
    function toggleResurrection() public onlyOwner {
        allowResurrection = !allowResurrection;
    }

    /**
    * @dev Give out mythics to phoenixs that have resurrected recently
    * @param _numMythics is the number of mythics that will be given out
    */
    function rewardMythics(uint _numMythics) external onlyOwner {

        require(allowResurrection == false, "Need to have resurrection paused mythics are rewarded");
        metadataHandler.rewardMythics(resurrectionId, _numMythics);

        toggleResurrection();

    }

    /**
    * @dev Allows the owner to raise the max level six cap, but only by 100 at a time
    * @param _newMax is the new level six cap to be set
    */
    function raiseMaxLevelSix(uint8 _newMax) external onlyOwner {

        require(_newMax > maxLevelSix, "Need to set the new max to be larger");

        require(_newMax - maxLevelSix <= 100, "Can't raise it by more than 100 at a time");

        maxLevelSix = _newMax;

    }

    function setRessurectionId(uint _id) external onlyOwner {

        resurrectionId = _id;

    } 

    function setBlazeCosts(uint _nameCost, uint _resurrectCost) external onlyOwner {

        nameCost = _nameCost;
        resurrectCost = _resurrectCost;
    }

    /**
         ______     __   __   ______     ______     ______     __     _____     ______    
        /\  __ \   /\ \ / /  /\  ___\   /\  == \   /\  == \   /\ \   /\  __-.  /\  ___\   
        \ \ \/\ \  \ \ \'/   \ \  __\   \ \  __<   \ \  __<   \ \ \  \ \ \/\ \ \ \  __\   
         \ \_____\  \ \__|    \ \_____\  \ \_\ \_\  \ \_\ \_\  \ \_\  \ \____-  \ \_____\ 
          \/_____/   \/_/      \/_____/   \/_/ /_/   \/_/ /_/   \/_/   \/____/   \/_____/ 
                                                                                  
    */

    /**
    * @dev Override the transfer function to update the blaze token contract
    */
    function transferFrom(address from, address to, uint256 tokenId) public override {

        blazeToken.updateTransfer(from, to);

        uint level = uint(tokenIdToPhoenix[tokenId].level);

        addressToLevels[from] -= level;
        addressToLevels[to] += level;

        ERC721Cheap.transferFrom(from, to, tokenId);

    }

    /**
    * @dev Override the transfer function to update the blaze token contract
    */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {


        blazeToken.updateTransfer(from, to);

        uint level = uint(tokenIdToPhoenix[tokenId].level);

        addressToLevels[from] -= level;
        addressToLevels[to] += level;

        ERC721Cheap.safeTransferFrom(from, to, tokenId, _data);

    }

}