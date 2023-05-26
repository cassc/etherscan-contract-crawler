//  This Project is done by Adil & Zohaib 
//  If you have any Queries you can Contact us
//  Adil/ +923217028026 Discord/ ADAM#2595
//  Zohaib/ +923334182339 Discord/ Zohaib saddiqi#4748


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract BuzzardBill is ERC721A("Buzzard Bill", "OJO") {
    string public baseURI = "ipfs://QmeSzRB8c2jb3pD2P5c9HnTSSEJBThHjfdiax1Ykqr4zpP/";
        

    bool public isSaleActive;
    uint256 public itemPrice = 0.04 ether;
    uint256 public itemPricePresale = 0.02 ether;
    uint256 public immutable maxSupply = 10000;

    address public owner = msg.sender;
 
   // internal
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    } 

    ///////////////////////////////
    //    PRESALE CODE STARTS    //
    ///////////////////////////////
    
    bool public isAllowlistActive;
    uint256 public allowlistMaxMint = 3;
    mapping(address => bool) public onAllowlist;
    mapping(address => uint256) public allowlistClaimedBy;

    function addToAllowlist(address[] calldata addresses, bool _add)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++)
            onAllowlist[addresses[i]] = _add;
    }

    // Purchase multiple NFTs at once
    function purchasePresaleTokens(uint256 _howMany)
        external
        payable
        tokensAvailable(_howMany)
    {
        require(isAllowlistActive, "Allowlist is not active");
        require(
            allowlistClaimedBy[msg.sender] + _howMany <= allowlistMaxMint,
            "Purchase exceeds max allowed"
        );
        require(
            msg.value >= _howMany * itemPricePresale,
            "Try to send more ETH"
        );

        allowlistClaimedBy[msg.sender] += _howMany;

        _safeMint(msg.sender, _howMany);
    }

    // set limit of allowlist
    function setAllowlistMaxMint(uint256 _allowlistMaxMint) external onlyOwner {
        allowlistMaxMint = _allowlistMaxMint;
    }

    // Change presale price in case of ETH price changes too much
    function setPricePresale(uint256 _itemPricePresale) external onlyOwner {
        itemPricePresale = _itemPricePresale;
    }

    function setIsAllowlistActive(bool _isAllowlistActive) external onlyOwner {
        isAllowlistActive = _isAllowlistActive;
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
        require(_howMany > 0 && _howMany <= 20, "Mint min 1, max 20");
        require(msg.value >= _howMany * itemPrice, "Try to send more ETH");

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
        return maxSupply - totalSupply() - 1000; // reserve 1000 mints for the team
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

    ///////////////////////////
    // AUTO APPROVE OPENSEA  //
    ///////////////////////////

    // Opensea Registerar Mainnet 0xa5409ec958C83C3f309868babACA7c86DCB077c1
    // Opensea Registerar Rinkeby 0xF57B2c51dED3A29e6891aba85459d600256Cf317
    address openSeaRegistrar = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool)
    {
        if (ProxyRegisterar(openSeaRegistrar).proxies(_owner) == _operator)
            return true;

        return super.isApprovedForAll(_owner, _operator);
    }

    // infuture address changes for opensea registrar
    function editOpenSeaRegisterar(address _openSeaRegistrar)
        external
        onlyOwner
    {
        openSeaRegistrar = _openSeaRegistrar;
    }

    // just in case openSeaRegistrar is not present we use this contract
    function proxies(address) external pure returns (address) {
        return address(0);
    }

    ////////////////////////////
    // Merkle tree whitelist  //
    ////////////////////////////

    bytes32 public whitelistMerkleRoot;

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot)
        external
        onlyOwner
    {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function inWhitelist(bytes32[] memory _proof, address _owner)
        external
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                _proof,
                whitelistMerkleRoot,
                keccak256(abi.encodePacked(_owner))
            );
    }

    // Purchase multiple NFTs at once
    function purchasePresaleTokensMerkle(
        uint256 _howMany,
        bytes32[] calldata proof
    ) external payable tokensAvailable(_howMany) {
        require(isAllowlistActive, "Allowlist is not active");

        require(
            MerkleProof.verify(
                proof,
                whitelistMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "You are not in allowlist"
        );

        require(
            allowlistClaimedBy[msg.sender] + _howMany <= allowlistMaxMint,
            "Purchase exceeds max allowed"
        );
        require(
            msg.value >= _howMany * itemPricePresale,
            "Try to send more ETH"
        );

        allowlistClaimedBy[msg.sender] += _howMany;

        _safeMint(msg.sender, _howMany);
    }
}

interface ProxyRegisterar {
    function proxies(address) external view returns (address);
}