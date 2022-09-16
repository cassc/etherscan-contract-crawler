// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract MojorEarlyBirdTicket is Ownable, ERC721A, ReentrancyGuard {

    uint public maxBatchSize_ = 5000;
    uint public collectionSize_ = 5000;

    event paramTimeEvent      (uint parmsTime);
    event paramAddressSurplusNumsEvent      (address ads, uint alSurplusNums, uint wlSurplusNums);
    event addMintParticipantEvent      (address ads);
    event luckyWinnerBirthEvent    (address ads, uint tokenId);
    event luckyNumBirthEvent       (uint noc);

    uint256 public constant CONTRIBUTE_MINT_ONE_QUANTITY = 1;
    uint256 public constant CONTRIBUTE_MINT_TWO_QUANTITY = 2;
    uint256 public constant CONTRIBUTE_MINT_THREE_QUANTITY = 3;
    uint256 public constant CONTRIBUTE_MINT_AL_QUANTITY = 800;

    mapping(address => uint) public participantsWaitingList;
    mapping(address => uint) public participantsWaitingListMinted;
    mapping(address => uint) public participantsAllowList;
    mapping(address => uint) public participantsAllowListMinited;
    mapping(uint => address) public participantMaps;
    address[10000] public mintList;
    uint public mintListNo = 0;
    uint public mintStartTime;
    uint public mintEndTime;

    bytes32 public WLOneRoot;
    bytes32 public WLTwoRoot;
    bytes32 public WLThreeRoot;
    bytes32 public WLTALRoot;

    // // metadata URI
    string private _baseTokenURI;

    constructor() ERC721A("Mojor Early Bird Ticket", "MOJOR EARLY BIRD TICKET", maxBatchSize_, collectionSize_) {
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setWLOneRoot(bytes32 merkleroot) external onlyOwner {
        WLOneRoot = merkleroot;
    }

    function setWLTwoRoot(bytes32 merkleroot) external onlyOwner {
        WLTwoRoot = merkleroot;
    }

    function setWLThreeRoot(bytes32 merkleroot) external onlyOwner {
        WLThreeRoot = merkleroot;
    }

    function setWLFourRoot(bytes32 merkleroot) external onlyOwner {
        WLTALRoot = merkleroot;
    }

    function safeMint(bytes32[] calldata proof) public {
        require(totalSupply() < 10000, "Maximum limit 10000");

        if (mintStartTime == 0 || block.timestamp < mintStartTime) {
            revert("Not Time To Mint");
        }


        //ONLY MINT BY ALLOW LIST TIME
        uint alSurplus = participantsAllowList[msg.sender] - participantsAllowListMinited[msg.sender];

        if (block.timestamp >= mintStartTime && block.timestamp <= mintEndTime) {
            if (alSurplus <= 0) {
                revert("Can Not Mint More");
            }
            participantsAllowListMinited[msg.sender] = participantsAllowListMinited[msg.sender] + alSurplus;
            _safeMint(msg.sender, alSurplus);
            mintList[mintListNo] = msg.sender;
            mintListNo++;
            emit  paramAddressSurplusNumsEvent(msg.sender, alSurplus - alSurplus, 0);
        }

        bool isMinted = false;
        if (block.timestamp > mintEndTime) {
            uint wlMinted = participantsAllowListMinited[msg.sender];
            require(wlMinted == 0, "Can Not Mint More");
            uint WLProofSurplus = 0;

            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            bool OneisValidLeaf = MerkleProof.verify(proof, WLOneRoot, leaf);
            if (OneisValidLeaf) {
                WLProofSurplus = CONTRIBUTE_MINT_ONE_QUANTITY;
            }

            bool TwoisValidLeaf = MerkleProof.verify(proof, WLTwoRoot, leaf);
            if (TwoisValidLeaf) {
                WLProofSurplus = CONTRIBUTE_MINT_TWO_QUANTITY;
            }

            bool ThreeisValidLeaf = MerkleProof.verify(proof, WLThreeRoot, leaf);
            if (ThreeisValidLeaf) {
                WLProofSurplus = CONTRIBUTE_MINT_THREE_QUANTITY;
            }

            bool ALisValidLeaf = MerkleProof.verify(proof, WLTALRoot, leaf);
            if (ALisValidLeaf) {
                WLProofSurplus = CONTRIBUTE_MINT_AL_QUANTITY;
            }
            if (WLProofSurplus > 0) {
                participantsWaitingListMinted[msg.sender] = participantsAllowListMinited[msg.sender] + WLProofSurplus;
                emit paramAddressSurplusNumsEvent(msg.sender, WLProofSurplus, 0);
                _safeMint(msg.sender, WLProofSurplus);
                isMinted = true;
            }
            //ALSURPLUS ENOUGH
            if (alSurplus > 0) {
                participantsAllowListMinited[msg.sender] = participantsAllowListMinited[msg.sender] + alSurplus;
                emit paramAddressSurplusNumsEvent(msg.sender, alSurplus - alSurplus, 0);
                _safeMint(msg.sender, alSurplus);
                isMinted = true;
            }

            if (isMinted) {
                mintList[mintListNo] = msg.sender;
                mintListNo++;
            }
        }
    }

    function projectCreation(uint count) public onlyOwner {
        require(totalSupply() + count < 10000, "Maximum limit 10000");
        _safeMint(msg.sender, count);
        mintList[mintListNo] = msg.sender;
        mintListNo++;

    }


    function isMintedTotal(address participant) public view returns (uint){
        uint wlMinted = participantsWaitingListMinted[participant];
        uint alMinted = participantsAllowListMinited[participant];
        uint totalMinted = wlMinted + alMinted;
        if (totalMinted > 0) {
            return totalMinted;
        }
        return 0;
    }

    function isMintedByWL(address participant) public view returns (uint){
        uint wlMinted = participantsWaitingListMinted[participant];
        if (wlMinted > 0) {
            return wlMinted;
        }
        return 0;
    }

    function isMintedByAL(address participant) public view returns (uint){
        uint alMinted = participantsAllowListMinited[participant];
        if (alMinted > 0) {
            return alMinted;
        }
        return 0;
    }


    function isValid(address participant, bytes32[] calldata proof) public view returns (uint){
        uint alSurplus = participantsAllowList[participant] - participantsAllowListMinited[participant];
        //ALL MINT TIME
        uint WLProofSurplus = 0;
        bytes32 leaf = keccak256(abi.encodePacked(participant));
        bool OneisValidLeaf = MerkleProof.verify(proof, WLOneRoot, leaf);
        if (OneisValidLeaf) {
            WLProofSurplus = CONTRIBUTE_MINT_ONE_QUANTITY;
        }

        bool TwoisValidLeaf = MerkleProof.verify(proof, WLTwoRoot, leaf);
        if (TwoisValidLeaf) {
            WLProofSurplus = CONTRIBUTE_MINT_TWO_QUANTITY;
        }

        bool ThreeisValidLeaf = MerkleProof.verify(proof, WLThreeRoot, leaf);
        if (ThreeisValidLeaf) {
            WLProofSurplus = CONTRIBUTE_MINT_THREE_QUANTITY;
        }

        bool ALisValidLeaf = MerkleProof.verify(proof, WLTALRoot, leaf);
        if (ALisValidLeaf) {
            WLProofSurplus = CONTRIBUTE_MINT_AL_QUANTITY;
        }
        uint wlSurplus = WLProofSurplus - participantsWaitingListMinted[participant];
        uint totalMinted = wlSurplus + alSurplus;
        if (totalMinted > 0) {
            return totalMinted;
        }
        return 0;
    }

    function setMintTimes(uint startTime, uint endTime) public onlyOwner {
        mintStartTime = startTime;
        mintEndTime = endTime;
    }

    function setParticipantAllowList(address[] memory ads,uint[] memory nums) onlyOwner public {
        for (uint a = 0; a < ads.length; a++) {
            participantsAllowList[ads[a]] = participantsAllowList[ads[a]] + nums[a];
        }
    }

}