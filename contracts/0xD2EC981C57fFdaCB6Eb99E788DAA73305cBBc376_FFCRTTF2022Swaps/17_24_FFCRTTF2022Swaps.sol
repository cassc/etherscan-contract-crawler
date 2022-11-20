// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";

enum Stage {
    NotStarted,
    Group,
    R16,
    Quarter,
    Semi,
    Final,
    Ended
}

enum Form {
    Unknown,
    Normal,
    Special
}

struct StageDetail {
    EnumerableMapUpgradeable.AddressToUintMap minterToTokenId;
    uint256 minimum;
    uint256 maximum;
}

contract FFCRTTF2022Swaps is
    EIP712Upgradeable,
    OwnableUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC721AQueryableUpgradeable
{
    using AddressUpgradeable for address payable;
    using ECDSAUpgradeable for bytes32;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    bytes32 public constant ALLOWLIST_SIGNER_ROLE =
        keccak256("ALLOWLIST_SIGNER_ROLE");
    bytes32 public constant ALLOWLIST_TYPEHASH =
        keccak256("Allow(address account)");
    bytes32 public constant EXCHANGER_ROLE = keccak256("EXCHANGER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    address public constant OS_CONDUIT_ADDRESS =
        0x1E0049783F008A0085193E00003D00cd54003c71;
    uint256 public constant START_TOKEN_ID = 1;
    bytes32 public constant UPGRADE_TYPEHASH =
        keccak256("Upgrade(uint256[] tokenIds)");

    string public baseURI;
    uint256 public specialPercentThreshold;
    uint256[] public stageTimestamps;

    EnumerableSetUpgradeable.UintSet internal _addedSpecialTokenIds;
    mapping(uint256 => StageDetail) internal _stageToDetails;

    event BaseURIUpdated(string oldBaseURI, string baseURI);
    event DowngradedFromSpecial(uint256[] tokenIds);
    event SpecialPercentThresholdUpdated(
        uint256 oldSpecialPercentThreshold,
        uint256 specialPercentThreshold
    );
    event StageTimestampsUpdated(
        uint256[] oldStageTimestamps,
        uint256[] stageTimestamps
    );
    event UpgradedToSpecial(uint256[] tokenIds);

    error AccountPreviouslyMintedStage();
    error InvalidSignature();
    error InvalidValue();
    error MintNotOpen();
    error NotAnEOA();
    error Unauthorized();
    error ValueUnchanged();

    function initialize(
        address allowlistSigner,
        address operator,
        string calldata baseURI_,
        uint256[] calldata stageTimestamps_,
        uint256 specialPercentThreshold_
    ) public initializerERC721A initializer {
        __EIP712_init("FFCRTTF2022Swaps", "1");
        __Ownable_init();
        __AccessControl_init();
        __ERC721A_init("FFC: RTTF 2022 Swaps", "FFCRTTF2022S");
        __ERC721AQueryable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ALLOWLIST_SIGNER_ROLE, allowlistSigner);
        _grantRole(OPERATOR_ROLE, operator);

        baseURI = baseURI_;
        stageTimestamps = stageTimestamps_;
        specialPercentThreshold = specialPercentThreshold_;

        _performMint(_msgSender(), uint256(Stage.Group));
    }

    function mint(bytes calldata signature) external {
        if (tx.origin != _msgSender()) revert NotAnEOA();

        uint256 stage = currentStage();
        if (false == mintAllowedDuring(stage)) revert MintNotOpen();

        bool walletHasMinted = hasAccountMintedStage(_msgSender(), stage);
        if (walletHasMinted) revert AccountPreviouslyMintedStage();

        bool signatureIsValid = isAllowlistSignatureValid(
            signature,
            _msgSender()
        );
        if (false == signatureIsValid) revert InvalidSignature();

        _performMint(_msgSender(), stage);
    }

    function upgrade(bytes calldata signature, uint256[] calldata tokenIds)
        external
    {
        if (false == isUpgradeSignatureValid(signature, tokenIds))
            revert InvalidSignature();

        _upgradeToSpecial(tokenIds);
    }

    function burn(uint256[] calldata tokenIds)
        external
        onlyRole(EXCHANGER_ROLE)
    {
        if (tokenIds.length == 0) revert InvalidValue();

        for (uint256 index = 0; index < tokenIds.length; ++index) {
            _burn(tokenIds[index]);
        }
    }

    function downgradeFromSpecial(uint256[] calldata tokenIds)
        external
        onlyRole(OPERATOR_ROLE)
    {
        for (uint256 index = 0; index < tokenIds.length; ++index) {
            _addedSpecialTokenIds.remove(tokenIds[index]);
        }

        emit DowngradedFromSpecial(tokenIds);
    }

    function upgradeToSpecial(uint256[] calldata tokenIds)
        external
        onlyRole(OPERATOR_ROLE)
    {
        _upgradeToSpecial(tokenIds);
    }

    function setBaseURI(string calldata baseURI_)
        external
        onlyRole(OPERATOR_ROLE)
    {
        if (
            keccak256(abi.encodePacked(baseURI_)) ==
            keccak256(abi.encodePacked(_baseURI()))
        ) revert ValueUnchanged();

        string memory oldBaseURI = _baseURI();
        baseURI = baseURI_;

        emit BaseURIUpdated(oldBaseURI, baseURI);
    }

    function setSpecialPercentThreshold(uint256 specialPercentThreshold_)
        external
        onlyRole(OPERATOR_ROLE)
    {
        if (specialPercentThreshold_ == specialPercentThreshold)
            revert ValueUnchanged();

        uint256 oldSpecialPercentThreshold = specialPercentThreshold;
        specialPercentThreshold = specialPercentThreshold_;

        emit SpecialPercentThresholdUpdated(
            oldSpecialPercentThreshold,
            specialPercentThreshold
        );
    }

    function setStageTimestamps(uint256[] calldata stageTimestamps_)
        external
        onlyRole(OPERATOR_ROLE)
    {
        if (stageTimestamps_.length != 7) revert InvalidValue();

        if (false == _areTimestampsDifferent(stageTimestamps, stageTimestamps_))
            revert ValueUnchanged();

        uint256[] storage oldStageTimestamps = stageTimestamps;
        stageTimestamps = stageTimestamps_;

        emit StageTimestampsUpdated(oldStageTimestamps, stageTimestamps);
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(_msgSender()).sendValue(address(this).balance);
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() external view returns (uint256) {
        return _totalBurned();
    }

    function nextTokenId() external view returns (uint256) {
        return _nextTokenId();
    }

    function mintersOf(uint256 stage) external view returns (address[] memory) {
        StageDetail storage stageDetail = _stageToDetails[stage];

        address[] memory minters = new address[](
            stageDetail.minterToTokenId.length()
        );
        for (uint256 index = 0; index < minters.length; ++index) {
            (address account, ) = stageDetail.minterToTokenId.at(index);
            minters[index] = account;
        }

        return minters;
    }

    function addedSpecialTokenIds() external view returns (uint256[] memory) {
        return _addedSpecialTokenIds.values();
    }

    function tokenIdRanges() external view returns (uint256[] memory) {
        uint256[] memory ranges = new uint256[](14);
        for (
            uint256 stage = uint256(Stage.Group);
            stage <= uint256(Stage.Final);
            ++stage
        ) {
            (uint256 minimum, uint256 maximum) = tokenIdRangeOf(stage);
            ranges[2 * stage] = minimum;
            ranges[2 * stage + 1] = maximum;
        }

        return ranges;
    }

    function stagesMintedBy(address account)
        external
        view
        returns (bool[] memory)
    {
        bool[] memory stagesMinted = new bool[](7);
        for (
            uint256 stage = uint256(Stage.Group);
            stage <= uint256(Stage.Final);
            ++stage
        ) {
            stagesMinted[stage] = hasAccountMintedStage(account, stage);
        }

        return stagesMinted;
    }

    function propertiesOfMany(uint256[] calldata tokenIds)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory properties = new uint256[](2 * tokenIds.length);

        for (uint256 index = 0; index < tokenIds.length; ++index) {
            (Stage stage, Form form) = propertiesOf(tokenIds[index]);

            properties[2 * index] = uint256(stage);
            properties[2 * index + 1] = uint256(form);
        }

        return properties;
    }

    function tokenIdsMintedBy(address account)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory tokenIdsMinted = new uint256[](7);
        for (
            uint256 stage = uint256(Stage.Group);
            stage <= uint256(Stage.Final);
            ++stage
        ) {
            StageDetail storage stageDetail = _stageToDetails[stage];

            (bool contains, uint256 tokenId) = stageDetail
                .minterToTokenId
                .tryGet(account);
            if (contains) {
                tokenIdsMinted[stage] = tokenId;
            }
        }

        return tokenIdsMinted;
    }

    function currentStage() public view returns (uint256) {
        uint256 stageIndex = 0;

        while (
            stageIndex < stageTimestamps.length - 1 &&
            stageTimestamps[stageIndex + 1] <= block.timestamp
        ) {
            ++stageIndex;
        }

        return stageIndex;
    }

    function tokenIdRangeOf(uint256 stage)
        public
        view
        returns (uint256, uint256)
    {
        StageDetail storage stageDetail = _stageToDetails[stage];

        return (stageDetail.minimum, stageDetail.maximum);
    }

    function tokenIdMintedBy(address account, uint256 stage)
        public
        view
        returns (uint256)
    {
        StageDetail storage stageDetail = _stageToDetails[stage];

        (, uint256 tokenId) = stageDetail.minterToTokenId.tryGet(account);
        return tokenId;
    }

    function hasAccountMintedStage(address account, uint256 stage)
        public
        view
        returns (bool)
    {
        return tokenIdMintedBy(account, stage) >= _startTokenId();
    }

    function propertiesOf(uint256 tokenId) public view returns (Stage, Form) {
        for (
            uint256 stage = uint256(Stage.Group);
            stage <= uint256(Stage.Final);
            ++stage
        ) {
            (
                uint256 stageMinimumTokenId,
                uint256 stageMaximumTokenId
            ) = tokenIdRangeOf(stage);

            if (
                stageMinimumTokenId <= tokenId && stageMaximumTokenId >= tokenId
            ) {
                Form form = Form.Normal;
                if (_addedSpecialTokenIds.contains(tokenId)) {
                    form = Form.Special;
                } else {
                    uint256 numberOfTokensInStage = MathUpgradeable.max(
                        stageMaximumTokenId - stageMinimumTokenId,
                        1
                    );
                    uint256 thisTokenNumberInStage = tokenId -
                        stageMinimumTokenId;
                    uint256 percent = ((100 * thisTokenNumberInStage) /
                        numberOfTokensInStage);
                    if (percent < specialPercentThreshold) {
                        form = Form.Special;
                    }
                }

                return (Stage(stage), form);
            }
        }

        revert InvalidValue();
    }

    function isAllowlistSignatureValid(
        bytes calldata signature,
        address account
    ) public view returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(ALLOWLIST_TYPEHASH, account))
        );
        address signer = ECDSAUpgradeable.recover(digest, signature);

        return hasRole(ALLOWLIST_SIGNER_ROLE, signer);
    }

    function isUpgradeSignatureValid(
        bytes calldata signature,
        uint256[] calldata tokenIds
    ) public view returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    UPGRADE_TYPEHASH,
                    keccak256(abi.encodePacked(tokenIds))
                )
            )
        );
        address signer = ECDSAUpgradeable.recover(digest, signature);

        return hasRole(ALLOWLIST_SIGNER_ROLE, signer);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            IERC721AUpgradeable,
            AccessControlEnumerableUpgradeable,
            ERC721AUpgradeable
        )
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            AccessControlEnumerableUpgradeable.supportsInterface(interfaceId);
    }

    function isApprovedForAll(address owner_, address operator)
        public
        view
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        returns (bool)
    {
        return
            super.isApprovedForAll(owner_, operator) ||
            operator == OS_CONDUIT_ADDRESS ||
            hasRole(EXCHANGER_ROLE, operator);
    }

    function mintAllowedDuring(uint256 stage_) public pure returns (bool) {
        Stage stage = Stage(stage_);

        return
            stage == Stage.Group ||
            stage == Stage.R16 ||
            stage == Stage.Quarter ||
            stage == Stage.Semi ||
            stage == Stage.Final;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _msgSenderERC721A() internal view override returns (address) {
        return _msgSender();
    }

    function _startTokenId() internal pure override returns (uint256) {
        return START_TOKEN_ID;
    }

    function _performMint(address account, uint256 stage) private {
        StageDetail storage stageDetail = _stageToDetails[stage];

        uint256 tokenId = _nextTokenId();
        if (stageDetail.minimum == 0) {
            stageDetail.minimum = tokenId;
        }
        stageDetail.maximum = tokenId;

        stageDetail.minterToTokenId.set(account, tokenId);

        _safeMint(account, 1);
    }

    function _upgradeToSpecial(uint256[] calldata tokenIds) private {
        for (uint256 index = 0; index < tokenIds.length; ++index) {
            _addedSpecialTokenIds.add(tokenIds[index]);
        }

        emit UpgradedToSpecial(tokenIds);
    }

    function _areTimestampsDifferent(
        uint256[] storage t1,
        uint256[] calldata t2
    ) private view returns (bool) {
        bool changed = false;
        for (
            uint256 index = 0;
            index < t1.length && false == changed;
            ++index
        ) {
            if (t1[index] != t2[index]) {
                changed = true;
            }
        }
        return changed;
    }
}