//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

//  _                   _    _         _     
// | |_  ___  ___ ._ _ | |_ <_> _ _  _| | ___
// | . \/ ._><_> || ' || . \| || '_>/ . |<_-<
// |___/\___.<___||_|_||___/|_||_|  \___|/__/
//                                  )  (
//                                (   ) )
//                                 ) ( (
//                               _______)_
//                            .-'---------|  
//                           ( C|---------|
//                            '-.---------|
//                              '_________'
//                               '-------'

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";
import "./Base64.sol";

contract BeanbirdsCoffee is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private tokenCounter;
    using Strings for uint256; 
    string private stampURI;
    uint256 public constant MAX_PUNCH_CARDS_PER_WALLET = 1;
    uint256 public constant MAX_PUNCHES_PER_CARD = 12;
    uint256 public maxPunchCards;
    uint256 public salePrice = 0.017 ether;
    bool public isSaleActive;
    mapping(uint256 => PunchCard) public punchCards;
    event NewPunchCard(address, uint256, uint256);
    event RepeatCustomer(address, uint256, uint256);
    event RewardRedeemed(address, uint256);

    struct PunchCard {
        uint256 punchCount;
        uint256 rewardCount;
    }

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier saleActive() {
        require(isSaleActive, "Not open for sale");
        _;
    }

    modifier maxPunchCardsPerWallet() {
        require(
            balanceOf(msg.sender) + 1 <= MAX_PUNCH_CARDS_PER_WALLET,
            "Max punch cards to mint is one"
        );
        _;
    }

    modifier canMintPunchCards() {
        require(
            tokenCounter.current() + 1 <= maxPunchCards,
            "Not enough punch cards remaining to mint"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 quantity) {
        require(
            price * quantity == msg.value,
            "Incorrect ETH value or quantity sent"
        );
        _;
    }

    modifier rewardsAvailable(uint256 tokenId) {
        require(
            punchCards[tokenId].rewardCount >= 1,
            "No rewards available to redeem"
        );
        _;
    }

    modifier isPunchCardOwner(uint256 tokenId) {
        require(
            msg.sender == ownerOf(tokenId),
            "Not your punch card"
        );
        _;
    }

    constructor(
        uint256 _maxPunchCards,
        string memory _stampURI
    ) ERC721("Beanbirds Coffee Co.", "BNBRDCFE") {
        maxPunchCards = _maxPunchCards;
        stampURI = _stampURI;
        isSaleActive = true;
    }

    function mint(uint256 quantity)
        external
        payable
        nonReentrant
        isCorrectPayment(salePrice, quantity)
        saleActive
        canMintPunchCards()
        maxPunchCardsPerWallet()
    {
        uint256 tokenId = nextTokenId();
         _safeMint(msg.sender, tokenId);
         stampCard(tokenId, quantity);
         emit NewPunchCard(msg.sender, tokenId, quantity);
    }

    function repeatCustomer(uint256 tokenId, uint256 quantity)
        external
        payable
        nonReentrant
        isCorrectPayment(salePrice, quantity)
        saleActive
        isPunchCardOwner(tokenId)
    {
         stampCard(tokenId, quantity);
         emit RepeatCustomer(msg.sender, tokenId, quantity);
    }

    function redeemReward(uint256 tokenId)
        external
        nonReentrant
        saleActive
        rewardsAvailable(tokenId)
        isPunchCardOwner(tokenId)
    {
        useReward(tokenId);
        emit RewardRedeemed(msg.sender, tokenId);
    }


    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============

    function getStampURI() external view returns (string memory) {
        return stampURI;
    }

    function getLastTokenId() external view returns (uint256) {
        return tokenCounter.current();
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============

    function setStampURI(string memory _stampURI) external onlyOwner {
        stampURI = _stampURI;
    }

    function setIsSaleActive(bool _isSaleActive) external onlyOwner {
        isSaleActive = _isSaleActive;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxPunchCards = _maxSupply;
    }

    function setSalePrice(uint256 _salePrice) external onlyOwner {
        salePrice = _salePrice;
    }

    function setRewardCount(uint256 _tokenId, uint256 _rewardCount) public onlyOwner {
        punchCards[_tokenId].rewardCount = _rewardCount;
    }

    function createPunchCard(address recipient, uint256 _rewardCount) external onlyOwner {
        uint256 tokenId = nextTokenId();
        _safeMint(recipient, tokenId);
        stampCard(tokenId, 0);
        setRewardCount(tokenId, _rewardCount);
        emit NewPunchCard(recipient, tokenId, 0);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    // ============ SUPPORTING FUNCTIONS ============

    function nextTokenId() private returns (uint256) {
        tokenCounter.increment();
        return tokenCounter.current();
    }

    function stampCard(uint256 tokenId, uint256 quantity) private returns (uint256) {
        if (quantity >= MAX_PUNCHES_PER_CARD) {
            punchCards[tokenId].rewardCount = (punchCards[tokenId].rewardCount + quantity) / MAX_PUNCHES_PER_CARD;
        } else {
            if ((currentPunchCount(tokenId) + quantity) >= MAX_PUNCHES_PER_CARD) {
                punchCards[tokenId].rewardCount = punchCards[tokenId].rewardCount + 1;
            }
        }
        punchCards[tokenId].punchCount = punchCards[tokenId].punchCount + quantity;
        return punchCards[tokenId].punchCount;
    }

    function useReward(uint256 tokenId) private returns (uint256) {
        punchCards[tokenId].rewardCount = punchCards[tokenId].rewardCount - 1;
        return punchCards[tokenId].rewardCount;
    }

    function currentPunchCount(uint256 tokenId) public view returns (uint256) {
        return punchCards[tokenId].punchCount % MAX_PUNCHES_PER_CARD;
    }

    function currentRewardCount(uint256 tokenId) public view returns (uint256) {
        return punchCards[tokenId].rewardCount;
    }

    // ============= OVERRIDES ====================

    function tokenURI(uint256 tokenId) override(ERC721) public view virtual returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": "Beanbirds Coffee Co. - Member #', tokenId.toString(), '",',
                    '"image": "', stampURI, currentPunchCount(tokenId).toString(), '.png",',
                    '"attributes": [{"value": "', uint2str(punchCards[tokenId].punchCount),' Total Bags"', '},',
                    '{"value": "', currentRewardCount(tokenId).toString(),' Rewards"', '},',
                    '{"value": "', currentPunchCount(tokenId).toString(),' Punches"', '}',
                    ']}'
                )
            ))
        );
        return string(abi.encodePacked('data:application/json;base64,', json));
    }
    receive() external payable {}
} // xoxo-x