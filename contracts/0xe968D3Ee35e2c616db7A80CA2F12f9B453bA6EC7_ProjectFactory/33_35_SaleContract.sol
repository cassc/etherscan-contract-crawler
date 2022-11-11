// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./ISaleContract.sol";
import "../token/IToken.sol";
import "../extras/recovery/BlackHolePrevention.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract SaleContract is AccessControlEnumerable, ISaleContract, Ownable, BlackHolePrevention {
    using Strings  for uint256;

    uint256             public  projectID;
    IToken              public  token;

    address payable []  _wallets;
    uint16[]            _shares;
    uint256             _maxMintPerTransaction;
    uint256             _maxApprovedSale;
    uint256             _maxMintPerAddress;
    uint256             _maxApprovedSalePerAddress;
    uint256             _maxSalePerAddress;
    address             _projectSigner;
    uint256             _approvedsaleStart;
    uint256             _approvedsaleEnd;
    uint256             _saleStart;
    uint256             _saleEnd;
    uint256             _fullPrice;
    uint256             _fullDustPrice;    
    bool                _ethSaleEnabled;    
    bool                _erc777SaleEnabled;    
    address             _erc777tokenAddress;

    uint256             _maxUserMintable;
    uint256             _userMinted;
    mapping(address => uint256) public _mintedByWallet;

    bool                _initialized;

    event ApprovedPayloadSale(address _buyer, address _receiver, uint256 _number_of_items, uint256 _amount);
    event ApprovedTokenPayloadSale(address _buyer, address _receiver, uint256 _number_of_items, uint256 _amount);

    event ETHSale(address _buyer, address _receiver, uint256 _number_of_items, uint256 _amount);
    event TokenSale(address _buyer, address _receiver, uint256 _number_of_items, uint256 _amount);

    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    IERC1820Registry internal constant _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    uint8 constant TRANSFER_TYPE_ETH = 1;
    uint8 constant TRANSFER_TYPE_ERC20 = 2;
    uint8 constant TRANSFER_TYPE_ERC677 = 3;
    uint8 constant TRANSFER_TYPE_ERC777 = 4;

    uint8 constant BUY_TYPE_APSALE = 1;
    uint8 constant BUY_TYPE_SALE = 2;

    function setup(SaleConfiguration memory config) public onlyOwner {
        require(!_initialized, "Sale: Contract already initialized");
        require(config.projectID > 0, "Sale: Project id must be higher than 0");
        require(config.token != address(0), "Sale: Token address can not be address(0)");
 
        projectID = config.projectID;
        token = IToken(config.token);

        TokenInfoForSale memory tinfo = token.getTokenInfoForSale();
        require(config.projectID == tinfo.projectID, "Sale: Project id must match");

        UpdateSaleConfiguration(config);
        UpdateWalletsAndShares(config.wallets, config.shares);

        // register with erc1820 registry so we can receive ERC777 tokens
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));

        _initialized = true;
    }

    function UpdateSaleConfiguration(SaleConfiguration memory config) public onlyAllowed {

        // How many tokens a transaction can mint
        _maxMintPerTransaction = config.maxMintPerTransaction;

        // Number of tokens to be sold in approvedsale 
        _maxApprovedSale = config.maxApprovedSale;

        // Limit approvedsale mints per address
        _maxApprovedSalePerAddress = config.maxApprovedSalePerAddress;

        // Limit sale mints per address ( must include _maxApprovedSalePerAddress value )
        _maxSalePerAddress = config.maxSalePerAddress;

        _approvedsaleStart  = config.approvedsaleStart;
        _approvedsaleEnd    = config.approvedsaleEnd;
        _saleStart          = config.saleStart;
        _saleEnd            = config.saleEnd;

        _fullPrice          = config.fullPrice;
        _fullDustPrice      = config.fullDustPrice;
        _ethSaleEnabled     = config.ethSaleEnabled;
        _erc777SaleEnabled  = config.erc777SaleEnabled; 
        _erc777tokenAddress = config.erc777tokenAddress; 

        // if provided use it.
        if(config.maxUserMintable > 0) {
            _maxUserMintable = config.maxUserMintable;
        } else {
            // Calculate how many tokens can be minted through the sale contract by normal users
            TokenInfoForSale memory tinfo = token.getTokenInfoForSale();
            _maxUserMintable = tinfo.maxSupply - tinfo.reservedSupply;
        }

        // Signed data signer address
        _projectSigner = config.signer;
    }

    /**
     * @dev Admin: Update wallets and shares
     */
    function UpdateWalletsAndShares(
        address payable[] memory _newWallets,
        uint16[] memory _newShares
    ) public onlyAllowed {
        require(_newWallets.length == _newShares.length && _newWallets.length > 0, "Sale: Must have at least 1 output wallet");
        uint16 totalShares = 0;
        for (uint8 j = 0; j < _newShares.length; j++) {
            totalShares+= _newShares[j];
        }
        require(totalShares == 10000, "Sale: Shares total must be 10000");
        _shares = _newShares;
        _wallets = _newWallets;
    }

    /**
     * @dev Public Sale minting
     */
    function mint(uint256 _numberOfCards) external payable {
        _internalMint(_numberOfCards, msg.sender, msg.value, TRANSFER_TYPE_ETH);
    }

    /**
     * @dev Public Sale cross mint
     */
    function crossmint(uint256 _numberOfCards, address _receiver) external payable {
        _internalMint(_numberOfCards, _receiver, msg.value, TRANSFER_TYPE_ETH);
    }

    /**
     * @dev Public Sale minting
     */
    function _internalMint(uint256 _numberOfCards, address _receiver, uint256 _value, uint8 _section) internal {
        require(checkSaleIsActive(),                            "Sale: Sale is not open");
        require(_numberOfCards <= _maxMintPerTransaction,       "Sale: Over maximum number per transaction");

        uint256 checkPrice = 0;
        uint8 transferType = 0;
        if(_section == TRANSFER_TYPE_ETH) {
            require(_ethSaleEnabled,                            "Sale: ETH Sale is not enabled");
            checkPrice = _fullPrice;
            transferType = TRANSFER_TYPE_ETH;
        } else {
            require(_erc777SaleEnabled,                           "Sale: Token Sale is not enabled");
            checkPrice = _fullDustPrice;
            transferType = TRANSFER_TYPE_ERC20;
        }
        
        uint256 number_of_items = _value / checkPrice;
        require(number_of_items == _numberOfCards,              "Sale: Value sent does not match items requested");
        require(number_of_items * checkPrice == _value,         "Sale: Incorrect amount sent");

        uint256 _sold = _mintedByWallet[_receiver];
        require(_sold < _maxSalePerAddress,                     "Sale: You have already minted your allowance");
        require(_sold + number_of_items <= _maxSalePerAddress,  "Sale: That would put you over your approvedsale limit");
        _mintedByWallet[_receiver]+= number_of_items;

        _mintCards(number_of_items, _receiver);
        _split(_value, transferType);

        if(_section == TRANSFER_TYPE_ETH) {
            emit ETHSale(msg.sender, _receiver, number_of_items, _value);
        } else {
            emit TokenSale(msg.sender, _receiver, number_of_items, _value);
        }
    }

    /**
    * ERC677Receiver
    */
    function onTokenTransfer(address from, uint amount, bytes calldata userData) external {
        checkReceivedTokens(from, amount, userData);
    }

    /**
    * ERC777Receiver
    */
    function tokensReceived(
        address ,
        address from,
        address ,
        uint256 amount,
        bytes calldata userData,
        bytes calldata
    ) external {
        checkReceivedTokens(from, amount, userData);
    }

    function checkReceivedTokens(address from, uint amount, bytes memory userData) internal {

        require(_erc777tokenAddress == msg.sender, "Invalid token received");

        // Decode userData tokenPayload(uint256, SaleSignedPayload) manually 
        // because solidity doesn't support nested structs
        // 
        // will not work:  tokenPayload memory receivedTokenPayload  = abi.decode(userData, (tokenPayload));

        (uint8 buyType, uint256 numberOfCards, SaleSignedPayload memory payload) = abi.decode(userData, (uint8, uint256, SaleSignedPayload));
        
        if(buyType == BUY_TYPE_APSALE) {

            // Make sure that from is actually the intended receiver
            require(payload.receiver == from, "Payload Verify: Invalid receiver");

            verify_payload_rules(payload, amount, numberOfCards, TRANSFER_TYPE_ERC20);

            _mintedByWallet[payload.receiver]+= numberOfCards;

            // Cards will be minted into the specified receiver
            _mintCards(numberOfCards, payload.receiver);
            
            if(!payload.free) {
                _split(amount, TRANSFER_TYPE_ERC20);
            }

            emit ApprovedTokenPayloadSale(from, from, numberOfCards, amount);

        } else if(buyType == BUY_TYPE_SALE) {
            _internalMint(numberOfCards, from, amount, TRANSFER_TYPE_ERC20);
            emit TokenSale(from, from, numberOfCards, amount);
        }
    }

    /**
     * @dev Internal mint method
     */
    function _mintCards(uint256 numberOfCards, address recipient) internal {
        _userMinted+= numberOfCards;
        require(
            _userMinted <= _maxUserMintable,
            "Sale: Exceeds maximum number of user mintable cards"
        );
        token.mintIncrementalCards(numberOfCards, recipient);
    }

    function verify_payload_rules(SaleSignedPayload memory _payload, uint256 _value, uint256 _numberOfCards, uint8 _section) internal view {

        require(_numberOfCards <= _maxMintPerTransaction, "APSale: Over maximum number per transaction");
        require(_numberOfCards + _userMinted <= _maxApprovedSale, "APSale: ApprovedSale maximum reached");

        // Make sure it can only be called if approvedsale is active
        require(checkApprovedSaleIsActive(), "APSale: ApprovedSale is not active");

        // First make sure the received payload was signed by _projectSigner
        require(verify(_payload), "APSale: SignedPayload verification failed");

        // Make sure that payload.projectID matches
        require(_payload.projectID == projectID, "APSale Verify: Invalid projectID");

        // Make sure that payload.chainID matches
        require(_payload.chainID == block.chainid, "APSale Verify: Invalid chainID");

        // Make sure in date range
        require(_payload.valid_from < _payload.valid_to, "APSale: Invalid from/to range in payload");
        require(
            getBlockTimestamp() >= _payload.valid_from &&
            getBlockTimestamp() <= _payload.valid_to,
            "APSale: Contract time outside from/to range"
        );

        uint256 number_of_items = 0;
        if(_payload.free) {
            number_of_items = _numberOfCards;
            require(_value == 0, "APSale: value needs to be 0");
        } else {

            uint256 checkPrice = 0;
            if(_section == TRANSFER_TYPE_ETH) {
                checkPrice = _payload.eth_price;
            } else {
                // } else if(_section == TRANSFER_TYPE_ERC20) {
                checkPrice = _payload.dust_price;
            }
            
            number_of_items = _value / checkPrice;
            require(number_of_items == _numberOfCards, "APSale: Value sent does not match items requested");
            require(number_of_items * checkPrice == _value, "APSale: Incorrect amount sent");
        }

        uint256 _presold = _mintedByWallet[_payload.receiver];
        require(_presold < _payload.max_mint, "APSale: You have already minted your allowance");
        require(_presold + number_of_items <= _payload.max_mint, "APSale: That would put you over your approvedsale limit");

    }

    /**
     * @dev Mint tokens as specified in the signed payload
     */

    function mint_approved(SaleSignedPayload memory _payload, uint256 _numberOfCards) external payable {

        // Make sure that msg.sender is actually the intended receiver
        require(_payload.receiver == msg.sender, "APSale Verify: Invalid receiver");

        verify_payload_rules(_payload, msg.value, _numberOfCards, TRANSFER_TYPE_ETH);

        _mintedByWallet[msg.sender]+= _numberOfCards;

        // Cards will be minted into the specified receiver
        _mintCards(_numberOfCards, msg.sender);
        
        if(!_payload.free) {
            _split(msg.value, TRANSFER_TYPE_ETH);
        }

        emit ApprovedPayloadSale(msg.sender, msg.sender, _numberOfCards, msg.value);
    }

    /**
     * @dev Verify signed payload
     */
    function verify(SaleSignedPayload memory info) public view returns (bool) {
        require(info.signature.length == 65, "Sale Verify: Invalid signature length");

        bytes memory encodedPayload = abi.encode(
            info.projectID,
            info.chainID,
            info.free,
            info.max_mint,
            info.receiver,
            info.valid_from,
            info.valid_to,
            info.eth_price,
            info.dust_price
        );

        bytes32 hash = keccak256(encodedPayload);

        bytes32 sigR;
        bytes32 sigS;
        uint8 sigV;
        bytes memory signature = info.signature;
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        assembly {
            sigR := mload(add(signature, 0x20))
            sigS := mload(add(signature, 0x40))
            sigV := byte(0, mload(add(signature, 0x60)))
        }

        bytes32 data = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address recovered = ecrecover(data, sigV, sigR, sigS);
        return recovered == _projectSigner;
    }

    /**
     * @dev Is approvedsale active?
     */
    function checkApprovedSaleIsActive() public view returns (bool) {
        if ( (_approvedsaleStart <= getBlockTimestamp()) && (_approvedsaleEnd >= getBlockTimestamp())) {
            return true;
        }
        return false;
    }

    /**
     * @dev Is sale active?
     */
    function checkSaleIsActive() public view returns (bool) {
        if ((_saleStart <= getBlockTimestamp()) && (_saleEnd >= getBlockTimestamp())) {
            return true;
        }
        return false;
    }

    /**
     * @dev Royalties splitter
     */
    receive() external payable {
        _split(msg.value, TRANSFER_TYPE_ETH);
    }

    /**
     * @dev Internal output splitter
     */
    function _split(uint256 amount, uint8 transferType) internal {
        bool sent;
        uint256 _total;

        for (uint256 j = 0; j < _wallets.length; j++) {
            uint256 _amount = (amount * _shares[j]) / 10000;
            if (j == _wallets.length - 1) {
                _amount = amount - _total;
            } else {
                _total += _amount;
            }
            
            if(transferType == TRANSFER_TYPE_ETH) {
                (sent,) = _wallets[j].call{value: _amount}("");
                require(sent, "Sale: Splitter failed to send ether");
            }
            else if(transferType == TRANSFER_TYPE_ERC20) {
                // (sent,) = _wallets[j].call{value: _amount}("");
                // require(sent, "Sale: Splitter failed to send ether");
            }
            else if(transferType == TRANSFER_TYPE_ERC677) {

            }
            else if(transferType == TRANSFER_TYPE_ERC777) {

            }
        }
    }

    modifier onlyAllowed() { 
        require( msg.sender == owner() || token.isAllowed(token.TOKEN_CONTRACT_ACCESS_SALE(), msg.sender), "Sale: Unauthorised");
        _;
    }
 
    function tellEverything() external view returns (SaleInfo memory) {
        
        return SaleInfo(
            SaleConfiguration(
                projectID,
                address(token),
                _wallets,
                _shares,
                _maxMintPerTransaction,
                _maxApprovedSale,
                _maxApprovedSalePerAddress,
                _maxSalePerAddress,
                _approvedsaleStart,
                _approvedsaleEnd,
                _saleStart,
                _saleEnd,
                _fullPrice,
                _maxUserMintable,
                _projectSigner,
                _fullDustPrice,
                _ethSaleEnabled,
                _erc777SaleEnabled,
                _erc777tokenAddress
            ),
            _userMinted,
            checkApprovedSaleIsActive(),
            checkSaleIsActive()
        );
    }

    function getBlockTimestamp() public view virtual returns(uint256) {
        return block.timestamp;
    }
}