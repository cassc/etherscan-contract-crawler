//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./EnumerableMap.sol";
import "./ERC721Enumerable.sol";
import "./ERC1155.sol";
import "./token/SafeERC20.sol";

contract COBI is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 public rewardToken =
        IERC20(0x5824e2d508dA5055C12046B0155cFd83d4b106f9);
    address masterAccountAddress = 0xBECcA544dA77c293e1017A621da5F44374500317;

    uint256 public constant DURATION = 100 days;
    uint256 private totalReward = 20000000000000000000000000;
    uint256 public periodFinish;

    using SafeMath for uint256;

    event RewardPaid(address indexed user, uint256 reward);

    // Token detail
    struct COBIDetail {
        uint256 first_encounter;
    }

    //Token Received Detail
    struct ReceivedCOBI {
        address owner;
        uint256 receivedTime;
    }

    // Events
    event TokenMinted(uint256 tokenId, address owner, uint256 first_encounter);

    // Token Detail
    mapping(uint256 => COBIDetail) private _cobiDetails;

    //Token Received Tracking
    mapping(uint256 => ReceivedCOBI) private _receivedCOBI;

    // Provenance number
    string public PROVENANCE = "";

    // Max amount of token to purchase per account each time
    uint256 public MAX_PURCHASE = 20;

    // Maximum amount of tokens to supply.
    uint256 public MAX_TOKENS = 10000;

    // Current price.
    uint256 public CURRENT_PRICE = 80000000000000000;

    // Define if sale is active
    bool public saleIsActive = false;

    // Base URI
    string private baseURI;

    /**
     * Contract constructor
     */
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        periodFinish = block.timestamp + DURATION;
    }

    /**
     * Withdraw
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * Reserve tokens
     */
    function reserveTokens() public onlyOwner {
        uint256 i;
        uint256 tokenId;
        uint256 first_encounter = block.timestamp;

        for (i = 1; i <= 50; i++) {
            tokenId = totalSupply().add(1);
            if (tokenId <= MAX_TOKENS) {
                _safeMint(msg.sender, tokenId);
                _cobiDetails[tokenId] = COBIDetail(first_encounter);
                _receivedCOBI[tokenId] = ReceivedCOBI(
                    msg.sender,
                    block.timestamp
                );
                emit TokenMinted(tokenId, msg.sender, first_encounter);
            }
        }
    }

    /**
     * Mint a specific token.
     */
    function mintTokenId(uint256 tokenId) public onlyOwner {
        require(!_exists(tokenId), "Token was minted");
        uint256 first_encounter = block.timestamp;
        _receivedCOBI[tokenId] = ReceivedCOBI(msg.sender, block.timestamp);
        _safeMint(msg.sender, tokenId);
        _cobiDetails[tokenId] = COBIDetail(first_encounter);
        emit TokenMinted(tokenId, msg.sender, first_encounter);
    }

    /*
     * Set provenance once it's calculated
     */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        PROVENANCE = provenanceHash;
    }

    /*
     * Set max tokens
     */
    function setMaxTokens(uint256 maxTokens) public onlyOwner {
        MAX_TOKENS = maxTokens;
    }

    /*
     * Pause sale if active, make active if paused
     */
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    /**
     * Mint COBI
     */
    function mintCOBI(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Mint is not available right now");
        require(
            numberOfTokens <= MAX_PURCHASE,
            "Can only mint 20 tokens at a time"
        );
        require(
            totalSupply().add(numberOfTokens) <= MAX_TOKENS,
            "Purchase would exceed max supply of BULL"
        );
        require(
            CURRENT_PRICE.mul(numberOfTokens) <= msg.value,
            "Value sent is not correct"
        );
        uint256 first_encounter = block.timestamp;
        uint256 tokenId;

        for (uint256 i = 1; i <= numberOfTokens; i++) {
            tokenId = totalSupply().add(1);
            if (tokenId <= MAX_TOKENS) {
                _safeMint(msg.sender, tokenId);
                _cobiDetails[tokenId] = COBIDetail(first_encounter);
                _receivedCOBI[tokenId] = ReceivedCOBI(
                    msg.sender,
                    block.timestamp
                );
                emit TokenMinted(tokenId, msg.sender, first_encounter);
            }
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        uint256 rewardAmount = getRewardAmount(
            _receivedCOBI[tokenId].receivedTime
        );
        if (rewardAmount != 0) {
            rewardToken.safeTransferFrom(
                masterAccountAddress,
                _receivedCOBI[tokenId].owner,
                rewardAmount
            );
        }
        super.safeTransferFrom(from, to, tokenId, "");
        _receivedCOBI[tokenId] = ReceivedCOBI(to, block.timestamp);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        uint256 rewardAmount = getRewardAmount(
            _receivedCOBI[tokenId].receivedTime
        );
        if (rewardAmount != 0) {
            rewardToken.safeTransferFrom(
                masterAccountAddress,
                _receivedCOBI[tokenId].owner,
                rewardAmount
            );
        }
        super.safeTransferFrom(from, to, tokenId, _data);
        _receivedCOBI[tokenId] = ReceivedCOBI(to, block.timestamp);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        uint256 rewardAmount = getRewardAmount(
            _receivedCOBI[tokenId].receivedTime
        );
        if (rewardAmount != 0) {
            rewardToken.safeTransferFrom(
                masterAccountAddress,
                _receivedCOBI[tokenId].owner,
                rewardAmount
            );
        }
        super.transferFrom(from, to, tokenId);

        _receivedCOBI[tokenId] = ReceivedCOBI(to, block.timestamp);
    }

    /**
     * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
     */
    function setBaseURI(string memory BaseURI) public onlyOwner {
        baseURI = BaseURI;
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * Set the current token price
     */
    function setCurrentPrice(uint256 currentPrice) public onlyOwner {
        CURRENT_PRICE = currentPrice;
    }

    /**
     * Get the token detail
     */
    function getCOBIDetail(uint256 tokenId)
        public
        view
        returns (COBIDetail memory detail)
    {
        require(_exists(tokenId), "Token was not minted");

        return _cobiDetails[tokenId];
    }

    function getRewardAmount(uint256 timestamp)
        internal
        view
        returns (uint256 rewardAmount)
    {
        if (block.timestamp < periodFinish)
            return (block.timestamp.sub(timestamp)).mul(rewardRate());

        if (block.timestamp > periodFinish && timestamp < periodFinish)
            return (periodFinish.sub(timestamp)).mul(rewardRate());

        return 0;
    }

    function rewardRate() internal view returns (uint256) {
        return totalReward.div(DURATION.mul(MAX_TOKENS));
    }

    function claimReward(uint256 _tokenId) public {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        require(msg.sender == ownerOf(_tokenId), "not from owner");
        rewardToken.safeTransferFrom(
            masterAccountAddress,
            msg.sender,
            getRewardAmount(_receivedCOBI[_tokenId].receivedTime)
        );
        _receivedCOBI[_tokenId].receivedTime = block.timestamp;
    }

    function multiClaim(uint256[] memory _tokenIds) public {
        uint256 totalRewardAmount = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                _exists(_tokenIds[i]),
                "ERC721Metadata: URI query for nonexistent token"
            );
            require(msg.sender == ownerOf(_tokenIds[i]), "not from owner");
            totalRewardAmount =
                totalRewardAmount +
                getRewardAmount(_receivedCOBI[_tokenIds[i]].receivedTime);
            _receivedCOBI[_tokenIds[i]].receivedTime = block.timestamp;
        }
        rewardToken.safeTransferFrom(
            masterAccountAddress,
            msg.sender,
            totalRewardAmount
        );
    }

    function getTotalRewards(uint256[] memory _tokenIds)
        public
        view
        returns (uint256 rewardAmount)
    {
        uint256 totalRewardAmount = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                _exists(_tokenIds[i]),
                "ERC721Metadata: URI query for nonexistent token"
            );
            require(msg.sender == ownerOf(_tokenIds[i]), "not from owner");
            totalRewardAmount =
                totalRewardAmount +
                getRewardAmount(_receivedCOBI[_tokenIds[i]].receivedTime);
        }
        return totalRewardAmount;
    }
}