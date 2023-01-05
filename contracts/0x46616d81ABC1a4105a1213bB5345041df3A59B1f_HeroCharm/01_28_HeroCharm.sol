// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC721AUpgradeable, ERC721AUpgradeable} from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import {ERC721AQueryableUpgradeable} from "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import {ERC721ABurnableUpgradeable} from "erc721a-upgradeable/contracts/extensions/ERC721ABurnableUpgradeable.sol";

import {OperatorFilterer} from "./utils/OperatorFilterer.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IERC2981Upgradeable, ERC2981Upgradeable} from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";

import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract HeroCharm is
    ERC721AQueryableUpgradeable,
    ERC721ABurnableUpgradeable,
    OperatorFilterer,
    OwnableUpgradeable,
    ERC2981Upgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using ECDSAUpgradeable for bytes32;

    bool public operatorFilteringEnabled;

    /*//////////////////////////////////////////////////////////////
                               ADDRESSES
    //////////////////////////////////////////////////////////////*/

    IERC721AUpgradeable public tdc;

    /*//////////////////////////////////////////////////////////////
                            STANDARD STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice The base URI for all tokens.
    string private _baseTokenURI;

    /// @notice Maximum number of mintable heroCharm.
    uint256 public maxSupply;

    /// @notice frozen max supply.
    bool public frzenSupply;

    /*//////////////////////////////////////////////////////////////
                              STAKE STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the public signer.
    address public signer;

    /// @notice The total slot of stakes.
    uint256 public totalStake;

    mapping(uint256 => stakeSlot) public stakeSlots;
    mapping(uint256 => uint32[]) public stakeTokens;

    struct stakeSlot {
        uint32 stakeType;
        uint64 stakeTime;
        uint64 nextMintTime;
        address owner;
    }

    event Stake(
        address indexed owner,
        uint32 indexed stakeType,
        uint256 indexed slotId,
        uint64 stakeTime,
        uint64 nextMintTime,
        uint32[] tokenIds
    );

    event Unstake(
        address indexed owner,
        uint32 indexed stakeType,
        uint256 indexed slotId,
        uint32[] tokenIds
    );

    event Mint(
        address indexed owner,
        uint32 indexed stakeType,
        uint256 indexed slotId,
        uint256 mintNumber
    );

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Only EOA wallets can mint");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor

    constructor() {
        _disableInitializers();
    }

    function initialize(address _tdc) public initializer initializerERC721A {
        __ERC721A_init("HeroCharm", "HC");
        __Ownable_init();
        __ERC2981_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        // Set royalty receiver to the contract creator,
        // at 5% (default denominator is 10000).
        _setDefaultRoyalty(msg.sender, 500);

        tdc = IERC721AUpgradeable(_tdc);
        maxSupply = 999;
    }

    function stake(
        uint256 _stakeType,
        uint32[] calldata _tokenIds,
        bytes[] calldata _signs
    ) external onlyEOA whenNotPaused nonReentrant {
        require(
            _tokenIds.length > 0 && _tokenIds.length <= 3,
            "Invalid tokenIds"
        );
        require(_tokenIds.length == _signs.length, "Invalid signature data");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                tdc.ownerOf(_tokenIds[i]) == msg.sender,
                "Invalid token owner"
            );
            require(
                verify(
                    keccak256(abi.encodePacked(_stakeType, _tokenIds[i])),
                    _signs[i]
                ),
                "Invalid signature"
            );
        }
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tdc.transferFrom(msg.sender, address(this), _tokenIds[i]);
        }

        uint256 nextMintTime = block.timestamp + 2 weeks;
        if (_stakeType == 3) {
            nextMintTime = block.timestamp + 10 days;
        }

        stakeTokens[totalStake] = _tokenIds;
        stakeSlots[totalStake] = stakeSlot({
            stakeType: uint32(_stakeType),
            stakeTime: uint64(block.timestamp),
            nextMintTime: uint64(nextMintTime),
            owner: msg.sender
        });

        emit Stake(
            msg.sender,
            uint32(_stakeType),
            totalStake,
            uint64(block.timestamp),
            uint64(nextMintTime),
            _tokenIds
        );

        totalStake += 1;
    }

    function migration(
        uint256 _stakeType,
        uint32[] calldata _tokenIds,
        bytes[] calldata _signs,
        uint256 _stakeTime,
        uint256 _slodId,
        bytes calldata _mSign
    ) external onlyEOA whenNotPaused nonReentrant {
        require(
            _tokenIds.length > 0 && _tokenIds.length <= 3,
            "Invalid tokenIds"
        );
        require(_tokenIds.length == _signs.length, "Invalid signature data");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                tdc.ownerOf(_tokenIds[i]) == msg.sender,
                "Invalid token owner"
            );
            require(
                verify(
                    keccak256(abi.encodePacked(_stakeType, _tokenIds[i])),
                    _signs[i]
                ),
                "Invalid signature"
            );
        }

        require(
            verify(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        _stakeType,
                        _stakeTime,
                        _slodId
                    )
                ),
                _mSign
            ),
            "Invalid migration signature"
        );
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tdc.transferFrom(msg.sender, address(this), _tokenIds[i]);
        }

        uint256 nextMintTime = _stakeTime + 2 weeks;
        if (_stakeType == 3) {
            nextMintTime = _stakeTime + 10 days;
        }

        stakeTokens[totalStake] = _tokenIds;
        stakeSlots[totalStake] = stakeSlot({
            stakeType: uint32(_stakeType),
            stakeTime: uint64(_stakeTime),
            nextMintTime: uint64(nextMintTime),
            owner: msg.sender
        });

        emit Stake(
            msg.sender,
            uint32(_stakeType),
            totalStake,
            uint64(_stakeTime),
            uint64(nextMintTime),
            _tokenIds
        );

        totalStake += 1;
    }

    function unstake(uint256 _slot) external onlyEOA nonReentrant {
        _unstake(_slot);
    }

    function multipleUnstake(uint256[] calldata _slots)
        external
        onlyEOA
        nonReentrant
    {
        for (uint256 i = 0; i < _slots.length; i++) {
            _unstake(_slots[i]);
        }
    }

    function _unstake(uint256 _slot) internal {
        require(stakeSlots[_slot].owner == msg.sender, "Invalid slot owner");

        for (uint256 i = 0; i < stakeTokens[_slot].length; i++) {
            tdc.transferFrom(address(this), msg.sender, stakeTokens[_slot][i]);
        }
        delete stakeTokens[_slot];
        delete stakeSlots[_slot];
        emit Unstake(
            msg.sender,
            stakeSlots[_slot].stakeType,
            _slot,
            stakeTokens[_slot]
        );
    }

    function mint(uint256 _slotId) external onlyEOA whenNotPaused nonReentrant {
        _mint(_slotId);
    }

    function multipleMint(uint256[] calldata _slots)
        external
        onlyEOA
        whenNotPaused
        nonReentrant
    {
        for (uint256 i = 0; i < _slots.length; i++) {
            _mint(_slots[i]);
        }
    }

    function _mint(uint256 _slotId) internal {
        stakeSlot memory _stakeSlot = stakeSlots[_slotId];
        require(
            _stakeSlot.nextMintTime <= block.timestamp,
            "Not available to mint"
        );

        uint256 totalMint = _calculateMintNum(_stakeSlot);
        require(totalMint > 0, "Not available to mint");

        require(_totalMinted() + totalMint <= maxSupply, "Max supply reached");

        uint256 nextMintTime = _stakeSlot.stakeTime + 2 weeks;
        if (_stakeSlot.stakeType == 3) {
            nextMintTime = _stakeSlot.stakeTime + 10 days;
        }

        stakeSlots[_slotId] = stakeSlot({
            stakeType: _stakeSlot.stakeType,
            stakeTime: _stakeSlot.nextMintTime,
            nextMintTime: uint64(nextMintTime),
            owner: _stakeSlot.owner
        });

        _mint(_stakeSlot.owner, totalMint);

        emit Mint(_stakeSlot.owner, _stakeSlot.stakeType, _slotId, totalMint);
    }

    function _calculateMintNum(stakeSlot memory _stakeSlot)
        internal
        view
        returns (uint256 num)
    {
        uint256 _stakeTime = block.timestamp - _stakeSlot.stakeTime;

        if (_stakeSlot.stakeType == 0) {
            num = 1;
        } else if (_stakeSlot.stakeType == 1) {
            num = 2;
        } else if (_stakeSlot.stakeType == 2 || _stakeSlot.stakeType == 3) {
            num = 3;
        } else {
            revert("Invalid stake type");
        }

        if (_stakeSlot.stakeType == 3) {
            if (_stakeTime / 10 days >= 1) {
                return num;
            }
        } else {
            if (_stakeTime / 2 weeks >= 1) {
                return num;
            }
        }
        return 0;
    }

    function verify(bytes32 _hash, bytes memory _signature)
        internal
        view
        returns (bool)
    {
        return _hash.toEthSignedMessageHash().recover(_signature) == signer;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(!frzenSupply, "Not allow change supply");
        maxSupply = _maxSupply;
    }

    function setFrzenSupply(bool _frzenSupply) external onlyOwner {
        require(!frzenSupply, "Not allow change state");
        frzenSupply = _frzenSupply;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function reverseMint(
        address[] calldata addressList,
        uint256[] calldata _amounts
    ) external onlyOwner {
        require(_numberMinted(msg.sender) == 0, "Already minted");
        for (uint256 i = 0; i < addressList.length; i++) {
            require(
                _totalMinted() + _amounts[i] <= maxSupply,
                "Max supply reached"
            );
            _mint(msg.sender, _amounts[i]);
        }
    }

    /// @dev change stake time when holder migration failed
    function setStakeTime(uint256 _slotId, uint256 _stakeTime)
        external
        onlyOwner
    {
        stakeSlot memory _stakeSlot = stakeSlots[_slotId];

        uint256 nextMintTime = _stakeTime + 2 weeks;
        if (_stakeSlot.stakeType == 3) {
            nextMintTime = _stakeTime + 10 days;
        }

        stakeSlots[_slotId] = stakeSlot({
            stakeType: _stakeSlot.stakeType,
            stakeTime: uint64(_stakeTime),
            nextMintTime: uint64(nextMintTime),
            owner: _stakeSlot.owner
        });
    }

    /* ============ ERC721A ============ */
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721AUpgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function _isPriorityOperator(address operator)
        internal
        pure
        override
        returns (bool)
    {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /* ============ External Getter Functions ============ */
    function getStakeSlotByAddress(address _address)
        external
        view
        returns (
            uint256[] memory,
            stakeSlot[] memory,
            uint32[][] memory
        )
    {
        uint256 count;
        for (uint256 i = 0; i < totalStake; i++) {
            if (stakeSlots[i].owner == _address) {
                count++;
            }
        }

        uint256[] memory _slotIds = new uint256[](count);
        stakeSlot[] memory _stakeSlots = new stakeSlot[](count);
        uint32[][] memory _stakeTokens = new uint32[][](count);
        uint256 index;
        for (uint256 i = 0; i < totalStake; i++) {
            if (stakeSlots[i].owner == _address) {
                _stakeSlots[index] = stakeSlots[i];
                _stakeTokens[index] = stakeTokens[i];
                _slotIds[index] = i;
                index++;
            }
        }

        return (_slotIds, _stakeSlots, _stakeTokens);
    }

    function calculateMintNum(uint256 _slotId) external view returns (uint256) {
        return _calculateMintNum(stakeSlots[_slotId]);
    }

    function getSlot(uint256 _slotId)
        external
        view
        returns (stakeSlot memory, uint32[] memory)
    {
        return (stakeSlots[_slotId], stakeTokens[_slotId]);
    }
}