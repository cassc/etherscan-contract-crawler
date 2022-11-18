// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract WorldCupMemoryNFT is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Strings for uint256;

    uint constant BASE_COST = 0.000025 ether;
    uint constant CREATOR_FEE = 0.0005 ether;
    uint constant REPURCHASE_POOL_FEE = 0.001 ether;

    mapping(uint256 => string) public teamIdToName;
    uint256 public winnerTeam;
    bytes32 public _presaleMerkleRoot;
    bool public presaleOpen = false;
    bool public publicSaleOpen = false;
    address public CREATOR_FEE_ADDRESS;
    address public REPURCHASE_POOL_ADDRESS;

    // tokenId -> teamId
    mapping(uint256 => uint256) public tokenIdAtTeam;
    mapping(uint256 => uint256) public teamTotalMinted;
    mapping(uint256 => uint256) public teamTotalBurned;
    mapping(uint256 => uint256) public teamMintId;

    string public baseTokenURI;
    string public constant BASE_EXTENSION = ".json";
    uint256 public allTeamTotalCreated;

    mapping(address => bool) public whitelistMintedRecord;

    modifier validTeamId(uint256 _teamId) {
        require(_teamId > 0 && _teamId <= 32, "wrong teamId");
        _;
    }

    constructor(address _creatorFeeAddress, address _repurchasePoolAddress)
        ERC721("WorldCupMemoryNFT", "WCM")
    {
        CREATOR_FEE_ADDRESS = _creatorFeeAddress;
        REPURCHASE_POOL_ADDRESS = _repurchasePoolAddress;
    }

    function presaleMint(uint256 _teamId, bytes32[] calldata merkleProof)
        external
        payable
        validTeamId(_teamId)
        nonReentrant
    {
        require(presaleOpen, "Pre-sale is not open");
        require(
            whitelistMintedRecord[msg.sender] == false,
            "the user has minted in whitelist"
        );
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, _presaleMerkleRoot, leaf),
            "Invalid Merkle proof"
        );
        uint256 cost = getMintFee(_teamId);
        teamTotalMinted[_teamId] = teamTotalMinted[_teamId] + 1;
        require(msg.value >= cost, "cost is not enough");

        allTeamTotalCreated = allTeamTotalCreated + 1;
        _safeMint(msg.sender, allTeamTotalCreated);

        whitelistMintedRecord[msg.sender] = true;
        (bool creatorFeeSent, ) = CREATOR_FEE_ADDRESS.call{value: CREATOR_FEE}(
            ""
        );
        require(creatorFeeSent, "Failed to send creatorFeeSent");
        tokenIdAtTeam[allTeamTotalCreated] = _teamId;
        teamMintId[allTeamTotalCreated] = teamTotalMinted[_teamId];
        (bool repucharseFeeSent, ) = REPURCHASE_POOL_ADDRESS.call{
            value: REPURCHASE_POOL_FEE
        }("");
        require(repucharseFeeSent, "Failed to send repucharseFeeSent");
    }

    function publicManyMint(uint256 amount, uint256 _teamId) public payable validTeamId(_teamId)  {
        for (uint i = 0; i < amount; i++) {
            publicMint(_teamId);
        }
    }

    function publicMint(uint256 _teamId)
        public
        payable
        validTeamId(_teamId)
        nonReentrant
    {
        require(publicSaleOpen, "Public-sale is not open");
        uint256 cost = getMintFee(_teamId);
        teamTotalMinted[_teamId] = teamTotalMinted[_teamId] + 1;

        require(msg.value >= cost, "cost is not enough");

        allTeamTotalCreated = allTeamTotalCreated + 1;
        _safeMint(msg.sender, allTeamTotalCreated);

        (bool creatorFeeSent, ) = CREATOR_FEE_ADDRESS.call{value: CREATOR_FEE}(
            ""
        );
        require(creatorFeeSent, "Failed to send creatorFeeSent");

        tokenIdAtTeam[allTeamTotalCreated] = _teamId;
        teamMintId[allTeamTotalCreated] = teamTotalMinted[_teamId];
        (bool repucharseFeeSent, ) = REPURCHASE_POOL_ADDRESS.call{
            value: REPURCHASE_POOL_FEE
        }("");
        require(repucharseFeeSent, "Failed to send repucharseFeeSent");
    }

    function setManyTeamName(uint256[] calldata _id, string[] memory _teamName)
        public
        onlyOwner
    {
        require(_id.length > 0, "_ids cannot be empty");
        require(_id.length == _teamName.length, "length not matcg");
        for (uint i = 0; i < _id.length; i++) {
            teamIdToName[_id[i]] = _teamName[i];
        }
    }

    function getMintFee(uint256 _teamId) public view returns (uint256) {
        return
            BASE_COST *
            (teamTotalSupply(_teamId) + 1) +
            CREATOR_FEE +
            REPURCHASE_POOL_FEE;
    }


    function getManyMintFee(uint256 _teamId, uint256 amount)public view returns (uint256){
        uint256 totalBaseCost ;
        for(uint i = 0; i< amount; i++){
            totalBaseCost = totalBaseCost +  BASE_COST * (teamTotalSupply(_teamId) + i+1);
        }
        return (CREATOR_FEE * amount + REPURCHASE_POOL_FEE * amount + totalBaseCost  );
    }


    function harvest(uint256 tokenId) public  {
        require(msg.sender == ownerOf(tokenId), "not owner of NFT");
        uint256 growth = (teamTotalMinted[tokenIdAtTeam[tokenId]] -
            teamMintId[tokenId]);
        uint256 produce = growth * BASE_COST;
        teamTotalBurned[tokenIdAtTeam[tokenId]] += 1;
        super._burn(tokenId);
        (bool ownerBurn, ) = msg.sender.call{value: produce}("");
        require(ownerBurn, "Failed to burn NFT");
    }

    function harvestMultiple(uint[] calldata tokenIds) public  {
        require(tokenIds.length > 0, "tokenIds");
        for (uint i = 0; i < tokenIds.length; i++) {
            harvest(tokenIds[i]);
        }
    }

    function repurchasePoolWinnerAmount() public view returns (uint256) {
        if (winnerTeam == 0) {
            return 0;
        } else {
            return teamTotalSupply(winnerTeam);
        }
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenID)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenID),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory base = _baseURI();
        require(bytes(base).length > 0, "baseURI not set");
        return
            string(
                abi.encodePacked(
                    base,
                    tokenIdAtTeam[tokenID].toString(),
                    BASE_EXTENSION
                )
            );
    }

    function teamTotalSupply(uint256 teamId) public view returns (uint256) {
        return teamTotalMinted[teamId] - teamTotalBurned[teamId];
    }

    function setPresaleMerkleRoot(bytes32 root) external onlyOwner {
        _presaleMerkleRoot = root;
    }

    function togglePresale() external onlyOwner {
        presaleOpen = !presaleOpen;
    }

    function togglePublicSale() external onlyOwner {
        publicSaleOpen = !publicSaleOpen;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function setWinnerTeam(uint256 _teamId) public onlyOwner {
        winnerTeam = _teamId;
    }

    function withdrawAll() public onlyOwner {
        require(publicSaleOpen == false ,"Activity not end");
        (bool ownerWithdraw, ) = msg.sender.call{value: address(this).balance}(
            ""
        );
        require(ownerWithdraw, "Failed to withdraw NFT");
    }

    function upgradeRepurchaseContract(address newRepurchasePool) public onlyOwner {
        REPURCHASE_POOL_ADDRESS = newRepurchasePool;
    }
}