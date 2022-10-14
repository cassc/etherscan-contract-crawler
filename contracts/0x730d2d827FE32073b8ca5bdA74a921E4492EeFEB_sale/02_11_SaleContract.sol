// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./ISaleContract.sol";
import "../token/IToken.sol";
import "../extras/recovery/BlackHolePrevention.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

struct SaleConfiguration {
    uint256 projectID; 
    address token;
    address payable[] wallets;
    uint16[] shares;

    uint256 maxMintPerTransaction;      // How many tokens a transaction can mint
    uint256 maxPresale;                 // Max sold in presale across presale eth
    uint256 maxPresalePerAddress;       // Limit discounts per address
    uint256 maxSalePerAddress;

    uint256 presaleStart;
    uint256 presaleEnd;
    uint256 saleStart;
    uint256 saleEnd;

    uint256 fullPrice;
    address signer;
}

struct SaleInfo {
    SaleConfiguration config;
    uint256 _userMinted;
    uint256 _MaxUserMintable;
    bool    _presaleIsActive;
    bool    _saleIsActive;
}


contract SaleContract is ISaleContract, Ownable, BlackHolePrevention {
    using Strings  for uint256;

    uint256 immutable   public  projectID;
    IToken  immutable   public  token;

    address payable []  _wallets;
    uint16[]            _shares;
    uint256             _maxMintPerTransaction;
    uint256             _maxPresale;
    uint256             _maxMintPerAddress;
    uint256             _maxPresalePerAddress;
    uint256             _maxSalePerAddress;
    address             _projectSigner;
    uint256             _presaleStart;
    uint256             _presaleEnd;
    uint256             _saleStart;
    uint256             _saleEnd;
    uint256             _fullPrice;

    uint256 immutable   _MaxUserMintable;
    uint256             _userMinted;
    mapping(address => uint256) public _mintedByWallet;


    event PreSale(address _buyer, address _receiver, uint256 _number_of_items, uint256 _amount);
    event Sale   (address _buyer, address _receiver, uint256 _number_of_items, uint256 _amount);

    constructor(SaleConfiguration memory config) {

        require(config.projectID > 0, "Sale: Project id must be higher than 0");
        require(config.token != address(0), "Sale: Token address can not be address(0)");
 
        projectID = config.projectID;
        token = IToken(config.token);

        TokenInfoForSale memory tinfo = token.getTokenInfoForSale();
        require(config.projectID == tinfo._projectID, "Sale: Project id must match");

        // Calculate how many tokens can be minted through the sale contract by normal users
        _MaxUserMintable = tinfo._maxSupply - tinfo._reservedSupply;

        UpdateSaleConfiguration(config);

        UpdateWalletsAndShares(config.wallets, config.shares);
    }

    function UpdateSaleConfiguration(SaleConfiguration memory config) public onlyAllowed {

        // How many tokens a transaction can mint
        _maxMintPerTransaction = config.maxMintPerTransaction;

        // Number of tokens to be sold in presale 
        _maxPresale = config.maxPresale;

        // Limit presale mints per address
        _maxPresalePerAddress = config.maxPresalePerAddress;

        // Limit sale mints per address ( must include _maxPresalePerAddress value )
        _maxSalePerAddress = config.maxSalePerAddress;

        _presaleStart   = config.presaleStart;
        _presaleEnd     = config.presaleEnd;
        _saleStart      = config.saleStart;
        _saleEnd        = config.saleEnd;

        _fullPrice      = config.fullPrice;

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
     * @dev Admin mint tokens
     */
    function admin_mint(address _destination, uint8 _count) external onlyAllowed {
        _mintCards(_count, _destination);
    }
    
    /**
     * @dev Public Sale minting
     */
    function mint(uint256 _numberOfCards) external payable {
        _internalMint(_numberOfCards, msg.sender);
    }

    /**
     * @dev Public Sale cross mint
     */
    function crossmint(uint256 _numberOfCards, address _receiver) external payable {
        _internalMint(_numberOfCards, _receiver);
    }

    /**
     * @dev Public Sale minting
     */
    function _internalMint(uint256 _numberOfCards, address _receiver) internal {
        require(checkSaleIsActive(),                            "Sale: Sale is not open");
        require(_numberOfCards <= _maxMintPerTransaction,       "Sale: Over maximum number per transaction");

        uint256 number_of_items = msg.value / _fullPrice;
        require(number_of_items == _numberOfCards,              "Sale: ETH sent does not match items requested");
        require(number_of_items * _fullPrice == msg.value,      "Sale: Incorrect ETH amount sent");

        uint256 _sold = _mintedByWallet[_receiver];
        require(_sold < _maxSalePerAddress,                     "Sale: You have already minted your allowance");
        require(_sold + number_of_items <= _maxSalePerAddress,  "Sale: That would put you over your presale limit");
        _mintedByWallet[_receiver]+= number_of_items;

        _mintCards(number_of_items, _receiver);
        _split(msg.value);

        emit Sale(msg.sender, _receiver, number_of_items, msg.value);
    }


    /**
     * @dev Internal mint method
     */
    function _mintCards(uint256 numberOfCards, address recipient) internal {
        _userMinted+= numberOfCards;
        require(
            _userMinted <= _MaxUserMintable,
            "Sale: Exceeds maximum number of user mintable cards"
        );
        token.mintIncrementalCards(numberOfCards, recipient);
    }

    /**
     * @dev Mint tokens as specified in the signed payload
     */
    struct SignedPayload {
        uint256 projectID;
        uint256 chainID;  // 1 mainnet / 4 rinkeby / 11155111 sepolia / 137 polygon / 80001 mumbai
        bool free;
        uint16 max_mint;
        address receiver;
        uint256 valid_from;
        uint256 valid_to;
        uint256 eth_price;
        uint256 dust_price;
        bytes signature;
    }

    function mint_approved(SignedPayload memory _payload, uint256 _numberOfCards) external payable {

        require(_numberOfCards <= _maxMintPerTransaction, "Sale: Over maximum number per transaction");
        require(_numberOfCards + _userMinted <= _maxPresale, "Sale: Presale maximum reached");

        // Make sure it can only be called if presale is active
        require(checkPresaleIsActive(), "Sale: Presale is not active");

        // First make sure the received payload was signed by _projectSigner
        require(verify(_payload), "Sale: SignedPayload verification failed");

        // Make sure that msg.sender is actually the intended receiver
        require(_payload.receiver == msg.sender, "Sale Verify: Invalid receiver");

        // Make sure that payload.projectID matches
        require(_payload.projectID == projectID, "Sale Verify: Invalid projectID");

        // Make sure that payload.chainID matches
        require(_payload.chainID == block.chainid, "Sale Verify: Invalid chainID");

        // Make sure in date range
        require(_payload.valid_from < _payload.valid_to, "Sale: Invalid from/to range in payload");
        require(
            getBlockTimestamp() >= _payload.valid_from &&
            getBlockTimestamp() <= _payload.valid_to,
            "Sale: Contract time outside from/to range"
        );

        uint256 number_of_items = msg.value / _payload.eth_price;
        require(number_of_items == _numberOfCards, "Sale: ETH sent does not match items requested");
        require(number_of_items * _payload.eth_price == msg.value, "Sale: Incorrect ETH amount sent");

        uint256 _presold = _mintedByWallet[msg.sender];
        require(_presold < _payload.max_mint, "Sale: You have already minted your allowance");
        require(_presold + number_of_items <= _payload.max_mint, "Sale: That would put you over your presale limit");

        _mintedByWallet[msg.sender]+= number_of_items;

        // Cards will be minted into the specified receiver
        _mintCards(number_of_items, msg.sender);
        _split(msg.value);

        emit PreSale(msg.sender, msg.sender, number_of_items, msg.value);
    }

    /**
     * @dev Verify signed payload
     */
    function verify(SignedPayload memory info) public view returns (bool) {
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
     * @dev Is presale active?
     */
    function checkPresaleIsActive() public view returns (bool) {
        if ( (_presaleStart <= getBlockTimestamp()) && (_presaleEnd >= getBlockTimestamp())) {
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
        _split(msg.value);
    }

    /**
     * @dev Internal output splitter
     */
    function _split(uint256 amount) internal {
        bool sent;
        uint256 _total;

        for (uint256 j = 0; j < _wallets.length; j++) {
            uint256 _amount = (amount * _shares[j]) / 10000;
            if (j == _wallets.length - 1) {
                _amount = amount - _total;
            } else {
                _total += _amount;
            }
            (sent,) = _wallets[j].call{value: _amount}("");
            require(sent, "Sale: Splitter failed to send ether");
        }
    }

    modifier onlyAllowed() {
        require(token.isAllowed(msg.sender) || msg.sender == owner(), "Sale: Unauthorised");
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
                _maxPresale,
                _maxPresalePerAddress,
                _maxSalePerAddress,
                _presaleStart,
                _presaleEnd,
                _saleStart,
                _saleEnd,
                _fullPrice,
                _projectSigner
            ),
            _userMinted,
            _MaxUserMintable,
            checkPresaleIsActive(),
            checkSaleIsActive()
        );
    }

    function getBlockTimestamp() public view virtual returns(uint256) {
        return block.timestamp;
    }
}