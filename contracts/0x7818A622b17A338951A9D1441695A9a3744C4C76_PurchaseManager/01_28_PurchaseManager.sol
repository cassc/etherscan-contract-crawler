// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@metacrypt/contracts/src/security/ContractSafe.sol";
import "@metacrypt/contracts/src/access/OwnableClaimable.sol";

import "./LazyDrinks.sol";
import "./LazyCubs.sol";

/// @title Purchase Manager for Lazy Cubs Collection
/// @author Akshat Mittal
contract PurchaseManager is OwnableClaimable, ContractSafe {
    using ECDSA for bytes32;

    IERC721 immutable LazyLionsInterface;
    LazyDrinks immutable LazyDrinksInterface;
    LazyCubs immutable LazyCubsInterface;

    address private signerAccount;
    bytes32 eip712DomainHash =
        keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("PurchaseManager")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

    /**
     ** Lazy Cubs Token ID Distribution
     **
     **      0 - 11,999 - Public Sale + Allowlist
     ** 12,000 - 21,999 - Mutation: Old
     ** 22,000 - 31,999 - Mutation: Young
     ** 32,000 - 32,007 - Mutation: Special - Signatures
     ** 32,008 - 32,014 - Mutation: Special
     */

    /**
     ** Sale Process
     ** Dutch Auction -> Allowlist -> Mutation
     */

    constructor(
        address _contract_lazylions,
        address _contract_lazydrinks,
        address _contract_lazycubs,
        address _allowlist_signer
    ) {
        LazyLionsInterface = IERC721(_contract_lazylions);
        LazyDrinksInterface = LazyDrinks(_contract_lazydrinks);
        LazyCubsInterface = LazyCubs(_contract_lazycubs);

        signerAccount = _allowlist_signer;
    }

    /**
     ** Control Functions
     */

    uint256 public mintOpenPublicTimestamp = 0;
    uint256 public mintOpenAllowlistTimestamp = 0;
    uint256 public mintOpenMutationTimestamp = 0;

    function setSignerAccount(address _newSigner) external onlyOwner {
        signerAccount = _newSigner;
    }

    function setOpenPublicTimestamp(uint256 _timestamp) public onlyOwner {
        mintOpenPublicTimestamp = _timestamp;
    }

    function setOpenAllowlistTimestamp(uint256 _timestamp) public onlyOwner {
        mintOpenAllowlistTimestamp = _timestamp;
    }

    function setOpenMutationTimestamp(uint256 _timestamp) public onlyOwner {
        mintOpenMutationTimestamp = _timestamp;
    }

    function isPublicSaleOpen() public view returns (bool) {
        return mintOpenPublicTimestamp == 0 ? false : (block.timestamp >= mintOpenPublicTimestamp);
    }

    function isAllowlistSaleOpen() public view returns (bool) {
        return mintOpenAllowlistTimestamp == 0 ? false : (block.timestamp >= mintOpenAllowlistTimestamp);
    }

    function isMutationOpen() public view returns (bool) {
        return mintOpenMutationTimestamp == 0 ? false : (block.timestamp >= mintOpenMutationTimestamp);
    }

    /**
     ** Sale Related Functions
     */

    uint256 public allowlistMintingPrice = 0.5 ether;

    function setAllowlistMintingPrice(uint256 _newPrice) external onlyOwner {
        allowlistMintingPrice = _newPrice;
    }

    /*
     ** Dutch Auction Public Sale
     ** Starting Price: 0.5 ETH
     ** Ending Price: 0.1 ETH
     ** Total Duration: 320 minutes
     ** Step: 20 minutes
     ** Step: 0.025 ETH
     ** Total Steps: 16
     */
    uint256 public dutchAuctionStartingPrice = 0.5 ether;
    uint256 public dutchAuctionEndingPrice = 0.1 ether;
    uint256 public dutchAuctionDuration = 320 minutes;
    uint256 public dutchAuctionStepDuration = 20 minutes;

    uint256 private dutchAuctionSteps = dutchAuctionDuration / dutchAuctionStepDuration;
    uint256 private dutchAuctionStepDrop = (dutchAuctionStartingPrice - dutchAuctionEndingPrice) / dutchAuctionSteps;

    uint256 public constant MAX_CUBS_PUBLIC = 10_000;
    uint256 public constant MAX_CUBS_ALLOWLIST = 2_000;

    mapping(address => uint256) public mintedDuringPublicSale;
    mapping(address => uint256) public mintedDuringAllowlistSale;

    uint256 public totalMintedDuringPublicSale;
    uint256 public totalMintedDuringAllowlistSale;

    uint256 public mintingLimitPublic = type(uint256).max;
    uint256 public mintingLimitAllowlist = 1;

    function setMintingLimits(uint256 _allowlist, uint256 _public) public onlyOwner {
        mintingLimitAllowlist = _allowlist;
        mintingLimitPublic = _public;
    }

    /// @notice This only gives out the public sale current price.
    function getCurrentPrice() public view returns (uint256) {
        if (!isPublicSaleOpen()) {
            return dutchAuctionStartingPrice;
        }
        uint256 stepCount = (block.timestamp - mintOpenPublicTimestamp) / dutchAuctionStepDuration;
        if (stepCount >= dutchAuctionSteps) {
            return dutchAuctionEndingPrice;
        }
        return dutchAuctionStartingPrice - (stepCount * dutchAuctionStepDrop);
    }

    function pausePublicSale() external onlyOwner {
        require(isPublicSaleOpen(), "Public Sale is not open");
        mintOpenPublicTimestamp = 0;
    }

    function resumePublicSale(
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 stepDuration
    ) external onlyOwner {
        require(!isPublicSaleOpen(), "Public Sale is already open");
        mintOpenPublicTimestamp = block.timestamp;

        dutchAuctionStartingPrice = startingPrice;
        dutchAuctionEndingPrice = endingPrice;
        dutchAuctionDuration = duration;
        dutchAuctionStepDuration = stepDuration;

        dutchAuctionSteps = dutchAuctionDuration / dutchAuctionStepDuration;
        dutchAuctionStepDrop = (dutchAuctionStartingPrice - dutchAuctionEndingPrice) / dutchAuctionSteps;
    }

    function mintPublic(uint256 numberOfTokens) public payable {
        require(isPublicSaleOpen(), "Public sale not open yet");
        require(msg.value >= (getCurrentPrice() * numberOfTokens), "Incorrect amount");
        require(mintedDuringPublicSale[msg.sender] + numberOfTokens <= mintingLimitPublic, "Exceeds limit");
        require(totalMintedDuringPublicSale + numberOfTokens <= MAX_CUBS_PUBLIC, "Purchase would exceed limit");
        require(!isContract(msg.sender) && isSentViaEOA(), "Must be sent via EOA");

        mintedDuringPublicSale[msg.sender] += numberOfTokens;
        totalMintedDuringPublicSale += numberOfTokens;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 nextMint = LazyCubsInterface.totalSupply();
            LazyCubsInterface.safeMint(msg.sender, nextMint);
        }
    }

    function mintAllowlist(
        uint256 numberOfTokens,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        require(isAllowlistSaleOpen(), "Allowlist not open yet");
        require(msg.value >= (allowlistMintingPrice * numberOfTokens), "Incorrect amount");
        require(mintedDuringAllowlistSale[msg.sender] + numberOfTokens <= mintingLimitAllowlist, "Exceeds limit");
        require(totalMintedDuringAllowlistSale + numberOfTokens <= MAX_CUBS_ALLOWLIST, "Purchase would exceed limit");
        require(!isContract(msg.sender) && isSentViaEOA(), "Must be sent via EOA");

        bytes32 hashStruct = keccak256(abi.encode(keccak256("Data(address target)"), msg.sender));
        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
        address signer = ecrecover(hash, v, r, s);

        require(signer == signerAccount, "ECDSA: invalid signature");

        mintedDuringAllowlistSale[msg.sender] += numberOfTokens;
        totalMintedDuringAllowlistSale += numberOfTokens;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 nextMint = LazyCubsInterface.totalSupply();
            LazyCubsInterface.safeMint(msg.sender, nextMint);
        }
    }

    /**
     ** Mutation Related Functions
     */

    uint256[9] signatureLions = [16, 678, 1685, 2349, 3912, 5454, 6483, 7384, 9431];

    uint256 private currentSpecialIndex = 0;
    mapping(uint256 => uint256) private specialMutations;

    function isLionEligibleForMutation(uint256 lionId) public view returns (bool) {
        // Exclude Lions that were accidentally minted on the original collection
        if (lionId >= 10000) {
            return false;
        }
        // Exclude Signature Lions
        for (uint256 i = 0; i < signatureLions.length; i++) {
            if (lionId == signatureLions[i]) {
                return false;
            }
        }
        return true;
    }

    function isLionAlreadyMutated(uint256 lionId, uint256 drinkId) public view returns (bool, uint256) {
        uint256 mutationId;

        if (drinkId == 0) {
            // Juice
            mutationId = lionId + 12000;
        } else if (drinkId == 1) {
            // Milk
            mutationId = lionId + 22000;
        } else if (drinkId == 2) {
            // Special
            if (specialMutations[lionId] != 0) {
                mutationId = specialMutations[lionId];
            } else {
                mutationId = 32008 + currentSpecialIndex;
            }
        } else {
            revert("Invalid drink id");
        }

        return (LazyCubsInterface.exists(mutationId), mutationId);
    }

    function mutate(uint256 lionId, uint256 drinkId) public {
        require(isMutationOpen(), "Mutation not open yet");

        require(LazyLionsInterface.ownerOf(lionId) == msg.sender, "Must own the lion");
        require(LazyDrinksInterface.balanceOf(msg.sender, drinkId) > 0, "Must own at least one of the specified drink");
        require(isLionEligibleForMutation(lionId), "Lion is not eligible for mutation");

        (bool isMutated, uint256 mutationId) = isLionAlreadyMutated(lionId, drinkId);

        require(!isMutated, "Mutation already exists");

        if (drinkId == 2) {
            require(currentSpecialIndex < 8, "Too many special mutations");
            specialMutations[lionId] = mutationId;
            currentSpecialIndex += 1;
        }

        LazyDrinksInterface.burn(msg.sender, drinkId, 1);
        LazyCubsInterface.safeMint(msg.sender, mutationId);
    }
}