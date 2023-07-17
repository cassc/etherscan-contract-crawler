// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Bean.sol";

contract ClaimVault is Pausable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    address payable bean;

    address public signatureManager;

    // contract => tokenId => claimed
    mapping(address => mapping(uint256 => bool)) internal _tokenClaimed;

    // signature => claimed
    mapping(bytes => bool) internal _signatureClaimed;

    // contract whitelist
    mapping(address => bool) public contractSupports;

    receive() external payable {}

    constructor(
        address payable _bean,
        address _signatureManager,
        address[] memory _contracts
    ) {
        bean = _bean;
        signatureManager = _signatureManager;
        for (uint256 i = 0; i < _contracts.length; i++) {
            contractSupports[_contracts[i]] = true;
        }
    }

    function claim(
        address[] memory _contracts,      // NFT contracts: azuki + beanz + elementals
        uint256[] memory _amounts,        // token amount for every contract: 2 + 3 + 1
        uint256[] memory _tokenIds,       // all token id, tokenIds.length = sum(amounts)
        uint256 _claimAmount,
        uint256 _endTime,
        bytes memory _signature          // sender + contracts + tokenIds + claimAmount + endTime
    ) external whenNotPaused nonReentrant {
        // check length
        require(_contracts.length == _amounts.length, "contracts length not match amounts length");

        // check contracts
        for (uint256 i = 0; i < _contracts.length; i++) {
            require(contractSupports[_contracts[i]], "contract not support");
        }

        uint256 totalAmount;
        for (uint256 j = 0; j < _amounts.length; j++) {
            totalAmount = totalAmount + _amounts[j];
        }
        require(totalAmount == _tokenIds.length, "total amount not match tokenId length");

        // check signature
        require(!signatureClaimed(_signature), "signature claimed");
        bytes32 message = keccak256(abi.encodePacked(msg.sender, _contracts, _tokenIds, _claimAmount, _endTime));
        require(signatureManager == message.toEthSignedMessageHash().recover(_signature), "invalid signature");
        require(block.timestamp <= _endTime, "signature expired");

        // check NFT
        uint256 endIndex;
        uint256 startIndex;
        for (uint256 i = 0; i < _amounts.length; i++) {

            endIndex = startIndex + _amounts[i];

            for (uint256 j = startIndex; j < endIndex; j++) {
                address contractAddr = _contracts[i];
                uint256 tokenId = _tokenIds[j];
                require(!tokenClaimed(contractAddr, tokenId), "token claimed");
                require(IERC721(contractAddr).ownerOf(tokenId) == msg.sender, "not owner");
                _tokenClaimed[contractAddr][tokenId] = true;
            }
            startIndex = endIndex;
        }
        _signatureClaimed[_signature] = true;
        // transfer token
        IERC20(bean).transfer(msg.sender, _claimAmount);
    }

    function signatureClaimed(bytes memory _signature) public returns(bool) {
        return _signatureClaimed[_signature] || Bean(bean).signatureClaimed(_signature);
    }

    function tokenClaimed(address _contract, uint256 _tokenId) public returns(bool) {
        return _tokenClaimed[_contract][_tokenId] || Bean(bean).tokenClaimed(_contract, _tokenId);
    }

    function setContractSupports(address[] memory _contracts, bool[] memory _enables) external onlyOwner {
        require(_contracts.length == _enables.length, "contracts length not match _enables length");
        for (uint256 i = 0; i < _contracts.length; i++) {
            contractSupports[_contracts[i]] = _enables[i];
        }
    }

    function setSignatureManager(address _signatureManager) external onlyOwner {
        signatureManager = _signatureManager;
    }

    function finish() external onlyOwner whenPaused {
        IERC20(bean).transfer(address(0), Bean(bean).balanceOf(address(this)));
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function withdraw(address _receiver, address _token, bool _isETH) external onlyOwner {
        if (_isETH) {
            payable(_receiver).transfer(address(this).balance);
        } else {
            IERC20(_token).transfer(_receiver, IERC20(_token).balanceOf(address(this)));
        }
    }

}