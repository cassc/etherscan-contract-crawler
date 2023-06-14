//     ______          __    __                          
//    / ____/___ ___  / /_  / /__  ____ ___              
//   / __/ / __ `__ \/ __ \/ / _ \/ __ `__ \             
//  / /___/ / / / / / /_/ / /  __/ / / / / /             
// /_____/_/ /_/ /_/_.___/_/\___/_/ /_/ /_/              
// | |  / /___ ___  __/ / /_                             
// | | / / __ `/ / / / / __/                             
// | |/ / /_/ / /_/ / / /_                               
// |___/\__,_/\__,_/_/\__/                               
//     __  __                ____                   ____ 
//    / / / /___ _____  ____/ / /__  _____   _   __( __ ) (upgradable)
//   / /_/ / __ `/ __ \/ __  / / _ \/ ___/  | | / / __  |
//  / __  / /_/ / / / / /_/ / /  __/ /      | |/ / /_/ / 
// /_/ /_/\__,_/_/ /_/\__,_/_/\___/_/       |___/\____/  

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./BasicERC20.sol";
import "./IIsSerialized.sol";
import "./SafeMath.sol";
import "./IERC721.sol";
import "./IERC165.sol";
import "./IERC1155.sol";
import "./IClaimed.sol";
import "./ERC165.sol";
import "./IMintVaultQuote.sol";
import "./ReentrancyGuardUpgradable.sol";
import "./HasCallbacksUpgradable.sol";
import "./BytesLib.sol";

contract VaultHandlerV8Upgradable is ReentrancyGuardUpgradable, HasCallbacksUpgradable, ERC165 {
    
    using SafeMath for uint256;
    string public metadataBaseUri;
    bool public initialized;
    address public recipientAddress;

    bytes4 private _INTERFACE_ID_ERC1155;
    bytes4 private _INTERFACE_ID_ERC20;
    bytes4 private _INTERFACE_ID_ERC721;
    bool public shouldBurn;
    
    mapping(address => bool) public witnesses;
    mapping(uint256 => bool) usedNonces;
    
    address private quoteContract;

    function initialize() public initializer {
        __Ownable_init();
        addWitness(owner());
        ReentrancyGuardUpgradable.init();
        metadataBaseUri = "https://v2.emblemvault.io/meta/";
        _INTERFACE_ID_ERC1155 = 0xd9b67a26;
        _INTERFACE_ID_ERC20 = 0x74a1476f;
        _INTERFACE_ID_ERC721 = 0x80ac58cd;
        recipientAddress = _msgSender();
        HasCallbacksUpgradable.allowCallbacks = true;        
        initializeERC165();
        initialized = true;
    }

    function updateQuoteContract(address _address) public onlyOwner() {
        quoteContract = _address;
    }

    function claim(address _nftAddress, uint256 tokenId) public nonReentrant isRegisteredContract(_nftAddress) {
        IClaimed claimer = IClaimed(registeredOfType[6][0]);
        bytes32[] memory proof;
        
        if (IERC165(_nftAddress).supportsInterface(_INTERFACE_ID_ERC1155)) {
            IIsSerialized serialized = IIsSerialized(_nftAddress);
            uint256 serialNumber = serialized.getFirstSerialByOwner(_msgSender(), tokenId);
            require(serialized.getTokenIdForSerialNumber(serialNumber) == tokenId, "Invalid tokenId serialnumber combination");
            require(serialized.getOwnerOfSerial(serialNumber) == _msgSender(), "Not owner of serial number");
            require(!claimer.isClaimed(_nftAddress, serialNumber, proof), "Already Claimed");
            IERC1155(_nftAddress).burn(_msgSender(), tokenId, 1);
            claimer.claim(_nftAddress, serialNumber, _msgSender());
        } else {            
            require(!claimer.isClaimed(_nftAddress, tokenId, proof), "Already Claimed");
            IERC721 token = IERC721(_nftAddress);
            require(token.ownerOf(tokenId) == _msgSender(), "Not Token Owner");
            token.burn(tokenId);
            claimer.claim(_nftAddress, tokenId, _msgSender());
        }
        executeCallbacksInternal(_nftAddress, _msgSender(), address(0), tokenId, IHandlerCallback.CallbackType.CLAIM);
    }

    function buyWithSignedPrice(address _nftAddress, address _payment, uint _price, address _to, uint256 _tokenId, uint256 _nonce, bytes calldata _signature, bytes calldata serialNumber, uint256 _amount) public nonReentrant {
        IERC20Token paymentToken = IERC20Token(_payment);
        if (shouldBurn) {
            require(paymentToken.transferFrom(msg.sender, address(this), _price), 'Transfer ERROR'); // Payment sent to recipient
            BasicERC20(_payment).burn(_price);
        } else {
            require(paymentToken.transferFrom(msg.sender, address(recipientAddress), _price), 'Transfer ERROR'); // Payment sent to recipient
        }
        address signer = getAddressFromSignature(_nftAddress, _payment, _price, _to, _tokenId, _nonce, _amount, _signature);
        handleMint(_nftAddress, _to, _tokenId, _nonce, _amount, signer, serialNumber);
    }

    function buyWithQuote(address _nftAddress, uint _price, address _to, uint256 _tokenId, uint256 _nonce, bytes calldata _signature, bytes calldata serialNumber, uint256 _amount) public payable nonReentrant {
        uint256 quote = IMintVaultQuote(quoteContract).quoteExternalPrice(_msgSender(), _price);
        uint256 totalPrice = quote * _amount;
        // Calculate the acceptable range for the msg.value
        uint256 acceptableRange = totalPrice * 2 / 100; // 2% of totalPrice

        require(
            msg.value >= totalPrice - acceptableRange && msg.value <= totalPrice + acceptableRange,
            "The sent amount is outside the acceptable range"
        );
        payable(recipientAddress).transfer(msg.value);
        address signer = getAddressFromSignatureQuote(_nftAddress, _price, _to, _tokenId, _nonce, _amount, _signature);
        handleMint(_nftAddress, _to, _tokenId, _nonce, _amount, signer, serialNumber);        
    }

    function handleMint(address _nftAddress, address _to, uint256 _tokenId, uint256 _nonce, uint256 _amount, address signer, bytes calldata serialNumber) internal {
        require(witnesses[signer], 'Not Witnessed');
        usedNonces[_nonce] = true;
        string memory _uri = concat(metadataBaseUri, uintToStr(_tokenId));
        if (IERC165(_nftAddress).supportsInterface(_INTERFACE_ID_ERC1155)) {
            if (IIsSerialized(_nftAddress).isOverloadSerial()) {
                IERC1155(_nftAddress).mintWithSerial(_to, _tokenId, _amount, serialNumber);
            } else {
                IERC1155(_nftAddress).mint(_to, _tokenId, _amount);
            }
        } else {
            IERC721(_nftAddress).mint(_to, _tokenId, _uri, '');
        }
    }

    function mint(address _nftAddress, address _to, uint256 _tokenId, string calldata _uri, string calldata _payload, uint256 amount) external onlyOwner {
        if (IERC165(_nftAddress).supportsInterface(_INTERFACE_ID_ERC1155)) {
            IERC1155(_nftAddress).mint(_to, _tokenId, amount);
        } else {
            IERC721(_nftAddress).mint(_to, _tokenId, _uri, _payload);
        }        
    }

    function moveVault(address _from, address _to, uint256 tokenId, uint256 newTokenId, uint256 nonce, bytes calldata signature, bytes memory serialNumber) external nonReentrant isRegisteredContract(_from) isRegisteredContract(_to)  {
        require(_from != _to, 'Cannot move vault to same address');
        require(witnesses[getAddressFromSignatureHash(keccak256(abi.encodePacked(_from, _to, tokenId, newTokenId, serialNumber, nonce)), signature)], 'Not Witnessed');
        usedNonces[nonce] = true;
        if (IERC165(_from).supportsInterface(_INTERFACE_ID_ERC1155)) {
            require(tokenId != newTokenId, 'from: TokenIds must be different for ERC1155');
            require(IERC1155(_from).balanceOf(_msgSender(), tokenId) > 0, 'from: Not owner of vault');
            IERC1155(_from).burn(_msgSender(), tokenId, 1);
        } else {
            require(IERC721(_from).ownerOf(tokenId) == _msgSender(), 'from: Not owner of vault');
            IERC721(_from).burn(tokenId);
        }
        if (IERC165(_to).supportsInterface(_INTERFACE_ID_ERC1155)) {
            require(tokenId != newTokenId, 'to: TokenIds must be different for ERC1155');
            if (IIsSerialized(_to).isOverloadSerial()) {
                require(BytesLib.toUint256(serialNumber, 0) != 0, "Handler: must provide serial number");
                IERC1155(_to).mintWithSerial(_msgSender(), newTokenId, 1, serialNumber);
            } else {
                IERC1155(_to).mint(_msgSender(), newTokenId, 1);
            }
        } else {
             IERC721(_to).mint(_msgSender(), newTokenId, concat(metadataBaseUri, uintToStr(newTokenId)), "");
        }
    }  
    
    function toggleShouldBurn() public onlyOwner {
        shouldBurn = !shouldBurn;
    }
    
    function addWitness(address _witness) public onlyOwner {
        witnesses[_witness] = true;
    }

    function removeWitness(address _witness) public onlyOwner {
        witnesses[_witness] = false;
    }

    function getAddressFromSignatureHash(bytes32 _hash, bytes calldata signature) internal pure returns (address) {
        address addressFromSig = recoverSigner(_hash, signature);
        return addressFromSig;
    }

    function getAddressFromSignature(address _nftAddress, address _payment, uint _price, address _to, uint256 _tokenId, uint256 _nonce, uint256 _amount, bytes calldata signature) internal view returns (address) {
        require(!usedNonces[_nonce], 'Nonce already used');
        return getAddressFromSignatureHash(keccak256(abi.encodePacked(_nftAddress, _payment, _price, _to, _tokenId, _nonce, _amount)), signature);
    }

    function getAddressFromSignatureQuote(address _nftAddress, uint _price, address _to, uint256 _tokenId, uint256 _nonce, uint256 _amount, bytes calldata signature) internal view returns (address) {
        require(!usedNonces[_nonce], 'Nonce already used');
        return getAddressFromSignatureHash(keccak256(abi.encodePacked(_nftAddress, _price, _to, _tokenId, _nonce, _amount)), signature);
    }

    function getAddressFromSignatureMint(address _nftAddress, address _to, uint256 _tokenId, uint256 _nonce, string calldata payload, bytes calldata signature) internal view returns (address) {
        require(!usedNonces[_nonce]);
        return getAddressFromSignatureHash(keccak256(abi.encodePacked(_nftAddress, _to, _tokenId, _nonce, payload)), signature);
    }

    function getAddressFromSignatureMove(address _from, address _to, uint256 tokenId, uint256 newTokenId, uint256 _nonce, bytes memory serialNumber, bytes calldata signature) internal view returns (address) {
        require(!usedNonces[_nonce]);
        return getAddressFromSignatureHash(keccak256(abi.encodePacked(_from, _to, tokenId, newTokenId, serialNumber, _nonce)), signature);
    }
    
    function changeMetadataBaseUri(string calldata _uri) public onlyOwner {
        metadataBaseUri = _uri;
    }
    
    function transferNftOwnership(address _nftAddress, address newOwner) external onlyOwner {
        OwnableUpgradeable(_nftAddress).transferOwnership(newOwner);
    }

    function changeRecipient(address _recipient) public onlyOwner {
       recipientAddress = _recipient;
    }

    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function recoverSigner(bytes32 hash, bytes memory sig) internal pure returns (address) {
        require(sig.length == 65, "Require correct length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Signature version not match");

        return recoverSigner2(hash, v, r, s);
    }

    function recoverSigner2(bytes32 h, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, h));
        address addr = ecrecover(prefixedHash, v, r, s);

        return addr;
    }
    
    function uintToStr(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function version() public pure returns (uint256) {
        return 4;
    }
}