// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
contract BeardedBuddies is 
    ERC721, 
    ERC721Enumerable, 
    ERC721URIStorage, 
    Pausable, 
    Ownable,
    VRFConsumerBaseV2 {

        using Counters for Counters.Counter;

        /** Interface **/
        VRFCoordinatorV2Interface COORDINATOR;

        Counters.Counter private _tokenIdCounter;
        uint256 public cost = 80000000000000000;
        uint256 public preSaleCost = 60000000000000000;
        uint256 public ogCost = 60000000000000000;
        uint256 public maxSupply = 10000;
        uint256 public maxMint = 6;
        uint256 public maxMintWhitelist = 10; 
        uint256 public requestId;
        uint256 public randomNumber;
        uint64 s_subscriptionId;
        uint32 public callbackGasLimit;
        uint16 requestConfirmations;
        uint private beardedBuddyDNA;
        bytes32 internal keyHash;
        address public VRFCoordinator;
        address public multiSig;
        string public beardedBaseURI;

        
        BeardedBuddy[] private beardedBuddies;

        /** Events **/
        event BeardedBuddyRequested(uint256 _requestbeardedBuddyId);
        event ethWithdrawn();
        event createdBeardedBuddy(string _message , uint256 _tokenID , uint256 _randomNumber);
        event imagesRevealed();

        /** Mappings **/
        mapping(uint256 => address) requestToSender;
        mapping(address => uint256) public addressBuddyBalance;
        mapping(address => bool) public whitelistStatus;
        mapping(address => bool) public whitelistOGStatus;
        
        /** Structs */
        struct BeardedBuddy {
           uint dna; 
           uint id;
        }

        constructor (address _VRFCoordinator,
                     bytes32 _keyhash, 
                     address _multiSig, 
                     uint64 _subscriptionId,
                     uint32 _callbackgasLimit,
                     uint16 _requestConfirmations) 
        ERC721("BeardedBuddies", "BBD")
        VRFConsumerBaseV2(_VRFCoordinator) {
            VRFCoordinator = _VRFCoordinator;
            COORDINATOR = VRFCoordinatorV2Interface(VRFCoordinator);
            keyHash = _keyhash;
            callbackGasLimit = _callbackgasLimit ;
            requestConfirmations = _requestConfirmations;
            multiSig = _multiSig;
            s_subscriptionId = _subscriptionId;
        }

        function pause() public onlyOwner {
            _pause();
        }

        function unpause() public onlyOwner {
            _unpause();
        }

        /**
         * Request Creation
         * @notice             For the given number of tokens mints the bearded buddies
         * @param _numberOfBeardedBuddies the number of tokens to be minted
         */
        function requestCreation(uint32 _numberOfBeardedBuddies ) public payable {

            uint256 mintingPrice = getMintingPrice(msg.sender);
            uint256 totalMintAmount = mintingPrice * _numberOfBeardedBuddies;
            uint256 mintLimit = getMintingLimit(msg.sender);
            require(msg.value >= totalMintAmount , "Insufficient funds");
            require(totalSupply() + _numberOfBeardedBuddies  <= maxSupply, "Max buddies limit exceeded");
            require(_numberOfBeardedBuddies > 0, "Need to mint at least 1 buddy");
            if(!(msg.sender == multiSig)){
            require(addressBuddyBalance[msg.sender] <= mintLimit, "You have reached your limit");
            }
            for(uint i = 0; i < _numberOfBeardedBuddies; i++) {
                if (totalSupply() < maxSupply) {
                generateBeardedBuddy();
                }
            }

        }

         /**
         * GenerateBearded Buddy
         * @notice             Request the random number to the coordinator emits a request event
         */
	    function generateBeardedBuddy() internal  {

            requestId = COORDINATOR.requestRandomWords(keyHash,
                                                        s_subscriptionId,
                                                        requestConfirmations,
                                                        callbackGasLimit,
                                                        1);
            requestToSender[requestId] = msg.sender;
            addressBuddyBalance[msg.sender]++;
            emit BeardedBuddyRequested(requestId);

	    }
         /**
         * FulfillRandomWords
         * @notice Chainlinks callback function with the random number
         * @param _randomWords the random numbers
         * @param _requestId the requestID from the generation function
        */
        function fulfillRandomWords(    
            uint256 _requestId,
            uint256[] memory _randomWords
            ) internal override {
        
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();

            randomNumber = _randomWords[0];
            uint256 dna = (randomNumber % 10 ** 26);
            BeardedBuddy memory beardedBuddy = BeardedBuddy(dna,tokenId);
            string memory newTokenURI =  string.concat(Strings.toString(tokenId),".json");
            safeMint(requestToSender[_requestId], newTokenURI, tokenId);
            beardedBuddies.push(beardedBuddy);
            emit createdBeardedBuddy("Bearded Buddy has been minted",tokenId, dna);
         }


         /**
         * SafeMint
         * @notice          Mints the token internally using the standard methods and sets the token URI
         * @param _to       the address that will receive the token
         * @param _uri      the URI of the token
         * @param _tokenId  the Token ID
         * 
         */
        function safeMint(address _to,
                          string memory _uri, 
                          uint256 _tokenId) 
                          internal 
        {
            _safeMint(_to, _tokenId);
            _setTokenURI(_tokenId, _uri);
        }


         /**
         * GetBeardedBuddyDNA
         * @notice             returns the minting price from an specific address
         * @param _tokenId       the address that will be requested to view the price
         * @return    returns the mint price depending on the whitelist tier
         */
        function getBeardedBuddyDNA(uint256 _tokenId) 
                    public 
                    view 
                    returns (uint256) 
        {
            return (
            beardedBuddies[_tokenId].dna
            );
        }
       
        /**
         * GetMintingPrice
         * @notice             returns the minting price from an specific address
         * @param _wallet       the address that will be requested to view the price
         * @return     returns the mint price depending on the whitelist tier
         */
        function getMintingPrice(address _wallet) 
                public 
                view 
                returns (uint256) 
        {
            if (_wallet == multiSig){
                 return 0;
                }
            else if (whitelistStatus[_wallet]) {
                return preSaleCost;
            }
            else if (whitelistOGStatus[_wallet]) {
                return ogCost;
            }  
            else {
                return cost;
            }
        }

       /**
        * GetMintingLimit
         * @notice             returns the limit for an specific address
        * @param _wallet       the address that will be requested to view the limit
        * @return    returns the mint limit depending on the whitelist tier
         */
        function getMintingLimit(address _wallet) 
                public 
                view 
                returns (uint256) 
        {

            if (_wallet == multiSig){
                return 300;
                }
            else  if (whitelistStatus[_wallet]){
                return maxMintWhitelist;
                }
            else  if (whitelistOGStatus[_wallet]){
                return maxMint;
                } 
            else {
                return maxMint;
            }
        }

        /**
        * WithdrawEth
        * @notice      Sends Ether from the NFT contract to the Multi-Sig Wallet
        */
        function withdraw() 
            external 
            payable 
            onlyOwner 
        {
            emit ethWithdrawn();
            payable(multiSig).transfer(address(this).balance);
		    return ;
         }
        /**
        * Override baseURI method
        * @notice             Overrides the baseURI Method for a custom implementation
        */
        function _baseURI() 
            internal 
            view 
            override 
            returns (string memory) 
        {
            return beardedBaseURI;
        }

        /**
        * SetBaseURI
        * @notice             Updates the token Base URI
        * @param _newBaseURI  the new baseURI
        */
        function setBaseURI(string memory _newBaseURI) 
                internal 
        {
            beardedBaseURI = _newBaseURI;
        }
        /**
         * _beforeTokenTransfer implementation
         *           
         */
        function _beforeTokenTransfer(address from, 
                                        address to, 
                                        uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
        {
            super._beforeTokenTransfer(from, to, tokenId);
        }

        /**
        * BeardedBuddies in Wallet
        * @notice             returns the list of all owned tokens from an specific address
        * @param  _wallet      the address to be checked
        * @return tokenIds    the list of tokens owned by the address
        */
        function walletOfOwner(address _wallet) 
            public view 
            returns (uint256[] memory){
                uint256 ownerTokenCount = balanceOf(_wallet);
                uint256[] memory tokenIds = new uint256[](ownerTokenCount);
                for (uint256 i; i < ownerTokenCount; i++) {
                tokenIds[i] = tokenOfOwnerByIndex(_wallet, i);
                }       
        return tokenIds;
        }
        /**
        * Reveal Images
        * @notice     reveals the image by updating the Base URI         
        */
        function revealImages(string memory _newBaseURI) 
                 public 
                 onlyOwner
        {
            setBaseURI(_newBaseURI);
            emit imagesRevealed();
         }

        /**
        * WhitelistAddresses
        * @notice             adds the list of address with the whitelist status to the mapping
        * @param  _whitelistAddresses      the address be whitelisted
        * @param _whitelisted the boolean status of the whitelist for the address
        */
        function whitelistAddresses(address[] memory _whitelistAddresses,
                                    bool _whitelisted) 
                 public 
                 onlyOwner 
        {
            for (uint256 account = 0; account < _whitelistAddresses.length; account++) {
                whitelistStatus[_whitelistAddresses[account]] = _whitelisted;
                }
        }

        /**
        * WhitelistOGAddresses
        * @notice             adds the list of OG address with the whitelist status to the mapping
        * @param  _whitelistAddresses      the address be whitelisted
        * @param _whitelisted the boolean status of the whitelist for the address
        */
        function whitelistOGAddresses(address[] memory _whitelistAddresses,
                                      bool _whitelisted) 
                 public 
                onlyOwner 
        {
            for (uint256 account = 0; account < _whitelistAddresses.length; account++) {
                whitelistOGStatus[_whitelistAddresses[account]] = _whitelisted;
                }
        }
        /**
        * UpdateMultiSigAddress
        * @notice             Updates the multisig address
        * @param  _newMultisig      The new multisig address
        */
        function updateMultisigAddress(address _newMultisig) 
                 public 
                onlyOwner 
        {
          multiSig = _newMultisig;
        }
         /**
        * UpdatekeyHash
        * @notice             Updates the keyhash for optimization
        * @param  _keyHash      The new keyhash for optimization
        */
        function updateKeyHash(bytes32 _keyHash) 
                 public 
                onlyOwner 
        {
          keyHash = _keyHash;
        }
        // The following functions are overrides required by Solidity.

        function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
            super._burn(tokenId);
        }

        function tokenURI(uint256 tokenId)
            public
            view
            override(ERC721, ERC721URIStorage)
            returns (string memory)
        {
            return super.tokenURI(tokenId);
        }


        function supportsInterface(bytes4 interfaceId)
            public
            view
            override(ERC721, ERC721Enumerable)
            returns (bool)
        {
            return super.supportsInterface(interfaceId);
        }
    }