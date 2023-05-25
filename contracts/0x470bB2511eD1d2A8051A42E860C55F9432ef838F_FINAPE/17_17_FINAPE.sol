// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title TokenRecover
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Allow to recover any ERC20 sent into the contract for error
 */
contract TokenRecover is Ownable {

    /**
     * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}

contract FINAPE is ERC721Enumerable, Ownable, ReentrancyGuard, TokenRecover {
    using Counters for Counters.Counter;

    mapping(address => bool) private oracleNodes;
    mapping(address => bool) public whitelist;
    mapping(uint8 => uint256) public stageNftCount;
    mapping(uint8 => uint256) public stageTokenIdStartIndex;
    mapping(uint8 => uint256) public startingIndex;
    mapping(uint256 => uint256) public bridgingFees;
    mapping(uint256 => uint256) public previousChainId;

    uint256 public constant MAX_NFT_SUPPLY = 5232;
    string public constant FINAPE_PROVENANCE_HASH = "7e5f7e6dbb6d4aa1e6f9d493700fd81225b5c715b8c629b0fd0b5a04d71ba58a";

    Counters.Counter private _stageMintedTracker;

    string public baseTokenURI;
    uint8 public currentStage = 0;
    uint256 public price = 0;
    uint256 public totalMintedPriorToCurrentStage = 0;
    uint256 public whitelistMintLimit = 10;
    uint256 public maxOneTimePurchase = 10;
    bool public publicMintingEnabled = false;
    bool public whitelistMintingEnabled = false;
    bool public bridgeEnabled = false;

    uint256 private nonce = 0;

    modifier onlyOracleNode() {
        require(oracleNodes[msg.sender], "Only Oracle nodes allowed");
        _;
    }

    event NewStageStarted(
        uint8 stage,
        uint256 count,
        uint256 price
    );

    event CurrentStageUpdated(
        uint8 stage,
        uint256 count
    );

    event Minted(
        uint8 stage,
        uint256 numberOfTokens,
        uint256 lastTokenId,
        address account
    );

    event BridgeToChain(
        uint256 targetChainId,
        uint256 tokenId,
        address account,
        uint256 ref
    );

    event BridgeFromChain(
        uint256 currentChainId,
        uint256 tokenId,
        address account,
        uint256 ref
    );

    event StartingIndexSet(
        uint256 stage,
        uint256 startingIndex
    );

    constructor() ERC721("FINAPE", "FINAPE"){
    }

    function startNewStage(uint256 _tokenIdStartIndex, uint256 _count, uint256 _price) external onlyOwner {
        require(_count > 0, "NFT count should not be zero.");
        require(_stageMintedTracker.current() >= stageNftCount[currentStage], "Cannot start new stage before current stage is sold out.");
        require(_tokenIdStartIndex >= (stageTokenIdStartIndex[currentStage] + stageNftCount[currentStage]), "Token Id must be bigger than the previous set");
        require((totalMintedCount() + _count) <= MAX_NFT_SUPPLY, "Exceeded max supply of FINAPE");
        require((_tokenIdStartIndex + _count) <= MAX_NFT_SUPPLY, "Exceeded max supply of FINAPE");

        if (currentStage > 0) {
            require(startingIndex[currentStage] > 0, "Cannot start new stage before starting index is set.");
            require((stageTokenIdStartIndex[currentStage] + stageNftCount[currentStage] - 1) < _tokenIdStartIndex, "Overlapping token id start index.");
        }

        // stage start with 1
        currentStage = currentStage + 1; 
        
        price = _price;

        totalMintedPriorToCurrentStage = totalMintedPriorToCurrentStage + _stageMintedTracker.current();
        stageTokenIdStartIndex[currentStage] = _tokenIdStartIndex;

        // reset stage minted count
        Counters.reset(_stageMintedTracker);

        stageNftCount[currentStage] = _count;

        emit NewStageStarted(currentStage, _count, _price);
    }

    function updateCurrentStageSupply(uint256 _count) external onlyOwner {
        require(_count > 0, "NFT count should not be zero.");
        require(currentStage > 0, "No stage to update");
        require(startingIndex[currentStage] == 0, "Cannot update current stage if starting index is already set");
        require(_count >= _stageMintedTracker.current(), "The new staged NFT supply must be greater than the current stage minted count");
        require(_count < stageNftCount[currentStage], "Can only shrink, not grow");

        stageNftCount[currentStage] = _count;

        emit CurrentStageUpdated(currentStage, _count);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function setWhitelistMintLimit(uint256 _whitelistMintLimit) external onlyOwner {
        require(_whitelistMintLimit > 0, "Count should not be zero.");
        whitelistMintLimit = _whitelistMintLimit;
    }

    function setMaxOneTimePurchase(uint256 _maxOneTimePurchase) external onlyOwner {
        require(_maxOneTimePurchase > 0, "Count should not be zero.");
        maxOneTimePurchase = _maxOneTimePurchase;
    }

    function addToWhitelist(address addr) external onlyOwner {
        whitelist[addr] = true;
    }

    function addManyToWhitelist(address[] calldata addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            whitelist[addrs[i]] = true;
        }
    }

    function removeFromWhitelist(address addr) external onlyOwner {
        whitelist[addr] = false;
    }

    function removeManyFromWhitelist(address[] calldata addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            whitelist[addrs[i]] = false;
        }
    }
    
    function enablePublicMinting() external onlyOwner {
        publicMintingEnabled = true;
    }

    function disablePublicMinting() external onlyOwner {
        publicMintingEnabled = false;
    }
    
    function enableWhitelistMinting() external onlyOwner {
        whitelistMintingEnabled = true;
    }

    function disableWhitelistMinting() external onlyOwner {
        whitelistMintingEnabled = false;
    }
    
    function enableBridge() external onlyOwner {
        bridgeEnabled = true;
    }

    function disableBridge() external onlyOwner {
        bridgeEnabled = false;
    }

    function setBridgingFee(uint256 _chainId, uint256 _fee) external onlyOwner {
        bridgingFees[_chainId] = _fee;
    }

    function addOracleNode(address _oracleNode) external onlyOwner {
        require(!oracleNodes[_oracleNode], "Oracle node already added");
        oracleNodes[_oracleNode] = true;
    }

    function removeOracleNode(address _oracleNode) external onlyOwner {
        require(oracleNodes[_oracleNode], "Oracle node not found");
        oracleNodes[_oracleNode] = false;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function totalMintedCount() public view returns (uint256) {
        return totalMintedPriorToCurrentStage + _stageMintedTracker.current();
    }

    function nextTokenId() public view returns (uint256) {
        // return next token id to be minted
        return stageTokenIdStartIndex[currentStage] + _stageMintedTracker.current();
    }

    function currentStageNftCount() public view returns (uint256) {
        return stageNftCount[currentStage];
    }

    function stageMintedCount() public view returns (uint256) {
        return _stageMintedTracker.current();
    }

    function whitelistMint(uint256 _numberOfTokens) payable external nonReentrant {
        require(whitelistMintingEnabled, "Whitelist minting has not started");
        require(whitelist[msg.sender], "Address not whitelisted");
        require((balanceOf(msg.sender) + _numberOfTokens) <= whitelistMintLimit, "Exceed whitelist mint limit");

        _mintNFT(_numberOfTokens);
    }

    function publicSaleMint(uint256 _numberOfTokens) payable external nonReentrant {
        require(publicMintingEnabled, "Public minting has not started");

        _mintNFT(_numberOfTokens);
    }

    function _mintNFT(uint256 _numberOfTokens) internal {
        require(_numberOfTokens > 0, "Quantity should not be zero");
        require(_numberOfTokens <= maxOneTimePurchase, "Quantity exceeded limit");
        require((_stageMintedTracker.current() + _numberOfTokens) <= stageNftCount[currentStage], "Out of stock, check back later");
        require((price * _numberOfTokens) <= msg.value, "Insufficient minting fees value");
        
        for(uint256 i = 0; i < _numberOfTokens; i++) {
            uint256 newTokenId = nextTokenId();

            if (_stageMintedTracker.current() < stageNftCount[currentStage]) {
                _safeMint(msg.sender, newTokenId);

                _stageMintedTracker.increment();
            }
        }

        emit Minted(currentStage, _numberOfTokens, nextTokenId(), address(msg.sender));
    }

    function bridgeToChain(uint256 _dstnChainId, uint256 _tokenId, uint256 _ref) payable external nonReentrant {
        require(_exists(_tokenId), "Nonexistent token");
        require(bridgeEnabled, "Bridge is disabled");
        require(ownerOf(_tokenId) == address(msg.sender), "The target NFT does not belong to user");
        require(_dstnChainId > 0, "Dstn Chain ID must be provided");
        require(_dstnChainId != block.chainid, "Dstn Chain ID must not be current chain");
        require(bridgingFees[_dstnChainId] <= msg.value, "Need to pay bridging fees");

        _burn(_tokenId);
        
        emit BridgeToChain(_dstnChainId, _tokenId, address(msg.sender), _ref);
    }

    function bridgeFromChain(uint256 _fromChainId, uint256 _tokenId, address _receiver, uint256 _ref) external onlyOracleNode {
        require(!_exists(_tokenId), "Invalid request, token already exist");
        require(_receiver != address(0), "ERC721: address zero is not a valid owner");
        require(_tokenId < MAX_NFT_SUPPLY, "Invalid token id");

        _safeMint(_receiver, _tokenId);

        previousChainId[_tokenId] = _fromChainId;

        emit BridgeFromChain(block.chainid, _tokenId, _receiver, _ref);
    }

    function setStartingIndex() external nonReentrant {
        require(currentStage > 0, "No stage found.");
        require(_stageMintedTracker.current() >= stageNftCount[currentStage], "Cannot set starting index before current stage is sold out.");
        require(startingIndex[currentStage] == 0, "Starting index is already set");

        uint256 randomNumber = generateRandomNumber();
        uint256 tempstarting_index = randomNumber % stageNftCount[currentStage];

        // Prevent default sequence
        if (tempstarting_index == 0) {
            tempstarting_index = tempstarting_index + 1;
        }

        startingIndex[currentStage] = tempstarting_index;

        emit StartingIndexSet(currentStage, tempstarting_index);
    }

    function generateRandomNumber() internal returns (uint256) {
        nonce++;
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender, nonce)));
    }

    function withdraw(uint256 _amount) external onlyOwner nonReentrant returns (bool) {
        payable(owner()).transfer(_amount);
        return true;
    }
}