// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./ERC2981/ERC2981ContractWideRoyalties.sol";
pragma solidity ^0.8.0;

contract MytoBytes is ERC721Enumerable, ERC2981ContractWideRoyalties {
    uint16 constant maxNumberCreatures = 1000;
    uint256 constant numGenOneCreatures = 100;
    uint256 constant setAsideForCreatorsAndMarketing = 5;
    string constant myBaseURI =
        "ipfs://QmZPdd9q1dueTzCmp1fwjDKjtavV7i2reMpmy7mYeDdVcX/";
    uint256 constant energyIncreaseExponent = 2;
    // 5000 GWEI
    uint256 constant energyIncreaseConstant = 5000000000000;
    // 500 GWEI
    uint256 constant blockEnergyValue = 500000000000;
    // Sun Oct 17 2021 12:00:00 GMT-0700
    uint256 constant mintStartTime = 1634497200;
    // Mon Oct 18 2021 12:00:00 GMT-0700
    uint256 constant openMintStartTime = 1634583600;

    uint256[maxNumberCreatures] public energyFoodLevel;
    uint256[maxNumberCreatures] public energyBlockLevel;
    uint16[numGenOneCreatures - setAsideForCreatorsAndMarketing]
        public genTokensAvailable;
    uint16[maxNumberCreatures - numGenOneCreatures] public splitTokensAvailable;
    address public creator;
    uint256 public energyRequired;

    mapping(address => bool) public claimed;
    // Merkle root
    bytes32 public root;

    constructor() ERC721("MytoBytes", "MYTO") {
        energyRequired =
            (numGenOneCreatures**energyIncreaseExponent) *
            energyIncreaseConstant;
        creator = msg.sender;
        _setRoyalties(creator, 250);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981ContractWideRoyalties, ERC721Enumerable)
        returns (bool)
    {
        return
            ERC2981ContractWideRoyalties.supportsInterface(interfaceId) ||
            ERC721Enumerable.supportsInterface(interfaceId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return myBaseURI;
    }

    function updateRoot(bytes32 newRoot) public {
        require(msg.sender == creator, "Only creator can update");
        root = newRoot;
    }

    function verify(bytes32 leaf, bytes32[] memory proof)
        private
        view
        returns (bool)
    {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }

    function feed(uint16 tokenID) public payable {
        require(totalSupply() >= numGenOneCreatures, "Not all genesis claimed");
        energyFoodLevel[tokenID] += msg.value;
        uint256 blockDelta = block.number - energyBlockLevel[tokenID];
        require(blockDelta > 20, "No split during cooldown");
        uint256 blockDeltaValue = blockDelta * blockEnergyValue;
        // Check if a new token should be minted
        if (
            energyFoodLevel[tokenID] + blockDeltaValue >= energyRequired &&
            totalSupply() < maxNumberCreatures
        ) {
            // Get a random unclaimed tokenID
            uint256 randomIndex = random(maxNumberCreatures - totalSupply());
            uint256 endIndex = maxNumberCreatures - totalSupply() - 1;
            uint256 newTokenID = splitTokensAvailable[randomIndex];
            if (newTokenID == 0) {
                newTokenID = randomIndex;
            }
            if (splitTokensAvailable[endIndex] == 0) {
                splitTokensAvailable[randomIndex] = uint16(endIndex);
            } else {
                splitTokensAvailable[randomIndex] = splitTokensAvailable[
                    endIndex
                ];
            }
            newTokenID += numGenOneCreatures;
            // Add energy from blocks to food value
            energyFoodLevel[tokenID] += blockDeltaValue;
            // Reset block to current
            energyBlockLevel[tokenID] = block.number;
            // Consume energy required for minting
            energyFoodLevel[tokenID] -= energyRequired;
            // Mint new token
            mintNewToken(newTokenID, ownerOf(tokenID));
            // Increase required energy
            energyRequired =
                (totalSupply()**energyIncreaseExponent) *
                energyIncreaseConstant;
        }
    }

    function mintNewToken(uint256 tokenID, address mintTo) private {
        energyBlockLevel[tokenID] = block.number;
        _safeMint(mintTo, tokenID);
    }

    function claim() private {
        require(totalSupply() < numGenOneCreatures, "No genesis left");
        require(msg.sender == tx.origin, "No contracts");
        uint256 randomIndex = random(numGenOneCreatures - totalSupply());
        uint256 endIndex = numGenOneCreatures - totalSupply() - 1;
        uint256 newTokenID = genTokensAvailable[randomIndex];
        if (newTokenID == 0) {
            newTokenID = randomIndex;
        }
        if (genTokensAvailable[endIndex] == 0) {
            genTokensAvailable[randomIndex] = uint16(endIndex);
        } else {
            genTokensAvailable[randomIndex] = genTokensAvailable[endIndex];
        }
        newTokenID += setAsideForCreatorsAndMarketing;
        mintNewToken(newTokenID, msg.sender);
    }

    function creatorClaim(uint256 tokenID) public {
        require(msg.sender == creator, "For creator only");
        require(tokenID < setAsideForCreatorsAndMarketing);
        require(msg.sender == tx.origin, "No contracts");
        mintNewToken(tokenID, creator);
    }

    function claimNotOnWhitelist() public {
        require(block.timestamp >= openMintStartTime, "Not open mint yet");
        claim();
    }

    function claimOnWhitelist(bytes32[] calldata merkleProof) public {
        require(block.timestamp >= mintStartTime, "Claiming not started");
        require(
            verify(keccak256(abi.encodePacked(msg.sender)), merkleProof),
            "Must prove whitelist"
        );
        require(!claimed[msg.sender], "Already claimed");
        claimed[msg.sender] = true;
        claim();
    }

    function withdraw() public {
        require(msg.sender == creator, "Only creator can withdraw");
        require(tx.origin == creator);
        payable(creator).transfer(address(this).balance);
    }

    function getEnergyBlockLevel() public view returns (uint256[1000] memory) {
        return energyBlockLevel;
    }

    function getEnergyFoodLevel() public view returns (uint256[1000] memory) {
        return energyFoodLevel;
    }

    function random(uint256 maxRand) private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        msg.sender
                    )
                )
            ) % maxRand;
    }
}