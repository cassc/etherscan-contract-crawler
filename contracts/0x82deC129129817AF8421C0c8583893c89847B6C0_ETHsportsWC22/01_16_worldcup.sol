// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {DefaultOperatorFilterer} from "./filter/DefaultOperatorFilterer.sol";

contract ETHsportsWC22 is ERC1155, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    string public name = "ETHsports World Cup 2022";
    string public symbol = "WC22";

    constructor(string memory _metadataURI) ERC1155(_metadataURI) {
        baseURI = _metadataURI;
    }

    using Strings for uint256;

    receive() external payable {}

    uint256 public price = 0.001 ether;
    uint256 public numTeams = 32;
    uint256 public winningTeam;
    uint256 public totalSupply;
    uint256 public initialPrizeCapital;
    uint256 public finalPrizePool;
    bool public publicActive = true;
    bool public contestCompleted;
    bool public ownerHasWithdrawn;

    // teamID/tokenID => amount minted
    mapping(uint256 => uint256) public numMintedForTeam;

    // merkle root
    bytes32 public freeMintRoot;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // setters
    function setPublicActive(bool _isActive) external onlyOwner {
        publicActive = _isActive;
    }

    function setFreeMintRoot(bytes32 _root) external onlyOwner {
        freeMintRoot = _root;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function sendInitialPrize() external payable onlyOwner {
        initialPrizeCapital = msg.value;
    }

    function setWinningTeam(uint256 _tokenID, bool _contestCompleted)
        external
        onlyOwner
    {
        winningTeam = _tokenID;
        contestCompleted = _contestCompleted;
        finalPrizePool = getPrizePool();
    }

    // getters
    function getTeamQuantities() public view returns (uint256[] memory) {
        uint256[] memory mintedArr = new uint256[](numTeams);
        for (uint8 i = 0; i < numTeams; i++) {
            mintedArr[i] = numMintedForTeam[i];
        }
        return mintedArr;
    }

    function getWinnerPayout(address _address) public view returns (uint256) {
        uint256 balance = balanceOf(_address, winningTeam);
        if (balance == 0 || !contestCompleted) {
            return 0;
        } else {
            return (balance * finalPrizePool) / numMintedForTeam[winningTeam];
        }
    }

    function getPrizePool() public view returns (uint256) {
        if (ownerHasWithdrawn) {
            return (address(this).balance);
        } else {
            return ((address(this).balance) -
                ((address(this).balance - initialPrizeCapital) / 5));
        }
    }

    // mint functions
    function airdrop(address[] calldata addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            // random number
            uint256 seed = uint256(keccak256(abi.encodePacked(
                block.timestamp + block.difficulty +
                ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
                block.gaslimit + 
                ((uint256(keccak256(abi.encodePacked(addrs[i])))) / (block.timestamp)) +
                block.number
            )));
            uint256 _tokenID = (seed - ((seed / numTeams) * numTeams));
            numMintedForTeam[_tokenID] += 1;
            totalSupply++;
            _mint(addrs[i], _tokenID, 1, "");
        }
    }

    function publicMint(uint8 quantity, uint128 _tokenID)
        external
        payable
        callerIsUser
        nonReentrant
    {
        require(publicActive, "Mint is not active");
        require(quantity > 0, "Must mint more than 0 tokens");
        totalSupply += quantity;
        numMintedForTeam[_tokenID] += quantity;
        _mint(msg.sender, _tokenID, quantity, "");
    }

    // winner cash out
    function claimWinnings() external callerIsUser nonReentrant {
        uint256 balance = balanceOf(msg.sender, winningTeam);
        require(contestCompleted == true, "Contest is still active");
        require(balance > 0, "No tokens to claim");
        payable(msg.sender).transfer(
            (balance * finalPrizePool) / numMintedForTeam[winningTeam]
        );
        _burn(msg.sender, winningTeam, balance);
    }

    // withdraw to owner wallet - 20% of proceeds not counting original ETH seeded into contract
    function withdraw() external onlyOwner {
        uint256 balance = (address(this).balance - initialPrizeCapital) / 5;
        require(ownerHasWithdrawn == false, "function can only be run once");
        ownerHasWithdrawn = true;
        payable(msg.sender).transfer(balance);
    }

    // metadata URI
    string private baseURI;

    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : baseURI;
    }

    // OS Operator Filter
    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}