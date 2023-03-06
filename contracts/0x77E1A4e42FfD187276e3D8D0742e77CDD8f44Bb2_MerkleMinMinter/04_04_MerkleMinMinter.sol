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

import "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import "./INM721A.sol";
import "./DropData2.sol";

contract MerkleMinMinter {

    mapping(address => DropData) internal _dropData;
    mapping(address => mapping(address => uint256)) public addressPublicMintCount;
    mapping(address => mapping(address => uint256)) public addressWLMintCount;
    mapping(address => mapping(address => uint256)) public referralCount;

    event MintbossMint(address _dropAddress, address _referrer, string _eid, uint256 _quantity);
    event MintPhaseChanged(address _dropAddress, address _from, uint256 newPhase);
    event MintCreated(address _dropAddress);

    constructor() {}

    function createMint(
        address _dropAddress, 
        DropData memory _initialDropData
    ) external {
        require(_dropData[_dropAddress].merkleroot == bytes32(0), "Mint already exists");

        DropData storage data = _dropData[_dropAddress];
        data.merkleroot = _initialDropData.merkleroot;
        data.mintbossAllowed = _initialDropData.mintbossAllowed;
        data.mintbossMintPrice = _initialDropData.mintbossMintPrice;
        data.mintbossAllowListMintPrice = _initialDropData.mintbossAllowListMintPrice;
        data.mintbossReferralFee = _initialDropData.mintbossReferralFee;
        data.mintPhase = _initialDropData.mintPhase;
        data.publicMintPrice = _initialDropData.publicMintPrice;
        data.minPublicMintCount = _initialDropData.minPublicMintCount;
        data.minWLMintCount = _initialDropData.minWLMintCount;
        data.maxPublicMintCount = _initialDropData.maxPublicMintCount;
        data.maxWLMintCount = _initialDropData.maxWLMintCount;
        data.allowlistMintPrice = _initialDropData.allowlistMintPrice;

        emit MintCreated(_dropAddress);
    }

    // SETTERS

    function setDropData(address _dropAddress, DropData memory _newDropData) external onlyAdmin(_dropAddress) {
        DropData storage data = _dropData[_dropAddress];
        data.merkleroot = _newDropData.merkleroot;
        data.mintbossAllowed = _newDropData.mintbossAllowed;
        data.mintbossMintPrice = _newDropData.mintbossMintPrice;
        data.mintbossAllowListMintPrice = _newDropData.mintbossAllowListMintPrice;
        data.mintbossReferralFee = _newDropData.mintbossReferralFee;
        data.mintPhase = _newDropData.mintPhase;
        data.publicMintPrice = _newDropData.publicMintPrice;
        data.minPublicMintCount = _newDropData.minPublicMintCount;
        data.minWLMintCount = _newDropData.minWLMintCount;
        data.maxPublicMintCount = _newDropData.maxPublicMintCount;
        data.maxWLMintCount = _newDropData.maxWLMintCount;
        data.allowlistMintPrice = _newDropData.allowlistMintPrice;
    }

    // Allows the contract owner to update the merkle root (allowlist)
    function setMerkleRoot(address _dropAddress, bytes32 _merkleroot) external onlyAdmin(_dropAddress) {
        _dropData[_dropAddress].merkleroot = _merkleroot;
    }

    // An owner-only function which toggles the public sale on/off
    function setMintPhase(address _dropAddress, uint256 _newPhase) external onlyAdmin(_dropAddress) {
        _dropData[_dropAddress].mintPhase = _newPhase;
        emit MintPhaseChanged(_dropAddress, msg.sender, _newPhase);
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
        uint256 _minPublicMintCount, // The minimum number of tokens any one address can mint
        uint256 _minWLMintCount,
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
            data.minPublicMintCount,
            data.minWLMintCount,
            data.maxPublicMintCount,
            data.maxWLMintCount,
            data.allowlistMintPrice
        );
    }

    // MINT FUNCTIONS

    // Minting function for addresses on the allowlist only
    function mintAllowList(address _dropAddress, address _recipient, uint256 _quantity, address payable _referrer, string memory _eid, bytes32[] calldata _proof) external payable {
        DropData storage data = _dropData[_dropAddress];
        uint256 mintCount = addressWLMintCount[_dropAddress][_recipient];
        require(_verify(_leaf(_recipient), _proof, data.merkleroot), "Wallet not on allowlist");
        require(_quantity >= data.minWLMintCount, "Mint quantity too low");
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
        
        INM721A(payable(_dropAddress)).mint(_recipient, _quantity);
        _payOut(_dropAddress, _referrer, _eid, _quantity, msg.value);
    }

    function mintPublic(address _dropAddress, address _recipient, uint256 _quantity, address payable _referrer, string memory _eid) external payable {
        DropData storage data = _dropData[_dropAddress];
        uint256 mintCount = addressPublicMintCount[_dropAddress][_recipient];
        require(data.mintPhase==2, "Public sale inactive");
        require(_quantity >= data.minPublicMintCount, "Mint quantity too low");
        require(mintCount + _quantity <= data.maxPublicMintCount, "Exceeded max mint");
        if (_referrer != address(0)) {
            require(_referrer != _recipient, "Referrer cannot be sender");
            require(data.mintbossAllowed, "Mintboss dissallowed");
            if(_quantity * data.mintbossMintPrice != msg.value) revert InvalidEthAmount();
        } else {
            if(_quantity * data.publicMintPrice != msg.value) revert InvalidEthAmount();
        }

        addressPublicMintCount[_dropAddress][_recipient] = mintCount + _quantity;
			
        INM721A(payable(_dropAddress)).mint(_recipient, _quantity);
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
    function _leaf(address _account) internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(_account));
    }

    // Verifies a leaf is part of the tree
    function _verify(bytes32 leaf, bytes32[] memory _proof, bytes32 _root) pure
    internal returns (bool)
    {
        return MerkleProof.verify(_proof, _root, leaf);
    }

    // MODIFIERS

    modifier onlyAdmin(address _dropAddress) virtual {
        require(INM721A(payable(_dropAddress)).hasAnyRole(msg.sender, INM721A(payable(_dropAddress)).ADMIN_ROLE()), "not admin");
        _;
    }

    modifier onlyMinter(address _dropAddress) virtual {
        require(INM721A(payable(_dropAddress)).hasAnyRole(msg.sender, INM721A(payable(_dropAddress)).MINTER_ROLE()), "not minter");
        _;
    }

    // ERRORS

    error InvalidEthAmount();
}