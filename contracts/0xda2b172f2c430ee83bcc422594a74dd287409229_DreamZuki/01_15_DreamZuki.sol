// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "ERC721A/extensions/ERC721AQueryable.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/utils/cryptography/ECDSA.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

error InvalidSignature();
error InvalidState(uint256 state);
error InvalidMintQuantity(uint256 quantity);
error TotalSupplyExceeded(uint256 totalMinted, uint256 maxSupply);
error InvalidOrigin();
error InsufficientFunds(uint256 msgValue, uint256 requiredValue);
error SaleClosed();

contract DreamZuki is DefaultOperatorFilterer, ERC721AQueryable, Ownable {
    address public constant TEAM_WALLET = 0xE7096d6474fff8BbCCa542ba63c32Ad1dacAdcc6;

    struct Config {
        uint32 maxSupply;
        uint32 fcfsSupply;
        uint32 guaranteedSupply;
        uint32 teamSupply;
        uint32 maxFcfsPerWallet;
        uint32 maxGuaranteedPerWallet;
        uint32 maxPublicPerWallet;
        uint256 mintPrice;
        uint256 guaranteedPrice;
    }

    enum State {
        CLOSED,
        FCFS,
        GUARANTEED,
        PUBLIC
    }

    mapping(State => uint256) private _stateMinted;
    mapping(address => uint16) private _packedMinted;
    address private _signer;
    bool public revealed;

    Config public cfg;
    State public status;
    string public baseUri = "https://d24c9gdwfym0sk.cloudfront.net/Pre_Reveal_GIF.gif";

    constructor(address signer_, Config memory cfg_) ERC721A("DreamZuki", "DZK") {
        _signer = signer_;
        cfg = cfg_;

        uint256 i;
        unchecked {
            do {
                _mint(TEAM_WALLET, 10);
                i++;
            } while(i < 15);
        }
    }

    function mint(uint256 quantity, bytes calldata signature) external payable {
        if(tx.origin != msg.sender) revert InvalidOrigin();

        _validateMint(quantity, signature);
        _addMintedByState(msg.sender, uint8(quantity));
        _stateMinted[status] += quantity;
        _mint(msg.sender, quantity);
    }

    function getCurrentStateMinted(address user) external view returns(uint256) {
        return _mintedByState(user);
    } 

    function setState(uint256 state) external onlyOwner {
        status = State(state);
    }

    function setSigner(address signer) external onlyOwner {
        _signer = signer;
    }

    function setBaseURI(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function setRevealed(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = TEAM_WALLET.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721A, IERC721A) payable onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from, 
        address to, 
        uint256 tokenId
    ) public override(ERC721A, IERC721A) payable onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from, 
        address to, 
        uint256 tokenId) 
    public override(ERC721A, IERC721A) payable onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from, 
        address to, 
        uint256 tokenId, 
        bytes memory data
    ) public override(ERC721A, IERC721A) payable onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) _revert(URIQueryForNonexistentToken.selector);

        if(revealed) {
            return string(abi.encodePacked(baseUri, _toString(tokenId)));
        } else {
            return baseUri;
        }
    }

    function _validateMint(uint256 quantity, bytes calldata signature) internal view {
        if (status == State.CLOSED) revert SaleClosed();

        uint256 stateMinted = _stateMinted[status];
        uint256 numberMinted = _mintedByState(msg.sender);

        if (status == State.FCFS) {
            if (stateMinted + quantity > cfg.fcfsSupply) 
                revert TotalSupplyExceeded(stateMinted, cfg.fcfsSupply);
            if (numberMinted + quantity > cfg.maxFcfsPerWallet) 
                revert InvalidMintQuantity(quantity);
            if (msg.value < cfg.mintPrice * quantity) 
                revert InsufficientFunds(msg.value, cfg.mintPrice * quantity);
            if (!_verify(signature, quantity))
                revert InvalidSignature();
            return;
        }

        if (status == State.GUARANTEED) {
            if (stateMinted + quantity > cfg.guaranteedSupply) 
                revert TotalSupplyExceeded(stateMinted, cfg.guaranteedSupply);
            if (numberMinted + quantity > cfg.maxGuaranteedPerWallet) 
                revert InvalidMintQuantity(quantity);
            if (msg.value < cfg.guaranteedPrice * quantity) 
                revert InsufficientFunds(msg.value, cfg.guaranteedPrice * quantity);
            if (!_verify(signature, quantity))
                revert InvalidSignature();
            return;
        }

        if (status == State.PUBLIC) {
            if (_totalMinted() + quantity > cfg.maxSupply)
                revert TotalSupplyExceeded(_totalMinted(), cfg.maxSupply);
            if (numberMinted + quantity > cfg.maxPublicPerWallet) 
                revert InvalidMintQuantity(quantity);
            if (msg.value < cfg.mintPrice * quantity) 
                revert InsufficientFunds(msg.value, cfg.mintPrice * quantity);
            return;
        }

        revert InvalidState(uint256(status));
    }

    // 0xf = 1111 4 bits
    function _mintedByState(address user) internal view returns(uint16) {
        return (_packedMinted[user] >> 4 * uint16(status)) & 0xf;
    }

    function _addMintedByState(address user, uint16 amount) internal {
        uint16 value = _mintedByState(user);

        amount += value;

        // shift 1111 to left by state * 4 bits and invert then and to set 4 bits to 0000
        value &= ~(uint16(0xf) << 4 * uint16(status));

        // shift amount to left by state * 4 bits and or to set 4 bits to amount
        value |= (amount & 0xf) << 4 * uint16(status);

        // Set updated value
        _packedMinted[user] = value;
    }

    function _verify(bytes calldata signature, uint256 quantity) internal view returns (bool) {
        return ECDSA.recover(keccak256(abi.encodePacked(msg.sender, quantity, uint256(status))), signature) == _signer;
    }
}