// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';

interface IERC1155 {
    function safeMint(address to, uint256 tokenId) external;
}

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;
}

contract AstrolistSell is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using StringsUpgradeable for uint256;
    mapping(address => bool) private _isWhiteListed;

    mapping(address => bool) private _isNotEligible;

    mapping(uint256 => bool) private _isIdTaken;

    address private _collectorAddress;

    IERC1155 private _nftToken;

    IERC20 private _erc20Token;

    uint256 private _price;

    string private _baseUri;

    address[] private _whiteListedAddresses;

    struct TokenUri {
        string uri;
        uint256 tokenId;
    }

    mapping(bytes32 => bool) private _isValidReferralId;

    struct ReferralData {
        uint256 totalClaimes;
        uint256 totalBuyes;
        address[] buyerAddresses;
        address[] claimerAddresses;
    }

    mapping(bytes32 => ReferralData) private _referralData;

    bytes32[] private _allReferrals;

    function initialize(
        address nftAddress,
        address erc20Address,
        address collectorAddress,
        string memory baseUri,
        uint256 price
    ) public initializer {
        _nftToken = IERC1155(nftAddress);
        _erc20Token = IERC20(erc20Address);
        _collectorAddress = collectorAddress;
        _baseUri = baseUri;
        _price = price;
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function claimReward(bytes32 referral) external {
        address to = _msgSender();
        _checkAddressConditions(to, referral);
        _referralData[referral].totalClaimes++;
        _referralData[referral].claimerAddresses.push(to);
        _isWhiteListed[to] = false;
        _removeWhiteListedAddress(to);
        for (uint256 i = 1; i < 501; i++) {
            if (!_isIdTaken[i]) {
                _nftToken.safeMint(to, i);
                _isIdTaken[i] = true;
                _isNotEligible[to] = true;
                break;
            }
        }
    }

    function claimRewardByTokenId(uint256 tokenId, bytes32 referral) external {
        address to = _msgSender();
        require(!_isIdTaken[tokenId], 'TokenId is already taken');
        _checkAddressConditions(to, referral);
        _referralData[referral].totalClaimes++;
        _referralData[referral].claimerAddresses.push(to);
        _isWhiteListed[to] = false;
        _removeWhiteListedAddress(to);
        _nftToken.safeMint(to, tokenId);
        _isIdTaken[tokenId] = true;
        _isNotEligible[to] = true;
    }

    function _checkAddressConditions(address to, bytes32 referral)
        internal
        view
    {
        require(_isWhiteListed[to], 'Address is not WhiteListed');
        require(!_isNotEligible[to], 'You are not eligible');
        require(
            _isValidReferralId[referral] || referral == bytes32(0),
            'Referral is invalid'
        );
    }

    function whiteListAddresses(address[] memory userAddresses)
        external
        onlyOwner
    {
        for (uint256 i; i < userAddresses.length; i++) {
            if (!_isWhiteListed[userAddresses[i]]) {
                _isWhiteListed[userAddresses[i]] = true;
                _whiteListedAddresses.push(userAddresses[i]);
            }
        }
    }

    function removeWhiteListedAddresses(address[] memory userAddresses)
        external
        onlyOwner
    {
        for (uint256 i; i < userAddresses.length; i++) {
            if (_isWhiteListed[userAddresses[i]]) {
                _isWhiteListed[userAddresses[i]] = false;
                _removeWhiteListedAddress(userAddresses[i]);
            }
        }
    }

    function _removeWhiteListedAddress(address userAddress) internal {
        uint256 length = _whiteListedAddresses.length;
        for (uint256 j = 0; j < length; j++) {
            if (_whiteListedAddresses[j] == userAddress) {
                _whiteListedAddresses[j] = _whiteListedAddresses[length - 1];
                _whiteListedAddresses.pop();
                break;
            }
        }
    }

    function buyNft(uint256 tokenId, bytes32 referral) external {
        require(!_isIdTaken[tokenId], 'Token Id is already taken');

        address userAddress = _msgSender();

        require(!_isNotEligible[userAddress], 'You are not eligible');
        require(
            _isValidReferralId[referral] || referral == bytes32(0),
            'Referral is invalid'
        );

        _referralData[referral].totalBuyes++;
        _referralData[referral].buyerAddresses.push(userAddress);

        _erc20Token.transferFrom(userAddress, _collectorAddress, _price);
        _nftToken.safeMint(userAddress, tokenId);
        _isNotEligible[userAddress] = true;
        _isIdTaken[tokenId] = true;
    }

    function getNfts() external view returns (TokenUri[] memory) {
        uint256 count;
        uint256 index;

        for (uint256 i = 1; i < 501; i++) {
            if (!_isIdTaken[i]) {
                count++;
            }
        }
        TokenUri[] memory tokenuris = new TokenUri[](count);

        for (uint256 j = 1; j < 501; j++) {
            if (!_isIdTaken[j]) {
                tokenuris[index] = TokenUri(
                    string(abi.encodePacked(_baseUri, j.toString())),
                    j
                );
                index++;
            }
        }
        return tokenuris;
    }

    function setIsIdTaken(uint256[] memory ids, bool value) external onlyOwner {
        for (uint256 i; i < ids.length; i++) {
            _isIdTaken[ids[i]] = value;
        }
    }

    function isWhiteListed(address userAddress) external view returns (bool) {
        return _isWhiteListed[userAddress];
    }

    function getWhitelistedAddresses()
        external
        view
        returns (address[] memory)
    {
        return _whiteListedAddresses;
    }

    function isNotEligible(address userAddress) external view returns (bool) {
        return _isNotEligible[userAddress];
    }

    function isIdTaken(uint256 tokenId) external view returns (bool) {
        return _isIdTaken[tokenId];
    }

    function getCollectorAddress() external view returns (address) {
        return _collectorAddress;
    }

    function getNFTAddress() external view returns (address) {
        return address(_nftToken);
    }

    function getERC20Address() external view returns (address) {
        return address(_erc20Token);
    }

    function getPrice() external view returns (uint256) {
        return _price;
    }

    function getBaseUri() external view returns (string memory) {
        return _baseUri;
    }

    function isValidReferralId(bytes32 referral) external view returns (bool) {
        return _isValidReferralId[referral];
    }

    function getReferralData(bytes32 referral)
        external
        view
        returns (
            uint256,
            uint256,
            address[] memory,
            address[] memory
        )
    {
        return (
            _referralData[referral].totalBuyes,
            _referralData[referral].totalClaimes,
            _referralData[referral].buyerAddresses,
            _referralData[referral].claimerAddresses
        );
    }

    function getAllReferrals() external view returns (bytes32[] memory) {
        return _allReferrals;
    }

    function makeAddressesEligibleOrRemoveIt(
        address[] memory userAddresses,
        bool value
    ) external onlyOwner {
        for (uint256 i; i < userAddresses.length; i++) {
            _isNotEligible[userAddresses[i]] = value;
        }
    }

    function setCollectorAddress(address collectorAddress) external onlyOwner {
        _collectorAddress = collectorAddress;
    }

    function setNFTTokenAddress(address nftAddress) external onlyOwner {
        _nftToken = IERC1155(nftAddress);
    }

    function setERC20TokenAddress(address erc20Address) external onlyOwner {
        _erc20Token = IERC20(erc20Address);
    }

    function setPrice(uint256 price) external onlyOwner {
        _price = price;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseUri = baseURI;
    }

    function mintNFT(address to, uint256 tokenId) external onlyOwner {
        require(!_isIdTaken[tokenId], 'Token Id is already taken');
        _isIdTaken[tokenId] = true;
        _nftToken.safeMint(to, tokenId);
    }

    function setReferrals(bytes32[] memory referrals) external onlyOwner {
        for (uint256 i; i < referrals.length; i++) {
            _isValidReferralId[referrals[i]] = true;
            _allReferrals.push(referrals[i]);
        }
    }

    function removeReferral(bytes32 referral) external onlyOwner {
        require(_isValidReferralId[referral], 'Referral is already removed');
        _isValidReferralId[referral] = false;
        uint256 length = _allReferrals.length - 1;
        for (uint256 i; i <= length; i++) {
            if (_allReferrals[i] == referral) {
                _allReferrals[i] = _allReferrals[length];
                _allReferrals.pop();
                break;
            }
        }
    }

    function setReferralData(
        uint256 totalBuyes,
        uint256 totalClaimes,
        address[] memory buyerAddresses,
        address[] memory claimerAddresses
    ) external onlyOwner {
        bytes32 zeroByte = bytes32(0);
        _referralData[zeroByte].totalClaimes = totalClaimes;
        _referralData[zeroByte].totalBuyes = totalBuyes;
        _referralData[zeroByte].buyerAddresses = buyerAddresses;
        _referralData[zeroByte].claimerAddresses = claimerAddresses;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}