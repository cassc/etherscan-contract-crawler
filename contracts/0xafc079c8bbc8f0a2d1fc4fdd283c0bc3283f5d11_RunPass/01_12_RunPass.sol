// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// author @Syed Qasim

contract RunPass is ERC721, Ownable {
    constructor(string memory _uri, address payable _owner_wallet, bytes32 _root) ERC721
    ("RUN PASS", "RPASS") 
    
    {
        notRevealedUri = _uri;
        owner_wallet = _owner_wallet;
        setRoyaltyInfo(msg.sender, 500);
        _merkleRoot = _root;
        // reserveDiamonds();
    }

    using Counters for Counters.Counter;
    Counters.Counter private supply;

    string public notRevealedUri;
    string public revealedUri;
    string public uriMetadataSuffix = "";

    bytes32 public _merkleRoot;
    bool public  reveal = false;
    uint public  MAX_SUPPLY = 1000;

    bool public  mintStatus = false;
    uint public  mintPrice = 10 ether;
    uint public  MAX_MINT = 2;
    bool public  limitMaxPublicmint = false;

    bool public  premintStatus = false;
    uint public  preMintPrice = 0.0 ether;
    uint public  MAX_Pre_Mint = 1;
    bool public  limitMaxPremint = true;

    // Wallet Addresses
    address payable private owner_wallet;

    mapping(address => uint256) public addressesMintedBalance;
    mapping(address => uint256) public WLaddressesMintedBalance;

    uint96 public royaltyFeesInBips = 500;
    uint96 public reservedDiamonds = 25;
    address public royaltyAddress = owner_wallet;


    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    

    // Diamonds will be reserved before Launch.
    function reserveDiamonds() public onlyOwner {
        require(supply.current() < reservedDiamonds, "Diamonds reserved");
        for (uint i = supply.current(); i < reservedDiamonds; i++) {
            supply.increment();
            _safeMint(msg.sender, supply.current());
        }
    }

    function airdropTokens(address[] calldata _to) public onlyOwner {
        require(supply.current() + _to.length <= MAX_SUPPLY, "Exceed Max tokens");
        for (uint i = 0; i < _to.length; i++) {
            supply.increment();
            _safeMint(_to[i], supply.current());
        }
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        royaltyAddress = _receiver;
        royaltyFeesInBips = _royaltyFeesInBips;
    }

    
    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function changeNotRevealedUri(string memory _uri) external onlyOwner {
        notRevealedUri = _uri;
    }

    function changeRevealedUri(string memory _uri) external onlyOwner {
        revealedUri = _uri;
    }

    function changeOwnerWallet(address payable _address) external onlyOwner {
        owner_wallet = _address;
    }

    function getRevealedUri() internal view virtual  returns (string memory) {
        return revealedUri;
    }

    function togglerevealToken() external onlyOwner {
        reveal = !reveal;
    }

    function togglePreMint() external onlyOwner {
        premintStatus = !premintStatus;
    }

    function toggleMint() public onlyOwner {
        mintStatus = !mintStatus;
    }

    function toggleLimitMaxPremint() public onlyOwner {
        limitMaxPremint = !limitMaxPremint;
    }

    function setMaxSupply(uint256 _supply) external onlyOwner {
        MAX_SUPPLY = _supply;
    }

    function setPrice(uint256 _price) external onlyOwner {
        mintPrice = _price; 
    }

    function setWLPrice(uint256 _price) external onlyOwner {
        preMintPrice = _price; 
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) external onlyOwner {
        MAX_MINT = _newmaxMintAmount; 
    }

    function setmaxPreMintAmount(uint256 _newmaxMintAmount) external onlyOwner {
        MAX_Pre_Mint = _newmaxMintAmount; 
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        _merkleRoot = _root;
    }

    function resetPreMintMultiple(address[] calldata _addresses) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            delete WLaddressesMintedBalance[_addresses[i]];
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

    function verify(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (leaf <= proofElement) {
                leaf = keccak256(abi.encodePacked(leaf, proofElement));
            } else {
                leaf = keccak256(abi.encodePacked(proofElement, leaf));
            }
        }
        return leaf == root;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (reveal == false) {
            string memory baseURI = _baseURI();
            return string(abi.encodePacked(baseURI));
        } else {
            string memory baseURI_revealed = _baseURI();
            // "ipfs://__CID__/"
            return string(abi.encodePacked(baseURI_revealed, toString(tokenId),uriMetadataSuffix));
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        if (reveal == false) {
            return notRevealedUri;
        } else {
            return revealedUri;
        }
    }

    function tokensOfWallet(address _owner) public view returns (uint256[] memory){
        uint256 ownerTokenCount = balanceOf(_owner);
  
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                tokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return tokenIds;
    }
	
	
    function getWLaddressMintBalance(address _address) internal view virtual  returns (uint256) {
        return WLaddressesMintedBalance[_address];
    }

    function regularMint(uint256 numberOfTokens) external payable {
        require(mintStatus, "Public Mint Paused");
        require(numberOfTokens > 0, "mint at least 1 NFT");
        require(supply.current() + numberOfTokens <= MAX_SUPPLY, "Exceed MAX Supply");
        require(numberOfTokens <= MAX_MINT,"amount per Transaction exceeded");
        require(mintPrice * numberOfTokens <= msg.value, "Ether value not correct");

        if (limitMaxPublicmint == true) {
            require(addressesMintedBalance[msg.sender] + numberOfTokens <= MAX_MINT, "Exceeded MAX Token Mint per Address");
        }

        for (uint256 i = 0; i < numberOfTokens; i++) {
            supply.increment();
            _safeMint(msg.sender, supply.current());
        }
        addressesMintedBalance[msg.sender] += numberOfTokens;
    }
    
    function preMint(bytes32[] calldata _merkleTree, uint256 numberOfTokens) external payable {
        require(premintStatus, "Presale Mint Paused for now");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(verify(_merkleTree, _merkleRoot, leaf), "Not on whitelist");
        if (limitMaxPremint == true) {
            require(WLaddressesMintedBalance[msg.sender] + numberOfTokens <= MAX_Pre_Mint, "Address already utilized");
        }

        require(supply.current() + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(preMintPrice * numberOfTokens <= msg.value, "Ether value not correct");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            supply.increment();
            _safeMint(msg.sender, supply.current());
        }
        WLaddressesMintedBalance[msg.sender] += numberOfTokens;
    }

    function get_balance() public onlyOwner view returns (uint balance) {
        return address(this).balance;
    }

    function withdraw() public onlyOwner {
		require(get_balance()>0, "Balance is 0");
		
        (bool owv, ) = payable(owner_wallet).call{value: get_balance()}("");
        require(owv);

    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)external view virtual returns (address, uint256){
        return (royaltyAddress, calculateRoyalty(_salePrice));
    }

    function calculateRoyalty(uint256 _salePrice) view public returns (uint256) {
        return (_salePrice / 10000) * royaltyFeesInBips;
    }
}