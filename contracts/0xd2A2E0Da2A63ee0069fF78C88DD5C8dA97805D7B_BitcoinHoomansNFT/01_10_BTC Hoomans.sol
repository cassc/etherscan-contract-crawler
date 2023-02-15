//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "contracts/DefaultOperatorFilterer.sol";

/*

Bitcoin Hoomans NFT New Contract.sol
Bitcoin Hoomans are the first ever BTC x ETH hybird PFP Collection launching in ETH which gets will be inscribed below 5 digit in the Ordinal Chain which is called as BTC NFTs
Helping you gets the piece of history in bitcoin blockchain

*/

contract BitcoinHoomansNFT is Ownable, DefaultOperatorFilterer, ERC721A {
    uint256 public MAX_SUPPLY = 1000;
    uint256 public TEAM_MINT_MAX = 2;

    uint256 public publicPrice = 0.0125 ether;

    uint256 public PUBLIC_MINT_LIMIT_TXN = 4;
    uint256 public PUBLIC_MINT_LIMIT = 8;

    uint256 public TOTAL_SUPPLY_TEAM;

    string public revealedURI;

    string public hiddenURI = "https://bafybeidsstdcom6ojlqsexyi3efgmbr6drx5257pvftg7u5gxkce4lee2y.ipfs.nftstorage.link/";
    
    // OpenSea CONTRACT_URI - https://docs.opensea.io/docs/contract-level-metadata
    string public CONTRACT_URI = "https://bafybeidsstdcom6ojlqsexyi3efgmbr6drx5257pvftg7u5gxkce4lee2y.ipfs.nftstorage.link/";

    bool public paused = false;
    bool public revealed = false;

    bool public freeSale = true;
    bool public publicSale = false;

    address constant internal FOUNDER_ADDRESS = 0x71A3C80dA4d1Bc4887Ee63811747F2085Ec5D9aD;
    address public teamWallet = 0x71A3C80dA4d1Bc4887Ee63811747F2085Ec5D9aD;

    mapping(address => bool) public userMintedFree;
    mapping(address => uint256) public numUserMints;

    constructor() ERC721A("BitcoinHoomansNFTs", "BTCHOOM") { }

    /*
     *
     Private Function                                                                                                                               
    *
    */

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function refundOverpay(uint256 price) private {
        if (msg.value > price) {
            (bool succ, ) = payable(msg.sender).call{
                value: (msg.value - price)
            }("");
            require(succ, "Transfer failed");
        }
        else if (msg.value < price) {
            revert("Not enough ETH sent");
        }
    }

    /*
     *
     Public Function
    *
    */

    function teamMint(uint256 quantity) public payable mintCompliance(quantity) {
        require(msg.sender == teamWallet, "Team minting only");
        require(TOTAL_SUPPLY_TEAM + quantity <= TEAM_MINT_MAX, "No team mints left");
        require(totalSupply() >= 200, "Team mints after free");

        TOTAL_SUPPLY_TEAM += quantity;

        _safeMint(msg.sender, quantity);
    }
    
    function freeMint(uint256 quantity) external payable mintCompliance(quantity) {
        require(freeSale, "Free sale inactive");
        require(msg.value == 0, "This phase is free");
        require(quantity == 1, "Only 1 free");

        uint256 newSupply = totalSupply() + quantity;
        
        require(newSupply <= 200, "Not enough free supply");

        require(!userMintedFree[msg.sender], "User max free limit");
        
        userMintedFree[msg.sender] = true;

        if(newSupply == 200) {
            freeSale = false;
            publicSale = true;
        }

        _safeMint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable mintCompliance(quantity) {
        require(publicSale, "Public sale inactive");
        require(quantity <= PUBLIC_MINT_LIMIT_TXN, "Quantity too high");

        uint256 price = publicPrice;
        uint256 currMints = numUserMints[msg.sender];
                
        require(currMints + quantity <= PUBLIC_MINT_LIMIT, "User max mint limit");
        
        refundOverpay(price * quantity);

        numUserMints[msg.sender] = (currMints + quantity);

        _safeMint(msg.sender, quantity);
    }

    /*
     *
     View Function
    *
    */

    function walletOfOwner(address _owner) public view returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

        currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        // Note: You don't REALLY need this require statement since nothing should be querying for non-existing tokens after reveal.
            // That said, it's a public view method so gas efficiency shouldn't come into play.
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        if (revealed) {
            return string(abi.encodePacked(revealedURI, Strings.toString(_tokenId), ".json"));
        }
        else {
            return hiddenURI;
        }
    }

    // https://docs.opensea.io/docs/contract-level-metadata
    // https://ethereum.stackexchange.com/questions/110924/how-to-properly-implement-a-contracturi-for-on-chain-nfts
    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    /*
     *
     Owner Function
     *
     */

    function setTeamMintMax(uint256 _teamMintMax) public onlyOwner {
        TEAM_MINT_MAX = _teamMintMax;
    }

    function setSupplyMax(uint256 _supplyMax) public onlyOwner {
        MAX_SUPPLY = _supplyMax;
    }

     function setPublicmintlimit(uint256 _publicmintlimit) public onlyOwner {
        PUBLIC_MINT_LIMIT = _publicmintlimit;
    }

    function setPublicmintperTransaction(uint256 _publicmintper) public onlyOwner {
        PUBLIC_MINT_LIMIT_TXN = _publicmintper;
    }

    function setPublicPrice(uint256 _newpublicPrice) external onlyOwner {
        publicPrice = _newpublicPrice;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        revealedURI = _baseUri;
    }


    // Note: This method can be hidden/removed if this is a constant.
    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenURI = _hiddenMetadataUri;
    }

    function revealCollection(bool _revealed, string memory _baseUri) public onlyOwner {
        revealed = _revealed;
        revealedURI = _baseUri;
    }

    // https://docs.opensea.io/docs/contract-level-metadata
    function setContractURI(string memory _contractURI) public onlyOwner {
        CONTRACT_URI = _contractURI;
    }

    // Note: Another option is to inherit Pausable without implementing the logic yourself.
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol
    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setPublicEnabled(bool _state) public onlyOwner {
        publicSale = _state;
        freeSale = !_state;
    }
    function setFreeEnabled(bool _state) public onlyOwner {
        freeSale = _state;
        publicSale = !_state;
    }

    function setTeamWalletAddress(address _teamWallet) public onlyOwner {
        teamWallet = _teamWallet;
    }

    function withdraw() external payable onlyOwner {
        // Get the current funds to calculate initial percentages
        uint256 currBalance = address(this).balance;

        (bool succ, ) = payable(FOUNDER_ADDRESS).call{
            value: (currBalance * 1000) / 10000
        }("");
        require(succ, "Founder transfer failed");

        // Withdraw the ENTIRE remaining balance to the team wallet
        (succ, ) = payable(teamWallet).call{
            value: address(this).balance
        }("");
        require(succ, "Team (remaining) transfer failed");
    }

    // Owner-only mint functionality to "Airdrop" mints to specific users
        // Note: These will likely end up hidden on OpenSea
    function mintToUser(uint256 quantity, address receiver) public onlyOwner mintCompliance(quantity) {
        _safeMint(receiver, quantity);
    }

    /*
     *
     Modifier 
    *
    */

    modifier mintCompliance(uint256 quantity) {
        require(!paused, "Contract is paused");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough mints left");
        require(tx.origin == msg.sender, "No contract minting");
        _;
    }

    
    /////////////////////////////
    // OPENSEA FILTER REGISTRY 
    /////////////////////////////

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}