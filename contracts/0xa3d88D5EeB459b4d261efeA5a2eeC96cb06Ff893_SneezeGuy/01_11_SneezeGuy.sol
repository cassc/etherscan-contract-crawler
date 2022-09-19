//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "erc721a/contracts/ERC721A.sol";

enum ContractStatus {
    disable,
    whitelist,
    open
}

contract SneezeGuy is Ownable, ERC721A, ERC2981, ReentrancyGuard {
    bytes32 public rootHash =
        0xf2a42d60e1e380c384ae039fde86c30a972bed7bc9a51cda14eb4935f3532133;

    ContractStatus public CONTRACT_STATUS = ContractStatus.disable;

    uint96 public immutable ROYALTY_FEE_NUMERATOR = 750;

    uint256 public immutable MAX_FREE_PER_WALLET = 1;
    uint256 public immutable MAX_TX_PER_WALLET = 3;
    uint256 public immutable PRICE = 0.004 ether;
    uint256 public immutable TOTAL_SUPPLY = 5555;
    uint256 public immutable WHITELIST_TOTAL_SUPPLY = 3000;

    string internal baseURI = "";

    modifier isEthAvailable(uint256 quantity) {
        require(
            msg.value >= getSalePrice(msg.sender, quantity),
            "Insufficient funds"
        );
        _;
    }

    modifier isMaxTxReached(uint256 quantity) {
        require(
            _numberMinted(msg.sender) + quantity <= MAX_TX_PER_WALLET,
            "Exceeded tx limit"
        );
        _;
    }

    modifier isSupplyUnavailable(uint256 quantity) {
        require(totalSupply() + quantity <= TOTAL_SUPPLY, "Max supply reached");
        _;
    }

    modifier isUser() {
        require(tx.origin == msg.sender, "Invalid User");
        _;
    }

    constructor() ERC721A("SneezeGuy", "SneezeGuy") {
        _setDefaultRoyalty(owner(), ROYALTY_FEE_NUMERATOR);
    }

    function getTotalSupplyLeft() public view returns (uint256) {
        return TOTAL_SUPPLY - totalSupply();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function isWhitelisted(bytes32[] memory merkleProof)
        public
        view
        returns (bool)
    {
        bytes memory encodedUserAddress = abi.encodePacked(msg.sender);
        bytes32 leaf = keccak256(encodedUserAddress);
        bool isProofValid = MerkleProof.verify(merkleProof, rootHash, leaf);

        return isProofValid;
    }

    function internalMint(address buyerAddress, uint256 quantity)
        external
        onlyOwner
        nonReentrant
        isUser
        isSupplyUnavailable(quantity)
    {
        _mint(buyerAddress, quantity);
    }

    function whitelistMint(uint256 quantity, bytes32[] memory merkleProof)
        public
        payable
        virtual
        nonReentrant
        isUser
        isSupplyUnavailable(quantity)
        isMaxTxReached(quantity)
        isEthAvailable(quantity)
    {
        require(
            CONTRACT_STATUS == ContractStatus.whitelist,
            "Not in whitelist mint stage"
        );
        require(
            totalSupply() + quantity <= WHITELIST_TOTAL_SUPPLY,
            "Max whitelist mint supply reached"
        );
        require(isWhitelisted(merkleProof), "Invalid Proof");

        _mint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity)
        public
        payable
        virtual
        nonReentrant
        isUser
        isSupplyUnavailable(quantity)
        isMaxTxReached(quantity)
        isEthAvailable(quantity)
    {
        require(
            CONTRACT_STATUS == ContractStatus.open,
            "Not in whitelist mint stage"
        );

        _mint(msg.sender, quantity);
    }

    function getTotalMinted(address addr) public view returns (uint256) {
        return _numberMinted(addr);
    }

    function setBaseURI(string memory newURI) external virtual onlyOwner {
        baseURI = newURI;
    }

    function setStatus(ContractStatus status) external onlyOwner {
        CONTRACT_STATUS = status;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    function getSalePrice(address sender, uint256 quantity)
        private
        view
        returns (uint256)
    {
        bool isAlreadyMinted = _numberMinted(sender) > 0;

        return
            isAlreadyMinted
                ? PRICE * (quantity)
                : PRICE * (quantity - MAX_FREE_PER_WALLET);
    }

    function withdraw(uint256 balance) external onlyOwner nonReentrant isUser {
        (bool success, ) = msg.sender.call{value: balance}("");

        require(success, "Transfer failed.");
    }

    function withdrawAll() external onlyOwner nonReentrant isUser {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");

        require(success, "Transfer failed.");
    }
}