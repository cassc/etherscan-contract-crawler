// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

interface IStakingPool {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function mint(address[] calldata _addresses, uint256[] calldata _points) external;
    function burn(address _owner, uint256 _amount) external;
}

interface IMintableToken {
    function mint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external;
}

interface IRainiNft1155 {
    function mint(
        address _to,
        uint256 _cardId,
        uint256 _cardLevel,
        uint256 _amount,
        bytes1 _mintedContractChar,
        uint256 _number,
        uint256[] memory _data
    ) external;
}

contract RainiTokenMinter is AccessControl {    
    using ECDSA for bytes32;
    using BitMaps for BitMaps.BitMap;

    address public verifier;

    struct ContractInfo {
        address contractAddress;
        bool isLegacy;
    }

    mapping(uint256 => ContractInfo) public tokenContracts;
    
    BitMaps.BitMap private sigUsed;

    event TokensMinted(uint256 transactionId);

    constructor(
        address _verifier
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        verifier = _verifier;
    }

    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        _;
    }

    function setVerifier(address _verifier) public onlyOwner {
        verifier = _verifier;
    }

    function addTokenContract(uint256 _contractId, address _contractAddress, bool _isLegacy) public onlyOwner {
        tokenContracts[_contractId] = ContractInfo(_contractAddress, _isLegacy);
    }

    function removeTokenContract(uint256 _contractId) public onlyOwner {
        delete tokenContracts[_contractId];
    }

    function checkSignature(bytes memory message, bytes memory sig) public view returns (bool _success) {
        bytes32 _hash = keccak256(abi.encode("RainiNftMinter|", block.chainid, message));
        address signer = ECDSA.recover(_hash.toEthSignedMessageHash(), sig);
        return signer == verifier;
    }

    function _mint(
        address _to,
        uint256 _contractId,
        uint256 _tokenId,
        uint256 _amount
    ) internal {
        ContractInfo memory _contractInfo = tokenContracts[_contractId];
        if (_contractInfo.isLegacy) {
            IRainiNft1155(_contractInfo.contractAddress).mint(_to, _tokenId, 0, _amount, "", 0, new uint256[](0));
        } else {
            IMintableToken(_contractInfo.contractAddress).mint(_to, _tokenId, _amount);
        }
    }


    function mintTokens(
        bytes memory sig,
        uint256 transactionId,
        uint256[] memory _contractId,
        uint256[] memory _tokenId,
        uint256[] memory _amount) public {

        require (!sigUsed.get(transactionId), "items claimed");
        sigUsed.set(transactionId);

        bytes memory _hashString = abi.encode(transactionId, _msgSender(), "|mintTokens|");       
        for (uint256 i = 0; i < _contractId.length; i++) {
            _hashString = abi.encode(
                _hashString,
                _contractId[i],
                _tokenId[i],
                _amount[i]
            );
        }
        require(checkSignature(_hashString, sig), "Invalid sig");

        for (uint256 i = 0; i < _contractId.length; i++) {
            _mint(_msgSender(), _contractId[i], _tokenId[i], _amount[i]);
        }
        emit TokensMinted(transactionId);
    }

    function bulkMintTokens(
        bytes[] memory sig,
        uint256[] memory transactionId,
        uint256[][] memory _contractId,
        uint256[][] memory _tokenId,
        uint256[][] memory _amount
    ) external {
        for (uint256 i = 0; i < sig.length; i++) {
            mintTokens(sig[i], transactionId[i], _contractId[i], _tokenId[i], _amount[i]);
        }
    }

}