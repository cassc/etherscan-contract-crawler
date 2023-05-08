//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/ERC721A/contracts/extensions/ERC721AQueryable.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {OperatorFilterer} from "lib/closedsea/src/OperatorFilterer.sol";
import "lib/openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import {IERC2981, ERC2981} from "lib/openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

error Paused();
error SoldOut();
error SaleNotStarted();
error MintingTooMany();
error NotWhitelisted();
error Underpriced();
error MintedOut();
error MaxMints();
error ArraysDontMatch();
error ZeroSigner();
error InvalidSignature();
error StartTimeInPast();

contract DA is ERC721AQueryable, Ownable, OperatorFilterer, ERC2981 {
    using ECDSA for bytes32;

    uint256 public highTierPrice = 2 ether;
    uint256 private maxMintableHighTierSupply = 25;
    uint256 private maxHighTierSupplyRNG = 75;
    uint256 public highTierMintableSupplyCounter;
    uint256 private highTierRNGCounter;
    uint256 public normalStartPrice = 0.1 ether;
    uint256 step = 0.01 ether;
    uint256 stepInterval = 100; //100 seconds
    uint256 maxSupply = 3000;
    uint256 private maxMintsPerHighTier = 1;
    uint256 private maxMintsPerTxRegular = 2;
    bool public operatorFilteringEnabled;
    string public baseURI;
    string public baseExtension = ".json";
    bool public revealed;
    bool highTierMintOn = true;
    bool normalMintOn = true;

    uint256 private startTime;
    address private signer;

    mapping(uint256 => bool) private isHighTier;
    mapping(address => uint256) private numMintedHighTier;

    constructor() ERC721A("DA", "da") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        // Set royalty receiver to the contract creator,
        // at 5% (default denominator is 10000).
        _setDefaultRoyalty(msg.sender, 500);
        startTime = block.timestamp;
    }

    function getDutchPrice() public view returns (uint256) {
        uint256 timeSinceStart = block.timestamp - startTime;
        uint256 steps = timeSinceStart / stepInterval;
        uint256 price = normalStartPrice - (step * steps);
        return price;
    }

    function mintHighTier() external payable {
        uint256 nextTokenId = _nextTokenId();
        if (numMintedHighTier[msg.sender] + 1 > maxMintsPerHighTier) revert MaxMints();
        if (nextTokenId + 1 > maxSupply) revert MintedOut();
        if (highTierMintableSupplyCounter + 1 > maxMintableHighTierSupply) revert SoldOut();
        if (msg.value < highTierPrice) revert Underpriced();
        if (!highTierMintOn) revert Paused();
        ++highTierMintableSupplyCounter;
        ++numMintedHighTier[msg.sender];
        isHighTier[nextTokenId] = true;
        _mint(msg.sender, 1);
    }

    function mintNormal(uint256 amount, uint256 numHighTier, bool isSenderMintingHighTier, bytes memory signature)
        external
        payable
    {
        uint256 nextTokenId = _nextTokenId();
        uint256 _highTierRNGCounter = highTierRNGCounter;
        if (amount > maxMintsPerTxRegular) revert MintingTooMany();
        if (nextTokenId + amount > maxSupply) revert MintedOut();
        if (!normalMintOn) revert Paused();
        if (msg.value < getDutchPrice() * amount) revert Underpriced();
        if (isSenderMintingHighTier) {
            bytes32 hash = keccak256(abi.encodePacked(msg.sender, amount, numHighTier, isSenderMintingHighTier));
            address hashSigner = hash.toEthSignedMessageHash().recover(signature);
            if (hashSigner == address(0)) revert ZeroSigner();
            if (hashSigner != signer) revert InvalidSignature();

            for (uint256 i = 0; i < numHighTier; i++) {
                if (_highTierRNGCounter + 1 > maxHighTierSupplyRNG) revert SoldOut();
                _highTierRNGCounter += 1;
                isHighTier[nextTokenId + i] = true;
            }
            //TOOD: DO we increment the mapping of high tier mints?
            highTierRNGCounter += numHighTier;
        }
        _mint(msg.sender, amount);
    }

    function getTierStatusesForTokenIDS(uint256[] calldata tokenIds) external view returns (bool[] memory) {
        bool[] memory statuses = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            statuses[i] = isHighTier[tokenIds[i]];
        }
        return statuses;
    }

    function _startTokenId() internal pure override(ERC721A) returns (uint256) {
        return 0;
    }
    //SETTERS

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        if (!_exists(tokenId)) revert OwnerQueryForNonexistentToken();
        address ownerOfToken = ownerOf(tokenId);
        if (spender == ownerOfToken) return true;
        if (getApproved(tokenId) == spender) return true;
        if (isApprovedForAll(ownerOfToken, spender)) return true;
        return false;
    }

    function burn(uint256 tokenId) public virtual {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert ApprovalCallerNotOwnerNorApproved();
        _burn(tokenId);
    }

    function setHighTierPrice(uint256 _highTierPrice) external onlyOwner {
        highTierPrice = _highTierPrice;
    }

    function setMaxMintableHighTierSupply(uint256 _maxMintableHighTierSupply) external onlyOwner {
        maxMintableHighTierSupply = _maxMintableHighTierSupply;
    }

    function setMaxHighTierSupplyRNG(uint256 _maxHighTierSupplyRNG) external onlyOwner {
        maxHighTierSupplyRNG = _maxHighTierSupplyRNG;
    }

    function setNormalStartPrice(uint256 _normalStartPrice) external onlyOwner {
        normalStartPrice = _normalStartPrice;
    }

    function setStep(uint256 _step) external onlyOwner {
        step = _step;
    }

    function setStepInterval(uint256 _stepInterval) external onlyOwner {
        stepInterval = _stepInterval;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxMintsPerHighTier(uint256 _maxMintsPerHighTier) external onlyOwner {
        maxMintsPerHighTier = _maxMintsPerHighTier;
    }

    function setMaxMintsPerTxRegular(uint256 _maxMintsPerTxRegular) external onlyOwner {
        maxMintsPerTxRegular = _maxMintsPerTxRegular;
    }

    function setHighTierMintOn(bool _highTierMintOn) external onlyOwner {
        highTierMintOn = _highTierMintOn;
    }

    function setNormalMintOn(bool _normalMintOn) external onlyOwner {
        normalMintOn = _normalMintOn;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        if (_startTime < block.timestamp) revert StartTimeInPast();
        startTime = _startTime;
    }

    function tokenURI(uint256 tokenId) public view override(IERC721A, ERC721A) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, _toString(tokenId), baseExtension));
    }
    //-----------CLOSEDSEA----------------

    function setApprovalForAll(address operator, bool approved)
        public
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC721A, ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    function getDashboardParams() external view returns (DashboardParams memory) {
        return DashboardParams({
            maxSupply: maxSupply,
            highTierPrice: highTierPrice,
            normalStartPrice: normalStartPrice,
            step: step,
            stepInterval: stepInterval,
            maxMintableHighTierSupply: maxMintableHighTierSupply,
            maxHighTierSupplyRNG: maxHighTierSupplyRNG,
            highTierMintableSupplyCounter: highTierMintableSupplyCounter,
            highTierRNGCounter: highTierRNGCounter,
            maxMintsPerHighTier: maxMintsPerHighTier,
            maxMintsPerTxRegular: maxMintsPerTxRegular,
            highTierMintOn: highTierMintOn,
            normalMintOn: normalMintOn,
            totalSupply: totalSupply(),
            balance: address(this).balance,
            totalBurned: _totalBurned()
        });
    }
}

struct DashboardParams {
    uint256 maxSupply;
    uint256 highTierPrice;
    uint256 normalStartPrice;
    uint256 step;
    uint256 stepInterval;
    uint256 maxMintableHighTierSupply;
    uint256 maxHighTierSupplyRNG;
    uint256 highTierMintableSupplyCounter;
    uint256 highTierRNGCounter;
    uint256 maxMintsPerHighTier;
    uint256 maxMintsPerTxRegular;
    bool highTierMintOn;
    bool normalMintOn;
    uint256 totalSupply;
    uint256 balance;
    uint256 totalBurned;
}