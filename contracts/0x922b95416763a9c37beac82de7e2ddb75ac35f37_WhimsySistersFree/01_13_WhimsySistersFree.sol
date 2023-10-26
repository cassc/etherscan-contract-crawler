// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WhimsySistersFree is ERC721A, Ownable {

    using ECDSA for bytes32;

    uint constant public MAX_SUPPLY = 7000;

    string public baseURI = "https://storage.googleapis.com/whimsysisters/meta-free/";

    uint public reservedSupply = 800;
    uint public maxMintsPerWallet = 3;

    uint public publicSaleStartTimestamp = 1658340000;
    uint public mintFromReservePeriod = 2 * 24 * 60 * 60;

    mapping(address => uint) public mintedNFTs;
    mapping(address => uint) public mintedNFTsFromReserve;

    address public authorizedSigner = 0x75632C07FdaD56EaE0AE8DE2E2DF010FB325F15F;

    bool osAutoApproveEnabled = true;
    address public openseaConduit = 0x1E0049783F008A0085193E00003D00cd54003c71;

    constructor() ERC721A("Whimsy Sisters", "WHIMSY", 15) {
    }

    function setBaseURI(string memory _baseURIArg) external onlyOwner {
        baseURI = _baseURIArg;
    }

    function configure(
        uint _reservedSupply,
        uint _maxMintsPerWallet,
        uint _publicSaleStartTimestamp,
        uint _mintFromReservePeriod,
        bool _osAutoApproveEnabled,
        address _authorizedSigner
    ) external onlyOwner {
        reservedSupply = _reservedSupply;
        maxMintsPerWallet = _maxMintsPerWallet;
        publicSaleStartTimestamp = _publicSaleStartTimestamp;
        mintFromReservePeriod = _mintFromReservePeriod;
        osAutoApproveEnabled = _osAutoApproveEnabled;
        authorizedSigner = _authorizedSigner;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function recoverSignerAddress(address minter, uint reserveMints, bytes calldata signature) internal pure returns (address) {
        bytes32 hash = hashTransaction(minter, reserveMints);
        return hash.recover(signature);
    }

    function hashTransaction(address minter, uint reserveMints) internal pure returns (bytes32) {
        bytes32 argsHash = keccak256(abi.encodePacked(minter, reserveMints));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", argsHash));
    }


    function mint(uint amount, uint amountFromReserve, uint reserveMints, bytes calldata signature) external {
        require(tx.origin == _msgSender(), "The caller is another contract");
        require(block.timestamp >= publicSaleStartTimestamp, "Minting is not available");
        require(amount > 0 || amountFromReserve > 0, "Zero amount to mint");

        require(reserveMints == 0 || recoverSignerAddress(_msgSender(), reserveMints, signature) == authorizedSigner, "tx sender is not allowed to presale");

        uint reserved = 0;
        if (block.timestamp < publicSaleStartTimestamp + mintFromReservePeriod) {
            reserved = reservedSupply;
        }

        require(totalSupply() + amount + reserved <= MAX_SUPPLY, "Tokens total supply reached limit");
        require(amountFromReserve <= reserved, "Tokens reserved supply reached limit");

        require(mintedNFTs[_msgSender()] + amount <= maxMintsPerWallet, "No more mints for this wallet!");
        mintedNFTs[_msgSender()] += amount;

        if (amountFromReserve > 0) {
            require(mintedNFTsFromReserve[_msgSender()] + amountFromReserve <= reserveMints, "Empty reserve for this address");
            mintedNFTsFromReserve[_msgSender()] += amountFromReserve;
            reservedSupply -= amountFromReserve;
        }

        _safeMint(_msgSender(), amount + amountFromReserve);
    }

    function airdrop(address[] calldata addresses, uint[] calldata amounts) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            require(totalSupply() + amounts[i] <= MAX_SUPPLY, "Tokens supply reached limit");
            _safeMint(addresses[i], amounts[i]);
        }
    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        if (osAutoApproveEnabled && operator == openseaConduit) {
            return true;
        }
        return super.isApprovedForAll(_owner, operator);
    }

}