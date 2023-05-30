//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

import {VRFBaseMainnet as VRFBase} from './VRFBase.sol';
import './ERC721A.sol';

error PublicSaleNotActive();
error ExceedsLimit();
error SignatureExceedsLimit();
error IncorrectValue();
error InvalidSignature();
error ContractCallNotAllowed();

contract BaoSociety is ERC721A, Ownable, VRFBase {
    using ECDSA for bytes32;
    using Strings for uint256;

    event SaleStateUpdate();

    bool public publicSaleActive;

    string public baseURI;
    string private unrevealedURI = 'ipfs://QmRuQYxmdzqfVfy8ZhZNTvXsmbN9yLnBFPDeczFvWUS2HU/';

    uint256 constant MAX_SUPPLY = 3888;
    uint256 constant MAX_PER_WALLET = 20;

    uint256 constant price = 0.0888 ether;
    uint256 constant PURCHASE_LIMIT = 10;

    uint256 constant whitelistPrice = 0.0777 ether;
    uint256 constant WHITELIST_PURCHASE_LIMIT = 10;

    address public signerAddress = 0x63B14a4D433d9ed70176cF7ed1f322790F0d5F89;
    address public treasuryAddress = 0x69D8004d527d72eFe1a4d5eECFf4A7f38f5b2B69;

    constructor() ERC721A('BaoSociety', 'BAOSOC', MAX_SUPPLY, 1, MAX_PER_WALLET) {}

    /* ------------- External ------------- */

    function mint(uint256 amount) external payable noContract {
        if (!publicSaleActive) revert PublicSaleNotActive();
        if (PURCHASE_LIMIT < amount) revert ExceedsLimit();
        if (msg.value != price * amount) revert IncorrectValue();

        _mint(msg.sender, amount);
    }

    function whitelistMint(
        uint256 amount,
        uint256 limit,
        bytes calldata signature
    ) external payable noContract {
        if (!validSignature(signature, limit)) revert InvalidSignature();
        if (WHITELIST_PURCHASE_LIMIT < limit) revert SignatureExceedsLimit();
        if (msg.value != whitelistPrice * amount) revert IncorrectValue();

        uint256 numMinted = numMinted(msg.sender);
        if (numMinted + amount > limit) revert ExceedsLimit();

        _mint(msg.sender, amount);
    }

    /* ------------- Private ------------- */

    function validSignature(bytes memory signature, uint256 limit) private view returns (bool) {
        bytes32 msgHash = keccak256(abi.encode(address(this), msg.sender, limit));
        return msgHash.toEthSignedMessageHash().recover(signature) == signerAddress;
    }

    /* ------------- Owner ------------- */

    function setPublicSaleActive(bool active) external onlyOwner {
        publicSaleActive = active;
        emit SaleStateUpdate();
    }

    function giveAway(address[] calldata users, uint256[] calldata amounts) external onlyOwner {
        for (uint256 i; i < users.length; i++) _mint(users[i], amounts[i]);
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setUnrevealedURI(string calldata _uri) external onlyOwner {
        unrevealedURI = _uri;
    }

    function setSignerAddress(address _address) external onlyOwner {
        signerAddress = _address;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(treasuryAddress).transfer(balance);
    }

    function recoverToken(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(treasuryAddress, balance);
    }

    /* ------------- Modifier ------------- */

    modifier noContract() {
        if (tx.origin != msg.sender) revert ContractCallNotAllowed();
        _;
    }

    /* ------------- ERC721 ------------- */

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert QueryForNonexistentToken();

        if (bytes(baseURI).length == 0 || !randomSeedSet())
            return string.concat(unrevealedURI, tokenId.toString(), '.json');

        uint256 metadataId = _getShiftedId(tokenId, startingIndex(), MAX_SUPPLY);
        return string.concat(baseURI, metadataId.toString(), '.json');
    }
}