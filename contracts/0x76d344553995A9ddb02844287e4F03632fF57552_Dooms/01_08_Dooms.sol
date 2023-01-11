// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "https://github.com/ProjectOpenSea/operator-filter-registry/blob/main/src/DefaultOperatorFilterer.sol";
import "https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Dooms is ERC721, Ownable, DefaultOperatorFilterer {
    error InvalidProof();
    error AllowedMintsExceeded();
    error RevealIncorrectOwner();
    error RevealClosed();
    error DoesNotExist();
    error IndexOutOfBound();

    bytes32 private _root;
    string private _metadataURI;
    string private _metadataExtension;
    mapping(address => uint256) private _minted;
    uint256 private _burned;

    bool public revealOpen;
    uint256 public nextTokenId;
    mapping(uint256 => bool) public revealed;

    constructor() ERC721("Dooms", "DOOMS") {}

    // Public
    function mint(bytes32[] memory proof_, uint256 quantity_) external {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender, quantity_)))
        );

        if (!MerkleProof.verify(proof_, _root, leaf)) {
            revert InvalidProof();
        }

        if (_minted[msg.sender] >= quantity_) {
            revert AllowedMintsExceeded();
        }

        uint256 allowance = quantity_ - _minted[msg.sender];

        _minted[msg.sender] = quantity_;

        _mintBatch(msg.sender, allowance);
    }

    function reveal(uint256 id_) external {
        if (!revealOpen) {
            revert RevealClosed();
        }

        if (_ownerOf[id_] != msg.sender) {
            revert RevealIncorrectOwner();
        }

        revealed[id_] = true;
    }

    // Owner only
    function airdrop(address to_, uint256 quantity_) external onlyOwner {
        _mintBatch(to_, quantity_);
    }

    function burn(uint256 id_) external onlyOwner {
        _burn(id_);
        unchecked {
            _burned++;
        }
    }

    function remint(address to_, uint256 id_) external onlyOwner {
        _mint(to_, id_);
        unchecked {
            _burned--;
        }
    }

    function setMerkleRoot(bytes32 root_) external onlyOwner {
        _root = root_;
    }

    function setMetadataURI(string memory metadataURI_) external onlyOwner {
        _metadataURI = metadataURI_;
    }

    function setMetadataExtension(string memory metadataExtension_)
        external
        onlyOwner
    {
        _metadataExtension = metadataExtension_;
    }

    function toggleReveal() external onlyOwner {
        revealOpen = !revealOpen;
    }

    // Overrides
    function setApprovalForAll(address operator_, bool approved_)
        public
        override
        onlyAllowedOperatorApproval(operator_)
    {
        super.setApprovalForAll(operator_, approved_);
    }

    function approve(address operator_, uint256 id_)
        public
        override
        onlyAllowedOperatorApproval(operator_)
    {
        super.approve(operator_, id_);
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 id_
    ) public override onlyAllowedOperator(from_) {
        super.transferFrom(from_, to_, id_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 id_
    ) public override onlyAllowedOperator(from_) {
        super.safeTransferFrom(from_, to_, id_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 id_,
        bytes calldata data_
    ) public override onlyAllowedOperator(from_) {
        super.safeTransferFrom(from_, to_, id_, data_);
    }

    function tokenURI(uint256 id_)
        public
        view
        override
        returns (string memory)
    {
        if (_ownerOf[id_] == address(0)) revert DoesNotExist();

        return
            bytes(_metadataURI).length != 0
                ? string(
                    abi.encodePacked(
                        _metadataURI,
                        _toString(id_),
                        _metadataExtension
                    )
                )
                : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceId == 0x780e9d63 || // ERC165 Interface ID for ERC721Enumerable
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    // Extension
    function totalSupply() external view returns (uint256) {
        return nextTokenId - _burned;
    }

    function tokenByIndex(uint256 index_) external view returns (uint256) {
        if (_ownerOf[index_] == address(0)) revert DoesNotExist();
        return index_;
    }

    function tokenOfOwnerByIndex(address owner_, uint256 index_)
        external
        view
        returns (uint256)
    {
        if (index_ >= _balanceOf[owner_]) revert IndexOutOfBound();

        unchecked {
            uint256 count;

            for (uint256 i; i < nextTokenId; i++) {
                if (owner_ == _ownerOf[i]) {
                    if (count == index_) {
                        return i;
                    } else {
                        count++;
                    }
                }
            }
        }

        revert IndexOutOfBound();
    }

    function tokensOfOwner(address owner_)
        external
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256 balance = _balanceOf[owner_];
            uint256 count;
            uint256[] memory ids = new uint256[](balance);

            for (uint256 i; count != balance; i++) {
                if (owner_ == _ownerOf[i]) {
                    ids[count++] = i;
                }
            }

            return ids;
        }
    }

    // Rescue
    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );

        require(success);
    }

    // Utils
    function _mintBatch(address to_, uint256 quantity_) private {
        unchecked {
            for (uint256 i; i < quantity_; i++) {
                _mint(to_, nextTokenId++);
            }
        }
    }

    function _toString(uint256 value) private pure returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}