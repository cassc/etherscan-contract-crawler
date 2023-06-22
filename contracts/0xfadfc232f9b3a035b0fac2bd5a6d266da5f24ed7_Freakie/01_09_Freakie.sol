// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract Freakie is ERC721A, VRFConsumerBaseV2, ReentrancyGuard, Ownable {
    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }

    bool public isAlreadyPrize;
    bool public finished; //
    bytes32 private root;
    bytes32 keyHash = 0x9fe0eebf5e446e3c998ec9bb19951541aee00bb90ea201ae456421a2ded86805;
    string private _baseTokenURI;

    VRFCoordinatorV2Interface COORDINATOR;

    uint256 private constant _collectionSize = 10000;
    uint256 public constant amountForFreeMint = 2900;
    uint256 public constant amountForSale = 7000;
    uint256 public constant amountForTeam = 100;
    uint256 public constant maxPerAddressDuringMint = 20;
    uint256 public immutable startTime;
    uint256 public sold;
    uint256 public numOfTeamsReceived;
    uint256 public numOfReceivedFree;
    uint256 public lotteryBlock;
    uint256 public lotteryTokenID;

    uint64 s_subscriptionId;
    uint32 callbackGasLimit = 2500000;
    uint32 numWords = 2;
    uint16 requestConfirmations = 3;

    mapping(address => uint256) public allowlist;
    mapping(address => uint256) public buyNum;
    mapping(address => bool) public isReceived;
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */

    constructor(uint256 _startTime, uint64 subscriptionId)
        ERC721A("Freakie", "FREAKIE")
        VRFConsumerBaseV2(0x271682DEB8C4E0901D1a1550aD2e64D568E69909)
    {
        startTime = _startTime;
        COORDINATOR = VRFCoordinatorV2Interface(0x271682DEB8C4E0901D1a1550aD2e64D568E69909);
        s_subscriptionId = subscriptionId;
    }

    event Mint(address indexed account, address inviter, uint256 quantity, uint256 payFee, uint256 rebates);
    event LotteryOpen(address account, uint256 randomNum, uint256 tokenId);
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function freeMint(bytes32[] memory proof) public callerIsUser {
        require(startTime != 0 && block.timestamp >= startTime, "free mint has not started yet");
        require(!isReceived[msg.sender], "already received");
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, 1))));
        require(MerkleProof.verify(proof, root, leaf), "Invalid proof");
        require(numOfReceivedFree < amountForFreeMint, "mint finished");
        require(totalSupply() + 1 <= _collectionSize, "reached max supply");
        unchecked {
            numOfReceivedFree = numOfReceivedFree + 1;
        }
        _safeMint(msg.sender, 1);
        isReceived[msg.sender] = true;
    }

    function teamMint() public {
        require(startTime != 0 && block.timestamp >= startTime, "team mint has not started yet");
        uint256 quantity = allowlist[msg.sender];
        require(quantity > 0, "nothing to mint");
        require(totalSupply() + quantity <= _collectionSize, "reached max supply");
        require(
            numOfTeamsReceived + quantity <= amountForTeam,
            "not enough remaining reserved for sale to support desired mint amount"
        );
        allowlist[msg.sender] = 0;
        _safeMint(msg.sender, quantity);
        unchecked {
            numOfTeamsReceived = numOfTeamsReceived + quantity;
        }
    }

    function mint(uint256 quantity, address inviter) external payable nonReentrant {
        require(startTime != 0 && block.timestamp >= startTime, "sale has not started yet");
        require(
            sold + quantity <= amountForSale, "not enough remaining reserved for sale to support desired mint amount"
        );
        require(totalSupply() + quantity <= _collectionSize, "reached max supply");
        require(buyNum[msg.sender] + quantity <= maxPerAddressDuringMint, "can not mint this many");
        uint256 rebates;
        uint256 payFee = checkoutCounter(quantity);
        if (inviter != address(0)) {
            require(numberMinted(inviter) > 0, "Invalid Inviter");
            rebates = (payFee * 15) / 100;
            payable(inviter).transfer(rebates);
        }
        _refundIfOver(payFee);
        _safeMint(msg.sender, quantity);
        buyNum[msg.sender] = buyNum[msg.sender] + quantity;
        unchecked {
            sold = sold + quantity;
        }
        if (sold == amountForSale) {
            lotteryBlock = block.number + 13000;
        }
        emit Mint(msg.sender, inviter, quantity, payFee, rebates);
    }

    function _refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function checkoutCounter(uint256 quantity) public view returns (uint256) {
        uint256 fee;
        for (uint256 index = sold; index < sold + quantity; index++) {
            uint256 price = getPrice(index);
            fee = fee + price;
        }
        return fee;
    }

    function getPrice(uint256 flag) public pure returns (uint256) {
        if (flag >= 4001) {
            return 80000000000000000; //0.08 eth
        } else if (flag >= 3001) {
            return 40000000000000000; //0.04 ETH
        } else if (flag >= 2001) {
            return 20000000000000000; // 0.02 ETH
        } else if (flag >= 1001) {
            return 10000000000000000; // 0.01 ETH
        } else {
            return 5000000000000000; //0.005 ETH
        }
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function seedAllowlist(address[] memory addresses, uint256[] memory numSlots) external onlyOwner {
        require(addresses.length == numSlots.length, "addresses does not match numSlots length");
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = numSlots[i];
        }
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function lotteryOpen() public nonReentrant {
        require(lotteryBlock != 0 && block.number >= lotteryBlock, "wait for block");
        require(!isAlreadyPrize, "AlreadyPrize");
        uint256 randomNum = _requestRandomWords();
        lotteryTokenID = randomNum % _collectionSize + 1;
        isAlreadyPrize = true;
        emit LotteryOpen(msg.sender, randomNum, lotteryTokenID);
    }

    function winerWithdraw() public callerIsUser nonReentrant {
        require(isAlreadyPrize, "wait for Lottery Open");
        require(!finished, "winer already withdraw");
        require(block.number <= lotteryBlock + 200000, "over deadline");
        address winer = IERC721A(address(this)).ownerOf(lotteryTokenID);
        require(winer == msg.sender, "sorry, U are not winer");
        finished = true;
        payable(msg.sender).transfer(100 ether);
    }

    //+++++++++++VRF+++++++++++//
    function _requestRandomWords() private returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId =
            COORDINATOR.requestRandomWords(keyHash, s_subscriptionId, requestConfirmations, callbackGasLimit, numWords);
        s_requests[requestId] = RequestStatus({randomWords: new uint256[](0), exists: true, fulfilled: false});

        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }
}