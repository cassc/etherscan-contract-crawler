// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract BountyGames is ERC721, EIP712, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    Counters.Counter private _tokenIdCounter;
    string _baseUri;
    address _signerAddress;
    string _contractUri;

    uint public price = 0.059 ether;
    uint public wlPrice = 0.049 ether;
    bool public canUnlock = true;
    uint public startSalesTimestamp = 1643310000;
    uint public endSalesTimestamp = 1643569200;

    mapping (address => uint) public accountToMintedFreeTokens;
    mapping (address => EnumerableSet.UintSet) accountToLockedTokens;

    modifier validSignature(uint maxFreeMints, bytes calldata signature) {
        require(recoverAddress(msg.sender, maxFreeMints, signature) == _signerAddress, "user cannot mint");
        _;
    }

    event Arrest(uint tokenId, address owner);
    event Release(uint tokenId, address owner);

    constructor() ERC721("Bounty Games", "BOUNTY") EIP712("BOUNTY", "1.0.0") {
        _contractUri = "ipfs://QmdeJsL7mUAs8K1U4NsjKpxM9dSv36sGhppGwANFu57t6N";
    }

    function mint(uint quantity) external payable {
        require(isSalesActive(), "sale is not active");
        require(msg.value >= price * quantity, "ether sent is under price");
        
        for (uint i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
    }

    function freeMint(uint maxFreeMints, uint quantity, bytes calldata signature) 
        external validSignature(maxFreeMints, signature) {
        require(isSalesActive(), "sale is not active");
        require(quantity + accountToMintedFreeTokens[msg.sender] <= maxFreeMints, "quantity exceeds allowance");
        
        for (uint i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
        
        accountToMintedFreeTokens[msg.sender] += quantity;
    }

    function whitelistMint(uint maxFreeMints, uint quantity, bytes calldata signature) 
        external payable validSignature(maxFreeMints, signature) {
        require(isSalesActive(), "sale is not active");
        require(msg.value >= quantity * wlPrice, "not enough ethers");

        for (uint i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
    }

    function safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }

    function isSalesActive() public view returns (bool) {
        return block.timestamp >= startSalesTimestamp && block.timestamp <= endSalesTimestamp;
    }

    function setSalesDates(uint start, uint end) external onlyOwner {
        startSalesTimestamp = start;
        endSalesTimestamp = end;
    }
 
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseUri = newBaseURI;
    }

    function setContractURI(string memory newContractURI) external onlyOwner {
        _contractUri = newContractURI;
    }

    function setPrices(uint newPrice, uint newWLPrice) external onlyOwner {
        price = newPrice;
        wlPrice = newWLPrice;
    }

    function setCanUnlock(bool newCanUnlock) external onlyOwner {
        canUnlock = newCanUnlock;
    }

    function arrest(uint tokenId) external {
        address tokenOwner = ownerOf(tokenId);

        require(tokenOwner == msg.sender || msg.sender == owner(), "user does not own this token");
        require(!canUnlock, "cannot arrest yet");

        _transfer(tokenOwner, address(this), tokenId);

        accountToLockedTokens[tokenOwner].add(tokenId);

        emit Arrest(tokenId, tokenOwner);
    }

    function releaseAll() external {
        uint amount = accountToLockedTokens[msg.sender].length();

        for (uint i = 0; i < amount; i++) {
            release(accountToLockedTokens[msg.sender].at(0));
        }
    }

    function release(uint tokenId) public {
        require(accountToLockedTokens[msg.sender].contains(tokenId), "user does not own this token");
        require(canUnlock, "cannot unlock yet");

        _transfer(address(this), msg.sender, tokenId);

        accountToLockedTokens[msg.sender].remove(tokenId);

        emit Release(tokenId, msg.sender);
    }

    function releaseAll(address accountAddress) external onlyOwner {
        uint amount = accountToLockedTokens[accountAddress].length();

        for (uint i = 0; i < amount; i++) {
            release(accountToLockedTokens[accountAddress].at(0));
        }
    }

    function release(address accountAddress, uint tokenId) public onlyOwner {
        require(accountToLockedTokens[accountAddress].contains(tokenId), "user does not own this token");

        _transfer(address(this), accountAddress, tokenId);

        accountToLockedTokens[accountAddress].remove(tokenId);

        emit Release(tokenId, accountAddress);
    }

    function lockedTokensFromAccount(address accountAddress) external view returns (uint[] memory tokenIds) {
        uint amount = accountToLockedTokens[accountAddress].length();
        tokenIds = new uint[](amount);

        for (uint i = 0; i < amount; i++) {
            tokenIds[i] = accountToLockedTokens[accountAddress].at(i);
        }
    }

    function _hash(address account, uint maxFreeMints) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("NFT(uint256 maxFreeMints,address account)"),
                        maxFreeMints,
                        account
                    )
                )
            );
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(_baseUri, tokenId.toString(), ownerOf(tokenId) == address(this) ? "?locked=true" : ""));
    }

    function recoverAddress(address account, uint maxFreeMints, bytes calldata signature) public view returns(address) {
        return ECDSA.recover(_hash(account, maxFreeMints), signature);
    }

    function setSignerAddress(address signerAddress) external onlyOwner {
        _signerAddress = signerAddress;
    }
    
    function withdraw(uint amount) external onlyOwner {
        require(payable(msg.sender).send(amount));
    }
    
    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}