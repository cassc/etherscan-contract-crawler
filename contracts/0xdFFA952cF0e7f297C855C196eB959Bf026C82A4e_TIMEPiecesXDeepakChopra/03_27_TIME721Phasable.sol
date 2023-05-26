// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./interfaces/ITimeCatsLoveEmHateEm.sol";
import "./Phasable.sol";

// Use custom errors instead require statements
error TIME721Phasable__MaxSupplyExceed();
error TIME721Phasable__MinQuantityNotMet();
error TIME721Phasable__MaxAllowedQuantityExceed();
error TIME721Phasable__MaxAllowedQuantityForPhaseExceed();
error TIME721Phasable__MaxAllowedQuantityForMintPass();
error TIME721Phasable__NotEnoughFunds();
error TIME721Phasable__NotAllowlisted();
error TIME721Phasable__InvalidSignature();

/**
 * @dev ERC721 token extension with phased token distribution.
 *
 * Designed for a more flexible token distribution process leveraging
 * Phasable.sol. It implements various distribution functions with awareness
 * of phase configurations, their whitelisting mechanisms, and verification
 * methods.
 *
 */
abstract contract TIME721Phasable is DefaultOperatorFilterer, ERC721, Phasable {
    // Variables
    uint256 public immutable maxSupply;
    address internal _passAddress = 0x7581F8E289F00591818f6c467939da7F9ab5A777;

    uint256 private _totalSupply = 0;
    uint256 internal _totalAllowedQuantity = 0;
    mapping(address => mapping(uint256 => uint256))
        public amountNFTsPerAddressAndPhase;
    mapping(address => uint256) public amountNFTsPerAddress;
    mapping(address => uint256) public amountNFTsPerAddressWithPass;

    // Constructor
    constructor(
        string memory name,
        string memory tokenSymbol,
        uint256 _maxSupply
    ) ERC721(name, tokenSymbol) {
        maxSupply = _maxSupply;
    }

    // Functions
    /**
     * @dev Mints tokens during public distribution phases.
     *
     * NOTE: This method is for internal use, no access control implemented
     */
    function _mint(uint256 _phase, uint256 _quantity)
        internal
        virtual
        whenPhaseActive(_phase)
        whenPhasePublic(_phase)
    {
        _validateRequirements(_phase, _quantity);
        _mintTokens(_phase, _quantity);
    }

    /**
     * @dev Mints tokens during allowlisted distribution phases with ECDSA Signature.
     *
     * NOTE: This method is for internal use, no access control implemented
     */
    function _mintWithSignature(
        uint256 _phase,
        uint256 _quantity,
        uint256 _maxQuantity,
        bytes calldata _signature
    ) internal virtual whenPhaseActive(_phase) {
        _validateRequirements(_phase, _quantity, _maxQuantity, _signature);
        _mintTokens(_phase, _quantity);
    }

    /**
     * @dev Mints tokens during allowlisted distribution phases with ECDSA Signature and a Mint Pass
     *
     * NOTE: This method is for internal use, no access control implemented
     */
    function _mintWithPass(
        uint256 _phase,
        uint256 _passId,
        uint256 _maxQuantity,
        bytes calldata _signature
    ) internal virtual whenPhaseActive(_phase) {
        ITimeCatsLoveEmHateEm mintPassContract = ITimeCatsLoveEmHateEm(
            _passAddress
        );
        require(
            mintPassContract.ownerOf(_passId) == _msgSender(),
            "You do not own this mint pass"
        );
        require(
            !mintPassContract.isUsed(_passId),
            "This mint pass has already been used"
        );
        _validateRequirements(_phase, _maxQuantity, _signature);
        _mintTokens(_msgSender(), 1);
        amountNFTsPerAddressWithPass[_msgSender()] += 1;
        mintPassContract.setAsUsed(_passId);
    }

    /**
     * @dev Airdrops the specified `_quantity` of tokens to a list of addresses.
     *
     * NOTE: This method is for internal use, no access control implemented
     */
    function _distributeTokens(address[] memory _addresses, uint256 _quantity)
        internal
        virtual
    {
        uint256 totalQuantity = _addresses.length * _quantity;
        if (totalQuantity > getAvailableTokenCount()) {
            revert TIME721Phasable__MaxSupplyExceed();
        }

        for (uint256 i; i < _addresses.length; i++) {
            _mintTokens(_addresses[i], _quantity);
        }
    }

    /**
     * @dev Mints `_quantity` number of tokens and transfers it to the message sender.
     * And updates distribution tracking states.
     */
    function _mintTokens(uint256 _phase, uint256 _quantity) private {
        _mintTokens(_msgSender(), _quantity);

        amountNFTsPerAddressAndPhase[_msgSender()][_phase] += _quantity;
        amountNFTsPerAddress[_msgSender()] += _quantity;
    }

    function _mintTokens(address _address, uint256 _quantity) private {
        uint256 startId = totalSupply();

        // safe mint for every NFT
        for (uint256 i; i < _quantity; i++) {
            _safeMint(_address, startId + i);
        }

        _totalSupply += _quantity;
    }

    /**
     * @dev Validate requirements for phase configurations
     */
    function _validateRequirements(uint256 _phase, uint256 _quantity)
        internal
        virtual
        whenPhaseActive(_phase)
    {
        if (_quantity < 1) {
            revert TIME721Phasable__MinQuantityNotMet();
        }
        if (_quantity > getAvailableTokenCount()) {
            revert TIME721Phasable__MaxSupplyExceed();
        }
        if (
            getTotalAllowedQuantity() > 0 &&
            amountNFTsPerAddress[_msgSender()] + _quantity >
            getTotalAllowedQuantity()
        ) {
            revert TIME721Phasable__MaxAllowedQuantityExceed();
        }
        if (
            getAllowedQuantity(_phase) > 0 &&
            amountNFTsPerAddressAndPhase[_msgSender()][_phase] + _quantity >
            getAllowedQuantity(_phase)
        ) {
            revert TIME721Phasable__MaxAllowedQuantityForPhaseExceed();
        }
        if (msg.value < getPrice(_phase) * _quantity) {
            revert TIME721Phasable__NotEnoughFunds();
        }
    }

    /**
     * @dev Validate requirements for allowlisted wallets through ECDSA signature
     */
    function _validateRequirements(
        uint256 _phase,
        uint256 _quantity,
        uint256 _maxQuantity,
        bytes calldata _signature
    ) internal virtual whenPhaseActive(_phase) {
        _validateRequirements(_phase, _quantity);

        if (
            ECDSA.recover(
                _generateMessageHash(_msgSender(), _maxQuantity),
                _signature
            ) != getSignerAddress(_phase)
        ) {
            revert TIME721Phasable__InvalidSignature();
        }
        if (
            amountNFTsPerAddressAndPhase[_msgSender()][_phase] + _quantity >
            _maxQuantity
        ) {
            revert TIME721Phasable__MaxAllowedQuantityForPhaseExceed();
        }
    }

    /**
     * @dev Validate requirements for allowlisted wallets through ECDSA signature with a Pass
     */
    function _validateRequirements(
        uint256 _phase,
        uint256 _maxQuantity,
        bytes calldata _signature
    ) internal virtual whenPhaseActive(_phase) {
        if (getAvailableTokenCount() < 1) {
            revert TIME721Phasable__MaxSupplyExceed();
        }
        if (msg.value < getPrice(_phase)) {
            revert TIME721Phasable__NotEnoughFunds();
        }
        if (
            ECDSA.recover(
                _generateMessageHash(_msgSender(), _maxQuantity),
                _signature
            ) != getSignerAddress(_phase)
        ) {
            revert TIME721Phasable__InvalidSignature();
        }
        if (amountNFTsPerAddressWithPass[_msgSender()] + 1 > _maxQuantity) {
            revert TIME721Phasable__MaxAllowedQuantityForMintPass();
        }
    }

    // Getters
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function getTotalAllowedQuantity() public view virtual returns (uint256) {
        return _totalAllowedQuantity;
    }

    function getAvailableTokenCount() public view virtual returns (uint256) {
        return maxSupply - _totalSupply;
    }

    function getPassAddress() public view virtual returns (address) {
        return _passAddress;
    }

    // Utility Functions
    /**
     * @dev Generate leaf node from wallet address
     */
    function _leaf(address _account) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    /**
     * @dev Generate a message hash for the given parameters
     */
    function _generateMessageHash(address _address, uint256 _maxQauntity)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(abi.encodePacked(_address, _maxQauntity))
                )
            );
    }

    /**
     * @dev Operator Filter Approval Overrides
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}