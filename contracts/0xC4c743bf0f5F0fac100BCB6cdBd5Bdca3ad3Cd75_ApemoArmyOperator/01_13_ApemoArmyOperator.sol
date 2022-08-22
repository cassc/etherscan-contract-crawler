//SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IApemoArmy.sol";
import "./utils/Operatorable.sol";
import "./helpers/DateHelper.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * Apemo Army Avatar Operator Contract V1
 * Provided by Satoshiverse LLC
 */
contract ApemoArmyOperator is Operatorable, ReentrancyGuard {
    IApemoArmy public apemoArmyContract;

    // Payable Address for the Initial Sale
    address payable public svEthAddr =
        payable(0x981268bF660454e24DBEa9020D57C2504a538C57);

    enum AllowLists {
        APELIST,
        CREWMEN_LIST,
        TREVOR_JONES,
        HACKATAO,
        PUBLIC_SALE_LIST
    }
    //Allow List Merkle roots
    mapping(AllowLists => bytes32) public allowListMerkleRoots;

    //Merkle Tree Root for the free claim list
    bytes32 public freeClaimMerkleRoot;

    //Current phase of the drop
    uint256 currentPhase = 0;

    uint16 mintIndex = 1;

    uint16 public apemoArmySold = 0;
    uint256 public trevorTexturesSold = 0;
    uint256 public hackataoTexturesSold = 0;

    uint256 MAX_SUPPLY = 10000;
    uint256 MAX_SUPPLY_SALES = 5000;
    uint256 MAX_SUPPLY_SPECIAL_TEXTURES = 100;

    uint256 publicSalePrice = .1 ether;

    bool public claimState = true;
    bool public purchaseState = true;

    //We can have a address => bool mapping or address => uint8 mapping
    mapping(address => uint8) public claimedAmount;
    mapping(address => bool) public claimedAddresses;

    //Allowlist purchases cannot exceed per-user allotment, which can never exceed 2.
    mapping(AllowLists => mapping(address => uint8)) public allowListPurchases;

    //Functions

    // Set Initial Addresses and Variables Upon Deployment
    constructor(address _operator, address _apemoArmyContract) {
        apemoArmyContract = IApemoArmy(_apemoArmyContract);
        addOperator(_operator);
    }

    // Change the Payment Adddress if Necessary
    function setPaymentAddress(address _svEthAddr) external onlyOwner {
        svEthAddr = payable(_svEthAddr);
    }

    // Sets the merkle root corresponding to the free Claim List
    // Snapshot will be taken on August 23rd, 2022 1:00 PM PST.
    function setFreeClaimMerkleRoot(bytes32 _freeClaimMerkleRoot)
        external
        onlyOperator
    {
        freeClaimMerkleRoot = _freeClaimMerkleRoot;
    }

    //Sets the merkle roots for the allow lists
    function setAllowListMerkleRoot(AllowLists allowList, bytes32 merkleRoot)
        external
        onlyOperator
    {
        allowListMerkleRoots[allowList] = merkleRoot;
    }

    // Operator can toggle the claim mechanism as On / Off
    function toggleClaim() external onlyOperator {
        claimState = !claimState;
    }

    // Operator can toggle the purchasing mechanism as On / Off for the Sale of Apemo Army
    function togglePurchase() external onlyOperator {
        purchaseState = !purchaseState;
    }

    // Claim Apemo Army if you have the allotment. Must be in phase = 4
    //function claim(uint8 claimCount, bytes32[] calldata merkleProof, uint8 phaseOrAllowList)
    function claim(
        uint256 claimCount,
        uint256 allotment,
        bytes32[] calldata merkleProof
    ) external nonReentrant {
        require(claimState, "Claim is disabled");
        require(currentPhase == 4, "Claim period has not yet begun.");
        require(
            !claimedAddresses[msg.sender],
            "You have already claimed your full allotment."
        );

        require(
            claimCount + claimedAmount[msg.sender] <= allotment,
            "Claiming this many would exceed your allotment."
        );
        require(
            MerkleProof.verify(
                merkleProof,
                freeClaimMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, allotment))
            ),
            "Sender address is not on the free claim list"
        );

        if (claimedAmount[msg.sender] + claimCount == allotment) {
            claimedAddresses[msg.sender] = true;
            claimedAmount[msg.sender] = (uint8)(
                claimedAmount[msg.sender] + claimCount
            );
        } else {
            claimedAmount[msg.sender] = (uint8)(
                claimedAmount[msg.sender] + claimCount
            );
        }

        uint256 i = 0;
        uint256 tokenId;

        while (i < claimCount) {
            tokenId = mintIndex;
            mintIndex++;
            apemoArmyContract.operatorMint(msg.sender, tokenId);
            i++;
        }
    }

    // Purchase Apemo Army avatars without discount. Max 10 per transaction.
    function purchase(uint256 count) external payable nonReentrant {
        require(purchaseState, "Purchase is disabled");
        require(count <= 10, "Can only purchase up to 10 per transaction");
        require(
            currentPhase == 3,
            "Public sale has not begun yet or has already ended"
        );
        require(msg.value >= count * publicSalePrice, "Not enough ether");

        require(
            apemoArmySold + count <= MAX_SUPPLY_SALES,
            "No Apemo Army avatars left for public sale"
        );

        uint256 tokenId;
        for (uint256 i = 0; i < count; i++) {
            tokenId = mintIndex;
            mintIndex++;
            apemoArmySold++;
            apemoArmyContract.operatorMint(msg.sender, tokenId);
        }

        (bool sent, ) = svEthAddr.call{value: count * publicSalePrice}("");
        require(sent, "Failed to send Ether");

        if (msg.value > count * publicSalePrice) {
            (sent, ) = payable(msg.sender).call{
                value: msg.value - count * publicSalePrice
            }("");
            require(sent, "Failed to send change back to user");
        }
    }

    //Purchase Apemo Army avatars using your spot in one of the allowlists
    function allowListPurchase(
        uint256 count,
        uint256 allotment,
        AllowLists list,
        bytes32[] calldata merkleProof
    ) external payable nonReentrant {
        require(purchaseState, "Purchase is disabled");
        require(
            allowListPurchases[list][msg.sender] + count <= allotment,
            "Purchasing would exceed allotment."
        );
        require(currentPhase >= 1, "Allowlist sale has not begun yet");
        require(currentPhase < 3, "Allowlist sale has already ended");
        if (list == AllowLists.PUBLIC_SALE_LIST) {
            require(
                currentPhase == 2,
                "Public Allowlist sales cannot be performed at this time"
            );
        } else if (list == AllowLists.TREVOR_JONES) {
            require(
                trevorTexturesSold + count <= MAX_SUPPLY_SPECIAL_TEXTURES,
                "Bitcoin Angel Clothing textures are sold out"
            );
            trevorTexturesSold += count;
        }
        else if (list == AllowLists.HACKATAO) {
            require(
                hackataoTexturesSold + count <= MAX_SUPPLY_SPECIAL_TEXTURES,
                "Hackatao Clothing textures are sold out"
            );
            hackataoTexturesSold += count;
        }

        require(count <= allotment, "Cannot mint more than allotment.");
        uint256 price = publicSalePrice;
        if (list == AllowLists.APELIST) {
            price = (price) / 2;
        } else if (
            list == AllowLists.CREWMEN_LIST ||
            list == AllowLists.TREVOR_JONES ||
            list == AllowLists.HACKATAO
        ) {
            price = (price * 8) / 10;
        }
        require(msg.value >= count * price, "Not enough ether");
        require(
            apemoArmySold + count <= MAX_SUPPLY_SALES,
            "No Apemo Army avatars left for public sale"
        );
        require(
            MerkleProof.verify(
                merkleProof,
                allowListMerkleRoots[list],
                keccak256(abi.encodePacked(msg.sender, allotment))
            ),
            "Sender address is not in that allowlist"
        );

        allowListPurchases[list][msg.sender] += uint8(count);

        uint256 tokenId;
        for (uint256 i = 0; i < count; i++) {
            tokenId = mintIndex;
            mintIndex++;
            apemoArmySold++;
            apemoArmyContract.operatorMint(msg.sender, tokenId);
        }

        (bool sent, ) = svEthAddr.call{value: count * price}("");
        require(sent, "Failed to send Ether");

        if (msg.value > count * price) {
            (sent, ) = payable(msg.sender).call{
                value: msg.value - count * price
            }("");
            require(sent, "Failed to send change back to user");
        }
    }

    // Operator can batch mint and transfer remaining Apemo Army avatars to a secure address
    function safeBatchMintAndTransfer(address holder, uint16 batchSize)
        external
        onlyOperator
    {
        require(
            mintIndex + batchSize <= MAX_SUPPLY + 1,
            "No Apemo Army avatars left for public sale"
        );

        for (uint256 i = mintIndex; i < mintIndex + batchSize; i++) {
            apemoArmyContract.operatorMint(holder, i);
        }

        mintIndex = uint16(mintIndex + batchSize);
    }

    // Owner can decrease the total supply not ever exceeding 10,000 Apemo Army avatars
    function setMaxLimit(uint256 maxLimit) external onlyOwner {
        require(maxLimit < 10001, "Max supply can never exceed 10000");
        MAX_SUPPLY = maxLimit;
    }

    //Sets current phase of the drop
    function setPhase(uint8 _currentPhase) external onlyOperator {
        require(
            _currentPhase <= 5 && _currentPhase >= 0,
            "Phase must be between 0 and 5"
        );
        currentPhase = _currentPhase;
    }
}