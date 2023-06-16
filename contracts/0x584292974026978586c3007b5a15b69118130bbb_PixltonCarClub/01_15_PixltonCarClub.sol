// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ERC721Enumerable.sol";
import "./IPixls.sol";

// Pixlton Car Club contract
contract PixltonCarClub is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private CurrentTokenId;
    uint256[5471] private Ids;
    
    uint16 public constant MAX_MINTS_TX = 10;

    string public baseURI;
    uint256 public PublicTokenPrice = 0.03 ether;
    uint16 public MaxTokens = 5471;
    bool public PublicMintActive = false;
    bool public ClaimActive = false;

    // Ledger of Pixl IDs that were claimed with.
    mapping(uint256 => bool) ClaimedPixlIds;

    string public constant Z = "You'll see this on the internet. Go on, press like, and make my clicks spike.";

    // Parent NFT Contract mainnet address
    address public nftAddress = 0x082903f4e94c5e10A2B116a4284940a36AFAEd63;
    IPixls nftContract = IPixls(nftAddress);

    constructor(string memory _baseURI) ERC721("Pixlton Car Club", "PXCC") {
        baseURI = _baseURI;
        devMint(0x12Ea1c7a2E93b23b5f0845DF4FeeeCd26d3b6B8d, 40);
    }
    
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function toggleClaimState() public onlyOwner {
        ClaimActive = !ClaimActive;
    }

    function togglePublicMintState() public onlyOwner {
        PublicMintActive = !PublicMintActive;
    }

    function setPublicPrice(uint256 newPrice) public onlyOwner {
        PublicTokenPrice = newPrice;
    }

    function getClaimablePixls() external view returns (uint256[] memory) {
        uint256 amount = nftContract.balanceOf(msg.sender);
        uint256[] memory lot = new uint256[](amount);
        uint16 arrayIndex = 0;

        for (uint i = 0; i < amount; i++) {
            uint256 id = nftContract.tokenOfOwnerByIndex(msg.sender, i);
            
            if(!ClaimedPixlIds[id])
            {
                lot[arrayIndex] = id;            
                arrayIndex += 1;
            }
        }

        uint256 needDec = amount - arrayIndex;
        assembly { mstore(lot, sub(mload(lot), needDec)) }
        
        return lot;
    }

    function checkIfClaimed(uint256 nftId) external view returns (bool) {
        return ClaimedPixlIds[nftId];
    }

    function getAvailableCars() external view returns (uint256) {
        return MaxTokens - CurrentTokenId.current();
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    // Private minting (Pixls holders only) - Claim for singular Pixl
    function claimWithPixl(uint256 nftId) external {
        require(ClaimActive, "Pixlton Car Club must be active to claim.");
        require(CurrentTokenId.current() + 1 <= MaxTokens, "Not enough available cars to claim.");
        require(nftContract.ownerOf(nftId) == msg.sender, "Not the owner of this Pixl.");
        require(!ClaimedPixlIds[nftId], "This Pixl has already been used.");
                
        internalMint(msg.sender, 1);
        ClaimedPixlIds[nftId] = true;
    }

    // Private minting (Pixls holders only) - Claim for specific NFTs
    function multiClaimWithPixl(uint256 [] memory nftIds) public {
        require(ClaimActive, "Pixlton Car Club must be active to claim.");
        require(nftIds.length + CurrentTokenId.current() <= MaxTokens, "Not enough available cars to claim.");

        for (uint i=0; i< nftIds.length; i++) {
            require(nftContract.ownerOf(nftIds[i]) == msg.sender, "Not the owner of this Pixl.");

            if(ClaimedPixlIds[nftIds[i]]) {
                continue;
            } else {
                internalMint(msg.sender, 1);
                ClaimedPixlIds[nftIds[i]] = true;
            }
        }
    }

    // Private minting (Pixls holders only) - Claim for all of your Pixl holdings
    function multiClaimWithAll() external {
        require(ClaimActive, "Pixlton Car Club must be active to claim.");
        uint256 balance = nftContract.balanceOf(msg.sender);
        uint256[] memory lot = new uint256[](balance);

        for (uint i = 0; i < balance; i++) {
            lot[i] = nftContract.tokenOfOwnerByIndex(msg.sender, i);
        }

        multiClaimWithPixl(lot);
    }

    // Mint a limited stack for the developer.
    function devMint(address _to, uint256 _quantity) internal {        
        internalMint(_to, _quantity);
    }

    function totalSupply() public view override returns (uint256) {
        return CurrentTokenId.current();
    }

    function mintPublic(uint256 quantity) public payable {
        require(PublicMintActive, "Minting is not open to the public!");
        require(quantity <= MAX_MINTS_TX, "Trying to mint too many at a time!");
        require(quantity + CurrentTokenId.current() <= MaxTokens, "Not enough available cars to mint.");
        require(msg.value >= PublicTokenPrice * quantity, "Not enough ether sent!");
        require(msg.sender == tx.origin, "No contracts please!");

        internalMint(msg.sender, quantity);
    }

    function internalMint(address _to, uint256 _quantity) private {
        require(_quantity <= MaxTokens && _quantity > 0, "Incorrect mint quantity");
        require(_quantity + CurrentTokenId.current() <= MaxTokens, "Cannot exceed max supply");
        
        uint256 remaining = MaxTokens - CurrentTokenId.current();
        
        for(uint256 i; i < _quantity; i++){
            
            remaining--;                    
            uint256 tokenId = CurrentTokenId.current();
            uint256 index = getRandomNumber(remaining, i * tokenId);

            _mint(_to, ((Ids[index] == 0) ? index : Ids[index]) + 1);
                 
            Ids[index] = Ids[remaining] == 0 ? remaining : Ids[remaining];
            CurrentTokenId.increment();            
        }
    }

    function getRandomNumber(uint256 maxValue, uint256 salt) private view returns(uint256) {
        if (maxValue == 0)
            return 0;
            
        uint256 seed =
			uint256(
				keccak256(
					abi.encodePacked(
							block.difficulty +	
							((uint256(keccak256(abi.encodePacked(tx.origin, msg.sig)))) / (block.timestamp)) +
							block.number +
							salt
					)
				)
			);
		return seed % maxValue;
    }
    
    function withdraw() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        payable(msg.sender).transfer(totalBalance);
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners[tokenId]= to;
        emit Transfer(address(0), to, tokenId);
    }
}