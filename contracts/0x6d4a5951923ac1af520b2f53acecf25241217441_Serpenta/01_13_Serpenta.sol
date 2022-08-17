// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { ERC2981 } from "@openzeppelin/contracts/token/common/ERC2981.sol";

import { ERC721A, IERC721A } from "erc721a/contracts/ERC721A.sol";

import { ERC721ABatch } from "./extensions/ERC721ABatch.sol";

import { ISerpenta } from "./interfaces/ISerpenta.sol";

contract Serpenta is ISerpenta, ERC721A, ERC721ABatch, ERC2981, Ownable {
    /* ------------------------------------------------------------------------------------------ */
    /*                                           STORAGE                                          */
    /* ------------------------------------------------------------------------------------------ */

    /// @notice The frequently accessed contract information.
    ContractInfo public contractInfo;

    /// @inheritdoc ISerpenta
    string public baseURI;

    /// @inheritdoc ISerpenta
    bytes32 public merkleRoot;

    /// @inheritdoc ISerpenta
    address public immutable paymentSplitter;

    /// @dev Overrides the default `baseURI + tokenId` tokenURI.
    string internal _tokenURIOverride;

    /* ------------------------------------------------------------------------------------------ */
    /*                                         CONSTRUCTOR                                        */
    /* ------------------------------------------------------------------------------------------ */

    constructor(
        string memory baseURI_,
        bytes32 _merkleRoot,
        uint32 _privateTimestamp,
        uint32 _publicTimestamp,
        address receiver,
        uint96 percentage,
        address _paymentSplitter
    ) ERC721A("Serpenta", "SERPENTA") {
        contractInfo = ContractInfo({
            maxSupply: 5555,
            maxTeam: 100,
            maxWalletPrivate: 4,
            maxWalletPublic: 5,
            price: 0.077 ether,
            privateTimestamp: _privateTimestamp,
            publicTimestamp: _publicTimestamp
        });

        baseURI = baseURI_;
        merkleRoot = _merkleRoot;

        _setDefaultRoyalty(receiver, percentage);

        require(
            _paymentSplitter != address(0) && address(_paymentSplitter).code.length != 0,
            "Invalid payment splitter"
        );
        paymentSplitter = _paymentSplitter;

        _mint(msg.sender, 1);
    }

    /* ------------------------------------------------------------------------------------------ */
    /*                                      PUBLIC FUNCTIONS                                      */
    /* ------------------------------------------------------------------------------------------ */

    /// @inheritdoc ISerpenta
    function privateMint(uint256 amount, bytes32[] calldata proof) external payable {
        _checkMintValidity(amount, true);

        if (!MerkleProof.verifyCalldata(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))))
            revert InvalidProof();

        _mint(msg.sender, amount);
    }

    /// @inheritdoc ISerpenta
    function publicMint(uint256 amount) external payable {
        _checkMintValidity(amount, false);

        _mint(msg.sender, amount);
    }

    /// @inheritdoc IERC721A
    function tokenURI(uint256 id) public view override(ERC721A, IERC721A) returns (string memory) {
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

    /// @inheritdoc IERC721A
    function supportsInterface(bytes4 id)
        public
        view
        override(ERC721A, ERC2981, IERC721A)
        returns (bool)
    {
        return ERC721A.supportsInterface(id) || ERC2981.supportsInterface(id);
    }

    /* ------------------------------------------------------------------------------------------ */
    /*                                       ADMIN FUNCTIONS                                      */
    /* ------------------------------------------------------------------------------------------ */

    /// @notice Sets the contract info.
    function setContractInfo(
        uint16 maxSupply,
        uint8 maxTeam,
        uint8 maxWalletPrivate,
        uint8 maxWalletPublic,
        uint128 price,
        uint32 privateTimestamp,
        uint32 publicTimestamp
    ) external onlyOwner {
        contractInfo.maxSupply = maxSupply > 5555 ? 5555 : maxSupply;
        contractInfo.maxTeam = maxTeam > 100 ? 100 : maxTeam;
        contractInfo.maxWalletPrivate = maxWalletPrivate;
        contractInfo.maxWalletPublic = maxWalletPublic;
        contractInfo.price = price;
        contractInfo.privateTimestamp = privateTimestamp;
        contractInfo.publicTimestamp = publicTimestamp;
    }

    /// @notice Sets the base URI for token metadata.
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /// @notice Sets the override for the token metadata URI.
    function setTokenURIOverride(string calldata tokenURIOverride) external onlyOwner {
        _tokenURIOverride = tokenURIOverride;
    }

    /// @notice Sets the merkle root.
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /// @notice Sets the ERC2981 royalty info.
    function setRoyaltyInfo(address receiver, uint96 percentage) external onlyOwner {
        _setDefaultRoyalty(receiver, percentage);
    }

    /// @notice Mints `amounts` to `addrs`.
    function teamMint(address[] calldata addrs, uint256[] calldata amounts) external onlyOwner {
        ContractInfo memory _contractInfo = contractInfo;

        uint256 addrsLen = addrs.length;
        require(addrsLen != 0 && addrsLen == amounts.length);

        uint256 sum;
        for (uint256 i; i < addrsLen; i++) {
            sum += amounts[i];
        }

        if (totalSupply() + sum > _contractInfo.maxSupply) revert SoldOut();

        // _getAux(address(this)) == number of team mints
        uint64 tot = _getAux(address(this)) + uint64(sum);
        if (tot > _contractInfo.maxTeam) revert InvalidMintAmount();
        _setAux(address(this), tot);

        for (uint256 i; i < addrsLen; i++) {
            _mint(addrs[i], amounts[i]);
        }
    }

    /// @notice Transfers all of the ether stored in the contract to the payment splitter.
    function withdrawETH() external onlyOwner {
        require(address(this).balance != 0);
        (bool success, ) = paymentSplitter.call{ value: address(this).balance }("");
        require(success);
    }

    /* ------------------------------------------------------------------------------------------ */
    /*                                     INTERNAL FUNCTIONS                                     */
    /* ------------------------------------------------------------------------------------------ */

    /// @dev Here we use ERC721A.AddressData.aux for storing the number of mints during the private
    /// sale.
    function _checkMintValidity(uint256 amount, bool isPrivateMint) internal {
        unchecked {
            ContractInfo memory _contractInfo = contractInfo;

            if (totalSupply() + amount > _contractInfo.maxSupply - _contractInfo.maxTeam)
                revert SoldOut();

            uint256 privateMinted = _getAux(msg.sender);
            uint256 minted = amount;
            uint256 timestamp;
            if (isPrivateMint) {
                timestamp = _contractInfo.privateTimestamp;
                minted += privateMinted;
                _setAux(msg.sender, uint64(minted));
            } else {
                timestamp = _contractInfo.publicTimestamp;
                minted += _numberMinted(msg.sender) - privateMinted;
            }
            if (timestamp == 0 || block.timestamp < timestamp) revert NotLive();
            if (
                minted >
                (isPrivateMint ? _contractInfo.maxWalletPrivate : _contractInfo.maxWalletPublic)
            ) revert InvalidMintAmount();

            if (msg.sender != tx.origin) revert CallerIsContract();
            if (msg.value != _contractInfo.price * amount) revert IncorrectEtherValue();
        }
    }

    /// @dev Override ERC721A to start at ID 1.
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}