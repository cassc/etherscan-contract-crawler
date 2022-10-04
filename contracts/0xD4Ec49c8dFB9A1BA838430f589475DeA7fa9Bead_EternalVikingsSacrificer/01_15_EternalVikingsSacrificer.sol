// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "../interfaces/IEternalVikings.sol";
import "../interfaces/IEternalVikingsWhitelistToken.sol";
import "../interfaces/IEternalVikingsStaking.sol";
import "../interfaces/IEternalVikingsGoldToken.sol";

contract EternalVikingsSacrificer is OwnableUpgradeable {
    using ECDSA for bytes32;

    IEternalVikings public EVNFT;
    IERC721 public EVWL;
    IEternalVikingsStaking public EVStaking;
    address public EVSacrificeReceiver;
    address public EVAltReceiver;

    // Global
    bytes32 public collectionsMerkleRoot;
    bytes32 public preMintMerkleRoot;
    uint256 public evMaxSupply;
    uint256 public walletLimit;
    uint256 public altp;
    mapping(address => uint256) public walletCount;

    // Timing
    uint256 public privateStart;
    uint256 public privateEnd;

    uint256 public preMintStart;
    uint256 public preMintEnd;

    uint256 public publicStart;
    uint256 public publicEnd;

    // Testing
    mapping(address => bool) public authorizedTester;

    // Signature
    address public authorizedSigner;

    // Gold bribe
    IEternalVikingsGoldToken public goldToken;
    uint256 public goldPrice;

    // Ring auction
    mapping(uint256 => mapping(address => uint256)) public ringBids;
    mapping(uint256 => uint256) public ringHighestBid;
    mapping(uint256 => address) public ringHighestBidder;
    mapping(uint256 => uint256) public ringAuctionDeadline;    

    event Sacrifice(address user, address sacrificedCollection, uint256 sacrificedTokenId, uint256 mintedVikingId, bool isStaked);
    event Bribe(address user, uint256 mintedVikingId);
    event BribeGold(address user, uint256 mintedVikingId);

    constructor(
        address ev,
        address evwl,
        address receiver,
        address altReceiver
    ) {}

    function initialize(
        address ev,
        address evwl,
        address receiver,
        address altReceiver
    ) public initializer {
        __Ownable_init();

        EVNFT = IEternalVikings(ev);
        EVWL = IERC721(evwl);
        EVSacrificeReceiver = receiver;
        EVAltReceiver = altReceiver;
    }
    
    receive() external payable {}

    function enterAuction(uint256 auctionId, uint256 bid) external {
        uint256 senderExistingBid = ringBids[auctionId][msg.sender];
        uint256 auctionDeadline = ringAuctionDeadline[auctionId];
        uint256 auctionHighestBid = ringHighestBid[auctionId];

        require(address(goldToken) != address(0), "Gold not set");
        require(auctionDeadline > 0, "Auction at id not set");
        require(auctionDeadline >= block.timestamp, "Auction passed deadline");
        require(bid > auctionHighestBid, "Higher bid exists");

        uint256 goldPayAmount = bid - senderExistingBid;
        goldToken.consume(msg.sender, goldPayAmount);

        ringBids[auctionId][msg.sender] = bid;
        ringHighestBid[auctionId] = bid;
        ringHighestBidder[auctionId] = msg.sender;
    }

    function vikingAirdrops(address[] memory receivers, uint256[] memory amount) external onlyOwner {
        require(receivers.length > 0);
        require(amount.length > 0);
        require(receivers.length == amount.length);

        for (uint i = 0; i < receivers.length; i++) {
            EVNFT.mint(receivers[i], amount[i]);
        }
    }

    function signatureTester(
        address user,
        address collection, 
        uint256 assetId, 
        uint256 expiration,
        bytes memory signature
    ) external view returns (bool) {
        verifySignature(user, collection, assetId, expiration, signature);
        return true;
    }

    function sacrificeNew(
        address collection, 
        uint256 assetId, 
        uint256 expiration,
        bytes memory signature,
        bool stake,
        bool isERC1155
    ) external {
        require(address(EVSacrificeReceiver) != address(0), "Receiver not set");

        require(walletCount[msg.sender] < walletLimit, "User exceeds sacrifice limit");
        walletCount[msg.sender]++;
        require(EVNFT.totalSupply() < evMaxSupply, "No more supply left");

        verifySignature(msg.sender, collection, assetId, expiration, signature);
       
        if (isERC1155) {
            require(IERC1155(collection).balanceOf(msg.sender, assetId) > 0, "Sender does not own asset in collection");
            require(IERC1155(collection).isApprovedForAll(msg.sender, address(this)), "Contract not approved for NFT transfer");
            IERC1155(collection).safeTransferFrom(msg.sender, EVSacrificeReceiver, assetId, 1, "");
        } else {
            require(IERC721(collection).ownerOf(assetId) == msg.sender, "Sender not owner of assetId in collection");
            require(
                IERC721(collection).getApproved(assetId) == address(this) || 
                IERC721(collection).isApprovedForAll(msg.sender, address(this)),
                "Contract not approved for NFT transfer"
            );
            IERC721(collection).transferFrom(msg.sender, EVSacrificeReceiver, assetId);
        }        

        EVNFT.mint(msg.sender, 1);
        uint256 mintedViking = EVNFT.totalSupply();
        if (stake) {
            uint256[] memory evIds = new uint256[](1);
            evIds[0] = mintedViking;
            EVStaking.delegateStakeVikings(msg.sender, evIds);
        }

        emit Sacrifice(msg.sender, collection, assetId, mintedViking, stake);
    }

    function sacrificeAltNew() external payable {
        require(address(EVSacrificeReceiver) != address(0), "Receiver not set");

        require(walletCount[msg.sender] < walletLimit, "User exceeds sacrifice limit");
        walletCount[msg.sender]++;
        require(EVNFT.totalSupply() < evMaxSupply, "No more supply left");       

        require(msg.value >= altp, "Incorrect msg.value");

        EVNFT.mint(msg.sender, 1);
        uint256 mintedVikingId = EVNFT.totalSupply();

        uint256[] memory evIds = new uint256[](1);
        evIds[0] = mintedVikingId;
        EVStaking.delegateStakeVikings(msg.sender, evIds);

        emit Bribe(msg.sender, mintedVikingId);
    }

    function sacrificeGold() external {
        require(address(EVSacrificeReceiver) != address(0), "Receiver not set");
        require(address(goldToken) != address(0), "Gold not set");

        require(walletCount[msg.sender] < walletLimit, "User exceeds sacrifice limit");
        walletCount[msg.sender]++;
        require(EVNFT.totalSupply() < evMaxSupply, "No more supply left");       

        goldToken.consume(msg.sender, goldPrice);

        EVNFT.mint(msg.sender, 1);
        uint256 mintedVikingId = EVNFT.totalSupply();

        uint256[] memory evIds = new uint256[](1);
        evIds[0] = mintedVikingId;
        EVStaking.delegateStakeVikings(msg.sender, evIds);

        emit BribeGold(msg.sender, mintedVikingId);
    }

    function whitelistMint(uint256 tokenId, bool stake) external {
        require(block.timestamp >= privateStart || authorizedTester[msg.sender], "Private not started");
        require(block.timestamp < privateEnd, "Private finished");
        
        require(IERC721(address(EVWL)).ownerOf(tokenId) == msg.sender, "User does not own whitelist token");
        require(EVNFT.totalSupply() < evMaxSupply, "No more supply left");
        walletCount[msg.sender]++;
        
        EVWL.transferFrom(msg.sender, EVSacrificeReceiver, tokenId);
        EVNFT.mint(msg.sender, 1);

        if (stake) {
            uint256[] memory evIds = new uint256[](1);
            evIds[0] = EVNFT.totalSupply();
            EVStaking.delegateStakeVikings(msg.sender, evIds);
        }
    }

    function getRemainingVikings() external view returns (uint256) {
        uint256 totalSupply = EVNFT.totalSupply();
        uint256 maxSupply = evMaxSupply;
        if (totalSupply > maxSupply)
            return 0;
        else
            return maxSupply - totalSupply;
    }

    function withdraw() external onlyOwner {
        payable(EVAltReceiver).transfer(address(this).balance);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    function verifySignature(
        address user,
        address collection,
        uint256 tokenId,
        uint256 expiration,
        bytes memory signature
    ) internal view {
        require(block.timestamp <= expiration, "Signature expired");
        bytes32 message = keccak256(abi.encodePacked(user, collection, tokenId, expiration)).toEthSignedMessageHash();
        require(recoverSigner(message, signature) == authorizedSigner, "SIGNATURE NOT FROM SIGNER WALLET");
    }

    function setEV(address ev) external onlyOwner {
        EVNFT = IEternalVikings(ev);
    }

    function setEVWL(address evwl) external onlyOwner {
        EVWL = IERC721(evwl);
    }

    function setEVStaking(address staking) external onlyOwner {
        EVStaking = IEternalVikingsStaking(staking);
    }

    function setEVSacrificeReceiver(address receiver) external onlyOwner {
        EVSacrificeReceiver = receiver;
    }

    function setEVAltReceiver(address receiver) external onlyOwner {
        EVAltReceiver = receiver;
    }

    function setCollectionsMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        collectionsMerkleRoot = merkleRoot;
    }   

    function setPreMintMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        preMintMerkleRoot = merkleRoot;
    }    

    function setEVMaxSupply(uint256 maxSupply) external onlyOwner {
        evMaxSupply = maxSupply;
    }

    function setLimit(uint256 limit) external onlyOwner {
        walletLimit = limit;
    }

    function setAltP(uint256 _altP) external onlyOwner {
        altp = _altP;
    }

    function setPrivateDates(uint256 start, uint256 end) external onlyOwner {
        privateStart = start;
        privateEnd = end;
    }

    function setPreMintDates(uint256 start, uint256 end) external onlyOwner {
        preMintStart = start;
        preMintEnd = end;
    }

    function setPublicDates(uint256 start, uint256 end) external onlyOwner {
        publicStart = start;
        publicEnd = end;
    }  

    function setAuthorizedTesters(address[] memory testers, bool[] memory states) external onlyOwner {
        require(testers.length == states.length);
        for (uint i = 0; i < testers.length; i++) {
            authorizedTester[testers[i]] = states[i];
        }
    }

    function setAuthorizedSigner(address signer) external onlyOwner {
        authorizedSigner = signer;
    }

    function setGoldToken(address _token) external onlyOwner {
        goldToken = IEternalVikingsGoldToken(_token);
    }

    function setGoldPrice(uint256 price) external onlyOwner {
        goldPrice = price;
    }

    function addRingAuction(uint256 id, uint256 deadline) external onlyOwner {
        require(deadline > block.timestamp + 3600, "Invalid deadline");
        require(ringAuctionDeadline[id] == 0, "Auction at Id already set");
        ringAuctionDeadline[id] = deadline;
    }
}