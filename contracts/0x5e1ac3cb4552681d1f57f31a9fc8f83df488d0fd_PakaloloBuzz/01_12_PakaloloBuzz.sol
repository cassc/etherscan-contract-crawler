// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// author @Syed Qasim

contract PakaloloBuzz is ERC721, Ownable {
    constructor(
        string memory _uri,
        bytes32 _merkleRootkey,
        address payable _team_wallet
    ) ERC721
    ("Pakalolo Buzz", "BUZZ")
    {
        notRevealedUri = _uri;
        owner_wallet = payable(msg.sender);
        _merkleRoot = _merkleRootkey;
        team_wallet = _team_wallet;
    }

    using Counters for Counters.Counter;
    Counters.Counter private supply;

    string public notRevealedUri;
    string public revealedUri;
    string public uriMetadataSuffix = "";

    bytes32 public _merkleRoot;
    
    uint public  revealFrom = 0;
    uint public  revealTo = 0;

    uint public  MAX_SUPPLY = 4200;

    bool public  mintStatus = false;
    uint public  mintPrice = 0.07 ether;
    uint public  MAX_MINT = 2;
    bool public  limitMaxPublicmint = true;

    bool public  premintStatus = true;
    uint public  preMintPrice = 0.05 ether;
    uint public  MAX_Pre_Mint = 3;
    bool public  limitMaxPremint = true;

    // Wallet Addresses
    address payable private owner_wallet;
    address payable private team_wallet;

    mapping(address => uint256) public addressesMintedBalance;
    mapping(address => uint256) public WLaddressesMintedBalance;

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
    
    function airdropTokens(address[] calldata _to) public onlyOwner {
        require(supply.current() + _to.length <= MAX_SUPPLY, "This Action would exceed max tokens");
        for (uint i = 0; i < _to.length; i++) {
            supply.increment();
            _safeMint(_to[i], supply.current());
        }
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
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

    function changeUriMetadataSuffix(string memory _uri) external onlyOwner {
        uriMetadataSuffix = _uri;
    }

    function changeOwnerWallet(address payable _address) external onlyOwner {
        owner_wallet = _address;
    }

    function changeTeamWallet(address payable _address) external onlyOwner {
        team_wallet = _address;
    }

    function getRevealedUri() internal view virtual  returns (string memory) {
        return revealedUri;
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

    function setrevealFrom(uint256 revealFromid) external onlyOwner {
        revealFrom = revealFromid;
    }

    function setrevealTo(uint256 revealToid) external onlyOwner {
        revealTo = revealToid;
    }

    function setMaxSupply(uint256 _supply) external onlyOwner {
        MAX_SUPPLY = _supply;
    }

    function setMintPrice(uint256 _price) external onlyOwner {
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
    
    function resetMintForAddress(address payable _address) external onlyOwner {
        addressesMintedBalance[_address] = 0;
        WLaddressesMintedBalance[_address] = 0;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

    function verify(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash == root;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        
        if (tokenId >= revealFrom && tokenId <= revealTo ) {
            // "ipfs://__CID__/"
            return string(abi.encodePacked(revealedUri, toString(tokenId),uriMetadataSuffix));
        } else {
            return string(abi.encodePacked(notRevealedUri));
        }
        
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory){
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

    function regularMint(uint256 numberOfTokens) external payable callerIsUser {
        // require(_launchAt < block.timestamp, "Public Minting not Started");
        require(mintStatus, "Public Mint Paused for now");
        require(numberOfTokens > 0, "need to mint at least 1 NFT");
        require(supply.current() + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens supply");
        require(numberOfTokens <= MAX_MINT,"Max Mint amount per Transaction exceeded");
        require(mintPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        if (limitMaxPublicmint == true) {
            require(addressesMintedBalance[msg.sender] + numberOfTokens <= MAX_MINT, "Exceeded MAX Token Mint per Address");
        }

        for (uint256 i = 0; i < numberOfTokens; i++) {
            supply.increment();
            _safeMint(msg.sender, supply.current());
        }
        addressesMintedBalance[msg.sender] += numberOfTokens;
    }
    
    function preMint(bytes32[] calldata _merkleTree, uint256 numberOfTokens) external payable callerIsUser {
        // require(_presaleAt < block.timestamp, "Presale Mint has not begun yet");
        // require(block.timestamp < _presaleAt + 1 days, "Presale Mint has ended");
        require(premintStatus, "Presale Mint Paused for now");
        require(numberOfTokens > 0, "need to mint at least 1 NFT");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(verify(_merkleTree, _merkleRoot, leaf), "Not on whitelist");
        if (limitMaxPremint == true) {
            require(WLaddressesMintedBalance[msg.sender] + numberOfTokens <= MAX_Pre_Mint, "Exceeded MAX Token Mint per Address");
        }

        require(supply.current() + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(preMintPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            supply.increment();
            _safeMint(msg.sender, supply.current());
        }
        WLaddressesMintedBalance[msg.sender] += numberOfTokens;
    }

    function get_balance() public onlyOwner view returns (uint balance) {
        return address(this).balance;
    }

    function withdraw() public onlyOwner callerIsUser {
        uint total_balance = address(this).balance;
		require(total_balance>0, "Balance is 0");
		
        uint team_wallet_value = total_balance * 5 / 100;
        (bool twv, ) = payable(team_wallet).call{value: team_wallet_value}("");
        require(twv);

        uint owner_wallet_value = total_balance * 95 / 100;
        (bool owv, ) = payable(owner_wallet).call{value: owner_wallet_value}("");
        require(owv);
    }
        
}