// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {DefaultOperatorFilterer} from "./OperatorFilterRegistry/DefaultOperatorFilterer.sol";

contract NFT1155 is ERC1155, DefaultOperatorFilterer, Ownable, ERC1155Burnable {
    using SafeMath for uint256;
    string public name = "Peking Monsters Soulbound Token";
    string public symbol = "PM-SBT";
    address public signer;
    address public creatorAddress;
    mapping(string => bool) internal nonceMap;
    mapping(uint256 => uint256[3]) internal tokenInfoMap;
    mapping(uint256 => uint256) internal mintCountMap;
    mapping(address => mapping(uint256 => uint256)) internal individualMintCountMap;

    constructor() ERC1155("") {
        creatorAddress = msg.sender;
    }

    event MintSuccess(address indexed operatorAddress, uint256 startId, uint256 quantity, uint256 price, string nonce, uint256 blockHeight);

    //******SET UP******
    function setSigner(address newSigner) public onlyOwner {
        signer = newSigner;
    }

    function setTokenInfo(uint256 tokenId, uint256[3] memory tokenInfo) public onlyOwner {
        tokenInfoMap[tokenId] = tokenInfo;
    }

    function setURI(string memory _newURI) public onlyOwner {
        _setURI(_newURI);
    }

    //******Functions******
    function uri(uint256 tokenId) public override view returns (string memory) {
        string memory baseURI = super.uri(tokenId);
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    function withdrawAll() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdraw(uint256 amount) public payable onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function airdropTokens(uint256[] calldata tokenIds, uint256[] calldata amount, address[] calldata owners) public onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _mint(owners[i], tokenIds[i], amount[i], abi.encode(creatorAddress));
        }
    }

    function safeMint(
        uint256 tokenId,
        uint256 quantity,
        bytes32 hash,
        bytes memory signature,
        uint256 blockHeight,
        string memory nonce)
    external
    payable
    {
        require(tokenInfoMap[tokenId][0] > 0, "Mint not available!");
        require(
            mintCountMap[tokenId] + quantity <= tokenInfoMap[tokenId][0],
            "Not enough stock!"
        );
        require(
            individualMintCountMap[msg.sender][tokenId] + quantity <= tokenInfoMap[tokenId][2],
            "You have reached individual mint limit!"
        );
        require(!nonceMap[nonce], "Nonce already exist!");
        require(hashSafeMint(tokenId, quantity, blockHeight, nonce, "peking_monsters_activity_sbt_mint") == hash, "Invalid hash!");
        require(matchAddressSigner(hash, signature), "Invalid signature!");
        uint256 totalPrice = quantity.mul(tokenInfoMap[tokenId][1]);
        require(msg.value >= totalPrice, "Not enough money!");

        mintCountMap[tokenId] = mintCountMap[tokenId] + quantity;
        individualMintCountMap[msg.sender][tokenId] = individualMintCountMap[msg.sender][tokenId] + quantity;
        nonceMap[nonce] = true;

        _mint(msg.sender, tokenId, quantity, abi.encode(creatorAddress));
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

        emit MintSuccess(msg.sender, tokenId, quantity, totalPrice, nonce, blockHeight);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    virtual
    override
    {
        require(from == address(0) || to == address(0), "Cannot transfer");
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    //******OperatorFilterer******
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    //******Tool******
    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
        // The maximum value of a uint256 contains 78 digits (1 byte per digit),
        // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
        // We will need 1 32-byte word to store the length,
        // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
        // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

        // Cache the end of the memory to calculate the length later.
            let end := ptr

        // We write the string from the rightmost digit to the leftmost digit.
        // The following is essentially a do-while loop that also handles the zero case.
        // Costs a bit more than early returning for the zero case,
        // but cheaper in terms of deployment and overall runtime costs.
            for {
            // Initialize and perform the first pass without check.
                let temp := value
            // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
            // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
            // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {// Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
        // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
        // Store the length.
            mstore(ptr, length)
        }
    }

    function hashSafeMint(uint256 tokenId, uint256 quantity, uint256 blockHeight, string memory nonce, string memory code)
    private
    view
    returns (bytes32)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(msg.sender, tokenId, quantity, blockHeight, nonce, code)
                )
            )
        );
        return hash;
    }

    function matchAddressSigner(bytes32 hash, bytes memory signature)
    internal
    view
    returns (bool)
    {
        return signer == recoverSigner(hash, signature);
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address){
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
    internal
    pure
    returns (
        bytes32 r,
        bytes32 s,
        uint8 v
    )
    {
        require(sig.length == 65, "Invalid signature length!");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}