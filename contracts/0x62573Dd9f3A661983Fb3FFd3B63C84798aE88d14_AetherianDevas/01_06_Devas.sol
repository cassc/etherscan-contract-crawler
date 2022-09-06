// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {IDevaURIHandler} from "./IDevaURIHandler.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Owned} from "./Owned.sol";

//                                     ....
//                                     ....
//                                    .......
//                                   ........
//                                   ........
//                                   ........
//                                   ........
//                                 ............
//          ....                   ............                   ....
//          ........               ............               ........
//            .............       ...............      .............
//              ...............  ................  ...............
//                ...............................................
//                ..............................................
//                   ........................................
//                     ....................................
//                      ...................................
//                       ................................
//                   ........................................
//                ...............................................
//           .........................................................
//     .....................................................................
// .............................................................................
// .............................................................................
//                          ...........................
//                          ...........................
//                        ..............   ..............
//                       .............       ............
//                       ............        ............
//                       ...........           ..........
//                       ........                ........
//                      ........                   .......
//                      ......                       ......
//                      .....                        ......
//                      ..                              ...

/// @title ERC721 for Aetheria

contract AetherianDevas is ERC721A, Owned {
    event StartTraining(uint256 indexed tokenId);

    event StopTraining(uint256 indexed tokenId);

    event Expelled(uint256 indexed tokenId);

    event NewBaseURI(string baseURI_);

    string public baseURI;

    string public _contractURI;

    uint256 public startedBlock;

    bool public teamHasClaimed;

    mapping(uint256 => uint256) private trainingStarted;

    mapping(uint256 => uint256) private trainingTotal;

    bool public trainingOpen;

    uint256 public constant MAX_SUPPLY = 3333;

    uint256 public constant TEAM_CLAIM_AMOUNT = 200;

    bytes32 public merkleRoot;

    mapping(address => bool) public claimed;

    bool internal enableTransfer;

    IDevaURIHandler public devaURIHandler;

    constructor(bytes32 _merkleRoot)
        ERC721A("Aetherian Devas", "DEVA")
        Owned(msg.sender)
    {
        merkleRoot = _merkleRoot;
        startedBlock = block.timestamp;
    }

    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(
            _ownershipOf(tokenId).addr == msg.sender ||
                getApproved(tokenId) == msg.sender,
            "Not approved / owner"
        );
        _;
    }

    // Restricts transfers while training in a non custodial way.
    function _beforeTokenTransfers(
        address,
        address,
        uint256 startTokenId,
        uint256 quantity
    ) internal view override {
        uint256 tokenId = startTokenId;

        for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
            require(
                trainingStarted[tokenId] == 0 || enableTransfer == true,
                "no transfer while training"
            );
        }
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
        emit NewBaseURI(baseURI_);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function toBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function ascend(bytes32[] calldata worthinessProof, uint256 amount)
        external
    {
        require(msg.sender == tx.origin, "no contract calls");
        require(
            claimed[msg.sender] == false && amount <= 2,
            "greediness is a sin"
        );
        claimed[msg.sender] = true;
        require(
            MerkleProof.verify(
                worthinessProof,
                merkleRoot,
                toBytes32(msg.sender)
            ) == true,
            "invalid worthiness proof"
        );
        _safeMint(msg.sender, amount);
        require(
            totalSupply() < MAX_SUPPLY - TEAM_CLAIM_AMOUNT,
            "our ranks are full"
        );
    }

    function publicAscend(uint256 amount) external {
        require(
            block.timestamp > startedBlock + 16 hours,
            "public not started"
        );
        require(msg.sender == tx.origin, "no contract calls");
        require(claimed[msg.sender] == false);
        require(amount <= 2, "greediness is a sin");
        claimed[msg.sender] = true;
        _safeMint(msg.sender, amount);
        require(
            totalSupply() < MAX_SUPPLY - TEAM_CLAIM_AMOUNT,
            "our ranks are full"
        );
    }

    function teamClaim() external onlyOwner {
        require(!teamHasClaimed, "already claimed");
        _safeMint(msg.sender, TEAM_CLAIM_AMOUNT);
        teamHasClaimed = true;
    }

    function safeTransferWhileTraining(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(ownerOf(tokenId) == msg.sender, "Must own token");
        enableTransfer = true;
        safeTransferFrom(from, to, tokenId);
        enableTransfer = false;
    }

    function setTrainingOpen(bool open) external onlyOwner {
        trainingOpen = open;
    }

    function trainingPeriod(uint256 tokenId)
        external
        view
        returns (
            bool isTraining,
            uint256 current,
            uint256 total
        )
    {
        uint256 start = trainingStarted[tokenId];
        if (start != 0) {
            isTraining = true;
            current = block.timestamp - start;
        }
        total = current + trainingTotal[tokenId];
    }

    function toggleTraining(uint256 tokenId)
        internal
        onlyApprovedOrOwner(tokenId)
    {
        uint256 start = trainingStarted[tokenId];
        if (start == 0) {
            require(trainingOpen, "Training closed");
            trainingStarted[tokenId] = block.timestamp;
            emit StartTraining(tokenId);
        } else {
            trainingTotal[tokenId] += block.timestamp - start;
            trainingStarted[tokenId] = 0;
            emit StopTraining(tokenId);
        }
    }

    function toggleTraining(uint256[] calldata tokenIds) external {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            toggleTraining(tokenIds[i]);
        }
    }

    function expelFromTraining(uint256 tokenId) external onlyOwner {
        require(trainingStarted[tokenId] != 0, "training not started");
        trainingTotal[tokenId] += block.timestamp - trainingStarted[tokenId];
        trainingStarted[tokenId] = 0;
        emit StopTraining(tokenId);
        emit Expelled(tokenId);
    }

    // Probably nothing
    function setDevaURIHandler(IDevaURIHandler _devaURIHandler)
        external
        onlyOwner
    {
        devaURIHandler = _devaURIHandler;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (address(devaURIHandler) != address(0)) {
            return devaURIHandler.tokenURI(tokenId);
        }
        return super.tokenURI(tokenId);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory contractURI_) external onlyOwner {
        _contractURI = contractURI_;
    }

    function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
}