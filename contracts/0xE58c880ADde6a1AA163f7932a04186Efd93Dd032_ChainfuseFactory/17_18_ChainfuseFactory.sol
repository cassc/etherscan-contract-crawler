// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import { Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC1155Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "hardhat/console.sol";

contract LibraryLockDataLayout {
  bool public initializedFlag;
}

contract ChainfuseFactoryWrapper is LibraryLockDataLayout {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet supportedTokens; // USDC for now
    EnumerableSet.AddressSet admins; // Admins where the fee can be transferred
    uint256 internal chainfusePercentage; // 10: 1%, 25: 2.5%
    mapping(uint256 => Registration) internal registrations;
    mapping(uint256 => string) internal tokenURIs;
    mapping(uint256 => mapping(address => MintedStatus)) internal mintedNfts;

    event NewRegistration(
        uint256 indexed registrationId,
        address indexed owner
    );
    event NewMultiRegistration(
        uint256 [] registrationIds,
        address indexed owner
    );
    event Minted(address indexed sender, uint256 amount);
    event Recovered(address indexedtoken, uint256 amount);

    struct Registration {
        address owner;
        uint256 price;
        uint256 initialSupply;
        uint256 totalSupply;
        string uri;
    }

    struct MintedStatus {
        address owner;
        uint256 registrationId;
        uint256 amount;
    }

    function initialized(address [] memory _acceptToken, address [] memory _admins, uint256 _chainfusePercentage) internal {
        uint256 i;
        
        for (i = 0; i < _acceptToken.length; i++)
            supportedTokens.add(_acceptToken[i]);
        for (i = 0; i < _admins.length; i++)
            admins.add(_admins[i]);
        chainfusePercentage = _chainfusePercentage;
    }

    function _addToken(address _token) internal {
        supportedTokens.add(_token);
    }

    function _removeToken(address _token) internal {
        supportedTokens.remove(_token);
    }

    function checkToken(address _token) internal view returns(bool) {
        return supportedTokens.contains(_token);
    }

    function fetchSupportedToken(uint256 index) internal view returns (address) {
        return supportedTokens.at(index);
    }

    function _addAdmin(address _admin) internal {
        admins.add(_admin);
    }

    function _removeAdmin(address _admin) internal {
        admins.remove(_admin);
    }

    function _updateChainfusePercentage(uint256 _chainfusePercentage) internal {
        chainfusePercentage = _chainfusePercentage;
    }

    function checkAdmin(address _admin) internal view returns(bool) {
        return admins.contains(_admin);
    }

    function fetchAdmins(uint256 index) internal view returns (address) {
        return admins.at(index);
    }
}

contract ChainfuseFactory is ERC1155Upgradeable, ChainfuseFactoryWrapper, ReentrancyGuardUpgradeable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    
    address private signer;
    Counters.Counter private _registered;

    AggregatorV3Interface internal priceFeed;
    uint8 mainDecimals; // Chainlink USD prices are always to 8

    function initialize(
        address [] memory _acceptToken,
        address [] memory _admins,
        uint256 _chainfusePercentage,
        string memory _uri,
        address _aggregator,
        uint8 _mainDecimals
    ) public initializer {
        require(!initializedFlag, "Contract is already initialized");
        ChainfuseFactoryWrapper.initialized(_acceptToken, _admins, _chainfusePercentage);
        ERC1155Upgradeable.__ERC1155_init(_uri);
        signer = _msgSender();
        initializedFlag = true;
        priceFeed = AggregatorV3Interface(
            _aggregator
        );
        mainDecimals = _mainDecimals;
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256 _tokenId) override public view returns (string memory) {
        return string(
            abi.encodePacked(
            "https://ipfs.io/ipfs/",
            tokenURIs[_tokenId]
           )
        );
    }

    function getRegistration(uint256 _registrationId) external view returns (Registration memory registration) {
        return registrations[_registrationId];
    }

    function getNft(uint256 _registrationId, address _userAddress) external view returns (MintedStatus memory status) {
        return mintedNfts[_registrationId][_userAddress];
    }

    function setTokenUri(uint256 tokenId, string memory tokenURI) private {
        tokenURIs[tokenId] = tokenURI;
    }

    function registerNftCollection(uint256 _price, uint256 _supply, string calldata _collectionUri) external delegatedOnly {
        _registered.increment();
        uint256 newItemId = _registered.current();

        Registration memory registration = Registration(msg.sender, _price, _supply, _supply, _collectionUri);    
        registrations[newItemId] = registration;
        setTokenUri(newItemId, _collectionUri);
        emit NewRegistration(newItemId, msg.sender);
    }

    function registerMultiNftCollections(uint256 [] calldata _prices, uint256 [] calldata _supplies, string [] calldata _collectionUri) external delegatedOnly {
        require(_prices.length == _supplies.length && _collectionUri.length == _supplies.length, "The length of arrays should be same.");
        uint256 i;
        uint256 [] memory newItemIds = new uint256 [](_prices.length);
        uint256 newItemId;

        for (i = 0; i < _prices.length; i++) {
            _registered.increment();
            newItemId = _registered.current();
            Registration memory registration = Registration(msg.sender, _prices[i], _supplies[i], _supplies[i], _collectionUri[i]);
            registrations[newItemId] = registration;
            setTokenUri(newItemId, _collectionUri[i]);
            newItemIds[i] = newItemId;
        }
        emit NewMultiRegistration(newItemIds, msg.sender);
    }

    function mint(
        // Voucher verification required.
        // Combine both of these to get signer confirmation address as verification
        bytes memory _signature,
        bytes32 _messageHash,

        // Data to process
        // (IDEA: Any way parterships can work the same way?)
        uint256 _registrationId,

        // Potential
        // Lock period: Until when will this NFT be mintable?
        // Decline formula: Devalue price of the NFT over time
        uint256 _amount,
        address _paidToken, // USDC
        uint256 _tokenAmount, // USDC amount
        uint8 _decimalDiff // USDC decimal is 6 so this value should be 12.
    ) payable external {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(_messageHash);

        Registration memory registration = registrations[_registrationId];

        // Make sure the owner's voucher is verified, and based if that voucher is valid with all of its parameters, proceed.
        require(recoverSigner(ethSignedMessageHash, _signature) == registrations[_registrationId].owner, "Signer is not the owner of the signature");
        require(_amount >= 0, "Must be positive number");

        uint256 rate = getLatestPrice();

        if (_paidToken == address(0))
            // Calculate the price with chainlink feed (ETH/USD)
            require((_amount * registration.price * (10 ** mainDecimals) / rate) == msg.value, "The ether price does not match");
        if (_paidToken != address(0))
            require((_amount * registration.price / (10 ** _decimalDiff)) == _tokenAmount, "The paid token amount does not match");
        require((registration.totalSupply - _amount) >= 0, "NFTs ran out");
        require(_amount >= 0, "Must be positive number");

        uint256 addAmount =  mintedNfts[_registrationId][msg.sender].amount + _amount;

        setTokenUri(_registrationId, registration.uri);
        
        _mint(msg.sender, _registrationId, _amount, "");
        
        registrations[_registrationId].totalSupply = registration.totalSupply - _amount;

        mintedNfts[_registrationId][msg.sender] = MintedStatus(msg.sender, _registrationId, addAmount);
        mintedNfts[_registrationId][msg.sender].amount = addAmount;

        uint256 price4Owner;

        if (_paidToken == address(0)) { // paid with ether
            // Calculate the ether amount to be transferred to the NFT owner by reducing the fee
            price4Owner = msg.value * (1000 - chainfusePercentage) / 1000;
            // Send ether to the NFT owner
            payable(address(registration.owner)).transfer(price4Owner);
        } else {
            // Check if the payment token is registered already
            require(checkToken(_paidToken), "Not supported token for payment");
            // Calculate the payment token amount to be transferred to the NFT owner by reducing the fee
            price4Owner = _tokenAmount * (1000 - chainfusePercentage) / 1000;
            // Transfer the payment token to this contract as fee
            IERC20(_paidToken).transferFrom(msg.sender, address(this), _tokenAmount);
            // Transfer the payment token to the NFT owner
            IERC20(_paidToken).transfer(address(registration.owner), price4Owner);
        }

        emit Minted(msg.sender, _amount);
    }

    function recoverERC20(address _tokenAddress, uint256 _tokenAmount, address _beneficiary) external isSigner {
        require(_tokenAddress == address(0) || checkToken(_tokenAddress), "Not supported token for payment");
        require(checkAdmin(_beneficiary), "Not admin");
        if (_tokenAddress == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            require(_tokenAmount <= IERC20(_tokenAddress).balanceOf(address(this)), "Not enough token amount");
            IERC20(_tokenAddress).transfer(_beneficiary, _tokenAmount);
        }
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    function verify(
        bytes memory _input,
        bytes memory _signature
    ) private view returns (bool) {
        bytes32 messageHash = getMessageHash(_input);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, _signature) == signer;
    }

    function getMessageHash(bytes memory _input) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_input));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        private
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        private
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function getSupportedTokens(uint256 _index) external view returns(address) {
        return fetchSupportedToken(_index);
    }

    function addToken(address _token) external isSigner {
        _addToken(_token);
    }

    function removeToken(address _token) external isSigner {
        _removeToken(_token);
    }

    function addAdmin(address _admin) external isSigner {
        _addAdmin(_admin);
    }

    function removeAdmin(address _admin) external isSigner {
        _removeAdmin(_admin);
    }

    function getSigner() external view returns(address) {
        return signer;
    }

    function updateSigner(address _signer) external isSigner {
        signer = _signer;
    }

    function updateChainfusePercentage(uint256 _chainfusePercentage) external isSigner {
        _updateChainfusePercentage(_chainfusePercentage);
    }

    function getTimestamp() public view virtual returns (uint256) {
        return block.timestamp;
    }

    function updateMainDecimals(uint8 _mainDecimals) external isSigner {
        mainDecimals = _mainDecimals;
    }

    function getLatestPrice() public view returns (uint256) {
        (
            ,
            /*uint80 roundID*/ int256 price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    modifier isSigner {
        require(_msgSender() == signer, "This function can only be called by an signer");
        _;
    }

    modifier delegatedOnly() {
        require(initializedFlag, "The library is locked. No direct 'call' is allowed");
        _;
    }
}