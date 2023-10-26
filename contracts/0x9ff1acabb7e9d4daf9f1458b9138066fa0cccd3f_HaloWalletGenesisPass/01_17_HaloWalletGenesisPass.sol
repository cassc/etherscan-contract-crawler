// SPDX-License-Identifier: MIT
// Creator: xxxx

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract HaloWalletGenesisPass is
    ERC721,
    Ownable2Step,
    Pausable,
    ReentrancyGuard
{
    using Strings for uint256;
    uint256 public constant MAX_SUPPLY = 2100; // the maximum supply ( >= totalSupply()+burnCounter )

    string private _baseURIextended; //notice: end with "/"

    uint256 public currentIndex; // current tokenId(number) of "minted" (start from 1.）
    uint256 public burnCounter; // the number of currently "destroyed"(transfer to 0x0)
    bool public canBurn; // burn is or not allowed now
    mapping(address => bool) public claimed; //  mark whether the user has claimed (all round activities are uniformly recorded)

    // minting activities' parameters (each round of activities needs to configure a set of the following parameters)
    struct Parameters {
        bytes32 merkleRoot; // merkle root corresponding to the whitelist list
        uint64 startTimestamp; // start time of this round activity
        uint64 endTimestamp;
        uint256 maxTokenId; // maximum tokenId that can be minted for this activity,eg.150 or 2100
    }
    mapping(uint256 => Parameters) public mintParameters; // key represent "mintType", 0:PRE_MINT，1: PUBLIC_MINT

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller is a contract");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {}

    function claimPass(
        bytes32[] calldata proof,
        uint256 mintType // 0:PRE_MINT，1: PUBLIC_MINT
    ) external callerIsUser nonReentrant whenNotPaused {
        // 0. Whether the specified activity is configured
        require(
            proof.length > 0 && mintParameters[mintType].merkleRoot != 0x0,
            "Not correct parameter"
        );

        // 1. Check if or not in active period
        require(
            block.timestamp >= mintParameters[mintType].startTimestamp &&
                block.timestamp <= mintParameters[mintType].endTimestamp,
            "Not in claim period"
        );
        // 2. Verify that the current user has not claimed
        require(!claimed[msg.sender], "Caller already claimed");

        // 3. Check current minted amount <= MAX_SUPPLY
        require(currentIndex < MAX_SUPPLY, "Exceeded max supply");

        // 4. Check minting is still possible during the current active period
        require(
            currentIndex < mintParameters[mintType].maxTokenId,
            "Exceeded max amount of this period"
        );

        // 5. Merkle verification
        require(
            MerkleProof.verify(
                proof,
                mintParameters[mintType].merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Not in the allowlist"
        );

        // All checks passed --- mint nft
        claimed[msg.sender] = true;
        _safeMint(msg.sender, ++currentIndex);
    }

    function adminMint(address[] calldata tolist) external onlyOwner {
        uint amount = tolist.length;
        address toAddr;
        require(currentIndex + amount <= MAX_SUPPLY, "Exceeded max supply");

        for (uint i = 0; i < amount; i++) {
            toAddr = tolist[i];
            require(!claimed[toAddr], "Caller already claimed");
            // check passed
            claimed[toAddr] = true;
            _safeMint(toAddr, ++currentIndex);
        }
    }

    // Owner: configure various parameters
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function setBurnStatus(bool canBurn_) external onlyOwner {
        canBurn = canBurn_;
    }

    function setMintParams(
        uint256[] calldata mintTypeList,
        Parameters[] calldata mintParamsList
    ) external onlyOwner {
        uint256 mintType;
        require(
            mintTypeList.length == mintParamsList.length,
            "Invalid paramters"
        );
        for (uint256 i = 0; i < mintTypeList.length; i++) {
            mintType = mintTypeList[i];
            mintParameters[mintType] = mintParamsList[i];
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdraw() external onlyOwner {
        //This contract does not implement fallback() or receive(),
        //So under normal circumstances, the contract cannot receive eth (unless: as the coinbase for mining, as the parameter of selfdestruct() )
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Caller is not token owner or approved"
        );
        require(canBurn, "Burn is not allowed now");
        _burn(tokenId);

        burnCounter++;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function isValid(
        bytes32 root,
        bytes32[] memory proof,
        address user
    ) public pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(user));
        return MerkleProof.verify(proof, root, leaf);
    }

    function totalSupply() public view returns (uint256) {
        // the amount minted -  the amount burned
        return currentIndex - burnCounter;
    }

    function ownersOf(
        uint256[] calldata tokenIds
    ) public view returns (address[] memory) {
        uint256 count = tokenIds.length;
        address[] memory ownerList = new address[](count);
        // loop
        for (uint256 i = 0; i < count; i++) {
            try this.ownerOf(tokenIds[i]) returns (address user) {
                ownerList[i] = user;
            } catch (bytes memory) {
                ownerList[i] = address(0);
            }
        }
        return ownerList;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
}