// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract CyberBoxPass is ERC1155, ERC1155Supply, Ownable, EIP712 {
    string public name = "CyberBox Pass";
    string public symbol = "CBXP";

    address public operator;

    struct Tier {
        uint32 maxSupply;
        uint32 saleLimit;
        uint256 tokenPrice;
        bool whitelistOnly;
    }

    struct Voucher {
        uint256 tokenID;
        uint256 tokenPrice;
        address beneficiary;
        bytes signature;
    }

    mapping (bytes => bool) vouchersUsed;

    uint256 numTiers;
    mapping (uint256 => Tier) public tiers;

    string private constant SIGNING_DOMAIN = "CyberBoxPass-Voucher";
    string private constant SIGNATURE_VERSION = "1";

    modifier onlyOperator() {
        require(operator == msg.sender, "Caller is not the operator");
        _;
    }

    constructor(string memory uri) ERC1155(uri) EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        createTier(169, 69, 1200000000000000000, true);
        operator = msg.sender;
    }

    function mintPublic(uint256 tokenID) public payable {
        Tier storage tier = tiers[tokenID];

        require(totalSupply(tokenID) < tier.maxSupply, "Total supply has been reached.");
        require(totalSupply(tokenID) < tier.saleLimit, "Sale limit has been reached.");
        require(msg.value >= tier.tokenPrice, "Ether value sent is not correct.");
        require(tier.whitelistOnly == false, "This token is currently only mintable for whitelisted users.");

        _mint(msg.sender, tokenID, 1, "");
    }

    function mintVoucher(Voucher calldata voucher) public payable {
        require(vouchersUsed[voucher.signature] == false, "Voucher has already been used or is invalid.");
        require(voucher.beneficiary == msg.sender, "Vouchers beneficiary is not the caller.");

        address signer = _verify(voucher);

        require(signer == operator, "Signature invalid or unauthorized");

        Tier storage tier = tiers[voucher.tokenID];
        require(msg.value >= voucher.tokenPrice, "Ether value sent is not correct.");
        require(totalSupply(voucher.tokenID) < tier.maxSupply, "Total supply has been reached.");
        require(totalSupply(voucher.tokenID) < tier.saleLimit, "Sale limit has been reached.");

        _mint(msg.sender, voucher.tokenID, 1, "");
        vouchersUsed[voucher.signature] = true;
    }

    function _hash(Voucher calldata voucher) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Voucher(uint256 tokenID,uint256 tokenPrice,address beneficiary)"),
            voucher.tokenID,
            voucher.tokenPrice,
            voucher.beneficiary
        )));
    }

    function _verify(Voucher calldata voucher) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }

    function createTier(uint32 maxSupply, uint32 saleLimit, uint256 tokenPrice, bool whitelistOnly) public onlyOwner {
        uint256 tokenID = numTiers++;
        Tier storage tier = tiers[tokenID];
        tier.maxSupply = maxSupply;
        tier.saleLimit = saleLimit;
        tier.tokenPrice = tokenPrice;
        tier.whitelistOnly = whitelistOnly;
    }

    function invalidateVoucher(bytes calldata signature) public onlyOperator {
        vouchersUsed[signature] = true;
    }

    function updatePrice(uint256 tokenPrice, uint256 tokenID) public onlyOwner {
        tiers[tokenID].tokenPrice = tokenPrice;
    }

    function updateWhitelistRequirement(bool whitelistOnly, uint256 tokenID) public onlyOwner {
        tiers[tokenID].whitelistOnly = whitelistOnly;
    }

    function updateSaleLimit(uint32 saleLimit, uint256 tokenID) public onlyOwner {
        require(saleLimit <= tiers[tokenID].maxSupply, "Sale limit must be less than or equal to the maximum supply.");
        tiers[tokenID].saleLimit = saleLimit;
    }

    function setURI(string memory uri) public onlyOwner {
        _setURI(uri);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setOperator(address _operator) public onlyOwner {
        operator = _operator;
    }

    function _beforeTokenTransfer(address _operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(_operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}