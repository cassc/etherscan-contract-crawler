//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./RENRoyalties.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";

import { GelatoRelayContext } from "@gelatonetwork/relay-context/contracts/GelatoRelayContext.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract RACINGSHOE5 is ERC721A, Ownable
, EIP712
, RENRoyalties
, RevokableDefaultOperatorFilterer
, GelatoRelayContext
, AccessControl
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    //Base uri
    string private baseURI;

    //Open sea metadata URI
    string private _contract_uri = 'undefined';

    bool _gelatoActive;
    uint256 private _maxByOwner;

    uint256 constant MAX_SUPPLY = 960;

    string private constant SIGNING_DOMAIN = "RACINGSHOE5-Voucher";
    string private constant SIGNATURE_VERSION = "1";

    uint256 pendingWithdrawals;
    uint256 minimumFundToKeep;
    mapping(uint256 => bool) private _vouchersUsed;

    constructor(         uint256 bps
        ) ERC721A('RACING SHOE5', 'RACINGSHOE5')         RENRoyalties(bps)
         EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {
        _maxByOwner = 6;
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(WITHDRAWER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _gelatoActive = true;    }

    function setContractURI(string memory uri) external onlyOwner {
        _contract_uri = uri;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    /**
        * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
        * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
        * by default, can be overridden in child contracts.
    */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //Open Sea meta-data
    function contractURI() external view returns (string memory) {
            return _contract_uri;
    }

    function setMaxByOwner(uint256 max) external onlyOwner {
        _maxByOwner = max;
    }

    function _beforeTokenTransfers(address, address to, uint256, uint256 quantity) internal virtual override{      if (to != address(0) && !hasRole(MINTER_ROLE, to))
          require(balanceOf(to) + quantity <= _maxByOwner, "maxByOwner reached");
    }
    function setGelatoActive(bool active) external onlyOwner {
        _gelatoActive = active;
    }
    //Setup Royalties
	function setupRoyalties(address addr, uint256 bps) external onlyOwner {
	    super.setRoyalties(addr, bps);
	}

    //Mint 'quantity' tokens
    function mint(address to, uint256 quantity) public {        require(hasRole(MINTER_ROLE, _msgSender()), "only minter can mint");
        
        require(_totalMinted() + quantity > _totalMinted() && _totalMinted() + quantity <= MAX_SUPPLY, "MAX_SUPPLY reached");
        
        _mint(to, quantity);
    }

    struct NFTVoucher {
        uint256 voucherId;
        uint256 quantity;
        uint256 minPrice;
        bytes   signature;
    }

    function redeem(address redeemer, NFTVoucher calldata voucher) external payable {
        require(!_vouchersUsed[voucher.voucherId], "Voucher already used");
        _vouchersUsed[voucher.voucherId] = true;
    
        // make sure signature is valid and get the address of the signer
        address signer = _verify(voucher);
    
        // make sure that the signer is authorized to mint NFTs
            require(hasRole(MINTER_ROLE, signer), "Signature invalid or unauthorized");
    
        // make sure that the redeemer is paying enough to cover the buyer's cost
        require(msg.value >= voucher.minPrice, "Insufficient funds to redeem");
    
        require(_totalMinted() + voucher.quantity > _totalMinted() && _totalMinted() + voucher.quantity <= MAX_SUPPLY, "MAX_SUPPLY reached");
    
        // mint to redeemer
        _mint(redeemer, voucher.quantity);
    
        // record payment to withdrawal balance
        pendingWithdrawals += msg.value;
    }

    function redeemWithGelato(address redeemer, NFTVoucher calldata voucher) external payable onlyGelatoRelay {
            require(_gelatoActive, "Gelato is not active");
        require(!_vouchersUsed[voucher.voucherId], "Voucher already used");
        _vouchersUsed[voucher.voucherId] = true;
    
        // make sure signature is valid and get the address of the signer
        address signer = _verify(voucher);
    
        // make sure that the signer is authorized to mint NFTs
            require(hasRole(MINTER_ROLE, signer), "Signature invalid or unauthorized");
    
        // make sure that the redeemer is paying enough to cover the buyer's cost
        require(msg.value >= voucher.minPrice, "Insufficient funds to redeem");
        require(pendingWithdrawals + msg.value >= _getFee(), "Not enough funds to pay Gelato");
    
        require(_totalMinted() + voucher.quantity > _totalMinted() && _totalMinted() + voucher.quantity <= MAX_SUPPLY, "MAX_SUPPLY reached");
    
        //Payment to gelato
        _transferRelayFee();
    
        // mint to redeemer
        _mint(redeemer, voucher.quantity);
    
        // record payment to withdrawal balance
        pendingWithdrawals += msg.value;
        pendingWithdrawals -= _getFee();
    }

    //Default receive
    receive() external payable {
       pendingWithdrawals += msg.value;
    }

    function setMinimumFundToKeep(uint amount) external onlyOwner {
       minimumFundToKeep = amount;
    }

    function availableToWithdraw() public view returns (uint256) {
        if (msg.sender == owner()) 
            return pendingWithdrawals;
        else if (pendingWithdrawals > minimumFundToKeep) return pendingWithdrawals - minimumFundToKeep;
        else return 0;
    }

    /// @notice Transfers pending withdrawal balance to the caller. Reverts if the caller is not an authorized withdrawer.
    function withdraw(uint amount) public {
        require(hasRole(WITHDRAWER_ROLE, msg.sender), "Only authorized withdrawers can withdraw");
        require(amount <= availableToWithdraw(), "Too much amount to withdraw");
    
        // IMPORTANT: casting msg.sender to a payable address is only safe if ALL members of the withdrawer role are payable addresses.
        address payable receiver = payable(msg.sender);
    
        pendingWithdrawals -= amount;
        receiver.transfer(amount);
    }
    
    /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
    /// @param voucher An NFTVoucher to hash.
    function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("NFTVoucher(uint256 voucherId,uint256 quantity,uint256 minPrice)"),
            voucher.voucherId,
            voucher.quantity,
            voucher.minPrice
        )));
    }

    /// @notice Returns the chain id of the current blockchain.
    /// @dev This is used to workaround an issue with ganache returning different values from the on-chain chainid() function and
    ///  the eth_chainId RPC method. See https://github.com/protocol/nft-website/issues/121 for context.
    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /// @notice Verifies the signature for a given NFTVoucher, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
    /// @param voucher An NFTVoucher describing an unminted NFT.
    function _verify(NFTVoucher calldata voucher) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A
    ,RENRoyalties
    ,AccessControl
    )
    returns (bool) {
        return ERC721A.supportsInterface(interfaceId)
    || RENRoyalties.supportsInterface(interfaceId)
    || AccessControl.supportsInterface(interfaceId)
    ;
    }


    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner() public view virtual override (Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }}