// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./SmashMarblesStorageV1.sol";

contract SmashMarblesArenaV1 is SmashMarblesStorageV1 {
    using StringsUpgradeable for uint256;

    /**
     * @dev initialize erc721 token and ownable
     *      sets beforeuri,afteruri,tokenvalue,
     *      tokencounter,maxNFTs and maxMarbleLimit
     */
    function initialize() public initializer {
        __ERC721_init("Smash Marbles Arena", "SMA");
        __Ownable_init();

        beforeUri = "https://smashmarbles-assets.s3.us-east-1.amazonaws.com/token-uri/";
        afterUri = "-token-uri.json";

        COMMUNITY_WALLET = 0xc582776248facE7104118708d49a4F7bf56874FF; // community wallet

        marblePrice = 1000000000000000;         //50000000000000000;
        arenaPrice = 2000000000000000;          //125000000000000000;

        maxArenaNFTs = 500;
        tokenCounter = 500;
        maxNFTs = 9800;
        
        Marblebundle = [1,2];
        arenaSale = true;
        whiteListSale = true;

        whitelistedAddress[0x8711142D476E385097e168Fd836Bfcb4cEEC70EF] = true;
    }

    /**
     * @dev modifier that check address is black listed or not
     *      if address address black listed then function failed
     */
    modifier isblacklistedAddresses() {
        require(
            blacklistedAddress[msg.sender] == false,
            "SmashMarblesArenaV1: You are blacklisted"
        );
        _;
    }

    /**
     * @dev for upadate default uri of tokens(beforeUri and afterUri)
     *
     * @param _before before uri
     * @param _after after uri
     *
     * Requirement : -
     *              only contract owner can call
     */
    function updateDefaultUri(string memory _before, string memory _after)
        external
        virtual
        onlyOwner
    {
        beforeUri = _before; // update the before uri for MPI
        afterUri = _after; // update the after uri for MPI
    }
    
    /**
     * @dev upadate token uri of previous minted tokens using token id
     *
     * @param id token id
     *
     * Requirement : -
     *              only contract owner can call
     */
    function updateTokenURI(uint256 id) external virtual onlyOwner {
        string memory _uri = uriConcate(beforeUri, id, afterUri);
        _setTokenURI(id, _uri);
    }

    /**
     * @dev upadate community wallet
     *
     * @param _wallet community wallet address
     *
     * Requirement : -
     *              only contract owner can call
     */
    function updateCommunityWallet(address _wallet) external virtual onlyOwner {
        COMMUNITY_WALLET = _wallet;
    }

    /**
     * @dev upadate max NFT limit of tokens that available for mint
     *
     * @param _value amount of tokens that need to increase
     *
     * Requirement : -
     *              only contract owner can call
     */
    function increaseMarbleNFT(uint256 _value) external virtual onlyOwner {
        maxNFTs += _value;
    }

    /**
     * @dev minting NFT using for loop with token amount
     *      check arena sale ,white list and public sale
     *      check all token conditions and price of token with discount
     *
     * @param noOfTokens  tokens number that user wants mint
     *
     * Event -
     *       emit AssertMinted event on succesful minting
     *       event contains user address and token ids in array
     */
    function buyMarbleNFT(uint256 noOfTokens)
        external
        payable
        virtual
        nonReentrant
        isblacklistedAddresses
    {
        require(
            (whiteListSale==true||publicSale==true),
            "SmashMarblesArenaV1:Only Arena Minting available"
        );
        if (whiteListSale) {
            require(
                whitelistedAddress[msg.sender],
                "SmashMarblesArenaV1: You are not eligible for whitelist minting"
            );
        }
        require(
            (noOfTokens + tokenCounter) <= maxNFTs,
            "SmashMarblesArenaV1: NFTs not available for minting"
        );

        require(
            !AddressUpgradeable.isContract(COMMUNITY_WALLET),
            "SmashMarblesArenaV1: Invalid merchant wallet address"
        );

        uint256 MarbleBalance = MarblesBalance(msg.sender);
        require(
            (MarbleBalance + noOfTokens) <= maxMarbleLimit,
            "SmashMarblesArenaV1: Exceeded max limit of tokens by user"
        );
        require(
            (noOfTokens == Marblebundle[0] || noOfTokens == Marblebundle[1]),
            "SmashMarblesArenaV1: Invaild number of tokens"
        );
        uint256 value = marblePrice * noOfTokens;
        if (noOfTokens == Marblebundle[1]) {
            value = (value * (1000 - publicSalePercentDiscount)) / 1000;
        }

        require(value == msg.value, "SmashMarblesArenaV1:Invaild price");

        payable(COMMUNITY_WALLET).transfer(msg.value);

        delete tokenArray;
        for (uint256 i = 1; i <= noOfTokens; i++) {
            tokenCounter++;
            _mintFor(msg.sender, tokenCounter);
            tokenArray.push(tokenCounter);
        }
        emit AssertMinted(msg.sender, tokenArray);
    }

    /**
     * @dev minting Arena token only one at a time
     *      check arena sale
     *      check all token conditions and price of token
     *
     * No parameter  only single arena mint
     *
     * Event -
     *       emit ArenaMinted event on succesful minting
     *       event contains user address and arena token id
     */
    function buyArenaNFT()
        external
        payable
        virtual
        nonReentrant
        isblacklistedAddresses
    {
        require(
            arenaSale == true,
            "SmashMarblesArenaV1:Arena Minting not started"
        );

        require(
            ArenaCounter <= maxArenaNFTs,
            "SmashMarblesArenaV1:Arena max limit exceeded"
        );

        require(
            arenaPrice == msg.value,
            "SmashMarblesArenaV1:Token price incorrect"         
        );

        require(
            !AddressUpgradeable.isContract(COMMUNITY_WALLET),
            "SmashMarblesArenaV1: Invalid merchant wallet address"
        );

        payable(COMMUNITY_WALLET).transfer(msg.value);

        ArenaCounter++;
        _mintFor(msg.sender, ArenaCounter);
        arenaBalance[msg.sender]++;

        rewardIds[msg.sender].push(ArenaCounter);
        reward memory _data = reward(msg.sender, false);
        rewardClaimed[ArenaCounter] = _data;
        emit ArenaMinted(msg.sender, ArenaCounter);
    }

    /**
     * @dev minting NFT when public sale is on for the user who has
     * reward in their balance. Only the users who has minted Arena
     * NFT can claim their token id reward.
     *
     * @param _id  tokenId for which reward has to claimed.
     *
     * Event -
     *       emit ClaimedNft event on succesful minting
     *       event contains user address and new token id and _id.
     */

    function claimNft(uint256 _id) external virtual isblacklistedAddresses {
        require(
            publicSale == true,
            "SmashMarblesArenaV1: public sale is closed"
        );

        require(
            !rewardClaimed[_id].isClaimed &&
                rewardClaimed[_id].user == msg.sender,
            "SmashMarblesArenaV1: No reward for user or already claimed"
        );
        tokenCounter++;
        _mintFor(msg.sender, tokenCounter);

        rewardClaimed[_id].isClaimed = true;

        emit ClaimedNft(msg.sender, tokenCounter, _id);
    }

    /**
     * @dev minting NFT when public sale is on for the user who has
     * reward in their balance. Only the users who has minted Arena
     * NFT can claim their token id reward. This function can claim
     * multiple NFT reward in one transaction.
     *
     * @param _id  tokenIds for which reward has to claimed.
     *
     * Event -
     *       emit ClaimedAllNft event on succesful minting
     *       event contains user address and arry of new token id and _id.
     */
    function claimAllNft(uint256[] calldata _id)
        external
        virtual
        isblacklistedAddresses
    {
        require(
            publicSale == true,
            "SmashMarblesArenaV1: public sale is closed"
        );

        delete tokenArray;
        delete tempId;

        for (uint256 i = 0; i < _id.length; i++) {
            require(
                !rewardClaimed[_id[i]].isClaimed &&
                    rewardClaimed[_id[i]].user == msg.sender,
                "SmashMarblesArenaV1: No reward for user or already claimed"
            );
            tokenCounter++;

            _mintFor(msg.sender, tokenCounter);

            rewardClaimed[_id[i]].isClaimed = true;

            tokenArray.push(tokenCounter);
            tempId.push(_id[i]);
        }

        emit ClaimAllNft(msg.sender, tokenArray, tempId);
    }

    /**
     * @dev Airdrop where the 1 NFT is minted for the listed addresses.
     *
     * @param _addresses array of addresses
     *
     * Event -
     *       emit AirDropMarbles event on succesful minting
     *       event contains array of user addresses and array of new token id.
     */
    function airDropMarbles(address[] calldata _addresses)
        external
        virtual
        onlyOwner
    {
        delete tempAddress;
        delete tokenArray;
        for (uint256 i = 0; i < _addresses.length; i++) {
            tokenCounter += 1;
            _mintFor(_addresses[i], tokenCounter);

            tempAddress.push(_addresses[i]);
            tokenArray.push(tokenCounter);
        }
        emit AirDropMarbles(tempAddress, tokenArray);
    }

    /**
     * @dev change one sale to other sale
     *      update price and nft limit according to sale
     *      update percent discount of price
     *
     * @param _whitelistStatus for white list and public sale , @param _arenaSaleStatus for arena sale
     * @param _maxMarbleLimit max limit of one to buy nft in a sell
     * @param _marblebundle bundle package according to sale
     * @param _marblePrice one token price in wei, @param _publicSalePercentDiscount percent discount
     *
     * Requirement : -
     *              only contract owner can call
     */
    function updateSale(
        bool _whitelistStatus,
        bool _arenaSaleStatus,
        bool _publicSaleStatus,
        uint256 _maxMarbleLimit,
        uint256[2] memory _marblebundle,
        uint256 _arenaPrice,
        uint256 _marblePrice,
        uint256 _publicSalePercentDiscount
    ) external virtual onlyOwner {
        maxMarbleLimit = _maxMarbleLimit;
        marblePrice = _marblePrice;
        arenaPrice=_arenaPrice;
        Marblebundle = _marblebundle;
        whiteListSale = _whitelistStatus;
        publicSale = _publicSaleStatus;
        arenaSale = _arenaSaleStatus;
        publicSalePercentDiscount = _publicSalePercentDiscount;
    }

    /**
     * @dev use to add or remove from white list address in array
     *
     * @param _addresses white list user's addresses in array
     * @param _status true for add user and false to remove user from whitelist
     *
     * Requirement : -
     *              only contract owner can call
     */
    function wihtelistAddress(address[] calldata _addresses, bool _status)
        external
        virtual
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelistedAddress[_addresses[i]] = _status;
        }

        emit WhiteListed(_addresses, _status);
    }

    /**
     * @dev use to add or remove from black list address
     *
     * @param _address user's address
     * @param _status true for add user and false to remove user from balck list
     *
     * Requirement : -
     *              only contract owner can call
     */
    function blacklistAddress(address _address, bool _status)
        external
        virtual
        onlyOwner
    {
        blacklistedAddress[_address] = _status;
    }

    /**
     * @dev use to get marble bundle in array of size two
     *
     * Return :-
     *        Array of marble bundle of size two
     */
    function getMarblebundle()
        external
        view
        virtual
        returns (uint256[2] memory)
    {
        return Marblebundle;
    }

    /**
     * @dev use to get marble balance of a user
     *
     * @param _address wallet address of user
     *
     * Return :-
     *        marble balance of user in integer form
     */
    function MarblesBalance(address _address)
        public
        view
        virtual
        returns (uint256 marbleBalance)
    {
        marbleBalance = (balanceOf(_address) - arenaBalance[_address]);
    }


    /**
     *  @dev see {ERC721 openzeppelin approve function}
     *       added blacklist functionality
     */
    function approve(address to, uint256 tokenId) public virtual override {
        require(
            blacklistedAddress[to] == false,
            "SmashMarblesArenaV1: Owner is blacklisted"
        );
        require(
            blacklistedAddress[msg.sender] == false,
            "SmashMarblesArenaV1: Owner is blacklisted"
        );

        address NFTowner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != NFTowner, "ERC721: approval to current owner");
        require(
            _msgSender() == NFTowner ||
                isApprovedForAll(NFTowner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }

    /**
     *  @dev see {ERC721 openzeppelin setApprovalForAll function}
     *       added blacklist functionality
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(
            blacklistedAddress[msg.sender] == false,
            "SmashMarblesArenaV1: Owner is blacklisted"
        );
        require(
            blacklistedAddress[operator] == false,
            "SmashMarblesArenaV1: Operator is blacklisted"
        );
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     *  @dev see {ERC721 openzeppelin transferFrom function}
     *       added blacklist functionality
     *       added Arena balance count functionality
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(
            blacklistedAddress[from] == false,
            "SmashMarblesArenaV1: Sender is blacklisted"
        );
        require(
            blacklistedAddress[to] == false,
            "SmashMarblesArenaV1: Reciver is blacklisted"
        );

        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _transfer(from, to, tokenId);

        if (tokenId <= 500) {
            arenaBalance[from] -= 1;
            arenaBalance[to] += 1;
        }
    }

    /**
     *  @dev see {ERC721 openzeppelin safeTransferFrom function}
     *       added blacklist functionality
     *       added Arena balance count functionality
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            blacklistedAddress[from] == false,
            "SmashMarblesArenaV1: Sender is blacklisted"
        );
        require(
            blacklistedAddress[to] == false,
            "SmashMarblesArenaV1: Reciver is blacklisted"
        );

        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
        if (tokenId <= 500) {
            arenaBalance[from] -= 1;
            arenaBalance[to] += 1;
        }
    }

    /**
     * @dev add before uri , token id and after uri then get single token uri
     *      private method only internal use
     *
     * Retrun : - token uri of a token
     */
    function uriConcate(
        string memory _before,
        uint256 _token_id,
        string memory _after
    ) private pure returns (string memory) {
        string memory token_uri = string(
            abi.encodePacked(_before, _token_id.toString(), _after)
        );
        return token_uri;
    }

    /**
     * @dev helper function for mint NFT
     *      internal function
     */
    function _mintFor(address user, uint256 id) internal {
        _safeMint(user, id, "");
        string memory _uri = uriConcate(beforeUri, id, afterUri);
        _setTokenURI(id, _uri);
    }
}