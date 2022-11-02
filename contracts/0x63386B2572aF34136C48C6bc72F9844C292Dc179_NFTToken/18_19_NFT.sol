// SPDX-License-Identifier: none
pragma solidity ^0.8.16;

import './erc721a/ERC721AUpgradeable.sol';
import './erc721a/IERC721AUpgradeable.sol';
import './erc721a/extensions/ERC721AQueryableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { IProxyRegistry } from "./ProxyRegistry.sol";

interface INFTToken is IERC721AUpgradeable {
	function exists(uint256 tokenId) external view returns (bool);
    function mintOperator(uint256 startTokenId, uint56 quantity, address recipient) external;
}

contract NFTToken is INFTToken, ERC721AUpgradeable, ERC721AQueryableUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;  
    
    // ---------------- STATE -----------------

    address public bridge;    
    address payable public wallet;
    address public signer;
    address public proxyRegistry;
    string public baseURI;
    bool public publicSale;
    bool public whiteListSale;
    uint256 publicPrice; 
    uint256 whiteListPrice;    
    mapping(address => bool) public operators;
    
    // ---------------- INIT -----------------

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseUri_,
        address payable wallet_,
        address signer_,
        uint256 initialMintQuantity_
    ) initializerERC721A initializer public {
        __ERC721A_init(name_, symbol_);
        __Ownable_init();
        __Pausable_init();

        setWallet(wallet_);
        setSigner(signer_);
        setBaseURI(baseUri_);

        if (initialMintQuantity_ != 0) _mintERC2309(msg.sender, initialMintQuantity_);
    }

    // ---------------- CONFIG -----------------
    
    function setBridge(address bridge_) public onlyOwner {
        require(bridge == address(0), 'Already set');

        bridge = bridge_;
        emit BridgeSet(bridge);
	}

    function setWallet(address payable wallet_) public onlyOwner {
        wallet = wallet_;
        emit WalletSet(wallet);
	}

    function setSigner(address signer_) public onlyOwner {
        signer = signer_;
        emit SignerSet(signer);
	}

    function setBaseURI(string memory baseUri_) public onlyOwner {
        baseURI = baseUri_;
        emit BaseURISet(baseUri_);
	}

    function setPublic(bool publicSale_, uint256 publicPrice_) public onlyOwner {
        publicSale = publicSale_;
        publicPrice = publicPrice_;
        emit PublicSet(publicSale, publicPrice);
	}

    function setWhiteList(bool whiteListSale_, uint256 whiteListPrice_) public onlyOwner {
        whiteListSale = whiteListSale_;
        whiteListPrice = whiteListPrice_;
        emit WhiteListSet(whiteListSale, whiteListPrice);
	}

    function blackListAccounts(address[] memory accounts_, bool[] memory states_) external onlyOwner {
		for (uint8 index = 0; index < accounts_.length; index++) {
            address account = accounts_[index];
            bool state = states_[index];

            (uint56 quantity,) = _getAccountAuxilarity(account);
            _setAccountAuxilarity(account, quantity, state);

            emit BlackListed(account, state);
        }
	}

    function setPaused(bool state_) public onlyOwner {
        require(state_ != paused(), 'Already set');        
        state_ ? _pause() : _unpause();        
	}

    function setOperator(address operator_, bool state_) public onlyOwner {
        require(state_ != operators[operator_], 'Already set');
        operators[operator_] = state_;
        emit OperatorSet(operator_, state_);     
	}

    function setProxyRegistry(address proxyRegistry_) public onlyOwner {
        proxyRegistry = proxyRegistry_;
        emit ProxyRegistrySet(proxyRegistry);  
	}

    function whiteListAccounts(address[] memory accounts_, uint56[] memory quantities_) external onlyOwner {
		for (uint256 index = 0; index < accounts_.length; index++) {
            address account = accounts_[index];
            uint56 quantity = quantities_[index];
            
            (, bool blackListed) = _getAccountAuxilarity(account);
            _setAccountAuxilarity(account, quantity, blackListed);
            
            emit WhiteListed(account, quantity);
        }
	}
        
    // ---------------- VIEWS -----------------

    struct AccountData {
        uint56 balance;
		uint256[] tokens;
        uint56 whiteListQuantity;
        bool blackListed;
    }
    function aggregatedData(address account) public view returns (
		// contract data
        string memory _name,
        string memory _symbol,
        string memory _baseUri,        
        uint256 _totalSupply,
        bool _publicSale,
        bool _whiteListSale,
        bool _bridging,
        uint256 _publicPrice,
        uint256 _whiteListPrice,
        // account data        
		AccountData memory _accountData        
    ) {
        _name = name();
        _symbol = symbol();
        _baseUri = baseURI;
		_totalSupply = totalSupply();
        _publicSale = publicSale;
        _whiteListSale = whiteListSale;
        _bridging = bridge != address(0);
        _publicPrice = publicPrice;
        _whiteListPrice = whiteListPrice;

        _accountData.balance = uint56(balanceOf(account));        
        _accountData.tokens = tokensOfOwner(account);
        (_accountData.whiteListQuantity, _accountData.blackListed) = _getAccountAuxilarity(account);              
	}
    
    function exists(uint256 tokenId_) external view returns (bool) {
        return _exists(tokenId_);
    }   

    function isApprovedForAll(address owner_, address operator_) public view virtual override(IERC721AUpgradeable, ERC721AUpgradeable) returns (bool) {
        if (proxyRegistry != address(0) && IProxyRegistry(proxyRegistry).proxies(owner_) == operator_) return true;
		if (operators[operator_]) return true;
		return super.isApprovedForAll(owner_, operator_);
    } 
             
    // ---------------- PUBLIC -----------------

    function mint(uint56 quantity_) external payable {
        require(bridge == address(0), 'Not allowed');
        _mintSale(quantity_);
    }

    function mintOperator(uint256 startTokenId_, uint56 quantity_, address recipient_) external {
        require(msg.sender == bridge || operators[msg.sender], 'Not allowed');

        if (startTokenId_ > _nextTokenId()) {
            _mint(bridge, startTokenId_ - _nextTokenId());                       
        } 
        _mint(recipient_, quantity_);
    }

    struct MintData {
        uint128 startTokenId;
        uint56 quantity;
        uint64 txDeadline;
    }
    function mintSigned(MintData calldata mintData_, bytes calldata signatureServer_, bytes calldata signatureUser_) external payable {
        require(bridge != address(0), 'Not bridging');
        require(_isSignatureValid(signatureServer_, keccak256(abi.encode(mintData_)), signer), 'Bad server signature');
        require(_isSignatureValid(signatureUser_, keccak256(abi.encode(mintData_)), msg.sender), 'Bad user signature');
        require(mintData_.txDeadline >= block.timestamp, 'Time past');

        if (mintData_.startTokenId > _nextTokenId()) {
            _mint(bridge, mintData_.startTokenId - _nextTokenId());                       
        } 
        _mintSale(mintData_.quantity);        
    }

    // ---------------- INTERNAL -----------------

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    function _getAccountAuxilarity(address account_) internal view returns (uint56 _whiteListQuantity, bool _blackListed) {
        uint64 aux = _getAux(account_);        
        _whiteListQuantity = uint56(aux >> 56);        
        _blackListed = uint8(aux) == 1 ? true : false;        
    }

    function _setAccountAuxilarity(address account_, uint56 whiteListQuantity_, bool blackListed_) internal {
        _setAux(account_, (uint64(whiteListQuantity_) << 56) | uint64(blackListed_ ? 1 : 0));
    }

    function _beforeTokenTransfers(
        address from_,
        address to_,
        uint256,
        uint256
    ) internal override view {
        (, bool blackListedFrom) = _getAccountAuxilarity(from_);
        (, bool blackListedTo) = _getAccountAuxilarity(to_);
        require(!blackListedFrom, 'Sender black listed');   
        require(!blackListedTo, 'Recipient black listed');     
    }

    function _mintSale(uint56 quantity_) internal whenNotPaused {
        require(whiteListSale || publicSale, 'Sale not started'); 
        require(quantity_ != 0, 'Zero quantity'); 
        
        if (whiteListSale) {
            (uint56 whiteListQuantity, bool blackListed) = _getAccountAuxilarity(msg.sender);
            
            require(whiteListQuantity >= quantity_, 'Max Tokens');              
            require(msg.value == quantity_ * whiteListPrice, 'Wrong ETH value');  

            whiteListQuantity -= quantity_;
            _setAccountAuxilarity(msg.sender, whiteListQuantity, blackListed);            
        } else {
            require(msg.value == quantity_ * publicPrice, 'Wrong ETH value'); 
        } 
        
        if (wallet != address(0)) {
            (bool success, ) = wallet.call{ value: msg.value }('');
			require(success, 'ETH Not Sent'); 
        }

        _mint(msg.sender, quantity_);
    }

    function _isSignatureValid(
		bytes memory signature_,
		bytes32 dataHash_,
        address signer_
	) internal pure returns (bool) {
		return ECDSAUpgradeable.recover(ECDSAUpgradeable.toEthSignedMessageHash(dataHash_), signature_) == signer_;
	}

    // ---------------- RECOVER -----------------

    function recover(
		address token_,
		uint256 amount_,
		address recipient_,
        bool nft
    ) external onlyOwner {
        if (nft) {
            IERC721AUpgradeable(token_).safeTransferFrom(address(this), recipient_, amount_);
        } else if (token_ != address(0)) {
			IERC20Upgradeable(token_).safeTransfer(recipient_, amount_);
		} else {
			(bool success, ) = recipient_.call{ value: amount_ }('');
			assert(success); 
		}
		emit Recover(token_, amount_, recipient_, nft);		
	}

    // ---------------- EVENTS -----------------

    event BridgeSet(address bridge);
    event WalletSet(address wallet);
    event SignerSet(address signer);
    event OperatorSet(address operator, bool state);
    event ProxyRegistrySet(address proxyRegistry);
    event BaseURISet(string baseUri);    
    event PublicSet(bool publicSale, uint256 publicPrice);
    event WhiteListSet(bool whiteListSale, uint256 whiteListPrice);
    event BlackListed(address account, bool state);
    event WhiteListed(address account, uint256 quantity);    
    event Recover(address token, uint256 amount, address recipient, bool nft);
      
}