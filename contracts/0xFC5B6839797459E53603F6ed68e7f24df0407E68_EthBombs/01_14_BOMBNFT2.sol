//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

//Goerli testnet contract
contract EthBombs is ERC721A, ERC721AQueryable, ReentrancyGuard, Ownable, VRFConsumerBaseV2, KeeperCompatible {

    VRFCoordinatorV2Interface COORDINATOR;
    uint64 subscriptionId;
    
    bytes32 private keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
    uint16 private requestConfirmations = 40;
    uint256[1] private randomWordsForRewards;
    uint32 private callbackGasLimit = 120000;
    uint32 private numWords = 1;

    uint256 lastTimestamp;
    bool winnersDetermined;

    uint256 public teamPoolBalance;
    uint256 public BigBangBalance;

    mapping (address => uint256) public freeMintAddresses;
    uint256 freeMintCount;

    struct WinnerInfo {
        bool eligible;
        bool withdrawn;
    }

    mapping (uint256 => uint256) public tokenIDtoColorID;
    mapping (uint256 => bool) public explodedColorsMetadata;

    mapping (uint256 => WinnerInfo) public checkBigPrize; //1 ETH
    mapping (uint256 => WinnerInfo) public checkSmallPrize; //0.25 ETH

    address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;

    //Merkle root for allowlist
    bytes32 public merkleRoot = 0x8b8409a9850d71fb5ae5374ca1cc9597123eafc4a9b2b308068e8fc25b0c44b7;

    uint256[] public dynamicArray = [
        111, //Blue 
        222, //Green 
        333, //Orange 
        444, //Pink 
        555, //Purple 
        666, //Red 
        777 //Yellow 
    ];

    event BombMinted(address indexed minter, uint256 indexed colorID, uint256 tokenID);

    //subscriptionID: 71 
    constructor(uint64 _subscriptionId) VRFConsumerBaseV2(vrfCoordinator) ERC721A("ETH BOMBS", "BOOM") {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        subscriptionId = _subscriptionId;
    }

    //Change Keepers conditions
    //Change mintPerAddress for mint and freeMint

    function freeMint(bytes32[] calldata _merkleProof, uint256[] memory colorList) public {
        uint256 quantity = colorList.length;

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Not in the allowlist");
        require(quantity + freeMintAddresses[msg.sender] <= 2, "Max amount of NFTs claimed for this address"); 

        uint256 totalMinted = _totalMinted();

        for (uint i; i < quantity; i++) {
            uint256 index = colorList[i];
            require((dynamicArray[index] / 111) == index + 1); 
            tokenIDtoColorID[totalMinted] = dynamicArray[index];
            dynamicArray[index] += 1;
            emit BombMinted(msg.sender, index, totalMinted);
            totalMinted++;
        }
        
        freeMintAddresses[msg.sender] += quantity;
        freeMintCount++;
        _safeMint(msg.sender, quantity);

    }

    function mint(uint256[] memory colorList) external payable {
        uint256 quantity = colorList.length;

        require(msg.value == 10000000000000000 * quantity, "Not enough ETH"); //Mint price is 0.01 Ether
        require(quantity + showFreePlusMint(msg.sender) <= 7, "Max amount of NFTs claimed for this address"); 
        
        uint256 totalMinted = _totalMinted();

        for (uint i; i < quantity; i++) {
            uint256 index = colorList[i];
            require((dynamicArray[index] / 111) == index + 1); 
            tokenIDtoColorID[totalMinted] = dynamicArray[index];
            dynamicArray[index] += 1;
            emit BombMinted(msg.sender, index, totalMinted);
            totalMinted++;
        }

        teamPoolBalance += (msg.value) * 15 / 100;
        BigBangBalance += (msg.value) * 50 / 100;

        _safeMint(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
       return "ipfs://bafybeibfgeou2i4wwy66hlqbbwl52jgvdx72f4ea6xpixwdlbjvl3jlxzm/";
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        uint256 colorID = tokenIDtoColorID[tokenId];
        uint256 colorIPFS = colorID / 111;

        if (explodedColorsMetadata[colorIPFS]) {
            return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(8))) : '';
        }

        else {

            if (winnersDetermined && checkSmallPrize[colorID - (dynamicArray[0] - 111)].eligible) {
                return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(9))) : '';
            }
            if (winnersDetermined && checkBigPrize[colorID - (dynamicArray[0] - 111)].eligible) {
                return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(10))) : '';
            }

            return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(colorIPFS))) : '';
        }
    }

    // Assumes the subscription is funded sufficiently.
    // Will revert if subscription is not set and funded.
    
    function requestRandomWords() internal {
        COORDINATOR.requestRandomWords(
        keyHash,
        subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
        );  
    }

    function fulfillRandomWords(
        uint256, /* requestID */
        uint256[] memory randomWords
    ) internal override {
        if (dynamicArray.length > 1) {
            uint256 explodedColorIndex = randomWords[0] % dynamicArray.length;
            removeColor(explodedColorIndex);
            randomWordsForRewards[0] = randomWords[0];
        }
        
        if(dynamicArray.length == 1) {
            winnersDetermined = true;
        }
    }

    function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {
        if(keccak256(checkData) == keccak256(hex'01')) {
            upkeepNeeded = (_totalMinted() > 776) && ((block.timestamp - lastTimestamp) > 86400) && (dynamicArray.length != 1);
            performData = checkData; 
        }

        if(keccak256(checkData) == keccak256(hex'02')) {
            upkeepNeeded = (dynamicArray.length == 1) && winnersDetermined;
            performData = checkData;
        }           
    }
    
    function performUpkeep(bytes calldata performData) external override{
        if(keccak256(performData) == keccak256(hex'01') && 
            (_totalMinted() > 776) && (dynamicArray.length != 1) &&
            (block.timestamp - lastTimestamp) > 86400) {

            lastTimestamp = block.timestamp;
            requestRandomWords();
        }

        if(keccak256(performData) == keccak256(hex'02') && 
            (dynamicArray.length == 1) &&
            winnersDetermined) {
            winnersDetermined = false;
            determineWinners(randomWordsForRewards[0]);
        }
    }

    function determineWinners(uint256 randomNumber) internal {

        //determine 1 ETH winner -  1 ID
        uint256 colorID = randomNumber % 111;
        checkBigPrize[colorID].eligible = true;
        randomNumber >>= 1;

        //determine 0.25 ETH winners - 6 IDs
        for (uint i; i < 6; i++) {
            colorID = randomNumber % 111;
            while(checkBigPrize[colorID].eligible || checkSmallPrize[colorID].eligible) {
                randomNumber >>= 1;
                colorID = randomNumber % 111;
            }
            checkSmallPrize[colorID].eligible = true;
            randomNumber >>= 1;
        }
        
        if (freeMintCount < 114) {
            uint256 extraCountFromFreeMint = 114 - freeMintCount;
            teamPoolBalance += (10000000000000000 * extraCountFromFreeMint) * 35 / 100;
        }
    }

    function withdrawBigPrize(uint256 tokenID) public payable nonReentrant {
        require(ownerOf(tokenID) == msg.sender);

        uint256 colorID = tokenIDtoColorID[tokenID];
        uint256 baseID = dynamicArray[0] - 111;
        uint256 checkID = colorID - baseID; 
        require(checkBigPrize[checkID].eligible && !checkBigPrize[checkID].withdrawn, 
        "ID is not eligible for reward or ID has withdrawn the prize");
        
        checkBigPrize[checkID].withdrawn = true;
        (bool sent, ) = msg.sender.call{value: 1 ether}("");
        require(sent, "Failed to send the rewards");
    }

    function withdrawSmallPrize(uint256 tokenID) public payable nonReentrant {
        require(ownerOf(tokenID) == msg.sender);

        uint256 colorID = tokenIDtoColorID[tokenID];
        uint256 baseID = dynamicArray[0] - 111;
        uint256 checkID = colorID - baseID; 
        require(checkSmallPrize[checkID].eligible && !checkSmallPrize[checkID].withdrawn, 
        "ID is not eligible for reward or ID has withdrawn the prize");
        checkSmallPrize[checkID].withdrawn = true;
        (bool sent, ) = msg.sender.call{value: 0.25 ether}("");
        require(sent, "Failed to send the rewards");
    }

    function withdrawTeam(uint256 amount) public payable nonReentrant onlyOwner {
        require(amount <= teamPoolBalance);

        teamPoolBalance -= amount;
        (bool sent,) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function withdrawBigBangRewards(uint256 amount) public payable nonReentrant onlyOwner {
        require(amount <= BigBangBalance);
        
        BigBangBalance -= amount;
        (bool sent,) = address(0x47493b9a8d72e4c1487aB1022aa3D71627A27dD1).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function eligibleForAirdrop(uint256 tokenID) public view returns (bool) {
        uint256 colorID = tokenIDtoColorID[tokenID];
        uint256 baseID = dynamicArray[0] - 111;
        uint256 checkID = colorID - baseID;

        if(!checkBigPrize[checkID].eligible && !checkSmallPrize[checkID].eligible && 
        colorID >= baseID && colorID < dynamicArray[0]) {
            return true;
        }
        return false;
    }

    function removeColor(uint256 index) internal {
        uint256 colorID = dynamicArray[index] - 111;
        uint256 popColorID = colorID / 111;

        explodedColorsMetadata[popColorID] = true;
        dynamicArray[index] = dynamicArray[dynamicArray.length - 1];
        dynamicArray.pop();
    }

    function showRemainingColors() public view returns(uint256[] memory) {
        return dynamicArray;
    }

    function showTotalMinted() public view returns(uint256) {
        return _totalMinted();
    }

    function showFreePlusMint(address minter) public view returns(uint256) {
        return(_numberMinted(minter) - freeMintAddresses[minter]); 
    }

    function showNumberMinted(address minter) external view returns (uint256) {
        return _numberMinted(minter);
    }
}