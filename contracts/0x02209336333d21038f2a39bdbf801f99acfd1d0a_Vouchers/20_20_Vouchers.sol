// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vouchers is ERC721, ERC721Enumerable, ERC721Burnable, Ownable, EIP712 {
    using Counters for Counters.Counter;

    modifier ownerOrMinter() {
        require(
            msg.sender == owner() || isMinter[msg.sender],
            "Vouchers: Owner or Minter only"
        );
        _;
    }

    error PaymentTokenTransferError(address from, address to, uint256 amount);
    error BalanceBelowThenTransferredAmount();
    event MintedWithNonce(
        address minter,
        uint256 indexed nonce,
        uint256 num,
        address ptFromAccount,
        address[] ptFromAccountReceivers,
        uint256[] fromAccountAmounts
    );
    event Redeemed(
        address indexed redeemer, 
        uint256[] indexed tokenIds,
        uint256[] indexed tokenTypes
    );
    event MintedWithType(uint256 tokenId, uint256 tokenType);

    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => bool) public isNonceUsed;
    address public signer;
    mapping(address => bool) public isMinter;
    mapping(uint256 => uint256) public typeOf;
    mapping(uint256 => bool) public isVoucherUsed;
    string internal uri_;

    constructor(
        string memory startUri,
        address signerRole
    ) ERC721("TravelCard-Collection", "TCC") EIP712("TravelCard", "1") {
        signer = signerRole;
        uri_ = startUri;
    }

    function mint(address to, uint256 tokenType) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(to, tokenId);
        typeOf[tokenId] = tokenType;
        emit MintedWithType(tokenId, tokenType);
    }

    function tokensAndTypesOfOwner(address owner) external view returns(uint256[] memory, uint256[] memory){
        uint256 balance = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](balance);
        uint256[] memory types = new uint256[](balance);
        for(uint256 i = 0; i<balance; i++){
            uint256 tokenId = tokenOfOwnerByIndex(owner, i);
            tokenIds[i] = tokenId;
            types[i] = typeOf[tokenId];
        }
        return(tokenIds, types);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return uri_;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function receivePayment(
        address ptFromAccount,
        address[] memory ptFromAccountReceivers,
        uint256[] memory fromAccountAmounts
    ) internal {
        if (
            (ptFromAccountReceivers.length != 0) &&
            (fromAccountAmounts.length != 0) &&
            (ptFromAccountReceivers.length == fromAccountAmounts.length)
        ) {
            if (ptFromAccount == address(0)) {
                uint256 sum;
                for (uint256 i = 0; i < ptFromAccountReceivers.length; i++) {
                    sum += fromAccountAmounts[i];
                }
                require(msg.value >= sum, "Vouchers: Not enough BNB");
                for (uint256 i = 0; i < ptFromAccountReceivers.length; i++) {
                    if (ptFromAccountReceivers[i] != address(this)) {
                        Address.sendValue(
                            payable(ptFromAccountReceivers[i]),
                            fromAccountAmounts[i]
                        );
                    }
                }
            } else {
                for (uint256 i = 0; i < ptFromAccountReceivers.length; i++) {
                    if (
                        IERC20(ptFromAccount).balanceOf(msg.sender) <
                        fromAccountAmounts[i]
                    ) {
                        revert BalanceBelowThenTransferredAmount();
                    }
                    if (
                        !IERC20(ptFromAccount).transferFrom(
                            msg.sender,
                            ptFromAccountReceivers[i],
                            fromAccountAmounts[i]
                        )
                    )
                        revert PaymentTokenTransferError(
                            msg.sender,
                            ptFromAccountReceivers[i],
                            fromAccountAmounts[i]
                        );
                }
            }
        }
    }

    function batchMintWithSignature(
        address to,
        uint256 num,
        uint256 tokenType,
        address ptFromAccount,
        address[] memory ptFromAccountReceivers,
        uint256[] memory fromAccountAmounts,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) external {
        require(block.timestamp <= deadline, "Vouchers: Transaction overdue");
        require(!isNonceUsed[nonce], "Vouchers: Nonce already used");
        bytes32 typedHash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "BatchMintData(address to,uint256 num,uint256 tokenType,address ptFromAccount,address[] ptFromAccountReceivers,uint256[] fromAccountAmounts,uint256 nonce,uint256 deadline)"
                    ),
                    to,
                    num,
                    tokenType,
                    ptFromAccount,
                    keccak256(abi.encodePacked(ptFromAccountReceivers)),
                    keccak256(abi.encodePacked(fromAccountAmounts)),
                    nonce,
                    deadline
                )
            )
        );
        require(
            ECDSA.recover(typedHash, signature) == signer,
            "Vouchers: Signature Mismatch"
        );
        isNonceUsed[nonce] = true;
        receivePayment(
            ptFromAccount,
            ptFromAccountReceivers,
            fromAccountAmounts
        );
        mintBatch(to, tokenType, num);
        emit MintedWithNonce(
            msg.sender,
            nonce,
            num,
            ptFromAccount,
            ptFromAccountReceivers,
            fromAccountAmounts
        );
    }

    function mintBatch(address to, uint256 tokenType, uint256 num) public ownerOrMinter{
        for (uint256 i = 0; i < num; i++) {
            mint(to, tokenType);
        }
    }

    function _burnBatch(uint256[] memory tokenIds) internal {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
        }
    }

    function batchRedeemWithSignature(
        uint256[] memory tokenIds,
        uint256 deadline,
        bytes memory signature
    ) external {
        require(block.timestamp <= deadline, "Vouchers: Transaction overdue");
        bytes32 typedHash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "RedeemData(address redeemer,uint256[] tokenIds,uint256 deadline)"
                    ),
                    msg.sender,
                    keccak256(abi.encodePacked(tokenIds)),
                    deadline
                )
            )
        );
        require(
            ECDSA.recover(typedHash, signature) == signer,
            "Vouchers: Signature Mismatch"
        );
        uint256[] memory tokenTypes = new uint256[](tokenIds.length);
        for(uint256 i=0;i<tokenIds.length; i++){
            tokenTypes[i] = typeOf[tokenIds[i]];
            require(ownerOf(tokenIds[i]) == msg.sender, "Vouchers: burner is not owner");
        }
        emit Redeemed(msg.sender, tokenIds, tokenTypes);
        _burnBatch(tokenIds);
    }

    function setURI(string memory newuri) public onlyOwner {
        uri_ = newuri;
    }

    function setStatusForMinter(
        address minter,
        bool newStatus
    ) external onlyOwner {
        isMinter[minter] = newStatus;
    }

    function withdrawTokens(
        address tokenAddress,
        uint256 amount
    ) external onlyOwner {
        require(
            IERC20(tokenAddress).transfer(msg.sender, amount),
            "Vouchers: transfer error"
        );
    }

    function withdraw(uint256 amount) external onlyOwner {
        Address.sendValue(payable(msg.sender), amount);
    }
}