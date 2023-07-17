// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

// ███████  █████  ██      ████████ ██    ██     ██████  ███████ ████████      ██████ ██████  ███████ ██     ██
// ██      ██   ██ ██         ██     ██  ██      ██   ██ ██         ██        ██      ██   ██ ██      ██     ██
// ███████ ███████ ██         ██      ████       ██████  █████      ██        ██      ██████  █████   ██  █  ██
//      ██ ██   ██ ██         ██       ██        ██      ██         ██        ██      ██   ██ ██      ██ ███ ██
// ███████ ██   ██ ███████    ██       ██        ██      ███████    ██         ██████ ██   ██ ███████  ███ ███
// By the Salty Pirate Crew: 0x7a4b1a8bb6e40cbce837fb72603c8a4a20d0b3e1
contract SaltyPetCrew is DefaultOperatorFilterer, ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    uint256 public constant MAX_SUPPLY = 1000;

    Counters.Counter private _totalSupply;
    address private _signer;
    string public baseURI;

    enum ContractState {
        PAUSED,
        UNLOCK
    }
    ContractState public currentState = ContractState.PAUSED;

    constructor(
        address __signer,
        string memory _URI
    ) ERC721("SaltyPetCrew", "SPC") {
        _signer = __signer;
        baseURI = _URI;
    }

    function setBaseURI(string memory _URI) public onlyOwner {
        baseURI = _URI;
    }

    // Sets a new contract state: PAUSED, UNLOCK
    function setContractState(ContractState _newState) external onlyOwner {
        currentState = _newState;
    }

    // Returns the total supply minted
    function totalSupply() public view returns (uint256) {
        return _totalSupply.current();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // Verifies that the sender is whitelisted
    function _verifySignature(
        bytes calldata signature,
        uint256 tokenId,
        address caller
    ) internal view returns (bool) {
        return
            keccak256(abi.encodePacked(tokenId, caller))
                .toEthSignedMessageHash()
                .recover(signature) == _signer;
    }

    function unlockPet(
        bytes calldata signature,
        uint256 _tokenId
    ) public nonReentrant {
        require(
            _tokenId >= 0 && _tokenId < MAX_SUPPLY,
            "Outside of unlock range"
        );
        require(
            _verifySignature(signature, _tokenId, msg.sender),
            "Signature is invalid"
        );
        require(
            currentState == ContractState.UNLOCK,
            "Contract cannot unlock Pet"
        );
        require(!_exists(_tokenId), "Token cannot exist");
        _safeMint(msg.sender, _tokenId);
        _totalSupply.increment();
    }

    // Withdraw funds
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }

    // OpenSea creator fee overrides
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}