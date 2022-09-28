// SPDX-License-Identifier: MIT

import { ERC721A } from "./ERC721A.sol";
import { Ownable } from "./Ownable.sol";
import { MerkleProof } from "./MerkleProof.sol";

pragma solidity >=0.8.17 <0.9.0;

error CallerIsContract();
error CannotMintFromContract();
error InsufficientFunds();
error InvalidMintAmount();
error InvalidMintPriceChange();
error InvalidMerkleProof();
error InvalidSalesPhaseChange();
error InvalidSupplyChangeAmount();
error InvalidWithdrawalAmount();
error MintAmountExceedsSupply();
error MintAmountExceedsUserAllowance();
error WithdrawalFailed();
error WrongSalesPhase();

contract Shikigai is ERC721A, Ownable {

    event MintedCounters(
        uint48 indexed supplyCounters,
        uint48 indexed userConfig
    );

    event SalesPhaseChanged(
        uint8 indexed newPhase
    );

    uint48 public constant SECTION_BITMASK = 15;
    uint48 public constant DISTRICT_BITMASK = 4095;

    uint48 public ichiroSupply = 0;
    uint48 public jiroSupply = 0;
    uint48 public saburoSupply = 0;
    uint48 public maxDistrictSupply = 2730;
    uint8 public maxAllowancePublic = 3;
    uint8 public currSalesPhase = 8;

    uint public publicPrice = 0.12 ether;
    uint public allowlistPrice = 0.088 ether;

    string public metadataURI;
    bytes32 private _merkleRoot;
    address private _signer;

    constructor() ERC721A("Shikigai", "SKG") {}

    //modifiers
    modifier CallerIsUser() {
        if (tx.origin != msg.sender) revert CallerIsContract();
        _;
    }

    //mint functions
    function publicMint(bytes32 _r, bytes32 _s, uint8 _v, uint48 _inputConfig) 
        external
        payable
        CallerIsUser
    {
        if (currSalesPhase > 1) revert WrongSalesPhase();

        uint48 ichiroAmount = _inputConfig & DISTRICT_BITMASK;
        uint48 jiroAmount = (_inputConfig >> 12) & DISTRICT_BITMASK;
        uint48 saburoAmount = (_inputConfig >> 24) & DISTRICT_BITMASK;

        bytes32 hash = keccak256(abi.encodePacked(msg.sender, ichiroAmount, jiroAmount, saburoAmount));
        bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address signer = ecrecover(digest, _v, _r, _s);
        if (signer != _signer) revert CannotMintFromContract();

        if (ichiroSupply + ichiroAmount > maxDistrictSupply
            || jiroSupply + jiroAmount > maxDistrictSupply
            || saburoSupply + saburoAmount > maxDistrictSupply) revert MintAmountExceedsSupply();

        uint48 total = ichiroAmount + jiroAmount + saburoAmount;
        if (total == 0) revert InvalidMintAmount();

        uint64 userAux = _getAux(msg.sender); 
        uint64 publicMinted = userAux & SECTION_BITMASK;

        if (total + publicMinted > maxAllowancePublic) revert MintAmountExceedsUserAllowance();
        if (msg.value < total * publicPrice) revert InsufficientFunds();

        _mint(msg.sender, total);

        uint48 supplyCounters = ichiroSupply + (jiroSupply << 16) + (saburoSupply << 32);
        emit MintedCounters(supplyCounters, _inputConfig);
        
        uint64 updatedAux = userAux + total;
        _setAux(msg.sender, updatedAux);

        ichiroSupply += ichiroAmount;
        jiroSupply += jiroAmount;
        saburoSupply += saburoAmount;
    }

    function nonPublicMint(bytes32[] calldata _proof, uint48 _inputConfig)
        external
        payable
        CallerIsUser
    {

        uint48 amountAllowed = (_inputConfig >> 36) & SECTION_BITMASK;
        uint48 userSalesPhase = _inputConfig >> 40;
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amountAllowed, userSalesPhase));
        if (!MerkleProof.verifyCalldata(_proof, _merkleRoot, leaf)) revert InvalidMerkleProof();
        if (userSalesPhase != currSalesPhase) revert WrongSalesPhase();

        uint48 ichiroAmount = _inputConfig & DISTRICT_BITMASK;
        uint48 jiroAmount = (_inputConfig >> 12) & DISTRICT_BITMASK;
        uint48 saburoAmount = (_inputConfig >> 24) & DISTRICT_BITMASK;

        if (ichiroSupply + ichiroAmount > maxDistrictSupply
            || jiroSupply + jiroAmount > maxDistrictSupply
            || saburoSupply + saburoAmount > maxDistrictSupply) revert MintAmountExceedsSupply();
        
        uint48 total = ichiroAmount + jiroAmount + saburoAmount;
        if (total == 0) revert InvalidMintAmount();

        uint64 userAux = _getAux(msg.sender);
        uint64 allowlistMinted = (userAux >> 4) & SECTION_BITMASK;

        if (allowlistMinted + total > amountAllowed) revert MintAmountExceedsUserAllowance();
        if (msg.value < total * allowlistPrice) revert InsufficientFunds();

        _mint(msg.sender, total);

        uint48 supplyCounters = ichiroSupply + (jiroSupply << 16) + (saburoSupply << 32);
        emit MintedCounters(supplyCounters, _inputConfig);
        
        uint64 updatedAux = userAux + (total << 4);
        _setAux(msg.sender, updatedAux);

        ichiroSupply += ichiroAmount;
        jiroSupply += jiroAmount;
        saburoSupply += saburoAmount;
    }

    // onlyOwner functions
    function setSigner(address newSigner_)
        external
        onlyOwner
    {
        _signer = newSigner_;
    }

    function setMerkleRoot(bytes32 newRoot_) 
        external 
        onlyOwner 
    {
        _merkleRoot = newRoot_;
    }

    function setURI(string calldata _uri) 
        external 
        onlyOwner 
    {
        metadataURI = _uri;
    }

    function demoteSalesPhase(uint8 amount)
        external 
        onlyOwner 
    {
        uint8 resultingPhase = currSalesPhase >> amount;
        if (resultingPhase == 0) revert InvalidSalesPhaseChange();
        currSalesPhase = resultingPhase;
        emit SalesPhaseChanged(currSalesPhase);
    }

    function promoteSalesPhase(uint8 amount)
        external 
        onlyOwner 
    {
        uint8 resultingPhase = currSalesPhase << amount;
        if (resultingPhase == 0) revert InvalidSalesPhaseChange();
        currSalesPhase = resultingPhase;
        emit SalesPhaseChanged(currSalesPhase);
    }

    function setPublicMintPrice(uint _mintPrice) 
        external 
        onlyOwner 
    {
        if (_mintPrice < 0.01 ether) revert InvalidMintPriceChange();
        publicPrice = _mintPrice;
    }

    function setWlMintPrice(uint _mintPrice) 
        external 
        onlyOwner 
    {
        if (_mintPrice < 0.01 ether) revert InvalidMintPriceChange();
        allowlistPrice = _mintPrice;
    }

    function setMaxAllowancePublic(uint8 _amount)
        external
        onlyOwner
    {
        maxAllowancePublic = _amount;
    }

    function setMaxDistrictSupply(uint48 _newSupply)
        external
        onlyOwner
    {
        if (_newSupply < ichiroSupply
            || _newSupply < jiroSupply
            || _newSupply < saburoSupply) revert InvalidSupplyChangeAmount();

        maxDistrictSupply = _newSupply;   
    }

    function devMint(uint48 _inputConfig, address _to) 
        external 
        onlyOwner 
    {
        uint48 ichiroAmount = _inputConfig & DISTRICT_BITMASK;
        uint48 jiroAmount = (_inputConfig >> 12) & DISTRICT_BITMASK;
        uint48 saburoAmount = (_inputConfig >> 24) & DISTRICT_BITMASK;
 
        if (ichiroSupply + ichiroAmount > maxDistrictSupply
            || jiroSupply + jiroAmount > maxDistrictSupply
            || saburoSupply + saburoAmount > maxDistrictSupply) revert MintAmountExceedsSupply();

        uint48 total = ichiroAmount + jiroAmount + saburoAmount;

        _mint(_to, total);

        uint48 supplyCounters = ichiroSupply + (jiroSupply << 16) + (saburoSupply << 32);
        emit MintedCounters(supplyCounters, _inputConfig);
        ichiroSupply += ichiroAmount;
        jiroSupply += jiroAmount;
        saburoSupply += saburoAmount;
    }

    function withdraw(uint256 _amount, address _to) 
        external 
        onlyOwner 
    {
        uint256 contractBalance = address(this).balance;
        if (contractBalance < _amount) revert InvalidWithdrawalAmount();

        (bool success,) = payable(_to).call{value: _amount}("");
        if (!success) revert WithdrawalFailed();
    }

    function burn(uint256 _tokenId) 
        external
        onlyOwner 
    {
        _burn(_tokenId, true);
    }

    // public view functions
    function numberMinted(address owner) 
        public 
        view 
        returns (uint256) 
    {
        return _numberMinted(owner);
    }

    function numberMintedPublic(address owner) 
        public 
        view 
        returns (uint64) 
    {
        return _getAux(owner) & SECTION_BITMASK;
    }

    function numberMintedNonPublic(address owner) 
        public 
        view 
        returns (uint64) 
    {
        return (_getAux(owner) >> 4) & SECTION_BITMASK;
    }

    // internal functions
    function _baseURI() 
        internal 
        view 
        virtual 
        override 
        returns (string memory) 
    {
        return metadataURI;
    }
}