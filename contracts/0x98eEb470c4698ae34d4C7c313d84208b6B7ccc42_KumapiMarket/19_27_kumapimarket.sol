// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import './kumapi.sol';
import './boxel.sol';

contract KumapiMarket is AccessControl {
    address public kumapiNftAddress;
    address public sasayonNftAddress;
    address public sellerAddress;
    address payable public withdrawAddress;
    bytes32 public kumapiMerkleRoot;
    bytes32 public regularMerkleRoot;
    bytes32 public giveawayMerkleRoot;
    bool public saleEnabled;
    bool public publicSaleEnable;
    bool public isPaused;
    uint256 public kumapiSalesPrice = 0.005 ether;
    uint256 public regularSalesPrice = 0.01 ether;
    uint256 public publicSalesPrice = 0.01 ether;

    mapping(address => uint256) public kumapiBoughtAmount;
    mapping(address => uint256) public regularBoughtAmount;
    mapping(address => uint256) public giveawayFinishedAmount;

    constructor(
        address _kumapiNftAddress,
        address _sasayonNftAddress,
        address payable _withdrawAddress,
        bytes32 _kumapiMerkleRoot,
        bytes32 _regularMerkleRoot,
        bytes32 _giveawayMerkleRoot
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        kumapiNftAddress = _kumapiNftAddress;
        sasayonNftAddress = _sasayonNftAddress;
        withdrawAddress = payable(_withdrawAddress);
        kumapiMerkleRoot = _kumapiMerkleRoot;
        regularMerkleRoot = _regularMerkleRoot;
        giveawayMerkleRoot = _giveawayMerkleRoot;
        sellerAddress = msg.sender;
    }

    function setPaused() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(isPaused == false);
        isPaused = true;
    }

    function setSaleEnable() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(saleEnabled == false);
        saleEnabled = true;
    }

    function startPublicSale() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(isPaused == false);
        require(publicSaleEnable == false);
        publicSaleEnable = true;
    }

    function changeKumapiMerkleRoot(bytes32 _merkleRoot) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(isPaused == false);
        kumapiMerkleRoot = _merkleRoot;
    }

    function changeRegularMerkleRoot(bytes32 _merkleRoot) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(isPaused == false);
        regularMerkleRoot = _merkleRoot;
    }

    function changeGiveawayMerkleRoot(bytes32 _merkleRoot) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(isPaused == false);
        giveawayMerkleRoot = _merkleRoot;
    }

    function changeSellerAddress(address _sellerAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(isPaused == false);
        sellerAddress = _sellerAddress;
    }

    function checkKumapiRemainAmount(
        bytes32[] memory _proof,
        uint256 _amount,
        address _holderAddress
    ) public view returns(uint256) {
        uint256 _kumapiEnableAmount;
        uint256 _mintedAmount = kumapiBoughtAmount[_holderAddress];
        if (_proof.length >= 1) {
            bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_holderAddress, _amount))));

            if (MerkleProof.verify(_proof, kumapiMerkleRoot, leaf) == true) {
                _kumapiEnableAmount += _amount;
            }
        }
        uint256 _kumapiRemainAmount = _kumapiEnableAmount - _mintedAmount;
        return _kumapiRemainAmount;
    }

    function checkRegularRemainAmount(
        bytes32[] memory _proof,
        uint256 _amount,
        address _holderAddress
    ) public view returns(uint256) {
        uint256 _regularEnableAmount;
        uint256 _mintedAmount = regularBoughtAmount[_holderAddress];

        if (_proof.length >= 1) {
            bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_holderAddress, _amount))));

            if (MerkleProof.verify(_proof, regularMerkleRoot, leaf) == true) {
                _regularEnableAmount += _amount;
            }
        }
        uint256 _regularRemainAmount = _regularEnableAmount - _mintedAmount;
        return _regularRemainAmount;
    }

    function checkGiveawayRemainAmount(
        bytes32[] memory _proof,
        uint256 _amount,
        address _holderAddress
    ) public view returns(uint256) {
        uint256 _giveawayEnableAmount;
        uint256 _mintedAmount = giveawayFinishedAmount[_holderAddress];

        if (_proof.length >= 1) {
            bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_holderAddress, _amount))));

            if (MerkleProof.verify(_proof, giveawayMerkleRoot, leaf) == true) {
                _giveawayEnableAmount += _amount;
            }
        }
        uint256 _regularRemainAmount = _giveawayEnableAmount - _mintedAmount;
        return _regularRemainAmount;
    }

    function kumapiSale(
        bytes32[] memory _proof,
        uint256 _amount,
        uint256[] memory _requireIds
    ) public payable {
        require(saleEnabled == true);
        require(isPaused == false);
        uint256 _remainAmount = checkKumapiRemainAmount(_proof, _amount, msg.sender);
        uint256 _salesAmount = _requireIds.length;
        require(_salesAmount <= _remainAmount, "not have mint amount");
        require(msg.value == _salesAmount * kumapiSalesPrice, "not enough value");

        for (uint i = 0; i < _salesAmount; i++) {
            uint256 _requireId = _requireIds[i];

            require(zoomanXkumapi(kumapiNftAddress).ownerOf(_requireId) == sellerAddress, "already sold");
            zoomanXkumapi(kumapiNftAddress).safeTransferFrom(sellerAddress, msg.sender, _requireId);

        }

        kumapiBoughtAmount[msg.sender] += _salesAmount;
    }

    function regularSale(
        bytes32[] memory _proof,
        uint256 _amount,
        uint256[] memory _requireIds
    ) public payable {
        require(saleEnabled == true);
        require(isPaused == false);
        uint256 _remainAmount = checkRegularRemainAmount(_proof, _amount, msg.sender);
        uint256 _salesAmount = _requireIds.length;
        require(_salesAmount <= _remainAmount);
        require(msg.value == _salesAmount * regularSalesPrice);

        for (uint i = 0; i < _salesAmount; i++) {
            uint256 _requireId = _requireIds[i];

            require(zoomanXkumapi(kumapiNftAddress).ownerOf(_requireId) == sellerAddress);
            zoomanXkumapi(kumapiNftAddress).safeTransferFrom(sellerAddress, msg.sender, _requireId);
            
            uint256 _boxelId = _requireId % 13;
            zoomanXsasayon(sasayonNftAddress).mint(_boxelId, msg.sender);
        }

        regularBoughtAmount[msg.sender] += _salesAmount;
    }

    function publicSale(uint256[] memory _requireIds) public payable {
        require(saleEnabled == true);
        require(isPaused == false);
        require(publicSaleEnable == true, "public sale is not enabled");
        uint256 _salesAmount = _requireIds.length;
        require(msg.value == _salesAmount * publicSalesPrice);
        for (uint i = 0; i < _salesAmount; i++) {
            uint256 _requireId = _requireIds[i];

            require(zoomanXkumapi(kumapiNftAddress).ownerOf(_requireId) == sellerAddress);
            zoomanXkumapi(kumapiNftAddress).safeTransferFrom(sellerAddress, msg.sender, _requireId);

        }
    }

    function giveaway(
        bytes32[] memory _proof,
        uint256 _amount,
        uint256[] memory _requireIds
    ) public {
        require(saleEnabled == true);
        require(isPaused == false);
        uint256 _remainAmount = checkGiveawayRemainAmount(_proof, _amount, msg.sender);
        uint256 _salesAmount = _requireIds.length;
        require(_salesAmount <= _remainAmount);

        for (uint i = 0; i < _salesAmount; i++) {
            uint256 _requireId = _requireIds[i];

            require(zoomanXkumapi(kumapiNftAddress).ownerOf(_requireId) == sellerAddress);
            zoomanXkumapi(kumapiNftAddress).safeTransferFrom(sellerAddress, msg.sender, _requireId);
            
            uint256 _boxelId = _requireId % 13;
            zoomanXsasayon(sasayonNftAddress).mint(_boxelId, msg.sender);
        }

        giveawayFinishedAmount[msg.sender] += _salesAmount;
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool ret, ) = payable(withdrawAddress).call{
            value: address(this).balance
        }("");
        require(ret, "transfer failed");
    }

}