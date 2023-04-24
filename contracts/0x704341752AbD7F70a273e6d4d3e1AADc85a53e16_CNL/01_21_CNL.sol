// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "./opensea/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

library Errors {
    error CallerIsAnotherContract();
    error NonexistentToken();
    error PresaleIsActive();
    error MintAmountOver();
    error PresaleIsNotActive();
    error InvalidMerkleProof();
    error OverMintLimit();
    error MintAmountCannotBeZero();
    error MaxSupplyOver();
    error NotEnoughFunds();
    error CallerIsNotTeam();
    error NowPaused();
    error FailedWithdraw();
    error BurnMintIsNotActive();
    error BurnMintCallerNotOwner();
    error BurnCallerNotOwner();
    error BurnMintMaxSupply();
    error NotBurnable();
    error NotAllowedPlatform();
    error NotAllowedExternalAddress();
}

library Events {
  /// @notice Emmited on setRoyaltyInfo()
  /// @param royaltyReceiver Royalty fee collector
  /// @param feePercent Royalty fee numerator; denominator is 10,000. So 500 represents 5%
  event RoyaltyInfoChanged(
    address indexed royaltyReceiver,
    uint96 feePercent
  );
}

contract CNL is 
    ERC721AUpgradeable,
    OwnableUpgradeable, 
    ERC2981Upgradeable, 
    ReentrancyGuardUpgradeable, 
    DefaultOperatorFiltererUpgradeable
{
    using StringsUpgradeable for uint256;

    string private baseURI;
    string internal revealUri;
    uint256 public preCost;
    uint256 public publicCost;
    uint256 public burnMintCost;
    uint256 public burnMintableNumber;
    bool internal isRevealed;
    bool public isPause;
    bool public isBurnable;
    bool public useAllowedPlatform;
    uint64 public salePhase;
    uint64 private mintedCountPhase;
    uint64 public maxSupply;
    uint64 public maxBurnSupply;
    bytes32 private merkleRoot1;
    bytes32 private merkleRoot2;
    mapping(uint64 => mapping(address => uint256)) public mintedLists;
    mapping(address => bool) private teamMember;
    mapping(address => bool) public allowedPlatform;
    mapping(address => bool) private allowedExternalAddress;
    
    function initialize() public initializerERC721A initializer {
        __Ownable_init();
        __ERC2981_init();
        __ReentrancyGuard_init();
        __DefaultOperatorFilterer_init();
        __ERC721A_init("Crypto Ninja LOVE", "CNL");

        setMember(_msgSender(), true);

        baseURI = "";
        revealUri = "https://storage.googleapis.com/cnl/cnl_hidden/hidden.json";

        preCost = 0.001 ether;
        publicCost = 0.002 ether;
        burnMintCost = 0.001 ether;

        isRevealed = false;
        isPause = false;
        isBurnable = false;

        salePhase = 0;

        mintedCountPhase = 1;
        maxSupply = 6969;
        maxBurnSupply = 7969;
        burnMintableNumber = 6969;

        useAllowedPlatform = true;
        setAllowedPlatform(0x00000000006c3852cbEf3e08E8dF289169EdE581, true);   //0x1E0049783F008A0085193E00003D00cd54003c71

        setRoyaltyInfo(0x0862a051fF2FA78bdCB2a071d0235f3a29C89398, 1000);
    }

    modifier onlyTeam() {
        if(!teamMember[_msgSender()]) revert Errors.CallerIsNotTeam();
        _;
    }
    event SetMember(address member, bool enable);
    function setMember(address member ,bool enable) public onlyOwner {
        teamMember[member] = enable;
        emit SetMember(member, enable);
    }

    modifier callerIsUser() {
        if(tx.origin != msg.sender) revert Errors.CallerIsAnotherContract();
        _;
    }

    // internal override
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if(!_exists(_tokenId)) revert Errors.NonexistentToken();
        if(isRevealed == false) {
            return revealUri;
        }
        return string(abi.encodePacked(baseURI, StringsUpgradeable.toString(_tokenId), ".json"));
    }
    // start from 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    modifier onlyAllowedPlatform(address operator) {
        if(useAllowedPlatform && !allowedPlatform[operator]) revert Errors.NotAllowedPlatform();
        _;
    }
    event SetAllowedPlatform(address operator, bool enable);
    function setAllowedPlatform(address operator ,bool enable) public onlyTeam {
        allowedPlatform[operator] = enable;
        emit SetAllowedPlatform(operator, enable);
    }
    function setUseAllowedPlatform(bool enable) public onlyTeam {
        useAllowedPlatform = enable;
    }

    modifier onlyAllowedExternalAddress(address addr) {
        if(!allowedExternalAddress[addr]) revert Errors.NotAllowedExternalAddress();
        _;
    }
    function setAllowedExternalAddress(address addr ,bool enable) public onlyTeam {
        allowedExternalAddress[addr] = enable;
    }

    // public mint
    function publicMint(uint256 _mintAmount) external payable callerIsUser nonReentrant {
        if(!(salePhase == 5)) revert Errors.PresaleIsActive();
        mintCheck(_mintAmount, publicCost * _mintAmount);
        if(_mintAmount > 5) revert Errors.MintAmountOver();
        _safeMint(_msgSender(), _mintAmount);
    }

    // pre Mint
    function preMint(
        uint256 _mintAmount,
        uint256 _maxCount,
        bytes32[] calldata _proof
    ) external payable callerIsUser nonReentrant {
        if(!(salePhase >= 1 && salePhase <= 2)) revert Errors.PresaleIsNotActive();
        mintCheck(_mintAmount,  getCurrentCost() * _mintAmount);
        bytes32 _leaf = keccak256(abi.encodePacked(_msgSender(), _maxCount));
        bytes32 _merkleRoot;
        if(salePhase == 1){
            _merkleRoot = merkleRoot1;
        }else if(salePhase == 2){
            _merkleRoot = merkleRoot2;
        }
        if(!MerkleProofUpgradeable.verifyCalldata(_proof, _merkleRoot, _leaf)) revert Errors.InvalidMerkleProof();     
        if(mintedLists[mintedCountPhase][_msgSender()] + _mintAmount > _maxCount) revert Errors.OverMintLimit();
        mintedLists[mintedCountPhase][_msgSender()] += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mintCheck(
        uint256 _mintAmount,
        uint256 _cost
    ) private view {
        if(isPause) revert Errors.NowPaused();
        if(_mintAmount < 1) revert Errors.MintAmountCannotBeZero();
        if(totalSupply() + _mintAmount > maxSupply) revert Errors.MaxSupplyOver();
        if(msg.value < _cost) revert Errors.NotEnoughFunds();
    }

    function ownerMint(address _address, uint256 count) external onlyTeam {
       _safeMint(_address, count);
    }

    function setSalePhase(uint64 _phase) external onlyTeam {
        if(_phase == 2 || _phase == 10){
            setMintedCountPhase();
        }
        salePhase = _phase;
    }

    function setPreCost(uint256 _preCost) external onlyTeam {
        preCost = _preCost;
    }

    function setPublicCost(uint256 _publicCost) external onlyTeam {
        publicCost = _publicCost;
    }

    function setBurnMintCost(uint256 _burnMintCost) external onlyTeam {
        burnMintCost = _burnMintCost;
    }

    function getCurrentCost() public view returns (uint256) {
        if (salePhase <= 2) {
            return preCost;
        }else if(salePhase >= 10 && salePhase <= 11){
            return burnMintCost;
        } else {
            return publicCost;
        }
    }

    function setBaseURI(string memory _newBaseURI) external onlyTeam {
        baseURI = _newBaseURI;
    }

    function setPause(bool _bool) external onlyTeam {
        isPause = _bool;
    }

    function setBurnable(bool _bool) external onlyTeam {
        isBurnable = _bool;
    }

    function withdraw() external onlyTeam {
        uint256 sendAmount = address(this).balance;
        bool success;
        (success, ) = payable(0xBF87C1012753839484F2d5cb8AC12A573Fd7F964).call{value: (sendAmount * 500/1000)}("");
        if(!success) revert Errors.FailedWithdraw();
        (success, ) = payable(0x9A2c7b7B5E3cc2C2232341211f3F9F9D53b51D2E).call{value: (sendAmount * 200/1000)}("");
        if(!success) revert Errors.FailedWithdraw();
        (success, ) = payable(0xe7e94A49FbdE459D933e01296dE46d9109E83B45).call{value: (sendAmount * 100/1000)}("");
        if(!success) revert Errors.FailedWithdraw();
        (success, ) = payable(0x8d8e29a36C2BCAec3bE2E38dB9E5EdC4d5D12FD8).call{value: (sendAmount * 200/1000)}("");
        if(!success) revert Errors.FailedWithdraw();
    }

    function setMerkleRoot(bytes32 _merkleRoot1, bytes32 _merkleRoot2) external onlyTeam {
        merkleRoot1 = _merkleRoot1;
        merkleRoot2 = _merkleRoot2;
    }

    function setMintedCountPhase() public onlyTeam {
        mintedCountPhase = mintedCountPhase + 1;
    }

    function getMintedCount(address _address) external view returns (uint256) {
        return mintedLists[mintedCountPhase][_address];
    }

    function getNextTokenId() external view returns (uint256) {
        return _nextTokenId();
    }

    function setMaxSupply(uint64 _maxSupply) external onlyTeam {
        maxSupply = _maxSupply;
    }

    function setMaxBurnSupply(uint64 _maxBurnSupply) external onlyTeam {
        maxBurnSupply = _maxBurnSupply;
    }

    function setBurnMintableNumber(uint64 _burnMintableNumber) external onlyTeam {
        burnMintableNumber = _burnMintableNumber;
    }

    function setHiddenBaseURI(string memory _uri) external virtual onlyTeam {
        revealUri = _uri;
    }

    function setReveal(bool _bool) external virtual onlyTeam {
        isRevealed = _bool;
    }

    function burn(uint256[] memory _burnTokenIds) external virtual {
        if(!isBurnable) revert Errors.NotBurnable();
        for (uint256 i = 0; i < _burnTokenIds.length; i++) {
            uint256 tokenId = _burnTokenIds[i];
            if (_msgSender() != ownerOf(tokenId)) revert Errors.BurnCallerNotOwner();
            _burn(tokenId);
        }
    }

    function getStatus() external view returns(uint256 _cost, uint64 _phase, bool _isPause, uint256 _totalSupply) {
        _cost = getCurrentCost();
        _phase = salePhase;
        _isPause = isPause;
        _totalSupply = totalSupply();
        return(_cost, _phase, _isPause, _totalSupply);
    }

    function burnMint(
        uint256[] memory _burnTokenIds,
        uint256 _maxCount,
        bytes32[] calldata _proof
    ) external payable nonReentrant {
        if(!(salePhase >= 10 && salePhase <= 11)) revert Errors.BurnMintIsNotActive();
        if (_msgSender() != owner()) {
            require(msg.value >= burnMintCost * _burnTokenIds.length);
        }
        if((_nextTokenId() + _burnTokenIds.length) -1 > maxBurnSupply) revert Errors.BurnMintMaxSupply();

        for (uint256 i = 0; i < _burnTokenIds.length; i++) {
            uint256 tokenId = _burnTokenIds[i];
            if (_msgSender() != ownerOf(tokenId)) revert Errors.BurnMintCallerNotOwner();
            if (tokenId > burnMintableNumber) revert Errors.NotBurnable();
            _burn(tokenId);
        }
        if(salePhase == 10){
            bytes32 _leaf = keccak256(abi.encodePacked(_msgSender(), _maxCount));
            bytes32 _merkleRoot = merkleRoot1;
            if(!MerkleProofUpgradeable.verifyCalldata(_proof, _merkleRoot, _leaf)) revert Errors.InvalidMerkleProof();
            if(mintedLists[mintedCountPhase][_msgSender()] + _burnTokenIds.length > _maxCount) revert Errors.OverMintLimit();
            mintedLists[mintedCountPhase][_msgSender()] += _burnTokenIds.length;
        }
        _safeMint(_msgSender(), _burnTokenIds.length);
    }

    function externalMint(address _address , uint256 _amount ) external payable nonReentrant onlyAllowedExternalAddress(msg.sender) {
        if((_nextTokenId() + _amount) -1 > maxBurnSupply) revert Errors.BurnMintMaxSupply();
        _safeMint( _address, _amount );
    }
    function externalBurn(uint256[] memory _burnTokenIds) external nonReentrant onlyAllowedExternalAddress(msg.sender) {
        if(!isBurnable) revert Errors.NotBurnable();
        for (uint256 i = 0; i < _burnTokenIds.length; i++) {
            uint256 tokenId = _burnTokenIds[i];
            if (tx.origin != ownerOf(tokenId)) revert Errors.BurnCallerNotOwner();
            _burn(tokenId);
        }
    }


    /// @notice Function for changing royalty information
    /// @dev Can only be called by project owner
    /// @dev Owner can prevent any sale by setting the address to any address that can't receive native network token
    /// @param _royaltyReceiver Royalty fee collector
    /// @param _feePercent Royalty fee numerator; denominator is 10,000. So 500 represents 5%
    function setRoyaltyInfo(address _royaltyReceiver, uint96 _feePercent)
        public
        onlyTeam
    {
        _setDefaultRoyalty(_royaltyReceiver, _feePercent);
        emit Events.RoyaltyInfoChanged(_royaltyReceiver, _feePercent);
    }

    /// @notice Returns true if this contract implements the interface defined by `interfaceId`
    /// @dev Needs to be overridden cause two base contracts implement it
    /// @param _interfaceId InterfaceId to consider. Comes from type(InterfaceContract).interfaceId
    /// @return bool True if the considered interface is supported
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            ERC721AUpgradeable.supportsInterface(_interfaceId) ||
            ERC2981Upgradeable.supportsInterface(_interfaceId);
    }


    // ========================
    // Opensea library
    // ========================
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) onlyAllowedPlatform(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) onlyAllowedPlatform(operator) {
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