// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

//                               _,add8ba,
//                             ,d888888888b,
//                            d8888888888888b                        _,ad8ba,_
//                           d888888888888888)                     ,d888888888b,
//                           I8888888888888888 _________          ,8888888888888b
//                 __________`Y88888888888888P"""""""""""baaa,__ ,888888888888888,
//             ,adP"""""""""""9888888888P""^                 ^""Y8888888888888888I
//          ,a8"^           ,d888P"888P^                           ^"Y8888888888P'
//        ,a8^            ,d8888'                                     ^Y8888888P'
//       a88'           ,d8888P'                                        I88P"^
//     ,d88'           d88888P'                                          "b,
//    ,d88'           d888888'                                            `b,
//   ,d88'           d888888I                                              `b,
//   d88I           ,8888888'            ___                                `b,
//  ,888'           d8888888          ,d88888b,              ____            `b,
//  d888           ,8888888I         d88888888b,           ,d8888b,           `b
// ,8888           I8888888I        d8888888888I          ,88888888b           8,
// I8888           88888888b       d88888888888'          8888888888b          8I
// d8886           888888888       Y888888888P'           Y8888888888,        ,8b
// 88888b          I88888888b      `Y8888888^             `Y888888888I        d88,
// Y88888b         `888888888b,      `""""^                `Y8888888P'       d888I
// `888888b         88888888888b,                           `Y8888P^        d88888
//  Y888888b       ,8888888888888ba,_          _______        `""^        ,d888888
//  I8888888b,    ,888888888888888888ba,_     d88888888b               ,ad8888888I
//  `888888888b,  I8888888888888888888888b,    ^"Y888P"^      ____.,ad88888888888I
//   88888888888b,`888888888888888888888888b,     ""      ad888888888888888888888'
//   8888888888888698888888888888888888888888b_,ad88ba,_,d88888888888888888888888
//   88888888888888888888888888888888888888888b,`"""^ d8888888888888888888888888I
//   8888888888888888888888888888888888888888888baaad888888888888888888888888888'
//   Y8888888888888888888888888888888888888888888888888888888888888888888888888P
//   I888888888888888888888888888888888888888888888P^  ^Y8888888888888888888888'
//   `Y88888888888888888P88888888888888888888888888'     ^88888888888888888888I
//    `Y8888888888888888 `8888888888888888888888888       8888888888888888888P'
//     `Y888888888888888  `888888888888888888888888,     ,888888888888888888P'
//      `Y88888888888888b  `88888888888888888888888I     I888888888888888888'
//        "Y8888888888888b  `8888888888888888888888I     I88888888888888888'
//          "Y88888888888P   `888888888888888888888b     d8888888888888888'
//             ^""""""""^     `Y88888888888888888888,    888888888888888P'
//                             "8888888888888888888b,   Y888888888888P^
//                               `Y888888888888888888b   `Y8888888P"^
//                                 "Y8888888888888888P     `""""^
//                                   `"YY88888888888P'
//                                        ^""""""""'

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title Grumpy Pandaz NFT collection
contract GrumpyPandaz is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // config

    address constant TEAM = 0x15C47dB7Ab4D5be704693FDE9fE477623e278FA5;
    uint constant MAX_SUPPLY = 8888;
    uint constant PRICE = 2 ether / 10; // 0.2 ETH
    uint constant MAX_MINT_PER_ADDRESS = 5;
    uint constant MAX_MINT_PRESALE = 2; // per address
    uint constant PREMINE_AMOUNT = 100;
    
    bytes32 private root;

    Counters.Counter private _tokenIdCounter;

    mapping(address => bool) public isWhitelisted;
    mapping(address => uint) public nbOfGPsMintedBy;
    bool public publicSaleStarted;
    bool public collectionHasBeenRevealed;
    bool public saleEnded;
    string private baseURI = "ipfs://QmUKTqtymsnFrjcTVuaNnYwVNPuJoqUQWdaqC2XaEeFbpx/";

    constructor(bytes32 _root) ERC721("GrumpyPandaz", "GP") {
        root = _root;

        for (uint i = 0; i < PREMINE_AMOUNT; i++){
            _tokenIdCounter.increment();
            _mint(TEAM, _tokenIdCounter.current());
        }
    }

    // public methods

    /// @notice buy `quantity` of Pandaz
    /// @param quantity required, number of NFTs to buy
    /// @param proof merkle proof if whitelisted, please provide an empty array if not / already did once
    /// @dev msg.value must be >= quantity * PRICE
    function buy(uint quantity, bytes32[] calldata proof) payable public {
        require(!saleEnded, "Sale Ended");
	    require(_tokenIdCounter.current() < MAX_SUPPLY, "Max supply reached");
		require(_tokenIdCounter.current() + quantity <= MAX_SUPPLY, "Mint quantity exceeds max supply");

        uint userMintLimit;

        if(!isWhitelisted[msg.sender] && proof.length > 0){
            isWhitelisted[msg.sender] = MerkleProof.verify(proof, root, bytes32(abi.encodePacked(msg.sender)));
        }

        if (publicSaleStarted){
            userMintLimit = MAX_MINT_PER_ADDRESS;

            if (isWhitelisted[msg.sender]) userMintLimit += MAX_MINT_PRESALE;
        } else {
            require(isWhitelisted[msg.sender], "Public sale hasn't started yet");
            
            userMintLimit = MAX_MINT_PRESALE;
        }

        require(nbOfGPsMintedBy[msg.sender] + quantity <= userMintLimit, "Mint quantity exceeds allowance for this address");
        require(msg.value >= PRICE * quantity, "Price not met");

        for (uint i = 0; i < quantity; i++){
            // _safeMint() not used to avoid reentrency
            // it is the responsibility of the caller not to call buy() from a contract where the tokens would be locked

            _tokenIdCounter.increment();
            nbOfGPsMintedBy[msg.sender]++;
            _mint(msg.sender, _tokenIdCounter.current());
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    // Admin methods

    /// @notice reveals metadatas, including images. Metadatas can't be modified after reveal
    function reveal(string calldata _baseUri) public onlyOwner {
        require(!collectionHasBeenRevealed);

        collectionHasBeenRevealed = true;
        baseURI = _baseUri;
    }

    /// @notice updates whitelist, to include more people as phases roll out, addresses that already have been verified in a 
    /// @notice previous whitelist stay whitelisted
    function updateWhitelist(bytes32 _root) public onlyOwner {
        root = _root;
    }

    function startPublicSale() public onlyOwner {
        publicSaleStarted = true;
    }
	
	function withdraw() public {
        require(msg.sender == TEAM);
		(bool success, ) = msg.sender.call{value: address(this).balance}('');
		require(success, "Withdrawal failed");
	}

    /// @notice ends sale, effectively locking the total supply at the current amout. Sale can't be resumed after this
    function endSale() public onlyOwner {
        saleEnded = true;
    }

    // private method

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}