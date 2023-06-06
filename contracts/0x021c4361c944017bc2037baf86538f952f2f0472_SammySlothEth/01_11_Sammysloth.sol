//  This Project is done by Adil & Zohaib 
//  If you have any Queries you can Contact us
//  Adil/ +923217028026 Discord/ ADAM#2595
//  Zohaib/ +923334182339 Discord/ Zohaib saddiqi#4748

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "[email protected]/contracts/ERC721A.sol";

interface OpenSea {
    function proxies(address) external view returns (address);
}

contract SammySlothEth is ERC721A("Sammy Sloth ETH", "SSETH"){
    string public baseURI = "ipfs://QmbxSgaer74CAa8rnDwMg2dAkTQKEZeYsXJBsXjbv3kugo/";
        

    bool public isSaleActive;
    uint256 public itemPrice = 0 ether;
    uint256 public immutable maxSupply = 10000;
    uint256 public nftPerAddressLimit = 1;
    mapping(address => uint256) public addressMintedBalance;

    address public owner = msg.sender;
 
   // internal
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    } 

    ///////////////////////////////////
    //    PUBLIC SALE CODE STARTS    //
    ///////////////////////////////////

    // Purchase multiple NFTs at once
    function purchaseTokens(uint256 _howMany)
        external
        payable
        tokensAvailable(_howMany)
    {
        require(isSaleActive, "Sale is not active");
        require(_howMany > 0, "Mint min 1");
        require(msg.value >= _howMany * itemPrice, "Try to send more ETH");

        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + _howMany <= nftPerAddressLimit, "max NFT per address exceeded");

        _safeMint(msg.sender, _howMany);
    }

    //////////////////////////
    // ONLY OWNER METHODS   //
    //////////////////////////

    // Owner can withdraw from here
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(owner).transfer(balance);
    }

    // Change price in case of ETH price changes too much
    function setPrice(uint256 _newPrice) external onlyOwner {
        itemPrice = _newPrice;
    }

    function setSaleActive(bool _isSaleActive) external onlyOwner {
        isSaleActive = _isSaleActive;
    }

    // Hide identity or show identity from here
    function setBaseURI(string memory __baseURI) external onlyOwner {
        baseURI = __baseURI;
    }

    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }

    ///////////////////////////////////
    //       AIRDROP CODE STARTS     //
    ///////////////////////////////////

    // Send NFTs to a list of addresses
    function giftNftToList(address[] calldata _sendNftsTo, uint256 _howMany)
        external
        onlyOwner
        tokensAvailable(_sendNftsTo.length)
    {
        for (uint256 i = 0; i < _sendNftsTo.length; i++)
            _safeMint(_sendNftsTo[i], _howMany);
    }

    // Send NFTs to a single address
    function giftNftToAddress(address _sendNftsTo, uint256 _howMany)
        external
        onlyOwner
        tokensAvailable(_howMany)
    {
        _safeMint(_sendNftsTo, _howMany);
    }

    ///////////////////
    // QUERY METHOD  //
    ///////////////////

    function tokensRemaining() public view returns (uint256) {
        return maxSupply - totalSupply() - 100; // reserve 100 mints for the team
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }


    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++)
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);

        return tokenIds;
    }

     function tokenOfOwnerByIndex(address _owner, uint256 index) public view returns (uint256) {
        if (index >= balanceOf(_owner)) revert();
        uint256 numMintedSoFar = _currentIndex;
        uint256 tokenIdsIdx;
        address currOwnershipAddr;
        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.burned) continue;
                if (ownership.addr != address(0)) currOwnershipAddr = ownership.addr;
                if (currOwnershipAddr == _owner) {
                    if (tokenIdsIdx == index) return i;
                    tokenIdsIdx++;
                }
            }
        }
        revert();
    }

    ///////////////////
    //  HELPER CODE  //
    ///////////////////

    modifier tokensAvailable(uint256 _howMany) {
        require(_howMany <= tokensRemaining(), "Try minting less tokens");
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    //////////////////////////////
    // WHITELISTING FOR STAKING //
    //////////////////////////////

    // tokenId => staked (yes or no)
    mapping(address => bool) public whitelisted;

    // add / remove from whitelist who can stake / unstake
    function addToWhitelist(address _address, bool _add) external onlyOwner {
        whitelisted[_address] = _add;
    }

    modifier onlyWhitelisted() {
        require(whitelisted[msg.sender], "Caller is not whitelisted");
        _;
    }

    /////////////////////
    // STAKING METHOD  //
    /////////////////////

    mapping(uint256 => bool) public staked;

    function _beforeTokenTransfers(
        address,
        address,
        uint256 startTokenId,
        uint256 quantity
    ) internal view override {
        for (uint256 i = startTokenId; i < startTokenId + quantity; i++)
            require(!staked[i], "Unstake tokenId it to transfer");
    }

    // stake / unstake nfts
    function stakeNfts(uint256[] calldata _tokenIds, bool _stake)
        external
        onlyWhitelisted
    {
        for (uint256 i = 0; i < _tokenIds.length; i++)
            staked[_tokenIds[i]] = _stake;
    }

    ///////////////////////////////
    // AUTO APPROVE MARKETPLACES //
    ///////////////////////////////

    mapping(address => bool) projectProxy;

    function flipProxyState(address proxyAddress) external onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
        return
            projectProxy[_operator] || // Auto Approve any Marketplace,
                _operator == OpenSea(0xa5409ec958C83C3f309868babACA7c86DCB077c1).proxies(_owner) ||
                _operator == 0xF849de01B080aDC3A814FaBE1E2087475cF2E354 || // Looksrare
                _operator == 0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e || // Rarible
                _operator == 0x4feE7B061C97C9c496b01DbcE9CDb10c02f0a0Be // X2Y2

                ? true
                : super.isApprovedForAll(_owner, _operator);
    }
}