// SPDX-License-Identifier: MIT
// Website: https://www.animagusgameclub.xyz
// Discord: https://discord.gg/NaFAxTptPe

import "./RMdep.sol";

pragma solidity 0.8.7;

contract Animagus_Game_1 is ERC721Enumerable, Ownable, ERC2981PerTokenRoyalties {
    using Strings for uint256;

    uint256 public constant maxSupply = 100;
    uint256 public constant maxPerTransaction = 10;
    uint256 public constant cost = 0.01 ether; 
    uint256 public constant ROYALTY_VALUE = 0; //No Royalties
    uint256 public minted = 0;
    bool public mintOpen = true;
    bool public revealed = false;
    uint256 gross = 0;
    string public baseTokenURI = "https://animagusgameclub.fra1.digitaloceanspaces.com/Slot100/100/";
    string public _initNotRevealedUri = "https://animagusgameclub.fra1.digitaloceanspaces.com/Slot100/unreveal.json";
    mapping(address => bool) admins;
    address royaltyRecipient = 0x94230c7262fd675fbD550e948055b0E979bA66c6;
    string baseUri;
    string public notRevealedUri;
    
    // random token id map
    mapping(uint256 => uint256) indexer;
    uint256 indexerLength = maxSupply;
    mapping(uint256 => uint256) tokenIDMap;
    mapping(uint256 => uint256) takenImages;
    event Claim(uint256 indexed _id);
    
    constructor() ERC721("AnimagusGame1", "GAME1") Ownable() 
    {
         baseUri = baseTokenURI;
         setNotRevealedURI(_initNotRevealedUri);
    }

//                      MINT 


    // Think of it as an array of 100 elements, where we take
    //    a random index, and then we want to make sure we don't
    //    pick it again.
    // If it hasn't been picked, the mapping points to 0, otherwise
    //    it will point to the index which took its place
    function getNextImageID(uint256 index) internal returns (uint256) {
        uint256 nextImageID = indexer[index];

        // if it's 0, means it hasn't been picked yet
        if (nextImageID == 0) {
            nextImageID = index;
        }
        // Swap last one with the picked one.
        // Last one can be a previously picked one as well, thats why we check
        if (indexer[indexerLength - 1] == 0) {
            indexer[index] = indexerLength - 1;
        } else {
            indexer[index] = indexer[indexerLength - 1];
        }
        indexerLength -= 1;
        return nextImageID;
    }

    function enoughRandom() internal view returns (uint256) {
        if (maxSupply - minted == 0) return 0;
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        msg.sender,
                        blockhash(block.number)
                    )
                )
            ) % (indexerLength);
    }

    function randomMint(address receiver, uint256 nextTokenIndex) internal {
        uint256 nextIndexerId = enoughRandom();
        uint256 nextImageID = getNextImageID(nextIndexerId);

        assert(takenImages[nextImageID] == 0);
        takenImages[nextImageID] = 1;
        tokenIDMap[nextTokenIndex] = nextImageID;
        _safeMint(receiver, nextTokenIndex);
    }


    function mint(uint256 n) public payable {
        require(mintOpen, "Mint is not open yet.");
        require(n + minted <= maxSupply, "Collection size exceeded.");
        require(n > 0, "Number need to be higher than 0");
        require(n <= maxPerTransaction, "Max mint per transaction exceeded");
        require(
            msg.value >= (cost * n),
            "Ether value sent is below the price"
        );

        uint256 total_cost = (cost * n);
        gross += total_cost;

        uint256 excess = msg.value - total_cost;
        payable(address(this)).transfer(total_cost);

        for (uint256 i = 0; i < n; i++) {
            randomMint(_msgSender(), minted);
            _setTokenRoyalty(minted, royaltyRecipient, ROYALTY_VALUE);

            minted += 1;
            emit Claim(minted);
        }

        if (excess > 0) {
            payable(_msgSender()).transfer(excess);
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {

        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _safeTransfer(from, to, tokenId, _data);
    }

      function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
         if(revealed == false) {
        return notRevealedUri;
    }

        string memory baseURI = _baseURI();
        uint256 imageID = tokenIDMap[tokenId];
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, imageID.toString(),".json"))
                : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function reveal() public onlyOwner {
      revealed = true;
  }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981Base, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

   function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

    function setAdmins(address[] calldata _addr) external onlyOwner{
        for (uint i=0; i<_addr.length ; i++){
            admins[_addr[i]] = true;
        }
    }
    function setRoyaltyAddress(address _royaltyRecipient) external onlyOwner {
        royaltyRecipient = _royaltyRecipient;
    }

    function setBaseUri(string memory uri) external onlyOwner {
        baseUri = uri;
    }

         function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
    }

    function openMint() external onlyOwner {
        mintOpen = !mintOpen;
    }

    function getAdmins(address _addr) public view onlyOwner returns(bool){
            return admins[_addr];
    }
 
    receive() external payable {}

    fallback() external payable {}
}