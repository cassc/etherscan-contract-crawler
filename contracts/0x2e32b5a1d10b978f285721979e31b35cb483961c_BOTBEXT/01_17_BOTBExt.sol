// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.12;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./abstract/ERC1155Factory.sol";

contract BOTBEXT is ERC1155Factory, ReentrancyGuard {
    using Strings for uint256;

    address public constant METH_ADDRESS =
        0xED5464bd5c477b7F71739Ce1d741b43E932b97b0;
    address public secret;
    address public treasuryWallet;

    mapping(bytes => bool) public usedSignatures;

    mapping(uint256 => uint256) public traitLimit;
    mapping(address => bool) public isMinter;

    event Minted(uint256 tokenId, uint256 amount, address to, address operator);
    event MintedFree(
        uint256 tokenId,
        uint256 amount,
        address to,
        address operator
    );
    event MintedMETH(
        uint256 tokenId,
        uint256 amount,
        address to,
        address operator
    );
    event MintedBatch(
        uint256[] ids,
        uint256[] amounts,
        address to,
        address operator
    );
    event MintedOffchain(
        uint256[] traitsOut,
        uint256[] traitsOutAmounts,
        bytes signature,
        address operator
    );

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155(_uri) {
        name_ = _name;
        symbol_ = _symbol;
    }

    modifier onlyMinter() {
        require(isMinter[msg.sender], "Mint: Not authorized to mint");
        _;
    }

    function mintOffchain(
        uint256[] memory traitsOut,
        uint256[] memory traitsOutAmounts,
        uint256 timeOut,
        bytes memory signature
    ) external nonReentrant {
        require(
            !usedSignatures[signature],
            "MintTraits: Signature already used"
        );
        require(timeOut > block.timestamp, "MintTraits: Signature expired");
        require(
            traitsOut.length == traitsOutAmounts.length,
            "MintTraits: Invalid traits length"
        );

        usedSignatures[signature] = true;

        string memory traitCode;

        for (uint256 i = 0; i < traitsOut.length; i++) {
            traitCode = string.concat(
                traitCode,
                "C",
                traitsOutAmounts[i].toString()
            );
            traitCode = string.concat(traitCode, "K", traitsOut[i].toString());
        }

        require(
            _verifyHashSignature(
                keccak256(abi.encode(timeOut, traitCode, msg.sender)),
                signature
            ),
            "MintTraits: Signature is invalid"
        );

        _mintBatch(msg.sender, traitsOut, traitsOutAmounts, "");

        emit MintedOffchain(traitsOut, traitsOutAmounts, signature, msg.sender);
    }

    function mint(
        address to,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        uint256 timeOut,
        bytes memory signature
    ) external payable nonReentrant {
        require(timeOut > block.timestamp, "Mint: Signature expired");
        require(!usedSignatures[signature], "Mint: Signature already used");
        if (traitLimit[tokenId] > 0) {
            require(
                amount + totalSupply(tokenId) <= traitLimit[tokenId],
                "Mint: Exceed trait limit"
            );
        }
        require(msg.value >= price, "Mint: Not enough funds for minting");
        require(
            _verifyHashSignature(
                keccak256(
                    abi.encode(msg.sender, tokenId, amount, price, timeOut)
                ),
                signature
            ),
            "Mint: Invalid signature"
        );

        usedSignatures[signature] = true;

        _mint(to, tokenId, amount, "");

        emit Minted(tokenId, amount, to, msg.sender);
    }

    function mintByMETH(
        address to,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        uint256 timeOut,
        bytes memory signature
    ) external nonReentrant {
        require(timeOut > block.timestamp, "Mint: Signature expired");
        require(!usedSignatures[signature], "Mint: Signature already used");
        if (traitLimit[tokenId] > 0) {
            require(
                amount + totalSupply(tokenId) <= traitLimit[tokenId],
                "Mint: Exceed trait limit"
            );
        }

        require(
            _verifyHashSignature(
                keccak256(
                    abi.encode(tokenId, msg.sender, timeOut, amount, price)
                ),
                signature
            ),
            "Mint: Invalid signature"
        );

        usedSignatures[signature] = true;

        IERC20(METH_ADDRESS).transfer(treasuryWallet, price);
        _mint(to, tokenId, amount, "");

        emit MintedMETH(tokenId, amount, to, msg.sender);
    }

    function freeMint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external onlyMinter {
        if (traitLimit[tokenId] > 0) {
            require(
                amount + totalSupply(tokenId) <= traitLimit[tokenId],
                "Mint: Exceed trait limit"
            );
        }

        _mint(to, tokenId, amount, "");

        emit MintedFree(tokenId, amount, to, msg.sender);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external payable onlyMinter {
        _mintBatch(to, ids, amounts, "");

        emit MintedBatch(ids, amounts, to, msg.sender);
    }

    function setTraitLimit(uint256 tokenId, uint256 limit) external onlyOwner {
        traitLimit[tokenId] = limit;
    }

    function bulkSetTraitLimit(
        uint256[] calldata tokenIds,
        uint256[] calldata limits
    ) external onlyOwner {
        require(
            tokenIds.length == limits.length,
            "bulkSetTrait: length mismatch"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            traitLimit[tokenIds[i]] = limits[i];
        }
    }

    function setIsMinter(address operator, bool status) external onlyOwner {
        isMinter[operator] = status;
    }

    function setTreasuryWallet(address _treasuryWallet) external onlyOwner {
        treasuryWallet = _treasuryWallet;
    }

    function setSecret(address _secret) external onlyOwner {
        secret = _secret;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "URI: nonexistent token");

        return string(abi.encodePacked(super.uri(_id), _id.toString()));
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        for (uint256 i = 0; i < ids.length; i++) {
            if (traitLimit[ids[i]] > 0) {
                require(
                    amounts[i] + totalSupply(ids[i]) <= traitLimit[ids[i]],
                    "Mint: Exceed trait limit"
                );
            }
        }

        super._mintBatch(to, ids, amounts, data);
    }

    function _verifyHashSignature(
        bytes32 freshHash,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return false;
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        address signer = address(0);
        if (v == 27 || v == 28) {
            // solium-disable-next-line arg-overflow
            signer = ecrecover(hash, v, r, s);
        }
        return secret == signer;
    }

    function withdrawETH(
        address _address,
        uint256 amount
    ) public nonReentrant onlyOwner {
        require(_address != address(0), "200:ZERO_ADDRESS");
        require(amount <= address(this).balance, "Insufficient funds");
        (bool success, ) = _address.call{value: amount}("");
        require(success, "Transaction failed");
    }
}