// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/IConverterMintableERC721.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

// import "hardhat/console.sol";

contract ConverterT is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using EnumerableSet for EnumerableSet.UintSet;
    using BitMaps for BitMaps.BitMap;

    IERC721 public kzgContract;
    IERC721 public avycContract;
    IERC721 public ordKubzContract;
    IERC721 public kubzContract;
    IConverterMintableERC721 public gfContract;
    address public vaultAddress;

    // event Convert(address indexed user, uint256 avycCount);
    // event Burn(address indexed user, uint256 avycCount);
    // event ClaimOrdKubz(address indexed user, uint256 ordKubzTokenId);
    // event ClaimKubz(address indexed user, uint256 kubzTokenId);

    uint256 public avycRequiredPer0xGF;

    uint256 public avycRequiredPerKzg;
    uint256 public avycRequiredPerOrdKubz;
    uint256 public avycRequiredPerKubz;

    EnumerableSet.UintSet availKzgIds;
    EnumerableSet.UintSet availKubzIds;
    EnumerableSet.UintSet availOrdKubzIds;
    uint256 rngCounter;

    BitMaps.BitMap claimedAVYCIds;
    address public signer;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address avycAddress,
        address gfAddress,
        address kzgAddress,
        address kubzAddress,
        address ordKubzAddress,
        address signerAddress
    ) public initializer {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        OwnableUpgradeable.__Ownable_init();
        setAddresses(
            avycAddress,
            gfAddress,
            kzgAddress,
            kubzAddress,
            ordKubzAddress
        );
        signer = signerAddress;
    }

    function checkValidity(
        bytes calldata signature,
        string memory action
    ) public view returns (bool) {
        require(
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(
                    keccak256(abi.encodePacked(msg.sender, action))
                ),
                signature
            ) == signer,
            "invalid signature"
        );
        return true;
    }

    function setSigner(address newSigner) external onlyOwner {
        signer = newSigner;
    }

    function setAddresses(
        address avycAddress,
        address gfAddress,
        address kzgAddress,
        address kubzAddress,
        address ordKubzAddress
    ) public onlyOwner {
        avycContract = IERC721(avycAddress);
        gfContract = IConverterMintableERC721(gfAddress);
        kubzContract = IERC721(kubzAddress);
        kzgContract = IERC721(kzgAddress);
        ordKubzContract = IERC721(ordKubzAddress);
    }

    function setupConversion(
        uint256 req0xGF,
        uint256 reqKzg,
        uint256 reqKubz,
        uint256 reqOrdKubz
    ) external onlyOwner {
        avycRequiredPer0xGF = req0xGF;
        avycRequiredPerKzg = reqKzg;
        avycRequiredPerKubz = reqKubz;
        avycRequiredPerOrdKubz = reqOrdKubz;
    }

    function setupVault(
        address vault,
        uint256[] calldata kzgIds,
        uint256[] calldata kubzIds,
        uint256[] calldata ordKubzIds
    ) external onlyOwner {
        vaultAddress = vault;
        for (uint256 i = 0; i < kzgIds.length; ) {
            availKzgIds.add(kzgIds[i]);
            unchecked {
                i++;
            }
        }
        for (uint256 i = 0; i < kubzIds.length; ) {
            availKubzIds.add(kubzIds[i]);
            unchecked {
                i++;
            }
        }
        for (uint256 i = 0; i < ordKubzIds.length; ) {
            availOrdKubzIds.add(ordKubzIds[i]);
            unchecked {
                i++;
            }
        }
    }

    function removeIds(
        uint256[] calldata kzgIds,
        uint256[] calldata kubzIds,
        uint256[] calldata ordKubzIds
    ) external onlyOwner {
        for (uint256 i = 0; i < kzgIds.length; ) {
            availKzgIds.remove(kzgIds[i]);
            unchecked {
                i++;
            }
        }
        for (uint256 i = 0; i < kubzIds.length; ) {
            availKubzIds.remove(kubzIds[i]);
            unchecked {
                i++;
            }
        }
        for (uint256 i = 0; i < ordKubzIds.length; ) {
            availOrdKubzIds.remove(ordKubzIds[i]);
            unchecked {
                i++;
            }
        }
    }

    function getAvailKzgIds() external view returns (uint256[] memory) {
        return availKzgIds.values();
    }

    function getAvailKubzIds() external view returns (uint256[] memory) {
        return availKubzIds.values();
    }

    function getAvailOrdKubzIds() external view returns (uint256[] memory) {
        return availOrdKubzIds.values();
    }

    function join(
        uint256[] calldata tokenIds
    ) internal pure returns (string memory) {
        string memory buffer = "";
        for (uint256 i = 0; i < tokenIds.length; ) {
            buffer = string.concat(buffer, Strings.toString(tokenIds[i]), ",");
            unchecked {
                i++;
            }
        }
        return buffer;
    }

    function _claimUsingAVYC(
        uint256[] calldata avycTokenIds,
        uint256 deadline,
        bytes calldata signature
    ) internal {
        require(block.timestamp <= deadline, "Exceed deadline");
        string memory action = string.concat(
            "avyc-ownership/",
            Strings.toString(deadline),
            "/",
            join(avycTokenIds)
        );
        checkValidity(signature, action);
        for (uint256 i = 0; i < avycTokenIds.length; ) {
            uint256 avycTokenId = avycTokenIds[i];
            // require(
            //     avycContract.ownerOf(avycTokenId) == msg.sender,
            //     "Incorrect ownership"
            // );
            require(
                !claimedAVYCIds.get(avycTokenId),
                "Some AVYC already claimed"
            );
            claimedAVYCIds.set(avycTokenId);
            unchecked {
                i++;
            }
        }
    }

    function avycOwnerOfMultiple(
        uint256[] calldata tokenIds
    ) external view returns (address[] memory) {
        address[] memory part = new address[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = avycContract.ownerOf(tokenIds[i]);
        }
        return part;
    }

    function isAvycClaimedMultiple(
        uint256[] calldata tokenIds
    ) external view returns (bool[] memory) {
        bool[] memory part = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = claimedAVYCIds.get(tokenIds[i]);
        }
        return part;
    }

    function sort(uint[] calldata data) internal pure returns (uint[] memory) {
        uint[] memory ar = new uint[](data.length);
        for (uint256 i = 0; i < data.length; ) {
            ar[i] = data[i];
            unchecked {
                i++;
            }
        }
        quickSort(ar, int(0), int(ar.length - 1));
        return ar;
    }

    function quickSort(
        uint256[] memory arr,
        int left,
        int right
    ) internal pure {
        int i = left;
        int j = right;
        if (i == j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
    }

    function subsetCheck(
        uint256[] memory arr1,
        uint256[] memory arr2
    ) internal pure returns (bool) {
        uint256 i;
        uint256 j;
        uint256 m = arr1.length;
        uint256 n = arr2.length;
        if (m < n) return false;
        while (i < n && j < m) {
            if (arr1[j] < arr2[i]) {
                j++;
            } else if (arr1[j] == arr2[i]) {
                j++;
                i++;
            } else if (arr1[j] > arr2[i]) {
                return false;
            }
        }
        return (i < n) ? false : true;
    }

    function preserveCheck(
        uint256[] calldata avycTokenIds,
        uint256[] calldata preserveTokenIds
    ) internal pure {
        uint256[] memory sortedAVYCTokenIds = sort(avycTokenIds);
        uint256[] memory sortedPreserveTokenIds = sort(preserveTokenIds);
        // duplicate preserveTokenIds is checked by subsetCheck + _claimUsingAVYC
        require(
            subsetCheck(sortedAVYCTokenIds, sortedPreserveTokenIds),
            "subsetCheck or dupCheck failed"
        );
    }

    function convertToGF(
        uint256[] calldata avycTokenIds,
        uint256[] calldata preserveTokenIds,
        uint256 deadline,
        bytes calldata signature
    ) external nonReentrant {
        require(avycRequiredPer0xGF > 0, "Conversion not open");
        uint256 nftCount = avycTokenIds.length / avycRequiredPer0xGF;
        require(
            nftCount * avycRequiredPer0xGF == avycTokenIds.length,
            "Non divisible count of AVYC provided"
        );
        require(nftCount > 0, "No AVYC provided");
        require(
            preserveTokenIds.length == nftCount,
            "Must preserve correct count of AVYC"
        );

        preserveCheck(avycTokenIds, preserveTokenIds);
        _claimUsingAVYC(avycTokenIds, deadline, signature);
        gfContract.converterMint(msg.sender, preserveTokenIds);
        // emit Convert(msg.sender, avycTokenIds.length);
    }

    // TODO: vault approve all Collection to Converter's address
    function convertToKzg(
        uint256[] calldata avycTokenIds,
        uint256 deadline,
        bytes calldata signature
    ) external {
        _claimUsingAVYC(avycTokenIds, deadline, signature);
        convert(avycTokenIds, avycRequiredPerKzg, availKzgIds, kzgContract);
    }

    function convertToKubz(
        uint256[] calldata avycTokenIds,
        uint256 deadline,
        bytes calldata signature
    ) external {
        _claimUsingAVYC(avycTokenIds, deadline, signature);
        convert(avycTokenIds, avycRequiredPerKubz, availKubzIds, kubzContract);
    }

    function convertToOrdKubz(
        uint256[] calldata avycTokenIds,
        uint256 deadline,
        bytes calldata signature
    ) external {
        _claimUsingAVYC(avycTokenIds, deadline, signature);
        convert(
            avycTokenIds,
            avycRequiredPerOrdKubz,
            availOrdKubzIds,
            ordKubzContract
        );
    }

    function convert(
        uint256[] calldata avycTokenIds,
        uint256 avycRequiredPerCollection,
        EnumerableSet.UintSet storage availTidSet,
        IERC721 collectionContract
    ) private {
        require(avycRequiredPerCollection > 0, "Conversion not open");
        uint256 nftCount = avycTokenIds.length / avycRequiredPerCollection;
        require(
            nftCount * avycRequiredPerCollection == avycTokenIds.length,
            "Non divisible count of AVYC provided"
        );
        require(nftCount > 0, "No AVYC provided");
        uint256 l = availTidSet.length();
        require(l >= nftCount, "Not enough availTidSet left");
        for (uint256 i = 0; i < nftCount; i++) {
            uint256 randTid = availTidSet.at(rng(avycTokenIds) % (l - i));
            availTidSet.remove(randTid);
            collectionContract.transferFrom(vaultAddress, msg.sender, randTid);
        }
    }

    function rng(uint256[] calldata ar) private returns (uint256) {
        unchecked {
            rngCounter++;
        }
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        msg.sender,
                        rngCounter,
                        ar
                    )
                )
            );
    }
}