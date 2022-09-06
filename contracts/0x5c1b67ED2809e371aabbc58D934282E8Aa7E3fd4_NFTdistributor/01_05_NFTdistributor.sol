// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
interface IERC721 {
        function transferFrom(address from, address to, uint256 tokenId) external;
    }


interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
}

//////////////////////////////////////////////////////////////////////////////////////
// @title NFTdistributor
// @version 0.2
// @author  H & K
// @dev     This contract is used to distribute NFTs to subscribers.
// @dev     The contract is deployed with the following parameters:
// @dev     - subscriptionId: The subscriptionId of chainlink VRF v2 service.
//   ____
//  /\' .\    _____
// /: \___\  / .  /\
// \' / . / /____/..\
//  \/___/  \'  '\  /
//           \'__'\/
//
// NFTDistributorv2: A smart contract that uses Chainlink VRF to fairly distribute NFTs
//////////////////////////////////////////////////////////////////////////////////////


contract NFTdistributor is VRFConsumerBaseV2, Ownable {
    VRFCoordinatorV2Interface COORDINATOR;

    // Chainlik subscription ID.
    uint64 s_subscriptionId;

    // Goerli 
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909; // mainnet

    // The gas lane
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;  // mainnet

    // ~20.000 gas per word
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    uint256[] public s_randomWords;
    uint256 public s_requestId;
    address public s_NFTAddress;  // current NFT contract address that will be rewarded
    uint256 public s_NFTId;  // current NFT id that will be rewarded

    address[] public mintSpots;
    mapping(address => uint256) public mintSpotBalance;
    mapping(bytes32 => uint256) private randomnessRequest;


    // events
    event MintSpotsBought(address indexed sender, uint256 amount);
    event RandomWordsReceived(uint256[] randomWords);
    event NFTRewarded(address indexed winner, uint256 NFTId);

    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
    }

    // mintspot price of 0.0066 ether  (~$10)
    uint256 public mintPrice = 6600000000000000;

    function exists1(address addr) public view returns (bool) {
        for (uint256 i = 0; i < mintSpots.length; i++) {
            if (mintSpots[i] == addr) {
                return true;
            }
        }
        return false;
    }

    function buyMintSpots(uint256 _amount) public payable {
        require(_amount > 0, "Value must be greater than 0");
        require(msg.value >= mintPrice * _amount, "Not enough ETH");
        mintSpotBalance[msg.sender] += _amount;
        // if address not in array, add it
        if (!exists1(msg.sender)) {
            mintSpots.push(msg.sender);
        }
        emit MintSpotsBought(msg.sender, _amount);
    }

    function transferNFT(address NFTAddress, address _receiver, uint256 _NFTId) internal {
        IERC721 NFT = IERC721(NFTAddress); // Create an instance of the NFT contract

        // Calling the NFT smart contract transferFrom function
        NFT.transferFrom(address(this), _receiver, _NFTId);
    }

    // Start NFT lottery distribution process
    // ASSUMES the subscription is funded sufficiently.
    function requestRandomWords(address NFTAddress, uint256 _NFTId) external onlyOwner {
        // store NFT address and id so that no chickanery can be done!
        s_NFTAddress = NFTAddress;
        s_NFTId = _NFTId;

        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    // callback function that is called when the random words are ready
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        s_randomWords = randomWords;
        emit RandomWordsReceived(s_randomWords);

        // call rewardNFT()  // Gas cost limit considerations
    }

    
    function hasBalance(address addr) public view returns (bool) {
        return mintSpotBalance[addr] > 0;
    }

    function rewardNFT() external onlyOwner {
        // select winner address from Chainlink VRF random words
        uint256 winnerIndex = s_randomWords[0] % mintSpots.length;
        // check if winner address has any balance
        while (!hasBalance(mintSpots[winnerIndex])) {
            winnerIndex = winnerIndex + 1;
        }
        // transfer NFT to winner address
        transferNFT(s_NFTAddress, mintSpots[winnerIndex], s_NFTId);
        // lower balance of winner address by 1
        mintSpotBalance[mintSpots[winnerIndex]] -= 1;
        emit NFTRewarded(mintSpots[winnerIndex], s_NFTId);
    }

    function withdrawFunds() external onlyOwner {
        // withdraw funds from contract
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
    }
}