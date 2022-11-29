// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@      @@@@@@@@@@@@   @@@@@@@@*   @@@@@@@@                   @@@                      @@@@    &@@@@@@@@@@@@    @@@@@@
// @@@@@       @@@@@@@@@@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@    @@@@@@@@@@    @@@@@@@
// @@@@@   #@    @@@@@@@@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@.   @@@@@@@    @@@@@@@@@
// @@@@@   #@@    @@@@@@@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@    @@@@    @@@@@@@@@@
// @@@@@   #@@@@    @@@@@@   @@@@@@@@*   @@@@@@@@                 @@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@   &    @@@@@@@@@@@@
// @@@@@   #@@@@@    @@@@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@     *@@@@@@@@@@@@@
// @@@@@   #@@@@@@@    @@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@
// @@@@@   #@@@@@@@@@   &@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@
// @@@@@   #@@@@@@@@@@       @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@
// @@@@@   #@@@@@@@@@@@@     @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@                                                                                                                   @@@
// @@@  @@@@@@@@         [email protected]@@@@@@@    @@@@@@          @@@@@       @@@@@@@@@@@@@@       @@@@@*        &@@@@@@@@@@@@       @@@
// @@@  @@@@@@@@@        @@@@@@@@@    @@@@@@          @@@@@     @@@@@@@@@@@@@@@@@@     @@@@@*     /@@@@@@@@@@@@@@@@@@    @@@
// @@@  @@@@@*@@@,      @@@@ @@@@@    @@@@@@          @@@@@    @@@@@          @@@@@    @@@@@*    @@@@@@,        @@@@@@   @@@
// @@@  @@@@@ @@@@      @@@@ @@@@@    @@@@@@          @@@@@    @@@@@                   @@@@@*   @@@@@@           @@@@@@  @@@
// @@@  @@@@@  @@@@    @@@@  @@@@@    @@@@@@          @@@@@    %@@@@@@@@@@@            @@@@@*   @@@@@                    @@@
// @@@  @@@@@  @@@@    @@@@  @@@@@    @@@@@@          @@@@@       @@@@@@@@@@@@@@@@     @@@@@*  &@@@@@                    @@@
// @@@  @@@@@   @@@@  @@@@   @@@@@    @@@@@@          @@@@@               @@@@@@@@@@   @@@@@*   @@@@@                    @@@
// @@@  @@@@@   @@@@ ,@@@    @@@@@    @@@@@@          @@@@@   @@@@@@           @@@@@   @@@@@*   @@@@@@           @@@@@@  @@@
// @@@  @@@@@    @@@@@@@@    @@@@@    @@@@@@@        @@@@@@    @@@@@#         ,@@@@@   @@@@@*    @@@@@@@        @@@@@@   @@@
// @@@  @@@@@    &@@@@@@     @@@@@     /@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@    @@@@@*      @@@@@@@@@@@@@@@@@     @@@
// @@@  @@@@@     @@@@@@     @@@@@        @@@@@@@@@@@@@            @@@@@@@@@@@@@       @@@@@*         @@@@@@@@@@@*       @@@
// @@@                                                                                                                   @@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/finance/PaymentSplitter.sol";
import "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import "./NM721A.sol";
import "./DropData.sol";

contract MerkleMinter {

    mapping(address => DropData) internal _dropData;
    mapping(address => mapping(address => uint256)) public addressPublicMintCount;
    mapping(address => mapping(address => uint256)) public addressWLMintCount;
    mapping(address => mapping(address => bool)) public freeMintClaimed;
    mapping(address => mapping(address => uint256)) public referralCount;

    event MintbossMint(address _dropAddress, address _referrer, string _eid, uint256 _quantity);
    event MintPhaseChanged(address _dropAddress, address _from, uint256 newPhase);
    event MintCreated(address _dropAddress);

    constructor() {}

    function createMint(
        address _dropAddress, 
        DropData memory _initialDropData
    ) external {
        DropData storage data = _dropData[_dropAddress];
        data.merkleroot = _initialDropData.merkleroot;
        data.mintbossAllowed = _initialDropData.mintbossAllowed;
        data.mintbossMintPrice = _initialDropData.mintbossMintPrice;
        data.mintbossAllowListMintPrice = _initialDropData.mintbossAllowListMintPrice;
        data.mintbossReferralFee = _initialDropData.mintbossReferralFee;
        data.mintPhase = _initialDropData.mintPhase;
        data.publicMintPrice = _initialDropData.publicMintPrice;
        data.maxPublicMintCount = _initialDropData.maxPublicMintCount;
        data.maxWLMintCount = _initialDropData.maxWLMintCount;
        data.allowlistMintPrice = _initialDropData.allowlistMintPrice;

        emit MintCreated(_dropAddress);
    }

    // SETTERS

    function toggleMintbossAllowed(address _dropAddress) external onlyAdmin(_dropAddress) {
        _dropData[_dropAddress].mintbossAllowed = !_dropData[_dropAddress].mintbossAllowed;
    }

    function setMintbossMintPrice(address _dropAddress, uint256 _newMintbossMintPrice) external onlyAdmin(_dropAddress)  {
        _dropData[_dropAddress].mintbossMintPrice = _newMintbossMintPrice;
    }

    function setMintbossReferralFee(address _dropAddress, uint256 _newMintbossReferralFee) external onlyAdmin(_dropAddress)  {
        _dropData[_dropAddress].mintbossReferralFee = _newMintbossReferralFee;
    }

    // Allows the contract owner to update the merkle root (allowlist)
    function setMerkleRoot(address _dropAddress, bytes32 _merkleroot) external onlyAdmin(_dropAddress) {
        _dropData[_dropAddress].merkleroot = _merkleroot;
    }

    // Allows the contract owner to set the wl cap
    function setWLCap(address _dropAddress, uint256 _newCap) external onlyAdmin(_dropAddress) {
        _dropData[_dropAddress].maxWLMintCount = _newCap;
    }

    // An owner-only function which toggles the public sale on/off
    function setMintPhase(address _dropAddress, uint256 _newPhase) external onlyAdmin(_dropAddress) {
        _dropData[_dropAddress].mintPhase = _newPhase;
        emit MintPhaseChanged(_dropAddress, msg.sender, _newPhase);
    }

    function setPublicMintPrice(address _dropAddress, uint256 _newMintPrice, uint256 _newMintCap) external onlyAdmin(_dropAddress) {
        _dropData[_dropAddress].publicMintPrice = _newMintPrice;
        _dropData[_dropAddress].maxPublicMintCount = _newMintCap;
    }

    // GETTERS

    function getDropData(address _dropAddress) external view returns (
        bytes32 _merkleroot, 
        bool _mintbossAllowed,
        uint256 _mintbossMintPrice,
        uint256 _mintbossAllowListMintPrice,
        uint256 _mintbossReferralFee, // The amount sent to the referrer on each mint
        uint256 _mintPhase, // 0 = closed, 1 = WL sale, 2 = public sale
        uint256 _publicMintPrice, // Public mint price
        uint256 _maxPublicMintCount, // The maximum number of tokens any one address can mint
        uint256 _maxWLMintCount,
        uint256 _allowlistMintPrice
    )  {
        DropData storage data = _dropData[_dropAddress];
        return (
            data.merkleroot,
            data.mintbossAllowed,
            data.mintbossMintPrice,
            data.mintbossAllowListMintPrice,
            data.mintbossReferralFee,
            data.mintPhase,
            data.publicMintPrice,
            data.maxPublicMintCount,
            data.maxWLMintCount,
            data.allowlistMintPrice
        );
    }

    // MINT FUNCTIONS

    // Minting function addresses on the OG list only
    function mintFreeMintList(address _dropAddress, bytes32[] calldata _proof) external {
        DropData storage data = _dropData[_dropAddress];
        require(!freeMintClaimed[_dropAddress][msg.sender], "Free mint already claimed");
        require(_verify(_leaf(msg.sender, true), _proof, data.merkleroot), "Wallet not on free mint list");
        require(data.mintPhase==1, "Sale is not active");

        freeMintClaimed[_dropAddress][msg.sender] = true;

        NM721A(payable(_dropAddress)).mint(msg.sender, 1);
    }

    // Minting function for addresses on the allowlist only
    function mintAllowList(address _dropAddress, address _recipient, uint256 _quantity, address payable _referrer, string memory _eid, bytes32[] calldata _proof) external payable {
        DropData storage data = _dropData[_dropAddress];
        uint256 mintCount = addressWLMintCount[_dropAddress][_recipient];
        require(_verify(_leaf(_recipient, false), _proof, data.merkleroot), "Wallet not on allowlist");
        require(mintCount + _quantity <= data.maxWLMintCount, "Exceeded whitelist allowance");
        require(data.mintPhase==1, "Allowlist sale is not active");
        if (_referrer != address(0)) {
            require(_referrer != _recipient, "Referrer cannot be sender");
            require(data.mintbossAllowed, "Mintboss dissallowed");
            require(_quantity * data.mintbossAllowListMintPrice == msg.value, "Incorrect price");
        } else {
            if(_quantity * data.allowlistMintPrice != msg.value) revert InvalidEthAmount();
        }

        addressWLMintCount[_dropAddress][_recipient] = mintCount + _quantity;
        
        NM721A(payable(_dropAddress)).mint(_recipient, _quantity);
        _payOut(_dropAddress, _referrer, _eid, _quantity, msg.value);
    }

    function mintPublic(address _dropAddress, address _recipient, uint256 _quantity, address payable _referrer, string memory _eid) external payable {
        DropData storage data = _dropData[_dropAddress];
        uint256 mintCount = addressPublicMintCount[_dropAddress][_recipient];
        require(data.mintPhase==2, "Public sale inactive");
        require(mintCount + _quantity <= data.maxPublicMintCount, "Exceeded max mint");
        if (_referrer != address(0)) {
            require(_referrer != _recipient, "Referrer cannot be sender");
            require(data.mintbossAllowed, "Mintboss dissallowed");
            if(_quantity * data.mintbossMintPrice != msg.value) revert InvalidEthAmount();
        } else {
            if(_quantity * data.publicMintPrice != msg.value) revert InvalidEthAmount();
        }

        addressPublicMintCount[_dropAddress][_recipient] = mintCount + _quantity;
			
        NM721A(payable(_dropAddress)).mint(_recipient, _quantity);
        _payOut(_dropAddress, _referrer, _eid, _quantity, msg.value);
    }

    function _payOut(address _dropAddress, address payable _referrer, string memory _eid, uint256 _quantity, uint256 _value) internal {
        DropData storage data = _dropData[_dropAddress];
        uint256 remainingAmount = _value;
        if (_referrer != address(0)) {
            uint256 refererralFee = data.mintbossReferralFee * _quantity;
            referralCount[_dropAddress][_referrer] += _quantity;
            remainingAmount -= refererralFee;
            emit MintbossMint(_dropAddress, _referrer, _eid, _quantity);

            payable(_referrer).transfer(refererralFee);
        }
        payable(_dropAddress).transfer(remainingAmount);
    }

    // MERKLE FUNCTIONS

    // Used to construct a merkle tree leaf
    function _leaf(address _account, bool _isFreeMintList)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(_account, _isFreeMintList));
    }

    // Verifies a leaf is part of the tree
    function _verify(bytes32 leaf, bytes32[] memory _proof, bytes32 _root) pure
    internal returns (bool)
    {
        return MerkleProof.verify(_proof, _root, leaf);
    }

    // MODIFIERS

    modifier onlyAdmin(address _dropAddress) virtual {
        require(NM721A(payable(_dropAddress)).hasRole(NM721A(payable(_dropAddress)).ADMIN_ROLE(), msg.sender), "not admin");
        _;
    }

    modifier onlyMinter(address _dropAddress) virtual {
        require(NM721A(payable(_dropAddress)).hasRole(NM721A(payable(_dropAddress)).MINTER_ROLE(), msg.sender), "not minter");
        _;
    }

    // ERRORS

    error InvalidEthAmount();
}