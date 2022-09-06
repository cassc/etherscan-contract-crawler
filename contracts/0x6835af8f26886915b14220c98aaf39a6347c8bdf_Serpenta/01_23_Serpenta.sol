// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import { AccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

import { ERC2981Upgradeable } from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";

import { ERC721AUpgradeable, IERC721AUpgradeable } from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";

import { ERC721ABatchUpgradeable } from "./extensions/ERC721ABatchUpgradeable.sol";

import { ISerpenta } from "./interfaces/ISerpenta.sol";

contract Serpenta is
    ISerpenta,
    AccessControlEnumerableUpgradeable,
    ERC721AUpgradeable,
    ERC721ABatchUpgradeable,
    ERC2981Upgradeable
{
    /* ------------------------------------------------------------------------------------------ */
    /*                                          CONSTANTS                                         */
    /* ------------------------------------------------------------------------------------------ */

    /// @inheritdoc ISerpenta
    uint256 public constant MAX_SUPPLY = 5555;

    /// @inheritdoc ISerpenta
    uint256 public constant MAX_WALLET_PRIVATE = 3;

    /// @inheritdoc ISerpenta
    uint256 public constant MAX_WALLET_PUBLIC = 5;

    /// @inheritdoc ISerpenta
    uint256 public constant MAX_TEAM_MINT = 100;

    /// @inheritdoc ISerpenta
    uint256 public constant PRICE = 0.088 ether;

    /* ------------------------------------------------------------------------------------------ */
    /*                                           STORAGE                                          */
    /* ------------------------------------------------------------------------------------------ */

    /// @inheritdoc ISerpenta
    string public baseURI;

    /// @inheritdoc ISerpenta
    bytes32 public merkleRoot;

    /// @inheritdoc ISerpenta
    uint256 public privateTimestamp;

    /// @inheritdoc ISerpenta
    uint256 public publicTimestamp;

    /// @inheritdoc ISerpenta
    bool public isTrainingEnabled;

    /// @notice Returns a token's information.
    /// @dev (id) returns (TokenInfo)
    mapping(uint256 => TokenInfo) public getTokenInfo;

    /// @dev The payment splitter address.
    address internal _paymentSplitter;

    /// @dev Values:
    ///  1 = transfer while in training disabled
    /// !1 = transfer while in training enabled
    uint256 private _training_transfer;

    string private _tokenURIOverride;

    /* ------------------------------------------------------------------------------------------ */
    /*                                         INITIALIZER                                        */
    /* ------------------------------------------------------------------------------------------ */

    function initialize(
        address admin,
        string calldata baseURI_,
        bytes32 _merkleRoot,
        uint256 _privateTimestamp,
        uint256 _publicTimestamp,
        address receiver,
        uint96 percentage,
        address paymentSplitter
    ) external initializer initializerERC721A {
        require(admin != address(0), "Invalid admin");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);

        __ERC721A_init("Serpenta", "SERPENTA");

        baseURI = baseURI_;
        merkleRoot = _merkleRoot;
        privateTimestamp = _privateTimestamp;
        publicTimestamp = _publicTimestamp;

        _setDefaultRoyalty(receiver, percentage);

        require(
            paymentSplitter != address(0) && address(paymentSplitter).code.length != 0,
            "Invalid payment splitter"
        );
        _paymentSplitter = paymentSplitter;

        _training_transfer = 1;
    }

    /* ------------------------------------------------------------------------------------------ */
    /*                                          MODIFIERS                                         */
    /* ------------------------------------------------------------------------------------------ */

    /// @dev Enables transferring tokens while they are in training.
    modifier enableTransferWhileInTraining() {
        _training_transfer = 2;

        _;

        _training_transfer = 1;
    }

    /* ------------------------------------------------------------------------------------------ */
    /*                                      PUBLIC FUNCTIONS                                      */
    /* ------------------------------------------------------------------------------------------ */

    /// @inheritdoc ISerpenta
    function privateMint(uint256 amount, bytes32[] calldata proof) external payable {
        _checkMintValidity(amount, privateTimestamp, true);

        if (!MerkleProof.verifyCalldata(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))))
            revert InvalidProof();

        _mint(msg.sender, amount);
    }

    /// @inheritdoc ISerpenta
    function publicMint(uint256 amount) external payable {
        _checkMintValidity(amount, publicTimestamp, false);

        _mint(msg.sender, amount);
    }

    /// @inheritdoc ISerpenta
    function toggleTraining(uint256[] calldata ids) external {
        if (!isTrainingEnabled) revert TrainingNotEnabled();

        uint256 len = ids.length;
        if (len == 0) revert InvalidIds();

        for (uint256 i; i < len; i++) {
            uint256 id = ids[i];
            TokenInfo storage ptr = getTokenInfo[id];

            address owner = ownerOf(id);
            uint64 lastTimestamp = ptr.lastTimestamp;
            uint64 timestamp = uint64(block.timestamp);

            if (owner != msg.sender && !isApprovedForAll(owner, msg.sender))
                revert TransferCallerNotOwnerNorApproved();

            if (lastTimestamp == 0) {
                // enable

                ptr.lastTimestamp = timestamp;
                emit Train(msg.sender, id, timestamp);
            } else {
                // disable

                // equivalent to: ptr.lastTimestamp = 0;
                delete ptr.lastTimestamp;
                emit Rest(msg.sender, id, timestamp, lastTimestamp);
            }
        }
    }

    /// @inheritdoc ISerpenta
    function isTokenInTraining(uint256 id) public view returns (bool) {
        return getTokenInfo[id].lastTimestamp != 0;
    }

    /// @inheritdoc ISerpenta
    function inTrainingFor(uint256 id) public view returns (uint256) {
        uint256 lastTimestamp = getTokenInfo[id].lastTimestamp;
        return lastTimestamp == 0 ? 0 : block.timestamp - lastTimestamp;
    }

    /// @inheritdoc ISerpenta
    function transferFromWhileInTraining(
        address from,
        address to,
        uint256 id
    ) external enableTransferWhileInTraining {
        if (msg.sender != ownerOf(id)) revert TransferFromIncorrectOwner();
        transferFrom(from, to, id);
    }

    /// @inheritdoc ISerpenta
    function safeTransferFromWhileInTraining(
        address from,
        address to,
        uint256 id
    ) external enableTransferWhileInTraining {
        if (msg.sender != ownerOf(id)) revert TransferFromIncorrectOwner();
        safeTransferFrom(from, to, id, "");
    }

    /// @inheritdoc ISerpenta
    function safeTransferFromWhileInTraining(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) external enableTransferWhileInTraining {
        if (msg.sender != ownerOf(id)) revert TransferFromIncorrectOwner();
        safeTransferFrom(from, to, id, data);
    }

    function tokenURI(uint256 id)
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        if (!_exists(id)) revert URIQueryForNonexistentToken();

        string memory tokenURIOverride = _tokenURIOverride;
        return
            bytes(tokenURIOverride).length == 0
                ? string.concat(baseURI, _toString(id))
                : tokenURIOverride;
    }

    /* ------------------------------------------------------------------------------------------ */
    /*                                           ERC165                                           */
    /* ------------------------------------------------------------------------------------------ */

    /// @inheritdoc IERC721AUpgradeable
    function supportsInterface(bytes4 id)
        public
        view
        override(
            AccessControlEnumerableUpgradeable,
            ERC721AUpgradeable,
            ERC2981Upgradeable,
            IERC721AUpgradeable
        )
        returns (bool)
    {
        return
            ERC721AUpgradeable.supportsInterface(id) ||
            AccessControlEnumerableUpgradeable.supportsInterface(id) ||
            ERC2981Upgradeable.supportsInterface(id);
    }

    /* ------------------------------------------------------------------------------------------ */
    /*                                       ADMIN FUNCTIONS                                      */
    /* ------------------------------------------------------------------------------------------ */

    /// @notice Sets the base URI for token metadata.
    function setBaseURI(string memory baseURI_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = baseURI_;
    }

    /// @notice Sets the override for the token metadata URI.
    function setTokenURIOverride(string memory tokenURIOverride)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _tokenURIOverride = tokenURIOverride;
    }

    /// @notice Sets the merkle root.
    function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        merkleRoot = _merkleRoot;
    }

    /// @notice Sets the private sale start timestamp.
    function setPrivateTimestamp(uint256 _privateTimestamp) external onlyRole(DEFAULT_ADMIN_ROLE) {
        privateTimestamp = _privateTimestamp;
    }

    /// @notice Sets the public sale start timestamp.
    function setPublicTimestamp(uint256 _publicTimestamp) external onlyRole(DEFAULT_ADMIN_ROLE) {
        publicTimestamp = _publicTimestamp;
    }

    /// @notice Sets the payment splitter address.
    function setPaymentSplitter(address paymentSplitter_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _paymentSplitter = paymentSplitter_;
    }

    /// @notice Sets the ERC2981 royalty info.
    function setRoyaltyInfo(address receiver, uint96 percentage)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDefaultRoyalty(receiver, percentage);
    }

    /// @notice Enables or disables training.
    function enableTraining() external onlyRole(DEFAULT_ADMIN_ROLE) {
        isTrainingEnabled = !isTrainingEnabled;
    }

    /// @notice Mints `amounts` to `addrs`.
    function teamMint(address[] calldata addrs, uint256[] calldata amounts)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 addrsLen = addrs.length;
        require(addrsLen != 0 && addrsLen == amounts.length);

        uint256 sum;
        for (uint256 i; i < addrsLen; i++) {
            sum += amounts[i];
        }

        if (totalSupply() + sum > MAX_SUPPLY) revert SoldOut();

        // _getAux(address(this)) == number of team mints
        uint64 tot = _getAux(address(this)) + uint64(sum);
        if (tot > MAX_TEAM_MINT) revert InvalidMintAmount();
        _setAux(address(this), tot);

        for (uint256 i; i < addrsLen; i++) {
            _mint(addrs[i], amounts[i]);
        }
    }

    /// @notice Transfers all of the ether stored in the contract to the payment splitter.
    function withdrawETH() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(this).balance != 0);
        (bool success, ) = _paymentSplitter.call{ value: address(this).balance }("");
        require(success);
    }

    /* ------------------------------------------------------------------------------------------ */
    /*                                     INTERNAL FUNCTIONS                                     */
    /* ------------------------------------------------------------------------------------------ */

    /// @dev Here we use ERC721A.AddressData.aux for storing the number of mints during the private
    /// sale.
    function _checkMintValidity(
        uint256 amount,
        uint256 timestamp,
        bool isPrivateMint
    ) internal {
        unchecked {
            if (totalSupply() + amount > MAX_SUPPLY) revert SoldOut();
            if (timestamp == 0 || block.timestamp < timestamp) revert NotLive();

            uint256 privateMinted = _getAux(msg.sender);
            uint256 minted = amount;
            if (isPrivateMint) {
                minted += privateMinted;
                _setAux(msg.sender, uint64(minted));
            } else {
                minted += _numberMinted(msg.sender);
                if (privateMinted >= minted) minted = 0;
                else minted -= privateMinted;
            }
            if (minted > (isPrivateMint ? MAX_WALLET_PRIVATE : MAX_WALLET_PUBLIC))
                revert InvalidMintAmount();

            if (msg.sender != tx.origin) revert CallerIsContract();
            if (msg.value != PRICE * amount) revert IncorrectEtherValue();
        }
    }

    /// @dev Override ERC721A to start at ID 1.
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @dev Reverts if token is in training and not using special transfer function.
    /// Since we are only checking for transfers and ignoring burns (`from != address(0)`), we can
    /// safely ignore the `quantity` parameter.
    function _beforeTokenTransfers(
        address from,
        address,
        uint256 id,
        uint256
    ) internal view override {
        if (from != address(0))
            if (isTokenInTraining(id))
                if (_training_transfer == 1) revert TransferWhileInTraining();
    }
}