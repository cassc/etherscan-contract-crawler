// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";

import "@massless.io/smart-contract-library/contracts/interfaces/IContractURI.sol";
import "@massless.io/smart-contract-library/contracts/sale/SaleState.sol";
import "@massless.io/smart-contract-library/contracts/signature/Signature.sol";
import "@massless.io/smart-contract-library/contracts/utils/PreAuthorisable.sol";
import "@massless.io/smart-contract-library/contracts/utils/AdminPermissionable.sol";
import "@massless.io/smart-contract-library/contracts/utils/WithdrawalSplittable.sol";
import "@massless.io/smart-contract-library/contracts/utils/BatchMintable.sol";
import "@massless.io/smart-contract-library/contracts/royalty/Royalty.sol";
import "@massless.io/smart-contract-library/contracts/minting/Whitelist.sol";
import "@massless.io/smart-contract-library/contracts/minting/Reserved.sol";

import "./interfaces/IFalloutCrystal.sol";
import "./interfaces/IJungle.sol";

error SoldOut();
error MustMintMinimumOne();
error NotEnoughEthProvided();
error AlreadyUsedMutation();
error NotGenesisOwner();
error NotCrystalOwner();
error NoTrailingSlash();
error DeployerIsMasslessAdmin();

error ZeroReceiverAddress();
error ZeroReceiverBasisPoints();

contract FalloutFreaks is
    AdminPermissionable,
    WithdrawalSplittable,
    BatchMintable,
    SaleState,
    Signature,
    PreAuthorisable,
    Royalty,
    ERC721ABurnable,
    Reserved,
    Whitelist
{
    using Strings for uint256;

    struct CrystalUsage {
        bool level1;
        bool level2;
        bool level3;
    }

    struct MutationData {
        uint32 level1;
        uint32 level2;
        uint32 level3;
    }

    struct MintDetails {
        uint32 originalId;
        uint32 level;
        uint32 mintType;
        uint32 mutationId;
        uint128 aux;
    }

    // Constants
    uint256 public constant MINT_PRICE = 0.13 ether;
    uint256 public constant MAX_SUPPLY = 15000;
    uint256 public constant MAX_MINT = 5000;
    uint256 public constant MAX_BATCH_MINT = 3;

    address[] private BENEFICIARY_WALLETS = [
        address(0x8e5F332a0662C8c06BDD1Eed105Ba1C4800d4c2f),
        address(0x954BfE5137c8D2816cE018EFd406757f9a060e5f),
        address(0x2E7D93e2AdFC4a36E2B3a3e23dE7c35212471CfB),
        address(0xd196e0aFacA3679C27FC05ba8C9D3ABBCD353b5D)
    ];

    uint256[] private BENEFICIARIES_PRIMARY = [5500, 2000, 500, 2000];

    uint16[] private _mintablesByLevel = [4000, 998, 2];

    string private baseURI;

    // Jungle Freaks Genesis contract
    IERC721 private _jfgContract;

    // Jungle Freaks Mortor Club
    IERC721 private _jfmcContract;

    // Crystal Freals contract
    IFalloutCrystal private _jfcContract;

    // Staking
    IJungle private _jungleContract;

    // Fallout Freaks Mint Log Details
    mapping(uint256 => MintDetails) private _mintDetails;

    // Jungle Freaks Genesis Token Used Details
    mapping(uint256 => CrystalUsage) private _genesisTokenUsage;

    // Sequential number per each level
    MutationData private _mutationData;

    event AllowListMintBegins();
    event PublicMintBegins();
    event CrystalMutationMintBegins();
    event MintEnds();
    event BaseURIUpdated(string newBaseURI_);

    // Modifiers
    modifier checkOriginalAndCrystalUsage(
        uint256 originalTokenId_,
        uint8 crystalTokenId_
    ) {
        if (
            _jfgContract.ownerOf(originalTokenId_) != _msgSender() &&
            _jungleContract.getStaker(originalTokenId_) != _msgSender()
        ) {
            revert NotGenesisOwner();
        } else if (_jfcContract.balanceOf(_msgSender(), crystalTokenId_) == 0) {
            revert NotCrystalOwner();
        } else if (
            crystalTokenId_ == 1 &&
            _genesisTokenUsage[originalTokenId_].level1 == true
        ) {
            revert AlreadyUsedMutation();
        } else if (
            crystalTokenId_ == 2 &&
            _genesisTokenUsage[originalTokenId_].level2 == true
        ) {
            revert AlreadyUsedMutation();
        } else if (
            crystalTokenId_ == 3 &&
            _genesisTokenUsage[originalTokenId_].level3 == true
        ) {
            revert AlreadyUsedMutation();
        }

        _;
    }

    modifier maxMintLimit(uint256 quantity_) {
        uint256 _remainingReservedTokens = reservedMintSupply -
            reservedMintQuantity;
        uint256 mintLimit = MAX_MINT -
            _remainingReservedTokens -
            _totalMinted();

        if (quantity_ == 0) revert MustMintMinimumOne();
        if (quantity_ > mintLimit) revert SoldOut();
        _;
    }

    modifier enoughEthProvided(uint8 quantity_) {
        uint256 discount;
        if (
            IERC721(_jfgContract).balanceOf(_msgSender()) > 0 ||
            IJungle(_jungleContract).getStakedAmount(_msgSender()) > 0
        ) {
            discount += 0.02 ether;
        }
        if (IERC721(_jfmcContract).balanceOf(_msgSender()) > 0) {
            discount += 0.01 ether;
        }
        if (msg.value < (MINT_PRICE - discount) * quantity_) {
            revert NotEnoughEthProvided();
        }

        _;
    }

    constructor(
        address signer_,
        address admin_,
        address royaltyReceiver_,
        IERC721 jfgContract_,
        IERC721 jfmcContract_,
        IFalloutCrystal jfcContract_,
        IJungle jungleContract_,
        address[] memory preAuthorized_
    )
        ERC721A("Fallout Freaks", "FFRK")
        Signature(signer_)
        PreAuthorisable(preAuthorized_)
    {
        if (_msgSender() == admin_) revert DeployerIsMasslessAdmin();
        _jfgContract = jfgContract_;
        _jfmcContract = jfmcContract_;
        _jfcContract = jfcContract_;
        _jungleContract = jungleContract_;

        setRoyaltyReceiver(royaltyReceiver_);
        setRoyaltyBasisPoints(500); // 5.00%

        _setReservedMintSupply(100);

        _setMaxBatchMint(MAX_BATCH_MINT);

        setBeneficiaries(BENEFICIARY_WALLETS, BENEFICIARIES_PRIMARY);

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
    }

    // Allow List Random Mint
    function setMerkleRoot(bytes32 _merkleRoot) public onlyAdmin {
        _setMerkleRoot(_merkleRoot);
    }

    function _whitelistMint(bytes32[] calldata merkleProof_, uint8 quantity_)
        private
        checkMerkleProof(_msgSender(), merkleProof_)
    {
        _safeMint(_msgSender(), quantity_);
    }

    function allowListRandomMint(
        bytes calldata signature_,
        bytes32 salt_,
        bytes32[] calldata merkleProof_,
        uint8 quantity_
    )
        external
        payable
        whenSaleIsActive("AllowListRandomMint")
        onlySignedTx(
            keccak256(
                abi.encodePacked(_msgSender(), salt_, merkleProof_, quantity_)
            ),
            signature_
        )
        maxMintLimit(quantity_)
        checkMaxBatchMint(quantity_)
        enoughEthProvided(quantity_)
    {
        _whitelistMint(merkleProof_, quantity_);

        _processRandomMint(salt_, quantity_);
    }

    // Public Random Mint
    function publicRandomMint(
        bytes calldata signature_,
        bytes32 salt_,
        uint8 quantity_
    )
        external
        payable
        whenSaleIsActive("PublicRandomMint")
        onlySignedTx(
            keccak256(abi.encodePacked(_msgSender(), salt_, quantity_)),
            signature_
        )
        maxMintLimit(quantity_)
        checkMaxBatchMint(quantity_)
        enoughEthProvided(quantity_)
    {
        _safeMint(_msgSender(), quantity_);

        _processRandomMint(salt_, quantity_);
    }

    function reservedRandomMint(
        bytes32 randomness_,
        address to_,
        uint8 quantity_
    )
        external
        onlyAdmin
        checkReservedMintQuantity(quantity_)
        checkAddressReservedMint(to_)
    {
        reservedMintQuantity += quantity_;
        _safeMint(to_, quantity_);

        _processRandomMint(randomness_, quantity_);
    }

    // Crystal Mutation Mint
    function crystalMutationMint(
        bytes calldata signature_,
        bytes32 salt_,
        uint32 originalTokenId_,
        uint8 crystalTokenId_
    )
        external
        whenSaleIsActive("CrystalMutationMint")
        onlySignedTx(
            keccak256(
                abi.encodePacked(
                    _msgSender(),
                    salt_,
                    originalTokenId_,
                    crystalTokenId_
                )
            ),
            signature_
        )
        checkOriginalAndCrystalUsage(originalTokenId_, crystalTokenId_)
    {
        _safeMint(_msgSender(), 1);

        _jfcContract.burn(_msgSender(), crystalTokenId_, 1);

        if (crystalTokenId_ == 1) {
            _genesisTokenUsage[originalTokenId_].level1 = true;
        } else if (crystalTokenId_ == 2) {
            _genesisTokenUsage[originalTokenId_].level2 = true;
        } else if (crystalTokenId_ == 3) {
            _genesisTokenUsage[originalTokenId_].level3 = true;
        }

        uint32 mutationId = _createMutationId(1, crystalTokenId_);
        MintDetails memory newMintDetails = MintDetails({
            originalId: originalTokenId_,
            level: crystalTokenId_,
            mintType: 1, // Crystal Mint
            mutationId: mutationId,
            aux: 0
        });
        _mintDetails[_currentIndex - 1] = newMintDetails;
    }

    function _createMutationId(uint32 mintType_, uint8 level_)
        private
        returns (uint32)
    {
        uint32 mutationId = 0;
        if (mintType_ == 0 && level_ == 1) {
            mutationId = _mutationData.level1;
            _mutationData.level1++;
        } else if (mintType_ == 0 && level_ == 2) {
            mutationId = _mutationData.level2;
            _mutationData.level2++;
        } else if (level_ == 3) {
            mutationId = _mutationData.level3;
            _mutationData.level3++;
        }
        return mutationId;
    }

    // ----- Random Mint Management -----

    function _sumMintablesUntilLevel(uint8 level_)
        private
        view
        returns (uint256)
    {
        uint256 totalMintables = 0;

        if (level_ > _mintablesByLevel.length) {
            level_ = uint8(_mintablesByLevel.length);
        }

        for (uint8 i; i < level_; i++) {
            totalMintables += _mintablesByLevel[i];
        }
        return totalMintables;
    }

    function _decideLevels(bytes32 randomness_, uint8 quantity_)
        private
        returns (uint8[] memory)
    {
        uint32[] memory randomNumbers = new uint32[](quantity_);

        for (uint8 i; i < quantity_; i++) {
            randomNumbers[i] = uint32(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            _currentIndex - quantity_ + i,
                            randomness_,
                            block.difficulty
                        )
                    )
                )
            );
        }

        uint8[] memory levels = new uint8[](quantity_);

        for (uint8 i; i < quantity_; i++) {
            uint256 totalMintables = _sumMintablesUntilLevel(3);
            uint256 selectedNum = (randomNumbers[i] * totalMintables) /
                type(uint32).max;

            uint8 level;
            if (selectedNum < _sumMintablesUntilLevel(1)) {
                level = 0;
            } else if (selectedNum < _sumMintablesUntilLevel(2)) {
                level = 1;
            } else if (selectedNum < _sumMintablesUntilLevel(3)) {
                level = 2;
            } else {
                revert SoldOut();
            }
            levels[i] = level + 1; // Index starts from 0, but level starts from 1
            _mintablesByLevel[level]--;
        }

        return levels;
    }

    function _processRandomMint(bytes32 randomness_, uint8 quantity_) private {
        uint8[] memory tokenLevels = _decideLevels(randomness_, quantity_);
        for (uint8 i; i < quantity_; i++) {
            uint32 mutationId = _createMutationId(0, tokenLevels[i]);
            MintDetails memory newMintDetails = MintDetails({
                originalId: 0,
                level: tokenLevels[i],
                mintType: 0, // Random Mint
                mutationId: mutationId,
                aux: 0
            });
            _mintDetails[_currentIndex - quantity_ + i] = newMintDetails;
        }
    }

    function getMintDetails(uint256 _tokenId)
        public
        view
        returns (MintDetails memory)
    {
        return _mintDetails[_tokenId];
    }

    // ----- State Management -----
    function startAllowListMint() external onlyAdminOrModerator {
        _setSaleType("AllowListRandomMint");
        _setSaleState(State.ACTIVE);

        emit AllowListMintBegins();
    }

    function startPublicMint() external onlyAdminOrModerator {
        _setSaleType("PublicRandomMint");
        _setSaleState(State.ACTIVE);

        emit PublicMintBegins();
    }

    function startCrystalMutationMint() external onlyAdminOrModerator {
        _setSaleType("CrystalMutationMint");
        _setSaleState(State.ACTIVE);

        emit CrystalMutationMintBegins();
    }

    function unpauseMint() external onlyAdminOrModerator {
        _unpause();
    }

    function pauseMint() external onlyAdminOrModerator {
        _pause();
    }

    function endMint() external onlyAdmin {
        if (getSaleState() == State.NOT_STARTED) revert NoActiveSale();
        _setSaleState(State.FINISHED);

        emit MintEnds();
    }

    // ----- URI Management -----

    function setBaseURI(string memory baseURI_) public onlyAdminOrModerator {
        if (bytes(baseURI_)[bytes(baseURI_).length - 1] != bytes1("/"))
            revert NoTrailingSlash();
        baseURI = baseURI_;

        emit BaseURIUpdated(baseURI_);
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseURI, "contract.json"));
    }

    function tokenURI(uint256 tokenId_)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId_), "URI query for nonexistent token");

        return
            string(
                abi.encodePacked(
                    baseURI,
                    "token/",
                    tokenId_.toString(),
                    ".json"
                )
            );
    }

    // ----- Royalty Management -----

    function setRoyaltyReceiver(address address_) public onlyAdmin {
        if (address_ == address(0)) {
            revert ZeroReceiverAddress();
        }
        _setRoyaltyReceiver(address_);
    }

    function setRoyaltyBasisPoints(uint32 basisPoints_) public onlyAdmin {
        if (basisPoints_ == 0) {
            revert ZeroReceiverBasisPoints();
        }
        _setRoyaltyBasisPoints(basisPoints_);
    }

    // ----- Ownership Management -----

    function transferOwnership(address newOwner_) public override onlyOwner {
        require(
            newOwner_ != address(0),
            "Ownable: new owner is the zero address"
        );

        _grantRole(DEFAULT_ADMIN_ROLE, newOwner_);
        _revokeRole(DEFAULT_ADMIN_ROLE, owner());
        _transferOwnership(newOwner_);
    }

    // ----- Authorization Management -----
    function setAuthorizedAddress(address authorizedAddress_, bool authorized_)
        public
        onlyAdmin
    {
        _setAuthorizedAddress(authorizedAddress_, authorized_);
    }

    function setSignerAddress(address signerAddress_)
        public
        onlyAdminOrModerator
    {
        _setSignerAddress(signerAddress_);
    }

    // Compulsory overrides
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC721A, Royalty)
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            ERC721A.supportsInterface(interfaceId);
    }

    /**
     * Override isApprovedForAll to whitelist the trusted accounts to enable gas-free listings.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        if (_isAuthorizedAddress(_operator)) {
            return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }
}