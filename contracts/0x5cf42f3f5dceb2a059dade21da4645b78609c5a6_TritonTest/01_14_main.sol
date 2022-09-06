// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

pragma solidity ^0.8.4;
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract TritonTest is ERC1155Supply, Ownable, Pausable {
    using ECDSA for bytes32;

    string public name;
    string public symbol;
    string public tokenURI = "https://ipfs.io/ipfs/QmWR8PPpBEMGrLd93oxwqufis5pmvpG5wtXh8iY5yaMGL7/1.json";

    address private wallet1 = 0xe712D64036F1c309eC875fbE4E9513c7bE61E6Ce;
    address private wallet2 = 0xe712D64036F1c309eC875fbE4E9513c7bE61E6Ce;

    bytes32 public merkleRoot = 0xb2a3090a161706a41e64270ba5a7b6478d1a8279f718c94e889e5470d2a9a3b1;

    uint256 public constant TOKEN_ID = 1;
    uint256 public TOKEN_PRICE = 0.001 ether;
    uint256 public constant MAX_TOKENS = 333;


    bool public publicsaleIsActive = false;
    bool public whitelistsaleIsActive = true;
    mapping (address => bool) public hasAddressMinted;

    constructor() ERC1155("") {
        name = "Triton Test";
        symbol = "Triton";
    _mint(msg.sender, TOKEN_ID, 1, "");
    }

    function pause() public onlyOwner {
        _pause();
    }
    function uri(uint256 tokenId) public view override returns (string memory) {
        return tokenURI;
    }
    function unpause() public onlyOwner {
        _unpause();
    }

    function mintPass() external payable {
        require(publicsaleIsActive, "SALE_NOT_ACTIVE");
        require(TOKEN_PRICE == msg.value, "PRICE_WAS_INCORRECT");
        require(totalSupply(TOKEN_ID) < MAX_TOKENS, "MAX_TOKEN_SUPPLY_REACHED");
        require(hasAddressMinted[msg.sender] == false, "ADDRESS_HAS_ALREADY_MINTED_PASS");
        hasAddressMinted[msg.sender] = true;
        _mint(msg.sender, TOKEN_ID, 1, "");
        if (totalSupply(TOKEN_ID) >= MAX_TOKENS) {
            publicsaleIsActive = false;
        }
    }

    function whitelistMintPass(bytes32[] calldata _proof) external payable {
        require(publicsaleIsActive, "SALE_NOT_ACTIVE");
        require(TOKEN_PRICE == msg.value, "PRICE_WAS_INCORRECT");
        require(totalSupply(TOKEN_ID) < MAX_TOKENS, "MAX_TOKEN_SUPPLY_REACHED");
        require(MerkleProof.verify(_proof,merkleRoot,keccak256(abi.encodePacked(msg.sender))),"Invalid proof.");
        require(hasAddressMinted[msg.sender] == false, "ADDRESS_HAS_ALREADY_MINTED_PASS");
        hasAddressMinted[msg.sender] = true;
        _mint(msg.sender, TOKEN_ID, 1, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        require(amount > 0, "AMOUNT_CANNOT_BE_ZERO");
        return super.safeTransferFrom(from, to, id, amount, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function withdraw() external onlyOwner {

    uint256 teamBal = address(this).balance;
    uint256 p1= SafeMath.div(SafeMath.mul(teamBal,50), 100);
    uint256 p2 = SafeMath.div(SafeMath.mul(teamBal,50), 100);
    payable(wallet1).transfer(p1);
    payable(wallet2).transfer(p2);
    payable(owner()).transfer(address(this).balance);

    }
    function setCost(uint256 _price) public onlyOwner {
        TOKEN_PRICE = _price;
    } 
    function setMerkleRoot(bytes32 _root) public onlyOwner {
        merkleRoot = _root;
  }
    function setWhitelistPaused(bool _state) public onlyOwner {
    publicsaleIsActive = _state;
  }
    function setPublicPaused(bool _state) public onlyOwner {
    whitelistsaleIsActive = _state;
  }
}