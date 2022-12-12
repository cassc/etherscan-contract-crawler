// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./CompliancyChecker.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFCStorage is Ownable {

    /*
    This smart contract has been handcrafted by OpenGem for The Non Fungible Conference 2023 event.
    OpenGem provides tools for users and developers to secure ownership of digital assets. We also advice leading organizations by performing audits on their products.

    https://opengem.com
    */

    struct Coupon {
        bool added;
        uint256 phase;
        mapping (uint256 => bool) redeemed;
    }
    mapping(address => Coupon) public coupons;
    mapping(address => bool) public whitelistClaimed;

    address[] public ERC721List;
    address[] public ERC721EnumerableList;

    uint256 public phase;
    uint256 public basePrice;
    address public nftAddress;
    bytes32 public merkleRoot; 
    
    bool public emergency = false;
    bool public salesLocked = false;
    bool public merkleRootLocked = false;

    event BackupUploaded(string backupData);

    modifier onlyFromNftContract {
        require(msg.sender == nftAddress, 'Only callable by NFT contract.');
        _;
    }

    constructor(uint256 _phase, uint256 _basePrice, bytes32 _merkleRoot) {
        phase = _phase;
        basePrice = _basePrice;
        merkleRoot = _merkleRoot;
    }

    function updateBasePrice(uint256 _basePrice) external onlyOwner {
        basePrice = _basePrice;
    }
    
    function toggleEmergency() external onlyOwner {
        emergency = !emergency;
    }

    function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        require(!merkleRootLocked, "Whitelist locked.");
        merkleRoot = _merkleRoot;
    }

    function lockWhitelist() external onlyOwner { //
        merkleRootLocked = true;
    }

    function lockSales() external onlyOwner {
        salesLocked = true;
    }

    function uploadBackup(string calldata backupData) external onlyOwner {
        emit BackupUploaded(backupData);
    }

    function attachNftContract(address _nftAddress) external onlyOwner {
        nftAddress = _nftAddress;
    }
    
    function updatePhase(uint256 _phase) external onlyOwner {
        require(_phase <= 100, "Phase needs to be below or equal 100.");
        phase = _phase;
    }

    function append721Coupon(address[] calldata _nft_contracts, uint256[] calldata _phases) external onlyOwner {
        require(_nft_contracts.length == _phases.length, "Contracts and Phases length mismatch");

        for (uint256 i = 0; i < _nft_contracts.length;) {
            if (_phases[i] <= 100 && CompliancyChecker.check721Compliancy(_nft_contracts[i])) {
                if (coupons[_nft_contracts[i]].added == false) {
                    if (CompliancyChecker.check721EnumerableCompliancy(_nft_contracts[i])) {
                        ERC721EnumerableList.push(_nft_contracts[i]);
                    } else {
                        ERC721List.push(_nft_contracts[i]);
                    }
                    coupons[_nft_contracts[i]].added = true;
                }
                coupons[_nft_contracts[i]].phase = _phases[i];
            }
            unchecked{ i++; }
        }
    }

    function getAllEligibles() external view returns (address[] memory) {
        address[] memory eligible_contracts = new address[](1000);
        uint256 k = 0;

        for (uint256 i = 0; i < ERC721List.length;) {
            if (isContractEligible(ERC721List[i]) && k < 1000) {
                eligible_contracts[k] = ERC721List[i];
                unchecked{ k++; }
            }
            unchecked{ i++; }
        }

        for (uint256 i = 0; i < ERC721EnumerableList.length;) {
            if (isContractEligible(ERC721EnumerableList[i]) && k < 1000) {
                eligible_contracts[k] = ERC721EnumerableList[i];
                unchecked{ k++; }
            }
            unchecked{ i++; }
        }

        return eligible_contracts;
    }

    function getRedeemedIdsFromContract(address _nft_contract, uint256 _start, uint256 _end) external view returns (string[] memory) {
        require(_start <= _end, "Start should be below End.");
        require(_end - _start < 1000, "Max range should be < 1000.");
        require(CompliancyChecker.check721Compliancy(_nft_contract), "This is not an ERC721.");

        string[] memory ids = new string[](1000);
        uint256 k = 0;

        for (uint256 i = _start; i <= _end;) {
            uint256 id;
            if (CompliancyChecker.check721EnumerableCompliancy(_nft_contract)) {
                id = IERC721Enumerable(_nft_contract).tokenByIndex(i);
            } else {
                id = i;
            }
            if (getRedeemFromId(_nft_contract, id) && k < 1000) {
                ids[k] = Strings.toString(id);
                unchecked { k++; }
            }
            unchecked { i++; }
        }

        return ids;
    }

    function getRedeemFromId(address _nft_contract, uint256 _nft_id) public view returns (bool) {
        return coupons[_nft_contract].redeemed[_nft_id];
    }

    function isContractEligible(address _nft_contract) public view returns (bool) {
        return (coupons[_nft_contract].phase >= phase && coupons[_nft_contract].added);
    }

    function getEligible721(address _buyer) external view returns (address[] memory) {
        uint256 j = 0;
        address[] memory nft_721_contracts = new address[](1000);

        for (uint256 i = 0; i < ERC721List.length;) {
            if (isContractEligible(ERC721List[i]) &&
                IERC721(ERC721List[i]).balanceOf(_buyer) > 0 &&
                j < 1000) {
                nft_721_contracts[j] = ERC721List[i];
                unchecked{ j++; }
            }
            unchecked{ i++; }
        }

        return nft_721_contracts;
    }

    function getEligibleTokens(address _buyer, address[] calldata _nft_721_contracts, uint256[] calldata _nft_721_ids)
        external view returns (address[] memory, uint256[] memory)
    {
        require(_nft_721_contracts.length == _nft_721_ids.length, "Contracts and Ids length mismatch");

        uint256 k = 0;
        address[] memory eligible_contracts = new address[](1000);
        uint256[] memory eligible_ids = new uint256[](1000);
        
        for (uint256 j = 0; j < _nft_721_contracts.length;) {
            if (isContractEligible(_nft_721_contracts[j])) {
                if (IERC721(_nft_721_contracts[j]).ownerOf(_nft_721_ids[j]) == _buyer &&
                    !getRedeemFromId(_nft_721_contracts[j], _nft_721_ids[j]) && 
                    k < 1000) {
                    eligible_contracts[k] = _nft_721_contracts[j];
                    eligible_ids[k] = _nft_721_ids[j];
                    unchecked{ k++; }
                }
            }
            unchecked{ j++; }
        }

        for (uint256 i = 0; i < ERC721EnumerableList.length;) {
            if (isContractEligible(ERC721EnumerableList[i])) {
                IERC721Enumerable ERC721EnumContract = IERC721Enumerable(ERC721EnumerableList[i]);
                for (uint256 j = 0; j < (ERC721EnumContract.balanceOf(_buyer) % 5);) {
                    uint256 tmp_id = ERC721EnumContract.tokenOfOwnerByIndex(_buyer, j);
                    if (!getRedeemFromId(ERC721EnumerableList[i], tmp_id) && k < 1000) {
                        eligible_contracts[k] = ERC721EnumerableList[i];
                        eligible_ids[k] = tmp_id;
                        unchecked{ k++; }
                    }
                    unchecked{ j++; }
                }
            }
            unchecked{ i++; }
        }

        return (eligible_contracts, eligible_ids);
    }

    function storeWhitelistClaim(address _addr) external onlyFromNftContract {
        whitelistClaimed[_addr] = true;
    }

    function redeem(address _nft_contract, uint256 _nft_id) external onlyFromNftContract {
        coupons[_nft_contract].redeemed[_nft_id] = true;
    }

    function checkEligibility(address _nft_contract, uint256 _nft_id) external view {
        require(phase > 0, "Private sales are closed.");
        require(isContractEligible(_nft_contract), "NFT not eligible.");
        require(!getRedeemFromId(_nft_contract, _nft_id), "NFT already redeemed.");
    }
}