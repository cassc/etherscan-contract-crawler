//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

contract GameCertificateTokenAdventure is ERC721Upgradeable {
    address public owner;
    uint64 public totalSupply;

    // for sell
    uint64 public startTime;
    uint64 public endTime;
    uint64 public batchIndex;
    // batch index => user address => has minted
    mapping(uint64 => mapping(address => bool)) public mintStatus;

    string internal baseURI;

    bytes32 public rootDrop;
    mapping(address => bool) public dropClaimed;
    uint128 public dropAmount;
    uint128 public dropMintedAmount;

    bool public freeMint;
    uint128 public startTimeWhitelist;
    uint128 public endTimeWhitelist;

    event DropWhitelist(address user, uint256 tokenID);

    function initialize(
        string memory name_,
        string memory symbol_,
        address owner_
    ) public initializer {
        __ERC721_init(name_, symbol_);
        owner = owner_;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    /* ---------------- sell ---------------- */

    /// @notice Each address can only mint once a month(30 days)
    function mint() public {
        require(freeMint, "ERROR: free mint is close");
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "ERROR: wrong time"
        );
        require(!mintStatus[batchIndex][msg.sender], "ERROR: has minted");

        mintStatus[batchIndex][msg.sender] = true;
        _mint(_msgSender(), totalSupply);
    }

    function setFreeMint(bool freeMint_) public onlyOwner {
        freeMint = freeMint_;
    }

    function setNewBatch(uint64 startTime_, uint64 endTime_) public onlyOwner {
        require(
            startTime_ < endTime_,
            "ERROR: start time should be smaller than end time"
        );
        startTime = startTime_;
        endTime = endTime_;
        batchIndex++;
    }

    function setSellTime(uint64 startTime_, uint64 endTime_) public onlyOwner {
        require(
            startTime_ < endTime_,
            "ERROR: start time should be smaller than end time"
        );
        startTime = startTime_;
        endTime = endTime_;
    }

    function withdraw(address reciever) public onlyOwner {
        payable(reciever).transfer(address(this).balance);
    }

    function mintCurrentPermission(address user) public view returns (bool) {
        return !mintStatus[batchIndex][user];
    }

    /* ---------------- drop ---------------- */

    function DropByMerkle(address user, bytes32[] calldata proofs) public {
        require(block.timestamp >= startTimeWhitelist, "Not start");
        
        if (endTimeWhitelist == 0) {
            require(block.timestamp <= 1677290400, "Finished");
        } else {
            require(block.timestamp <= endTimeWhitelist, "Finished");
        }

        require(
            dropMintedAmount < dropAmount,
            "All airdrop passes have been distributed"
        );
        // merkle verify
        bytes32 leaf = keccak256(abi.encode(user));
        require(
            MerkleProofUpgradeable.verify(proofs, rootDrop, leaf),
            "Merkle proof is wrong"
        );
        require(!dropClaimed[user], "This user has claimed");

        dropMintedAmount++;
        dropClaimed[user] = true;
        emit DropWhitelist(user, totalSupply);
        _mint(user, totalSupply);
    }

    function setRootDrop(bytes32 root_) public onlyOwner {
        rootDrop = root_;
    }

    function setDropAmount(uint128 amount_) public onlyOwner {
        dropAmount = amount_;
    }

    function setDropTime(
        uint128 startTimeWhitelist_,
        uint128 endTimeWhitelist_
    ) public onlyOwner {
        startTimeWhitelist = startTimeWhitelist_;
        endTimeWhitelist = endTimeWhitelist_;
    }

    /* ---------------- reveal ---------------- */

    function setBaseURI(string calldata baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (from == address(0)) {
            totalSupply++;
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }
}