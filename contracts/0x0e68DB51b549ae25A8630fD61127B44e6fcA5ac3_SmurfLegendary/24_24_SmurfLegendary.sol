// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
// Local customization
import "./ERC721EnumerableUpgradeable.sol";
//For the crystals :
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./Constants.sol";
import "./ISmurfMint.sol";

contract SmurfLegendary is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, PausableUpgradeable, AccessControlUpgradeable, ERC721BurnableUpgradeable, ERC2981Upgradeable, EIP712Upgradeable, SmurfConstants, ISmurfMint {
    // Keeping track of given smurfs
    mapping(uint => uint) public    __givenSmurfsForPhase;

    // Max quantities per phase
    uint[] public                   __phaseQuantities;

    // Defining team addresses
    address public                  __approverAddress;
    address public                  __withdrawalWallet;

    // Full price of a smurf defined by the bucket auction
    uint public                     __bucketDefinedPrice;

    // Contract variables
    string public                   __contractUri;                      // The contract URI json link
    string public 	                __tokenUriBase;                     // Domain & api root
    bool public                     __isCrystalMintingOpen;

    mapping(uint => bool)           __crystalHasBeenUsed;

    event CrystalsMinted(address indexed to, uint[] tokenIds, uint phase);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _royaltyAddress, uint96 _royaltyValue, address _approverAddress, address _withdrawalWallet) initializer public {
        PERCENTAGES_BPS = [8000, 5000, 4000, 3000, 3000, 3000, 2500, 2500, 2500, 2500, 2000, 2000, 2000, 2000, 2000, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500];

        __ERC721_init("Legendary Smurfs", "TSS: LGD");
        __ERC721Enumerable_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC721Burnable_init();
        __EIP712_init("SmurfSociety", "1");

        // Grant roles to deployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        _setDefaultRoyalty(_royaltyAddress, _royaltyValue);
        __approverAddress = _approverAddress;
        __withdrawalWallet = _withdrawalWallet;
    }

    modifier onlyWhenMintingOpen() {
        require(__isCrystalMintingOpen, "Smurf: Redeeming crystals is not opened");
        _;
    }

    function mintCrystalSmurfs(uint[] memory _crystalIds, bytes calldata _signature) public payable onlyWhenMintingOpen whenNotPaused {
        uint totalPrice = getTotalPrice(_crystalIds);
        require(msg.value == totalPrice, "Smurf: Incorrect price");

        _crystalIds = insertionSort(_crystalIds);

        checkApprovals(msg.sender, _crystalIds, _signature);

        for (uint i; i < _crystalIds.length; i++) {
            require(!__crystalHasBeenUsed[_crystalIds[i]], "Smurf: Crystal has already been used for minting !");
            __crystalHasBeenUsed[_crystalIds[i]] = true;

            _safeSmurfMint(msg.sender, _crystalIds[i], PHASE_CRYSTALS);
        }
        
        emit CrystalsMinted(msg.sender, _crystalIds, PHASE_CRYSTALS);
    }

    function mintHackerSmurf(uint _qty) external onlyRole(MINTER_ROLE) whenNotPaused {
        mintSmurf(_qty, msg.sender, PHASE_HACKER_SMURF);
    }

    function mintBucketSmurf(address _to, uint _qty) external onlyRole(RARIBLE_ROLE) whenNotPaused {
        mintSmurf(_qty, _to, PHASE_BUCKET);
    }

    function mintBlueListSmurf(address _to, uint _qty) external onlyRole(MINTER_ROLE) whenNotPaused {
        mintSmurf(_qty, _to, PHASE_BLUELIST);
    }

    function mintFrensSmurf(address _to, uint _qty) external onlyRole(MINTER_ROLE) whenNotPaused {
        mintSmurf(_qty, _to, PHASE_FRENS);
    }

    function mintSmurf(uint _qty, address _to, uint _phaseId) internal whenNotPaused {
        require(_phaseId + 1 <= MAX_PHASE_ID, "Smurf: Phase ID out of range");
        uint startId = _phaseId*PHASE_RANGES + __givenSmurfsForPhase[_phaseId];

        require(__givenSmurfsForPhase[_phaseId] + _qty <= __phaseQuantities[_phaseId], "Smurf: Quantity would exceed max supply");
        
        __givenSmurfsForPhase[_phaseId] += _qty;

         for (uint id=0; id<_qty; id++) {
            _safeSmurfMint(_to, id+startId, _phaseId);
         }
    }

    function _safeSmurfMint(address _to, uint _tokenId, uint _phaseId) internal  {
        require(_tokenId >= _phaseId*PHASE_RANGES && _tokenId < (_phaseId+1)*PHASE_RANGES, "Smurf: Token out of phase range");

        _safeMint(_to, _tokenId);
    }

    function checkApprovals(address _user, uint[] memory _crystalIds, bytes memory _signature) public view {
        bytes32 structHash = keccak256(
            abi.encode(
                CRYSTALS_TYPE_HASH,
                _user,
                keccak256(abi.encodePacked(_crystalIds))
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);
        address recoveredAddress = ECDSAUpgradeable.recover(hash, _signature);

        require(recoveredAddress == __approverAddress, "Smurf: The signature address does not match the provided address");
    }

    function insertionSort(uint[] memory array) public pure returns (uint[] memory) {
        uint len = array.length;

        for (uint i = 1; i < len; i++) {
            uint value = array[i];
            uint j = i;

            while (j > 0 && array[j - 1] > value) {
                array[j] = array[j - 1];
                j--;
            }
            array[j] = value;
        }
        return array;
    }

    // Setters
    function setRoyalties(address _royaltyAddress, uint96 _royaltyValue) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        require(_royaltyAddress != address(0), "Smurf: address zero is not a valid royalty address");

        _setDefaultRoyalty(_royaltyAddress, _royaltyValue);
    }

    function setPriceFromBucketAuction(uint _price) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        require(_price > 0, "Smurf: Price cannot be zero");
        __bucketDefinedPrice = _price;
    }

    function setTokenUriBase(string memory _tokenUriBase) external onlyRole(URI_SETTER_ROLE) whenNotPaused {
        __tokenUriBase = _tokenUriBase;
    }

    function setContractUri(string memory _contractUri) external onlyRole(URI_SETTER_ROLE) whenNotPaused {
        __contractUri = _contractUri;
    }

	function setApproverAddress(address _newApproverAddress) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        require(_newApproverAddress != address(0), "Smurf: address zero is not a valid approver address");

		__approverAddress = _newApproverAddress;
	}	

	function setWithdrawalWallet(address _newWithdrawalWallet) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        require(_newWithdrawalWallet != address(0), "Smurf: address zero is not a valid withdrawal address");

		__withdrawalWallet = _newWithdrawalWallet;
	}	

    function setPhaseQuantities(uint[] memory _phaseQuantities) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        __phaseQuantities = _phaseQuantities;
    }

    function switchCrystalMintingPermission() external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        __isCrystalMintingOpen = !__isCrystalMintingOpen;
    }

    // Getters
    function contractURI() external view returns (string memory) {
        return __contractUri;
    }

    function getPrice(uint _crystalId) public view returns (uint) {
        uint rank = _crystalId % CRYSTAL_RANGES;
        uint price = ((10000-PERCENTAGES_BPS[rank])*__bucketDefinedPrice)/10000; //(10000-BPS) should be before __bdprice otherwise it'll get rounded down to 0

        return price;
    }

    function getTotalPrice(uint[] memory _crystalIds) public view returns (uint) {
        uint totalPrice;
        for (uint i; i<_crystalIds.length; i++) {
            totalPrice += getPrice(_crystalIds[i]);
        }
        return totalPrice;
    }

    function tokenURI(uint256 _tokenId) public view override(ERC721Upgradeable) returns (string memory) {
        if (_exists(_tokenId)) {
            uint phaseId = _tokenId / PHASE_RANGES;
            if (0 == phaseId) {
                return string.concat(__tokenUriBase,"/",StringsUpgradeable.toString(_tokenId),'.json');
            } else if (1 == phaseId) {
                return string.concat(__tokenUriBase,'/Hacker.json');
            } else if (2 == phaseId) {
                return string.concat(__tokenUriBase,'/Bucket.json');
            } else if (3 == phaseId) {
                return string.concat(__tokenUriBase,'/Bluelist.json');
            } else if (4 == phaseId) {
                return string.concat(__tokenUriBase,'/Team.json');
            }
            return string.concat(__tokenUriBase,"/",StringsUpgradeable.toString(_tokenId),'.json');
        } else {
            return "";
        }
    }

    // Internals
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal whenNotPaused override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable, ERC2981Upgradeable) returns (bool) {
        if (interfaceId == type(IERC721EnumerableUpgradeable).interfaceId) {
            return false;
        } else {
            return super.supportsInterface(interfaceId);
        }
    }

    // Withdraw
    function withdraw() external payable onlyRole(DEFAULT_ADMIN_ROLE) returns (bool success) {
        (success,) = payable(__withdrawalWallet).call{value: address(this).balance}("");
    }
}