// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./SignatureVerify.sol";
import "../../utils/uniq/Ierc20.sol";
import "../../interfaces/IUniqRedeemV2.sol";

contract UniqPaymentProxyV2 is Ownable, SignatureVerify {
    IUniqRedeemV2 internal _redeem;

    // ----- EVENTS ----- //
    event TokensRequested(
        address indexed _requester,
        address indexed _mintAddress,
        uint256[] _tokenIds,
        uint256 _bundleId
    );
    event TokensBougth(
        address indexed _mintingContractAddress,
        address indexed _sellerAddress,
        address indexed _receiver,
        uint256 _bundleId,
        uint256[] _tokenIds,
        uint256 _priceForPackage,
        address _paymentToken,
        uint256 _sellerFee
    );
    event Withdraw(
        address indexed _sellerAddress,
        address _tokenContractAddress,
        uint256 _amount
    );

    // ----- VARIABLES ----- //
    uint256 internal _transactionOffset;
    uint256 internal _networkId;
    mapping(bytes => bool) internal _isSignatureUsed;
    mapping(address => mapping(uint256 => bool))
        internal _tokenAlreadyRequested;
    mapping(uint256 => bool) internal _isNonceUsed;

    // ----- CONSTRUCTOR ----- //
    constructor(uint256 _pnetworkId) {
        _transactionOffset = 3 minutes;
        _networkId = _pnetworkId;
    }

    function setRedeemAddress(IUniqRedeemV2 _redeemAddress) external onlyOwner {
        _redeem = _redeemAddress;
    }

    // ----- VIEWS ----- //
    function getRedeemAddress() external view returns (address) {
        return address(_redeem);
    }

    // ----- MESSAGE SIGNATURE ----- //
    /// @dev not test for functions related to signature
    function getMessageHash(
        address _mintingContractAddress,
        address _sellerAddress,
        uint256 _percentageForSeller,
        uint256 _bundleId,
        uint256[] memory _tokenIds,
        uint256 _price,
        address _paymnetTokenAddress,
        uint256 _timestamp,
        string memory _redeemerName,
        uint256 _purpose
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _networkId,
                    _mintingContractAddress,
                    _sellerAddress,
                    _percentageForSeller,
                    _bundleId,
                    _tokenIds,
                    _price,
                    _paymnetTokenAddress,
                    _timestamp,
                    _redeemerName,
                    _purpose
                )
            );
    }

    /// @dev not test for functions related to signature
    function verifySignature(
        address _mintingContractAddress,
        address _sellerAddress,
        uint256 _percentageForSeller,
        uint256 _bundleId,
        uint256[] memory _tokenIds,
        uint256 _price,
        address _paymentTokenAddress,
        bytes memory _signature,
        uint256 _timestamp,
        string memory _redeemerName,
        uint256 _purpose
    ) internal view returns (bool) {
        bytes32 messageHash = getMessageHash(
            _mintingContractAddress,
            _sellerAddress,
            _percentageForSeller,
            _bundleId,
            _tokenIds,
            _price,
            _paymentTokenAddress,
            _timestamp,
            _redeemerName,
            _purpose
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == owner();
    }

    function getMessageHashRequester(
        address _mintContractAddress,
        uint256 _mintNetworkId,
        address _sellerAddress,
        uint256 _percentageForSeller,
        uint256 _bundleId,
        uint256[] memory _tokenIds,
        uint256 _price,
        address _paymnetTokenAddress,
        uint256 _timestamp,
        address _requesterAddress
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _networkId,
                    _mintContractAddress,
                    _mintNetworkId,
                    _sellerAddress,
                    _percentageForSeller,
                    _bundleId,
                    _tokenIds,
                    _price,
                    _paymnetTokenAddress,
                    _timestamp,
                    _requesterAddress
                )
            );
    }

    function verifySignatureRequester(
        address _mintContractAddress,
        uint256 _mintNetworkId,
        address _sellerAddress,
        uint256 _percentageForSeller,
        uint256 _bundleId,
        uint256[] memory _tokenIds,
        uint256 _price,
        address _paymentTokenAddress,
        bytes memory _signature,
        uint256 _timestamp
    ) internal view returns (bool) {
        bytes32 messageHash = getMessageHashRequester(
            _mintContractAddress,
            _mintNetworkId,
            _sellerAddress,
            _percentageForSeller,
            _bundleId,
            _tokenIds,
            _price,
            _paymentTokenAddress,
            _timestamp,
            msg.sender
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == owner();
    }

    function _redeemTokens(
        address _mintingContractAddress,
        uint256[] memory _tokenIds,
        string memory _redeemerName,
        uint256 _purpose
    ) internal {
        address[] memory contractAddresses = new address[](_tokenIds.length);
        uint256[] memory purposes = new uint256[](_tokenIds.length);
        string[] memory names = new string[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            contractAddresses[i] = _mintingContractAddress;
            purposes[i] = _purpose;
            names[i] = _redeemerName;
        }
        _redeem.redeemTokensAsAdmin(
            contractAddresses,
            _tokenIds,
            purposes,
            names
        );
    }

    function _sendTokens(address _paymentToken, uint256 _priceForPackage, address _sellerAddress, uint256 _percentageForSeller) internal returns(uint256 sellerFee){
        sellerFee = (_priceForPackage * _percentageForSeller) / 100;
        if (_priceForPackage != 0) {
        if (_paymentToken == address(0)) {
                require(msg.value >= _priceForPackage, "Not enough ether");
                if (_priceForPackage < msg.value) {
                    payable(msg.sender).transfer(msg.value - _priceForPackage);
                }
                payable(_sellerAddress).transfer(sellerFee);
            } else {
                Ierc20(_paymentToken).transferFrom(
                    msg.sender,
                    _sellerAddress,
                    sellerFee
                );
                Ierc20(_paymentToken).transferFrom(
                    msg.sender,
                    address(this),
                    _priceForPackage - sellerFee
                );
            }
        }
    }

    function _mintAndRedeem(address _mintingContractAddress,  address _receiver, uint256[] memory _tokenIds, string memory _redeemerName, uint256 _purpose) internal {
        address[] memory _receivers = new address[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _receivers[i] = _receiver;
        }
        IUniqCollections(_mintingContractAddress).batchMintSelectedIds(
            _tokenIds,
            _receivers
        );
        if (
            _purpose != 0 && bytes(_redeemerName).length >= 2 && (address(_redeem) != address(0))
        ) {
            _redeemTokens(_mintingContractAddress, _tokenIds, _redeemerName, _purpose);
        }
    }

    // ----- PUBLIC METHODS ----- //
    function buyTokens(
        address _mintingContractAddress,
        address _sellerAddress,
        uint256 _percentageForSeller,
        uint256 _bundleId,
        uint256[] memory _tokenIds,
        uint256 _priceForPackage,
        address _paymentToken,
        address _receiver,
        bytes memory _signature,
        uint256 _timestamp,
        string memory _redeemerName,
        uint256 _purpose
    ) external payable {
        require(
            _timestamp + _transactionOffset >= block.timestamp,
            "Transaction timed out"
        );
        require(!_isSignatureUsed[_signature], "Signature already used");
        require(
            verifySignature(
                _mintingContractAddress,
                _sellerAddress,
                _percentageForSeller,
                _bundleId,
                _tokenIds,
                _priceForPackage,
                _paymentToken,
                _signature,
                _timestamp,
                _redeemerName,
                _purpose
            ),
            "Signature mismatch"
        );
        _isSignatureUsed[_signature] = true;
        
        uint256 sellerFee = _sendTokens(_paymentToken,  _priceForPackage,  _sellerAddress, _percentageForSeller);

        _mintAndRedeem(_mintingContractAddress, _receiver, _tokenIds, _redeemerName, _purpose);
        
        emit TokensBougth(
            _mintingContractAddress,
            _sellerAddress,
            _receiver,
            _bundleId,
            _tokenIds,
            _priceForPackage,
            _paymentToken,
            sellerFee
        );
    }

    function requestTokens(
        address _mintContractAddress,
        uint256 _mintNetworkId,
        address _sellerAddress,
        uint256 _percentageForSeller,
        uint256 _bundleId,
        uint256[] memory _tokenIds,
        uint256 _priceForPackage,
        address _paymentToken,
        bytes memory _signature,
        uint256 _timestamp
    ) external payable {
        require(
            _timestamp + _transactionOffset >= block.timestamp,
            "Transaction timed out"
        );
        require(!_isSignatureUsed[_signature], "Signature already used");
        require(
            verifySignatureRequester(
                _mintContractAddress,
                _mintNetworkId,
                _sellerAddress,
                _percentageForSeller,
                _bundleId,
                _tokenIds,
                _priceForPackage,
                _paymentToken,
                _signature,
                _timestamp
            ),
            "Signature mismatch"
        );
        _isSignatureUsed[_signature] = true;
        uint256 sellerFee = (_priceForPackage * _percentageForSeller) /
                    100;
        if (_priceForPackage != 0) {
            if (_paymentToken == address(0)) {
                require(msg.value >= _priceForPackage, "Not enough ether");
                if (_priceForPackage < msg.value) {
                    payable(msg.sender).transfer(msg.value - _priceForPackage);
                }
                payable(_sellerAddress).transfer(sellerFee);
            } else {
                Ierc20(_paymentToken).transferFrom(
                    msg.sender,
                    _sellerAddress,
                    sellerFee
                );
                Ierc20(_paymentToken).transferFrom(
                    msg.sender,
                    address(this),
                    _priceForPackage - sellerFee
                );
            }
        }
        if(_mintNetworkId == _networkId){ 
            if(NFTContract(_mintContractAddress).owner() == address(this)){
            address[] memory _receivers = new address[](_tokenIds.length);
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                _receivers[i] = msg.sender;
            }
            IUniqCollections(_mintContractAddress).batchMintSelectedIds(
                _tokenIds,
                _receivers
            );
            return();
            }
        }
        emit TokensRequested(
            msg.sender,
            _mintContractAddress,
            _tokenIds,
            _bundleId
        );
    }

    // ----- PROXY METHODS ----- //

    function pEditClaimingAddress(address _contractAddress, address _newAddress)
        external
        onlyOwner
    {
        IUniqCollections(_contractAddress).editClaimingAdress(_newAddress);
    }

    function pEditRoyaltyFee(address _contractAddress, uint256 _newFee)
        external
        onlyOwner
    {
        IUniqCollections(_contractAddress).editRoyaltyFee(_newFee);
    }

    function pEditTokenUri(address _contractAddress, string memory _ttokenUri)
        external
        onlyOwner
    {
        IUniqCollections(_contractAddress).editTokenUri(_ttokenUri);
    }

    function pRecoverERC20(address _contractAddress, address token)
        external
        onlyOwner
    {
        IUniqCollections(_contractAddress).recoverERC20(token);
        uint256 val = IERC20(token).balanceOf(address(this));
        require(val > 0, "Nothing to recover");
        Ierc20(token).transfer(owner(), val);
    }

    function pTransferOwnership(address _contractAddress, address newOwner)
        external
        onlyOwner
    {
        IUniqCollections(_contractAddress).transferOwnership(newOwner);
    }

    function pBatchMintSelectedIds(
        uint256[] memory _ids,
        address[] memory _addresses,
        address _contractAddress
    ) external onlyOwner {
        IUniqCollections(_contractAddress).batchMintSelectedIds(
            _ids,
            _addresses
        );
    }

    function pBatchMintSelectedIdsAndRedeem(
        uint256[] memory _ids,
        address[] memory _addresses,
        address _contractAddress,
        string[] memory _redeemerName,
        uint256 _purpose
    ) external onlyOwner {
        IUniqCollections(_contractAddress).batchMintSelectedIds(
            _ids,
            _addresses
        );
        uint256[] memory purposes = new uint256[](_ids.length);
        address[] memory contractAddresses = new address[](_ids.length);
        for (uint256 i = 0; i < _ids.length; i++) {
            purposes[i] = _purpose;
            contractAddresses[i] = _contractAddress;
        }
        _redeem.redeemTokensAsAdmin(
            contractAddresses,
            _ids,
            purposes,
            _redeemerName
        );
    }

    function pMintNextToken(address _contractAddress, address _receiver)
        external
        onlyOwner
    {
        IUniqCollections(_contractAddress).mintNextToken(_receiver);
    }

    // ----- OWNERS METHODS ----- //

    function withdrawTokens(address token) external onlyOwner {
        uint256 val = IERC20(token).balanceOf(address(this));
        require(val != 0, "Nothing to recover");
        // use interface that not return value (USDT case)
        Ierc20(token).transfer(msg.sender, val);
    }

    function setTransactionOffset(uint256 _newOffset) external onlyOwner {
        _transactionOffset = _newOffset;
    }

    receive() external payable {}

    function wthdrawETH() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}

interface IUniqCollections {
    function editClaimingAdress(address _newAddress) external;

    function editRoyaltyFee(uint256 _newFee) external;

    function batchMintSelectedIds(
        uint256[] memory _ids,
        address[] memory _addresses
    ) external;

    function editTokenUri(string memory _ttokenUri) external;

    function recoverERC20(address token) external;

    function transferOwnership(address newOwner) external;

    function mintNextToken(address _receiver) external;
}

interface NFTContract {
    function mintNFTTokens(
        address _requesterAddress,
        uint256 _bundleId,
        uint256[] memory _tokenIds,
        uint256 _chainId,
        bytes memory _transactionHash
    ) external;

    function owner() external view returns(address);
}