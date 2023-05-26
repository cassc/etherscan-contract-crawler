// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface ICanonicon {
    function balanceOf(address owner) external view returns (uint256);
}

contract SocialContracts is ERC721 {

    /// ============ Events ============de

    event MetadataUpdate(uint256 tokenId);
    event PaymentReleased(address to, uint256 amount);

    /// ============ Mutable storage ============

    mapping (uint256 => address[]) public provenance;
    mapping(address => uint256) public addressMintedBalance;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    mapping(address => uint256) private _splitBalances;
    mapping(address => uint256) private _released;
    mapping(address => bool) private sanctionedAddresses;

    /// ============ Immutable storage ============

    string private baseuri;
    // uint256 immutable public totalSupply;
    uint256 immutable public mintEndsAt;
    uint256 immutable public mintFee;
    address payable feeAddress;
    uint8 immutable public mintPerAddressLimit;
    uint256 immutable public mintFeeDiscounted;
    ICanonicon canoniconContract;
    uint256 immutable public splitRate;
    address payable splitAddress;

    /// ============ Constructor ============

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        string memory _baseuri,
        // uint256 _totalSupply,
        uint256 _mintEndsAt,
        uint256 _mintFee,
        address payable _feeAddress,
        uint8 _mintPerAddressLimit,
        uint256 _mintFeeDiscounted,
        address _canoniconContract,
        uint256 _splitRate,
        address payable _splitAddress
    ) ERC721(
        tokenName,
        tokenSymbol
    ) {
        // require(_totalSupply > 0, "_totalSupply cannot be 0");
        require(_mintEndsAt > block.timestamp, "mintEndsAt cannot be earlier than current block time");
        require(_mintFee > 0, "mintFee cannot be 0");
        require(_feeAddress != address(0), "feeAddress cannot be null address");
        require(_mintPerAddressLimit > 0, "mintPerAddressLimit cannot be 0");
        require(_mintFeeDiscounted > 0, "mintFeeDiscounted cannot be 0");
        require(_canoniconContract != address(0), "canoniconContractAddress cannot be null address");
        require(_splitAddress != address(0), "splitAddress cannot be null address");
        require(_splitRate <= 100, "splitRate too high");

        baseuri = _baseuri;
        // totalSupply = _totalSupply;
        mintEndsAt = _mintEndsAt;
        mintFee = _mintFee;
        feeAddress = _feeAddress;
        mintPerAddressLimit = _mintPerAddressLimit;
        mintFeeDiscounted = _mintFeeDiscounted;
        canoniconContract = ICanonicon(_canoniconContract);
        splitRate = _splitRate;
        splitAddress = _splitAddress;

        for (uint8 i=0; i < 100;) {
            uint256 tokenId = _tokenIds.current();
            _safeMint(msg.sender, tokenId);
            _tokenIds.increment();
            unchecked { ++i; }
        }

        // Based on https://www.treasury.gov/ofac/downloads/sdn.csv
        address[28] memory sanctionAddresses = [
            address(0x098B716B8Aaf21512996dC57EB0615e2383E2f96),
            address(0xa0e1c89Ef1a489c9C7dE96311eD5Ce5D32c20E4B),
            address(0x3Cffd56B47B7b41c56258D9C7731ABaDc360E073),
            address(0x53b6936513e738f44FB50d2b9476730C0Ab3Bfc1),
            address(0x35fB6f6DB4fb05e6A4cE86f2C93691425626d4b1),
            address(0xF7B31119c2682c88d88D455dBb9d5932c65Cf1bE),
            address(0x3e37627dEAA754090fBFbb8bd226c1CE66D255e9),
            address(0x08723392Ed15743cc38513C4925f5e6be5c17243),
            address(0x7F367cC41522cE07553e823bf3be79A889DEbe1B),
            address(0xd882cFc20F52f2599D84b8e8D58C7FB62cfE344b),
            address(0x901bb9583b24D97e995513C6778dc6888AB6870e),
            address(0xA7e5d5A720f06526557c513402f2e6B5fA20b008),
            address(0x9F4cda013E354b8fC285BF4b9A60460cEe7f7Ea9),
            address(0x3CBdeD43EFdAf0FC77b9C55F6fC9988fCC9b757d),
            address(0xfEC8A60023265364D066a1212fDE3930F6Ae8da7),
            address(0x7FF9cFad3877F21d41Da833E2F775dB0569eE3D9),
            address(0x8589427373D6D84E98730D7795D8f6f8731FDA16),
            address(0x722122dF12D4e14e13Ac3b6895a86e84145b6967),
            address(0xDD4c48C0B24039969fC16D1cdF626eaB821d3384),
            address(0xd90e2f925DA726b50C4Ed8D0Fb90Ad053324F31b),
            address(0xd96f2B1c14Db8458374d9Aca76E26c3D18364307),
            address(0x4736dCf1b7A3d580672CcE6E7c65cd5cc9cFBa9D),
            address(0xD4B88Df4D29F5CedD6857912842cff3b20C8Cfa3),
            address(0x910Cbd523D972eb0a6f4cAe4618aD62622b39DbF),
            address(0xA160cdAB225685dA1d56aa342Ad8841c3b53f291),
            address(0xFD8610d20aA15b7B2E3Be39B396a1bC3516c7144),
            address(0xF60dD140cFf0706bAE9Cd734Ac3ae76AD9eBC32A),
            address(0x22aaA7720ddd5388A3c0A3333430953C68f1849b)
        ];
        for (uint256 i = 0; i < sanctionAddresses.length;) {
            sanctionedAddresses[sanctionAddresses[i]] = true;
            unchecked { ++i; }
        }
    }

    /// ============ Functions ============

    /**
     * @notice Mint
     */
    function mint(uint8 _mintAmount) external payable {
        require(!sanctionedAddresses[msg.sender], "Sanctioned address");
        require(_mintAmount > 0, "Need to mint at least 1 NFT");
        require(_mintAmount <= mintPerAddressLimit, "Max mint amount per session exceeded");
        require(addressMintedBalance[msg.sender] < mintPerAddressLimit, "Max mint amount per address exceeded");

        uint256 fee = mintFee;
        if (isDiscounted(msg.sender)) {
            fee = mintFeeDiscounted;
        }
        require(msg.value == fee * _mintAmount, "Payment must be equal to mint fee");

        // uint256 tokenId = _tokenIds.current();
        // require(tokenId < totalSupply, "Supply limit exceeded");
        require(mintEndsAt > block.timestamp, "Mint time limit exceeded");

        for (uint8 i=0; i < _mintAmount;) {
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, _tokenIds.current());
            _tokenIds.increment();
            unchecked { ++i; }
        }

        uint256 totalFee = fee * _mintAmount;
        uint256 splitFee = 0;
        if (splitRate > 0) {
            splitFee = (totalFee * splitRate) / 100;
            totalFee = totalFee - splitFee;
        }
        if (splitFee > 0) {
            _splitBalances[splitAddress] = _splitBalances[splitAddress] + splitFee;
        }

        Address.sendValue(feeAddress, totalFee);
    }

    /**
     * @notice Withdraw triggers a transfer to `account` of the amount of Ether they are owed,
     * according to their balance and their previous withdrawals.
     */
    function withdraw(address payable account) external virtual {
        uint256 payment = releasable(account);
        require(payment > 0, "Account is not due payment");

        _released[account] += payment;

        emit PaymentReleased(account, payment);
        Address.sendValue(account, payment);
    }

    /**
     * @dev Store owners of the token to provenance
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal virtual override
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        provenance[tokenId].push(to);
    }

    /// ============ Read-only functions ============

    /**
     * @dev Contract metadata
     */
    function contractURI() external view returns (string memory) {
        return string(
            abi.encodePacked(baseuri, "/", "contract-metadata", ".json")
        );
    }

    /**
     * @notice Get the amount of payee's releasable ETH
     */
    function isDiscounted(address account) public view returns (bool) {
        return canoniconContract.balanceOf(account) > 0;
    }

    /**
     * @notice Get the amount of payee's releasable ETH
     */
    function releasable(address account) public view returns (uint256) {
        return _splitBalances[account] - _released[account];
    }

    /**
     * @notice Get the amount of ETH already released to a payee
     */
    function released(address account) external view returns (uint256) {
        return _released[account];
    }

    /**
     * @notice Get metadata URI for the token
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Invalid token ID");

        return string(
            abi.encodePacked(baseuri, "/token/", Strings.toString(tokenId), ".json")
        );
    }

    /**
     * @notice Get current count of minted tokens
     */
    function tokenCount() external view virtual returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * @notice Get total supply of minted tokens (time-bound mint, so same as tokenCount)
     */
    function totalSupply() external view virtual returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * @notice Get current count of mints per address
     */
    function getMintBalance(address account) external view virtual returns (uint256) {
        return addressMintedBalance[account];
    }

    /**
     * @notice Get all accounts who owned this token
     * the first is the minter, the last is the current owner
     */
    function getProvenance(uint256 tokenId) external view virtual returns (address[] memory) {
        return provenance[tokenId];
    }
}