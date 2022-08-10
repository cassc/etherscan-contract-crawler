//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract Kindredz is ERC721AQueryable, Pausable, Ownable {
    address fundsWallet = 0xcDd02AE86063122a4B4054D977E39D707B285EFF;
    string public unrevealedURI;
    string public baseTokenURI;
    bool unrevealedURIFlag = true;

    uint public mintPrice = 0.033 ether;
    uint public whitelistPrice = 0.025 ether;
    uint16 public maxSupply = 5_111;
    uint16 public freeMintMaxSuppply = 100;
    uint16 public minted = 0;
    uint16 public freeMinted = 0;
    uint8 public constant batchLimit = 10; // mint amount limit
    uint8 public constant whitelistBatchLimit = 20; // mint amount limit
    bool public mintStarted = false; // is mint started flag
    bool public mintWhitelistStarted = false; // is mint for white list started flag
    uint256 private stakingTransfer = 1;  // MUST only be modified by safeTransferWhileNesting(); if set to 2 then the _beforeTokenTransfer() block while staking is disabled
    bool public stakingOpen = false; // If false then staking is blocked, but unstaking is always allowed.

    bytes32 public whiteListMerkleRoot; // root of Merkle tree only for white list minters
    mapping(address => bool) public whitelistMinted; // store if sender is already minted from white list
    mapping(uint => uint) public stake; // tokenID -> timestamp
    mapping(uint256 => uint256) private stakingStarted; // tokenId to staking start time (0 = not staking)
    mapping(uint256 => uint256) private stakingTotal; // Cumulative per-token staking, excluding the current period.
    
    event Staked(uint256 indexed tokenId); // Emitted when begins staking.
    event Unstaked(uint256 indexed tokenId); // Emitted when stops nesting
    event Expelled(uint256 indexed tokenId); // Emitted when expelled from the stak

    constructor(string memory _name, string memory _symbol) ERC721A(_name, _symbol) { }

    /**
    @notice mint tokens to sender 
    @param _mintAmount amount of tokens to mint
    */
    function mint(uint8 _mintAmount) public payable {
        require(mintStarted, "Mint is not started");
        require(_mintAmount <= batchLimit, "Not in batch limit");
        require(minted + _mintAmount <= maxSupply, "Too much tokens to mint");
        require(mintPrice * _mintAmount == msg.value, "Wrong amount of ETH");

        _safeMint(msg.sender, _mintAmount);
        minted += _mintAmount;
    }

    /**
    @notice tokens from whitelist to sender
    @param _merkleProof Merkle proof to verify if address in whitelist
    @param _mintAmount amount of tokens to mint
    */
    function whitelistMint(bytes32[] calldata _merkleProof, uint8 _mintAmount) public payable {
        require(mintWhitelistStarted, "Mint for whitelist is not started");
        require(_mintAmount <= whitelistBatchLimit, "Not in batch limit");
        require(minted + _mintAmount <= maxSupply, "Too much tokens to mint");
        require(whitelistPrice * _mintAmount == msg.value, "Wrong amount of ETH");
        require(!whitelistMinted[msg.sender], "Already minted from whitelist.");
        require(
            MerkleProof.verify(
                _merkleProof,
                whiteListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Failed to verify proof."
        );

        _safeMint(msg.sender, _mintAmount);
        minted += _mintAmount;
        whitelistMinted[msg.sender] = true;
    }

    /**
    @notice mint tokens to address for free cost 
    @param _mintAmount amount of tokens to mint
    */
    function freeMint(address _to, uint8 _mintAmount) public onlyOwner {
        require(_mintAmount <= batchLimit, "Too much tokens to mint");
        require(freeMinted + _mintAmount <= freeMintMaxSuppply, "Too much tokens to mint");
        
        _safeMint(_to, _mintAmount);
        freeMinted += _mintAmount;
        minted += _mintAmount;
    }

    /**
    @notice Returns the length of time, in seconds, that the Token has staked.
    @dev staking is tied to a specific Token, not to the owner, so it doesn't reset upon sale.
    @return staking whether the Token is currently staking.
    @return current Zero if not currently staking, otherwise the length of time since the most recent staking began.
    @return total Total period of time for which the Token has staked across its life, including the current period.
    */
    function stakingPeriod(uint256 tokenId) external view returns (bool staking, uint256 current, uint256 total) {
        require(_exists(tokenId), "Token not exists");

        uint256 start = stakingStarted[tokenId];
        if (start != 0) {
            staking = true;
            current = block.timestamp - start;
        }
        total = current + stakingTotal[tokenId];
    }

    /**
    @notice Transfer a token between addresses while the Token is staking,
    thus not resetting the staking period.
    */
    function safeTransferWhilestaking(address from, address to, uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(ownerOf(tokenIds[i]) == msg.sender, "Not your NFT!");
            stakingTransfer = 2;
            safeTransferFrom(from, to, tokenIds[i]);
            stakingTransfer = 1;
        }
    }

    /**
    @dev Block transfers while staking.
    */
    function _beforeTokenTransfers(address, address, uint256 startTokenId, uint256 quantity) internal view override {
        uint256 tokenId = startTokenId;
        for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
            require(stakingStarted[tokenId] == 0 || stakingTransfer == 2, "staking");
        }
    }

    /**
    @notice Changes staking status of token.
    */
    function togglestaking(uint256 tokenId) internal {
        uint256 start = stakingStarted[tokenId];
        if (start == 0) {
            require(stakingOpen, "staking closed");
            stakingStarted[tokenId] = block.timestamp;
            emit Staked(tokenId);
        } else {
            stakingTotal[tokenId] += block.timestamp - start;
            stakingStarted[tokenId] = 0;
            emit Unstaked(tokenId);
        }
    }

    /**
    @notice Changes staking status of tokens.
    */
    function togglestaking(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(ownerOf(tokenIds[i]) == msg.sender, "Not your NFT!");
            togglestaking(tokenIds[i]);
        }
    }

    /**
    @notice Admin-only ability to expel token from the stake.
    */
    function expelFromStak(uint256 tokenId) external onlyOwner {
        require(stakingStarted[tokenId] != 0, "Not staked");

        stakingTotal[tokenId] += block.timestamp - stakingStarted[tokenId];
        stakingStarted[tokenId] = 0;
        emit Unstaked(tokenId);
        emit Expelled(tokenId);
    }

    function setPrices(uint _publicPrice, uint _whitelistPrice) public onlyOwner {
        mintPrice = _publicPrice; // convert to WEI
        whitelistPrice = _whitelistPrice;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setUnrevealedURI(string memory _uri) external onlyOwner {
        unrevealedURI = _uri;
    }

    function setUnrevealedURIFlag(bool _state) external onlyOwner {
        unrevealedURIFlag = _state;
    }

    function setstakingOpen(bool _state) external onlyOwner {
        stakingOpen = _state;
    }

    function setMintState(bool _state) external onlyOwner {
        mintStarted = _state;
    }

    function setWhitelistMintState(bool _state) external onlyOwner {
        mintWhitelistStarted = _state;
    }

    function setWhitelistRoot(bytes32 _merkleRoot) public onlyOwner {
        whiteListMerkleRoot = _merkleRoot;
    }

    function withdraw() public onlyOwner {
        payable(fundsWallet).transfer(address(this).balance);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (unrevealedURIFlag) {
            return unrevealedURI;
        }

        return string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }
}