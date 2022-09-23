// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "../interfaces/IEternalVikings.sol";
import "../interfaces/IEternalVikingsWhitelistToken.sol";
import "../interfaces/IEternalVikingsStaking.sol";

contract EternalVikingsSacrificer is OwnableUpgradeable {
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

    function vikingAirdrops(address[] memory receivers, uint256[] memory amount) external onlyOwner {
        require(receivers.length > 0);
        require(amount.length > 0);
        require(receivers.length == amount.length);

        for (uint i = 0; i < receivers.length; i++) {
            EVNFT.mint(receivers[i], amount[i]);
        }
    }

    function sacrifice(
        address collection, 
        uint256 assetId, 
        bytes32[] calldata collectionProof,
        bytes32[] calldata preMintProof,
        bool stake,
        bool isERC1155
    ) external {
        require(address(EVSacrificeReceiver) != address(0), "Receiver not set");
        require(block.timestamp >= preMintStart || authorizedTester[msg.sender], "Sacrifice not started");
        require(block.timestamp < publicEnd, "Sacrifice finished");

        require(walletCount[msg.sender] < walletLimit, "User exceeds sacrifice limit");
        if (walletCount[msg.sender] == 1) {
            require(EVStaking.walletEVStakeCount(msg.sender) == 1, "User did not stake first viking");
        }
        walletCount[msg.sender]++;
        require(EVNFT.totalSupply() < evMaxSupply, "No more supply left");

        if (block.timestamp < preMintEnd) {
            bytes32 preMintLeaf = keccak256(abi.encodePacked(msg.sender));
            require(
                MerkleProof.verify(preMintProof, preMintMerkleRoot, preMintLeaf),
                "Sender not allowed to mint in this round"
            );
        }

        bytes32 collectionLeaf = keccak256(abi.encodePacked(collection));
        require(
            MerkleProof.verify(collectionProof, collectionsMerkleRoot, collectionLeaf),
            "Collection not qualified"
        );

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
        if (stake) {
            uint256[] memory evIds = new uint256[](1);
            evIds[0] = EVNFT.totalSupply();
            EVStaking.delegateStakeVikings(msg.sender, evIds);
        }
    }

    function sacrificeAlt(
        bytes32[] calldata preMintProof
    ) external payable {
        require(address(EVSacrificeReceiver) != address(0), "Receiver not set");
        require(block.timestamp >= preMintStart || authorizedTester[msg.sender], "Sacrifice not started");
        require(block.timestamp < publicEnd, "Sacrifice finished");

        require(walletCount[msg.sender] < walletLimit, "User exceeds sacrifice limit");
        if (walletCount[msg.sender] == 1) {
            require(EVStaking.walletEVStakeCount(msg.sender) == 1, "User did not stake first viking");
        }
        walletCount[msg.sender]++;
        require(EVNFT.totalSupply() < evMaxSupply, "No more supply left");

        if (block.timestamp < preMintEnd) {
            bytes32 preMintLeaf = keccak256(abi.encodePacked(msg.sender));
            require(
                MerkleProof.verify(preMintProof, preMintMerkleRoot, preMintLeaf),
                "Sender not allowed to mint in this round"
            );
        }

        require(msg.value >= altp, "Incorrect msg.value");

        EVNFT.mint(msg.sender, 1);

        uint256[] memory evIds = new uint256[](1);
        evIds[0] = EVNFT.totalSupply();
        EVStaking.delegateStakeVikings(msg.sender, evIds);
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
}